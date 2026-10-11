class Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0.0,
  });

  bool get isBullish => close >= open;
  bool get isBearish => close < open;

  double get bodyTop => isBullish ? close : open;
  double get bodyBottom => isBullish ? open : close;
  double get bodyHeight => (close - open).abs();
  double get totalRange => high - low;
  double get change => close - open;
  double get changePercent => open != 0 ? ((close - open) / open) * 100 : 0.0;

  factory Candle.fromJson(Map<String, dynamic> json) {
    // Format TwelveData: { "datetime": "2026-08-15", "open": "2345.50", "high": "2360.10", "low": "2340.00", "close": "2355.20", "volume": "145000" }
    DateTime parsedTime;
    if (json['datetime'] != null) {
      parsedTime = DateTime.tryParse(json['datetime'].toString()) ?? DateTime.now();
    } else if (json['time'] != null) {
      if (json['time'] is int) {
        parsedTime = DateTime.fromMillisecondsSinceEpoch(json['time'] * 1000);
      } else {
        parsedTime = DateTime.tryParse(json['time'].toString()) ?? DateTime.now();
      }
    } else if (json['t'] != null && json['t'] is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(json['t'] * 1000);
    } else {
      parsedTime = DateTime.now();
    }

    return Candle(
      time: parsedTime,
      open: double.tryParse(json['open']?.toString() ?? json['o']?.toString() ?? '0') ?? 0.0,
      high: double.tryParse(json['high']?.toString() ?? json['h']?.toString() ?? '0') ?? 0.0,
      low: double.tryParse(json['low']?.toString() ?? json['l']?.toString() ?? '0') ?? 0.0,
      close: double.tryParse(json['close']?.toString() ?? json['c']?.toString() ?? '0') ?? 0.0,
      volume: double.tryParse(json['volume']?.toString() ?? json['v']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'datetime': time.toIso8601String(),
      'open': open, 
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }

  Candle copyWith({
    DateTime? time,
    double? open,
    double? high,
    double? low,
    double? close,
    double? volume,
  }) {
    return Candle(
      time: time ?? this.time,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      volume: volume ?? this.volume,
    );
  }
}
