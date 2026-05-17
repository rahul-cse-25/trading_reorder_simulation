import '../entities/holding.dart';
import '../entities/trade.dart';

/// [TradeRepository] defines the contract for trade-related data operations.
/// It handles wallet balance, trade history, and portfolio holdings.
abstract class TradeRepository {
  /// --- Wallet ---
  Future<int> getWalletBalance();
  Future<void> updateWalletBalance(int balancePaisa);

  /// --- Trade History ---
  Future<List<Trade>> getTradeHistory();
  Future<void> saveTrade(Trade trade);

  /// --- Holdings (Portfolio) ---
  Future<List<Holding>> getHoldings();
  Future<void> saveHoldings(List<Holding> holdings);
}
