import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Circular score indicator used in list tiles and result cards.
class ScoreBadge extends StatelessWidget {
  final double score;
  final double size;

  const ScoreBadge({super.key, required this.score, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: size * 0.1,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
          Text(
            '${score.toInt()}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.28,
            ),
          ),
        ],
      ),
    );
  }
}
