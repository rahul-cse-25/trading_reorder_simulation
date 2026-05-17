/// [StorageKeys] centralizes all persistence keys to prevent typo-based bugs
/// and provide a single source of truth for local data.
abstract class StorageKeys {
  /// Integer (paisa): User's current wallet balance
  static const String walletBalance = 'wallet_balance_paisa';

  /// List<String>: Symbols in order for the watchlist
  static const String watchlistOrder = 'watchlist_order';

  /// String (JSON): List of Trade models
  static const String tradeHistory = 'trade_history';

  /// String (JSON): List of Holding models
  static const String holdings = 'holdings';

  /// String: Schema version for migrations
  static const String storageVersion = 'storage_version';
}
