import '../../domain/entities/holding.dart';

class HoldingModel {
  final String symbol;
  final String stockName;
  final int quantity;
  final double avgBuyPricePaisa;
  final int totalCostPaisa;

  HoldingModel({
    required this.symbol,
    required this.stockName,
    required this.quantity,
    required this.avgBuyPricePaisa,
    required this.totalCostPaisa,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'stockName': stockName,
    'quantity': quantity,
    'avgBuyPricePaisa': avgBuyPricePaisa,
    'totalCostPaisa': totalCostPaisa,
  };

  factory HoldingModel.fromJson(Map<String, dynamic> json) => HoldingModel(
    symbol: json['symbol'],
    stockName: json['stockName'],
    quantity: json['quantity'],
    avgBuyPricePaisa: (json['avgBuyPricePaisa'] as num).toDouble(),
    totalCostPaisa: json['totalCostPaisa'],
  );

  Holding toEntity() => Holding(
    symbol: symbol,
    stockName: stockName,
    quantity: quantity,
    totalCostPaisa: totalCostPaisa,
  );

  factory HoldingModel.fromEntity(Holding entity) => HoldingModel(
    symbol: entity.symbol,
    stockName: entity.stockName,
    quantity: entity.quantity,
    avgBuyPricePaisa: entity.avgBuyPricePaisa,
    totalCostPaisa: entity.totalCostPaisa,
  );
}
