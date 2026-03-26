import 'package:flutter/material.dart';
import '../models/interview_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'score_badge.dart';

/// A reusable list tile for an [InterviewSession].
/// Used on both HomeScreen and ProfileScreen.
class SessionTile extends StatelessWidget {
  final InterviewSession session;
  final VoidCallback? onTap;

  const SessionTile({super.key, required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: kS8),
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kBorderSubtle),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: kS16, vertical: kS4,
        ),
        leading: ScoreBadge(score: session.overallScore),
        title: Text(
          session.categoryName,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          session.formattedDate,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right, color: kTextSecondary, size: 20),
        onTap: onTap,
      ),
    );
  }
}
