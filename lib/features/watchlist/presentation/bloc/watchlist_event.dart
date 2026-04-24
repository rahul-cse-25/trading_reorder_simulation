import '../../../../core/services/simulation_service.dart';

abstract class WatchlistEvent {}

class LoadStocks extends WatchlistEvent {}

class ReorderStocks extends WatchlistEvent {
  final int oldIndex;
  final int newIndex;

  ReorderStocks({required this.oldIndex, required this.newIndex});
}

class UpdateStockPrice extends WatchlistEvent {
  final String symbol;
  final double newPrice;

  UpdateStockPrice(this.symbol, this.newPrice);
}

class UpdateMarketBatch extends WatchlistEvent {
  final List<MarketUpdate> updates;

  UpdateMarketBatch(this.updates);
}
