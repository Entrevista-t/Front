import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _green = Color(0xFF00D4A1);
const _bgDark = Color(0xFF0F1117);
const _cardDark = Color(0xFF1A1E2E);
const _textLight = Color(0xFFE8EAF0);
const _textMuted = Color(0xFF7B8099);

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
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _cardDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textLight),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        title: const Text('Editar perfil',
            style: TextStyle(color: _textLight, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: _green.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, color: _green, size: 56),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                      border: Border.all(color: _bgDark, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: _bgDark, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            _buildField('Nom', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildField('Correu electrònic', _emailController, Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _saved ? const Color(0xFF2E7D32) : _green,
                  foregroundColor: _bgDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Color(0xFF0F1117), strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_saved ? Icons.check_rounded : Icons.save_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(_saved ? 'Guardat!' : 'Guardar canvis',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/profile'),
              child: const Text('Cancel·lar', style: TextStyle(color: _textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: _textLight),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _textMuted, size: 20),
            filled: true,
            fillColor: _cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
