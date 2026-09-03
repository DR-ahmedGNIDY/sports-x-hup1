// A guard against the bug that kept coming back.
//
// `AsyncValue.value` *rethrows* on an AsyncError instead of answering null,
// so `provider.value?.thing ?? fallback` does not fall back — it throws, and
// whatever was building at the time fails. It reads exactly like the safe
// form, the analyzer is happy with it, and every test passes as long as the
// request succeeds. It only shows up in front of a user whose network
// hiccuped.
//
// It reached production three times before this existed: the white results
// list on Search, the invitation card, and the navigation bar vanishing when
// a profile request failed. `valueOrNull` is the accessor that actually
// returns null. This scans for the unsafe form so there is no fourth.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reads that are AsyncValue reads, and never anything else.
///
/// Deliberately narrow. `.value` is also VideoPlayerController's state, an
/// Animation's position, a ValueNotifier's contents and a dozen widget
/// parameters — none of which are this bug. Matching those would make the
/// test noise, and a noisy guard gets deleted.
final _unsafe = <RegExp>[
  // ref.watch(fooProvider).value / ref.read(fooProvider).value
  RegExp(r'ref\.(?:watch|read)\([A-Za-z0-9_]*[Pp]rovider[^)]*\)\.value\b'),
  // state.value, inside an AsyncNotifier
  RegExp(r'\bstate\.value\b'),
  // someAsync.value — the conventional name for an AsyncValue local here
  RegExp(r'\b[A-Za-z0-9_]*[Aa]sync\.value\b'),
];

void main() {
  test('no AsyncValue.value reads in lib/ — use valueOrNull', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Comments explain the trap; they are not the trap.
        if (line.trimLeft().startsWith('//')) continue;
        if (_unsafe.any((pattern) => pattern.hasMatch(line))) {
          offenders.add(
            '${entity.path.replaceAll(r'\', '/')}:${i + 1}  ${line.trim()}',
          );
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'AsyncValue.value rethrows on error. Use valueOrNull:\n'
          '${offenders.join('\n')}',
    );
  });
}
