import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../portfolio/presentation/bloc/portfolio_bloc.dart';
import '../portfolio/presentation/bloc/portfolio_event.dart';
import '../portfolio/presentation/screens/portfolio_screen.dart';
import '../trading/presentation/screens/transaction_history_screen.dart';
import '../watchlist/presentation/screens/watchlist_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static AppShellState? instance;

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const WatchlistScreen(),
    const PortfolioScreen(),
    const TransactionHistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    AppShell.instance = this;
  }

  @override
  void dispose() {
    if (AppShell.instance == this) {
      AppShell.instance = null;
    }
    super.dispose();
  }

  void setIndex(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    HapticFeedback.selectionClick();
    setIndex(index);

    // Refresh portfolio when switching to it
    if (index == 1) {
      context.read<PortfolioBloc>().add(LoadPortfolio());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          margin: const EdgeInsets.all(16),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(32)),
            border: Border.all(
              color: Colors.white10,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              backgroundColor: Colors.transparent,
              onTap: _onTabTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.show_chart_rounded),
                  activeIcon: Icon(
                    Icons.show_chart_rounded,
                    color: Colors.blueAccent,
                  ),
                  label: 'Markets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pie_chart_outline_rounded),
                  activeIcon: Icon(
                    Icons.pie_chart_rounded,
                    color: Colors.blueAccent,
                  ),
                  label: 'Portfolio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.blueAccent,
                  ),
                  label: 'Orders',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
