import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/core/network/notifications_api.dart';

import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notificationsAsync = ref.watch(_notificationsProvider);

    return Scaffold(
      appBar: RepairAppBar(title: l10n.notifications),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: _ErrorState(
            message: _friendlyError(error),
            onRetry: () => ref.invalidate(_notificationsProvider),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: _EmptyState(message: 'No notifications yet'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_notificationsProvider),
            child: ListView.builder(
              padding: RepairInsets.scroll(context),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationCard(notification: n);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  String _friendlyError(Object error) {
    if (error is ApiException) return error.message;
    return 'Could not load notifications.';
  }
}

final _notificationsProvider =
    FutureProvider<List<_NotificationItem>>((ref) async {
  final api = ref.watch(notificationApiProvider);
  final items = await api.list();
  return items.map((item) => _NotificationItem.fromMap(item)).toList();
});

class _NotificationItem {
  final int id;
  final String phone;
  final String name;
  final String channel;
  final String message;
  final String status;
  final String sentAt;

  const _NotificationItem({
    required this.id,
    required this.phone,
    required this.name,
    required this.channel,
    required this.message,
    required this.status,
    required this.sentAt,
  });

  factory _NotificationItem.fromMap(Map<String, dynamic> map) {
    return _NotificationItem(
      id: map['id'] as int? ?? 0,
      phone: '${map['recipient_phone'] ?? ''}',
      name: '${map['recipient_name'] ?? ''}',
      channel: '${map['channel'] ?? 'sms'}',
      message: '${map['message'] ?? ''}',
      status: '${map['status'] ?? 'pending'}',
      sentAt: '${map['sent_at'] ?? ''}',
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final _NotificationItem notification;

  IconData get _channelIcon {
    switch (notification.channel) {
      case 'sms':
        return Icons.sms_outlined;
      case 'whatsapp':
        return Icons.chat_outlined;
      case 'phone':
        return Icons.phone_outlined;
      case 'email':
        return Icons.email_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _statusColor {
    switch (notification.status) {
      case 'sent':
        return AppTheme.success;
      case 'failed':
        return AppTheme.error;
      case 'pending':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  String get _statusLabel {
    switch (notification.status) {
      case 'sent':
        return 'Sent';
      case 'failed':
        return 'Failed';
      case 'pending':
        return 'Pending';
      case 'simulated':
        return 'Simulated';
      default:
        return notification.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = RepairBreakpoints.isCompactPhone(context);
    final recipientLabel =
        notification.name.isNotEmpty ? notification.name : notification.phone;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceTinted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _channelIcon,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipientLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          notification.channel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(notification.sentAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.notifications_off_outlined,
          size: 56,
          color: AppTheme.primary.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 48,
          color: AppTheme.warning.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 10),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
