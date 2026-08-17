import '../../../player/domain/entities/player_enums.dart';

class PlayerSearchFilters {
  const PlayerSearchFilters({
    this.search,
    this.country,
    this.minAge,
    this.maxAge,
    this.position,
    this.minHeight,
    this.maxHeight,
    this.weight,
    this.preferredFoot,
    this.sport,
    this.page = 1,
  });

  final String? search;
  final String? country;
  final int? minAge;
  final int? maxAge;
  final String? position;
  final int? minHeight;
  final int? maxHeight;
  final int? weight;
  final PreferredFoot? preferredFoot;
  final String? sport;
  final int page;

  PlayerSearchFilters copyWith({
    String? search,
    String? country,
    int? minAge,
    int? maxAge,
    String? position,
    int? minHeight,
    int? maxHeight,
    int? weight,
    PreferredFoot? preferredFoot,
    String? sport,
    int? page,
  }) {
    return PlayerSearchFilters(
      search: search ?? this.search,
      country: country ?? this.country,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      position: position ?? this.position,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      weight: weight ?? this.weight,
      preferredFoot: preferredFoot ?? this.preferredFoot,
      sport: sport ?? this.sport,
      page: page ?? this.page,
    );
  }
}
