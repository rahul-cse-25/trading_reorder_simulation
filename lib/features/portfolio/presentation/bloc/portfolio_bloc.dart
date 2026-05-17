import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/events/trading_orchestrator.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../trading/domain/repository/trade_repository.dart';
import '../../../watchlist/presentation/bloc/watchlist_bloc.dart';
import 'portfolio_event.dart';
import 'portfolio_state.dart';

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final TradeRepository repository;
  final WatchlistBloc watchlistBloc;
  final TradingOrchestrator orchestrator;
  StreamSubscription? _watchlistSubscription;
  StreamSubscription? _orchestratorSubscription;

  PortfolioBloc({
    required this.repository,
    required this.watchlistBloc,
    required this.orchestrator,
  }) : super(PortfolioInitial()) {
    on<LoadPortfolio>(_onLoadPortfolio);
    on<UpdateLivePrices>(_onUpdateLivePrices);

    // Listen to live prices from WatchlistBloc
    _watchlistSubscription = watchlistBloc.stream.listen((watchlistState) {
      final Map<String, double> prices = {
        for (var stock in watchlistState.stocks) stock.symbol: stock.price,
      };
      add(UpdateLivePrices(prices));
    });

    // Listen for trade completion events to update holdings reactively (WebSocket Mimic)
    _orchestratorSubscription = orchestrator.events.listen((event) {
      if (event is TradeCompletedEvent) {
        // We could just reload, but to mimic real-time sync, we can emit a temporary state or trigger Load
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
    if (state is PortfolioLoaded || state is PortfolioEmpty) {
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

    // Use current prices from state if not provided
    final prices = livePrices ?? _getCurrentPricesFromWatchlist();

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

      // Calculate percent using basis points (integer math)
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

  Map<String, double> _getCurrentPricesFromWatchlist() {
    return {
      for (var stock in watchlistBloc.state.stocks) stock.symbol: stock.price,
    };
  }

  @override
  Future<void> close() {
    _watchlistSubscription?.cancel();
    _orchestratorSubscription?.cancel();
    return super.close();
  }
}
