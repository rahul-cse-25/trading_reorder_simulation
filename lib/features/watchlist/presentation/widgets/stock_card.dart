import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_text.dart';
import '../../../../shared/widgets/price_text.dart';
import '../../domain/entities/stock.dart';
import '../bloc/watchlist_bloc.dart';
import '../bloc/watchlist_state.dart';
import 'mini_chart_widget.dart';

class StockCard extends StatelessWidget {
  final String symbol;
  final VoidCallback onTap;
  final double verticalPadding;

  const StockCard({
    super.key,
    required this.symbol,
    required this.onTap,
    this.verticalPadding = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WatchlistBloc, WatchlistState, Stock?>(
      selector: (state) {
        try {
          return state.stocks.firstWhere((s) => s.symbol == symbol);
        } catch (_) {
          return null;
        }
      },
      builder: (context, stock) {
        if (stock == null) return const SizedBox.shrink();
        final isPositive = stock.change >= 0;
        final color = isPositive ? Colors.greenAccent : Colors.redAccent;

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: verticalPadding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        stock.symbol,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      AppText(stock.name, fontSize: 12, color: Colors.white54),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Real Mini Chart
                RepaintBoundary(
                  child: SizedBox(
                    width: 80,
                    height: 50,
                    child: MiniChartWidget(
                      candles: stock.candles,
                      isPositive: isPositive,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PriceText(
                      price: stock.price,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    Row(
                      children: [
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 300),
                          turns: isPositive ? 0.0 : 0.2,
                          child: Icon(
                            key: ValueKey(isPositive),
                            Icons.trending_up_rounded,
                            size: 12,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AppText(
                          '${isPositive ? '+' : ''}${stock.percentChange.toStringAsFixed(2)}%',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
