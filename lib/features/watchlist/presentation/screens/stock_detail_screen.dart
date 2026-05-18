import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/simulation_service.dart';
import '../../../../core/formatters/integer_input_formatter.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../../../shared/widgets/price_text.dart';
import '../../../../shared/widgets/slide_to_confirm.dart';
import '../../domain/entities/stock.dart';
import '../bloc/watchlist_bloc.dart';
import '../bloc/watchlist_state.dart';
import '../widgets/stock_chart_widget.dart';
import '../../../trading/domain/entities/trade.dart';
import '../../../trading/presentation/bloc/trade_bloc.dart';
import '../../../trading/presentation/bloc/trade_event.dart';
import '../../../trading/presentation/bloc/trade_state.dart';
import '../../../trading/presentation/bloc/wallet_cubit.dart';
import '../../../portfolio/presentation/bloc/portfolio_bloc.dart';
import '../../../portfolio/presentation/bloc/portfolio_state.dart';

class StockDetailScreen extends StatefulWidget {
  final Stock stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final TextEditingController _quantityController = TextEditingController();
  TradeType _tradeType = TradeType.buy;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _onTradeExecuted() {
    _quantityController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TradeBloc, TradeState>(
      listener: (context, state) {
        if (state is TradeSuccess) {
          _onTradeExecuted();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: AppText('Order Executed Successfully!', color: Colors.white)),
          );
        } else if (state is TradeFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: AppText(state.message, color: Colors.white), backgroundColor: Colors.redAccent),
          );
        }
      },
      child: BlocSelector<WatchlistBloc, WatchlistState, Stock>(
        selector: (state) => state.stocks.firstWhere(
          (s) => s.symbol == widget.stock.symbol,
          orElse: () => widget.stock,
        ),
        builder: (context, liveStock) {
          return Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: CustomScrollView(
              slivers: [
                _buildAppBar(liveStock),
                _buildPriceHeader(liveStock),
                _buildChart(liveStock),
                _buildHoldingInfo(liveStock),
                _buildTerminalInfo(),
                const SliverToBoxAdapter(child: SizedBox(height: 350)), // Space for Terminal
              ],
            ),
            bottomSheet: _buildTradingTerminal(liveStock),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(Stock stock) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFF121212),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(stock.symbol, fontWeight: FontWeight.bold, fontSize: 18),
          AppText(stock.name, color: Colors.white54, fontSize: 12),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 12.0, bottom: 12.0),
          child: StreamBuilder<List<MarketUpdate>>(
            stream: sl<SimulationService>().stream,
            builder: (context, snapshot) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: AppText(
                  sl<SimulationService>().formattedMarketTime,
                  fontSize: 11,
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceHeader(Stock stock) {
    final isPositive = stock.change >= 0;
    final color = isPositive ? Colors.greenAccent : Colors.redAccent;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(price: stock.price, fontSize: 36, fontWeight: FontWeight.bold),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppText(
                    '${isPositive ? '+' : ''}${stock.percentChange.toStringAsFixed(2)}%',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Stock stock) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 300,
        child: StockChartWidget(stock: stock),
      ),
    );
  }

  Widget _buildHoldingInfo(Stock stock) {
    return SliverToBoxAdapter(
      child: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoaded) {
            final holding = state.holdings.where((h) => h.holding.symbol == stock.symbol).firstOrNull;
            if (holding == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText('YOUR POSITION', fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      AppText('${holding.holding.quantity} Shares @ ${MoneyUtils.format(holding.holding.avgBuyPricePaisa)}', fontSize: 14, fontWeight: FontWeight.w600),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const AppText('UNREALIZED P&L', fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      AppText(
                        '${holding.pnlPaisa >= 0 ? "+" : ""}${MoneyUtils.format(holding.pnlPaisa)}',
                        color: holding.pnlPaisa >= 0 ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ],
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

  Widget _buildTerminalInfo() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText('MARKET DEPTH & INSIGHTS', fontSize: 12, color: Colors.white38, fontWeight: FontWeight.bold),
            const SizedBox(height: 12),
            AppText(
              "Experience real-time market impact. Your trades directly influence the chart spikes and price drift, mimicking a live exchange environment with surgical precision.",
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradingTerminal(Stock stock) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Trade Type Selector
            Row(
              children: [
                _buildTypeTab('BUY', TradeType.buy, Colors.greenAccent),
                _buildTypeTab('SELL', TradeType.sell, Colors.redAccent),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Quantity & Balance
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText('QUANTITY', fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [IntegerInputFormatter()],
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(hintText: '0', border: InputBorder.none),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<WalletCubit, int>(
                  builder: (context, balance) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const AppText('WALLET BALANCE', fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold),
                        const SizedBox(height: 4),
                        AppText(MoneyUtils.format(balance), fontSize: 16, fontWeight: FontWeight.bold),
                      ],
                    );
                  },
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),

            // 3. Dynamic Summary & Slide to Confirm
            _buildActionSection(stock),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, TradeType type, Color activeColor) {
    final isSelected = _tradeType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tradeType = type),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? activeColor : Colors.white10),
          ),
          child: AppText(label, color: isSelected ? activeColor : Colors.white38, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionSection(Stock stock) {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final totalCostPaisa = (stock.price * 100).toInt() * qty;
    final balance = context.read<WalletCubit>().state;
    final isBuy = _tradeType == TradeType.buy;
    
    // Check if enough funds (Buy)
    final hasEnoughFunds = !isBuy || balance >= totalCostPaisa;

    // Check if enough holdings (Sell)
    final portfolioState = context.read<PortfolioBloc>().state;
    int qtyHeld = 0;
    if (portfolioState is PortfolioLoaded) {
      final holding = portfolioState.holdings
          .where((h) => h.holding.symbol == stock.symbol)
          .firstOrNull;
      if (holding != null) {
        qtyHeld = holding.holding.quantity;
      }
    }
    final hasEnoughHoldings = isBuy || qtyHeld >= qty;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(isBuy ? 'Estimated Total' : 'Estimated Value', color: Colors.white54),
            AppText(MoneyUtils.format(totalCostPaisa), fontWeight: FontWeight.bold, fontSize: 18),
          ],
        ),
        const SizedBox(height: 20),
        if (isBuy && !hasEnoughFunds)
          _buildAddFundsButton(totalCostPaisa - balance)
        else if (!isBuy && !hasEnoughHoldings)
          _buildSellWarningButton(qtyHeld)
        else
          SlideToConfirm(
            label: 'SLIDE TO ${isBuy ? "BUY" : "SELL"}',
            color: isBuy ? Colors.greenAccent : Colors.redAccent,
            isEnabled: qty > 0,
            onConfirm: () {
              context.read<TradeBloc>().add(ExecuteTrade(
                symbol: stock.symbol,
                stockName: stock.name,
                quantity: qty,
                type: _tradeType,
                livePricePaisa: (stock.price * 100).toInt(),
              ));
            },
          ),
      ],
    );
  }

  Widget _buildSellWarningButton(int qtyHeld) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppText('Insufficient Holdings', fontWeight: FontWeight.bold, color: Colors.redAccent),
          const SizedBox(height: 2),
          AppText(
            qtyHeld > 0 
              ? 'You only own $qtyHeld shares of this stock'
              : 'You do not own any shares of this stock',
            fontSize: 12,
            color: Colors.white38,
          ),
        ],
      ),
    );
  }

  Widget _buildAddFundsButton(int requiredPaisa) {
    return ElevatedButton(
      onPressed: () => context.read<WalletCubit>().addFunds(10000000), // Add 1Lakh
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppText('Insufficient Funds', fontWeight: FontWeight.bold),
          AppText('Tap to add ${MoneyUtils.format(10000000)}', fontSize: 12),
        ],
      ),
    );
  }
}
