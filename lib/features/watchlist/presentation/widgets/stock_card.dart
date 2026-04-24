import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/app_text.dart';
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
                // 1. Symbol & Name Widget
                Expanded(
                  child: _StockInfoWidget(
                    symbol: stock.symbol,
                    name: stock.name,
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Optimized Chart Widget (RepaintBoundary)
                _StockChartWidget(
                  candles: stock.candles,
                  isPositive: stock.change >= 0,
                ),

                const SizedBox(width: 12),

                // 3. Price & Change Widget
                _StockPriceSection(stock: stock),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StockInfoWidget extends StatelessWidget {
  final String symbol;
  final String name;

  const _StockInfoWidget({required this.symbol, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          symbol,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        const SizedBox(height: 2),
        AppText(
          name,
          fontSize: 11,
          color: Colors.white38,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StockChartWidget extends StatelessWidget {
  final List<Candle> candles;
  final bool isPositive;

  const _StockChartWidget({required this.candles, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 70,
        height: 35,
        child: MiniChartWidget(candles: candles, isPositive: isPositive),
      ),
    );
  }
}

class _StockPriceSection extends StatefulWidget {
  final Stock stock;

  const _StockPriceSection({required this.stock});

  @override
  State<_StockPriceSection> createState() => _StockPriceSectionState();
}

class _StockPriceSectionState extends State<_StockPriceSection> {
  Color _flashColor = Colors.transparent;
  double _scale = 1.0;

  @override
  void didUpdateWidget(covariant _StockPriceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stock.price != oldWidget.stock.price) {
      final isUp = widget.stock.price > oldWidget.stock.price;
      setState(() {
        _flashColor = isUp
            ? Colors.greenAccent.withValues(alpha: 0.15)
            : Colors.redAccent.withValues(alpha: 0.15);
        _scale = 1.05; // Subtle scale animation
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _flashColor = Colors.transparent;
            _scale = 1.0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.stock.change >= 0;
    final color = isPositive ? Colors.greenAccent : Colors.redAccent;

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: _flashColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              AppPriceFormatter.format(widget.stock.price),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 16,
                  color: color,
                ),
                AppText(
                  '${widget.stock.percentChange.abs().toStringAsFixed(2)}%',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
