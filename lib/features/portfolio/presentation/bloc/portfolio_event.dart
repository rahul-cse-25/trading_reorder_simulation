import 'package:equatable/equatable.dart';

enum PortfolioSortType {
  pnl,
  symbol,
  currentValue,
}

sealed class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when the app starts or when a trade completes
class LoadPortfolio extends PortfolioEvent {}

/// Triggered by WatchlistBloc price updates
class UpdateLivePrices extends PortfolioEvent {
  final Map<String, double> prices;
  const UpdateLivePrices(this.prices);

  @override
  List<Object?> get props => [prices];
}

class ChangePortfolioSortType extends PortfolioEvent {
  final PortfolioSortType sortType;
  const ChangePortfolioSortType(this.sortType);

  @override
  List<Object?> get props => [sortType];
}
