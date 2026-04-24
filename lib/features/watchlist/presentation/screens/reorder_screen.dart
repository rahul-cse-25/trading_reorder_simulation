import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trading_simulation/features/watchlist/presentation/screens/stock_detail_screen.dart';

import '../../../../shared/widgets/app_text.dart';
import '../bloc/watchlist_bloc.dart';
import '../bloc/watchlist_event.dart';
import '../bloc/watchlist_state.dart';
import '../widgets/stock_card.dart';

class ReorderWatchlistScreen extends StatefulWidget {
  const ReorderWatchlistScreen({super.key});

  @override
  State<ReorderWatchlistScreen> createState() => _ReorderWatchlistScreenState();
}

class _ReorderWatchlistScreenState extends State<ReorderWatchlistScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        controller: _scrollController,
        // physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: const AppText(
              'Reorder Watchlist',
              fontWeight: FontWeight.bold,
            ),
            leadingWidth: 32,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // We use BlocBuilder here to manage the list structure.
          // By placing it only around the SliverReorderableList, we isolate updates.
          BlocBuilder<WatchlistBloc, WatchlistState>(
            buildWhen: (previous, current) {
              // Only rebuild the list structure if stocks order or count changes.
              // This is critical for performance and preventing UI flicker.
              return !listEquals(
                previous.stocks.map((s) => s.symbol).toList(),
                current.stocks.map((s) => s.symbol).toList(),
              );
            },
            builder: (context, state) {
              return SliverReorderableList(
                itemCount: state.stocks.length,
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
                  // Direct BLoC communication.
                  // The BLoC will emit the new state, and this BlocBuilder will
                  // catch it and update the list.
                  context.read<WatchlistBloc>().add(
                    ReorderStocks(oldIndex: oldIndex, newIndex: newIndex),
                  );
                },
                itemBuilder: (context, index) {
                  final stock = state.stocks[index];
                  // Using ReorderableDelayedDragStartListener ensures the whole card
                  // is draggable after a long press, while single taps remain snappy.
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(stock.symbol),
                    index: index,
                    child: StockCard(
                      symbol: stock.symbol,
                      verticalPadding: 8,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StockDetailScreen(stock: stock),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SafeArea(top: false, child: SizedBox.shrink()),
          ),
        ],
      ),
    );
  }
}
