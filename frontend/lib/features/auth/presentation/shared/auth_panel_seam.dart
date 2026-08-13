import 'package:flutter/material.dart';

import '../../../../core/widgets/app_logo.dart';

/// Subtle visual bridge between [AuthVideoPanel] and the form panel on
/// Desktop auth screens — a soft gradient fade from the video panel's dark
/// edge plus a faint [AppLogo] watermark centered on the seam, so the two
/// halves read as one composition instead of an abrupt cut.
///
/// Purely decorative and non-interactive; place as the first child of a
/// [Stack] that also holds the form content, pinned to the left edge of the
/// form-side panel (i.e. right up against [AuthVideoPanel]'s right edge).
/// The gradient fades to transparent so it works unchanged over either the
/// light or dark Scaffold background.
class AuthPanelSeam extends StatelessWidget {
  const AuthPanelSeam({super.key});

  static const double _width = 96;

  // Matches AuthVideoPanel's own background/scrim color so the fade reads
  // as a continuation of the video panel rather than a new tone.
  static const Color _videoPanelColor = Color(0xFF0B0E14);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: _width,
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _videoPanelColor.withValues(alpha: 0.32),
                    _videoPanelColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            const Opacity(opacity: 0.07, child: AppLogo(height: 48)),
          ],
        ),
      ),
    );
  }
}
