import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A section heading row with an optional trailing widget.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );

    if (trailing == null) return text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        text,
        trailing!,
      ],
    );
  }
}

/// A small uppercase label (e.g. "Últim mes", "Pla gratuït").
class AppLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const AppLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color ?? kTextSecondary,
      ),
    );
  }
}

/// A small chip / badge (e.g. "Pla gratuït", category tags).
class AppChip extends StatelessWidget {
  final String label;
  final Color? color;

  const AppChip(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: c,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
