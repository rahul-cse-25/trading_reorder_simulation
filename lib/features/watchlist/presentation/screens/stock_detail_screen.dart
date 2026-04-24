import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_text.dart';
import '../../../../shared/widgets/price_text.dart';
import '../../domain/entities/stock.dart';
import '../bloc/watchlist_bloc.dart';
import '../bloc/watchlist_state.dart';
import '../widgets/stock_chart_widget.dart';

class StockDetailScreen extends StatelessWidget {
  final Stock stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final chartHeight = MediaQuery.of(context).size.width;
    return BlocSelector<WatchlistBloc, WatchlistState, Stock>(
      selector: (state) => state.stocks.firstWhere(
        (s) => s.symbol == stock.symbol,
        orElse: () => stock,
      ),
      builder: (context, liveStock) {
        final isPositive = liveStock.change >= 0;
        final color = isPositive ? Colors.greenAccent : Colors.redAccent;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: CustomScrollView(
            slivers: [
              // 1. Sliver App Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFF121212),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leadingWidth: 32,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                centerTitle: false,
                title: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            liveStock.symbol,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          AppText(
                            liveStock.name,
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PriceText(
                          price: liveStock.price,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        const AppText(
                          'Current Price',
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Price Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          PriceText(
                            price: liveStock.price,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: AppText(
                                '${isPositive ? '+' : ''}${liveStock.percentChange.toStringAsFixed(2)}%',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppText(
                        '${isPositive ? '+' : ''}₹${liveStock.change.toStringAsFixed(2)} Today',
                        fontSize: 14,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Chart Section
              SliverToBoxAdapter(
                child: SizedBox(
                  height: chartHeight,
                  width: double.infinity,
                  child: StockChartWidget(stock: liveStock),
                ),
              ),

              // 4. Timeframe Selectors
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['1D', '1W', '1M', '3M', '1Y', 'ALL'].map((
                        label,
                      ) {
                        final isSelected = label == '1D';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AppText(
                            label,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white38,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // Chart Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    spacing: 4,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Icon(
                            Icons.stars_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                          AppText(
                            "Chart Feature",
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      AppText(
                        "The above chart is powered by a custom-built Flutter package (imp_trading_chart) developed and published by me. It is designed with a performant, scalable rendering architecture using CustomPainter, enabling efficient real-time data visualization similar to production-grade trading applications.",
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
