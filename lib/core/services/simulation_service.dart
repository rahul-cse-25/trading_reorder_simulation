import 'dart:async';
import 'dart:math';

import '../../features/trading/domain/entities/trade.dart';
import '../../features/watchlist/domain/entities/market_index.dart';
import '../../features/watchlist/domain/entities/stock.dart';

class MarketUpdate {
  final String symbol;
  final double newPrice;
  final double change;
  final double percentChange;
  final int marketTimeSeconds;
  final int day;

  MarketUpdate({
    required this.symbol,
    required this.newPrice,
    required this.change,
    required this.percentChange,
    required this.marketTimeSeconds,
    required this.day,
  });
}

class SimulationService {
  final _controller = StreamController<List<MarketUpdate>>.broadcast();
  final _timeController = StreamController<String>.broadcast();
  Timer? _timer;

  Duration _tickDuration = const Duration(milliseconds: 1000);
  List<Stock>? _lastStocks;
  List<MarketIndex>? _lastIndices;

  Duration get tickDuration => _tickDuration;
  Stream<String> get timeStream => _timeController.stream;

  void setTickDuration(Duration d) {
    if (_tickDuration == d) return;
    _tickDuration = d;
    if (_lastStocks != null && _lastIndices != null) {
      start(stocks: _lastStocks!, indices: _lastIndices!);
    }
  }

  // Market clock configuration:
  // Starts at 9:15 AM (33300s) and closes at 3:30 PM (55800s).
  static const int marketOpenSeconds = 33300;
  static const int marketCloseSeconds = 55800;
  static const int marketSecondsPerTick =
      60; // 1 real second = 1 market minute (perfect fast forward)

  int _currentElapsedSeconds = marketOpenSeconds;
  int _currentDay = 1;

  final Map<String, double> _initialPrices = {};
  final Map<String, double> _shocks = {};

  Stream<List<MarketUpdate>> get stream => _controller.stream;

  int get currentElapsedSeconds => _currentElapsedSeconds;

  int get currentDay => _currentDay;

  String get formattedMarketTime {
    final int hours = _currentElapsedSeconds ~/ 3600;
    final int minutes = (_currentElapsedSeconds % 3600) ~/ 60;
    final int seconds = _currentElapsedSeconds % 60;

    final String period = hours >= 12 ? 'PM' : 'AM';
    final int displayHours = hours > 12
        ? hours - 12
        : (hours == 0 ? 12 : hours);

    final String minStr = minutes.toString().padLeft(2, '0');
    final String secStr = seconds.toString().padLeft(2, '0');

    return 'Day $_currentDay, $displayHours:$minStr:$secStr $period';
  }

  void applyMarketImpact(String symbol, int quantity, TradeType type) {
    // Logarithmic trade volume scale for realistic price shocks (up to 2.5% max)
    final double impactStrength = (log(quantity + 1) / log(10000)) * 0.025;
    final double direction = type == TradeType.buy ? 1.0 : -1.0;

    _shocks[symbol] = (_shocks[symbol] ?? 0.0) + (direction * impactStrength);
  }

  void start({
    required List<Stock> stocks,
    required List<MarketIndex> indices,
  }) {
    _lastStocks = stocks;
    _lastIndices = indices;

    // Populate base initial anchor prices if empty to avoid price explosions
    if (_initialPrices.isEmpty) {
      for (final s in stocks) {
        _initialPrices[s.symbol] = s.price;
      }
      for (final idx in indices) {
        _initialPrices[idx.symbol] = idx.price;
      }
    }

    _timer?.cancel();
    _timer = Timer.periodic(_tickDuration, (_) {
      // Step simulated clock
      _currentElapsedSeconds += marketSecondsPerTick;
      if (_currentElapsedSeconds > marketCloseSeconds) {
        _currentElapsedSeconds = marketOpenSeconds;
        _currentDay++;
      }

      final List<MarketUpdate> updates = [];

      for (final stock in stocks) {
        updates.add(_generateStockUpdate(stock));
      }
      for (final index in indices) {
        updates.add(_generateIndexUpdate(index));
      }

      if (updates.isNotEmpty) {
        _controller.add(updates);
      }
      _timeController.add(formattedMarketTime);
    });
  }

