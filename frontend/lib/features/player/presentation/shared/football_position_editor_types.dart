import 'package:flutter/widgets.dart';

/// Renders the Edit Profile position picker for one platform. Supplied by
/// the desktop/mobile Edit Profile pages to the shared [ProfileDetailsForm]
/// (`profile_details_form.dart`) so the form itself never branches on
/// platform — it only owns the `positions` state and reports taps/long-
/// presses back up through [onTap]/[onLongPress].
typedef FootballPositionEditorBuilder =
    Widget Function(
      BuildContext context, {
      required String? sport,
      required List<String> positions,
      required ValueChanged<String> onTap,
      required ValueChanged<String> onLongPress,
    });
