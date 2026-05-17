import 'package:flutter/material.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/widgets/app_text.dart';
import '../bloc/portfolio_state.dart';

class HoldingCard extends StatelessWidget {
  final HoldingDisplayModel display;

  const HoldingCard({super.key, required this.display});

  @override
  Widget build(BuildContext context) {
    final isProfit = display.pnlPaisa >= 0;
    final color = isProfit ? Colors.greenAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(display.holding.symbol, fontWeight: FontWeight.bold, fontSize: 16),
                  AppText('${display.holding.quantity} Shares', color: Colors.white38, fontSize: 12),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText(
                    MoneyUtils.format(display.currentValuePaisa),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  Row(
                    children: [
                      Icon(
                        isProfit ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: color,
                        size: 20,
                      ),
                      AppText(
                        '${MoneyUtils.format(display.pnlPaisa)} (${display.pnlPercent.toStringAsFixed(2)}%)',
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallMetric('Avg. Price', MoneyUtils.format(display.holding.avgBuyPricePaisa)),
              _buildSmallMetric('LTP', AppPriceFormatter.format(display.currentPrice)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, color: Colors.white38, fontSize: 11),
        AppText(value, fontSize: 13, fontWeight: FontWeight.w600),
      ],
    );
  }
}

// LTP: Last Traded Price
class AppPriceFormatter {
  static String format(double price) => '₹${price.toStringAsFixed(2)}';
}
