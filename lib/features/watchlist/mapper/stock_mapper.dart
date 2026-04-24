import '../data/models/stock_model.dart';
import '../domain/entities/stock.dart';

class StockMapper {
  static Stock toEntity(StockModel model) {
    return Stock(
      symbol: model.symbol,
      name: model.name,
      price: model.price,
      change: model.change,
      percentChange: model.percentChange,
      candles: model.candles, // Both use imp_trading_chart.Candle now
    );
  }
}
