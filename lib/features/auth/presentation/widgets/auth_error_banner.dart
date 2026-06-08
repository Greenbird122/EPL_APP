import 'package:flutter/material.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.error.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 6),
              IconButton(
                onPressed: onDismiss,
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close,
                  color: scheme.onErrorContainer,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum AuthStatusTone { info, warning, success }

class AuthStatusBanner extends StatelessWidget {
  const AuthStatusBanner({
    super.key,
    required this.message,
    this.tone = AuthStatusTone.info,
    this.showProgress = false,
  });

  final String message;
  final AuthStatusTone tone;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (tone) {
      AuthStatusTone.success => (
          scheme.primaryContainer.withValues(alpha: 0.82),
          scheme.onPrimaryContainer,
          Icons.check_circle_outline,
        ),
      AuthStatusTone.warning => (
          scheme.tertiaryContainer.withValues(alpha: 0.82),
          scheme.onTertiaryContainer,
          Icons.info_outline,
        ),
      AuthStatusTone.info => (
          scheme.secondaryContainer.withValues(alpha: 0.82),
          scheme.onSecondaryContainer,
          Icons.info_outline,
        ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showProgress)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            else
              Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String friendlyAuthError(Object error, {String? fallback}) {
  if (error is ApiException) {
    final lower = error.message.toLowerCase();
    final statusCode = error.statusCode;
    if (statusCode == null) {
      return _friendlyMessageText(error.message, fallback: fallback);
    }
    final friendly = switch (statusCode) {
      400 => error.message,
      401 =>
        'We could not sign you in. Check your username and password, then try again.',
      403 => lower.contains('web dashboard')
          ? error.message
          : 'This account does not have permission to use this part of the app.',
      404 =>
        'This action is not available yet. Please check setup or contact support.',
      >= 500 =>
        'Care services are having trouble right now. Please try again shortly.',
      _ => _friendlyMessageText(error.message, fallback: fallback),
    };
    return friendly;
  }

  final raw = error.toString();
  final message =
      raw.replaceFirst(RegExp(r'^ApiException\(\d+\):\s*'), '').trim();
  return _friendlyMessageText(message, fallback: fallback);
}

String friendlyAuthStatusMessage(
  BuildContext context,
  Object error, {
  String? fallback,
}) {
  final l10n = AppLocalizations.of(context);
  if (error is ApiException) {
    final message = _cleanBackendMessage(error.message);
    final lower = message.toLowerCase();
    final statusCode = error.statusCode;
    if (statusCode == null) {
      return _friendlyMessageText(
        message,
        fallback: fallback ?? l10n.authCareServicesUnavailable,
      );
    }
    return switch (statusCode) {
      400 => message.isEmpty
          ? l10n.authSomeDetailsNeedChecking
          : '${l10n.authSomeDetailsNeedChecking}\n$message',
      401 => l10n.authCannotSignIn,
      403 => lower.contains('web dashboard') ? message : l10n.authNoPermission,
      404 => l10n.authActionUnavailable,
      >= 500 => l10n.authTryAgainSoon,
      _ =>
        _friendlyMessageText(message, fallback: fallback ?? l10n.genericError),
    };
  }

  return _friendlyMessageText(
    _cleanBackendMessage(error.toString()),
    fallback: fallback ?? l10n.genericError,
  );
}

String _friendlyMessageText(String message, {String? fallback}) {
  final lower = message.toLowerCase();

  if (lower.contains('no active account') ||
      lower.contains('invalid username') ||
      lower.contains('invalid credentials') ||
      lower.contains('unauthorized')) {
    return 'We could not sign you in. Check your username and password, then try again.';
  }

  if (lower.contains('failed host lookup') ||
      lower.contains('connection') ||
      lower.contains('xmlhttprequest') ||
      lower.contains('timed out') ||
      lower.contains('timeout')) {
    return 'We could not reach care services. Check your internet or try again shortly.';
  }

  if (lower.contains('forbidden') || lower.contains('permission')) {
    return 'You do not have permission to use this feature with this account.';
  }

  if (lower.contains('not found') || lower.contains('404')) {
    return 'This action is not available yet. Please check setup or contact support.';
  }

  if (message.isNotEmpty && !message.startsWith('Exception:')) {
    return message;
  }

  return fallback ?? 'Something went wrong. Please try again.';
}

String _cleanBackendMessage(String message) {
  return message
      .replaceAll(RegExp('backend', caseSensitive: false), 'care services')
      .replaceAll(RegExp('endpoint', caseSensitive: false), 'action')
      .replaceAll(RegExp('server error', caseSensitive: false), 'service issue')
      .replaceAll(RegExp(r'^ApiException\(\d+\):\s*'), '')
      .trim();
}
