import 'package:equatable/equatable.dart';

enum TradeType { buy, sell }

/// [Trade] represents a single transaction record in the system.
///
/// It follows the 10/10 financial standard by storing prices in paisa (int).
class Trade extends Equatable {
  final String id;
  final String symbol;
  final String stockName;
  final TradeType type;
  final int quantity;
  final int pricePaisa;      // Price at confirmation time
  final int totalCostPaisa;  // Calculated: pricePaisa * quantity
  final DateTime timestamp;

  const Trade({
    required this.id,
    required this.symbol,
    required this.stockName,
    required this.type,
    required this.quantity,
    required this.pricePaisa,
    required this.totalCostPaisa,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
    id,
    symbol,
    stockName,
    type,
    quantity,
    pricePaisa,
    totalCostPaisa,
    timestamp,
  ];
}
