import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Reusable empty state: icon + message + optional CTA button.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kS48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.colors.textDisabled, size: 52),
          const SizedBox(height: kS16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonLabel != null && onButtonTap != null) ...[
            const SizedBox(height: kS24),
            SizedBox(
              width: 280,
              child: ElevatedButton(
                onPressed: onButtonTap,
                child: Text(buttonLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
