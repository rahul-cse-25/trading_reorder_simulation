import 'package:flutter_test/flutter_test.dart';
import 'package:trading_simulation/features/trading/domain/entities/holding.dart';
import 'package:trading_simulation/features/trading/domain/entities/trade.dart';
import 'package:trading_simulation/features/trading/domain/repository/trade_repository.dart';
import 'package:trading_simulation/features/trading/domain/usecases/execute_trade_usecase.dart';
import 'package:trading_simulation/core/events/trading_orchestrator.dart';
import 'package:trading_simulation/core/services/simulation_service.dart';

class MockTradeRepository implements TradeRepository {
  int walletBalance = 100000; // ₹1,000.00 starting balance (100000 paisa)
  List<Holding> holdings = [];
  List<Trade> trades = [];

  @override
  Future<int> getWalletBalance() async => walletBalance;

  @override
  Future<void> updateWalletBalance(int balancePaisa) async {
    walletBalance = balancePaisa;
  }

  @override
  Future<List<Holding>> getHoldings() async => holdings;

  @override
  Future<void> saveHoldings(List<Holding> updatedHoldings) async {
    holdings = List.from(updatedHoldings);
  }

  @override
  Future<List<Trade>> getTradeHistory() async => trades;

  @override
  Future<void> saveTrade(Trade trade) async {
    trades.add(trade);
  }

  @override
  Future<void> executeTradeTransaction({
    required int newBalancePaisa,
    required List<Holding> updatedHoldings,
    required Trade newTrade,
  }) async {
    walletBalance = newBalancePaisa;
    holdings = List.from(updatedHoldings);
    trades.add(newTrade);
  }
}

void main() {
  group('ExecuteTradeUseCase Validation & Bounds Unit Tests', () {
    late MockTradeRepository repository;
    late TradingOrchestrator orchestrator;
    late SimulationService simulationService;
    late ExecuteTradeUseCase useCase;

    setUp(() {
      repository = MockTradeRepository();
      orchestrator = TradingOrchestrator();
      simulationService = SimulationService(); // unstarted, safe for unit tests
      useCase = ExecuteTradeUseCase(repository, orchestrator, simulationService);
    });

    tearDown(() {
      orchestrator.dispose();
      simulationService.stop();
    });

    test('Zero or negative quantity trade fails immediately', () async {
      final result = await useCase(
        symbol: 'RELIANCE',
        stockName: 'Reliance Industries',
        quantity: 0,
        type: TradeType.buy,
        pricePaisa: 1000,
      );

      expect(result, isA<ExecuteTradeFailure>());
      expect((result as ExecuteTradeFailure).message, 'Quantity must be at least 1');
    });

    test('Buying with insufficient wallet balance triggers validation failure', () async {
      // Starting balance: ₹1,000.00 (100,000 paisa).
      // Attempting to buy 2 shares at ₹600.00 each (120,000 paisa).
      final result = await useCase(
        symbol: 'TCS',
        stockName: 'Tata Consultancy',
        quantity: 2,
        type: TradeType.buy,
        pricePaisa: 60000,
      );

      expect(result, isA<ExecuteTradeFailure>());
      expect((result as ExecuteTradeFailure).message, 'Insufficient balance. You need more funds.');
    });

    test('Short selling (selling unowned shares) triggers validation failure', () async {
      final result = await useCase(
        symbol: 'INFY',
        stockName: 'Infosys',
        quantity: 5,
        type: TradeType.sell,
        pricePaisa: 150000,
      );

      expect(result, isA<ExecuteTradeFailure>());
      expect((result as ExecuteTradeFailure).message, 'You do not own enough shares of INFY to sell.');
    });

    test('Selling more shares than owned triggers validation failure', () async {
      // User owns 3 shares of INFY
      repository.holdings = [
        const Holding(
          symbol: 'INFY',
          stockName: 'Infosys',
          quantity: 3,
          totalCostPaisa: 450000,
        )
      ];

      final result = await useCase(
        symbol: 'INFY',
        stockName: 'Infosys',
        quantity: 5,
        type: TradeType.sell,
        pricePaisa: 150000,
      );

      expect(result, isA<ExecuteTradeFailure>());
      expect((result as ExecuteTradeFailure).message, 'You do not own enough shares of INFY to sell.');
    });

    test('Valid buy trade updates wallet balance and creates holdings record', () async {
      // Starting balance: ₹1,000.00 (100,000 paisa).
      // Buy 2 shares at ₹100.00 (10,000 paisa) each. Total = 20,000 paisa.
      final result = await useCase(
        symbol: 'RELIANCE',
        stockName: 'Reliance Industries',
        quantity: 2,
        type: TradeType.buy,
        pricePaisa: 10000,
      );

      expect(result, isA<ExecuteTradeSuccess>());
      expect(repository.walletBalance, 80000); // 100,000 - 20,000 = 80,000 paisa
      expect(repository.holdings.length, 1);
      expect(repository.holdings[0].symbol, 'RELIANCE');
      expect(repository.holdings[0].quantity, 2);
      expect(repository.holdings[0].avgBuyPricePaisa, 10000.0);
    });

    test('Valid partial sell reduces holdings quantity and adds wallet balance', () async {
      // User starts with 3 shares of TCS and ₹1,000.00 balance
      repository.holdings = [
        const Holding(
          symbol: 'TCS',
          stockName: 'Tata Consultancy',
          quantity: 3,
          totalCostPaisa: 150000,
        )
      ];

      // Sell 1 share at ₹600.00 (60,000 paisa)
      final result = await useCase(
        symbol: 'TCS',
        stockName: 'Tata Consultancy',
        quantity: 1,
        type: TradeType.sell,
        pricePaisa: 60000,
      );

      expect(result, isA<ExecuteTradeSuccess>());
      expect(repository.walletBalance, 160000); // 100,000 + 60,000 = 160,000 paisa
      expect(repository.holdings.length, 1);
      expect(repository.holdings[0].quantity, 2); // 3 - 1 = 2
    });

    test('Full sale of stock removes it from portfolio holdings completely', () async {
      // User starts with 2 shares of SBIN
      repository.holdings = [
        const Holding(
          symbol: 'SBIN',
          stockName: 'State Bank of India',
          quantity: 2,
          totalCostPaisa: 80000,
        )
      ];

      // Sell all 2 shares
      final result = await useCase(
        symbol: 'SBIN',
        stockName: 'State Bank of India',
        quantity: 2,
        type: TradeType.sell,
        pricePaisa: 42000,
      );

      expect(result, isA<ExecuteTradeSuccess>());
      expect(repository.holdings, isEmpty); // removed completely from list
    });
  });
}
