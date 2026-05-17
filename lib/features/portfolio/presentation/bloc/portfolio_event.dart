import 'package:equatable/equatable.dart';

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
