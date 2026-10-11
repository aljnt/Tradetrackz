import 'package:flutter/material.dart';

enum AssetType {
  forex,
  gold,
  indices,
  stock,
  crypto,
  cfd,
}

class AssetItem {
  final String symbol;
  final String displayName;
  final String fullName;
  final AssetType type;
  final String exchange;
  final String sector;
  final IconData iconData;
  final Color iconColor;

  const AssetItem({
    required this.symbol,
    required this.displayName,
    required this.fullName,
    required this.type,
    required this.exchange,
    this.sector = 'Financial',
    this.iconData = Icons.show_chart,
    this.iconColor = const Color(0xFF4A90E2),
  });

  int get decimalPlaces {
    switch (type) {
      case AssetType.forex:
        return symbol.contains('JPY') ? 3 : 5;
      case AssetType.gold:
      case AssetType.cfd:
        return 2;
      case AssetType.indices:
        return 2;
      case AssetType.stock:
        return 2;
      case AssetType.crypto:
        return symbol.contains('BTC') || symbol.contains('ETH') ? 2 : 4;
    }
  }

  String formatPrice(double price) {
    return price.toStringAsFixed(decimalPlaces);
  }

  String formatChange(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(decimalPlaces)}';
  }

  String formatPercent(double changePercent) {
    final sign = changePercent >= 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(2)}%';
  }
}

