import 'package:equatable/equatable.dart';

enum PositionSide { long, short }

class TradePosition extends Equatable {
  final String id;
  final String symbol;
  final PositionSide side;
  final double entryPrice;
  final double takeProfit;
  final double stopLoss;
  final double margin;      // montant de la marge en USD
  final double leverage;
  final DateTime openedAt;

  const TradePosition({
    required this.id,
    required this.symbol,
    required this.side,
    required this.entryPrice,
    required this.takeProfit,
    required this.stopLoss,
    required this.margin,
    required this.leverage,
    required this.openedAt,
  });

  /// Taille totale de la position (marge * levier)
  double get positionSize => margin * leverage;

  /// P&L non réalisé au prix actuel
  double unrealizedPnl(double currentPrice) {
    final diff = currentPrice - entryPrice;
    final direction = side == PositionSide.long ? 1.0 : -1.0;
    return (diff / entryPrice) * positionSize * direction;
  }

  /// % de variation
  double pnlPercent(double currentPrice) {
    final diff = currentPrice - entryPrice;
    final direction = side == PositionSide.long ? 1.0 : -1.0;
    return (diff / entryPrice) * leverage * 100 * direction;
  }

  bool get isLong => side == PositionSide.long;

  @override
  List<Object?> get props =>
      [id, symbol, side, entryPrice, takeProfit, stopLoss, margin, leverage, openedAt];
}
