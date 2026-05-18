import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/money_utils.dart';
import '../../../../core/utils/navigator_ex.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../../watchlist/domain/entities/stock.dart';
import '../../../watchlist/presentation/bloc/watchlist_bloc.dart';
import '../../../watchlist/presentation/screens/stock_detail_screen.dart';
import '../bloc/portfolio_state.dart';

class HoldingCard extends StatelessWidget {
  final HoldingDisplayModel display;

  const HoldingCard({super.key, required this.display});

  @override
  Widget build(BuildContext context) {
    final isProfit = display.pnlPaisa >= 0;
    final pnlColor =
        isProfit ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () {
        final watchlistBloc = context.read<WatchlistBloc>();
        final stock = watchlistBloc.state.stocks.firstWhere(
          (s) => s.symbol == display.holding.symbol,
          orElse: () => Stock(
            symbol: display.holding.symbol,
            name: display.holding.symbol,
            price: display.currentPrice,
            change: 0.0,
            percentChange: 0.0,
            candles: const [],
          ),
        );
        context.push(
          StockDetailScreen(stock: stock),
          animation: AnimationType.slide,
          direction: NavSlideDirection.rtl,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // ── Symbol avatar ──
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: pnlColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: pnlColor.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: AppText(
                display.holding.symbol.substring(0, 1),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: pnlColor,
              ),
            ),

            const SizedBox(width: 12),

            // ── Symbol + quantity ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    display.holding.symbol,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    '${display.holding.quantity} shares  ·  avg ${AppPriceFormatter.format(display.holding.avgBuyPricePaisa / 100)}',
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Value + P&L ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText(
                  MoneyUtils.format(display.currentValuePaisa),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                      color: pnlColor,
                      size: 16,
                    ),
                    AppText(
                      '${isProfit ? "+" : ""}${display.pnlPercent.toStringAsFixed(2)}%',
                      color: pnlColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ],
            ),

            // ── Chevron ──
            // Padding(
            //   padding: const EdgeInsets.only(left: 6),
            //   child: Icon(
            //     Icons.chevron_right_rounded,
            //     size: 18,
            //     color: Colors.white.withValues(alpha: 0.15),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

// LTP: Last Traded Price
class AppPriceFormatter {
  static String format(double price) => '₹${price.toStringAsFixed(2)}';
}
