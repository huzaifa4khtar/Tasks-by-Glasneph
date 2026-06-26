import 'package:flutter/material.dart';

import '../constants.dart';

Route<dynamic> fadeRoute(Widget screen) {
  return PageRouteBuilder<dynamic>(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: AppDurations.long,
  );
}
