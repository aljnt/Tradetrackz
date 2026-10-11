import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/datasources/market_data_service.dart';
import '../../../data/models/asset_type.dart';
import '../../../data/models/candle.dart';
import '../../../data/models/trade_position.dart';
import '../../blocs/market/market_data_bloc.dart';
import '../../blocs/market/market_data_event.dart';
import '../../blocs/market/market_data_state.dart';

class TradePage extends StatelessWidget {
  final AssetItem? initialAsset;

  const TradePage({super.key, this.initialAsset});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MarketDataBloc(
        marketDataService: MarketDataService(),
      )..add(InitMarketDataEvent(initialAsset: initialAsset ?? AssetCatalog.defaultAsset)),
      child: const _TradePageContent(),
    );
  }
}

class _TradePageContent extends StatefulWidget {
  const _TradePageContent();

  @override
  State<_TradePageContent> createState() => _TradePageContentState();
}

class _TradePageContentState extends State<_TradePageContent> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int? _hoveredCandleIndex;
  Offset? _crosshairPosition;

  final List<DrawingElement> _drawings = [];
  ChartPoint? _drawingStartPoint;
  ChartPoint? _drawingEndPoint;
  bool _isDrawing = false;

  final List<String> _timeframes = ['1m', '5m', '15m', '1H', '4H', '1D', '1W'];
  final List<String> _periods = ['1D', '5D', '1M', '3M', '6M', 'YTD', '1Y', '5Y', 'ALL'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MarketDataBloc, MarketDataState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.errorMessage!)),
                ],
              ),
              backgroundColor: const Color(0xFF1E222D),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0E12),
          body: SafeArea(
            child: Column(
              children: [
                // ── TradingView Header Bar ──
                _buildTopHeader(context, state),
                // ── Subheader OHLC + Status ribbon ──
                _buildOhlcRibbon(context, state),
                const Divider(height: 1, color: Color(0xFF1E222D)),

                // ── Zone de contenu principale (Responsive) ──
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 960;
                      if (isDesktop) {
                        return _buildDesktopLayout(context, state);
                      } else {
                        return _buildMobileLayout(context, state);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. TOP HEADER (Symbole, Timeframes, Actions & API Key)
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context, MarketDataState state) {
    final asset = state.currentAsset;
    final quote = state.currentQuote;
    final priceStr = quote != null ? asset.formatPrice(quote.price) : '---';
    final isPositive = quote?.isPositive ?? true;
    final changePctStr = quote != null ? asset.formatPercent(quote.changePercent) : '';

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF131722),
        border: Border(bottom: BorderSide(color: Color(0xFF1E222D), width: 1)),
      ),
      child: Row(
        children: [
          // Bouton retour
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFFD1D4DC)),
            tooltip: 'Retour',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),

          // Sélecteur d'Actif (Dropdown Pill)
          InkWell(
            onTap: () => _openAssetSelectorModal(context, state),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2A2E39)),
              ),
              child: Row(
                children: [
                  Icon(asset.iconData, size: 18, color: asset.iconColor),
                  const SizedBox(width: 8),
                  Text(
                    asset.symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2E39),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      asset.exchange,
                      style: const TextStyle(color: Color(0xFF787B86), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF787B86)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Sélecteur de Timeframes (1m, 5m, 15m, 1H, 4H, 1D, 1W)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _timeframes.map((tf) {
                  final isSelected = tf == state.timeframe;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () {
                        context.read<MarketDataBloc>().add(ChangeTimeframeEvent(tf));
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2962FF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tf,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF787B86),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Badge Live Prix Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isPositive ? const Color(0xFF089981) : const Color(0xFFF23645)).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (isPositive ? const Color(0xFF089981) : const Color(0xFFF23645)).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Text(
                  priceStr,
                  style: TextStyle(
                    color: isPositive ? const Color(0xFF089981) : const Color(0xFFF23645),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  changePctStr,
                  style: TextStyle(
                    color: isPositive ? const Color(0xFF089981) : const Color(0xFFF23645),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Bouton Configuration Clés API
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined, size: 18, color: Color(0xFFD1D4DC)),
            tooltip: 'Configurer les clés API (TwelveData / Finnhub)',
            onPressed: () => _openApiKeyDialog(context),
          ),

          // Bouton Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFD1D4DC)),
            tooltip: 'Rafraîchir les cotations',
            onPressed: () {
              context.read<MarketDataBloc>().add(RefreshWatchlistEvent());
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. OHLC RIBBON (TradingView Bar: O / H / L / C / Vol / Statut)
  // ─────────────────────────────────────────────────────────────
  Widget _buildOhlcRibbon(BuildContext context, MarketDataState state) {
    final asset = state.currentAsset;
    final quote = state.currentQuote;
    final candles = state.candles;

    Candle? currentCandle;
    if (_hoveredCandleIndex != null &&
        _hoveredCandleIndex! >= 0 &&
        _hoveredCandleIndex! < candles.length) {
      currentCandle = candles[_hoveredCandleIndex!];
    } else if (candles.isNotEmpty) {
      currentCandle = candles.last;
    }

    final open = currentCandle?.open ?? quote?.open ?? 0.0;
    final high = currentCandle?.high ?? quote?.high ?? 0.0;
    final low = currentCandle?.low ?? quote?.low ?? 0.0;
    final close = currentCandle?.close ?? quote?.price ?? 0.0;
    final vol = currentCandle?.volume ?? quote?.volume ?? 0.0;
    final isBull = close >= open;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF131722),
      child: Row(
        children: [
          Text(
            '${asset.symbol} · ${state.timeframe}',
            style: const TextStyle(color: Color(0xFFD1D4DC), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 14),
          _buildOhlcItem('O', asset.formatPrice(open)),
          const SizedBox(width: 10),
          _buildOhlcItem('H', asset.formatPrice(high), color: const Color(0xFF089981)),
          const SizedBox(width: 10),
          _buildOhlcItem('L', asset.formatPrice(low), color: const Color(0xFFF23645)),
          const SizedBox(width: 10),
          _buildOhlcItem('C', asset.formatPrice(close), color: isBull ? const Color(0xFF089981) : const Color(0xFFF23645)),
          const SizedBox(width: 10),
          _buildOhlcItem('Vol', NumberFormat.compact().format(vol)),
          const Spacer(),

          // Statut du marché
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: (quote?.isMarketOpen ?? true) ? const Color(0xFF089981) : const Color(0xFF787B86),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                (quote?.isMarketOpen ?? true) ? 'Market Open' : 'Market Closed',
                style: TextStyle(
                  color: (quote?.isMarketOpen ?? true) ? const Color(0xFF089981) : const Color(0xFF787B86),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOhlcItem(String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: const TextStyle(color: Color(0xFF787B86), fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? const Color(0xFFD1D4DC),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. DESKTOP / TABLET LAYOUT (2 Colonnes : ~75% Chart + 25% Watchlist)
  // ─────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context, MarketDataState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Colonne gauche : TradingView Tools + Interactive Chart + Bottom Controls
        Expanded(
          flex: 75,
          child: Row(
            children: [
              // Toolbar verticale gauche TradingView
              _buildTradingViewLeftToolbar(context, state),
              const VerticalDivider(width: 1, color: Color(0xFF1E222D)),

              // Zone graphique
              Expanded(
                child: Column(
                  children: [
                    // Canvas du graphique avec boutons Buy/Sell flottants
                    Expanded(
                      child: Stack(
                        children: [
                          _buildChartCanvas(context, state),
                          // Boutons Buy/Sell flottants TradingView
                          Positioned(
                            top: 14,
                            left: 14,
                            child: _buildFloatingTradePills(context, state),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF1E222D)),
                    // Sélecteur de période en bas (1D, 5D, 1M, 3M, 6M, YTD, 1Y, 5Y, ALL)
                    _buildBottomPeriodSelector(context, state),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFF1E222D)),

        // Colonne droite : Watchlist & Détails de l'actif sélectionné
        Expanded(
          flex: 25,
          child: Container(
            color: const Color(0xFF131722),
            child: Column(
              children: [
                // Section Positions ouvertes (si existantes pour l'actif actuel)
                if (state.currentAssetPositions.isNotEmpty) ...[
                  _buildPositionsPanel(context, state),
                  const Divider(height: 1, color: Color(0xFF1E222D)),
                ],
                // Section Watchlist avec recherche
                Expanded(
                  flex: 6,
                  child: _buildWatchlistPanel(context, state),
                ),
                const Divider(height: 1, color: Color(0xFF1E222D)),
                // Section Détails Actif sélectionné
                Expanded(
                  flex: 4,
                  child: _buildAssetDetailsPanel(context, state),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. MOBILE LAYOUT (Graphique plein écran + Bottom Bar d'actions)
  // ─────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, MarketDataState state) {
    return Column(
      children: [
        // Graphique Candlestick avec boutons Buy/Sell
        Expanded(
          child: Stack(
            children: [
              _buildChartCanvas(context, state),
              Positioned(
                top: 10,
                left: 10,
                child: _buildFloatingTradePills(context, state),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF1E222D)),
        // Sélecteur de période
        _buildBottomPeriodSelector(context, state),
        const Divider(height: 1, color: Color(0xFF1E222D)),

        // Barre d'actions mobile
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF131722),
          child: Row(
            children: [
              // Bouton Watchlist
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.format_list_bulleted_rounded, size: 16, color: Color(0xFFD1D4DC)),
                  label: const Text('Watchlist', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2A2E39)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _openWatchlistBottomSheet(context, state),
                ),
              ),
              const SizedBox(width: 8),

              // Bouton Sell
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF23645),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _openOrderModal(context, state, isBuy: false),
                  child: const Text('SELL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),

              // Bouton Buy
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _openOrderModal(context, state, isBuy: true),
                  child: const Text('BUY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. TRADINGVIEW LEFT VERTICAL TOOLBAR (Outils de dessin)
  // ─────────────────────────────────────────────────────────────
  Widget _buildTradingViewLeftToolbar(BuildContext context, MarketDataState state) {
    final tools = [
      {'id': 'cursor', 'icon': Icons.near_me_outlined, 'tooltip': 'Curseur'},
      {'id': 'trendline', 'icon': Icons.timeline_rounded, 'tooltip': 'Ligne de tendance'},
      {'id': 'fib', 'icon': Icons.stacked_line_chart_rounded, 'tooltip': 'Retracements de Fibonacci'},
      {'id': 'text', 'icon': Icons.title_rounded, 'tooltip': 'Texte & Annotation'},
      {'id': 'measure', 'icon': Icons.straighten_rounded, 'tooltip': 'Règle de mesure'},
      {'id': 'trash', 'icon': Icons.delete_outline_rounded, 'tooltip': 'Effacer les dessins'},
    ];

    return Container(
      width: 44,
      color: const Color(0xFF131722),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...tools.map((t) {
            final isSelected = state.selectedDrawingTool == t['id'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: IconButton(
                icon: Icon(
                  t['icon'] as IconData,
                  size: 20,
                  color: isSelected ? const Color(0xFF2962FF) : const Color(0xFF787B86),
                ),
                tooltip: t['tooltip'] as String,
                onPressed: () {
                  if (t['id'] == 'trash') {
                    setState(() {
                      _drawings.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dessins nettoyés'), duration: Duration(seconds: 1)),
                    );
                  } else {
                    context.read<MarketDataBloc>().add(SelectDrawingToolEvent(t['id'] as String));
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 6. BOUTONS FLOTTANTS BUY / SELL TRADINGVIEW
  // ─────────────────────────────────────────────────────────────
  Widget _buildFloatingTradePills(BuildContext context, MarketDataState state) {
    final asset = state.currentAsset;
    final quote = state.currentQuote;
    final bid = quote != null ? asset.formatPrice(quote.bidPrice) : '---';
    final ask = quote != null ? asset.formatPrice(quote.askPrice) : '---';
    final spread = quote != null ? quote.spread.toStringAsFixed(asset.type == AssetType.forex ? 5 : 2) : '0.00';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2E39)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton SELL
          InkWell(
            onTap: () => _openOrderModal(context, state, isBuy: false),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFF2A2E39))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('SELL', style: TextStyle(color: Color(0xFFF23645), fontSize: 10, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(bid, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),

          // Spread au milieu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('SPREAD', style: TextStyle(color: Color(0xFF787B86), fontSize: 8, fontWeight: FontWeight.w600)),
                Text(spread, style: const TextStyle(color: Color(0xFFD1D4DC), fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // Bouton BUY
          InkWell(
            onTap: () => _openOrderModal(context, state, isBuy: true),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Color(0xFF2A2E39))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('BUY', style: TextStyle(color: Color(0xFF2962FF), fontSize: 10, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(ask, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 7. CANVAS GRAPHIQUE CANDLESTICK & VOLUME (TradingView Style)
  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  // 7. CANVAS GRAPHIQUE CANDLESTICK & VOLUME (TradingView Style)
  // ─────────────────────────────────────────────────────────────
  Widget _buildChartCanvas(BuildContext context, MarketDataState state) {
    if (state.status == MarketDataStatus.loading && state.candles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2962FF)),
      );
    }

    if (state.candles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.show_chart_rounded, size: 48, color: Color(0xFF787B86)),
            const SizedBox(height: 12),
            const Text('Aucune donnée de chandelier disponible', style: TextStyle(color: Color(0xFF787B86))),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<MarketDataBloc>().add(InitMarketDataEvent(initialAsset: state.currentAsset)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final candles = state.candles;
    final quote = state.currentQuote;
    final currentPrice = quote?.price ?? (candles.isNotEmpty ? candles.last.close : 0.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final rightMargin = 70.0;
        final bottomMargin = 26.0;
        final chartWidth = width - rightMargin;
        final chartHeight = height - bottomMargin;
        final volumeHeight = chartHeight * 0.22;
        final priceChartHeight = chartHeight - volumeHeight;

        double minPrice = double.infinity;
        double maxPrice = -double.infinity;
        for (final c in candles) {
          if (c.low < minPrice) minPrice = c.low;
          if (c.high > maxPrice) maxPrice = c.high;
        }
        if (minPrice == maxPrice) {
          minPrice -= 1;
          maxPrice += 1;
        }
        final pricePadding = (maxPrice - minPrice) * 0.08;
        minPrice -= pricePadding;
        maxPrice += pricePadding;

        final selectedTool = state.selectedDrawingTool;

        return GestureDetector(
          onPanDown: (details) {
            if (selectedTool == 'cursor') {
              _updateCrosshair(details.localPosition);
            } else if (selectedTool == 'trendline' || selectedTool == 'fib' || selectedTool == 'measure') {
              final pt = _getChartPointFromOffset(details.localPosition, chartWidth, priceChartHeight, minPrice, maxPrice, candles);
              setState(() {
                _drawingStartPoint = pt;
                _drawingEndPoint = pt;
                _isDrawing = true;
              });
            } else if (selectedTool == 'text') {
              final pt = _getChartPointFromOffset(details.localPosition, chartWidth, priceChartHeight, minPrice, maxPrice, candles);
              _showTextAnnotationDialog(context).then((text) {
                if (text != null && text.trim().isNotEmpty) {
                  setState(() {
                    _drawings.add(TextElement(pt, text.trim()));
                  });
                }
                context.read<MarketDataBloc>().add(const SelectDrawingToolEvent('cursor'));
              });
            }
          },
          onPanUpdate: (details) {
            if (selectedTool == 'cursor') {
              _updateCrosshair(details.localPosition);
            } else if (_isDrawing) {
              final pt = _getChartPointFromOffset(details.localPosition, chartWidth, priceChartHeight, minPrice, maxPrice, candles);
              setState(() {
                _drawingEndPoint = pt;
                _crosshairPosition = details.localPosition;
              });
            }
          },
          onPanEnd: (_) {
            if (selectedTool == 'cursor') {
              setState(() {
                _crosshairPosition = null;
                _hoveredCandleIndex = null;
              });
            } else if (_isDrawing && _drawingStartPoint != null && _drawingEndPoint != null) {
              setState(() {
                if (selectedTool == 'trendline') {
                  _drawings.add(TrendLineElement(_drawingStartPoint!, _drawingEndPoint!));
                } else if (selectedTool == 'fib') {
                  _drawings.add(FibonacciElement(_drawingStartPoint!, _drawingEndPoint!));
                } else if (selectedTool == 'measure') {
                  _drawings.add(RulerElement(_drawingStartPoint!, _drawingEndPoint!));
                }
                _isDrawing = false;
                _drawingStartPoint = null;
                _drawingEndPoint = null;
                _crosshairPosition = null;
              });
              context.read<MarketDataBloc>().add(const SelectDrawingToolEvent('cursor'));
            }
          },
          onTapUp: (details) {
            if (selectedTool == 'cursor') {
              _updateCrosshair(details.localPosition);
            }
          },
          child: Container(
            color: const Color(0xFF131722),
            child: CustomPaint(
              size: Size.infinite,
              painter: _TradingViewCandlePainter(
                candles: candles,
                currentPrice: currentPrice,
                asset: state.currentAsset,
                crosshairPosition: _crosshairPosition,
                drawings: _drawings,
                drawingStart: _drawingStartPoint,
                drawingEnd: _drawingEndPoint,
                selectedTool: selectedTool,
                positions: state.currentAssetPositions,
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateCrosshair(Offset localPos) {
    setState(() {
      _crosshairPosition = localPos;
    });
  }

  ChartPoint _getChartPointFromOffset(
    Offset offset,
    double chartWidth,
    double priceChartHeight,
    double minPrice,
    double maxPrice,
    List<Candle> candles,
  ) {
    if (candles.isEmpty) return ChartPoint(0, 0.0);
    int index = (offset.dx / (chartWidth / candles.length)).floor();
    index = index.clamp(0, candles.length - 1);
    final priceRange = maxPrice - minPrice;
    final price = priceRange == 0 ? minPrice : maxPrice - (offset.dy / priceChartHeight) * priceRange;
    return ChartPoint(index, price);
  }

  Future<String?> _showTextAnnotationDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E222D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Ajouter une note', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Écrire l\'annotation...',
              hintStyle: TextStyle(color: Color(0xFF787B86)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2962FF))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF787B86))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2962FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 8. SÉLECTEUR DE PÉRIODE EN BAS (1D, 5D, 1M, 3M, 6M, YTD, 1Y, 5Y, ALL)
  // ─────────────────────────────────────────────────────────────
  Widget _buildBottomPeriodSelector(BuildContext context, MarketDataState state) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF131722),
      child: Row(
        children: [
          // Boutons Périodes
          ..._periods.map((p) {
            final isSelected = p == state.period;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () {
                  context.read<MarketDataBloc>().add(ChangePeriodEvent(p));
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2A2E39) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF787B86),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),

          // Info Timezone & TradingView logo / watermark
          Row(
            children: [
              Text(
                DateFormat('HH:mm:ss').format(DateTime.now()),
                style: const TextStyle(color: Color(0xFF787B86), fontSize: 11, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 6),
              const Text('UTC+1', style: TextStyle(color: Color(0xFF787B86), fontSize: 10)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E222D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ADJ',
                  style: TextStyle(color: Color(0xFF787B86), fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 9. WATCHLIST PANEL (Catégories collapsibles & Ticker live)
  // ─────────────────────────────────────────────────────────────
  Widget _buildWatchlistPanel(BuildContext context, MarketDataState state) {
    final categorized = AssetCatalog.categorizedAssets;

    return Column(
      children: [
        // Header Watchlist + Recherche
        Container(
          padding: const EdgeInsets.all(10),
          color: const Color(0xFF131722),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Watchlist',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Symbol / Last / Chg%',
                    style: TextStyle(color: Color(0xFF787B86), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Search input
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E222D),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2A2E39)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 16, color: Color(0xFF787B86)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          context.read<MarketDataBloc>().add(FilterWatchlistEvent(val));
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher actif (XAU, EUR, AAPL...)',
                          hintStyle: TextStyle(color: Color(0xFF787B86), fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          context.read<MarketDataBloc>().add(const FilterWatchlistEvent(''));
                        },
                        child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF787B86)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF1E222D)),

        // Liste des catégories et actifs
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: categorized.entries.map((entry) {
              final categoryName = entry.key;
              var items = entry.value;

              // Filtrage par recherche
              if (state.searchQuery.isNotEmpty) {
                items = items.where((a) {
                  final q = state.searchQuery.toUpperCase();
                  return a.symbol.toUpperCase().contains(q) ||
                      a.displayName.toUpperCase().contains(q) ||
                      a.fullName.toUpperCase().contains(q);
                }).toList();
                if (items.isEmpty) return const SizedBox.shrink();
              }

              final isCollapsed = state.collapsedCategories.contains(categoryName);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de catégorie collapsible
                  InkWell(
                    onTap: () {
                      context.read<MarketDataBloc>().add(ToggleWatchlistCategoryEvent(categoryName));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: const Color(0xFF1E222D).withValues(alpha: 0.5),
                      child: Row(
                        children: [
                          Icon(
                            isCollapsed ? Icons.chevron_right_rounded : Icons.expand_more_rounded,
                            size: 16,
                            color: const Color(0xFF787B86),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            categoryName,
                            style: const TextStyle(
                              color: Color(0xFF787B86),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${items.length}',
                            style: const TextStyle(color: Color(0xFF787B86), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Liste des actifs dans cette catégorie
                  if (!isCollapsed)
                    ...items.map((asset) {
                      final isSelected = asset.symbol == state.currentAsset.symbol;
                      final quote = state.watchlistQuotes[asset.symbol];
                      final price = quote?.price ?? 0.0;
                      final chgPct = quote?.changePercent ?? 0.0;
                      final isPos = chgPct >= 0;
                      final flashUp = state.priceFlashMap[asset.symbol];

                      return InkWell(
                        onTap: () {
                          context.read<MarketDataBloc>().add(SelectAssetEvent(asset));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2962FF).withValues(alpha: 0.15)
                                : (flashUp != null
                                    ? (flashUp
                                        ? const Color(0xFF089981).withValues(alpha: 0.12)
                                        : const Color(0xFFF23645).withValues(alpha: 0.12))
                                    : Colors.transparent),
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? const Color(0xFF2962FF) : Colors.transparent,
                                width: 3,
                              ),
                              bottom: const BorderSide(color: Color(0xFF1E222D), width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon de l'actif
                              Icon(asset.iconData, size: 16, color: asset.iconColor),
                              const SizedBox(width: 8),
                              // Symbol & Exchange
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      asset.displayName,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFFD1D4DC),
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      asset.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Color(0xFF787B86), fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),

                              // Prix + Chg%
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    price > 0 ? asset.formatPrice(price) : '---',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFFD1D4DC),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: (isPos ? const Color(0xFF089981) : const Color(0xFFF23645)).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      quote != null ? asset.formatPercent(chgPct) : '0.00%',
                                      style: TextStyle(
                                        color: isPos ? const Color(0xFF089981) : const Color(0xFFF23645),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 10. PANNEAU DÉTAIL ACTIF SÉLECTIONNÉ (Bas droite)
  // ─────────────────────────────────────────────────────────────
  Widget _buildAssetDetailsPanel(BuildContext context, MarketDataState state) {
    final asset = state.currentAsset;
    final quote = state.currentQuote;
    final price = quote?.price ?? 0.0;
    final isPos = quote?.isPositive ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec nom complet et secteur
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(asset.iconData, size: 24, color: asset.iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${asset.exchange} · ${asset.sector}',
                      style: const TextStyle(color: Color(0xFF787B86), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Prix en gros + Variation
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                asset.formatPrice(price),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 6),
              const Text('USD', style: TextStyle(color: Color(0xFF787B86), fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(
                quote != null ? '${asset.formatChange(quote.change)} (${asset.formatPercent(quote.changePercent)})' : '',
                style: TextStyle(
                  color: isPos ? const Color(0xFF089981) : const Color(0xFFF23645),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Grille des statistiques clés
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222D),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                _buildStatRow('Day High', quote != null ? asset.formatPrice(quote.high) : '---', 'Day Low',
                    quote != null ? asset.formatPrice(quote.low) : '---'),
                const Divider(height: 8, color: Color(0xFF2A2E39)),
                _buildStatRow('52W High', quote != null ? asset.formatPrice(quote.fiftyTwoWeekHigh) : '---', '52W Low',
                    quote != null ? asset.formatPrice(quote.fiftyTwoWeekLow) : '---'),
                const Divider(height: 8, color: Color(0xFF2A2E39)),
                _buildStatRow('Prev Close', quote != null ? asset.formatPrice(quote.previousClose) : '---', 'Volume',
                    quote != null ? NumberFormat.compact().format(quote.volume) : '---'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Boutons rapides d'ordre
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF23645),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openOrderModal(context, state, isBuy: false),
                  child: const Text('SHORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openOrderModal(context, state, isBuy: true),
                  child: const Text('LONG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String l1, String v1, String l2, String v2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l1, style: const TextStyle(color: Color(0xFF787B86), fontSize: 10)),
              Text(v1, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l2, style: const TextStyle(color: Color(0xFF787B86), fontSize: 10)),
              Text(v2, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 10b. PANNEAU POSITIONS OUVERTES
  // ─────────────────────────────────────────────────────────────
  Widget _buildPositionsPanel(BuildContext context, MarketDataState state) {
    final positions = state.currentAssetPositions;
    final quote = state.currentQuote;
    final asset = state.currentAsset;

    return Container(
      color: const Color(0xFF0D0E12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, size: 14, color: Color(0xFF2962FF)),
                const SizedBox(width: 6),
                Text(
                  'Positions ouvertes (${positions.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...positions.map((pos) {
            final currentPrice = quote?.price ?? pos.entryPrice;
            final pnl = pos.unrealizedPnl(currentPrice);
            final pnlPct = pos.pnlPercent(currentPrice);
            final isProfit = pnl >= 0;
            final sideColor = pos.isLong ? const Color(0xFF2962FF) : const Color(0xFFF23645);

            return Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: sideColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: sideColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pos.isLong ? '\u25b2 LONG' : '\u25bc SHORT',
                          style: TextStyle(color: sideColor, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${isProfit ? "+" : ""}\$${pnl.toStringAsFixed(2)} (${isProfit ? "+" : ""}${pnlPct.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: isProfit ? const Color(0xFF089981) : const Color(0xFFF23645),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Entree: ${asset.formatPrice(pos.entryPrice)}',
                          style: const TextStyle(color: Color(0xFF787B86), fontSize: 10)),
                      Text('x${pos.leverage.toInt()}',
                          style: const TextStyle(color: Color(0xFFD1D4DC), fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TP: ${asset.formatPrice(pos.takeProfit)}',
                          style: const TextStyle(color: Color(0xFF089981), fontSize: 10)),
                      Text('SL: ${asset.formatPrice(pos.stopLoss)}',
                          style: const TextStyle(color: Color(0xFFF23645), fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2A2E39)),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        context.read<MarketDataBloc>().add(ClosePositionEvent(pos.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Position ${pos.isLong ? "Long" : "Short"} ${pos.symbol} fermee'),
                            backgroundColor: const Color(0xFF1E222D),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text('Fermer la position',
                          style: TextStyle(color: Color(0xFF787B86), fontSize: 11)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 11. MODAL DE SÉLECTION D'ACTIFS RAPIDE
  // ─────────────────────────────────────────────────────────────
  void _openAssetSelectorModal(BuildContext context, MarketDataState state) {
    // ✅ FIX: Capture le bloc AVANT l'ouverture du modal pour éviter
    // le problème de contexte isolé dans le builder du BottomSheet.
    final bloc = context.read<MarketDataBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131722),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sélectionner un actif',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF787B86)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: AssetCatalog.allAssets.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E222D), height: 1),
                  itemBuilder: (_, idx) {
                    final asset = AssetCatalog.allAssets[idx];
                    final isSel = asset.symbol == state.currentAsset.symbol;
                    return ListTile(
                      dense: true,
                      leading: Icon(asset.iconData, color: asset.iconColor),
                      title: Text(
                        asset.symbol,
                        style: TextStyle(
                          color: isSel ? const Color(0xFF2962FF) : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(asset.fullName, style: const TextStyle(color: Color(0xFF787B86), fontSize: 11)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E222D),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(asset.exchange, style: const TextStyle(color: Color(0xFF787B86), fontSize: 10)),
                      ),
                      onTap: () {
                        // ✅ Utilise le bloc capturé, pas context.read depuis le sous-ctx
                        bloc.add(SelectAssetEvent(asset));
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 12. BOTTOM SHEET WATCHLIST (Pour Mobile)
  // ─────────────────────────────────────────────────────────────
  void _openWatchlistBottomSheet(BuildContext context, MarketDataState state) {
    // ✅ FIX: Enveloppe dans BlocProvider.value pour transmettre le BLoC
    // au contexte isolé du BottomSheet.
    final bloc = context.read<MarketDataBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131722),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<MarketDataBloc, MarketDataState>(
            builder: (innerCtx, innerState) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: _buildWatchlistPanel(innerCtx, innerState),
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 13. MODAL ORDER TICKET (BUY / SELL AVEC LEVERAGE ET TP/SL)
  // ─────────────────────────────────────────────────────────────
  void _openOrderModal(BuildContext context, MarketDataState state, {required bool isBuy}) {
    final asset = state.currentAsset;
    final quote = state.currentQuote;
    final price = quote?.price ?? 100.0;
    // ✅ Capture bloc ET messenger AVANT l'ouverture du modal
    final bloc = context.read<MarketDataBloc>();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131722),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _OrderTicketSheet(
          asset: asset,
          isBuy: isBuy,
          currentPrice: price,
          marketDataBloc: bloc,
          scaffoldMessenger: messenger,
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 14. DIALOG CONFIGURATION CLÉS API (TwelveData, Finnhub, AlphaVantage)
  // ─────────────────────────────────────────────────────────────
  void _openApiKeyDialog(BuildContext context) {
    final service = context.read<MarketDataBloc>().marketDataService;
    final twelveController = TextEditingController(text: service.twelveDataKey ?? '');
    final finnhubController = TextEditingController(text: service.finnhubKey ?? '');
    final alphaController = TextEditingController(text: service.alphaVantageKey ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131722),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A2E39)),
          ),
          title: Row(
            children: const [
              Icon(Icons.vpn_key_rounded, color: Color(0xFF2962FF), size: 22),
              SizedBox(width: 10),
              Text(
                'Configuration des APIs Réelles',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entrez vos clés API gratuites pour récupérer les données de marché en direct :',
                  style: TextStyle(color: Color(0xFFD1D4DC), fontSize: 12),
                ),
                const SizedBox(height: 16),

                // TwelveData (Prioritaire)
                const Text(
                  '1. TwelveData API Key (Forex, XAUUSD, CFD, Indices)',
                  style: TextStyle(color: Color(0xFFFFB800), fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: twelveController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'ex: 7a8b9c... (twelvedata.com)',
                    hintStyle: TextStyle(color: Color(0xFF787B86), fontSize: 12),
                    filled: true,
                    fillColor: Color(0xFF1E222D),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),

                // Finnhub
                const Text(
                  '2. Finnhub API Key (Indices SPX, NDQ, Stocks)',
                  style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: finnhubController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'ex: c12345... (finnhub.io)',
                    hintStyle: TextStyle(color: Color(0xFF787B86), fontSize: 12),
                    filled: true,
                    fillColor: Color(0xFF1E222D),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),

                // AlphaVantage
                const Text(
                  '3. Alpha Vantage Key (Backup)',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: alphaController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'ex: ALPHAVANTAGE_KEY',
                    hintStyle: TextStyle(color: Color(0xFF787B86), fontSize: 12),
                    filled: true,
                    fillColor: Color(0xFF1E222D),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Note : Si aucune clé n\'est entrée, un simulateur temps réel calibré est actif pour assurer la fluidité sans interruption.',
                  style: TextStyle(color: Color(0xFF787B86), fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF787B86))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF)),
              onPressed: () {
                context.read<MarketDataBloc>().add(
                      SaveApiKeysEvent(
                        twelveDataKey: twelveController.text.trim(),
                        finnhubKey: finnhubController.text.trim(),
                        alphaVantageKey: alphaController.text.trim(),
                      ),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Clés API sauvegardées avec succès !'),
                    backgroundColor: Color(0xFF089981),
                  ),
                );
              },
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CUSTOM PAINTER TRADINGVIEW CANDLESTICK + VOLUME + CROSSHAIR
// ─────────────────────────────────────────────────────────────────
class _TradingViewCandlePainter extends CustomPainter {
  final List<Candle> candles;
  final double currentPrice;
  final AssetItem asset;
  final Offset? crosshairPosition;
  final List<DrawingElement> drawings;
  final ChartPoint? drawingStart;
  final ChartPoint? drawingEnd;
  final String selectedTool;
  final List<TradePosition> positions; // ✅ Liste des positions ouvertes à afficher

  _TradingViewCandlePainter({
    required this.candles,
    required this.currentPrice,
    required this.asset,
    this.crosshairPosition,
    this.drawings = const [],
    this.drawingStart,
    this.drawingEnd,
    this.selectedTool = 'cursor',
    this.positions = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final rightMargin = 70.0; // espace pour l'axe Y des prix
    final bottomMargin = 26.0; // espace pour l'axe X des dates
    final chartWidth = size.width - rightMargin;
    final chartHeight = size.height - bottomMargin;
    final volumeHeight = chartHeight * 0.22; // 22% en bas pour volume
    final priceChartHeight = chartHeight - volumeHeight;

    // Calcul min/max prix
    double minPrice = double.infinity;
    double maxPrice = -double.infinity;
    double maxVolume = 0.0;

    for (final c in candles) {
      if (c.low < minPrice) minPrice = c.low;
      if (c.high > maxPrice) maxPrice = c.high;
      if (c.volume > maxVolume) maxVolume = c.volume;
    }

    if (minPrice == maxPrice) {
      minPrice -= 1;
      maxPrice += 1;
    }

    // Marge de confort Y
    final pricePadding = (maxPrice - minPrice) * 0.08;
    minPrice -= pricePadding;
    maxPrice += pricePadding;
    final priceRange = maxPrice - minPrice;

    // 1. Grille TradingView (horizontale et verticale)
    final gridPaint = Paint()
      ..color = const Color(0xFF1E222D)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const int horizontalGridLines = 6;
    for (int i = 0; i <= horizontalGridLines; i++) {
      final y = priceChartHeight * (i / horizontalGridLines);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);

      // Label de prix sur l'axe Y à droite
      final priceAtLine = maxPrice - (priceRange * (i / horizontalGridLines));
      final textSpan = TextSpan(
        text: asset.formatPrice(priceAtLine),
        style: const TextStyle(color: Color(0xFF787B86), fontSize: 10, fontFamily: 'monospace'),
      );
      final tp = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(chartWidth + 6, y - (tp.height / 2)));
    }

    // 2. Ligne horizontale du Prix Actuel (Current Price Line)
    final currentPriceY = priceChartHeight * (1 - (currentPrice - minPrice) / priceRange);
    final currentPricePaint = Paint()
      ..color = const Color(0xFFF23645).withValues(alpha: 0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Ligne pointillée
    double startX = 0;
    while (startX < chartWidth) {
      canvas.drawLine(Offset(startX, currentPriceY), Offset(startX + 4, currentPriceY), currentPricePaint);
      startX += 8;
    }

    // Badge prix actuel sur l'axe Y
    final currentPriceBadgeBg = Paint()..color = const Color(0xFFF23645);
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(chartWidth + 2, currentPriceY - 9, rightMargin - 4, 18),
      const Radius.circular(4),
    );
    canvas.drawRRect(badgeRect, currentPriceBadgeBg);

    final curPriceText = TextSpan(
      text: asset.formatPrice(currentPrice),
      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
    );
    final curPricePainter = TextPainter(text: curPriceText, textDirection: ui.TextDirection.ltr)..layout();
    curPricePainter.paint(canvas, Offset(chartWidth + 6, currentPriceY - (curPricePainter.height / 2)));

    // 3. Dessin des Chandelier (Wicks + Bodies) & Volume
    final effectiveCandleWidth = chartWidth / candles.length;
    final bodyWidth = math.max(2.0, effectiveCandleWidth * 0.7);

    const bullishColor = Color(0xFF089981);
    const bearishColor = Color(0xFFF23645);

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = (i * effectiveCandleWidth) + (effectiveCandleWidth / 2);
      final isBull = c.isBullish;
      final color = isBull ? bullishColor : bearishColor;

      final openY = priceChartHeight * (1 - (c.open - minPrice) / priceRange);
      final closeY = priceChartHeight * (1 - (c.close - minPrice) / priceRange);
      final highY = priceChartHeight * (1 - (c.high - minPrice) / priceRange);
      final lowY = priceChartHeight * (1 - (c.low - minPrice) / priceRange);

      // Mèche (Wick)
      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

      // Corps (Body)
      final topY = math.min(openY, closeY);
      final bottomY = math.max(openY, closeY);
      final height = math.max(1.5, bottomY - topY);

      final bodyPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(x - (bodyWidth / 2), topY, bodyWidth, height), bodyPaint);

      // Histogramme Volume
      if (maxVolume > 0) {
        final volBarHeight = (c.volume / maxVolume) * (volumeHeight - 8);
        final volY = chartHeight - volBarHeight;
        final volPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(x - (bodyWidth / 2), volY, bodyWidth, volBarHeight), volPaint);
      }

      // Labels de dates sur l'axe X (tous les N chandeliers)
      final step = math.max(1, (candles.length / 5).floor());
      if (i % step == 0) {
        final dateStr = DateFormat('dd MMM').format(c.time);
        final dateSpan = TextSpan(
          text: dateStr,
          style: const TextStyle(color: Color(0xFF787B86), fontSize: 9),
        );
        final datePainter = TextPainter(text: dateSpan, textDirection: ui.TextDirection.ltr)..layout();
        datePainter.paint(canvas, Offset(x - (datePainter.width / 2), chartHeight + 6));
      }
    }

    // Dessiner les dessins finalisés
    for (final drawing in drawings) {
      drawing.draw(canvas, size, minPrice, maxPrice, chartWidth, priceChartHeight, candles);
    }

    // ✅ DESSIN DES POSITIONS OUVERTES SUR LE CHART (Entry, TP, SL)
    for (final pos in positions) {
      final sideColor = pos.isLong ? const Color(0xFF2962FF) : const Color(0xFFF23645);
      
      // 1. Ligne du Prix d'Entrée
      if (pos.entryPrice >= minPrice && pos.entryPrice <= maxPrice) {
        final entryY = priceChartHeight * (1 - (pos.entryPrice - minPrice) / priceRange);
        
        final entryPaint = Paint()
          ..color = sideColor
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
          
        // Ligne pointillée
        double startX = 0;
        while (startX < chartWidth) {
          canvas.drawLine(Offset(startX, entryY), Offset(startX + 4, entryY), entryPaint);
          startX += 8;
        }

        // Badge d'étiquette d'entrée
        final labelSpan = TextSpan(
          text: ' ${pos.isLong ? "LONG" : "SHORT"} x${pos.leverage.toInt()} ',
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
        );
        final labelPainter = TextPainter(text: labelSpan, textDirection: ui.TextDirection.ltr)..layout();
        final labelBgPaint = Paint()..color = sideColor;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(8, entryY - 7, labelPainter.width, 14),
            const Radius.circular(3),
          ),
          labelBgPaint,
        );
        labelPainter.paint(canvas, Offset(8, entryY - 7));
      }

      // 2. Ligne du Take Profit (TP)
      if (pos.takeProfit >= minPrice && pos.takeProfit <= maxPrice) {
        final tpY = priceChartHeight * (1 - (pos.takeProfit - minPrice) / priceRange);
        final tpPaint = Paint()
          ..color = const Color(0xFF089981).withValues(alpha: 0.7)
          ..strokeWidth = 1.0;
        
        // Ligne fine tiretée
        double startX = 0;
        while (startX < chartWidth) {
          canvas.drawLine(Offset(startX, tpY), Offset(startX + 6, tpY), tpPaint);
          startX += 12;
        }

        final tpSpan = TextSpan(
          text: ' TP: ${asset.formatPrice(pos.takeProfit)} ',
          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
        );
        final tpPainter = TextPainter(text: tpSpan, textDirection: ui.TextDirection.ltr)..layout();
        final tpBgPaint = Paint()..color = const Color(0xFF089981);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(8, tpY - 6, tpPainter.width, 12),
            const Radius.circular(3),
          ),
          tpBgPaint,
        );
        tpPainter.paint(canvas, Offset(8, tpY - 6));
      }

      // 3. Ligne du Stop Loss (SL)
      if (pos.stopLoss >= minPrice && pos.stopLoss <= maxPrice) {
        final slY = priceChartHeight * (1 - (pos.stopLoss - minPrice) / priceRange);
        final slPaint = Paint()
          ..color = const Color(0xFFF23645).withValues(alpha: 0.7)
          ..strokeWidth = 1.0;

        // Ligne fine tiretée
        double startX = 0;
        while (startX < chartWidth) {
          canvas.drawLine(Offset(startX, slY), Offset(startX + 6, slY), slPaint);
          startX += 12;
        }

        final slSpan = TextSpan(
          text: ' SL: ${asset.formatPrice(pos.stopLoss)} ',
          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
        );
        final slPainter = TextPainter(text: slSpan, textDirection: ui.TextDirection.ltr)..layout();
        final slBgPaint = Paint()..color = const Color(0xFFF23645);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(8, slY - 6, slPainter.width, 12),
            const Radius.circular(3),
          ),
          slBgPaint,
        );
        slPainter.paint(canvas, Offset(8, slY - 6));
      }
    }

    // Dessiner le dessin actif en cours de création
    if (drawingStart != null && drawingEnd != null) {
      DrawingElement? preview;
      if (selectedTool == 'trendline') {
        preview = TrendLineElement(drawingStart!, drawingEnd!);
      } else if (selectedTool == 'fib') {
        preview = FibonacciElement(drawingStart!, drawingEnd!);
      } else if (selectedTool == 'measure') {
        preview = RulerElement(drawingStart!, drawingEnd!);
      }
      preview?.draw(canvas, size, minPrice, maxPrice, chartWidth, priceChartHeight, candles);
    }

    // 4. Crosshair Cursor interactif (si touché)
    if (crosshairPosition != null) {
      final crossX = crosshairPosition!.dx.clamp(0.0, chartWidth);
      final crossY = crosshairPosition!.dy.clamp(0.0, priceChartHeight);

      final crossPaint = Paint()
        ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.6)
        ..strokeWidth = 0.9
        ..style = PaintingStyle.stroke;

      // Ligne horizontale
      canvas.drawLine(Offset(0, crossY), Offset(chartWidth, crossY), crossPaint);
      // Ligne verticale
      canvas.drawLine(Offset(crossX, 0), Offset(crossX, chartHeight), crossPaint);

      // Badge Prix du crosshair sur l'axe Y
      final crossPrice = maxPrice - (priceRange * (crossY / priceChartHeight));
      final crossPriceBadgeBg = Paint()..color = const Color(0xFF2A2E39);
      final crossBadgeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(chartWidth + 2, crossY - 9, rightMargin - 4, 18),
        const Radius.circular(4),
      );
      canvas.drawRRect(crossBadgeRect, crossPriceBadgeBg);

      final crossPriceText = TextSpan(
        text: asset.formatPrice(crossPrice),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
      );
      final crossPainter = TextPainter(text: crossPriceText, textDirection: ui.TextDirection.ltr)..layout();
      crossPainter.paint(canvas, Offset(chartWidth + 6, crossY - (crossPainter.height / 2)));
    }
  }

  @override
  bool shouldRepaint(covariant _TradingViewCandlePainter oldDelegate) {
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────
// ORDER TICKET BOTTOM SHEET (Exécution rapide d'ordre de trading)
// ─────────────────────────────────────────────────────────────────
class _OrderTicketSheet extends StatefulWidget {
  final AssetItem asset;
  final bool isBuy;
  final double currentPrice;
  // ✅ FIX: Reçoit le ScaffoldMessengerState capturé avant le pop
  final ScaffoldMessengerState scaffoldMessenger;
  // ✅ Reçoit le bloc pour y dispatcher l'ouverture de position
  final MarketDataBloc marketDataBloc;

  const _OrderTicketSheet({
    required this.asset,
    required this.isBuy,
    required this.currentPrice,
    required this.scaffoldMessenger,
    required this.marketDataBloc,
  });

  @override
  State<_OrderTicketSheet> createState() => _OrderTicketSheetState();
}

class _OrderTicketSheetState extends State<_OrderTicketSheet> {
  final TextEditingController _amountController = TextEditingController(text: '1000');
  double _leverage = 20.0;
  late double _tpPrice;
  late double _slPrice;
  int _selectedPct = 0;

  @override
  void initState() {
    super.initState();
    final p = widget.currentPrice;
    if (widget.isBuy) {
      _tpPrice = p * 1.05;
      _slPrice = p * 0.97;
    } else {
      _tpPrice = p * 0.95;
      _slPrice = p * 1.03;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text) ?? 1000.0;
    final positionSize = amount * _leverage;
    final liquidationPrice = widget.isBuy
        ? widget.currentPrice * (1 - (1 / _leverage))
        : widget.currentPrice * (1 + (1 / _leverage));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Ticket
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (widget.isBuy ? const Color(0xFF2962FF) : const Color(0xFFF23645)).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.isBuy ? 'OPEN LONG 📈' : 'OPEN SHORT 📉',
                        style: TextStyle(
                          color: widget.isBuy ? const Color(0xFF2962FF) : const Color(0xFFF23645),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.asset.symbol,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF787B86)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Montant de la marge
            const Text('Montant de l\'ordre (Marge USD)', style: TextStyle(color: Color(0xFFD1D4DC), fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2E39)),
              ),
              child: Row(
                children: [
                  const Text('\$', style: TextStyle(color: Color(0xFF787B86), fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Sélecteur rapide de pourcentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [25, 50, 75, 100].map((pct) {
                final isSel = _selectedPct == pct;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSel ? const Color(0xFF2A2E39) : Colors.transparent,
                        side: BorderSide(color: isSel ? const Color(0xFF2962FF) : const Color(0xFF2A2E39)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedPct = pct;
                          _amountController.text = (2500 * pct / 100).toStringAsFixed(0);
                        });
                      },
                      child: Text(
                        pct == 100 ? 'MAX' : '$pct%',
                        style: TextStyle(
                          color: isSel ? const Color(0xFF2962FF) : const Color(0xFFD1D4DC),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Effet de Levier (Leverage Slider)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Levier', style: TextStyle(color: Color(0xFFD1D4DC), fontSize: 12)),
                Text('${_leverage.toInt()}x', style: const TextStyle(color: Color(0xFF2962FF), fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF2962FF),
                inactiveTrackColor: const Color(0xFF2A2E39),
                thumbColor: Colors.white,
                overlayColor: const Color(0xFF2962FF).withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _leverage,
                min: 1,
                max: 100,
                divisions: 99,
                onChanged: (val) => setState(() => _leverage = val),
              ),
            ),
            const SizedBox(height: 8),

            // Take Profit / Stop Loss
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Take Profit (TP)', style: TextStyle(color: Color(0xFF089981), fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E222D),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2A2E39)),
                        ),
                        child: Text(widget.asset.formatPrice(_tpPrice), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stop Loss (SL)', style: TextStyle(color: Color(0xFFF23645), fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E222D),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2A2E39)),
                        ),
                        child: Text(widget.asset.formatPrice(_slPrice), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Estimation récapitulative
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Taille de la position', style: TextStyle(color: Color(0xFF787B86), fontSize: 11)),
                      Text('\$${positionSize.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Prix de liquidation estimé', style: TextStyle(color: Color(0xFF787B86), fontSize: 11)),
                      Text(widget.asset.formatPrice(liquidationPrice), style: const TextStyle(color: Color(0xFFF23645), fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bouton de confirmation
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isBuy ? const Color(0xFF2962FF) : const Color(0xFFF23645),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Création de la position de trading
                final newPosition = TradePosition(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  symbol: widget.asset.symbol,
                  side: widget.isBuy ? PositionSide.long : PositionSide.short,
                  entryPrice: widget.currentPrice,
                  takeProfit: _tpPrice,
                  stopLoss: _slPrice,
                  margin: amount,
                  leverage: _leverage,
                  openedAt: DateTime.now(),
                );

                // ✅ Dispatcher l'événement au BLoC pour de vrai !
                widget.marketDataBloc.add(OpenPositionEvent(newPosition));

                // ✅ Afficher le SnackBar AVANT le pop pour éviter
                // d'utiliser un context détaché après fermeture du modal.
                widget.scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '${widget.isBuy ? "Achat (Long)" : "Vente (Short)"} de ${widget.asset.symbol} ouvert avec succès ! 🚀',
                    ),
                    backgroundColor: widget.isBuy ? const Color(0xFF2962FF) : const Color(0xFFF23645),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
                Navigator.pop(context);
              },
              child: Text(
                'Confirmer ${widget.isBuy ? "Achat Long" : "Vente Short"}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// OOP DRAWINGS IMPLEMENTATIONS
// ============================================================

class ChartPoint {
  final int candleIndex;
  final double price;

  ChartPoint(this.candleIndex, this.price);

  Offset toOffset(double chartWidth, double priceChartHeight, double minPrice, double maxPrice, int totalCandles) {
    if (totalCandles == 0) return Offset.zero;
    final x = (candleIndex + 0.5) * (chartWidth / totalCandles);
    final priceRange = maxPrice - minPrice;
    final y = priceRange == 0 ? priceChartHeight / 2 : priceChartHeight * (1.0 - (price - minPrice) / priceRange);
    return Offset(x, y);
  }
}

abstract class DrawingElement {
  void draw(
    Canvas canvas,
    Size size,
    double minPrice,
    double maxPrice,
    double chartWidth,
    double priceChartHeight,
    List<Candle> candles,
  );
}

class TrendLineElement extends DrawingElement {
  final ChartPoint start;
  final ChartPoint end;

  TrendLineElement(this.start, this.end);

  @override
  void draw(
    Canvas canvas,
    Size size,
    double minPrice,
    double maxPrice,
    double chartWidth,
    double priceChartHeight,
    List<Candle> candles,
  ) {
    final startOffset = start.toOffset(chartWidth, priceChartHeight, minPrice, maxPrice, candles.length);
    final endOffset = end.toOffset(chartWidth, priceChartHeight, minPrice, maxPrice, candles.length);

    final paint = Paint()
      ..color = const Color(0xFF2962FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(startOffset, endOffset, paint);

    final anchorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startOffset, 4, anchorPaint);
    canvas.drawCircle(endOffset, 4, anchorPaint);
  }
}

class FibonacciElement extends DrawingElement {
  final ChartPoint start;
  final ChartPoint end;

  FibonacciElement(this.start, this.end);

  @override
  void draw(
    Canvas canvas,
    Size size,
    double minPrice,
    double maxPrice,
    double chartWidth,
    double priceChartHeight,
    List<Candle> candles,
  ) {
    final startOffset = start.toOffset(chartWidth, priceChartHeight, minPrice, maxPrice, candles.length);
    final endOffset = end.toOffset(chartWidth, priceChartHeight, minPrice, maxPrice, candles.length);

    final basePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(startOffset, endOffset, basePaint);

    final levels = [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0];
    final levelColors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.cyan,
      Colors.blue,
      Colors.purple
    ];

    final startPrice = start.price;
    final diff = end.price - startPrice;

    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];
      final price = startPrice + diff * level;
      final tempPoint = ChartPoint(start.candleIndex, price);
      final y = tempPoint.toOffset(chartWidth, priceChartHeight, minPrice, maxPrice, candles.length).dy;

      final paint = Paint()
        ..color = levelColors[i].withOpacity(0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Fib ${(level * 100).toStringAsFixed(1)}% (${price.toStringAsFixed(2)})',
          style: TextStyle(color: levelColors[i], fontSize: 10),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(8, y - 12));
    }
  }
}

class TextElement extends DrawingElement {
  final ChartPoint point;
  final String text;

  TextElement(this.point, this.text);

  @override
  void draw(
    Canvas canvas,
    Size size,
    double minPrice,
    double maxPrice,
    double chartWidth,
    double priceChartHeight,
    List<Candle> candles,
  ) {
    final offset = point.toOffset(chartWidth, priceChartHeight, minPrice, maxPrice, candles.length);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xFF1E222D),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final rectPaint = Paint()
      ..color = const Color(0xFF1E222D)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(offset.dx - 6, offset.dy - textPainter.height / 2 - 4, textPainter.width + 12, textPainter.height + 8),
        const Radius.circular(4),
      ),
      rectPaint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFF2962FF)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(offset.dx - 6, offset.dy - textPainter.height / 2 - 4, textPainter.width + 12, textPainter.height + 8),
        const Radius.circular(4),
      ),
      borderPaint,
    );

    textPainter.paint(canvas, Offset(offset.dx, offset.dy - textPainter.height / 2));
  }
}

class RulerElement extends DrawingElement {
  final ChartPoint start;
  final ChartPoint end;

  RulerElement(this.start, this.end);

  @override
  void draw(
    Canvas canvas,
    Size size,
    double minPrice,
    double maxPrice,
    double chartWidth,
    double priceChartHeight,
    List<Candle> candles,
  ) {
    final startOffset = start.toOffset(chartWidth, priceChartHeight, minPrice, maxPrice, candles.length);
    final endOffset = end.toOffset(chartWidth, priceChartHeight, minPrice, maxPrice, candles.length);

    final rectPaint = Paint()
      ..color = const Color(0xFF2962FF).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromPoints(startOffset, endOffset);
    canvas.drawRect(rect, rectPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF2962FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(startOffset, endOffset, linePaint);

    final priceDiff = end.price - start.price;
    final percentChange = start.price == 0 ? 0.0 : (priceDiff / start.price) * 100;
    final barsCount = (end.candleIndex - start.candleIndex).abs() + 1;

    final infoText = '${priceDiff >= 0 ? "+" : ""}${priceDiff.toStringAsFixed(2)} (${percentChange >= 0 ? "+" : ""}${percentChange.toStringAsFixed(2)}%)\n$barsCount bars';

    final textPainter = TextPainter(
      text: TextSpan(
        text: infoText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final center = Offset((startOffset.dx + endOffset.dx) / 2, (startOffset.dy + endOffset.dy) / 2);

    final bubblePaint = Paint()
      ..color = const Color(0xFF1E222D)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - textPainter.width / 2 - 8, center.dy - textPainter.height / 2 - 6, textPainter.width + 16, textPainter.height + 12),
        const Radius.circular(6),
      ),
      bubblePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - textPainter.width / 2 - 8, center.dy - textPainter.height / 2 - 6, textPainter.width + 16, textPainter.height + 12),
        const Radius.circular(6),
      ),
      borderPaint,
    );

    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
  }
}
