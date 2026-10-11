import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────
// WithdrawPage – Retrait de fonds
// ─────────────────────────────────────────────
class WithdrawPage extends StatefulWidget {
  const WithdrawPage({Key? key}) : super(key: key);

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountCtrl = TextEditingController();

  // Solde disponible simulé
  final double _availableBalance = 1500.54;

  // Destination sélectionnée (0 = compte bancaire, 1 = adresse crypto)
  int _selectedDest = 0;

  // Frais de retrait
  final double _feeRate = 0.0125; // 1.25%
  final double _networkFee = 2.50; // frais réseau fixes

  // Animation pour le shake (montant > solde)
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // Destinations disponibles
  final List<Map<String, dynamic>> _destinations = const [
    {
      'icon': Icons.account_balance,
      'label': 'Bank Account',
      'sub': 'FR76 •••• •••• 4821',
      'delay': '1–3 business days',
    },
    {
      'icon': Icons.currency_bitcoin,
      'label': 'Crypto Wallet',
      'sub': '0x4a7b...f8d2',
      'delay': '~10 minutes',
    },
  ];

  double get _amount =>
      double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;

  double get _feePercent => _amount * _feeRate;

  double get _totalFee => _feePercent + _networkFee;

  double get _netAmount => _amount - _totalFee;

  bool get _isOverBalance => _amount > _availableBalance;

  bool get _isValid => _amount > 0 && !_isOverBalance && _netAmount > 0;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // Remplir avec le solde maximum
  void _setMax() {
    final maxWithdrawable = _availableBalance / (1 + _feeRate) - _networkFee;
    _amountCtrl.text = maxWithdrawable.toStringAsFixed(2);
    setState(() {});
  }

  // Confirmation du retrait
  void _confirm() {
    if (!_isValid) {
      _shakeCtrl.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.down,
          content: Text(
            _isOverBalance
                ? 'Insufficient balance (\$${_availableBalance.toStringAsFixed(2)} available)'
                : 'Please enter a valid amount',
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryPurple,
        content: Text(
            'Withdraw - \$${_amount.toStringAsFixed(2)} in progress ✓'),
      ),
    );
    // Vérifier mounted avant d'utiliser le context après une opération async
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Withdraw'),
        actions: [
          IconButton(
              icon: const Icon(Icons.history_outlined), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Carte solde disponible
              _buildBalanceCard(),
              const SizedBox(height: 28),

              // ── Saisie montant + bouton MAX
              const Text(
                'Amount to withdraw',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              _buildAmountField(),

              // ── Warning : montant > solde
              if (_isOverBalance) ...[
                const SizedBox(height: 10),
                _buildWarningBanner(),
              ],
              const SizedBox(height: 28),

              // ── Sélecteur de destination
              const Text(
                'Withdrawal destination',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...List.generate(_destinations.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildDestCard(i),
                );
              }),
              const SizedBox(height: 28),

              // ── Récap des frais
              _buildFeeSummary(),
              const SizedBox(height: 20),

              // ── Bouton confirm
              _buildConfirmButton(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets privés ───────────────────────────────────────────

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppTheme.withdrawGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available balance',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${_availableBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final offset = _shakeCtrl.isAnimating
            ? _shakeAnim.value *
                (0.5 - _shakeCtrl.value).clamp(-1.0, 1.0)
            : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isOverBalance
                ? AppColors.down
                : AppColors.primaryPurple.withValues(alpha: 0.5),
            width: _isOverBalance ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '\$',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _amountCtrl,
                onChanged: (_) => setState(() {}),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: TextStyle(
                  color: _isOverBalance ? AppColors.down : Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            // ── Bouton MAX
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _setMax,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.withdrawGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'MAX',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.down.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.down.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.down, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Amount exceeds available balance (\$${_availableBalance.toStringAsFixed(2)})',
              style: const TextStyle(
                color: AppColors.down,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestCard(int i) {
    final dest = _destinations[i];
    final selected = i == _selectedDest;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedDest = i),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceLight : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primaryPurple
                  : AppColors.border,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (selected
                          ? AppColors.primaryPurple
                          : AppColors.textMuted)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  dest['icon'] as IconData,
                  color: selected
                      ? AppColors.primaryPurple
                      : Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dest['label'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      dest['sub'] as String,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryPurple
                            : AppColors.border,
                        width: 2,
                      ),
                      color: selected
                          ? AppColors.primaryPurple
                          : Colors.transparent,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dest['delay'] as String,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _summaryRow(
              'Withdrawal amount', '\$${_amount.toStringAsFixed(2)}'),
          _summaryRow(
              'Service fee (1.25%)', '\$${_feePercent.toStringAsFixed(2)}'),
          _summaryRow('Network fee', '\$${_networkFee.toStringAsFixed(2)}'),
          const Divider(color: AppColors.border, height: 24),
          _summaryRow(
            'You\'ll receive',
            _netAmount > 0 ? '\$${_netAmount.toStringAsFixed(2)}' : '-',
            highlight: true,
            highlightColor: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      height: 58,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _isValid
            ? AppTheme.withdrawGradient
            : const LinearGradient(
                colors: [Color(0xFF3A3A4A), Color(0xFF2A2A3A)],
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isValid
            ? [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _confirm,
          borderRadius: BorderRadius.circular(14),
          child: const Center(
            child: Text(
              'Confirm Withdraw',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool highlight = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.white : AppColors.textSecondary,
              fontSize: highlight ? 15 : 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight
                  ? (highlightColor ?? AppColors.primaryPurple)
                  : Colors.white,
              fontSize: highlight ? 16 : 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
