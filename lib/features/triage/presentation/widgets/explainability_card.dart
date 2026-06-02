import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';

class ExplainabilityCard extends StatefulWidget {
  const ExplainabilityCard({
    super.key,
    required this.reasons,
    this.title = 'Why this result?',
  });

  final List<String> reasons;
  final String title;

  @override
  State<ExplainabilityCard> createState() => _ExplainabilityCardState();
}

class _ExplainabilityCardState extends State<ExplainabilityCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        children: widget.reasons
            .map(
              (r) => ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle_outline, size: 20),
                title: Text(r, style: const TextStyle(height: 1.4)),
              ),
            )
            .toList(),
      ),
    );
  }
}
