import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/custom_watchlist.dart';
import '../../domain/repository/watchlist_repository.dart';
import 'watchlist_manager_state.dart';

/// [WatchlistManagerCubit] manages the lifecycle of custom watchlists.
/// It handles CRUD operations and persists changes to local storage.
///
/// This Cubit NEVER touches live prices — it only manages organizational metadata
/// (names, symbol lists, ordering). This separation ensures zero coupling with
/// the real-time price pipeline.
class WatchlistManagerCubit extends Cubit<WatchlistManagerState> {
  final WatchlistRepository repository;
  static const _uuid = Uuid();

  WatchlistManagerCubit({required this.repository})
      : super(const WatchlistManagerState(
          watchlists: [],
          selectedWatchlistId: '',
          isLoading: true,
        ));

  /// Load watchlists from storage. On first launch, creates a default watchlist.
  Future<void> loadWatchlists() async {
    emit(state.copyWith(isLoading: true));

    var watchlists = await repository.getWatchlists();

    if (watchlists.isEmpty) {
      // First launch: create a default watchlist with all available stocks
      final allSymbols = repository.getAllAvailableSymbols();
      final defaultWatchlist = CustomWatchlist(
        id: _uuid.v4(),
        name: 'My Watchlist',
        symbols: allSymbols,
      );
      watchlists = [defaultWatchlist];
      await repository.saveWatchlists(watchlists);
    }

    emit(WatchlistManagerState(
      watchlists: watchlists,
      selectedWatchlistId: watchlists.first.id,
      isLoading: false,
    ));
  }

  /// Create a new empty watchlist with the given name.
  Future<void> createWatchlist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final newWatchlist = CustomWatchlist(
      id: _uuid.v4(),
      name: trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed,
      symbols: const [],
    );

    final updated = [...state.watchlists, newWatchlist];
    await _persistAndEmit(updated, selectedId: newWatchlist.id);
  }

  /// Rename an existing watchlist.
  Future<void> renameWatchlist(String watchlistId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updated = state.watchlists.map((w) {
      if (w.id == watchlistId) {
        return w.copyWith(
          name: trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed,
        );
      }
      return w;
    }).toList();

    await _persistAndEmit(updated);
  }

  /// Delete a watchlist. Cannot delete the last remaining watchlist.
  Future<void> deleteWatchlist(String watchlistId) async {
    if (state.watchlists.length <= 1) return; // Guard: keep at least one

    final updated = state.watchlists.where((w) => w.id != watchlistId).toList();

    // If the deleted watchlist was selected, auto-select the first remaining one
    final newSelectedId = state.selectedWatchlistId == watchlistId
        ? updated.first.id
        : state.selectedWatchlistId;

    await _persistAndEmit(updated, selectedId: newSelectedId);
  }

  /// Switch to a different watchlist.
  void selectWatchlist(String watchlistId) {
    if (state.selectedWatchlistId == watchlistId) return;
    emit(state.copyWith(selectedWatchlistId: watchlistId));
  }

  /// Add a stock symbol to a watchlist. No-op if already present.
  Future<void> addStock(String watchlistId, String symbol) async {
    final updated = state.watchlists.map((w) {
      if (w.id == watchlistId && !w.symbols.contains(symbol)) {
        return w.copyWith(symbols: [...w.symbols, symbol]);
      }
      return w;
    }).toList();

    await _persistAndEmit(updated);
  }

  /// Remove a stock symbol from a watchlist.
  Future<void> removeStock(String watchlistId, String symbol) async {
    final updated = state.watchlists.map((w) {
      if (w.id == watchlistId) {
        return w.copyWith(
          symbols: w.symbols.where((s) => s != symbol).toList(),
        );
      }
      return w;
    }).toList();

    await _persistAndEmit(updated);
  }

  /// Reorder stocks within a watchlist.
  Future<void> reorderStocks(
    String watchlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final watchlist = state.watchlists.firstWhere((w) => w.id == watchlistId);
    final symbols = List<String>.from(watchlist.symbols);

    var adjustedNew = newIndex;
    if (oldIndex < adjustedNew) {
      adjustedNew -= 1;
    }
    final item = symbols.removeAt(oldIndex);
    symbols.insert(adjustedNew, item);

    final updated = state.watchlists.map((w) {
      if (w.id == watchlistId) {
        return w.copyWith(symbols: symbols);
      }
      return w;
    }).toList();

    await _persistAndEmit(updated);
  }

  /// Persist changes and emit new state.
  Future<void> _persistAndEmit(
    List<CustomWatchlist> watchlists, {
    String? selectedId,
  }) async {
    emit(state.copyWith(
      watchlists: watchlists,
      selectedWatchlistId: selectedId,
    ));
    // Fire-and-forget persistence (non-blocking)
    repository.saveWatchlists(watchlists);
  }
}
