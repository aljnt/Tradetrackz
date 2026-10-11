import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../auth/login_screen.dart';
import '../wallet/deposit_page.dart';
import '../wallet/withdraw_page.dart';
import '../wallet/trade_page.dart';
import '../../../settings/api_settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  final Color bgColor = const Color(0xFF0B0E14);
  final Color primaryPurple = const Color(0xFF9B6FE6);
  final Color primaryBlue = const Color(0xFF4A90E2);
  final Color surfaceColor = const Color(0xFF161A23);

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon \u{1F680}'),
        backgroundColor: primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildNotificationItem(Icons.trending_up, 'BTC is up 2.4% today', '2 min ago', Colors.greenAccent),
            const SizedBox(height: 12),
            _buildNotificationItem(Icons.price_change, 'ETH new price alert', '15 min ago', primaryBlue),
            const SizedBox(height: 12),
            _buildNotificationItem(Icons.security, 'Account secured successfully', '1 hour ago', primaryPurple),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(IconData icon, String title, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.candlestick_chart, color: primaryPurple),
            const SizedBox(width: 8),
            const Text(
              'TradeTrackz',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
    icon: const Icon(Icons.vpn_key_rounded, color: Colors.white),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ApiSettingsScreen()),
      );
    },
    ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () => _showNotificationsSheet(context),
              ),
              Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: bgColor, width: 2),
                  ),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Hello, Trader 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back to your portfolio',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),

              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [primaryPurple, primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '\$24,562.00',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 16),
                              SizedBox(width: 4),
                              Text(
                                '+2.4%',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Today',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Boutons d'action principaux ─────────────────────────
              Row(
                children: [
                  // ── Deposit ──
                  Expanded(
                    child: _buildMainActionBtn(
                      context: context,
                      label: 'Deposit',
                      icon: Icons.add_circle_outline_rounded,
                      gradient: AppTheme.depositGradient,
                      glowColor: AppColors.primaryBlue,
                      snackMsg: 'Deposit -',
                      snackColor: AppColors.primaryBlue,
                      destination: const DepositPage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ── Withdraw ──
                  Expanded(
                    child: _buildMainActionBtn(
                      context: context,
                      label: 'Withdraw',
                      icon: Icons.remove_circle_outline_rounded,
                      gradient: AppTheme.withdrawGradient,
                      glowColor: AppColors.primaryPurple,
                      snackMsg: 'Withdraw -',
                      snackColor: AppColors.primaryPurple,
                      destination: const WithdrawPage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ── Trade ──
                  Expanded(
                    child: _buildMainActionBtn(
                      context: context,
                      label: 'Trade',
                      icon: Icons.candlestick_chart_rounded,
                      gradient: AppTheme.tradeGradient,
                      glowColor: AppColors.primaryOrange,
                      snackMsg: 'Trade -',
                      snackColor: AppColors.primaryOrange,
                      destination: const TradePage(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Market Trends Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Market Trends',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showComingSoon(context, 'All Markets'),
                    child: Text('See All', style: TextStyle(color: primaryBlue)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Market Items List
              _buildMarketItem(context, 'Bitcoin', 'BTC', '\$64,230.50', '+1.2%', true, Icons.currency_bitcoin, Colors.orange),
              const SizedBox(height: 12),
              _buildMarketItem(context, 'Ethereum', 'ETH', '\$3,450.20', '-0.5%', false, Icons.currency_exchange, Colors.blue),
              const SizedBox(height: 12),
              _buildMarketItem(context, 'Solana', 'SOL', '\$142.80', '+4.8%', true, Icons.token, Colors.tealAccent),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bouton d'action principal (Deposit / Withdraw / Trade)
  // Affiche un SnackBar immédiat puis navigue vers la page cible.
  Widget _buildMainActionBtn({
    required BuildContext context,
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required Color glowColor,
    required String snackMsg,
    required Color snackColor,
    required Widget destination,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 1. SnackBar immédiat
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: snackColor,
                content: Text(
                  snackMsg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                duration: const Duration(seconds: 1),
              ),
            );
            // 2. Navigation avec transition slide fluide
            Navigator.push(context, AppTheme.slideRoute(destination));
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketItem(BuildContext context, String name, String symbol, String price, String change, bool isUp, IconData icon, Color iconColor) {
    return InkWell(
      onTap: () => _showComingSoon(context, '$name ($symbol) Details'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade900, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    symbol,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: isUp ? Colors.greenAccent : Colors.redAccent,
                      size: 20,
                    ),
                    Text(
                      change,
                      style: TextStyle(
                        color: isUp ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
