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
    final pnlColor = isProfit ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            pnlColor.withValues(alpha: 0.15),
            pnlColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pnlColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Current Value (hero number) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'CURRENT VALUE',
                      fontSize: 10,
                      color: Colors.white38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AppText(
                        MoneyUtils.format(currentValuePaisa),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // ── P&L Badge ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: pnlColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: pnlColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: pnlColor,
                    ),
                    const SizedBox(width: 4),
                    AppText(
                      '${isProfit ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: pnlColor,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),

          // ── Invested / P&L row ──
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'INVESTED',
                  value: MoneyUtils.format(investedPaisa),
                  valueColor: Colors.white70,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'TOTAL P&L',
                  value:
                      '${isProfit ? "+" : ""}${MoneyUtils.format(pnlPaisa)}',
                  valueColor: pnlColor,
                  alignRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool alignRight;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final align =
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Padding(
      padding: EdgeInsets.only(
        left: alignRight ? 16 : 0,
        right: alignRight ? 0 : 16,
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          AppText(
            label,
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
                alignRight ? Alignment.centerRight : Alignment.centerLeft,
            child: AppText(
              value,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
