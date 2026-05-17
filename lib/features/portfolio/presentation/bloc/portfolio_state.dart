import 'package:equatable/equatable.dart';

import '../../../trading/domain/entities/holding.dart';

/// Represents the calculated P&L for a single holding
class HoldingDisplayModel extends Equatable {
  final Holding holding;
  final double currentPrice;
  final int currentValuePaisa;
  final int pnlPaisa;
  final double pnlPercent;

  const HoldingDisplayModel({
    required this.holding,
    required this.currentPrice,
    required this.currentValuePaisa,
    required this.pnlPaisa,
    required this.pnlPercent,
  });

  @override
  List<Object?> get props => [
    holding,
    currentPrice,
    currentValuePaisa,
    pnlPaisa,
    pnlPercent,
  ];
}

sealed class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object?> get props => [];
}

class PortfolioInitial extends PortfolioState {}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final List<HoldingDisplayModel> holdings;
  final int totalInvestedPaisa;
  final int totalCurrentValuePaisa;
  final int totalPnLPaisa;
  final double totalPnLPercent;

  const PortfolioLoaded({
    required this.holdings,
    required this.totalInvestedPaisa,
    required this.totalCurrentValuePaisa,
    required this.totalPnLPaisa,
    required this.totalPnLPercent,
  });

  @override
  List<Object?> get props => [
    holdings,
    totalInvestedPaisa,
    totalCurrentValuePaisa,
    totalPnLPaisa,
    totalPnLPercent,
  ];
}

class PortfolioEmpty extends PortfolioState {}
