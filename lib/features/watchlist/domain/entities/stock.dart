import 'package:equatable/equatable.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';

class Stock extends Equatable {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double percentChange;
  final List<Candle> candles;

  const Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.percentChange,
    required this.candles,
  });

  Stock copyWith({
    double? price,
    double? change,
    double? percentChange,
    List<Candle>? candles,
  }) {
    return Stock(
      symbol: symbol,
      name: name,
      price: price ?? this.price,
      change: change ?? this.change,
      percentChange: percentChange ?? this.percentChange,
      candles: candles ?? this.candles,
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
  ];
}
