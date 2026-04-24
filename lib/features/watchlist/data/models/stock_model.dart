import 'package:imp_trading_chart/imp_trading_chart.dart';

class StockModel {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double percentChange;
  final List<Candle> candles;

  StockModel({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.percentChange,
    required this.candles,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      symbol: json['symbol'],
      name: json['name'],
      price: json['price'],
      change: json['change'],
      percentChange: json['percentChange'],
      candles: (json['candles'] as List)
          .map(
            (c) => Candle(
              time: c['timestamp'] ?? c['time'],
              open: c['open'],
              high: c['high'],
              low: c['low'],
              close: c['close'],
            ),
          )
          .toList(),
    );
  }
}
