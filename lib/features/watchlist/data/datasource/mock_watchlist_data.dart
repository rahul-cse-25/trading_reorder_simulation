import 'dart:math';

import 'package:flutter/material.dart' show Color;
import 'package:imp_trading_chart/imp_trading_chart.dart';

import '../models/market_index_model.dart';
import '../models/stock_model.dart';

class MockWatchlistData {
  List<MarketIndexModel> getInitialIndices() {
    return [
      MarketIndexModel(
        symbol: 'NIFTY 50',
        name: 'NSE Nifty 50',
        price: 22350.85,
        change: 156.40,
        percentChange: 0.70,
        bgColor: const Color(0xFF1A237E),
        // NSE Indigo
        candles: _generateSmartCandles('NIFTY 50', 22350.85, count: 10),
      ),
      MarketIndexModel(
        symbol: 'SENSEX',
        name: 'BSE Sensex',
        price: 73651.35,
        change: 482.15,
        percentChange: 0.66,
        bgColor: const Color(0xFF0D47A1),
        // BSE Blue
        candles: _generateSmartCandles('SENSEX', 73651.35, count: 10),
      ),
      MarketIndexModel(
        symbol: 'NIFTY BANK',
        name: 'Nifty Bank',
        price: 47582.10,
        change: -120.45,
        percentChange: -0.25,
        bgColor: const Color(0xFF4A148C),
        // Banking Purple
        candles: _generateSmartCandles('NIFTY BANK', 47582.10, count: 10),
      ),
    ];
  }

  List<StockModel> getInitialData() {
    return [
      StockModel(
        symbol: 'RELIANCE',
        name: 'Reliance Industries',
        price: 2950.45,
        change: 12.50,
        percentChange: 0.42,
        candles: _generateSmartCandles('RELIANCE', 2950.45, count: 5),
      ),
      StockModel(
        symbol: 'TCS',
        name: 'Tata Consultancy Services',
        price: 3845.00,
        change: -45.20,
        percentChange: -1.16,
        candles: _generateSmartCandles('TCS', 3845.00, count: 5),
      ),
      StockModel(
        symbol: 'HDFCBANK',
        name: 'HDFC Bank Ltd',
        price: 1520.30,
        change: 5.15,
        percentChange: 0.34,
        candles: _generateSmartCandles('HDFCBANK', 1520.30, count: 5),
      ),
      StockModel(
        symbol: 'INFY',
        name: 'Infosys Ltd',
        price: 1475.60,
        change: -8.40,
        percentChange: -0.57,
        candles: _generateSmartCandles('INFY', 1475.60, count: 5),
      ),
      StockModel(
        symbol: 'ICICIBANK',
        name: 'ICICI Bank Ltd',
        price: 1085.25,
        change: 14.80,
        percentChange: 1.38,
        candles: _generateSmartCandles('ICICIBANK', 1085.25, count: 5),
      ),
      StockModel(
        symbol: 'ITC',
        name: 'ITC Limited',
        price: 445.30,
        change: 3.85,
        percentChange: 0.87,
        candles: _generateSmartCandles('ITC', 445.30, count: 5),
      ),
      StockModel(
        symbol: 'SBIN',
        name: 'State Bank of India',
        price: 820.10,
        change: 9.25,
        percentChange: 1.14,
        candles: _generateSmartCandles('SBIN', 820.10, count: 5),
      ),
      StockModel(
        symbol: 'BHARTIARTL',
        name: 'Bharti Airtel',
        price: 1345.60,
        change: 22.30,
        percentChange: 1.68,
        candles: _generateSmartCandles('BHARTIARTL', 1345.60, count: 5),
      ),
      StockModel(
        symbol: 'LT',
        name: 'Larsen & Toubro',
        price: 3620.00,
        change: -30.00,
        percentChange: -0.82,
        candles: _generateSmartCandles('LT', 3620.00, count: 5),
      ),
      StockModel(
        symbol: 'AXISBANK',
        name: 'Axis Bank Ltd',
        price: 1142.50,
        change: -5.60,
        percentChange: -0.49,
        candles: _generateSmartCandles('AXISBANK', 1142.50, count: 5),
      ),
    ];
  }

  List<Candle> _generateSmartCandles(String symbol, double basePrice, {required int count}) {
    final List<Candle> candles = [];
    final int seed = symbol.hashCode.abs();
    final double stockFactor = (seed % 100) / 100.0;
    
    // Matching volatility multiplier
    final double volatilityMultiplier = 0.8 + (stockFactor * 1.7);
    
    // Generate historical candles leading up to market open (33300)
    // 60 seconds (1 minute) interval per candle
    int startTime = 33300 - (count * 60);
    double lastClose = basePrice;
    
    for (int i = 0; i < count; i++) {
      final int time = startTime + (i * 60);
      final double open = lastClose;
      
      // Calculate a highly deterministic and beautiful intraday trend using sine waves
      final double dayFraction = (time - 33300) / 22500.0;
      final double wave1 = 0.018 * sin(dayFraction * pi * 2 + (stockFactor * pi)) * volatilityMultiplier;
      final double wave2 = 0.008 * cos(dayFraction * pi * 4 - (stockFactor * pi / 2)) * volatilityMultiplier;
      
      final random = Random(seed ^ time);
      final double noise = (random.nextDouble() - 0.48) * 0.004 * volatilityMultiplier;
      
      final double close = basePrice * (1.0 + wave1 + wave2 + noise);
      
      // Keep high/low realistic and bound
      final double high = (open > close ? open : close) + (random.nextDouble() * 0.0008 * basePrice * volatilityMultiplier);
      final double low = (open < close ? open : close) - (random.nextDouble() * 0.0008 * basePrice * volatilityMultiplier);
      final double volume = 10000 + random.nextInt(90000).toDouble();
      
      candles.add(
        Candle(
          time: time,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );
      
      lastClose = close;
    }
    return candles;
  }
}
