import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class DepositPage extends StatefulWidget {
  const DepositPage({Key? key}) : super(key: key);

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final TextEditingController _amountCtrl = TextEditingController();

  // Solde simulé
  final double _totalBalance = 1500.54;

  // Méthode sélectionnée
  int _selectedMethod = 0;
  final List<Map<String, dynamic>> _methods = const [
    {'icon': Icons.credit_card, 'label': 'Card', 'sub': '•••• 4242'},
    {'icon': Icons.account_balance, 'label': 'Transfer', 'sub': 'SEPA'},
    {'icon': Icons.currency_bitcoin, 'label': 'Crypto', 'sub': 'BTC / ETH'},
  ];

  // Frais
  final double _feeRate = 0.018; // 1.8%
  final double _minFee = 1.0;

  double get _amount => double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;
  double get _fee {
    final calc = _amount * _feeRate;
    return calc < _minFee && _amount > 0 ? _minFee : calc;
  }
  double get _netAmount => _amount - _fee;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  // Confirmation -> SnackBar bleu + retour
  void _confirm() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.down,
          content: const Text('Please enter an amount'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryBlue,
        content: Text('Deposit - \$${_amount.toStringAsFixed(2)} in progress ✓'),
      ),
    );
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
        title: const Text('Deposit'),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // ---- Carte solde ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.25),
                      blurRadius: 20, offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total balance',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('\$${_totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 12),
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
                              Text('+2.4%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('Today', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ---- Champ montant (style calculatrice centré) ----
              const Text('Enter amount',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('\$', style: TextStyle(color: AppColors.textSecondary, fontSize: 26, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amountCtrl,
                            onChanged: (_) => setState(() {}),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: '0.00',
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 42, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('≈ €${(_amount * 0.92).toStringAsFixed(2)}  •  ≈ ₿${(_amount / 64000).toStringAsFixed(6)}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 14),
                    // Montants rapides
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final v in ['100', '250', '500', '1000'])
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _amountCtrl.text = v;
                                setState(() {});
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text('\$$v',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ---- Méthodes de dépôt ----
              const Text('Payment method',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              ...List.generate(_methods.length, (i) {
                final m = _methods[i];
                final selected = i == _selectedMethod;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedMethod = i),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.surfaceLight : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? AppColors.primaryBlue : AppColors.border,
                            width: selected ? 1.3 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (selected ? AppColors.primaryBlue : AppColors.primaryPurple).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(m['icon'], color: selected ? AppColors.primaryBlue : Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m['label'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                  Text(m['sub'], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: selected ? AppColors.primaryBlue : AppColors.border, width: 2),
                                color: selected ? AppColors.primaryBlue : Colors.transparent,
                              ),
                              child: selected
                                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),

              // ---- Récap + Bouton confirm ----
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _summaryRow('Gross amount', '\$${_amount.toStringAsFixed(2)}'),
                    _summaryRow('Fee (1.8%)', '\$${_fee.toStringAsFixed(2)}'),
                    const Divider(color: AppColors.border, height: 24),
                    _summaryRow('You\'ll receive', '\$${_netAmount.toStringAsFixed(2)}', highlight: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 58,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.depositGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                      blurRadius: 16, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _confirm,
                    borderRadius: BorderRadius.circular(14),
                    child: const Center(
                      child: Text(
                        'Confirm Deposit',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            color: highlight ? Colors.white : AppColors.textSecondary,
            fontSize: highlight ? 15 : 13, fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          )),
          Text(value, style: TextStyle(
            color: highlight ? AppColors.primaryBlue : Colors.white,
            fontSize: highlight ? 16 : 13, fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          )),
        ],
      ),
    );
  }
}
