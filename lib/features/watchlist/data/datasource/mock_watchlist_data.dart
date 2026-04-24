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
        candles: _generateSmartCandles(22350.85, count: 10),
      ),
      MarketIndexModel(
        symbol: 'SENSEX',
        name: 'BSE Sensex',
        price: 73651.35,
        change: 482.15,
        percentChange: 0.66,
        bgColor: const Color(0xFF0D47A1),
        // BSE Blue
        candles: _generateSmartCandles(73651.35, count: 10),
      ),
      MarketIndexModel(
        symbol: 'NIFTY BANK',
        name: 'Nifty Bank',
        price: 47582.10,
        change: -120.45,
        percentChange: -0.25,
        bgColor: const Color(0xFF4A148C),
        // Banking Purple
        candles: _generateSmartCandles(47582.10, count: 10),
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
        candles: _generateSmartCandles(2950.45, count: 5),
      ),
      StockModel(
        symbol: 'TCS',
        name: 'Tata Consultancy Services',
        price: 3845.00,
        change: -45.20,
        percentChange: -1.16,
        candles: _generateSmartCandles(3845.00, count: 5),
      ),
      StockModel(
        symbol: 'HDFCBANK',
        name: 'HDFC Bank Ltd',
        price: 1520.30,
        change: 5.15,
        percentChange: 0.34,
        candles: _generateSmartCandles(1520.30, count: 5),
      ),
      StockModel(
        symbol: 'INFY',
        name: 'Infosys Ltd',
        price: 1475.60,
        change: -8.40,
        percentChange: -0.57,
        candles: _generateSmartCandles(1475.60, count: 5),
      ),
      StockModel(
        symbol: 'ICICIBANK',
        name: 'ICICI Bank Ltd',
        price: 1085.25,
        change: 14.80,
        percentChange: 1.38,
        candles: _generateSmartCandles(1085.25, count: 5),
      ),
      StockModel(
        symbol: 'HINDUNILVR',
        name: 'Hindustan Unilever',
        price: 2520.75,
        change: -18.40,
        percentChange: -0.72,
        candles: _generateSmartCandles(2520.75, count: 5),
      ),
      StockModel(
        symbol: 'SBIN',
        name: 'State Bank of India',
        price: 820.10,
        change: 9.25,
        percentChange: 1.14,
        candles: _generateSmartCandles(820.10, count: 5),
      ),
      StockModel(
        symbol: 'BHARTIARTL',
        name: 'Bharti Airtel',
        price: 1345.60,
        change: 22.30,
        percentChange: 1.68,
        candles: _generateSmartCandles(1345.60, count: 5),
      ),
      StockModel(
        symbol: 'LT',
        name: 'Larsen & Toubro',
        price: 3620.00,
        change: -30.00,
        percentChange: -0.82,
        candles: _generateSmartCandles(3620.00, count: 5),
      ),
      StockModel(
        symbol: 'ASIANPAINT',
        name: 'Asian Paints',
        price: 3105.40,
        change: 6.20,
        percentChange: 0.20,
        candles: _generateSmartCandles(3105.40, count: 5),
      ),
      StockModel(
        symbol: 'ITC',
        name: 'ITC Ltd',
        price: 435.20,
        change: 2.15,
        percentChange: 0.50,
        candles: _generateSmartCandles(435.20, count: 5),
      ),
      StockModel(
        symbol: 'KOTAKBANK',
        name: 'Kotak Mahindra Bank',
        price: 1785.60,
        change: -12.40,
        percentChange: -0.69,
        candles: _generateSmartCandles(1785.60, count: 5),
      ),
      StockModel(
        symbol: 'AXISBANK',
        name: 'Axis Bank Ltd',
        price: 1120.45,
        change: 8.30,
        percentChange: 0.75,
        candles: _generateSmartCandles(1120.45, count: 5),
      ),
      StockModel(
        symbol: 'HCLTECH',
        name: 'HCL Technologies',
        price: 1465.00,
        change: -5.20,
        percentChange: -0.35,
        candles: _generateSmartCandles(1465.00, count: 5),
      ),
      StockModel(
        symbol: 'MARUTI',
        name: 'Maruti Suzuki India',
        price: 12450.00,
        change: 150.00,
        percentChange: 1.22,
        candles: _generateSmartCandles(12450.00, count: 5),
      ),
      StockModel(
        symbol: 'SUNPHARMA',
        name: 'Sun Pharmaceutical',
        price: 1620.30,
        change: 15.45,
        percentChange: 0.96,
        candles: _generateSmartCandles(1620.30, count: 5),
      ),
      StockModel(
        symbol: 'BAJFINANCE',
        name: 'Bajaj Finance Ltd',
        price: 6840.00,
        change: -95.00,
        percentChange: -1.37,
        candles: _generateSmartCandles(6840.00, count: 5),
      ),
      StockModel(
        symbol: 'WIPRO',
        name: 'Wipro Ltd',
        price: 462.80,
        change: -1.20,
        percentChange: -0.26,
        candles: _generateSmartCandles(462.80, count: 5),
      ),
      StockModel(
        symbol: 'TITAN',
        name: 'Titan Company Ltd',
        price: 3625.40,
        change: 42.10,
        percentChange: 1.18,
        candles: _generateSmartCandles(3625.40, count: 5),
      ),
      StockModel(
        symbol: 'ADANIENT',
        name: 'Adani Enterprises',
        price: 3140.00,
        change: 55.40,
        percentChange: 1.79,
        candles: _generateSmartCandles(3140.00, count: 5),
      ),
    ];
  }

  List<Candle> _generateSmartCandles(double basePrice, {required int count}) {
    final random = Random();
    final List<Candle> candles = [];

    // Start time: between 2 and 3 days ago
    final daysAgo = 2 + random.nextDouble(); // 2.0 to 3.0 days
    DateTime currentTime = DateTime.now().subtract(
      Duration(hours: (daysAgo * 24).toInt()),
    );

    // Interval for candles to reach roughly now
    final intervalHours = (daysAgo * 24) / count;

    double lastClose = basePrice;

    for (int i = 0; i < count; i++) {
      final open = lastClose;
      // Random walk with 2% max volatility per candle
      final volatility = open * 0.02;
      final close =
          open +
          (random.nextDouble() - 0.45) * volatility; // Slight upward bias
      final high =
          (open > close ? open : close) +
          random.nextDouble() * (volatility * 0.5);
      final low =
          (open < close ? open : close) -
          random.nextDouble() * (volatility * 0.5);

      final volume = 100000 + random.nextDouble() * 900000;

      candles.add(
        Candle(
          time: currentTime.millisecondsSinceEpoch ~/ 1000,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );

      lastClose = close;
      currentTime = currentTime.add(Duration(hours: intervalHours.toInt()));
    }

    return candles;
  }
}
