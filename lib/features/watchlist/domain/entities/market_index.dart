import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';

class MarketIndex extends Equatable {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double percentChange;
  final List<Candle> candles;
  final Color bgColor;

  const MarketIndex({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.percentChange,
    required this.candles,
    required this.bgColor,
  });

  MarketIndex copyWith({
    double? price,
    double? change,
    double? percentChange,
    List<Candle>? candles,
    Color? bgColor,
  }) {
    return MarketIndex(
      symbol: symbol,
      name: name,
      price: price ?? this.price,
      change: change ?? this.change,
      percentChange: percentChange ?? this.percentChange,
      candles: candles ?? this.candles,
      bgColor: bgColor ?? this.bgColor,
    );
  }

  @override
  List<Object?> get props => [
    symbol,
    name,
    price,
    change,
    percentChange,
    candles,
    bgColor,
  ];
}
