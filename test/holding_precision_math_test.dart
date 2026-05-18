import 'package:flutter_test/flutter_test.dart';
import 'package:trading_simulation/features/trading/domain/entities/holding.dart';

void main() {
  group('Holding Precision Math Unit Tests', () {
    test('updateWithBuy calculates weighted average and total cost precisely', () {
      const holding = Holding(
        symbol: 'RELIANCE',
        stockName: 'Reliance Industries',
        quantity: 0,
        totalCostPaisa: 0,
      );

      // Buy 3 shares at 33 Paisa each
      final buy1 = holding.updateWithBuy(3, 33);
      expect(buy1.quantity, 3);
      expect(buy1.totalCostPaisa, 99);
      expect(buy1.avgBuyPricePaisa, 33.0);

      // Buy another 2 shares at 34 Paisa each
      // Total cost: 99 + 68 = 167. Avg price: 167 / 5 = 33.4
      final buy2 = buy1.updateWithBuy(2, 34);
      expect(buy2.quantity, 5);
      expect(buy2.totalCostPaisa, 167);
      expect(buy2.avgBuyPricePaisa, 33.4);
    });

    test('updateWithSell reduces cost basis proportionally to prevent drift', () {
      const holding = Holding(
        symbol: 'TCS',
        stockName: 'Tata Consultancy Services',
        quantity: 3,
        totalCostPaisa: 101, // 3 shares representing 101 paisa cost basis (fractional buy avg: 33.67)
      );

      // Sell 1 share
      // Sold cost basis = (101 * (1 / 3)).round() = (33.67).round() = 34 paisa
      // Remaining cost: 101 - 34 = 67 paisa. Avg price: 67 / 2 = 33.5 paisa
      final sell1 = holding.updateWithSell(1);
      expect(sell1.quantity, 2);
      expect(sell1.totalCostPaisa, 67);
      expect(sell1.avgBuyPricePaisa, 33.5);

      // Sell another 1 share
      // Sold cost basis = (67 * (1 / 2)).round() = (33.5).round() = 34 paisa
      // Remaining cost: 67 - 34 = 33 paisa. Avg price: 33 / 1 = 33.0 paisa
      final sell2 = sell1.updateWithSell(1);
      expect(sell2.quantity, 1);
      expect(sell2.totalCostPaisa, 33);
      expect(sell2.avgBuyPricePaisa, 33.0);

      // Sell the final share
      // Sold cost basis = (33 * (1 / 1)).round() = 33 paisa
      // Remaining cost: 33 - 33 = 0 paisa. Avg price: 0.0
      final sell3 = sell2.updateWithSell(1);
      expect(sell3.quantity, 0);
      expect(sell3.totalCostPaisa, 0);
      expect(sell3.avgBuyPricePaisa, 0.0);
    });
  });
}
