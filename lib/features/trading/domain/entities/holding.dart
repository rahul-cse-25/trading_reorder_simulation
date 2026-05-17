import 'package:equatable/equatable.dart';

/// [Holding] represents a stock owned by the user in their portfolio.
///
/// It uses a weighted average buy price to calculate P&L correctly
/// as the user buys more of the same stock at different prices.
class Holding extends Equatable {
  final String symbol;
  final String stockName;
  final int quantity;
  final int avgBuyPricePaisa;  // Weighted average price in paisa
  final int totalCostPaisa;    // Total amount invested in this stock

  const Holding({
    required this.symbol,
    required this.stockName,
    required this.quantity,
    required this.avgBuyPricePaisa,
    required this.totalCostPaisa,
  });

  /// Logic for updating a holding when a new trade occurs.
  /// This ensures weighted average is always accurate.
  Holding updateWithBuy(int buyQty, int buyPricePaisa) {
    final int newQty = quantity + buyQty;
    final int newTotalCost = totalCostPaisa + (buyQty * buyPricePaisa);
    // Integer division is fine here as we track the cost accurately
    final int newAvgPrice = newTotalCost ~/ newQty;

    return Holding(
      symbol: symbol,
      stockName: stockName,
      quantity: newQty,
      avgBuyPricePaisa: newAvgPrice,
      totalCostPaisa: newTotalCost,
    );
  }

  Holding updateWithSell(int sellQty) {
    final int newQty = quantity - sellQty;
    // Avg price stays the same on sell, we just reduce volume and total cost proportionally
    final int newTotalCost = (newQty * avgBuyPricePaisa);

    return Holding(
      symbol: symbol,
      stockName: stockName,
      quantity: newQty,
      avgBuyPricePaisa: avgBuyPricePaisa,
      totalCostPaisa: newTotalCost,
    );
  }

  @override
  List<Object?> get props => [
    symbol,
    stockName,
    quantity,
    avgBuyPricePaisa,
    totalCostPaisa,
  ];
}
