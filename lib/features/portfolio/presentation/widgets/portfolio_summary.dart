import 'package:flutter/material.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/widgets/app_text.dart';

class PortfolioSummary extends StatelessWidget {
  final int investedPaisa;
  final int currentValuePaisa;
  final int pnlPaisa;
  final double pnlPercent;

  const PortfolioSummary({
    super.key,
    required this.investedPaisa,
    required this.currentValuePaisa,
    required this.pnlPaisa,
    required this.pnlPercent,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = pnlPaisa >= 0;
    final color = isProfit ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF121212),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Current Value', color: Colors.white54, fontSize: 14),
          const SizedBox(height: 4),
          AppText(
            MoneyUtils.format(currentValuePaisa),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMetric('Invested', MoneyUtils.format(investedPaisa)),
              const Spacer(),
              _buildMetric(
                'Total P&L',
                '${isProfit ? "+" : ""}${MoneyUtils.format(pnlPaisa)}',
                valueColor: color,
                suffix: ' (${pnlPercent.toStringAsFixed(2)}%)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, {Color? valueColor, String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, color: Colors.white38, fontSize: 12),
        const SizedBox(height: 4),
        Row(
          children: [
            AppText(value, fontSize: 16, fontWeight: FontWeight.bold, color: valueColor),
            if (suffix != null)
              AppText(suffix, fontSize: 14, fontWeight: FontWeight.bold, color: valueColor),
          ],
        ),
      ],
    );
  }
}
