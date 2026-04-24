import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../domain/entities/stock.dart';

class StockChartWidget extends StatefulWidget {
  final Stock stock;

  const StockChartWidget({super.key, required this.stock});

  @override
  State<StockChartWidget> createState() => _StockChartWidgetState();
}

class _StockChartWidgetState extends State<StockChartWidget> {
  Candle? _hoveredCandle;

  @override
  Widget build(BuildContext context) {
    if (widget.stock.candles.isEmpty) return const SizedBox();
    final currentCandle = _hoveredCandle ?? widget.stock.candles.last;

    return Stack(
      children: [
        ImpChart.trading(
          candles: widget.stock.candles,
          onCrosshairChanged: (candle) {
            setState(() {
              _hoveredCandle = candle;
            });
          },
        ),
        Positioned(
          top: 8,
          left: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOhlcRow(currentCandle),
                const SizedBox(height: 4),
                _buildVolumeRow(currentCandle),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOhlcRow(Candle candle) {
    final isBullish = candle.close >= candle.open;
    final color = isBullish ? Colors.greenAccent : Colors.redAccent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Wrap(
            runSpacing: 4,
            spacing: 8,
            children: [
              StyledTextPair.highlighted(
                label: "O ",
                value: _formatNumber(candle.open),
                valueColor: Colors.white,
              ),
              StyledTextPair.highlighted(
                label: "H ",
                value: _formatNumber(candle.high),
                valueColor: Colors.greenAccent,
              ),
              StyledTextPair.highlighted(
                label: "L ",
                value: _formatNumber(candle.low),
                valueColor: Colors.redAccent,
              ),
              StyledTextPair.highlighted(
                label: "C ",
                value: _formatNumber(candle.close),
                valueColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeRow(Candle candle) {
    final isBullish = candle.close >= candle.open;
    final color = isBullish ? Colors.greenAccent : Colors.redAccent;
    final change = candle.close - candle.open;
    final percent = (change / candle.open) * 100;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              StyledTextPair.highlighted(
                label: "Volume ",
                value: _formatNumber(candle.volume),
                valueColor: Colors.white,
              ),
              StyledTextPair.highlighted(
                label: "${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} ",
                value: "(${percent.toStringAsFixed(2)}%)",
                labelColor: color,
                valueColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(double? data) {
    return NumberFormat.currency(symbol: '', decimalDigits: 2).format(data);
  }
}

/// A reusable RichText widget with two differently styled text spans.
///
/// Perfect for displaying label-value pairs like:
/// - "Open: 1.2345"
/// - "Price: $100"
/// - "Volume: 1.5M"
///
/// Usage:
/// ```dart
/// StyledTextPair(
///   first: 'Open: ',
///   second: '1.2345',
///   firstStyle: TextStyle(color: Colors.grey),
///   secondStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
/// )
/// ```
class StyledTextPair extends StatelessWidget {
  /// First text (e.g., label)
  final String first;

  /// Second text (e.g., value)
  final String second;

  /// Style for the first text
  final TextStyle? firstStyle;

  /// Style for the second text
  final TextStyle? secondStyle;

  /// Text alignment (default: start)
  final TextAlign? textAlign;

  /// Max lines before truncation (default: 1)
  final int? maxLines;

  /// Overflow behavior (default: ellipsis)
  final TextOverflow? overflow;

  const StyledTextPair({
    super.key,
    required this.first,
    required this.second,
    this.firstStyle,
    this.secondStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines ?? 1,
      overflow: overflow ?? TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: first,
            style: firstStyle ?? DefaultTextStyle.of(context).style,
          ),
          TextSpan(
            text: second,
            style: secondStyle ?? DefaultTextStyle.of(context).style,
          ),
        ],
      ),
    );
  }

  /// Factory: Label-value style with grey label and white bold value
  factory StyledTextPair.labelValue({
    Key? key,
    required String label,
    required String value,
    Color labelColor = Colors.grey,
    Color valueColor = Colors.white,
    double fontSize = 12.0,
    FontWeight valueFontWeight = FontWeight.w600,
    TextAlign? textAlign,
    int? maxLine,
  }) {
    return StyledTextPair(
      key: key,
      first: label,
      second: value,
      textAlign: textAlign,
      maxLines: maxLine,
      overflow: TextOverflow.ellipsis,
      firstStyle: TextStyle(color: labelColor, fontSize: fontSize),
      secondStyle: TextStyle(
        color: valueColor,
        fontSize: fontSize,
        fontWeight: valueFontWeight,
      ),
    );
  }

  /// Factory: Compact style for small spaces
  factory StyledTextPair.compact({
    Key? key,
    required String first,
    required String second,
    Color firstColor = Colors.grey,
    Color secondColor = Colors.white,
    double fontSize = 10.0,
  }) {
    return StyledTextPair(
      key: key,
      first: first,
      second: second,
      firstStyle: TextStyle(color: firstColor, fontSize: fontSize),
      secondStyle: TextStyle(
        color: secondColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Factory: Highlighted value with accent color
  factory StyledTextPair.highlighted({
    Key? key,
    required String label,
    required String value,
    Color labelColor = Colors.white70,
    Color valueColor = const Color(0xFF4EF2A8), // Green accent
    double fontSize = 12.0,
  }) {
    return StyledTextPair(
      key: key,
      first: label,
      second: value,
      firstStyle: TextStyle(color: labelColor, fontSize: fontSize),
      secondStyle: TextStyle(
        color: valueColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
