import '../../domain/entities/trade.dart';

sealed class TradeEvent {}

class ExecuteTrade extends TradeEvent {
  final String symbol;
  final String stockName;
  final int quantity;
  final TradeType type;
  final int livePricePaisa;

  ExecuteTrade({
    required this.symbol,
    required this.stockName,
    required this.quantity,
    required this.type,
    required this.livePricePaisa,
  });
}

class LoadHistory extends TradeEvent {}

class ClearHistory extends TradeEvent {}
