import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/market_data_service.dart';
import '../../../data/models/asset_type.dart';
import '../../../data/models/trade_position.dart';
import 'market_data_event.dart';
import 'market_data_state.dart';

class MarketDataBloc
    extends Bloc<MarketDataEvent, MarketDataState> {
  final MarketDataService marketDataService;

  StreamSubscription<Map<String, double>>?
      _priceSubscription;

  MarketDataBloc({
    required this.marketDataService,
  }) : super(
          MarketDataState(
            currentAsset: AssetCatalog.defaultAsset,
          ),
        ) {
    on<InitMarketDataEvent>(_onInit);
    on<SelectAssetEvent>(_onSelectAsset);
    on<ChangeTimeframeEvent>(_onChangeTimeframe);
    on<ChangePeriodEvent>(_onChangePeriod);
    on<RefreshWatchlistEvent>(_onRefreshWatchlist);
    on<LivePriceTickEvent>(_onLivePriceTick);
    on<ToggleWatchlistCategoryEvent>(
      _onToggleWatchlistCategory,
    );
    on<FilterWatchlistEvent>(_onFilterWatchlist);
    on<SelectDrawingToolEvent>(_onSelectDrawingTool);
    on<SaveApiKeysEvent>(_onSaveApiKeys);
    on<OpenPositionEvent>(_onOpenPosition);
    on<ClosePositionEvent>(_onClosePosition);

    _listenToPriceStream();
  }

  // ============================================================
  // STREAM
  // ============================================================

  void _listenToPriceStream() {
    _priceSubscription?.cancel();

    _priceSubscription =
        marketDataService.priceStream.listen(
      (updates) {
        add(
          LivePriceTickEvent(updates),
        );
      },
    );
  }

  // ============================================================
  // INIT
  // ============================================================

  Future<void> _onInit(
    InitMarketDataEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    emit(
      state.copyWith(
        status: MarketDataStatus.loading,
      ),
    );

    try {
      // Charger les clés sauvegardées
      await marketDataService.init();

      final asset =
          event.initialAsset ?? state.currentAsset;

      // --------------------------------------------------------
      // SEULEMENT 2 REQUÊTES API
      // --------------------------------------------------------

      final quote =
          await marketDataService.fetchQuote(asset);

      final candles =
          await marketDataService.fetchCandles(
        asset,
        state.timeframe,
      );

      // Watchlist = cache/fallback, aucune requête distante
      final watchlist =
          await marketDataService.fetchWatchlist(
        AssetCatalog.allAssets,
      );

      emit(
        state.copyWith(
          status: MarketDataStatus.loaded,
          currentAsset: asset,
          currentQuote: quote,
          candles: candles,
          watchlistQuotes: watchlist,
        ),
      );

      // PAS de polling automatique
    } catch (e) {
      emit(
        state.copyWith(
          status: MarketDataStatus.error,
          errorMessage:
              'Impossible de charger ${state.currentAsset.symbol}: $e',
        ),
      );
    }
  }

  // ============================================================
  // SELECT ASSET
  // ============================================================

  Future<void> _onSelectAsset(
    SelectAssetEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    emit(
      state.copyWith(
        status: MarketDataStatus.loading,
        currentAsset: event.asset,
      ),
    );

    try {
      final quote =
          await marketDataService.fetchQuote(
        event.asset,
      );

      final candles =
          await marketDataService.fetchCandles(
        event.asset,
        state.timeframe,
      );

      // Mettre aussi le quote dans la watchlist
      final watchlist =
          Map<String, dynamic>.from(
        state.watchlistQuotes,
      );

      watchlist[event.asset.symbol] = quote;

      emit(
        state.copyWith(
          status: MarketDataStatus.loaded,
          currentQuote: quote,
          candles: candles,
          watchlistQuotes: watchlist.cast(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MarketDataStatus.error,
          errorMessage:
              'Erreur pour ${event.asset.displayName}: $e',
        ),
      );
    }
  }

  // ============================================================
  // CHANGE TIMEFRAME
  // ============================================================

  Future<void> _onChangeTimeframe(
    ChangeTimeframeEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    emit(
      state.copyWith(
        timeframe: event.timeframe,
        status: MarketDataStatus.loading,
      ),
    );

    try {
      final candles =
          await marketDataService.fetchCandles(
        state.currentAsset,
        event.timeframe,
      );

      emit(
        state.copyWith(
          status: MarketDataStatus.loaded,
          candles: candles,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MarketDataStatus.error,
          errorMessage:
              'Erreur timeframe: $e',
        ),
      );
    }
  }

  // ============================================================
  // CHANGE PERIOD
  // ============================================================

  Future<void> _onChangePeriod(
    ChangePeriodEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    String timeframe;

    switch (event.period) {
      case '1D':
        timeframe = '5m';
        break;

      case '5D':
        timeframe = '15m';
        break;

      case '1M':
        timeframe = '1H';
        break;

      case '3M':
      case '6M':
      case 'YTD':
      case '1Y':
        timeframe = '1D';
        break;

      case '5Y':
      case 'ALL':
        timeframe = '1W';
        break;

      default:
        timeframe = '1D';
    }

    emit(
      state.copyWith(
        period: event.period,
        timeframe: timeframe,
        status: MarketDataStatus.loading,
      ),
    );

    try {
      final candles =
          await marketDataService.fetchCandles(
        state.currentAsset,
        timeframe,
      );

      emit(
        state.copyWith(
          status: MarketDataStatus.loaded,
          candles: candles,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MarketDataStatus.error,
          errorMessage:
              'Erreur période: $e',
        ),
      );
    }
  }

  // ============================================================
  // REFRESH WATCHLIST
  // ============================================================

  Future<void> _onRefreshWatchlist(
    RefreshWatchlistEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    try {
      // Ne fait PAS de nouvelles requêtes API
      final watchlist =
          await marketDataService.fetchWatchlist(
        AssetCatalog.allAssets,
      );

      emit(
        state.copyWith(
          watchlistQuotes: watchlist,
        ),
      );
    } catch (_) {
      // Rien
    }
  }

  // ============================================================
  // LIVE TICK
  // ============================================================

  void _onLivePriceTick(
    LivePriceTickEvent event,
    Emitter<MarketDataState> emit,
  ) {
    // Le live polling est désactivé pour le moment.
    // On garde cette méthode pour ne pas casser ton architecture.
  }

  // ============================================================
  // WATCHLIST CATEGORY
  // ============================================================

  void _onToggleWatchlistCategory(
    ToggleWatchlistCategoryEvent event,
    Emitter<MarketDataState> emit,
  ) {
    final collapsed =
        Set<String>.from(
      state.collapsedCategories,
    );

    if (collapsed.contains(event.category)) {
      collapsed.remove(event.category);
    } else {
      collapsed.add(event.category);
    }

    emit(
      state.copyWith(
        collapsedCategories: collapsed,
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onFilterWatchlist(
    FilterWatchlistEvent event,
    Emitter<MarketDataState> emit,
  ) {
    emit(
      state.copyWith(
        searchQuery: event.query,
      ),
    );
  }

  // ============================================================
  // DRAWING TOOL
  // ============================================================

  void _onSelectDrawingTool(
    SelectDrawingToolEvent event,
    Emitter<MarketDataState> emit,
  ) {
    emit(
      state.copyWith(
        selectedDrawingTool: event.tool,
      ),
    );
  }

  // ============================================================
  // SAVE API KEYS
  // ============================================================

  Future<void> _onSaveApiKeys(
    SaveApiKeysEvent event,
    Emitter<MarketDataState> emit,
  ) async {
    try {
      await marketDataService.setApiKeys(
        twelveDataKey: event.twelveDataKey,
        finnhubKey: event.finnhubKey,
        alphaVantageKey: event.alphaVantageKey,
      );

      // Recharger seulement l'actif actuel
      add(
        InitMarketDataEvent(
          initialAsset: state.currentAsset,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MarketDataStatus.error,
          errorMessage:
              'Erreur lors de la sauvegarde des clés: $e',
        ),
      );
    }
  }

  // ============================================================
  // OPEN POSITION
  // ============================================================

  void _onOpenPosition(
    OpenPositionEvent event,
    Emitter<MarketDataState> emit,
  ) {
    final updated = List<TradePosition>.from(state.openPositions)
      ..add(event.position);
    emit(state.copyWith(openPositions: updated));
  }

  // ============================================================
  // CLOSE POSITION
  // ============================================================

  void _onClosePosition(
    ClosePositionEvent event,
    Emitter<MarketDataState> emit,
  ) {
    final updated = state.openPositions
        .where((p) => p.id != event.positionId)
        .toList();
    emit(state.copyWith(openPositions: updated));
  }

  // ============================================================
  // CLOSE
  // ============================================================

  @override
  Future<void> close() {
    _priceSubscription?.cancel();
    marketDataService.dispose();

    return super.close();
  }
}