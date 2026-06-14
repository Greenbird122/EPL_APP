import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/auth/presentation/controllers/login_profile_providers.dart';
import 'package:repair_ai/features/profile/presentation/controllers/payments_provider.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsStateProvider);

    return Scaffold(
      appBar: const RepairAppBar(title: 'Payments & Balance'),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                'Could not load card details: $error',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(paymentsStateProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (state) {
          if (!state.hasPid) {
            return const _NoPidWidget();
          }
          if (state.card == null) {
            return const _NoCardWidget();
          }

          return SingleChildScrollView(
            padding: RepairInsets.scroll(context),
            child: ResponsivePageShell(
              maxWidth: RepairSizing.formMaxWidth(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // GORGEOUS CREDIT CARD COMPONENT
                  _AnimatedPaymentCard(card: state.card!),
                  const SizedBox(height: 24),

                  // TOP UP & QUICK ACTIONS
                  const _ActionButtonsSection(),
                  const SizedBox(height: 28),

                  // TRANSACTION STATEMENT HISTORY
                  const _StatementSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoPidWidget extends StatelessWidget {
  const _NoPidWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person_outlined,
                  size: 64,
                  color: AppTheme.warning,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Patient ID Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'You need an active REPAIR-AI Patient Digital ID before you can manage payments and top ups.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                RepairPrimaryButton(
                  label: 'Go to Home Screen',
                  icon: Icons.home_outlined,
                  onPressed: () => context.go('/'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoCardWidget extends ConsumerWidget {
  const _NoCardWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.credit_card_off_outlined,
              size: 58,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Payment Card Available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'A payment card will be provisioned automatically when your Patient ID registration completes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(paymentsStateProvider),
              child: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedPaymentCard extends ConsumerStatefulWidget {
  const _AnimatedPaymentCard({required this.card});
  final PatientCard card;

  @override
  ConsumerState<_AnimatedPaymentCard> createState() =>
      __AnimatedPaymentCardState();
}

class __AnimatedPaymentCardState extends ConsumerState<_AnimatedPaymentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientName = ref.watch(profileNameProvider) ?? 'Patient Card';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final val = _anim.value;
        final rotation = math.sin((1 - val) * math.pi * 0.5) * 0.12;
        final scale = 0.95 + 0.05 * val;
        final opacity = val;

        return Opacity(
          opacity: opacity,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..scaleByDouble(scale, scale, 1.0, 1.0)
              ..rotateY(rotation),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF0F2027),
              Color(0xFF203A43),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.25),
              offset: const Offset(0, 10),
              blurRadius: 20,
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Bar: Brand, Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.cyanAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'REPAIR-AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                _StatusBadge(status: widget.card.status),
              ],
            ),

            // Middle: Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVAILABLE BALANCE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'KES ${widget.card.balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),

            // Bottom: Card Holder Name & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    patientName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Text(
                  'ID: #${widget.card.id}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'active':
        bg = Colors.greenAccent.withValues(alpha: 0.15);
        fg = Colors.greenAccent;
        break;
      case 'pending':
        bg = Colors.amberAccent.withValues(alpha: 0.15);
        fg = Colors.amberAccent;
        break;
      default:
        bg = Colors.redAccent.withValues(alpha: 0.15);
        fg = Colors.redAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ActionButtonsSection extends StatelessWidget {
  const _ActionButtonsSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionBtn(
            icon: Icons.add_card_outlined,
            label: 'Top Up Balance',
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryLight],
            ),
            onTap: () => _showTopUpDialog(context),
          ),
        ),
      ],
    );
  }

  void _showTopUpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TopUpBottomSheet(),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: isDark ? 0.3 : 0.15),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopUpBottomSheet extends ConsumerStatefulWidget {
  const _TopUpBottomSheet();

  @override
  ConsumerState<_TopUpBottomSheet> createState() => _TopUpBottomSheetState();
}

class _TopUpBottomSheetState extends ConsumerState<_TopUpBottomSheet> {
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(topUpControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Up Card via M-Pesa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 20),
            const SizedBox(height: 8),

            // Amount field
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (KES)',
                hintText: 'e.g. 500',
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter top up amount';
                }
                final numVal = double.tryParse(val);
                if (numVal == null || numVal <= 0) {
                  return 'Please enter a valid positive amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Phone field
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Phone Number',
                hintText: 'e.g. 0712345678',
                prefixIcon: Icon(Icons.phone_android_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                if (val.length < 9) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Submit Button
            RepairPrimaryButton(
              label: 'Trigger STK Push',
              icon: Icons.send_rounded,
              isLoading: state.isLoading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final amount = double.parse(_amountCtrl.text.trim());
                final phone = _phoneCtrl.text.trim();
                final mockRef = 'MPESA_${DateTime.now().millisecondsSinceEpoch}';
                // Capture messenger and navigator before the async gap.
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);

                await ref.read(topUpControllerProvider.notifier).topUp(
                      amount: amount,
                      reference: mockRef,
                    );

                if (!mounted) return;
                final nextState = ref.read(topUpControllerProvider);
                if (!nextState.hasError) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'STK Push sent to $phone. Account balance updated successfully.',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  nav.pop();
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Top up failed: ${nextState.error}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementSection extends ConsumerWidget {
  const _StatementSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transAsync = ref.watch(transactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        transAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Could not load transaction statement: $error',
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceTinted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No transaction history found',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: list.map((tx) => _TransactionTile(tx: tx)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final isTopup = tx.type.toLowerCase() == 'topup';
    final sign = isTopup ? '+' : '-';
    final color = isTopup ? AppTheme.success : AppTheme.error;
    final icon = isTopup ? Icons.add_circle_outline : Icons.remove_circle_outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          tx.description.isNotEmpty ? tx.description : (isTopup ? 'Wallet Top Up' : 'Payment'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              'Ref: ${tx.reference}',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 2),
            Text(
              tx.createdAt.toLocal().toString().split('.').first,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
        trailing: Text(
          '$sign KES ${tx.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
