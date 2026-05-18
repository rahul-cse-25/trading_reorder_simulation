import 'package:uuid/uuid.dart';
import '../../domain/entities/holding.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repository/trade_repository.dart';
import '../../../../core/events/trading_orchestrator.dart';
import '../../../../core/services/simulation_service.dart';

/// Result types for trade execution following the 10/10 plan (Sealed class).
sealed class ExecuteTradeResult {}

class ExecuteTradeSuccess extends ExecuteTradeResult {
  final Trade trade;
  ExecuteTradeSuccess(this.trade);
}

class ExecuteTradeFailure extends ExecuteTradeResult {
  final String message;
  ExecuteTradeFailure(this.message);
}

/// [ExecuteTradeUseCase] encapsulates the core business logic for processing a trade.
/// It performs validations (balance, quantity) and updates multiple data points atomically.
class ExecuteTradeUseCase {
  final TradeRepository repository;
  final TradingOrchestrator orchestrator;
  final SimulationService simulationService;
  final _uuid = const Uuid();

  ExecuteTradeUseCase(this.repository, this.orchestrator, this.simulationService);

  Future<ExecuteTradeResult> call({
    required String symbol,
    required String stockName,
    required int quantity,
    required TradeType type,
    required int pricePaisa,
  }) async {
    // 1. Validation: Quantity must be positive (Edge cases T1, T2, T8)
    if (quantity <= 0) {
      return ExecuteTradeFailure("Quantity must be at least 1");
    }

    // 2. Fetch current state
    final balancePaisa = await repository.getWalletBalance();
    final holdings = await repository.getHoldings();
    final totalCostPaisa = quantity * pricePaisa;

    // 3. Trade Specific Validations
    if (type == TradeType.buy) {
      // Check wallet balance (Edge case T4)
      if (totalCostPaisa > balancePaisa) {
        return ExecuteTradeFailure("Insufficient balance. You need more funds.");
      }
    } else {
      // Check if user owns enough quantity to sell (Edge case T6, T7)
      final existingHoldingIndex = holdings.indexWhere((h) => h.symbol == symbol);
      if (existingHoldingIndex == -1 || holdings[existingHoldingIndex].quantity < quantity) {
        return ExecuteTradeFailure("You do not own enough shares of $symbol to sell.");
      }
    }

    // 4. Create the Trade record
    final trade = Trade(
      id: _uuid.v4(),
      symbol: symbol,
      stockName: stockName,
      type: type,
      quantity: quantity,
      pricePaisa: pricePaisa,
      totalCostPaisa: totalCostPaisa,
      timestamp: DateTime.now(),
    );

    // 5. Update system state
    try {
      final newBalance = type == TradeType.buy 
          ? balancePaisa - totalCostPaisa 
          : balancePaisa + totalCostPaisa;

      // Update Holdings (Computed in-memory first)
      final existingIndex = holdings.indexWhere((h) => h.symbol == symbol);
      final List<Holding> updatedHoldings = List.from(holdings);

      if (type == TradeType.buy) {
        if (existingIndex != -1) {
          updatedHoldings[existingIndex] = updatedHoldings[existingIndex].updateWithBuy(quantity, pricePaisa);
        } else {
          updatedHoldings.add(Holding(
            symbol: symbol,
            stockName: stockName,
            quantity: quantity,
            totalCostPaisa: totalCostPaisa,
          ));
        }
      } else {
        final holding = updatedHoldings[existingIndex];
        if (holding.quantity == quantity) {
          // Sold everything (Edge case T9)
          updatedHoldings.removeAt(existingIndex);
        } else {
          updatedHoldings[existingIndex] = holding.updateWithSell(quantity);
        }
      }
      
      // 6. Execute atomic batch write transaction
      await repository.executeTradeTransaction(
        newBalancePaisa: newBalance,
        updatedHoldings: updatedHoldings,
        newTrade: trade,
      );

      // --- Reactive Updates (WebSocket Mimic) ---
      // 1. Notify Orchestrator (Updates Wallet, Portfolio, History globally)
      orchestrator.notifyTradeExecuted(trade, updatedHoldings, newBalance);

      // 2. Apply Market Impact (Update Chart/Price)
      simulationService.applyMarketImpact(symbol, quantity, type);

      return ExecuteTradeSuccess(trade);
    } catch (e) {
      return ExecuteTradeFailure("Transaction failed: ${e.toString()}");
    }
  }
}
