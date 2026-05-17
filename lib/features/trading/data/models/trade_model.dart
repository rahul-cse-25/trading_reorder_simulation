import '../../domain/entities/trade.dart';

class TradeModel {
  final String id;
  final String symbol;
  final String stockName;
  final String type; // 'buy' or 'sell'
  final int quantity;
  final int pricePaisa;
  final int totalCostPaisa;
  final String timestamp; // ISO8601

  TradeModel({
    required this.id,
    required this.symbol,
    required this.stockName,
    required this.type,
    required this.quantity,
    required this.pricePaisa,
    required this.totalCostPaisa,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'stockName': stockName,
    'type': type,
    'quantity': quantity,
    'pricePaisa': pricePaisa,
    'totalCostPaisa': totalCostPaisa,
    'timestamp': timestamp,
  };

  factory TradeModel.fromJson(Map<String, dynamic> json) => TradeModel(
    id: json['id'],
    symbol: json['symbol'],
    stockName: json['stockName'],
    type: json['type'],
    quantity: json['quantity'],
    pricePaisa: json['pricePaisa'],
    totalCostPaisa: json['totalCostPaisa'],
    timestamp: json['timestamp'],
  );

  Trade toEntity() => Trade(
    id: id,
    symbol: symbol,
    stockName: stockName,
    type: type == 'buy' ? TradeType.buy : TradeType.sell,
    quantity: quantity,
    pricePaisa: pricePaisa,
    totalCostPaisa: totalCostPaisa,
    timestamp: DateTime.parse(timestamp),
  );

  factory TradeModel.fromEntity(Trade entity) => TradeModel(
    id: entity.id,
    symbol: entity.symbol,
    stockName: entity.stockName,
    type: entity.type == TradeType.buy ? 'buy' : 'sell',
    quantity: entity.quantity,
    pricePaisa: entity.pricePaisa,
    totalCostPaisa: entity.totalCostPaisa,
    timestamp: entity.timestamp.toIso8601String(),
  );
}
