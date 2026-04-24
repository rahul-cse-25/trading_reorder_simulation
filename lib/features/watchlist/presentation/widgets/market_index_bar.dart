import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/entities/market_index.dart';
import '../bloc/watchlist_bloc.dart';
import '../bloc/watchlist_state.dart';
import 'mini_chart_widget.dart';

class MarketIndexBar extends StatelessWidget {
  const MarketIndexBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WatchlistBloc, WatchlistState, List<MarketIndex>>(
      selector: (state) => state.indices,
      builder: (context, indices) {
        if (indices.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: AppText(
                'No market data available',
                color: Colors.white24,
                fontSize: 14,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: AppText(
                'MARKET INDICES',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white24,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: indices.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final marketIndex = indices[index];
                  final isPositive = marketIndex.change >= 0;
                  final color = isPositive
                      ? Colors.greenAccent
                      : Colors.redAccent;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    width: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      border: Border.all(color: Colors.white10, width: 0.5),
                      gradient: LinearGradient(
                        colors: [
                          marketIndex.bgColor.withOpacity(0.15),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          marketIndex.symbol,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                        Expanded(
                          child: RepaintBoundary(
                            child: IgnorePointer(
                              child: MiniChartWidget(
                                candles: marketIndex.candles,
                                isPositive: isPositive,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AppText(
                              AppPriceFormatter.format(marketIndex.price),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            AppText(
                              '${isPositive ? '+' : ''}${marketIndex.percentChange.toStringAsFixed(2)}%',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
