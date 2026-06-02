import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/quote_loading_screen.dart';

/// Post-login welcome with motherly quotes (min 5s) then fade to home.
class LoginTransitionScreen extends StatefulWidget {
  const LoginTransitionScreen({super.key});

  @override
  State<LoginTransitionScreen> createState() => _LoginTransitionScreenState();
}

class _LoginTransitionScreenState extends State<LoginTransitionScreen>
    with SingleTickerProviderStateMixin {
  bool _showHome = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onQuotesFinished() {
    _fadeController.forward().then((_) {
      if (mounted) {
        context.go('/');
      }
    });
    setState(() => _showHome = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_showHome) {
      return QuoteLoadingScreen(
        subtitle: l10n.signingIn,
        onFinished: _onQuotesFinished,
        runTask: () async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, size: 48, color: Color(0xFF6B4EFF)),
              const SizedBox(height: 16),
              Text(
                l10n.welcomeHome,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
