import 'package:equatable/equatable.dart';

/// [Holding] represents a stock owned by the user in their portfolio.
///
/// It uses a weighted average buy price to calculate P&L correctly
/// as the user buys more of the same stock at different prices.
class Holding extends Equatable {
  final String symbol;
  final String stockName;
  final int quantity;
  final int totalCostPaisa;    // Total amount invested in this stock

  const Holding({
    required this.symbol,
    required this.stockName,
    required this.quantity,
    required this.totalCostPaisa,
  });

  /// Derived average price in paisa for display (Double precision)
  double get avgBuyPricePaisa => quantity > 0 ? totalCostPaisa / quantity : 0.0;

  /// Logic for updating a holding when a new trade occurs.
  /// This ensures weighted average is always accurate.
  Holding updateWithBuy(int buyQty, int buyPricePaisa) {
    final int newQty = quantity + buyQty;
    final int newTotalCost = totalCostPaisa + (buyQty * buyPricePaisa);

    return Holding(
      symbol: symbol,
      stockName: stockName,
      quantity: newQty,
      totalCostPaisa: newTotalCost,
    );
  }

  Holding updateWithSell(int sellQty) {
    final int newQty = quantity - sellQty;
    // Proportional cost reduction using exact fractional math to prevent cost basis drift
    final int soldCostBasis = (totalCostPaisa * (sellQty / quantity)).round();
    final int newTotalCost = totalCostPaisa - soldCostBasis;

    return Holding(
      symbol: symbol,
      stockName: stockName,
      quantity: newQty,
      totalCostPaisa: newTotalCost,
    );
  }

  @override
  List<Object?> get props => [
    symbol,
    stockName,
    quantity,
    totalCostPaisa,
  ];
}
