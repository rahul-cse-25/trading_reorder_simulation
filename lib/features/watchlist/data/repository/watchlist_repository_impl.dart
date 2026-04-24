import '../../domain/entities/market_index.dart';
import '../../domain/entities/stock.dart';
import '../../domain/repository/watchlist_repository.dart';
import '../../mapper/market_index_mapper.dart';
import '../../mapper/stock_mapper.dart';
import '../datasource/mock_watchlist_data.dart';

class WatchlistRepositoryImpl implements WatchlistRepository {
  final MockWatchlistData dataSource;

  WatchlistRepositoryImpl(this.dataSource);

  @override
  List<Stock> getInitialStocks() {
    final models = dataSource.getInitialData();
    return models.map(StockMapper.toEntity).toList();
  }

  @override
  List<MarketIndex> getInitialIndices() {
    final models = dataSource.getInitialIndices();
    return models.map(MarketIndexMapper.toEntity).toList();
  }
}
