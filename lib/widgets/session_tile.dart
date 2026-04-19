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

  IconData get _statusIcon {
    switch (session.status) {
      case 'completat': return Icons.check_circle_outline_rounded;
      case 'processant': return Icons.hourglass_top_rounded;
      case 'error': return Icons.error_outline_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  Color _statusColor(BuildContext context) {
    switch (session.status) {
      case 'completat': return kScoreGood;
      case 'processant': return kAccent;
      case 'error': return kScoreLow;
      default: return context.colors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = session.overallScore;
    return Container(
      margin: const EdgeInsets.only(bottom: kS8),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: kS16, vertical: kS4,
        ),
        leading: score != null
            ? ScoreBadge(score: score)
            : Icon(_statusIcon, color: _statusColor(context), size: 28),
        title: Text(
          'Entrevista ${session.formattedDate}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          session.statusLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _statusColor(context),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: context.colors.textSecondary, size: 20),
        onTap: onTap,
      ),
    );
  }
}
