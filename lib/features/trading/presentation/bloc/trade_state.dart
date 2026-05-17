import 'package:equatable/equatable.dart';
import '../../domain/entities/trade.dart';

sealed class TradeState extends Equatable {
  const TradeState();

  @override
  List<Object?> get props => [];
}

class TradeInitial extends TradeState {}

class TradeLoading extends TradeState {}

class TradeSuccess extends TradeState {
  final Trade trade;
  const TradeSuccess(this.trade);

  @override
  List<Object?> get props => [trade];
}

class TradeFailure extends TradeState {
  final String message;
  const TradeFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class HistoryLoaded extends TradeState {
  final List<Trade> history;

  const HistoryLoaded({required this.history});

  @override
  List<Object?> get props => [history];
}
