import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/blocs/market/market_data_bloc.dart';
import '../presentation/blocs/market/market_data_event.dart';
import '../presentation/blocs/market/market_data_state.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _twelveDataController = TextEditingController();
  final _finnhubController = TextEditingController();
  final _alphaVantageController = TextEditingController();

  bool _obscureTwelveData = true;
  bool _obscureFinnhub = true;
  bool _obscureAlphaVantage = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final service = context.read<MarketDataBloc>().marketDataService;
      _twelveDataController.text = service.twelveDataKey ?? '';
      _finnhubController.text = service.finnhubKey ?? '';
      _alphaVantageController.text = service.alphaVantageKey ?? '';
      setState(() {});
    });
  }

  @override
  void dispose() {
    _twelveDataController.dispose();
    _finnhubController.dispose();
    _alphaVantageController.dispose();
    super.dispose();
  }

  void _save() {
    final twelveData = _twelveDataController.text.trim();
    final finnhub = _finnhubController.text.trim();

    if (twelveData.isEmpty && finnhub.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoute au moins une clé API : Finnhub ou TwelveData'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    context.read<MarketDataBloc>().add(
      SaveApiKeysEvent(
        twelveDataKey: twelveData,
        finnhubKey: finnhub,
        alphaVantageKey: _alphaVantageController.text.trim(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Clés API enregistrées'),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131722),
        title: const Text('Configuration API', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<MarketDataBloc, MarketDataState>(
        listener: (context, state) {
          if (state.status == MarketDataStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Erreur de chargement'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBanner(),
              const SizedBox(height: 24),
              _buildApiKeyField(
                label: 'TwelveData API Key',
                subtitle: 'Préférée — Forex, Or, Indices, Actions, Crypto',
                controller: _twelveDataController,
                obscure: _obscureTwelveData,
                onToggleObscure: () => setState(() => _obscureTwelveData = !_obscureTwelveData),
                required: false,
                signupUrl: 'twelvedata.com/pricing',
              ),
              const SizedBox(height: 20),
              _buildApiKeyField(
                label: 'Finnhub API Key',
                subtitle: 'Optionnel — fallback pour stocks/indices',
                controller: _finnhubController,
                obscure: _obscureFinnhub,
                onToggleObscure: () => setState(() => _obscureFinnhub = !_obscureFinnhub),
                required: false,
                signupUrl: 'finnhub.io',
              ),
              const SizedBox(height: 20),
              _buildApiKeyField(
                label: 'Alpha Vantage API Key',
                subtitle: 'Optionnel — Source de secours',
                controller: _alphaVantageController,
                obscure: _obscureAlphaVantage,
                onToggleObscure: () => setState(() => _obscureAlphaVantage = !_obscureAlphaVantage),
                required: false,
                signupUrl: 'alphavantage.co/support/#api-key',
              ),
              const SizedBox(height: 32),
              BlocBuilder<MarketDataBloc, MarketDataState>(
                builder: (context, state) {
                  final isLoading = state.status == MarketDataStatus.loading;
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Enregistrer et charger',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2233),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'TwelveData est utilisée en priorité. Finnhub serve de fallback. Ajoute au moins une clé pour charger les données de marché.',
              style: TextStyle(color: Color(0xFFB0B8C4), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyField({
    required String label,
    required String subtitle,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required bool required,
    required String signupUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (required) ...[
              const SizedBox(width: 6),
              const Text('*', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1D23),
            hintText: 'Colle ta clé ici',
            hintStyle: const TextStyle(color: Color(0xFF4B5563)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: const Color(0xFF6B7280),
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Obtenir une clé : $signupUrl',
          style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11),
        ),
      ],
    );
  }
}