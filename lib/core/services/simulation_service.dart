import 'dart:async';
import 'dart:math';
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

  Stream<List<MarketUpdate>> get stream => _controller.stream;

  void start({
    required List<Stock> stocks,
    required List<MarketIndex> indices,
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      final List<MarketUpdate> updates = [];

      // Perform 2 updates per tick (Optimized for performance)
      for (int i = 0; i < 2; i++) {
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
    final changePercent = (_random.nextDouble() - 0.5) * 0.005; // +/- 0.25%
    final newPrice = stock.price * (1 + changePercent);

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
