import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/simulation_service.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../trading/presentation/bloc/wallet_cubit.dart';
import '../bloc/watchlist_bloc.dart';
import '../bloc/watchlist_manager_cubit.dart';
import '../bloc/watchlist_manager_state.dart';
import '../bloc/watchlist_state.dart';
import '../widgets/market_index_bar.dart';
import '../widgets/stock_card.dart';
import 'reorder_screen.dart';
import 'stock_detail_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: BlocBuilder<WatchlistBloc, WatchlistState>(
        buildWhen: (previous, current) {
          // Only rebuild the scaffold structure if loading state changes
          // or the master stock list count changes.
          // Price updates are handled by individual StockCard BlocSelectors.
          return previous.isLoading != current.isLoading ||
              previous.stocks.length != current.stocks.length;
        },
        builder: (context, watchlistState) {
          if (watchlistState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFF121212),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppText(
                          'MarketPulse',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        StreamBuilder<List<MarketUpdate>>(
                          stream: sl<SimulationService>().stream,
                          builder: (context, snapshot) {
                            return AppText(
                              sl<SimulationService>().formattedMarketTime,
                              fontSize: 12,
                              color: Colors.white38,
                              fontWeight: FontWeight.w600,
                            );
                          },
                        ),
                      ],
                    ),
                    BlocBuilder<WalletCubit, int>(
                      builder: (context, balance) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    Colors.blueAccent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 14,
                                  color: Colors.blueAccent),
                              const SizedBox(width: 6),
                              AppText(
                                MoneyUtils.format(balance),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    tooltip: 'Manage Watchlists',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ReorderWatchlistScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Market Indices Section (Isolates its own rebuilds)
              const SliverToBoxAdapter(child: MarketIndexBar()),

              const SliverToBoxAdapter(child: SizedBox(height: 4)),

              // Watchlist name header
              SliverToBoxAdapter(
                child: BlocBuilder<WatchlistManagerCubit,
                    WatchlistManagerState>(
                  buildWhen: (prev, curr) =>
                      prev.selectedWatchlistId !=
                          curr.selectedWatchlistId ||
                      prev.selectedWatchlist?.name !=
                          curr.selectedWatchlist?.name,
                  builder: (context, state) {
                    final name =
                        state.selectedWatchlist?.name ?? 'Watchlist';
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: AppText(
                        name.toUpperCase(),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white24,
                        letterSpacing: 1.2,
                      ),
                    );
                  },
                ),
              ),

              // Stock list filtered by selected watchlist
              BlocBuilder<WatchlistManagerCubit, WatchlistManagerState>(
                buildWhen: (prev, curr) {
                  // Only rebuild when selected watchlist's symbols change
                  return !listEquals(
                    prev.selectedSymbols,
                    curr.selectedSymbols,
                  );
                },
                builder: (context, managerState) {
                  final symbols = managerState.selectedSymbols;

                  if (symbols.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: AppText(
                          'No stocks in watchlist',
                          color: Colors.white54,
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final symbol = symbols[index];

                          return StockCard(
                            key: ValueKey(symbol),
                            symbol: symbol,
                            verticalPadding: 12,
                            onTap: () {
                              final stock = context
                                  .read<WatchlistBloc>()
                                  .state
                                  .stocks
                                  .firstWhere(
                                    (s) => s.symbol == symbol,
                                  );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StockDetailScreen(stock: stock),
                                ),
                              );
                            },
                          );
                        },
                        childCount: symbols.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
