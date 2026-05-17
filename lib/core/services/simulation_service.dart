import 'dart:async';
import 'dart:math';

import '../../features/trading/domain/entities/trade.dart';
import '../../features/watchlist/domain/entities/market_index.dart';
import '../../features/watchlist/domain/entities/stock.dart';

class MarketUpdate {
  final String symbol;
  final double newPrice;

  MarketUpdate({required this.symbol, required this.newPrice});
}

class SimulationService {
  final _controller = StreamController<List<MarketUpdate>>.broadcast();
  Timer? _timer;
  final _random = Random();
  final Map<String, double> _shocks = {}; // symbol -> price_shock_multiplier

  Stream<List<MarketUpdate>> get stream => _controller.stream;

  void applyMarketImpact(String symbol, int quantity, TradeType type) {
    // Large trades have more impact (Logarithmic scale for realism)
    // Strength: Up to 1.5% shock for huge orders
    final impactStrength = (log(quantity + 1) / log(10000)) * 0.015;
    final direction = type == TradeType.buy ? 1.0 : -1.0;

    _shocks[symbol] = (_shocks[symbol] ?? 0.0) + (direction * impactStrength);
  }

  void start({
    required List<Stock> stocks,
    required List<MarketIndex> indices,
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      final List<MarketUpdate> updates = [];

      // Perform 3 updates per tick for higher activity
      for (int i = 0; i < 3; i++) {
        if (_random.nextDouble() > 0.3 && stocks.isNotEmpty) {
          updates.add(_generateStockUpdate(stocks));
        } else if (indices.isNotEmpty) {
          updates.add(_generateIndexUpdate(indices));
        }
      }

      if (updates.isNotEmpty) {
        _controller.add(updates);
      }
    });
  }

  MarketUpdate _generateStockUpdate(List<Stock> stocks) {
    final stock = stocks[_random.nextInt(stocks.length)];

    // Natural Drift (Slight upward bias for simulation feel)
    final changePercent = (_random.nextDouble() - 0.48) * 0.006;

    // Apply and decay shocks over time (Mean Reversion / Dissipation)
    final shock = _shocks[stock.symbol] ?? 0.0;
    _shocks[stock.symbol] = shock * 0.90; // 10% dissipation per tick

    final totalChange = changePercent + shock;
    final newPrice = stock.price * (1 + totalChange);

    return MarketUpdate(
      symbol: stock.symbol,
      newPrice: double.parse(newPrice.toStringAsFixed(2)),
    );
  }

  MarketUpdate _generateIndexUpdate(List<MarketIndex> indices) {
    final index = indices[_random.nextInt(indices.length)];
    final changePercent = (_random.nextDouble() - 0.5) * 0.002; // +/- 0.1%
    final newPrice = index.price * (1 + changePercent);

    return MarketUpdate(
      symbol: index.symbol,
      newPrice: double.parse(newPrice.toStringAsFixed(2)),
    );
  }

  void stop() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
