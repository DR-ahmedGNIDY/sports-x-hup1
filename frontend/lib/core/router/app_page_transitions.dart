import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_motion.dart';

/// Page transitions for the app's routes.
///
/// go_router's default on the web is no transition at all: a screen is simply
/// replaced, which is precisely how a web page behaves and precisely how an
/// app does not. Two transitions cover everything here, borrowed from the
/// grammar every phone platform shares:
///
/// * [slidePage] for hierarchical moves — opening a detail screen, an edit
///   form. The new screen comes in from the leading edge and the old one
///   yields, so the motion itself says "you went deeper" and the reverse says
///   "you came back".
/// * [fadePage] for lateral moves — one tab to another, the splash handing
///   off. There is no hierarchy to express, so a cross-fade is the honest
///   description.
///
/// Both respect [AppMotion] rather than inventing their own durations, and
/// both collapse to an instant swap when the platform asks for reduced
/// motion.

/// A hierarchical push/pop. Direction follows text direction, so on an Arabic
/// (RTL) layout the screen enters from the left exactly as it enters from the
/// right in English — the gesture and the motion have to agree.
CustomTransitionPage<T> slidePage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.base,
    reverseTransitionDuration: AppMotion.base,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;

      final leading = Directionality.of(context) == TextDirection.rtl
          ? const Offset(-1, 0)
          : const Offset(1, 0);

      return SlideTransition(
        position: Tween<Offset>(begin: leading, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: AppMotion.enter),
        ),
        // The outgoing screen slides a short way in the same direction rather
        // than sitting still — the parallax is what stops the two screens
        // reading as one flat sheet sliding past.
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset.zero, end: leading * -0.25)
              .animate(
                CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: AppMotion.exit,
                ),
              ),
          child: child,
        ),
      );
    },
  );
}

/// A lateral swap with no direction implied.
CustomTransitionPage<T> fadePage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.fast,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
