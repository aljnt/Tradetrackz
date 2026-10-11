import 'package:equatable/equatable.dart';
import '../../../data/models/asset_type.dart';
import '../../../data/models/candle.dart';
import '../../../data/models/quote.dart';
import '../../../data/models/trade_position.dart';

enum MarketDataStatus { initial, loading, loaded, error }

class MarketDataState extends Equatable {
  final MarketDataStatus status;
  final AssetItem currentAsset;
  final Quote? currentQuote;
  final List<Candle> candles;
  final String timeframe;
  final String period;
  final Map<String, Quote> watchlistQuotes;
  final Set<String> collapsedCategories;
  final String searchQuery;
  final String selectedDrawingTool;
  final bool isStreaming;
  final String? errorMessage;
  final Map<String, bool> priceFlashMap; // symbol -> isUp
  final List<TradePosition> openPositions; // positions ouvertes

  const MarketDataState({
    this.status = MarketDataStatus.initial,
    required this.currentAsset,
    this.currentQuote,
    this.candles = const [],
    this.timeframe = '1D',
    this.period = '1D',
    this.watchlistQuotes = const {},
    this.collapsedCategories = const {},
    this.searchQuery = '',
    this.selectedDrawingTool = 'cursor',
    this.isStreaming = true,
    this.errorMessage,
    this.priceFlashMap = const {},
    this.openPositions = const [],
  });

  MarketDataState copyWith({
    MarketDataStatus? status,
    AssetItem? currentAsset,
    Quote? currentQuote,
    List<Candle>? candles,
    String? timeframe,
    String? period,
    Map<String, Quote>? watchlistQuotes,
    Set<String>? collapsedCategories,
    String? searchQuery,
    String? selectedDrawingTool,
    bool? isStreaming,
    String? errorMessage,
    Map<String, bool>? priceFlashMap,
    List<TradePosition>? openPositions,
  }) {
    return MarketDataState(
      status: status ?? this.status,
      currentAsset: currentAsset ?? this.currentAsset,
      currentQuote: currentQuote ?? this.currentQuote,
      candles: candles ?? this.candles,
      timeframe: timeframe ?? this.timeframe,
      period: period ?? this.period,
      watchlistQuotes: watchlistQuotes ?? this.watchlistQuotes,
      collapsedCategories: collapsedCategories ?? this.collapsedCategories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDrawingTool: selectedDrawingTool ?? this.selectedDrawingTool,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: errorMessage,
      priceFlashMap: priceFlashMap ?? this.priceFlashMap,
      openPositions: openPositions ?? this.openPositions,
    );
  }

  /// Positions ouvertes pour l'actif actuellement affiché
  List<TradePosition> get currentAssetPositions =>
      openPositions.where((p) => p.symbol == currentAsset.symbol).toList();

  @override
  List<Object?> get props => [
        status,
        currentAsset,
        currentQuote,
        candles,
        timeframe,
        period,
        watchlistQuotes,
        collapsedCategories,
        searchQuery,
        selectedDrawingTool,
        isStreaming,
        errorMessage,
        priceFlashMap,
        openPositions,
      ];
}
