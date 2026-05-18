import '../entities/custom_watchlist.dart';
import '../entities/market_index.dart';
import '../entities/stock.dart';

/// [WatchlistRepository] defines the contract for watchlist data operations.
abstract class WatchlistRepository {
  List<Stock> getInitialStocks();
  List<MarketIndex> getInitialIndices();

  /// Custom watchlist CRUD
  Future<List<CustomWatchlist>> getWatchlists();
  Future<void> saveWatchlists(List<CustomWatchlist> watchlists);

  /// Returns the ordered list of all available stock symbols
  List<String> getAllAvailableSymbols();
}
