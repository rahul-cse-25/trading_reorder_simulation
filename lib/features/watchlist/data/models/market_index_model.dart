import 'dart:ui' show Color;

import 'package:imp_trading_chart/imp_trading_chart.dart';

class MarketIndexModel {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double percentChange;
  final List<Candle> candles;
  final Color bgColor;

  MarketIndexModel({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.percentChange,
    required this.candles,
    required this.bgColor,
  });

  factory MarketIndexModel.fromJson(Map<String, dynamic> json) {
    return MarketIndexModel(
      symbol: json['symbol'],
      name: json['name'],
      price: json['price'].toDouble(),
      change: json['change'].toDouble(),
      percentChange: json['percentChange'].toDouble(),
      candles: [],
      // Placeholder or map from JSON if available
      bgColor: json['bgColor'],
    );
  }
}
