import '../entities/market_index.dart';
import '../entities/stock.dart';

abstract class WatchlistRepository {
  List<Stock> getInitialStocks();
  List<MarketIndex> getInitialIndices();
}
