import 'package:equatable/equatable.dart';
import '../../../data/models/asset_type.dart';
import '../../../data/models/trade_position.dart';

abstract class MarketDataEvent extends Equatable {
  const MarketDataEvent();

  @override
  List<Object?> get props => [];
}

class InitMarketDataEvent extends MarketDataEvent {
  final AssetItem? initialAsset;
  const InitMarketDataEvent({this.initialAsset});

  @override
  List<Object?> get props => [initialAsset];
}

class SelectAssetEvent extends MarketDataEvent {
  final AssetItem asset;
  const SelectAssetEvent(this.asset);

  @override
  List<Object?> get props => [asset];
}

class ChangeTimeframeEvent extends MarketDataEvent {
  final String timeframe;
  const ChangeTimeframeEvent(this.timeframe);

  @override
  List<Object?> get props => [timeframe];
}

class ChangePeriodEvent extends MarketDataEvent {
  final String period;
  const ChangePeriodEvent(this.period);

  @override
  List<Object?> get props => [period];
}

class RefreshWatchlistEvent extends MarketDataEvent {}

class LivePriceTickEvent extends MarketDataEvent {
  final Map<String, double> priceUpdates;
  const LivePriceTickEvent(this.priceUpdates);

  @override
  List<Object?> get props => [priceUpdates];
}

class ToggleWatchlistCategoryEvent extends MarketDataEvent {
  final String category;
  const ToggleWatchlistCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class FilterWatchlistEvent extends MarketDataEvent {
  final String query;
  const FilterWatchlistEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectDrawingToolEvent extends MarketDataEvent {
  final String tool;
  const SelectDrawingToolEvent(this.tool);

  @override
  List<Object?> get props => [tool];
}

class SaveApiKeysEvent extends MarketDataEvent {
  final String? twelveDataKey;
  final String? finnhubKey;
  final String? alphaVantageKey;

  const SaveApiKeysEvent({
    this.twelveDataKey,
    this.finnhubKey,
    this.alphaVantageKey,
  });

  @override
  List<Object?> get props => [twelveDataKey, finnhubKey, alphaVantageKey];
}

class OpenPositionEvent extends MarketDataEvent {
  final TradePosition position;
  const OpenPositionEvent(this.position);

  @override
  List<Object?> get props => [position];
}

class ClosePositionEvent extends MarketDataEvent {
  final String positionId;
  const ClosePositionEvent(this.positionId);

  @override
  List<Object?> get props => [positionId];
}
