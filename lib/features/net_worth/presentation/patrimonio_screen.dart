import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/farol_colors.dart';
import 'widgets/profile_summary_card.dart';
import 'widgets/asset_allocation_card.dart';
import 'widgets/period_flow_card.dart';

class PatrimonioScreen extends StatelessWidget {
  const PatrimonioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('Patrimônio',
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ProfileSummaryCard(),
          SizedBox(height: 16),
          AssetAllocationCard(),
          SizedBox(height: 16),
          PeriodFlowCard(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
