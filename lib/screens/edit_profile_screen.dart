import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _saved = false;
  bool _hoverSave = false;
  bool _hoverCamera = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('user_name') ?? 'Usuari';
    _emailController.text = prefs.getString('user_email') ?? 'usuari@entrevistat.com';
    setState(() {});
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() { _loading = true; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('user_email', _emailController.text.trim());
    setState(() { _loading = false; _saved = true; });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) context.go('/profile');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        title: const Text('Editar perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kS24),
        child: Column(
          children: [
            const SizedBox(height: kS12),
            Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: kAccent.withValues(alpha: 0.08),
                  child: const Icon(Icons.person, color: kAccent, size: 56),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoverCamera = true),
                    onExit: (_) => setState(() => _hoverCamera = false),
                    cursor: SystemMouseCursors.click,
                    child: AnimatedScale(
                      scale: _hoverCamera ? 1.15 : 1.0,
                      duration: kDurationFast,
                      curve: kCurveHover,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: kAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.bgBase, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kS32),
            _buildField(context, 'Nom', _nameController, Icons.person_outline),
            const SizedBox(height: kS16),
            _buildField(context, 'Correu electrònic', _emailController, Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: kS32),
            MouseRegion(
              onEnter: (_) => setState(() => _hoverSave = true),
              onExit: (_) => setState(() => _hoverSave = false),
              child: AnimatedContainer(
                duration: kDurationFast,
                curve: kCurveHover,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kRadiusMd),
                  boxShadow: _hoverSave ? kShadowGlow : [],
                ),
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(_saved ? Icons.check_rounded : Icons.save_outlined, size: 18),
                  label: Text(_saved ? 'Guardat!' : 'Guardar canvis'),
                  style: _saved
                      ? ElevatedButton.styleFrom(backgroundColor: kScoreGood)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: kS12),
            TextButton(
              onPressed: () => context.go('/profile'),
              child: const Text('Cancel·lar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.colors.textSecondary, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: kS8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
          ),
        ),
      ],
    );
  }
}
