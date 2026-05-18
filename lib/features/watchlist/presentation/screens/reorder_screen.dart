import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/formatters/capitalize_name_formatter.dart';
import '../../../../core/utils/navigator_ex.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<WatchlistManagerCubit, WatchlistManagerState>(
        builder: (context, managerState) {
          if (managerState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          final selectedWatchlist = managerState.selectedWatchlist;
          if (selectedWatchlist == null) {
            return const Center(
              child: AppText('No watchlists found', color: Colors.white54),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                leading: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const AppText(
                  'Watchlists',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              // ── Watchlist Manager Panel ──
              SliverToBoxAdapter(
                child: _WatchlistManagerPanel(
                  watchlists: managerState.watchlists,
                  selectedId: managerState.selectedWatchlistId,
                  onSelect: (id) =>
                      context.read<WatchlistManagerCubit>().selectWatchlist(id),
                  onRename: (id) => _showRenameDialog(context, id),
                  onDelete: (id) => _confirmDeleteWatchlist(context, id),
                  onCreateNew: () => _showCreateWatchlistDialog(context),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 4)),

              if (selectedWatchlist.symbols.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyCTA(),
                )
              else
                _StockReorderableList(
                  symbols: selectedWatchlist.symbols,
                  watchlistId: selectedWatchlist.id,
                ),
              const SliverToBoxAdapter(
                child: SafeArea(top: false, child: SizedBox(height: 90)),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showStockPicker(context),
      backgroundColor: const Color(0xFF3B82F6),
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      label: const AppText(
        'Add Stock',
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _buildEmptyCTA() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.playlist_add_rounded,
                size: 32,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 20),
            const AppText(
              'Watchlist is empty',
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            const AppText(
              'Tap "Add Stock" below to start\ntracking your favourite stocks.',
              color: Colors.white38,
              fontSize: 13,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateWatchlistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _WatchlistNameDialog(
        title: 'New Watchlist',
        controller: controller,
        confirmLabel: 'Create',
        onConfirm: (name) {
          context.read<WatchlistManagerCubit>().createWatchlist(name);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String watchlistId) {
    final cubit = context.read<WatchlistManagerCubit>();
    final current = cubit.state.watchlists.firstWhere(
      (w) => w.id == watchlistId,
    );
    final controller = TextEditingController(text: current.name)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: current.name.length,
      );
    showDialog(
      context: context,
      builder: (ctx) => _WatchlistNameDialog(
        title: 'Rename Watchlist',
        controller: controller,
        confirmLabel: 'Save',
        onConfirm: (name) {
          cubit.renameWatchlist(watchlistId, name);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _confirmDeleteWatchlist(BuildContext context, String watchlistId) {
    final cubit = context.read<WatchlistManagerCubit>();
    if (cubit.state.watchlists.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the last watchlist'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const AppText(
          'Delete Watchlist?',
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
        content: const AppText(
          'All stocks in this watchlist will be removed. This cannot be undone.',
          color: Colors.white54,
          fontSize: 13,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const AppText('Cancel', color: Colors.white38),
          ),
          TextButton(
            onPressed: () {
              cubit.deleteWatchlist(watchlistId);
              Navigator.pop(ctx);
            },
            child: const AppText(
              'Delete',
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
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
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) =>
            BlocBuilder<WatchlistManagerCubit, WatchlistManagerState>(
              builder: (context, state) {
                final currentSymbols = state.selectedWatchlist?.symbols ?? [];
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
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
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollCtrl,
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
                );
              },
            ),
      ),
    );
  }
}

// ── Watchlist Manager Panel ──
class _WatchlistManagerPanel extends StatefulWidget {
  final List<CustomWatchlist> watchlists;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onDelete;
  final VoidCallback onCreateNew;

  const _WatchlistManagerPanel({
    required this.watchlists,
    required this.selectedId,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
    required this.onCreateNew,
  });

  @override
  State<_WatchlistManagerPanel> createState() => _WatchlistManagerPanelState();
}

class _WatchlistManagerPanelState extends State<_WatchlistManagerPanel> {
  bool _isExpanded = false;

  void _toggleExpand() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    final watchlists = widget.watchlists;
    final selectedId = widget.selectedId;
    final selected = watchlists.firstWhere(
      (w) => w.id == selectedId,
      orElse: () => watchlists.first,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Selected watchlist header ──
          GestureDetector(
            onTap: _toggleExpand,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: Color(0xFF3B82F6),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          selected.name,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          '${selected.symbols.length} stocks tracking',
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                  // Rename & Delete always visible
                  if (!_isExpanded) ...[
                    _ActionIcon(
                      icon: Icons.edit_rounded,
                      color: Colors.white54,
                      onTap: () => widget.onRename(selectedId),
                    ),
                    const SizedBox(width: 4),
                    _ActionIcon(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                      onTap: () => widget.onDelete(selectedId),
                    ),
                    const SizedBox(width: 4),
                  ],
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white38,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded list of all watchlists ──
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
                    children: [
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      ...watchlists.map(
                        (w) => _WatchlistRow(
                          watchlist: w,
                          isSelected: w.id == selectedId,
                          onSelect: () {
                            widget.onSelect(w.id);
                            setState(() => _isExpanded = false);
                          },
                          onRename: () => widget.onRename(w.id),
                          onDelete: () => widget.onDelete(w.id),
                        ),
                      ),
                      // ── Create New Watchlist row ──
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.onCreateNew();
                          setState(() => _isExpanded = false);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 20,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const AppText(
                                'Create new watchlist',
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  final CustomWatchlist watchlist;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _WatchlistRow({
    required this.watchlist,
    required this.isSelected,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: isSelected
            ? const Color(0xFF3B82F6).withValues(alpha: 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: isSelected ? const Color(0xFF3B82F6) : Colors.white24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    watchlist.name,
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  AppText(
                    '${watchlist.symbols.length} stocks',
                    fontSize: 11,
                    color: Colors.white30,
                  ),
                ],
              ),
            ),
            _ActionIcon(
              icon: Icons.edit_rounded,
              color: Colors.white38,
              onTap: onRename,
            ),
            const SizedBox(width: 2),
            _ActionIcon(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFEF4444).withValues(alpha: 0.6),
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ── Shared dialog for create / rename ──
class _WatchlistNameDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String confirmLabel;
  final ValueChanged<String> onConfirm;

  const _WatchlistNameDialog({
    required this.title,
    required this.controller,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: AppText(title, fontWeight: FontWeight.bold, fontSize: 17),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 20,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        inputFormatters: [CapitalizeFirstLetterFormatter()],
        decoration: InputDecoration(
          hintText: 'Watchlist name',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
          counterStyle: TextStyle(color: Colors.white24, fontSize: 10),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) onConfirm(v.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('Cancel', color: Colors.white38),
        ),
        TextButton(
          onPressed: () {
            final n = controller.text.trim();
            if (n.isNotEmpty) onConfirm(n);
          },
          child: AppText(
            confirmLabel,
            color: const Color(0xFF3B82F6),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Reorderable stock list ──
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
      onReorder: (oldIndex, newIndex) => context
          .read<WatchlistManagerCubit>()
          .reorderStocks(watchlistId, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final symbol = symbols[index];
        return Dismissible(
          key: ValueKey('dismiss_$symbol'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 22,
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
                  onTap: () => context.push(
                    StockDetailScreen(stock: stock),
                    animation: AnimationType.slide,
                    direction: NavSlideDirection.rtl,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Stock picker row ──
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
        final color = isPositive
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444);
        return ListTile(
          onTap: onTap,
          dense: true,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isInWatchlist
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isInWatchlist ? Icons.check_rounded : Icons.add_rounded,
              size: 18,
              color: isInWatchlist ? const Color(0xFF3B82F6) : Colors.white38,
            ),
          ),
          title: AppText(
            symbol,
            fontWeight: FontWeight.w600,
            fontSize: 14,
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
                fontSize: 13,
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
