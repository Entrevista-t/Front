import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ReportSentScreen extends StatefulWidget {
  final String sessionId;
  const ReportSentScreen({super.key, required this.sessionId});

  @override
  State<ReportSentScreen> createState() => _ReportSentScreenState();
}

class _ReportSentScreenState extends State<ReportSentScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  String _email = 'usuari@entrevistat.com';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null && mounted) setState(() { _email = email; });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kS32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kScoreGood.withValues(alpha: 0.1),
                      border: Border.all(color: kScoreGood.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Icon(Icons.mark_email_read_outlined, color: kScoreGood, size: 52),
                  ),
                ),
                const SizedBox(height: kS32),
                Text(
                  'Informe enviat!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kS16),
                Text(
                  "El teu informe detallat amb els resultats\nde l'entrevista s'ha enviat al teu correu.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kS16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: kS16, vertical: kS12),
                  decoration: BoxDecoration(
                    color: kBgSurface,
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    border: Border.all(color: kBorderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.email_outlined, color: kAccent, size: 18),
                      const SizedBox(width: kS8),
                      Flexible(
                        child: Text(_email,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kS48),
                ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded, size: 20),
                  label: const Text("Tornar a l'inici"),
                ),
                const SizedBox(height: kS12),
                TextButton(
                  onPressed: () => context.go('/results/${widget.sessionId}'),
                  child: const Text('Veure resultats complets'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
