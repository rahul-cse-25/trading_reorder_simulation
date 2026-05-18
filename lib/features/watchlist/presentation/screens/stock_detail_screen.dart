import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/formatters/integer_input_formatter.dart';
import '../../../../core/services/floating_notification/manager.dart';
import '../../../../core/services/simulation_service.dart';
import '../../../../core/services/snackbar/manager.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/animated_widgets/animated_value_change.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../../../shared/widgets/price_text.dart';
import '../../../../shared/widgets/slide_to_confirm.dart';
import '../../../portfolio/presentation/bloc/portfolio_bloc.dart';
import '../../../portfolio/presentation/bloc/portfolio_state.dart';
import '../../../trading/domain/entities/trade.dart';
import '../../../trading/presentation/bloc/trade_bloc.dart';
import '../../../trading/presentation/bloc/trade_event.dart';
import '../../../trading/presentation/bloc/trade_state.dart';
import '../../../trading/presentation/bloc/wallet_cubit.dart';
import '../../domain/entities/stock.dart';
import '../bloc/watchlist_bloc.dart';
import '../bloc/watchlist_state.dart';
import '../widgets/stock_chart_widget.dart';

class StockDetailScreen extends StatefulWidget {
  final Stock stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _quantityController = TextEditingController();
  TradeType _tradeType = TradeType.buy;
  late TabController _tabController;

