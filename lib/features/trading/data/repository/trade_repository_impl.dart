import 'dart:convert';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../domain/entities/holding.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repository/trade_repository.dart';
import '../models/holding_model.dart';
import '../models/trade_model.dart';

/// [TradeRepositoryImpl] provides concrete persistence for trading data.
/// It acts as a bridge between the domain layer and the local storage.
class TradeRepositoryImpl implements TradeRepository {
  final LocalStorageService storage;

  TradeRepositoryImpl(this.storage);

  @override
  Future<int> getWalletBalance() async {
    // Default starting balance: ₹10,00,000 (100,000,000 paisa)
    final balance = await storage.getInt(StorageKeys.walletBalance);
    return balance ?? 100000000;
  }

  @override
  Future<void> updateWalletBalance(int balancePaisa) async {
    await storage.saveInt(StorageKeys.walletBalance, balancePaisa);
  }

  @override
  Future<List<Trade>> getTradeHistory() async {
    final jsonString = await storage.getString(StorageKeys.tradeHistory);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => TradeModel.fromJson(item).toEntity())
          .toList();
    } catch (e) {
      // In case of corruption, return empty list (Edge case S2)
      return [];
    }
  }

  @override
  Future<void> saveTrade(Trade trade) async {
    final history = await getTradeHistory();
    // Insert at top (newest first)
    final newHistory = [trade, ...history];
    
    // Memory safeguard: Cap history at 500 entries (Edge case S4)
    final cappedHistory = newHistory.take(500).toList();
    
    final jsonString = jsonEncode(
      cappedHistory.map((t) => TradeModel.fromEntity(t).toJson()).toList(),
    );
    await storage.saveString(StorageKeys.tradeHistory, jsonString);
  }

  @override
  Future<List<Holding>> getHoldings() async {
    final jsonString = await storage.getString(StorageKeys.holdings);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => HoldingModel.fromJson(item).toEntity())
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveHoldings(List<Holding> holdings) async {
    final jsonString = jsonEncode(
      holdings.map((h) => HoldingModel.fromEntity(h).toJson()).toList(),
    );
    await storage.saveString(StorageKeys.holdings, jsonString);
  }
}
