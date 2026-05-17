import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repository/trade_repository.dart';
import '../../domain/usecases/execute_trade_usecase.dart';
import 'trade_event.dart';
import 'trade_state.dart';

class TradeBloc extends Bloc<TradeEvent, TradeState> {
  final ExecuteTradeUseCase executeTrade;
  final TradeRepository repository;

  TradeBloc({required this.executeTrade, required this.repository})
    : super(TradeInitial()) {
    on<ExecuteTrade>(_onExecuteTrade);
    on<LoadHistory>(_onLoadHistory);
  }

  Future<void> _onExecuteTrade(
    ExecuteTrade event,
    Emitter<TradeState> emit,
  ) async {
    emit(TradeLoading());

    final result = await executeTrade(
      symbol: event.symbol,
      stockName: event.stockName,
      quantity: event.quantity,
      type: event.type,
      pricePaisa: event.livePricePaisa,
    );

    switch (result) {
      case ExecuteTradeSuccess(:final trade):
        emit(TradeSuccess(trade));
        // Refresh history and balance after success
        add(LoadHistory());
      case ExecuteTradeFailure(:final message):
        emit(TradeFailure(message));
    }
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<TradeState> emit,
  ) async {
    final history = await repository.getTradeHistory();
    emit(HistoryLoaded(history: history));
  }
}
