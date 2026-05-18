import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'features/portfolio/presentation/bloc/portfolio_event.dart';
import 'features/shell/app_shell.dart';
import 'features/trading/presentation/bloc/trade_bloc.dart';
import 'features/trading/presentation/bloc/trade_event.dart';
import 'features/trading/presentation/bloc/wallet_cubit.dart';
import 'features/watchlist/presentation/bloc/watchlist_bloc.dart';
import 'features/watchlist/presentation/bloc/watchlist_event.dart';
import 'features/watchlist/presentation/bloc/watchlist_manager_cubit.dart';

import 'core/storage/storage_keys.dart';

class TradingApp extends StatelessWidget {
  const TradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<WatchlistBloc>()..add(LoadStocks()),
        ),
        BlocProvider(
          create: (context) =>
              sl<WatchlistManagerCubit>()..loadWatchlists(),
        ),
        BlocProvider(create: (context) => sl<TradeBloc>()..add(LoadHistory())),
        BlocProvider(create: (context) => sl<WalletCubit>()),
        BlocProvider(
          create: (context) => sl<PortfolioBloc>()..add(LoadPortfolio()),
        ),
      ],
      child: MaterialApp(
        title: 'MarketPulse',
        debugShowCheckedModeBanner: false,
        navigatorKey: AppKeys.instance.navigatorKey,
        scaffoldMessengerKey: AppKeys.instance.scaffoldMessengerKey,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blueAccent,
          scaffoldBackgroundColor: const Color(0xFF121212),
          fontFamily: 'RobotoCondensed',
        ),
        home: const AppShell(),
      ),
    );
  }
}
