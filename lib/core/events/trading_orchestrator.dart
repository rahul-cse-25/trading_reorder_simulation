import 'dart:async';
import '../../features/trading/domain/entities/trade.dart';
import '../../features/trading/domain/entities/holding.dart';

/// [TradeEvent] represents the different types of events the orchestrator can broadcast.
sealed class TradingEvent {}

/// Emitted when a trade is successfully completed.
class TradeCompletedEvent extends TradingEvent {
  final Trade trade;
  final List<Holding> updatedHoldings;
  final int newBalancePaisa;

  TradeCompletedEvent({
    required this.trade,
    required this.updatedHoldings,
    required this.newBalancePaisa,
  });
}

/// Emitted when a market impact should be applied to a stock.
class MarketImpactEvent extends TradingEvent {
  final String symbol;
  final int quantity;
  final TradeType type;

  MarketImpactEvent({
    required this.symbol,
    required this.quantity,
    required this.type,
  });
}

/// [TradingOrchestrator] is a central Event Bus that facilitates 
/// decoupled communication between features (Watchlist, Trading, Portfolio).
/// 
/// Pattern: Observer Pattern / Mediator.
class TradingOrchestrator {
  final _eventController = StreamController<TradingEvent>.broadcast();

  Stream<TradingEvent> get events => _eventController.stream;

  /// Notify all listeners that a trade has occurred.
  void notifyTradeExecuted(Trade trade, List<Holding> updatedHoldings, int newBalancePaisa) {
    _eventController.add(TradeCompletedEvent(
      trade: trade,
      updatedHoldings: updatedHoldings,
      newBalancePaisa: newBalancePaisa,
    ));
    
    // Also trigger market impact event
    _eventController.add(MarketImpactEvent(
      symbol: trade.symbol,
      quantity: trade.quantity,
      type: trade.type,
    ));
  }

  void dispose() {
    _eventController.close();
  }
}
