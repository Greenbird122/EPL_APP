import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';

/// Full-bleed blurred photo background + gradient scrim + optional sharp foreground card.
class HeroImageStack extends StatelessWidget {
  const HeroImageStack({
    super.key,
    required this.imageAsset,
    this.accentColor,
    this.showForegroundCard = true,
    this.foregroundHeight,
    this.fallbackIcon,
    this.child,
  });

  final String imageAsset;
  final Color? accentColor;
  final bool showForegroundCard;
  final double? foregroundHeight;
  final IconData? fallbackIcon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? AppTheme.primary;
    final scrimEnd = isDark ? 0.78 : 0.58;
    final blurSigma = isDark ? 10.0 : 6.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(color: accent),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                accent.withValues(alpha: scrimEnd),
              ],
            ),
          ),
        ),
        if (child != null)
          child!
        else if (showForegroundCard)
          _ForegroundCard(
            imageAsset: imageAsset,
            accentColor: accent,
            height: foregroundHeight,
            fallbackIcon: fallbackIcon,
          ),
      ],
    );
  }
}

class _ForegroundCard extends StatelessWidget {
  const _ForegroundCard({
    required this.imageAsset,
    required this.accentColor,
    this.height,
    this.fallbackIcon,
  });

  final String imageAsset;
  final Color accentColor;
  final double? height;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final cardHeight = height ?? MediaQuery.of(context).size.height * 0.28;
    final cardWidth = MediaQuery.of(context).size.width * 0.72;

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight.clamp(160.0, 280.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: accentColor.withValues(alpha: 0.2),
              child: Icon(
                fallbackIcon ?? Icons.image_outlined,
                size: 56,
                color: accentColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact hero for home (no foreground card).
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({
    super.key,
    required this.imageAsset,
    required this.bottomChild,
    this.topChild,
  });

  final String imageAsset;
  final Widget bottomChild;
  final Widget? topChild;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          HeroImageStack(
            imageAsset: imageAsset,
            showForegroundCard: false,
          ),
          if (topChild != null)
            Positioned(top: 12, left: 16, right: 16, child: topChild!),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: bottomChild,
          ),
        ],
      ),
    );
  }
}
