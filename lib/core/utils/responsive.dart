import 'dart:math' as math;

import 'package:flutter/material.dart';

class RepairBreakpoints {
  const RepairBreakpoints._();

  static bool isCompactPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 380;
  }

  static bool isShortScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).height < 720;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 700;
  }
}

class RepairInsets {
  const RepairInsets._();

  static EdgeInsets page(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 380) return const EdgeInsets.all(12);
    if (width >= 700) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  static EdgeInsets scroll(BuildContext context) {
    final base = page(context);
    return base.copyWith(bottom: scrollBottom(context));
  }

  static double scrollBottom(BuildContext context) {
    final padding = MediaQuery.paddingOf(context).bottom;
    return math.max(96, padding + 88);
  }
}

class RepairSizing {
  const RepairSizing._();

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 1040;
    if (width >= 700) return 900;
    return double.infinity;
  }

  static double formMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 700) return 760;
    return double.infinity;
  }

  static double heroHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.shortestSide;
    final byWidth = shortest * 0.46;
    final byHeight = size.height * 0.24;
    return math.min(byWidth, byHeight).clamp(150.0, 230.0).toDouble();
  }

  static double foregroundImageHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final byHeight =
        size.height * (RepairBreakpoints.isShortScreen(context) ? 0.22 : 0.28);
    final byWidth = size.width * 0.54;
    return math.min(byHeight, byWidth).clamp(128.0, 260.0).toDouble();
  }

  static double imageCardHeight(BuildContext context, double width) {
    final size = MediaQuery.sizeOf(context);
    final byWidth = width * 0.34;
    final byHeight = size.height * 0.18;
    return math.min(byWidth, byHeight).clamp(104.0, 190.0).toDouble();
  }

  static double mapHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return math
        .min(size.width * 0.38, size.height * 0.18)
        .clamp(116.0, 170.0)
        .toDouble();
  }

  static double symptomGridAspectRatio(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    if (width < 360 || textScale > 1.25) return 0.86;
    if (width < 420) return 0.96;
    return 1.08;
  }

  static double supportVisualSize(BuildContext context,
      {bool compact = false}) {
    final width = MediaQuery.sizeOf(context).width;
    if (compact || width < 360) return 44;
    if (width < 420) return 56;
    return 72;
  }
}
