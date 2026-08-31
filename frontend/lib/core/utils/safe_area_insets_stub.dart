import 'package:flutter/widgets.dart';

/// Non-web implementation: the embedder already reports real safe-area
/// values through `MediaQuery.padding`, so there is nothing to add. Returning
/// [EdgeInsets.zero] makes `applyWebSafeArea` fall through untouched.
EdgeInsets readSafeAreaInsets() => EdgeInsets.zero;
