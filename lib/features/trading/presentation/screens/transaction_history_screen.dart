import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repository/trade_repository.dart';
import '../bloc/trade_bloc.dart';
import '../bloc/trade_state.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<Trade>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = sl<TradeRepository>().getTradeHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<TradeBloc, TradeState>(
        listener: (context, state) {
          if (state is HistoryLoaded) {
            _refreshHistory();
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const AppText(
                'Orders',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            FutureBuilder<List<Trade>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    ),
                  );
                }

                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  );
                }

                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCard(history),
                            const SizedBox(height: 24),
                            const AppText(
                              'RECENT TRANSACTIONS',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white24,
                              letterSpacing: 1.2,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildTransactionCard(history[index]);
                          },
                          childCount: history.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SafeArea(
                        top: false,
                        child: SizedBox(height: 100),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<Trade> history) {
    final buyCount = history.where((t) => t.type == TradeType.buy).length;
    final sellCount = history.where((t) => t.type == TradeType.sell).length;

    int totalVolume = 0;
    int totalValuePaisa = 0;
    for (var trade in history) {
      totalVolume += trade.quantity;
      totalValuePaisa += trade.totalCostPaisa;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withValues(alpha: 0.15),
            Colors.purpleAccent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Total Executed',
                    fontSize: 12,
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    '${history.length} Orders',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const AppText(
                    'Trade Value',
                    fontSize: 12,
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    MoneyUtils.format(totalValuePaisa),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniSummaryStat('BUYS', '$buyCount', Colors.greenAccent),
              _buildMiniSummaryStat('SELLS', '$sellCount', Colors.redAccent),
              _buildMiniSummaryStat(
                'VOLUME',
                '$totalVolume Shs',
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSummaryStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          fontSize: 10,
          color: Colors.white24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        const SizedBox(height: 4),
        AppText(value, fontSize: 14, fontWeight: FontWeight.bold, color: color),
      ],
    );
  }

  Widget _buildTransactionCard(Trade trade) {
    final isBuy = trade.type == TradeType.buy;
    final typeColor = isBuy ? Colors.greenAccent : Colors.redAccent;
    final timestampString = _formatDateTime(trade.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Direction Icon Card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBuy ? Icons.arrow_outward_rounded : Icons.call_received_rounded,
              color: typeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Stock Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppText(
                      trade.symbol,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: AppText(
                        isBuy ? 'BUY' : 'SELL',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AppText(timestampString, fontSize: 11, color: Colors.white38),
              ],
            ),
          ),
          // Price Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                MoneyUtils.format(trade.totalCostPaisa),
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              AppText(
                '${trade.quantity} Shares @ ${MoneyUtils.format(trade.pricePaisa)}',
                fontSize: 11,
                color: Colors.white38,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          const AppText(
            'No Orders Yet',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          const AppText(
            'Your trade transactions will appear here.',
            color: Colors.white38,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;

    final hourInt = dt.hour;
    final period = hourInt >= 12 ? 'PM' : 'AM';
    final hour = (hourInt % 12 == 0 ? 12 : hourInt % 12).toString().padLeft(
      2,
      '0',
    );
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day $month $year • $hour:$minute $period';
  }
}
