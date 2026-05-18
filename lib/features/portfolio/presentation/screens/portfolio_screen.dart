import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_text.dart';
import '../bloc/portfolio_bloc.dart';
import '../bloc/portfolio_event.dart';
import '../bloc/portfolio_state.dart';
import '../widgets/holding_card.dart';
import '../widgets/portfolio_summary.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
                strokeWidth: 2,
              ),
            );
          }

          if (state is PortfolioEmpty) {
            return _buildEmptyState();
          }

          if (state is PortfolioLoaded) {
            return RefreshIndicator(
              color: const Color(0xFF3B82F6),
              backgroundColor: const Color(0xFF1A1A1A),
              onRefresh: () async =>
                  context.read<PortfolioBloc>().add(LoadPortfolio()),
              child: CustomScrollView(
                slivers: [
                  // ── Premium SliverAppBar ──
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 0,
                    toolbarHeight: 60,
                    title: const Row(
                      children: [
                        AppText(
                          'Portfolio',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    actions: [
                      _buildSortSelector(context),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // ── Portfolio Summary Card ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: PortfolioSummary(
                        investedPaisa: state.totalInvestedPaisa,
                        currentValuePaisa: state.totalCurrentValuePaisa,
                        pnlPaisa: state.totalPnLPaisa,
                        pnlPercent: state.totalPnLPercent,
                      ),
                    ),
                  ),

                  // ── Holdings Header ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const AppText(
                            'HOLDINGS',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white38,
                            letterSpacing: 1.4,
                          ),
                          const Spacer(),
                          AppText(
                            '${state.holdings.length} positions',
                            fontSize: 11,
                            color: Colors.white24,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Holdings List ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            HoldingCard(display: state.holdings[index]),
                        childCount: state.holdings.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SafeArea(top: false, child: SizedBox.shrink()),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSortSelector(BuildContext context) {
    final portfolioBloc = context.read<PortfolioBloc>();
    final currentSort = portfolioBloc.currentSortType;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSortChip(context, 'P&L', PortfolioSortType.pnl, currentSort),
        const SizedBox(width: 4),
        _buildSortChip(
          context,
          'Value',
          PortfolioSortType.currentValue,
          currentSort,
        ),
        const SizedBox(width: 4),
        _buildSortChip(context, 'A–Z', PortfolioSortType.symbol, currentSort),
      ],
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    String label,
    PortfolioSortType type,
    PortfolioSortType current,
  ) {
    final isSelected = type == current;
    return GestureDetector(
      onTap: () =>
          context.read<PortfolioBloc>().add(ChangePortfolioSortType(type)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: AppText(
          label,
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white38,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: const Icon(
                Icons.pie_chart_outline_rounded,
                size: 36,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 20),
            const AppText(
              'No Holdings Yet',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            const AppText(
              'Start trading from the Markets tab\nto build your portfolio here.',
              fontSize: 13,
              color: Colors.white38,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