  static const List<int> _quickChips = [1, 5, 10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _quantityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  int get _qty => int.tryParse(_quantityController.text) ?? 0;

  /// Returns the number of shares held for the current stock, 0 if none.
  int _maxSellQty() {
    final ps = context.read<PortfolioBloc>().state;
    if (ps is PortfolioLoaded) {
      final h = ps.holdings
          .where((h) => h.holding.symbol == widget.stock.symbol)
          .firstOrNull;
      if (h != null) return h.holding.quantity;
    }
    return 0;
  }

  /// True when user is in sell mode but owns zero shares — input should be locked.
  bool get _isSellDisabled =>
      _tradeType == TradeType.sell && _maxSellQty() == 0;

  void _switchTradeType(TradeType type) {
    if (_tradeType == type) return;
    setState(() {
      _tradeType = type;
      // Clear quantity on mode switch so stale values don't persist
      _quantityController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TradeBloc, TradeState>(
      listener: (context, state) {
        if (state is TradeSuccess) {
          AppFloating.show(
            child: _AppFloatingTradeNotification(trade: state.trade),
            options: const AppFloatingOptions(
              enableHapticOnAppear: true,
              showDuration: Duration(seconds: 4),
            ),
          );
          AppSnackbar.showSuccess(
            'Order Executed Successfully!',
            showLabel: true,
          );
        } else if (state is TradeFailure) {
          AppSnackbar.showError(state.message);
        }
      },
      child: BlocSelector<WatchlistBloc, WatchlistState, Stock>(
        selector: (state) => state.stocks.firstWhere(
          (s) => s.symbol == widget.stock.symbol,
          orElse: () => widget.stock,
        ),
        builder: (context, liveStock) {
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                _buildAppBar(liveStock),
                _buildPriceHeader(liveStock),
                _buildChart(liveStock),
                _buildPositionCard(liveStock),
                _buildTradingPanel(liveStock),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(Stock stock) {
    return SliverAppBar(
      pinned: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Colors.white70,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(stock.symbol, fontWeight: FontWeight.bold, fontSize: 17),
          AppText(stock.name, color: Colors.white38, fontSize: 11),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
          child: StreamBuilder<List<MarketUpdate>>(
            stream: sl<SimulationService>().stream,
            builder: (_, snap) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: AppText(
                sl<SimulationService>().formattedMarketTime,
                fontSize: 10,
                color: Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  Widget _buildPriceHeader(Stock stock) {
    final isPositive = stock.change >= 0;
    final color = isPositive
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: PriceText(
                price: stock.price,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color: color,
                    size: 18,
                  ),
                  AppText(
                    '${isPositive ? '+' : ''}${stock.percentChange.toStringAsFixed(2)}%',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Stock stock) {
    return SliverToBoxAdapter(
      child: SizedBox(height: 280, child: StockChartWidget(stock: stock)),
    );
  }

  Widget _buildPositionCard(Stock stock) {
    return SliverToBoxAdapter(
      child: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, state) {
          if (state is! PortfolioLoaded) return const SizedBox.shrink();
          final holding = state.holdings
              .where((h) => h.holding.symbol == stock.symbol)
              .firstOrNull;
          if (holding == null) return const SizedBox.shrink();
          final isProfit = holding.pnlPaisa >= 0;
          final pnlColor = isProfit
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444);
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppText(
                    '${holding.holding.quantity} shares @ ${MoneyUtils.format(holding.holding.avgBuyPricePaisa)}',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppText(
                  '${isProfit ? "+" : ""}${holding.pnlPercent.toStringAsFixed(2)}%',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: pnlColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTradingPanel(Stock stock) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Buy / Sell Tab Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _TradeTab(
                  label: 'BUY',
                  type: TradeType.buy,
                  selected: _tradeType,
                  color: const Color(0xFF22C55E),
                  onTap: () => _switchTradeType(TradeType.buy),
                ),
                const SizedBox(width: 6),
                _TradeTab(
                  label: 'SELL',
                  type: TradeType.sell,
                  selected: _tradeType,
                  color: const Color(0xFFEF4444),
                  onTap: () => _switchTradeType(TradeType.sell),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Wallet row ──
                _buildWalletRow(),
                const SizedBox(height: 14),

                // ── Quantity input ──
                _buildQuantityInput(),
                const SizedBox(height: 10),

                // ── Quick chips ──
                _buildQuickChips(stock),
                const SizedBox(height: 14),

                // ── Order summary ──
                _buildOrderSummary(stock),
                const SizedBox(height: 16),

                // ── CTA ──
                _buildCTA(stock),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletRow() {
    return BlocBuilder<WalletCubit, int>(
      builder: (context, balance) => Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 14,
            color: Colors.white38,
          ),
          const SizedBox(width: 6),
          const AppText('Balance', fontSize: 12, color: Colors.white38),
          const Spacer(),
          AnimatedValue(
            value: balance.toDouble(),
            increaseColor: const Color(0xFF22C55E),
            decreaseColor: const Color(0xFFEF4444),
            idleColor: Colors.white,
            builder: (_, val, color) => AppText(
              MoneyUtils.format(val.toInt()),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityInput() {
    final isBuy = _tradeType == TradeType.buy;
    final isDisabled = _isSellDisabled;
    final accentColor = isBuy
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    final borderColor = isDisabled
        ? Colors.white.withValues(alpha: 0.04)
        : (_qty > 0
              ? accentColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDisabled
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: IgnorePointer(
              // Fully block taps when disabled
              ignoring: isDisabled,
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [IntegerInputFormatter()],
                enabled: !isDisabled,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDisabled
                      ? Colors.white12
                      : (_qty > 0 ? Colors.white : Colors.white54),
                ),
                decoration: InputDecoration(
                  hintText: isDisabled ? '—' : '0',
                  hintStyle: TextStyle(
                    fontSize: 26,
                    color: isDisabled ? Colors.white12 : Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                'SHARES',
                fontSize: 9,
                color: isDisabled ? Colors.white12 : Colors.white24,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
              const SizedBox(height: 2),
              if (isDisabled)
                // Lock icon when sell is disabled (no holdings)
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: Colors.white12,
                )
              else if (_qty > 0)
                GestureDetector(
                  onTap: () => setState(() => _quantityController.clear()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const AppText(
                      'Clear',
                      fontSize: 10,
                      color: Colors.white38,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips(Stock stock) {
    final isBuy = _tradeType == TradeType.buy;
    final accentColor = isBuy
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    final balance = context.read<WalletCubit>().state;

    // For sell: max based on holdings
    int maxSell = 0;
    final ps = context.read<PortfolioBloc>().state;
    if (ps is PortfolioLoaded) {
      final h = ps.holdings
          .where((h) => h.holding.symbol == stock.symbol)
          .firstOrNull;
      if (h != null) maxSell = h.holding.quantity;
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ..._quickChips.map((qty) {
          final isSelected = _qty == qty;
          final costPaisa = (stock.price * 100).toInt() * qty;
          final canAfford = !isBuy || balance >= costPaisa;
          final canSell = isBuy || qty <= maxSell;
          final available = canAfford && canSell;

          return GestureDetector(
            onTap: available
                ? () => setState(() => _quantityController.text = '$qty')
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: available ? 0.05 : 0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: available ? 0.08 : 0.04),
                ),
              ),
              child: AppText(
                '$qty',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? accentColor
                    : (available ? Colors.white60 : Colors.white24),
              ),
            ),
          );
        }),
        // MAX chip
        if (!isBuy && maxSell > 0)
          GestureDetector(
            onTap: () => setState(() => _quantityController.text = '$maxSell'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _qty == maxSell
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _qty == maxSell
                      ? accentColor.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: AppText(
                'MAX',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _qty == maxSell ? accentColor : Colors.white60,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderSummary(Stock stock) {
    final totalCostPaisa = (stock.price * 100).toInt() * _qty;
    final isBuy = _tradeType == TradeType.buy;
    if (_qty == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                isBuy ? 'Est. Cost' : 'Est. Return',
                fontSize: 11,
                color: Colors.white38,
              ),
              const SizedBox(height: 2),
              AnimatedValue(
                value: totalCostPaisa.toDouble(),
                increaseColor: const Color(0xFF22C55E),
                decreaseColor: const Color(0xFFEF4444),
                idleColor: Colors.white,
                builder: (_, val, color) => AppText(
                  MoneyUtils.format(val.toInt()),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.white,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText('Price / share', fontSize: 11, color: Colors.white38),
              const SizedBox(height: 2),
              AppText(
                '₹${stock.price.toStringAsFixed(2)}',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCTA(Stock stock) {
    final qty = _qty;
    final totalCostPaisa = (stock.price * 100).toInt() * qty;
    final balance = context.read<WalletCubit>().state;
    final isBuy = _tradeType == TradeType.buy;
    final hasEnoughFunds = !isBuy || balance >= totalCostPaisa;

    final portfolioState = context.read<PortfolioBloc>().state;
    int qtyHeld = 0;
    if (portfolioState is PortfolioLoaded) {
      final holding = portfolioState.holdings
          .where((h) => h.holding.symbol == stock.symbol)
          .firstOrNull;
      if (holding != null) qtyHeld = holding.holding.quantity;
    }
    final hasEnoughHoldings = isBuy || qtyHeld >= qty;

    if (isBuy && !hasEnoughFunds) {
      return _buildAddFundsButton(totalCostPaisa - balance);
    }
    if (!isBuy && !hasEnoughHoldings) {
      return _buildSellWarning(qtyHeld);
    }

    return SlideToConfirm(
      label: 'SLIDE TO ${isBuy ? "BUY" : "SELL"}',
      color: isBuy ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
      isEnabled: qty > 0,
      onConfirm: () {
        context.read<TradeBloc>().add(
          ExecuteTrade(
            symbol: stock.symbol,
            stockName: stock.name,
            quantity: qty,
            type: _tradeType,
            livePricePaisa: (stock.price * 100).toInt(),
          ),
        );
        _quantityController.clear();
      },
    );
  }

  Widget _buildSellWarning(int qtyHeld) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Insufficient Holdings',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                ),
                AppText(
                  qtyHeld > 0
                      ? 'You own $qtyHeld shares'
                      : 'You don\'t own any shares',
                  fontSize: 11,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFundsButton(int requiredPaisa) {
    return GestureDetector(
      onTap: () => context.read<WalletCubit>().addFunds(10000000),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_card_rounded,
              color: Colors.orangeAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Insufficient Funds',
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                    fontSize: 13,
                  ),
                  const AppText(
                    'Tap to add ₹1,00,000 to wallet',
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.orangeAccent,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trade Tab ──
class _TradeTab extends StatelessWidget {
  final String label;
  final TradeType type;
  final TradeType selected;
  final Color color;
  final VoidCallback onTap;

  const _TradeTab({
    required this.label,
    required this.type,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = type == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: AppText(
            label,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isSelected ? color : Colors.white24,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ── Floating trade notification ──
class _AppFloatingTradeNotification extends StatelessWidget {
  final Trade trade;

  const _AppFloatingTradeNotification({required this.trade});

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.type == TradeType.buy;
    final accentColor = isBuy
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBuy ? Icons.arrow_outward_rounded : Icons.call_received_rounded,
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppText(
                      isBuy ? 'BUY EXECUTED' : 'SELL EXECUTED',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 1.0,
                    ),
                    const Spacer(),
                    AppText(
                      MoneyUtils.format(trade.totalCostPaisa),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    AppText(
                      '${trade.quantity} shares of ${trade.symbol}',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    const Spacer(),
                    AppText(
                      '@ ${MoneyUtils.format(trade.pricePaisa)}',
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
