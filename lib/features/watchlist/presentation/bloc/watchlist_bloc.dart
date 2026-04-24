import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imp_trading_chart/imp_trading_chart.dart';
import '../../../../core/services/simulation_service.dart';
import '../../domain/entities/stock.dart';
import '../../domain/repository/watchlist_repository.dart';
import 'watchlist_event.dart';
import 'watchlist_state.dart';

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  final WatchlistRepository repository;
  final SimulationService simulationService;
  StreamSubscription? _simulationSubscription;

  WatchlistBloc(this.repository, this.simulationService)
    : super(WatchlistState(stocks: [], indices: [])) {
    on<LoadStocks>(_onLoadStocks);
    on<ReorderStocks>(_onReorderStocks);
    on<UpdateStockPrice>(_onUpdatePrice);

    _simulationSubscription = simulationService.stream.listen((event) {
      add(UpdateStockPrice(event.symbol, event.newPrice));
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

  void _onUpdatePrice(UpdateStockPrice event, Emitter<WatchlistState> emit) {
    // Check stocks
    bool updated = false;
    final updatedStocks = state.stocks.map((stock) {
      if (stock.symbol == event.symbol) {
        updated = true;
        final newPrice = event.newPrice;
        final change = newPrice - stock.price;
        final percentChange = (change / stock.price) * 100;

        final candles = List<Candle>.from(stock.candles);
        if (candles.isNotEmpty) {
          final lastCandle = candles.last;
          final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          // If more than 60 seconds passed since last candle started, create a new one
          if (nowSeconds - lastCandle.time >= 60) {
            candles.add(
              Candle(
                time: nowSeconds,
                open: lastCandle.close,
                high: newPrice > lastCandle.close ? newPrice : lastCandle.close,
                low: newPrice < lastCandle.close ? newPrice : lastCandle.close,
                close: newPrice,
                volume: 5000 + (newPrice % 100) * 10,
              ),
            );
          } else {
            candles[candles.length - 1] = Candle(
              time: lastCandle.time,
              open: lastCandle.open,
              high: newPrice > lastCandle.high ? newPrice : lastCandle.high,
              low: newPrice < lastCandle.low ? newPrice : lastCandle.low,
              close: newPrice,
              volume: (lastCandle.volume ?? 0) + 1000 + (newPrice % 50) * 5,
            );
          }
        }

        return stock.copyWith(
          price: newPrice,
          change: change,
          percentChange: percentChange,
          candles: candles,
        );
      }
      return stock;
    }).toList();

    if (updated) {
      emit(state.copyWith(stocks: updatedStocks));
      return;
    }

    // Check indices
    final updatedIndices = state.indices.map((index) {
      if (index.symbol == event.symbol) {
        final newPrice = event.newPrice;
        final change = newPrice - index.price;
        final percentChange = (change / index.price) * 100;

        final candles = List<Candle>.from(index.candles);
        if (candles.isNotEmpty) {
          final lastCandle = candles.last;
          final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          if (nowSeconds - lastCandle.time >= 60) {
            candles.add(
              Candle(
                time: nowSeconds,
                open: lastCandle.close,
                high: newPrice > lastCandle.close ? newPrice : lastCandle.close,
                low: newPrice < lastCandle.close ? newPrice : lastCandle.close,
                close: newPrice,
                volume: 5000 + (newPrice % 100) * 10,
              ),
            );
          } else {
            candles[candles.length - 1] = Candle(
              time: lastCandle.time,
              open: lastCandle.open,
              high: newPrice > lastCandle.high ? newPrice : lastCandle.high,
              low: newPrice < lastCandle.low ? newPrice : lastCandle.low,
              close: newPrice,
              volume: (lastCandle.volume ?? 0) + 1000 + (newPrice % 50) * 5,
            );
          }
        }

        return index.copyWith(
          price: newPrice,
          change: change,
          percentChange: percentChange,
          candles: candles,
        );
      }
      return index;
    }).toList();

    emit(state.copyWith(indices: updatedIndices));
  }

  @override
  Future<void> close() {
    _simulationSubscription?.cancel();
    return super.close();
  }
}
