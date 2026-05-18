import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/events/trading_orchestrator.dart';
import '../../domain/repository/trade_repository.dart';

/// [WalletCubit] is the single source of truth for the user's cash balance.
///
/// It listens to the [TradingOrchestrator] to update the balance
/// automatically whenever a trade occurs.
class WalletCubit extends Cubit<int> {
  final TradeRepository repository;
  final TradingOrchestrator orchestrator;
  StreamSubscription? _orchestratorSubscription;

  WalletCubit({required this.repository, required this.orchestrator})
    : super(0) {
    _init();

    // Listen for trade completion events to update balance reactively
    _orchestratorSubscription = orchestrator.events.listen((event) {
      if (event is TradeCompletedEvent) {
        emit(event.newBalancePaisa);
      }
    });
  }

  Future<void> _init() async {
    final balance = await repository.getWalletBalance();
    emit(balance);
  }

  /// Manually add funds (e.g., from the "Add Funds" CTA)
  Future<void> addFunds(int amountPaisa) async {
    final newBalance = state + amountPaisa;
    await repository.updateWalletBalance(newBalance);
    emit(newBalance);
  }

  @override
  Future<void> close() {
    _orchestratorSubscription?.cancel();
    return super.close();
  }
}
