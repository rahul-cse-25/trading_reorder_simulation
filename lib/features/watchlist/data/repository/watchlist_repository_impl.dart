import 'dart:convert';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../domain/entities/custom_watchlist.dart';
import '../../domain/entities/market_index.dart';
import '../../domain/entities/stock.dart';
import '../../domain/repository/watchlist_repository.dart';
import '../../mapper/market_index_mapper.dart';
import '../../mapper/stock_mapper.dart';
import '../datasource/mock_watchlist_data.dart';

class WatchlistRepositoryImpl implements WatchlistRepository {
  final MockWatchlistData dataSource;
  final LocalStorageService storage;

  WatchlistRepositoryImpl(this.dataSource, this.storage);

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

  @override
  List<String> getAllAvailableSymbols() {
    return dataSource.getInitialData().map((s) => s.symbol).toList();
  }

  @override
  Future<List<CustomWatchlist>> getWatchlists() async {
    final jsonString = await storage.getString(StorageKeys.watchlists);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => CustomWatchlist.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveWatchlists(List<CustomWatchlist> watchlists) async {
    final jsonString = jsonEncode(
      watchlists.map((w) => w.toJson()).toList(),
    );
    await storage.saveString(StorageKeys.watchlists, jsonString);
  }
}
