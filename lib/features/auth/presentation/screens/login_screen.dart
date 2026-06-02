import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/core/utils/async_guard.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/hero_image_stack.dart';
import 'package:repair_ai/shared/widgets/language_toggle.dart';
import 'package:repair_ai/shared/widgets/theme_mode_toggle.dart';

import '../controllers/auth_session_provider.dart';
import '../controllers/login_profile_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_agreedToTerms) {
      showAppErrorSnackBar(context, l10n.mustAgreeTerms);
      return;
    }

    setState(() => _isSubmitting = true);

    final ok = await runWithTimeout(
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        ref.read(profileFormDataProvider.notifier).state = ProfileFormData(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );
        await AuthSessionNotifier.acceptTerms();
        await ref.read(authSessionProvider.notifier).signIn();
        return true;
      },
      timeout: const Duration(seconds: 15),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok != true) {
      showAppErrorSnackBar(context, l10n.timeoutError);
      return;
    }

    context.go('/login/transition');
  }

  void _fillDemo() {
    _nameController.text = 'Jane Wanjiku';
    _emailController.text = 'jane@example.com';
    _passwordController.text = 'demo123';
    setState(() => _agreedToTerms = true);
  }

  void _showTerms() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.termsTitle,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(l10n.termsBody),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _agreedToTerms = true);
                  Navigator.pop(ctx);
                },
                child: Text(l10n.continueButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    const bgImage = 'assets/illustrations/pregnant_mother.jpg';

    final horizontalPadding = shortest < 380 ? 14.0 : 24.0;
    final formCardPadding = shortest < 380 ? 16.0 : 20.0;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: HeroImageStack(
                imageAsset: bgImage,
                showForegroundCard: false,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: shortest < 360 || textScale > 1.2
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        ThemeModeToggle(),
                        SizedBox(height: 6),
                        LanguageToggle(),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ThemeModeToggle(),
                        SizedBox(width: 6),
                        LanguageToggle(),
                      ],
                    ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 22,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - 44),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.login,
                        style: TextStyle(
                          fontSize: (shortest < 380 ? 34 : 40),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.loginSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: shortest < 380 ? 14 : 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.95),
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(formCardPadding),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.name,
                                    prefixIcon:
                                        const Icon(Icons.person_outline),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return l10n.nameRequired;
                                    if (value.length < 2) {
                                      return l10n.nameTooShort;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: l10n.email,
                                    prefixIcon:
                                        const Icon(Icons.email_outlined),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) {
                                      return l10n.emailRequired;
                                    }
                                    final emailRegex = RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                    );
                                    if (!emailRegex.hasMatch(value)) {
                                      return l10n.emailInvalid;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: l10n.password,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  validator: (v) {
                                    final value = v ?? '';
                                    if (value.isEmpty) {
                                      return l10n.passwordRequired;
                                    }
                                    if (value.length < 6) {
                                      return l10n.passwordMinLength;
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _onSubmit(),
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  value: _agreedToTerms,
                                  onChanged: (v) =>
                                      setState(() => _agreedToTerms = v ?? false),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  title: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        l10n.agreeTermsPrefix,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      GestureDetector(
                                        onTap: _showTerms,
                                        child: Text(
                                          l10n.agreeTermsLink,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                OutlinedButton(
                                  onPressed: _isSubmitting ? null : _fillDemo,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    side: BorderSide(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(l10n.tryDemo),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSubmitting ? null : _onSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            l10n.loginButton,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          l10n.privacyNotice,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.forgotPasswordMock)),
                          );
                        },
                        child: Text(
                          l10n.forgotPassword,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