  MarketUpdate _generateStockUpdate(Stock stock) {
    final double initialPrice = _initialPrices[stock.symbol] ?? stock.price;
    final double basePrice = calculateBasePrice(
      stock.symbol,
      initialPrice,
      _currentElapsedSeconds,
    );

    // Retrieve and decay shocks (mean-reversion)
    final double shock = _shocks[stock.symbol] ?? 0.0;
    _shocks[stock.symbol] = shock * 0.85; // 15% dissipation per minute

    final double finalPrice = basePrice * (1.0 + shock);
    final double change = finalPrice - initialPrice;
    final double percentChange = (change / initialPrice) * 100.0;

    return MarketUpdate(
      symbol: stock.symbol,
      newPrice: double.parse(finalPrice.toStringAsFixed(2)),
      change: double.parse(change.toStringAsFixed(2)),
      percentChange: double.parse(percentChange.toStringAsFixed(2)),
      marketTimeSeconds: _currentElapsedSeconds,
      day: _currentDay,
    );
  }

  MarketUpdate _generateIndexUpdate(MarketIndex index) {
    final double initialPrice = _initialPrices[index.symbol] ?? index.price;
    final double finalPrice = calculateIndexPrice(
      index.symbol,
      initialPrice,
      _currentElapsedSeconds,
    );

    final double change = finalPrice - initialPrice;
    final double percentChange = (change / initialPrice) * 100.0;

    return MarketUpdate(
      symbol: index.symbol,
      newPrice: double.parse(finalPrice.toStringAsFixed(2)),
      change: double.parse(change.toStringAsFixed(2)),
      percentChange: double.parse(percentChange.toStringAsFixed(2)),
      marketTimeSeconds: _currentElapsedSeconds,
      day: _currentDay,
    );
  }

  /// High-Fidelity Deterministic Intraday Price Generator
  double calculateBasePrice(
    String symbol,
    double initialPrice,
    int elapsedSeconds,
  ) {
    final double dayFraction =
        (elapsedSeconds - marketOpenSeconds) /
        (marketCloseSeconds - marketOpenSeconds);

    final int seed = symbol.hashCode.abs();
    final double stockFactor = (seed % 100) / 100.0;

    // Volatility multiplier: ranges from 0.8 (highly stable) to 2.5 (highly volatile)
    final double volatilityMultiplier = 0.8 + (stockFactor * 1.7);

    // Volatility waves scaled by the stock's volatility multiplier
    final double wave1 =
        0.018 *
        sin(dayFraction * pi * 2 + (stockFactor * pi)) *
        volatilityMultiplier;
    final double wave2 =
        0.008 *
        cos(dayFraction * pi * 4 - (stockFactor * pi / 2)) *
        volatilityMultiplier;

    // Seeded PRNG for deterministic tick-by-tick micro noise
    final random = Random(seed ^ elapsedSeconds ^ _currentDay);
    final double noise =
        (random.nextDouble() - 0.48) * 0.004 * volatilityMultiplier;

    // Linear daily drift
    final double drift =
        (stockFactor - 0.46) * 0.018 * dayFraction * volatilityMultiplier;

    final double multiplier = 1.0 + wave1 + wave2 + noise + drift;
    return initialPrice * multiplier;
  }

  /// High-Fidelity Deterministic Index Price Generator
  double calculateIndexPrice(
    String symbol,
    double initialPrice,
    int elapsedSeconds,
  ) {
    final double dayFraction =
        (elapsedSeconds - marketOpenSeconds) /
        (marketCloseSeconds - marketOpenSeconds);

    final int seed = symbol.hashCode.abs();
    final double indexFactor = (seed % 100) / 100.0;

    final double wave = 0.008 * sin(dayFraction * pi * 2 + (indexFactor * pi));

    final random = Random(seed ^ elapsedSeconds ^ _currentDay);
    final double noise = (random.nextDouble() - 0.5) * 0.0008; // highly stable

    final double multiplier = 1.0 + wave + noise;
    return initialPrice * multiplier;
  }

  void stop() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
