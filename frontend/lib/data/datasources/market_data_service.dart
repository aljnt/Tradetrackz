import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/asset_type.dart';
import '../models/candle.dart';
import '../models/quote.dart';

class RateLimitException implements Exception {
  final String message;
  const RateLimitException(this.message);

  @override
  String toString() => message;
}

class MarketDataService {
  String? _twelveDataKey;
  String? _finnhubKey;
  String? _alphaVantageKey;

  String? get twelveDataKey => _twelveDataKey;
  String? get finnhubKey => _finnhubKey;
  String? get alphaVantageKey => _alphaVantageKey;
  bool get hasTwelveDataKey =>
      _twelveDataKey != null && _twelveDataKey!.trim().isNotEmpty;

  final StreamController<Map<String, double>> _priceController =
      StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get priceStream => _priceController.stream;

  Timer? _pollingTimer;
  List<String> _subscribedSymbols = [];

  final Map<String, Quote> _quoteCache = {};
  final Map<String, DateTime> _quoteCacheTime = {};
  final Map<String, List<Candle>> _candleCache = {};

  static const Duration quoteCacheDuration = Duration(minutes: 2);
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _twelveDataKey = prefs.getString('twelve_data_key');
    _finnhubKey = prefs.getString('finnhub_key');
    _alphaVantageKey = prefs.getString('alpha_vantage_key');
  }

  Future<void> setApiKeys({
    String? twelveDataKey,
    String? finnhubKey,
    String? alphaVantageKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (twelveDataKey != null) {
      final value = twelveDataKey.trim();
      if (value.isEmpty) {
        _twelveDataKey = null;
        await prefs.remove('twelve_data_key');
      } else {
        _twelveDataKey = value;
        await prefs.setString('twelve_data_key', value);
      }
    }

    if (finnhubKey != null) {
      final value = finnhubKey.trim();
      _finnhubKey = value.isEmpty ? null : value;
      if (value.isEmpty) {
        await prefs.remove('finnhub_key');
      } else {
        await prefs.setString('finnhub_key', value);
      }
    }

    if (alphaVantageKey != null) {
      final value = alphaVantageKey.trim();
      _alphaVantageKey = value.isEmpty ? null : value;
      if (value.isEmpty) {
        await prefs.remove('alpha_vantage_key');
      } else {
        await prefs.setString('alpha_vantage_key', value);
      }
    }

    _quoteCache.clear();
    _quoteCacheTime.clear();
    _candleCache.clear();
  }

  void subscribeToLivePrices(List<String> symbols) {
    _subscribedSymbols = symbols;
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!hasTwelveDataKey || _subscribedSymbols.isEmpty) return;

      final Map<String, double> updates = {};
      for (final symbol in _subscribedSymbols) {
        final cached = _quoteCache[symbol];
        if (cached != null) {
          updates[symbol] = cached.price;
        }
      }

      if (updates.isNotEmpty && !_priceController.isClosed) {
        _priceController.add(updates);
      }
    });
  }

  Future<void> _throttle() async {
    final now = DateTime.now();
    final diff = now.difference(_lastRequestTime);
    if (diff.inMilliseconds < 1200) {
      await Future.delayed(Duration(milliseconds: 1200 - diff.inMilliseconds));
    }
    _lastRequestTime = DateTime.now();
  }

  // ============================================================
  // FETCH QUOTE
  // ============================================================

  Future<Quote> fetchQuote(AssetItem asset) async {
    final cached = _quoteCache[asset.symbol];
    final cachedTime = _quoteCacheTime[asset.symbol];

    if (cached != null && cachedTime != null) {
      if (DateTime.now().difference(cachedTime) < quoteCacheDuration) {
        return cached;
      }
    }

    if (!hasTwelveDataKey) {
      throw Exception('Clé Twelve Data non configurée');
    }

    await _throttle();

    final symbol = _twelveSymbol(asset);
    print('REQUEST QUOTE: $symbol');

    final uri = Uri.https('api.twelvedata.com', '/quote', {
      'symbol': symbol,
      'apikey': _twelveDataKey!,
    });

    final response = await http.get(uri);

    if (response.statusCode == 429) {
      throw const RateLimitException('Limite 8 req/min Twelve Data atteinte.');
    }

    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} pour $symbol');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['code'] != null) {
      throw Exception('Twelve Data: ${data['message'] ?? data}');
    }

    final quote = Quote.fromTwelveData(json: data, asset: asset);
    _quoteCache[asset.symbol] = quote;
    _quoteCacheTime[asset.symbol] = DateTime.now();

    return quote;
  }

  // ============================================================
  // FETCH CANDLES (TIME SERIES)
  // ============================================================

  Future<List<Candle>> fetchCandles(AssetItem asset, String timeframe) async {
    final cacheKey = '${asset.symbol}_$timeframe';

    if (_candleCache.containsKey(cacheKey)) {
      return _candleCache[cacheKey]!;
    }

    if (!hasTwelveDataKey) {
      throw Exception('Clé Twelve Data non configurée');
    }

    await _throttle();

    final interval = _convertTimeframe(timeframe);
    final symbol = _twelveSymbol(asset);
    print('REQUEST CANDLES: $symbol ($interval)');

    final uri = Uri.https('api.twelvedata.com', '/time_series', {
      'symbol': symbol,
      'interval': interval,
      'outputsize': '30',
      'apikey': _twelveDataKey!,
    });

    final response = await http.get(uri);

    if (response.statusCode == 429) {
      throw const RateLimitException('Limite Twelve Data atteinte (Candles).');
    }

    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} pour $symbol');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['code'] != null) {
      throw Exception('Twelve Data: ${data['message'] ?? data}');
    }

    final values = data['values'] as List?;
    if (values == null || values.isEmpty) {
      throw Exception('Aucune donnée disponible pour $symbol');
    }

    final candles = values
        .map((value) => Candle.fromJson(value as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();

    _candleCache[cacheKey] = candles;
    return candles;
  }

  // ============================================================
  // WATCHLIST & UTILS
  // ============================================================

  Future<Map<String, Quote>> fetchWatchlist(List<AssetItem> assets) async {
    final result = <String, Quote>{};
    for (final asset in assets) {
      result[asset.symbol] = _quoteCache[asset.symbol] ?? generateFallbackQuote(asset);
    }
    return result;
  }

  String _convertTimeframe(String timeframe) {
    switch (timeframe) {
      case '1m': return '1min';
      case '5m': return '5min';
      case '15m': return '15min';
      case '1H': return '1h';
      case '4H': return '4h';
      case '1D': return '1day';
      default: return '1day';
    }
  }

  String _twelveSymbol(AssetItem asset) {
    switch (asset.symbol.toUpperCase()) {
      case 'WTI/USD': return 'WTI';
      case 'DXY': return 'DX-Y.NYB';
      default: return asset.symbol;
    }
  }

  Quote generateFallbackQuote(AssetItem asset) {
    return Quote(
      symbol: asset.symbol,
      name: asset.fullName,
      price: 100.0,
      change: 0.0,
      changePercent: 0.0,
      high: 100.0,
      low: 100.0,
      open: 100.0,
      previousClose: 100.0,
      volume: 0.0,
      timestamp: DateTime.now(),
      assetType: asset.type,
      exchange: asset.exchange,
      sector: asset.sector,
      isMarketOpen: true,
      fiftyTwoWeekHigh: 100.0,
      fiftyTwoWeekLow: 100.0,
    );
  }

  void dispose() {
    _pollingTimer?.cancel();
    _priceController.close();
  }
}