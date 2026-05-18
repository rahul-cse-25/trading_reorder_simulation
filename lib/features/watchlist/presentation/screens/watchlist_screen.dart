import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/simulation_service.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/utils/navigator_ex.dart';
import '../../../../shared/animated_widgets/shake_animator.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../../trading/presentation/bloc/wallet_cubit.dart';
import '../../domain/repository/watchlist_repository.dart';
import '../bloc/watchlist_bloc.dart';
import '../bloc/watchlist_state.dart';
import '../widgets/market_index_bar.dart';
import '../widgets/stock_card.dart';
import 'reorder_screen.dart';
import 'stock_detail_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve all 10 available stock symbols directly
    final symbols = sl<WatchlistRepository>().getAllAvailableSymbols();

    return Scaffold(
      extendBody: true,
      body: BlocBuilder<WatchlistBloc, WatchlistState>(
        buildWhen: (previous, current) {
          // Performance Guard: Only rebuild scaffold structure if loading state changes
          // or the master stock list count changes.
          // Real-time price ticks are isolated inside StockCard's specific BlocSelectors.
          return previous.isLoading != current.isLoading ||
              previous.stocks.length != current.stocks.length;
        },
        builder: (context, watchlistState) {
          if (watchlistState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
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
                        return PremiumShake.card(
                          trigger: balance,
                          idleBorder: BorderSide.none,
                          padding: const EdgeInsets.all(1),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(24),
                          ),
                          enableHaptic: true,
                          premiumHoldDuration: const Duration(
                            milliseconds: 1000,
                          ),
                          glowBlurRadius: 10,
                          glowSpreadRadius: 0,
                          hapticType: PremiumHapticType.light,
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(24),
                              ),
                              color: Color.fromRGBO(0, 0, 0, 0.05),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 14,
                                  // color: activeColor,
                                ),
                                const SizedBox(width: 6),
                                AppText(
                                  MoneyUtils.formatCompact(balance),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  // color: activeColor,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.list_alt_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Manage Watchlists',
                    onPressed: () {
                      context.push(
                        const ReorderWatchlistScreen(),
                        animation: AnimationType.slide,
                        direction: NavSlideDirection.rtl,
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

              // Section Header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: AppText(
                    'MARKET RATES',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white24,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // Direct SliverList of all 10 stocks in real-time
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final symbol = symbols[index];

                    return StockCard(
                      key: ValueKey(symbol),
                      symbol: symbol,
                      verticalPadding: 12,
                      onTap: () {
                        final stock = watchlistState.stocks.firstWhere(
                          (s) => s.symbol == symbol,
                        );
                        context.push(
                          StockDetailScreen(stock: stock),
                          animation: AnimationType.slide,
                          direction: NavSlideDirection.rtl,
                        );
                      },
                    );
                  }, childCount: symbols.length),
                ),
              ),
              const SliverToBoxAdapter(
                child: SafeArea(top: false, child: SizedBox.shrink()),
              ),
            ],
          );
        },
      ),
    );
  }
}
