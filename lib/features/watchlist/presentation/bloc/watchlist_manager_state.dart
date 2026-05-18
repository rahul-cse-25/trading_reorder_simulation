import 'package:equatable/equatable.dart';

import '../../domain/entities/custom_watchlist.dart';

class WatchlistManagerState extends Equatable {
  final List<CustomWatchlist> watchlists;
  final String selectedWatchlistId;
  final bool isLoading;

  const WatchlistManagerState({
    required this.watchlists,
    required this.selectedWatchlistId,
    this.isLoading = false,
  });

  /// Returns the currently selected watchlist, or null if none found.
  CustomWatchlist? get selectedWatchlist {
    try {
      return watchlists.firstWhere((w) => w.id == selectedWatchlistId);
    } catch (_) {
      return watchlists.isNotEmpty ? watchlists.first : null;
    }
  }

  /// Returns the symbols of the currently selected watchlist.
  List<String> get selectedSymbols => selectedWatchlist?.symbols ?? [];

  WatchlistManagerState copyWith({
    List<CustomWatchlist>? watchlists,
    String? selectedWatchlistId,
    bool? isLoading,
  }) {
    return WatchlistManagerState(
      watchlists: watchlists ?? this.watchlists,
      selectedWatchlistId: selectedWatchlistId ?? this.selectedWatchlistId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [watchlists, selectedWatchlistId, isLoading];
}
