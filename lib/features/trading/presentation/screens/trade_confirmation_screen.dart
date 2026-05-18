import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/money_utils.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../../shell/app_shell.dart';
import '../../domain/entities/trade.dart';

class TradeConfirmationScreen extends StatefulWidget {
  final Trade trade;

  const TradeConfirmationScreen({super.key, required this.trade});

  @override
  State<TradeConfirmationScreen> createState() => _TradeConfirmationScreenState();
}

class _TradeConfirmationScreenState extends State<TradeConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.trade.type == TradeType.buy;
    final primaryColor = isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // 1. Success Indicator Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 56,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 2. Main Title Text
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    AppText(
                      isBuy ? 'Buy Order Placed' : 'Sell Order Placed',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const AppText(
                      'Your order has been filled instantly.',
                      fontSize: 14,
                      color: Colors.white38,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 3. Receipt Details Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                widget.trade.symbol,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 2),
                              AppText(
                                widget.trade.stockName,
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AppText(
                              isBuy ? 'BUY' : 'SELL',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.white10, height: 1),
                      ),

                      // Receipt Items
                      _buildReceiptRow('Order Quantity', '${widget.trade.quantity} Shares'),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Execution Price', AppPriceFormatter.format(widget.trade.pricePaisa / 100)),
                      const SizedBox(height: 12),
                      _buildReceiptRow(
                        'Total Transaction Cost',
                        MoneyUtils.format(widget.trade.totalCostPaisa),
                        valueColor: Colors.white,
                        valueWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 12),
                      _buildReceiptRow(
                        'Execution Time',
                        _formatTimestamp(widget.trade.timestamp),
                      ),
                      const SizedBox(height: 12),
                      _buildReceiptRow(
                        'Reference ID',
                        '#${widget.trade.id.substring(0, 8).toUpperCase()}',
                        valueColor: Colors.white38,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // 4. Interactive Action Buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Redirect AppShell active tab to Portfolio (index 1)
                        AppShell.instance?.setIndex(1);
                        // Pop all the way back to AppShell home
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const AppText(
                        'Go to Portfolio',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        // Redirect AppShell active tab to Watchlist (index 0)
                        AppShell.instance?.setIndex(0);
                        // Pop all the way back to AppShell home
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.white10),
                        ),
                      ),
                      child: const AppText(
                        'Back to Watchlist',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    Color valueColor = Colors.white70,
    FontWeight valueWeight = FontWeight.w600,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          fontSize: 13,
          color: Colors.white38,
        ),
        AppText(
          value,
          fontSize: 13,
          color: valueColor,
          fontWeight: valueWeight,
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime time) {
    final minuteStr = time.minute < 10 ? '0${time.minute}' : '${time.minute}';
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${time.day} ${months[time.month - 1]} ${time.year}, $hour:$minuteStr $amPm';
  }
}
