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
  final _controller = StreamController<MarketUpdate>.broadcast();
  Timer? _timer;
  final _random = Random();

  Stream<MarketUpdate> get stream => _controller.stream;

  void start({
    required List<Stock> stocks,
    required List<MarketIndex> indices,
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      // Perform at least 3 updates per tick
      for (int i = 0; i < 3; i++) {
        // 70% chance to update a stock, 30% for an index (since there are more stocks)
        if (_random.nextDouble() > 0.3 && stocks.isNotEmpty) {
          _updateStock(stocks);
        } else if (indices.isNotEmpty) {
          _updateIndex(indices);
        }
      }
    });
  }

  void _updateStock(List<Stock> stocks) {
    final stock = stocks[_random.nextInt(stocks.length)];
    final changePercent = (_random.nextDouble() - 0.5) * 0.005; // +/- 0.25%
    final newPrice = stock.price * (1 + changePercent);

    _controller.add(
      MarketUpdate(
        symbol: stock.symbol,
        newPrice: double.parse(newPrice.toStringAsFixed(2)),
      ),
    );
  }

  void _updateIndex(List<MarketIndex> indices) {
    final index = indices[_random.nextInt(indices.length)];
    final changePercent = (_random.nextDouble() - 0.5) * 0.002; // +/- 0.1%
    final newPrice = index.price * (1 + changePercent);

    _controller.add(
      MarketUpdate(
        symbol: index.symbol,
        newPrice: double.parse(newPrice.toStringAsFixed(2)),
      ),
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
