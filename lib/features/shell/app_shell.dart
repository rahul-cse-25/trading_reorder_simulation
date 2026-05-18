import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../watchlist/presentation/screens/watchlist_screen.dart';
import '../portfolio/presentation/screens/portfolio_screen.dart';
import '../portfolio/presentation/bloc/portfolio_bloc.dart';
import '../portfolio/presentation/bloc/portfolio_event.dart';
import '../trading/presentation/screens/transaction_history_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const WatchlistScreen(),
    const PortfolioScreen(),
    const TransactionHistoryScreen(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });

    // Refresh portfolio when switching to it
    if (index == 1) {
      context.read<PortfolioBloc>().add(LoadPortfolio());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_rounded),
              activeIcon: Icon(Icons.show_chart_rounded, color: Colors.blueAccent),
              label: 'Markets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded),
              activeIcon: Icon(Icons.pie_chart_rounded, color: Colors.blueAccent),
              label: 'Portfolio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded, color: Colors.blueAccent),
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }
}
