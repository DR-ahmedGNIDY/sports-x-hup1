# Phase Mobile M8 — quality, RTL and accessibility

**Plan:** [MOBILE_APP_EXPERIENCE_PLAN.md](MOBILE_APP_EXPERIENCE_PLAN.md), stage M8
**Goal:** hold the seven phases before it to the matrix they were supposed to
survive.
**Status:** complete. Analyze clean, 127/127 tests, built and checked at 320px.

---

## Audited rather than assumed

The plan listed an RTL sweep of directional padding. The sweep found **zero**
non-directional `EdgeInsets.only(left:/right:)` in the whole app — that
discipline was already there. What it did find was 24 hardcoded `Alignment` and
`Positioned` values, of which **five were genuine defects** and the rest were
geometry that no language mirrors:

| Defect | Effect in Arabic |
|---|---|
| Login's "forgot password?" (mobile and desktop) | sat at the reading start instead of the trailing edge of its field |
| Change email / change password submit buttons | jumped to the opposite side of the form |
| Media tile's delete badge | pinned to the same visual corner in both directions, so it covered different content |
| Video card's category chip and action | the chip that reads first ended up at the trailing edge |

The pitch and court canvases, the auth panel gradient and the hero glow were
left alone: a football pitch is not mirrored by the language describing it.

## The tab bar overflowed, and only a test found it

Set the system text to 2x — the ceiling both platforms expose, and the setting
the people who most need it actually use — put it on a 320px phone, and the
navigation bar I built in M2 **overflowed by 5 pixels**. Nothing in seven
phases of manual checking had caught it, because nobody had turned the setting
on.

The fix clamps the *label's* scale inside that one subtree to 1.3. That is a
trade and worth naming as one: the icon carries the same meaning at any size,
the `Semantics` label is read aloud at any size, and the alternative — a
navigation bar consuming a third of a 640px screen — is worse for exactly the
same person. Nothing else in the app is clamped.

## Seventeen buttons that said nothing

An `IconButton` with no `tooltip` announces itself to a screen reader as
"button" and nothing else — the icon is invisible to it, so the tooltip is the
only name there is. **Seventeen of the app's forty-eight had none**: every
pagination arrow, the password reveal, the search clear, edit and delete on
achievements and social links, send on both comment sheets, delete on a
comment, and the video player's own play/pause.

All seventeen now carry a localized label, from nine new keys. A source-scanning
test keeps it that way — the point is coverage across all forty-eight, and no
widget test mounts every screen they live on. It is also what found the second
nine: the first pass fixed ten, the test immediately named the rest.

---

## A mistake worth recording

Midway through, `dart format lib/features` reformatted **176 files** — the
whole feature tree, most of it untouched by this phase. A commit like that
buries five real fixes in thousands of lines of reflow and makes the history
useless to whoever reads it next.

`git diff -w` could not separate them, because the formatter re-wraps lines
rather than only changing whitespace within them. The clean recovery was to
revert `lib/features` wholesale and re-apply the twelve intentional edits
deliberately. Formatting now runs on named files only.

---

## Verification

- `flutter analyze` clean, `flutter test` **127/127**.
- Sixteen tests are new, in `test/core/accessibility_test.dart` plus one in the
  shell suite:
  - **Text scaling** at 1x, 1.5x and 2x, and an empty state at 2x on 320px.
  - **The device matrix** from the plan: iPhone SE, a 320px Android, iPhone 15
    Pro, Pixel 8.
  - **Direction × theme**: all four combinations of LTR/RTL and light/dark.
  - **Mirroring**, measured rather than eyeballed: a row's icon is to the left
    of its label in LTR and to the right in RTL.
  - **Touch targets**: a tappable row clears `AppTouch.minTarget` on the
    smallest phone.
  - **Screen-reader names**: every `IconButton` in `lib/` has a tooltip.
  - **The tab bar** at 2x text on 320px — the test that found the overflow.
- Built and loaded at 320×640 with a clean console.

**Not done: golden tests.** The plan asked for them on the M3 components, and
they were considered and rejected. Flutter goldens are pixel comparisons whose
output depends on the platform's font rasterisation, so files generated here on
Windows would fail against the project's own Linux Docker build — a suite that
only passes on the machine that wrote it is worse than none, because it teaches
people to re-baseline instead of to look. The measurable properties goldens
would have protected — mirroring, sizes, spacing, divider counts, chevron rules
— are asserted directly by the tests above and in M3's, which are
platform-independent. Worth revisiting if this project ever gets a fixed Linux
CI to generate baselines on.

---

## The eight phases

M0 viewport and boot · M1 tokens and type · M2 stateful shell · M3 component
library · M4 screen migration · M5 motion and touch · M6 performance · M8
quality — with M7's PWA and offline in between. Fifteen defects fixed along the
way that were not on any plan, most of them found by testing rather than by
reading.
