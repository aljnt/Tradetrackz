import 'asset_type.dart';

class Quote {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final double high;
  final double low;
  final double open;
  final double previousClose;
  final double volume;
  final DateTime timestamp;
  final AssetType assetType;
  final String exchange;
  final String sector;
  final bool isMarketOpen;
  final double fiftyTwoWeekHigh;
  final double fiftyTwoWeekLow;

  const Quote({
    required this.symbol,
    required this.name,
    required this.price,
    this.change = 0.0,
    this.changePercent = 0.0,
    this.high = 0.0,
    this.low = 0.0,
    this.open = 0.0,
    this.previousClose = 0.0,
    this.volume = 0.0,
    required this.timestamp,
    required this.assetType,
    this.exchange = 'GLOBAL',
    this.sector = 'Financial',
    this.isMarketOpen = true,
    this.fiftyTwoWeekHigh = 0.0,
    this.fiftyTwoWeekLow = 0.0,
  });

  bool get isPositive => change >= 0;

  double get spread {
    switch (assetType) {
      case AssetType.forex:
        return symbol.contains('JPY') ? 0.015 : 0.00015;
      case AssetType.gold:
        return 0.35;
      case AssetType.cfd:
        return 0.04;
      case AssetType.indices:
        return 0.80;
      case AssetType.stock:
        return 0.05;
      case AssetType.crypto:
        return price * 0.0005;
    }
  }

  double get bidPrice => (price - (spread / 2)).clamp(0, double.infinity);
  double get askPrice => price + (spread / 2);

  factory Quote.fromTwelveData({
    required Map<String, dynamic> json,
    required AssetItem asset,
  }) {
    // TwelveData format: { "price": "2345.50" } or quote response
    final price = double.tryParse(json['price']?.toString() ?? json['close']?.toString() ?? '0') ?? 0.0;
    final change = double.tryParse(json['change']?.toString() ?? '0') ?? 0.0;
    final percentChange = double.tryParse(json['percent_change']?.toString() ?? '0') ?? 0.0;
    final high = double.tryParse(json['high']?.toString() ?? '0') ?? price * 1.008;
    final low = double.tryParse(json['low']?.toString() ?? '0') ?? price * 0.992;
    final open = double.tryParse(json['open']?.toString() ?? '0') ?? price - change;
    final prevClose = double.tryParse(json['previous_close']?.toString() ?? '0') ?? (open != 0 ? open : price);
    final volume = double.tryParse(json['volume']?.toString() ?? '0') ?? 0.0;

    final isMarketOpen = json['is_market_open'] == true ||
        (json['is_market_open'] == null && (asset.type == AssetType.crypto || asset.type == AssetType.forex || asset.type == AssetType.gold));

    DateTime ts;
    if (json['timestamp'] != null) {
      if (json['timestamp'] is int) {
        ts = DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as int) * 1000);
      } else {
        ts = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
      }
    } else {
      ts = DateTime.now();
    }

    final fiftyTwoHigh = double.tryParse(json['fifty_two_week']?['high']?.toString() ?? '0') ?? (price * 1.15);
    final fiftyTwoLow = double.tryParse(json['fifty_two_week']?['low']?.toString() ?? '0') ?? (price * 0.85);

    return Quote(
      symbol: asset.symbol,
      name: asset.fullName,
      price: price,
      change: change,
      changePercent: percentChange,
      high: high,
      low: low,
      open: open,
      previousClose: prevClose,
      volume: volume,
      timestamp: ts,
      assetType: asset.type,
      exchange: asset.exchange,
      sector: asset.sector,
      isMarketOpen: isMarketOpen,
      fiftyTwoWeekHigh: fiftyTwoHigh,
      fiftyTwoWeekLow: fiftyTwoLow,
    );
  }

  factory Quote.fromFinnhub({
    required Map<String, dynamic> json,
    required AssetItem asset,
  }) {
    final price = (json['c'] as num?)?.toDouble() ?? 0.0;
    final change = (json['d'] as num?)?.toDouble() ?? 0.0;
    final percentChange = (json['dp'] as num?)?.toDouble() ?? 0.0;
    final high = (json['h'] as num?)?.toDouble() ?? price * 1.008;
    final low = (json['l'] as num?)?.toDouble() ?? price * 0.992;
    final open = (json['o'] as num?)?.toDouble() ?? price - change;
    final prevClose = (json['pc'] as num?)?.toDouble() ?? (open != 0 ? open : price);
    final timestamp = json['t'] is num
        ? DateTime.fromMillisecondsSinceEpoch((json['t'] as num).toInt() * 1000)
        : DateTime.now();

    return Quote(
      symbol: asset.symbol,
      name: asset.fullName,
      price: price,
      change: change,
      changePercent: percentChange,
      high: high,
      low: low,
      open: open,
      previousClose: prevClose,
      volume: 0.0,
      timestamp: timestamp,
      assetType: asset.type,
      exchange: asset.exchange,
      sector: asset.sector,
      isMarketOpen: true,
      fiftyTwoWeekHigh: price * 1.15,
      fiftyTwoWeekLow: price * 0.85,
    );
  }

  Quote copyWith({
    String? symbol,
    String? name,
    double? price,
    double? change,
    double? changePercent,
    double? high,
    double? low,
    double? open,
    double? previousClose,
    double? volume,
    DateTime? timestamp,
    AssetType? assetType,
    String? exchange,
    String? sector,
    bool? isMarketOpen,
    double? fiftyTwoWeekHigh,
    double? fiftyTwoWeekLow,
  }) {
    return Quote(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      high: high ?? this.high,
      low: low ?? this.low,
      open: open ?? this.open,
      previousClose: previousClose ?? this.previousClose,
      volume: volume ?? this.volume,
      timestamp: timestamp ?? this.timestamp,
      assetType: assetType ?? this.assetType,
      exchange: exchange ?? this.exchange,
      sector: sector ?? this.sector,
      isMarketOpen: isMarketOpen ?? this.isMarketOpen,
      fiftyTwoWeekHigh: fiftyTwoWeekHigh ?? this.fiftyTwoWeekHigh,
      fiftyTwoWeekLow: fiftyTwoWeekLow ?? this.fiftyTwoWeekLow,
    );
  }
}
