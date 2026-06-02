import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';

class DemoDisclaimerBanner extends StatelessWidget {
  const DemoDisclaimerBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: isDark ? 0.22 : 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: isDark ? 0.6 : 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: compact ? 18 : 20,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Demo assessment — not a medical diagnosis. Seek care if you feel unwell or worried.',
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                height: 1.35,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
