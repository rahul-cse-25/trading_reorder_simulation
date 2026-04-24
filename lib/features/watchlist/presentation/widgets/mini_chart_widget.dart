import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';

class MiniChartWidget extends StatelessWidget {
  final List<Candle> candles;
  final bool isPositive;

  const MiniChartWidget({
    super.key,
    required this.candles,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) return const SizedBox();

    return IgnorePointer(
      child: ImpChart(
        candles: candles,
        style: ChartStyle(
          backgroundColor: Colors.transparent,
          lineStyle: LineChartStyle(
            color: isPositive ? Colors.greenAccent : Colors.redAccent,
            width: 1.5,
            showGlow: false,
            glowWidth: 1.0,
            smooth: true,
          ),
          currentPriceStyle: CurrentPriceIndicatorStyle.hidden(),
          rippleStyle: RippleAnimationStyle.hidden(),
          priceLabelStyle: const PriceLabelStyle(show: false),
          timeLabelStyle: const TimeLabelStyle(show: false),
          axisStyle: const AxisStyle(showGrid: false),
          crosshairStyle: const CrosshairStyle(show: false),
        ),
      ),
    );
  }
}
