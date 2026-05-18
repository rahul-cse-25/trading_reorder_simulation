import 'package:equatable/equatable.dart';

/// [CustomWatchlist] represents a user-created watchlist containing stock symbols.
/// It is a pure domain entity — no UI, no persistence logic.
class CustomWatchlist extends Equatable {
  final String id;
  final String name;
  final List<String> symbols;

  const CustomWatchlist({
    required this.id,
    required this.name,
    required this.symbols,
  });

  CustomWatchlist copyWith({
    String? name,
    List<String>? symbols,
  }) {
    return CustomWatchlist(
      id: id,
      name: name ?? this.name,
      symbols: symbols ?? this.symbols,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'symbols': symbols,
      };

  factory CustomWatchlist.fromJson(Map<String, dynamic> json) {
    return CustomWatchlist(
      id: json['id'] as String,
      name: json['name'] as String,
      symbols: List<String>.from(json['symbols'] as List),
    );
  }

  @override
  List<Object?> get props => [id, name, symbols];
}
