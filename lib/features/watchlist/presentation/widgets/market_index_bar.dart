import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_text.dart';
import '../../../../shared/widgets/price_text.dart';
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
        if (indices.isEmpty) return const SizedBox();

        return SizedBox(
          height: 160, // Increased height to accommodate chart
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: indices.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final marketIndex = indices[index];
              final isPositive = marketIndex.change >= 0;
              final color = isPositive ? Colors.greenAccent : Colors.redAccent;

              return Container(
                padding: const EdgeInsets.all(16),
                width: 240,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  border: Border.all(color: Colors.white10, width: 0.5),
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.05), Colors.transparent],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      marketIndex.symbol,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                    Expanded(
                      child: MiniChartWidget(
                        candles: marketIndex.candles,
                        isPositive: isPositive,
                      ),
                    ),
                    PriceText(
                      price: marketIndex.price,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    AppText(
                      '${isPositive ? '+' : ''}${marketIndex.percentChange.toStringAsFixed(2)}%',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