class AssetCatalog {
  static const List<AssetItem> allAssets = [
    // GOLD / COMMODITIES / CFD
    AssetItem(
      symbol: 'XAU/USD',
      displayName: 'GOLD',
      fullName: 'Gold Spot / US Dollar',
      type: AssetType.gold,
      exchange: 'COMEX / FOREX',
      sector: 'Precious Metals',
      iconData: Icons.monetization_on_rounded,
      iconColor: Color(0xFFFFB800),
    ),
    AssetItem(
      symbol: 'XAG/USD',
      displayName: 'SILVER',
      fullName: 'Silver Spot / US Dollar',
      type: AssetType.gold,
      exchange: 'COMEX / FOREX',
      sector: 'Precious Metals',
      iconData: Icons.circle_outlined,
      iconColor: Color(0xFFC0C0C0),
    ),
    AssetItem(
      symbol: 'WTI/USD',
      displayName: 'USOIL',
      fullName: 'Crude Oil WTI Spot',
      type: AssetType.cfd,
      exchange: 'NYMEX',
      sector: 'Energy Commodities',
      iconData: Icons.water_drop_rounded,
      iconColor: Color(0xFFEF4444),
    ),

    // FOREX
    AssetItem(
      symbol: 'EUR/USD',
      displayName: 'EUR/USD',
      fullName: 'Euro / US Dollar',
      type: AssetType.forex,
      exchange: 'FXCM / OANDA',
      sector: 'Major Forex Pair',
      iconData: Icons.euro_symbol_rounded,
      iconColor: Color(0xFF3B82F6),
    ),
    AssetItem(
      symbol: 'GBP/USD',
      displayName: 'GBP/USD',
      fullName: 'British Pound / US Dollar',
      type: AssetType.forex,
      exchange: 'FXCM / OANDA',
      sector: 'Major Forex Pair',
      iconData: Icons.currency_pound_rounded,
      iconColor: Color(0xFF8B5CF6),
    ),
    AssetItem(
      symbol: 'USD/JPY',
      displayName: 'USD/JPY',
      fullName: 'US Dollar / Japanese Yen',
      type: AssetType.forex,
      exchange: 'FXCM / OANDA',
      sector: 'Major Forex Pair',
      iconData: Icons.currency_yen_rounded,
      iconColor: Color(0xFFEC4899),
    ),
    AssetItem(
      symbol: 'AUD/USD',
      displayName: 'AUD/USD',
      fullName: 'Australian Dollar / US Dollar',
      type: AssetType.forex,
      exchange: 'FXCM / OANDA',
      sector: 'Commodity Forex',
      iconData: Icons.attach_money_rounded,
      iconColor: Color(0xFF10B981),
    ),

    // INDICES
    AssetItem(
      symbol: 'SPX',
      displayName: 'S&P 500',
      fullName: 'S&P 500 Index',
      type: AssetType.indices,
      exchange: 'CBOE',
      sector: 'US Broad Market',
      iconData: Icons.insights_rounded,
      iconColor: Color(0xFF3B82F6),
    ),
    AssetItem(
      symbol: 'NDX',
      displayName: 'NASDAQ 100',
      fullName: 'NASDAQ 100 Technology Index',
      type: AssetType.indices,
      exchange: 'NASDAQ',
      sector: 'Technology Index',
      iconData: Icons.trending_up_rounded,
      iconColor: Color(0xFF06B6D4),
    ),
    AssetItem(
      symbol: 'DJI',
      displayName: 'DOW JONES',
      fullName: 'Dow Jones Industrial Average',
      type: AssetType.indices,
      exchange: 'NYSE',
      sector: 'US Industrial',
      iconData: Icons.domain_rounded,
      iconColor: Color(0xFF6366F1),
    ),
    AssetItem(
      symbol: 'DXY',
      displayName: 'US DOLLAR',
      fullName: 'US Dollar Currency Index',
      type: AssetType.indices,
      exchange: 'ICE',
      sector: 'Currency Index',
      iconData: Icons.account_balance_rounded,
      iconColor: Color(0xFF10B981),
    ),

    // STOCKS
    AssetItem(
      symbol: 'AAPL',
      displayName: 'AAPL',
      fullName: 'Apple Inc.',
      type: AssetType.stock,
      exchange: 'NASDAQ',
      sector: 'Consumer Electronics & Tech',
      iconData: Icons.apple_rounded,
      iconColor: Color(0xFF9CA3AF),
    ),
    AssetItem(
      symbol: 'TSLA',
      displayName: 'TSLA',
      fullName: 'Tesla Inc.',
      type: AssetType.stock,
      exchange: 'NASDAQ',
      sector: 'Automotive & Clean Energy',
      iconData: Icons.electric_car_rounded,
      iconColor: Color(0xFFEF4444),
    ),
    AssetItem(
      symbol: 'NVDA',
      displayName: 'NVDA',
      fullName: 'NVIDIA Corporation',
      type: AssetType.stock,
      exchange: 'NASDAQ',
      sector: 'Semiconductors & AI',
      iconData: Icons.memory_rounded,
      iconColor: Color(0xFF22C55E),
    ),
    AssetItem(
      symbol: 'MSFT',
      displayName: 'MSFT',
      fullName: 'Microsoft Corporation',
      type: AssetType.stock,
      exchange: 'NASDAQ',
      sector: 'Software & Cloud',
      iconData: Icons.window_rounded,
      iconColor: Color(0xFF3B82F6),
    ),

    // CRYPTO
    AssetItem(
      symbol: 'BTC/USD',
      displayName: 'BTC',
      fullName: 'Bitcoin / US Dollar',
      type: AssetType.crypto,
      exchange: 'Coinbase / Binance',
      sector: 'Digital Currency',
      iconData: Icons.currency_bitcoin_rounded,
      iconColor: Color(0xFFF7931A),
    ),
    AssetItem(
      symbol: 'ETH/USD',
      displayName: 'ETH',
      fullName: 'Ethereum / US Dollar',
      type: AssetType.crypto,
      exchange: 'Coinbase / Binance',
      sector: 'Smart Contracts Platform',
      iconData: Icons.diamond_rounded,
      iconColor: Color(0xFF627EEA),
    ),
    AssetItem(
      symbol: 'SOL/USD',
      displayName: 'SOL',
      fullName: 'Solana / US Dollar',
      type: AssetType.crypto,
      exchange: 'Coinbase / Binance',
      sector: 'High Speed Blockchain',
      iconData: Icons.bolt_rounded,
      iconColor: Color(0xFF14F195),
    ),
  ];

  static AssetItem defaultAsset = allAssets.first; // XAU/USD (Gold)

  static AssetItem findBySymbol(String symbol) {
    final clean = symbol.toUpperCase().replaceAll(' ', '');
    return allAssets.firstWhere(
      (a) => a.symbol.toUpperCase() == clean || a.displayName.toUpperCase() == clean,
      orElse: () => AssetItem(
        symbol: symbol,
        displayName: symbol,
        fullName: symbol,
        type: AssetType.forex,
        exchange: 'GLOBAL',
      ),
    );
  }

  static Map<String, List<AssetItem>> get categorizedAssets => {
    'GOLD & CFD': allAssets.where((a) => a.type == AssetType.gold || a.type == AssetType.cfd).toList(),
    'FOREX': allAssets.where((a) => a.type == AssetType.forex).toList(),
    'INDICES': allAssets.where((a) => a.type == AssetType.indices).toList(),
    'STOCKS': allAssets.where((a) => a.type == AssetType.stock).toList(),
    'CRYPTO': allAssets.where((a) => a.type == AssetType.crypto).toList(),
  };
}
