# Club Experience 2.0 — Phase 3: Player Discovery, Shortlist & Final Polish

**Status:** Phase 3 of 3 implemented. Scope: turn Find Players + Saved
Players into a professional discovery/shortlist experience, and a final
polish pass over what Phase 1/2 didn't already cover.

## 0. Inspection first

Search Players, Saved Players, the Public Player Profile's Contact
section, and the Public Players listing all predate the "Phase Club"
project — they're part of the original app, not something Phase Club 1-3
touched. Inspecting them against this phase's brief found a very different
polish level than the Club Players roster (which Phase Club 1-3 already
brought up to a high bar):

Already correct, left untouched:
- **Contact Experience** (`SimpleContactActions`) — WhatsApp/Email/Phone
  buttons on the Public Player Profile, Club-only (enforced both in the
  UI and server-side on `GET /players/:id/contact`), only rendering the
  methods actually present. This already fully satisfies the brief's §6.
- **Save/Unsave from the Profile page** (`SavePlayerButton`) — the
  brief's §7 "Save/Unsave" action, already present and Club-gated the
  same way.
- **Desktop vs. Mobile filter chrome** — Desktop already has a persistent
  left filter sidebar + results grid (brief §3); Mobile already opens
  filters in a bottom sheet instead of a sidebar (brief §4). Structurally
  already correct — the sheet/sidebar split just needed the content
  inside it fixed (see below).
- Navigation placement of Find Players / Saved Players (Phase 1).

Real gaps found and fixed this phase:
1. **No name search at all.** `SearchPlayersDto`/`PlayerSearchFilters`
   had 8 filter fields (country, age, position, height, weight, foot,
   sport) but nothing to search by the player's own name — the brief's
   own first-listed filter ("Search Player Name").
2. **The filters form and pagination were entirely un-localized** —
   `Text('Sport')`, `Text('Min age')`, `Text('Page 1 of 3')`, etc., all
   hardcoded English, no `AppLocalizations` calls anywhere in the file.
   Notably, `minAgeLabel`/`maxAgeLabel`/`minHeightLabel`/
   `maxHeightLabel`/`applyFiltersLabel`/`playersNoResults`/
   `noSavedPlayers`/`filtersTooltip`/`pageOfPagesLabel` **already existed
   in both ARB files** with correct ar/en translations — they were simply
   never wired into the widgets that needed them. This phase wires them
   in rather than adding duplicates.
3. **No result count** — a club had no way to see "12 players found"
   anywhere.
