import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';

enum ImageAccentContentStyle {
  glass,
  fullOverlay,
  plain,
}

class ImageAccentCard extends StatelessWidget {
  const ImageAccentCard({
    super.key,
    required this.imageAsset,
    required this.child,
    this.onTap,
    this.accentColor = AppTheme.primary,
    this.padding = const EdgeInsets.all(16),
    this.imageWidth = 86,
    this.contentStyle = ImageAccentContentStyle.glass,
  });

  final String imageAsset;
  final Widget child;
  final VoidCallback? onTap;
  final Color accentColor;
  final EdgeInsets padding;
  final double imageWidth;
  final ImageAccentContentStyle contentStyle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Container(
      constraints: BoxConstraints(minHeight: imageWidth + 34),
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
      child: Stack(
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
                    accentColor.withValues(alpha: isDark ? 0.30 : 0.18),
                    Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
                    accentColor.withValues(alpha: isDark ? 0.08 : 0.02),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: _ImageCardContentPlate(
              accentColor: accentColor,
              padding: padding,
              style: contentStyle,
              child: child,
            ),
          ),
        ],
      ),
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
