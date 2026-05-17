import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';
import '../../../../core/services/simulation_service.dart';
import '../../domain/entities/market_index.dart';
import '../../domain/entities/stock.dart';
import '../../domain/repository/watchlist_repository.dart';
import 'watchlist_event.dart';
import 'watchlist_state.dart';

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  final WatchlistRepository repository;
  final SimulationService simulationService;
  StreamSubscription? _simulationSubscription;

  WatchlistBloc(this.repository, this.simulationService)
    : super(const WatchlistState(stocks: [], indices: [])) {
    on<LoadStocks>(_onLoadStocks);
    on<ReorderStocks>(_onReorderStocks);
    on<UpdateStockPrice>(_onUpdatePrice);
    on<UpdateMarketBatch>(_onUpdateMarketBatch);

    _simulationSubscription = simulationService.stream.listen((updates) {
      add(UpdateMarketBatch(updates));
    });
  }

  Future<void> _onLoadStocks(
    LoadStocks event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final stocks = repository.getInitialStocks();
    final indices = repository.getInitialIndices();
    emit(state.copyWith(stocks: stocks, indices: indices, isLoading: false));
    simulationService.start(stocks: stocks, indices: indices);
  }

  void _onReorderStocks(ReorderStocks event, Emitter<WatchlistState> emit) {
    final stocks = List<Stock>.from(state.stocks);
    var oldIndex = event.oldIndex;
    var newIndex = event.newIndex;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = stocks.removeAt(oldIndex);
    stocks.insert(newIndex, item);

    emit(state.copyWith(stocks: stocks));
  }

  void _onUpdateMarketBatch(
    UpdateMarketBatch event,
    Emitter<WatchlistState> emit,
  ) {
    List<Stock> currentStocks = List<Stock>.from(state.stocks);
    List<MarketIndex> currentIndices = List<MarketIndex>.from(state.indices);

    for (final update in event.updates) {
      // Update Stocks
      int stockIndex = currentStocks.indexWhere(
        (s) => s.symbol == update.symbol,
      );
      if (stockIndex != -1) {
        currentStocks[stockIndex] = _processStockUpdate(
          currentStocks[stockIndex],
          update,
        );
        continue;
      }

      // Update Indices
      int indexIdx = currentIndices.indexWhere(
        (i) => i.symbol == update.symbol,
      );
      if (indexIdx != -1) {
        currentIndices[indexIdx] = _processIndexUpdate(
          currentIndices[indexIdx],
          update,
        );
      }
    }

    emit(state.copyWith(stocks: currentStocks, indices: currentIndices));
  }

  Stock _processStockUpdate(Stock stock, MarketUpdate update) {
    final candles = _updateCandles(stock.candles, update.newPrice, update.marketTimeSeconds);

    return stock.copyWith(
      price: update.newPrice,
      change: update.change,
      percentChange: update.percentChange,
      candles: candles,
    );
  }

  MarketIndex _processIndexUpdate(MarketIndex index, MarketUpdate update) {
    final candles = _updateCandles(index.candles, update.newPrice, update.marketTimeSeconds);

    return index.copyWith(
      price: update.newPrice,
      change: update.change,
      percentChange: update.percentChange,
      candles: candles,
    );
  }

  List<Candle> _updateCandles(List<Candle> currentCandles, double newPrice, int marketTimeSeconds) {
    // Cloning the list to maintain immutability and ensure Bloc state transitions are pure
    final candles = List<Candle>.from(currentCandles);
    if (candles.isEmpty) return candles;

    final lastCandle = candles.last;

    if (marketTimeSeconds - lastCandle.time >= 60) {
      // Start a new candle every 60 seconds
      candles.add(
        Candle(
          time: marketTimeSeconds,
          open: lastCandle.close,
          high: newPrice > lastCandle.close ? newPrice : lastCandle.close,
          low: newPrice < lastCandle.close ? newPrice : lastCandle.close,
          close: newPrice,
          volume: 5000 + (newPrice % 100) * 10,
        ),
      );
      // Performance Safeguard: Keep candle history capped to 20 for optimal rendering
      if (candles.length > 20) candles.removeAt(0);
    } else {
      // Update the current candle with latest tick
      candles[candles.length - 1] = Candle(
        time: lastCandle.time,
        open: lastCandle.open,
        high: newPrice > lastCandle.high ? newPrice : lastCandle.high,
        low: newPrice < lastCandle.low ? newPrice : lastCandle.low,
        close: newPrice,
        volume: (lastCandle.volume ?? 0) + 1000 + (newPrice % 50) * 5,
      );
    }
    return candles;
  }

  void _onUpdatePrice(UpdateStockPrice event, Emitter<WatchlistState> emit) {
    // Kept for backward compatibility or individual updates
    add(
      UpdateMarketBatch([
        MarketUpdate(
          symbol: event.symbol,
          newPrice: event.newPrice,
          change: 0.0,
          percentChange: 0.0,
          marketTimeSeconds: 33300,
          day: 1,
        ),
      ]),
    );
  }

  @override
  Future<void> close() {
    _simulationSubscription?.cancel();
    simulationService
        .dispose(); // CRITICAL: Properly dispose simulation service
    return super.close();
  }
}
