import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _green = Color(0xFF00D4A1);
const _bgDark = Color(0xFF0F1117);
const _cardDark = Color(0xFF1A1E2E);
const _textLight = Color(0xFFE8EAF0);
const _textMuted = Color(0xFF7B8099);

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
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _green.withValues(alpha: 0.12),
                      border: Border.all(color: _green.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Icon(Icons.mark_email_read_outlined, color: _green, size: 52),
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Informe enviat!',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: _textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'El teu informe detallat amb els resultats\nde l\'entrevista s\'ha enviat al teu correu.',
                  style: const TextStyle(color: _textMuted, fontSize: 15, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _green.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.email_outlined, color: _green, size: 18),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(_email,
                            style: const TextStyle(
                                color: _textLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 52),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home_rounded, size: 20),
                    label: const Text('Tornar a l\'inici',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: _bgDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/results/${widget.sessionId}'),
                  child: const Text('Veure resultats complets',
                      style: TextStyle(color: _textMuted, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
