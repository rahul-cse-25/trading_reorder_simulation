import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_text.dart';
import '../../domain/entities/custom_watchlist.dart';
import '../bloc/watchlist_bloc.dart';
import '../bloc/watchlist_manager_cubit.dart';
import '../bloc/watchlist_manager_state.dart';
import '../bloc/watchlist_state.dart';
import '../widgets/stock_card.dart';
import 'stock_detail_screen.dart';

class ReorderWatchlistScreen extends StatefulWidget {
  const ReorderWatchlistScreen({super.key});

  @override
  State<ReorderWatchlistScreen> createState() => _ReorderWatchlistScreenState();
}

class _ReorderWatchlistScreenState extends State<ReorderWatchlistScreen> {
  bool _isWatchlistSelectorExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: BlocBuilder<WatchlistManagerCubit, WatchlistManagerState>(
        builder: (context, managerState) {
          if (managerState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final selectedWatchlist = managerState.selectedWatchlist;
          if (selectedWatchlist == null) {
            return const Center(
              child: AppText('No watchlists found', color: Colors.white54),
            );
          }

          return CustomScrollView(
            slivers: [
              // ── Zone 1: AppBar ──
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFF121212),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                title: const AppText(
                  'Manage Watchlists',
                  fontWeight: FontWeight.bold,
                ),
                leadingWidth: 32,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blueAccent),
                    tooltip: 'Create Watchlist',
                    onPressed: () => _showCreateWatchlistDialog(context),
                  ),
                  const SizedBox(width: 4),
                ],
              ),

