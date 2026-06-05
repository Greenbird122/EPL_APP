import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/backend_config.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/language_toggle.dart';
import 'package:repair_ai/shared/widgets/theme_mode_toggle.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.imageAsset,
    this.showBack = false,
    this.imageOverlayOpacity = 0.3,
    this.showCompactSupport = true,
    this.errorMessage,
    this.statusMessage,
    this.onDismissError,
    this.isLoading = false,
    this.statusTone = AuthStatusTone.info,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? imageAsset;
  final bool showBack;
  final double imageOverlayOpacity;
  final bool showCompactSupport;
  final String? errorMessage;
  final String? statusMessage;
  final VoidCallback? onDismissError;
  final bool isLoading;
  final AuthStatusTone statusTone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final image = imageAsset ?? 'assets/illustrations/mama.jpeg';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardOpen = viewInsets.bottom > 0;
    final topGap = keyboardOpen
        ? 28.0
        : (size.height * 0.13).clamp(56.0, 118.0).toDouble();
    final horizontalPadding = size.width < 380 ? 12.0 : 14.0;
    final panelPadding = size.width < 380
        ? const EdgeInsets.fromLTRB(14, 16, 14, 16)
        : const EdgeInsets.fromLTRB(18, 20, 18, 20);
    final glassTint = isDark
        ? const Color(0xFF1F1737).withValues(alpha: 0.68)
        : Colors.white.withValues(alpha: 0.58);
    final fieldFill = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.74);

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: AppTheme.primary,
            ),
          ),
          ColoredBox(
            color: AppTheme.primary.withValues(alpha: imageOverlayOpacity),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.28),
                  AppTheme.primary.withValues(alpha: isDark ? 0.74 : 0.48),
                  (isDark ? Colors.black : const Color(0xFFE9E2FF))
                      .withValues(alpha: isDark ? 0.78 : 0.58),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                viewInsets.bottom + 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showBack)
                        _GlassIconButton(
                          icon: Icons.arrow_back,
                          onPressed: () => context.pop(),
                        )
                      else
                        const SizedBox(width: 44),
                      const Spacer(),
                      const _GlassControlPill(child: LanguageToggle()),
                      const SizedBox(width: 8),
                      const _GlassControlPill(child: ThemeModeToggle()),
                    ],
                  ),
                  SizedBox(height: topGap),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontSize: size.width < 360 ? 24 : null,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (errorMessage != null) ...[
                    AuthErrorBanner(
                      message: errorMessage!,
                      onDismiss: onDismissError,
                    ),
                    const SizedBox(height: 12),
                  ] else if (statusMessage != null || isLoading) ...[
                    AuthStatusBanner(
                      message: statusMessage ?? 'Connecting to REPAIR-AI...',
                      tone: statusTone,
                      showProgress: isLoading,
                    ),
                    const SizedBox(height: 12),
                  ],
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: glassTint,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.14 : 0.48,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        padding: panelPadding,
                        child: Material(
                          type: MaterialType.transparency,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: Theme.of(context)
                                  .inputDecorationTheme
                                  .copyWith(fillColor: fieldFill, filled: true),
                              outlinedButtonTheme: OutlinedButtonThemeData(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: BorderSide(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                child,
                                if (showCompactSupport) ...[
                                  const SizedBox(height: 14),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 6,
                                    children: [
                                      Text(
                                        kDebugMode
                                            ? '${l10n.useUssdTitle} · ${BackendConfig.defaultBaseUrl}'
                                            : l10n.useUssdTitle,
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: launchUssdCode,
                                        child: const Text(kRepairAiUssdCode),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassControlPill extends StatelessWidget {
  const _GlassControlPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.44)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.72),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: AppTheme.primary),
          ),
        ),
      ),
    );
  }
}
