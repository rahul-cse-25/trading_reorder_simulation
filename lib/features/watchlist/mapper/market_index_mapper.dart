import '../data/models/market_index_model.dart';
import '../domain/entities/market_index.dart';

class MarketIndexMapper {
  static MarketIndex toEntity(MarketIndexModel model) {
    return MarketIndex(
      symbol: model.symbol,
      name: model.name,
      price: model.price,
      change: model.change,
      percentChange: model.percentChange,
      candles: model.candles,
      bgColor: model.bgColor,
    );
  }
}
