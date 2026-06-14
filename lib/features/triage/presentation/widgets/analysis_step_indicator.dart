import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';

class AnalysisStepIndicator extends StatelessWidget {
  const AnalysisStepIndicator({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  final List<String> steps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final done = index < currentIndex;
        final active = index == currentIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: done || active
                    ? AppTheme.primary
                    : AppTheme.primary.withValues(alpha: 0.1),
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : active
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  steps[index],
                  style: TextStyle(
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active || done
                        ? AppTheme.primary
                        : AppTheme.primary.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