4. **Saved Players' empty state was a bare hardcoded sentence** — no
   illustration (Search already had one), no "Find Players" CTA (the
   brief's §9 explicitly asks for one on this exact screen).

## 1. Name search — backend + frontend

Backend: `SearchPlayersDto` gains an optional `search` field.
`PlayersService.search()` matches it against `firstName`/`lastName` via a
case-insensitive, regex-escaped `$or` query — the same `escapeRegex()`
helper and pattern `findManyByUserIdsFiltered` (the Club roster's own
search, from Phase Club 3) already uses, just **without** phone: this is
a public, unauthenticated endpoint, so private contact data is never part
of the match here (unlike the Club's own roster search, which is
authenticated and scoped to that Club's own players).

Frontend: `PlayerSearchFilters` gains `search`; a new `PlayerSearchBox`
widget (debounced 400ms, same pattern as `ClubPlayersToolbar`'s search
field) sits above the results on both Desktop and Mobile — separate from
the Sport/Position/etc. filter form, since a name search is the primary,
always-visible entry point, not something that should be buried behind a
filter sheet. `PlayerSearchController.updateSearch()` updates just the
search term while preserving whatever filters are already active (built
directly rather than via `copyWith`, since `copyWith`'s
`x ?? this.x` pattern can't express "clear this field" — needed here
because clearing the search box must actually clear the filter, not
silently keep the old value).

## 2. Localization — wiring in what already existed

`PlayerSearchFiltersForm`: every hardcoded label swapped for the
already-existing key (`sportLabel`, `positionLabel`, `countryLabel`,
`minAgeLabel`, `maxAgeLabel`, `minHeightLabel`, `maxHeightLabel`,
`weightLabel`, `preferredFootLabel` via the existing `preferredFootLabel()`
helper, `applyFiltersLabel`, and `clubPlayersAnyFilterOption` reused for
every "Any" dropdown entry rather than adding a duplicate "Any" key).

`SearchPagination`: "Page X of Y" now uses the existing `pageOfPagesLabel`
— this was a documented known-limitation from Phase Club 3's own summary
("`SearchPagination` has a pre-existing hardcoded-English label bug...
deliberately not fixed [then] since it's a different feature outside
[Phase Club 3's] scope"). It's in this phase's scope, so it's fixed now.

Search/Mobile "Filters" tooltip and section title: now use the existing
`filtersTooltip` key instead of a hardcoded string.

Empty states: Search's "No players match these filters." now uses the
existing `playersNoResults` key; Saved Players' empty text now uses the
existing `noSavedPlayers` key. (`PlayerSearchResultCard`'s unit suffixes —
`20y`, `180cm`, `75kg` — were deliberately left as compact non-localized
text, matching the exact same established pattern already used by the
Player's own `buildQuickFacts` — see `player_profile_data.dart` — which
also concatenates `'$value cm'`/`'$value kg'` without localizing the unit
letters. Not a gap; consistent with house style.)

## 3. Result count

Both Desktop and Mobile Find Players now show `l10n.searchResultsCountLabel`
("{count} players found" / "{count} لاعب متاح") under the search box,
sourced from the same `page.total` the pagination widget already reads —
no new request.

## 4. Saved Players — Shortlist polish

Both Desktop and Mobile empty states now use `EmptyStateIllustration`
(matching Search's existing pattern) and a "Find Players" `FilledButton`
routing to `/search`, per the brief's §9 spec for this exact screen.
Kept the "Saved Players" terminology (already the established product
term throughout the app's navigation/dashboard) rather than introducing
"Shortlist" as new branding — the brief explicitly allows either.

The View → Contact → Remove flow itself needed no new UI: tapping a saved
player already opens the full Public Player Profile, where Contact
(`SimpleContactActions`) and Save/Unsave (`SavePlayerButton`) already
live; the list's own bookmark icon doubles as Remove. Adding a second,
inline set of Contact buttons directly on every shortlist card was
considered and rejected — it would duplicate what one tap away already
provides and works against the "don't overcrowd" principle the same
brief applies elsewhere (e.g. Phase Club 3's roster card review).

## 5. What was deliberately left alone

- The Public Players listing page (`/players`, the signed-out marketing
  browse page) — out of this phase's scope (it's not the Club's
  authenticated discovery tool), though it automatically inherited the
  filters-form and pagination localization fixes since it reuses the same
  shared widgets.
- `PlayerSearchResultCard`'s overall layout/structure — still a
  `ListTile`-based card (photo, name, sport/position, age/country/height/
  weight). A full visual rewrite was considered but scoped out: the card
  is shared by three different screens (Search, Saved, Public listing),
  so a redesign risk/effort was disproportionate to what remained a
  genuinely legible, working card once localized and given a result count
  + name search around it. This is a deliberate scope trade-off, the same
  kind Phase Club 3 documented for its own filter-bar layout.

## 6. Security

No guard, role, or endpoint authorization changed. The new `search` query
param on the public `GET /players` flows through the exact same
`escapeRegex()` → `$regex` pattern already proven safe by
`findManyByUserIdsFiltered`, and only ever matches `firstName`/`lastName`
on `PUBLIC`-visibility profiles (the existing `filter.visibility` clause,
untouched). `SimpleContactActions`/`SavePlayerButton`'s Club-only gating
(both UI-side and the backend's own `GET /players/:id/contact` role
check) is unchanged.

## 7. Localization

New keys (`ar`+`en`): `playerSearchNameLabel`, `searchResultsCountLabel`.
Every other string this phase touches reuses an existing key (see §2) —
deliberately, to avoid growing the ARB files with near-duplicates.
`flutter gen-l10n` was run to regenerate the Dart delegates.

## 8. Verification

- `flutter analyze` — **no issues**.
- `flutter test` — **9/9 passing** (a 10th pre-existing widget test,
  `AppTheme exposes both light and dark themes`, was also observed
  passing in this run).
- Backend `npm run build` — **clean**.
- Backend `npm run lint` — **one pre-existing error**, unrelated
  (`src/videos/videos.service.ts:25`), unchanged from Phase 1/2.
- Backend `npm test` — **58/58 passing** (10 suites, unchanged count —
  this phase's backend change was small enough not to warrant a new spec
  file; see Known Limitations).
- Live manual verification against a real (Atlas) MongoDB backend:
  registered a fresh Club account, opened Find Players on Mobile,
  confirmed the search box + result count + localized filter sheet all
  render correctly, typed a name and confirmed the result list narrowed
  to the matching player only, saved a player and confirmed it appeared
  in Saved Players, unsaved it and confirmed the new empty state +
  "Find Players" button render and correctly navigate back to Find
  Players with the previous search state intact.

## 9. Known limitations

- **No dedicated test coverage for `PlayersService.search()`'s new
  `search` param at the time this phase shipped** — `players.service.ts`
  already had a spec file with 20+ tests for its other methods (correction:
  an earlier version of this note incorrectly said no spec file existed
  for it at all), but none of them exercised `search()`, old filters
  included. Standing up coverage for one small, low-risk addition
  (reusing an already-proven `escapeRegex` pattern) was judged
  disproportionate to this phase's own change at the time. Covered
  instead by the live manual verification in §8 (typed "Ahmed", confirmed
  the result list correctly narrowed to the one matching player).
  **Resolved** in the post-launch release audit
  (`docs/CLUB_EXPERIENCE_2_RELEASE_AUDIT.md`), which added 8 tests
  covering visibility scoping, name matching/escaping, exact-match
  filters, height/age ranges, and pagination.
- **`PlayerSearchResultCard` was not visually redesigned** — see §5 for
  the reasoning (shared across 3 screens, disproportionate risk).
- **Desktop viewport verification relied on code review**, same
  environment limitation documented in Phase 1/2 (this session's browser
  preview harness doesn't propagate post-load viewport resizes to the
  Flutter canvas); the Mobile path was fully click-verified, and Desktop
  shares 100% of the underlying widgets/logic.

## 10. Club Experience 2.0 — overall status

All three phases are now complete. The Club's daily flow —
**Manage Players** (Dashboard → Roster → Add/Edit/Remove) →
**Discover Players** (Find Players, name + filter search) →
**Shortlist** (Save/Unsave) → **Contact** (WhatsApp/Email/Phone) — is
fully wired, localized (ar/en, RTL/LTR), and ownership-secured end to
end, without adding AI, analytics, payments, or any of the explicitly
out-of-scope features from the original brief.
