import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/themes.dart';

void installAppErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      // Keep the red screen in debug mode for faster diagnosis.
      return;
    }
    // In release mode, show a branded error screen.
    ErrorWidget.builder = (details) {
      return Material(
        child: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              color: isDark ? const Color(0xFF1A1625) : const Color(0xFFF5F3FF),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Something went wrong',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please restart the app',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () => exit(0),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Restart'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    };
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught: $error\n$stack');
    }
    return true;
  };
}

void showAppErrorSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
