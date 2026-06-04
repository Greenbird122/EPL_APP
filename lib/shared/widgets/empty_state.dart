import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.imageAsset,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 168,
                  height: 112,
                  child: Image.asset(
                    imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      icon,
                      size: 72,
                      color: AppTheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: 72,
                color: AppTheme.primary.withValues(alpha: 0.5),
              ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              RepairPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: Icons.add_circle_outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
