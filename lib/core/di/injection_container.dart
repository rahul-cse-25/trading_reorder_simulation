import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../events/trading_orchestrator.dart';
import '../services/simulation_service.dart';
import '../storage/local_storage_service.dart';
import '../storage/shared_prefs_storage_service.dart';
import '../../features/watchlist/data/datasource/mock_watchlist_data.dart';
import '../../features/watchlist/data/repository/watchlist_repository_impl.dart';
import '../../features/watchlist/domain/repository/watchlist_repository.dart';
import '../../features/watchlist/presentation/bloc/watchlist_bloc.dart';
import '../../features/trading/domain/repository/trade_repository.dart';
import '../../features/trading/data/repository/trade_repository_impl.dart';
import '../../features/trading/domain/usecases/execute_trade_usecase.dart';
import '../../features/trading/presentation/bloc/trade_bloc.dart';
import '../../features/trading/presentation/bloc/wallet_cubit.dart';
import '../../features/portfolio/presentation/bloc/portfolio_bloc.dart';

final sl = GetIt.instance;

/// [initDI] initializes all dependencies using GetIt.
/// Following Clean Architecture, we separate:
/// 1. External (SharedPreferences, UUID)
/// 2. Services (Simulation, Storage)
/// 3. Repositories (Watchlist, Trade, Portfolio)
/// 4. UseCases (ExecuteTrade, etc.)
/// 5. BLoCs (State management)
Future<void> initDI() async {
  // --- External ---
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // --- Services ---
  sl.registerLazySingleton<LocalStorageService>(
    () => SharedPrefsStorageService(sl()),
  );
  sl.registerLazySingleton(() => SimulationService());
  sl.registerLazySingleton(() => TradingOrchestrator());
  sl.registerLazySingleton(() => MockWatchlistData());

  // --- Repositories ---
  sl.registerLazySingleton<WatchlistRepository>(
    () => WatchlistRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<TradeRepository>(
    () => TradeRepositoryImpl(sl()),
  );

  // --- UseCases ---
  sl.registerLazySingleton(() => ExecuteTradeUseCase(sl(), sl(), sl()));

  // --- BLoCs ---
  sl.registerLazySingleton(() => WatchlistBloc(sl(), sl()));
  sl.registerLazySingleton(() => TradeBloc(executeTrade: sl(), repository: sl()));
  sl.registerLazySingleton(() => WalletCubit(repository: sl(), orchestrator: sl()));
  sl.registerLazySingleton(() => PortfolioBloc(
        repository: sl(),
        orchestrator: sl(),
        simulationService: sl(),
      ));

  // Note: Trade and Portfolio dependencies will be added as we implement those features.
}
