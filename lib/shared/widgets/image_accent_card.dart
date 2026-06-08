import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/responsive.dart';

enum ImageAccentContentStyle { split, glass, fullOverlay, plain }

enum ImageAccentFit { cover, visibleTop, contain }

class ImageAccentCard extends StatelessWidget {
  const ImageAccentCard({
    super.key,
    required this.imageAsset,
    required this.child,
    this.onTap,
    this.accentColor = AppTheme.primary,
    this.padding = const EdgeInsets.all(16),
    this.imageWidth = 86,
    this.contentStyle = ImageAccentContentStyle.split,
    this.imageFit = ImageAccentFit.cover,
  });

  final String imageAsset;
  final Widget child;
  final VoidCallback? onTap;
  final Color accentColor;
  final EdgeInsets padding;
  final double imageWidth;
  final ImageAccentContentStyle contentStyle;
  final ImageAccentFit imageFit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textScaler = MediaQuery.textScalerOf(context);

    final card = LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 32;
        final responsiveHeight = RepairSizing.imageCardHeight(
          context,
          availableWidth,
        );
        final imageHeight = textScaler.scale(1) > 1.25
            ? responsiveHeight.clamp(104.0, 168.0)
            : responsiveHeight;
        final compactPadding =
            availableWidth < 180 ? const EdgeInsets.all(12) : padding;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : accentColor.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: contentStyle == ImageAccentContentStyle.split
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      child: _ImageBand(
                        imageAsset: imageAsset,
                        accentColor: accentColor,
                        imageFit: imageFit,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E28)
                            : Colors.white.withValues(alpha: 0.98),
                      ),
                      child: Padding(padding: compactPadding, child: child),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: accentColor.withValues(alpha: 0.22),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(
                                alpha: isDark ? 0.30 : 0.18,
                              ),
                              Colors.black.withValues(
                                alpha: isDark ? 0.28 : 0.10,
                              ),
                              accentColor.withValues(
                                alpha: isDark ? 0.08 : 0.02,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: _ImageCardContentPlate(
                        accentColor: accentColor,
                        padding: compactPadding,
                        style: contentStyle,
                        child: child,
                      ),
                    ),
                  ],
                ),
        );
      },
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: card,
      ),
    );
  }
}

class _ImageBand extends StatelessWidget {
  const _ImageBand({
    required this.imageAsset,
    required this.accentColor,
    required this.imageFit,
  });

  final String imageAsset;
  final Color accentColor;
  final ImageAccentFit imageFit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: accentColor.withValues(alpha: isDark ? 0.16 : 0.08),
          ),
        ),
        Align(
          alignment: imageFit == ImageAccentFit.visibleTop
              ? Alignment.topCenter
              : Alignment.center,
          child: Image.asset(
            imageAsset,
            width: double.infinity,
            height: double.infinity,
            fit: switch (imageFit) {
              ImageAccentFit.cover => BoxFit.cover,
              ImageAccentFit.visibleTop => BoxFit.contain,
              ImageAccentFit.contain => BoxFit.contain,
            },
            errorBuilder: (_, __, ___) =>
                ColoredBox(color: accentColor.withValues(alpha: 0.22)),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                AppTheme.primary.withValues(alpha: isDark ? 0.42 : 0.30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageCardContentPlate extends StatelessWidget {
  const _ImageCardContentPlate({
    required this.accentColor,
    required this.padding,
    required this.style,
    required this.child,
  });

  final Color accentColor;
  final EdgeInsets padding;
  final ImageAccentContentStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    if (style == ImageAccentContentStyle.plain) {
      return Padding(padding: padding, child: child);
    }

    if (style == ImageAccentContentStyle.fullOverlay) {
      return Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: IconTheme.merge(
            data: const IconThemeData(color: Colors.white),
            child: child,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radius - 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF171126).withValues(alpha: 0.50)
                : Colors.white.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(AppTheme.radius - 2),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.54),
            ),
          ),
          child: Padding(
            padding: padding,
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: scheme.copyWith(
                  primary: accentColor,
                  onSurface: isDark ? Colors.white : const Color(0xFF1F1737),
                  onSurfaceVariant:
                      isDark ? Colors.white70 : const Color(0xFF5C5670),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
