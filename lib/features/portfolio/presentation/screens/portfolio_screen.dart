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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const AppText('Portfolio', fontWeight: FontWeight.bold, fontSize: 24),
      ),
      body: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
          }

          if (state is PortfolioEmpty) {
            return _buildEmptyState();
          }

          if (state is PortfolioLoaded) {
            return RefreshIndicator(
              onRefresh: () async => context.read<PortfolioBloc>().add(LoadPortfolio()),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: PortfolioSummary(
                        investedPaisa: state.totalInvestedPaisa,
                        currentValuePaisa: state.totalCurrentValuePaisa,
                        pnlPaisa: state.totalPnLPaisa,
                        pnlPercent: state.totalPnLPercent,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: AppText('YOUR HOLDINGS', fontSize: 12, color: Colors.white38, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => HoldingCard(display: state.holdings[index]),
                        childCount: state.holdings.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          const AppText('No Holdings Yet', fontSize: 20, fontWeight: FontWeight.bold),
          const SizedBox(height: 8),
          const AppText('Start trading to build your portfolio', color: Colors.white38),
        ],
      ),
    );
  }
}
