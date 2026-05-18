import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/feature_gate.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../design/branding/branding.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: const [
              FarolMark(size: FarolBrand.markSizeCompact, variant: FarolLogoVariant.dark),
              SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farol Premium',
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Entenda o futuro do seu dinheiro',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _PlanComparison(),
                  const SizedBox(height: 32),
                  const _FeatureTable(),
                  const SizedBox(height: 32),
                  const _TrialBadge(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Billing integração em breve 🔜'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.FarolColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Assinar Premium'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanComparison extends StatelessWidget {
  const _PlanComparison();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return isMobile
        ? const Column(
            children: [
              _PlanCard(
                name: 'Gratuito',
                price: 'R\$ 0',
                period: 'para sempre',
                isPremium: false,
              ),
              SizedBox(height: 16),
              _PlanCard(
                name: 'Premium',
                price: 'R\$ 19,90',
                period: '/mês',
                isPremium: true,
              ),
            ],
          )
        : const Row(
            children: [
              Expanded(
                child: _PlanCard(
                  name: 'Gratuito',
                  price: 'R\$ 0',
                  period: 'para sempre',
                  isPremium: false,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _PlanCard(
                  name: 'Premium',
                  price: 'R\$ 19,90',
                  period: '/mês',
                  isPremium: true,
                ),
              ),
            ],
          );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.period,
    required this.isPremium,
  });

  final String name;
  final String price;
  final String period;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPremium
            ? tokens.FarolColors.navy.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.04),
        border: Border.all(
          color: isPremium
              ? tokens.FarolColors.navy
              : Colors.grey.withValues(alpha: 0.2),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: price,
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' $period',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTable extends StatelessWidget {
  const _FeatureTable();

  static const _freeFeatures = [
    'Registro de gastos e receitas',
    'Orçamento por categoria',
    'Despesas recorrentes e parcelamentos',
    'Sincronização offline',
    '1 workspace pessoal',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funcionalidades',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            ..._freeFeatures.map((feature) => _FreeFeatureRow(feature: feature)),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            const _PremiumFeatureItem(PremiumFeature.multiWorkspace),
            const _PremiumFeatureItem(PremiumFeature.cashflowProjections),
            const _PremiumFeatureItem(PremiumFeature.aiInsights),
            const _PremiumFeatureItem(PremiumFeature.exportPdf),
          ],
        ),
      ],
    );
  }
}

class _FreeFeatureRow extends StatelessWidget {
  const _FreeFeatureRow({required this.feature});

  final String feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: tokens.FarolColors.tide,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumFeatureItem extends StatelessWidget {
  const _PremiumFeatureItem(this.feature);

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: tokens.FarolColors.navy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: tokens.FarolColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    feature.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: tokens.FarolColors.navy,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tokens.FarolColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tokens.FarolColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialBadge extends StatelessWidget {
  const _TrialBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.FarolColors.tide.withValues(alpha: 0.08),
        border: Border.all(
          color: tokens.FarolColors.tide.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.celebration_rounded,
            size: 20,
            color: tokens.FarolColors.tide,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '14 dias grátis para novos assinantes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: tokens.FarolColors.tide,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
