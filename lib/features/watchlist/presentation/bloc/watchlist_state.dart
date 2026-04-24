import '../../domain/entities/market_index.dart';
import '../../domain/entities/stock.dart';

class WatchlistState {
  final List<Stock> stocks;
  final List<MarketIndex> indices;
  final bool isLoading;

  WatchlistState({
    required this.stocks,
    required this.indices,
    this.isLoading = false,
  });

  WatchlistState copyWith({
    List<Stock>? stocks,
    List<MarketIndex>? indices,
    bool? isLoading,
  }) {
    return WatchlistState(
      stocks: stocks ?? this.stocks,
      indices: indices ?? this.indices,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
