import 'package:flutter/material.dart';
import 'package:repair_ai/core/utils/responsive.dart';

class ConstrainedPage extends StatelessWidget {
  const ConstrainedPage({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double? maxWidth;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final resolvedMaxWidth = maxWidth ?? RepairSizing.contentMaxWidth(context);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class ResponsivePageShell extends StatelessWidget {
  const ResponsivePageShell({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ConstrainedPage(
      maxWidth: maxWidth,
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
  }
}
