import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/events/trading_orchestrator.dart';
import '../../../../core/services/simulation_service.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../trading/domain/repository/trade_repository.dart';
import 'portfolio_event.dart';
import 'portfolio_state.dart';

/// [PortfolioBloc] manages the state of the user's trading holdings portfolio.
/// It is decoupled from the Watchlist feature by listening directly to [SimulationService]
/// for price updates, avoiding DI scope mismatches and laggy disk operations.
class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final TradeRepository repository;
  final TradingOrchestrator orchestrator;
  final SimulationService simulationService;
  StreamSubscription? _simulationSubscription;
  StreamSubscription? _orchestratorSubscription;

  PortfolioBloc({
    required this.repository,
    required this.orchestrator,
    required this.simulationService,
  }) : super(PortfolioInitial()) {
    on<LoadPortfolio>(_onLoadPortfolio);
    on<UpdateLivePrices>(_onUpdateLivePrices);

    // Listen to live prices directly from the SimulationService (Direct & Decoupled)
    _simulationSubscription = simulationService.stream.listen((updates) {
      final Map<String, double> prices = {
        for (var update in updates) update.symbol: update.newPrice,
      };
      add(UpdateLivePrices(prices));
    });

    // Listen for trade completion events to update holdings reactively (WebSocket Mimic)
    _orchestratorSubscription = orchestrator.events.listen((event) {
      if (event is TradeCompletedEvent) {
        add(LoadPortfolio()); 
      }
    });
  }

  Future<void> _onLoadPortfolio(
    LoadPortfolio event,
    Emitter<PortfolioState> emit,
  ) async {
    emit(PortfolioLoading());
    await _calculateAndEmit(emit);
  }

  Future<void> _onUpdateLivePrices(
    UpdateLivePrices event,
    Emitter<PortfolioState> emit,
  ) async {
    final currentState = state;
    
    // Performance Guard: If already loaded, calculate new values synchronously using 
    // the cached holdings from state. This completely avoids laggy disk reads on every tick!
    if (currentState is PortfolioLoaded) {
      final prices = event.prices;
      int totalInvested = 0;
      int totalCurrentValue = 0;
      final List<HoldingDisplayModel> displayModels = [];

      for (final model in currentState.holdings) {
        final holding = model.holding;
        final currentPrice = prices[holding.symbol] ?? model.currentPrice;
        final currentPricePaisa = MoneyUtils.toPaisa(currentPrice);

        final currentValuePaisa = currentPricePaisa * holding.quantity;
        final investedPaisa = holding.totalCostPaisa;
        final pnlPaisa = currentValuePaisa - investedPaisa;

        final pnlPercent = investedPaisa > 0
            ? (pnlPaisa * 100.0) / investedPaisa
            : 0.0;

        totalInvested += investedPaisa;
        totalCurrentValue += currentValuePaisa;

        displayModels.add(
          HoldingDisplayModel(
            holding: holding,
            currentPrice: currentPrice,
            currentValuePaisa: currentValuePaisa,
            pnlPaisa: pnlPaisa,
            pnlPercent: pnlPercent,
          ),
        );
      }

      // Auto-sort by P&L descending (Movers on top)
      displayModels.sort((a, b) => b.pnlPaisa.compareTo(a.pnlPaisa));

      final totalPnL = totalCurrentValue - totalInvested;
      final totalPnLPercent = totalInvested > 0
          ? (totalPnL * 100.0) / totalInvested
          : 0.0;

      emit(
        PortfolioLoaded(
          holdings: displayModels,
          totalInvestedPaisa: totalInvested,
          totalCurrentValuePaisa: totalCurrentValue,
          totalPnLPaisa: totalPnL,
          totalPnLPercent: totalPnLPercent,
        ),
      );
    } else if (currentState is PortfolioEmpty || currentState is PortfolioInitial) {
      // If portfolio is empty or uninitialized, do a standard load (database fetch)
      await _calculateAndEmit(emit, livePrices: event.prices);
    }
  }

  Future<void> _calculateAndEmit(
    Emitter<PortfolioState> emit, {
    Map<String, double>? livePrices,
  }) async {
    final holdings = await repository.getHoldings();

    if (holdings.isEmpty) {
      emit(PortfolioEmpty());
      return;
    }

    final prices = livePrices ?? {};

    int totalInvested = 0;
    int totalCurrentValue = 0;
    final List<HoldingDisplayModel> displayModels = [];

    for (final holding in holdings) {
      final currentPrice =
          prices[holding.symbol] ??
          MoneyUtils.toRupees(holding.avgBuyPricePaisa);
      final currentPricePaisa = MoneyUtils.toPaisa(currentPrice);

      final currentValuePaisa = currentPricePaisa * holding.quantity;
      final investedPaisa = holding.totalCostPaisa;
      final pnlPaisa = currentValuePaisa - investedPaisa;

      final pnlPercent = investedPaisa > 0
          ? (pnlPaisa * 100.0) / investedPaisa
          : 0.0;

      totalInvested += investedPaisa;
      totalCurrentValue += currentValuePaisa;

      displayModels.add(
        HoldingDisplayModel(
          holding: holding,
          currentPrice: currentPrice,
          currentValuePaisa: currentValuePaisa,
          pnlPaisa: pnlPaisa,
          pnlPercent: pnlPercent,
        ),
      );
    }

    // Auto-sort by P&L descending (Movers on top)
    displayModels.sort((a, b) => b.pnlPaisa.compareTo(a.pnlPaisa));

    final totalPnL = totalCurrentValue - totalInvested;
    final totalPnLPercent = totalInvested > 0
        ? (totalPnL * 100.0) / totalInvested
        : 0.0;

    emit(
      PortfolioLoaded(
        holdings: displayModels,
        totalInvestedPaisa: totalInvested,
        totalCurrentValuePaisa: totalCurrentValue,
        totalPnLPaisa: totalPnL,
        totalPnLPercent: totalPnLPercent,
      ),
    );
  }

  @override
  Future<void> close() {
    _simulationSubscription?.cancel();
    _orchestratorSubscription?.cancel();
    return super.close();
  }
}