              // ── Zone 2: Watchlist Selector ──
              SliverToBoxAdapter(
                child: _WatchlistSelector(
                  watchlists: managerState.watchlists,
                  selectedId: managerState.selectedWatchlistId,
                  isExpanded: _isWatchlistSelectorExpanded,
                  onToggleExpand: () {
                    setState(() {
                      _isWatchlistSelectorExpanded =
                          !_isWatchlistSelectorExpanded;
                    });
                  },
                  onSelect: (id) {
                    context.read<WatchlistManagerCubit>().selectWatchlist(id);
                    setState(() => _isWatchlistSelectorExpanded = false);
                  },
                  onRename: (id) => _showRenameDialog(context, id),
                  onDelete: (id) => _confirmDeleteWatchlist(context, id),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ── Zone 3: Stock List ──
              if (selectedWatchlist.symbols.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.playlist_add,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 16),
                        const AppText(
                          'No stocks in this watchlist',
                          color: Colors.white38,
                        ),
                        const SizedBox(height: 8),
                        const AppText(
                          'Tap + below to add stocks',
                          color: Colors.white24,
                          fontSize: 12,
                        ),
                      ],
                    ),
                  ),
                )
              else
                _StockReorderableList(
                  symbols: selectedWatchlist.symbols,
                  watchlistId: selectedWatchlist.id,
                ),

              const SliverToBoxAdapter(
                child: SafeArea(top: false, child: SizedBox(height: 80)),
              ),
            ],
          );
        },
      ),
      // ── Zone 4: Add Stock FAB ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStockPicker(context),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const AppText(
          'Add Stock',
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Dialogs ──

  void _showCreateWatchlistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const AppText('New Watchlist', fontWeight: FontWeight.bold),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Watchlist name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              context.read<WatchlistManagerCubit>().createWatchlist(
                value.trim(),
              );
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const AppText('Cancel', color: Colors.white38, fontSize: 14),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<WatchlistManagerCubit>().createWatchlist(name);
                Navigator.pop(ctx);
              }
            },
            child: const AppText(
              'Create',
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String watchlistId) {
    final cubit = context.read<WatchlistManagerCubit>();
    final current = cubit.state.watchlists.firstWhere(
      (w) => w.id == watchlistId,
    );
    final controller = TextEditingController(text: current.name);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: current.name.length,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const AppText('Rename Watchlist', fontWeight: FontWeight.bold),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'New name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              cubit.renameWatchlist(watchlistId, value.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const AppText('Cancel', color: Colors.white38, fontSize: 14),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                cubit.renameWatchlist(watchlistId, name);
                Navigator.pop(ctx);
              }
            },
            child: const AppText(
              'Save',
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWatchlist(BuildContext context, String watchlistId) {
    final cubit = context.read<WatchlistManagerCubit>();
    if (cubit.state.watchlists.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            'Cannot delete the last watchlist',
            color: Colors.white,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const AppText('Delete Watchlist', fontWeight: FontWeight.bold),
        content: const AppText(
          'This action cannot be undone. All stocks in this watchlist will be removed.',
          color: Colors.white54,
          fontSize: 14,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const AppText('Cancel', color: Colors.white38, fontSize: 14),
          ),
          TextButton(
            onPressed: () {
              cubit.deleteWatchlist(watchlistId);
              Navigator.pop(ctx);
            },
            child: const AppText(
              'Delete',
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showStockPicker(BuildContext context) {
    final cubit = context.read<WatchlistManagerCubit>();
    final selected = cubit.state.selectedWatchlist;
    if (selected == null) return;

    final allSymbols = cubit.repository.getAllAvailableSymbols();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BlocBuilder<WatchlistManagerCubit, WatchlistManagerState>(
          builder: (context, state) {
            final currentSymbols = state.selectedWatchlist?.symbols ?? [];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        AppText(
                          'Add Stock',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allSymbols.length,
                      itemBuilder: (context, index) {
                        final symbol = allSymbols[index];
                        final isInWatchlist = currentSymbols.contains(symbol);

                        return _StockPickerRow(
                          symbol: symbol,
                          isInWatchlist: isInWatchlist,
                          onTap: isInWatchlist
                              ? null
                              : () {
                                  cubit.addStock(selected.id, symbol);
                                  HapticFeedback.lightImpact();
                                },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Extracted Widgets — for performance isolation
// ─────────────────────────────────────────────────────────────

/// Expandable/collapsible watchlist selector section.
class _WatchlistSelector extends StatelessWidget {
  final List<CustomWatchlist> watchlists;
  final String selectedId;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onDelete;

  const _WatchlistSelector({
    required this.watchlists,
    required this.selectedId,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final selected = watchlists.firstWhere(
      (w) => w.id == selectedId,
      orElse: () => watchlists.first,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected watchlist header (always visible)
        GestureDetector(
          onTap: onToggleExpand,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.list_alt_rounded,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        selected.name,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      AppText(
                        '${selected.symbols.length} stocks',
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded watchlist chips
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: watchlists.map<Widget>((watchlist) {
                      final isSelected = watchlist.id == selectedId;
                      return GestureDetector(
                        onTap: () => onSelect(watchlist.id),
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          _showContextMenu(context, watchlist);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 14,
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.white24,
                              ),
                              const SizedBox(width: 8),
                              AppText(
                                watchlist.name,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: AppText(
                                  '${watchlist.symbols.length}',
                                  fontSize: 10,
                                  color: Colors.white38,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showContextMenu(BuildContext context, dynamic watchlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppText(
                watchlist.name,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueAccent),
              title: const AppText('Rename', fontSize: 14),
              onTap: () {
                Navigator.pop(ctx);
                onRename(watchlist.id);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const AppText(
                'Delete',
                fontSize: 14,
                color: Colors.redAccent,
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete(watchlist.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Performant reorderable stock list that uses the same StockCard widget.
/// Completely isolated from price tick rebuilds via buildWhen.
class _StockReorderableList extends StatelessWidget {
  final List<String> symbols;
  final String watchlistId;

  const _StockReorderableList({
    required this.symbols,
    required this.watchlistId,
  });

  @override
  Widget build(BuildContext context) {
    return SliverReorderableList(
      itemCount: symbols.length,
      onReorderStart: (_) => HapticFeedback.lightImpact(),
      proxyDecorator: (child, index, animation) {
        return Material(
          color: Colors.transparent,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              border: Border(
                top: BorderSide(
                  color: Colors.white70,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                bottom: BorderSide(
                  color: Colors.white70,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: child,
            ),
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        context.read<WatchlistManagerCubit>().reorderStocks(
          watchlistId,
          oldIndex,
          newIndex,
        );
      },
      itemBuilder: (context, index) {
        final symbol = symbols[index];
        return Dismissible(
          key: ValueKey('dismiss_$symbol'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.redAccent.withValues(alpha: 0.15),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 24,
            ),
          ),
          onDismissed: (_) {
            HapticFeedback.mediumImpact();
            context.read<WatchlistManagerCubit>().removeStock(
              watchlistId,
              symbol,
            );
          },
          child: ReorderableDelayedDragStartListener(
            key: ValueKey(symbol),
            index: index,
            child: BlocSelector<WatchlistBloc, WatchlistState, bool>(
              // Only need to know if stock exists — price rendering is inside StockCard
              selector: (state) => state.stocks.any((s) => s.symbol == symbol),
              builder: (context, exists) {
                if (!exists) return const SizedBox.shrink();

                final stock = context
                    .read<WatchlistBloc>()
                    .state
                    .stocks
                    .firstWhere((s) => s.symbol == symbol);

                return StockCard(
                  symbol: symbol,
                  verticalPadding: 8,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StockDetailScreen(stock: stock),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// A single row in the stock picker bottom sheet.
/// Shows live price via BlocSelector for premium feel.
class _StockPickerRow extends StatelessWidget {
  final String symbol;
  final bool isInWatchlist;
  final VoidCallback? onTap;

  const _StockPickerRow({
    required this.symbol,
    required this.isInWatchlist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      WatchlistBloc,
      WatchlistState,
      ({String name, double price, double change})
    >(
      selector: (state) {
        final stock = state.stocks.firstWhere((s) => s.symbol == symbol);
        return (
          name: stock.name,
          price: stock.price,
          change: stock.percentChange,
        );
      },
      builder: (context, data) {
        final isPositive = data.change >= 0;
        final color = isPositive ? Colors.greenAccent : Colors.redAccent;

        return ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: isInWatchlist
                ? Colors.blueAccent.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            radius: 18,
            child: Icon(
              isInWatchlist ? Icons.check : Icons.add,
              size: 18,
              color: isInWatchlist ? Colors.blueAccent : Colors.white38,
            ),
          ),
          title: AppText(
            symbol,
            fontWeight: FontWeight.w600,
            color: isInWatchlist ? Colors.white38 : Colors.white,
          ),
          subtitle: AppText(
            data.name,
            fontSize: 11,
            color: isInWatchlist ? Colors.white24 : Colors.white38,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                '₹${data.price.toStringAsFixed(2)}',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isInWatchlist ? Colors.white24 : Colors.white,
              ),
              AppText(
                '${isPositive ? '+' : ''}${data.change.toStringAsFixed(2)}%',
                fontSize: 11,
                color: isInWatchlist ? Colors.white24 : color,
              ),
            ],
          ),
        );
      },
    );
  }
}
