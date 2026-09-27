import 'package:flutter/material.dart';

enum SlideDirection { rightToLeft, leftToRight, bottomToTop, fadeOnly }

class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SmoothPageRoute({
    required this.page,
    this.direction = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 420),
    Duration reverseDuration = const Duration(milliseconds: 380),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubicEmphasized,
              reverseCurve: Curves.easeInOutCubic,
            );

            if (direction == SlideDirection.fadeOnly) {
              return FadeTransition(
                opacity: curvedAnimation,
                child: child,
              );
            }

            Offset beginOffset;
            switch (direction) {
              case SlideDirection.rightToLeft:
                beginOffset = const Offset(0.12, 0.0);
                break;
              case SlideDirection.leftToRight:
                beginOffset = const Offset(-0.12, 0.0);
                break;
              case SlideDirection.bottomToTop:
                beginOffset = const Offset(0.0, 0.08);
                break;
              default:
                beginOffset = const Offset(0.12, 0.0);
            }

            return SlideTransition(
              position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}
