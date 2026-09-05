/// Search/filter/page state for the Club Players roster — mirrors
/// `PlayerSearchFilters`' shape (search feature) so the same
/// apply-resets-to-page-1 / loadPage-keeps-filters pattern applies here
/// too. All server-side (see `ClubPlayersController`); nothing here ever
/// filters an already-downloaded list on the client.
class ClubPlayersFilters {
  const ClubPlayersFilters({
    this.search,
    this.sport,
    this.position,
    this.birthYear,
    this.page = 1,
  });

  final String? search;
  final String? sport;
  final String? position;

  /// Exact birth year (e.g. 2010) — how clubs group players into age
  /// categories, not a min/max-age range.
  final int? birthYear;
  final int page;

  ClubPlayersFilters copyWith({
    String? search,
    String? sport,
    String? position,
    int? birthYear,
    int? page,
  }) {
    return ClubPlayersFilters(
      search: search ?? this.search,
      sport: sport ?? this.sport,
      position: position ?? this.position,
      birthYear: birthYear ?? this.birthYear,
      page: page ?? this.page,
    );
  }

  /// Only [page] changes; a `null` given for the others deliberately
  /// *clears* that filter instead of falling back to the current value —
  /// [copyWith] can't express "set this back to empty".
  factory ClubPlayersFilters.cleared({
    String? search,
    String? sport,
    String? position,
    int? birthYear,
    int page = 1,
  }) {
    return ClubPlayersFilters(
      search: search,
      sport: sport,
      position: position,
      birthYear: birthYear,
      page: page,
    );
  }
}
