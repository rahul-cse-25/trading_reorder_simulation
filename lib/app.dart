import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/simulation_service.dart';
import 'features/watchlist/data/datasource/mock_watchlist_data.dart';
import 'features/watchlist/data/repository/watchlist_repository_impl.dart';
import 'features/watchlist/presentation/bloc/watchlist_bloc.dart';
import 'features/watchlist/presentation/bloc/watchlist_event.dart';
import 'features/watchlist/presentation/screens/watchlist_screen.dart';

class TradingApp extends StatelessWidget {
  const TradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => MockWatchlistData()),
        RepositoryProvider(
          create: (context) =>
              WatchlistRepositoryImpl(context.read<MockWatchlistData>()),
        ),
        RepositoryProvider(create: (context) => SimulationService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => WatchlistBloc(
              context.read<WatchlistRepositoryImpl>(),
              context.read<SimulationService>(),
            )..add(LoadStocks()),
          ),
        ],
        child: MaterialApp(
          title: 'MarketPulse',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFF121212),
            fontFamily: 'RobotoCondensed',
          ),
          home: const WatchlistScreen(),
        ),
      ),
    );
  }
}
