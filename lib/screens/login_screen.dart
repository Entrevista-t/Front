import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

const _pink = Color(0xFFE91E8C);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignIn = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  bool _agreeTerms = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAlreadyLoggedIn();
  }

  Future<void> _checkAlreadyLoggedIn() async {
    if (await ApiService.isLoggedIn() && mounted) context.go('/home');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isSignIn) {
        await ApiService.login(_emailController.text.trim(), _passwordController.text);
      } else {
        await ApiService.register(_nameController.text.trim(), _emailController.text.trim(), _passwordController.text);
      }
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 720) {
            return _buildWebLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  // ── WEB LAYOUT ────────────────────────────────────────────────────────────

  Widget _buildWebLayout() {
    return Center(
      child: Container(
        width: 900,
        height: 580,
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 40, offset: const Offset(0, 10)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Left branding panel
            Expanded(flex: 5, child: _buildBrandingPanel()),
            // Right form panel
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
                child: _buildFormContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE91E8C), Color(0xFFAD1457)],
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(top: -40, right: -40,
            child: Container(width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
          Positioned(bottom: -30, left: -30,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
          Positioned(bottom: 60, right: 20,
            child: Container(width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)))),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 20),
              const Text("Entrevista't",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Prepara la teva pròxima entrevista amb Intel·ligència Artificial.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 36),
              _brandingFeature(Icons.videocam_rounded, 'Anàlisi de vídeo en temps real'),
              const SizedBox(height: 14),
              _brandingFeature(Icons.mic_rounded, 'Transcripció i mètriques de parla'),
              const SizedBox(height: 14),
              _brandingFeature(Icons.auto_awesome_rounded, 'Feedback personalitzat amb IA'),
              const SizedBox(height: 14),
              _brandingFeature(Icons.picture_as_pdf_rounded, 'Informe PDF detallat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _brandingFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
      ],
    );
  }

  // ── MOBILE LAYOUT ─────────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(children: [
                const Icon(Icons.record_voice_over_rounded, size: 56, color: _pink),
                const SizedBox(height: 6),
                Text("Entrevista't", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 32),
            _buildFormContent(),
          ],
        ),
      ),
    );
  }

  // ── SHARED FORM ───────────────────────────────────────────────────────────

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _isSignIn ? 'Sign In' : 'Sign Up',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Text(
          _isSignIn ? "Hi there! Nice to see you again." : "Create your account to get started.",
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        const SizedBox(height: 28),

        if (!_isSignIn) ...[
          _pinkField('Name', 'Your full name', _nameController),
          const SizedBox(height: 18),
        ],

        _pinkField('Email', 'example@email.com', _emailController,
            type: TextInputType.emailAddress),
        const SizedBox(height: 18),
        _pinkField(
          'Password',
          '••••••••••',
          _passwordController,
          obscure: _obscurePassword,
          suffix: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey, size: 20),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 24),

        if (!_isSignIn) ...[
          Row(children: [
            Checkbox(
              value: _agreeTerms,
              onChanged: (v) => setState(() => _agreeTerms = v ?? false),
              activeColor: _pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  children: const [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(text: 'Terms of Service', style: TextStyle(color: _pink, fontWeight: FontWeight.w600)),
                    TextSpan(text: ' and '),
                    TextSpan(text: 'Privacy Policy', style: TextStyle(color: _pink, fontWeight: FontWeight.w600)),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
        ],

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
          const SizedBox(height: 14),
        ],

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 4,
              shadowColor: _pink.withValues(alpha: 0.4),
            ),
            child: _loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(_isSignIn ? 'Sign in' : 'Create Account',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 20),

        // Toggle
        Center(
          child: _isSignIn
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  Text("Don't have an account? ", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  GestureDetector(
                    onTap: () => setState(() { _isSignIn = false; _error = null; }),
                    child: const Text('Sign Up', style: TextStyle(color: _pink, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ])
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Have an Account? ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  GestureDetector(
                    onTap: () => setState(() { _isSignIn = true; _error = null; }),
                    child: const Text('Sign In', style: TextStyle(color: _pink, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ]),
        ),

        if (_isSignIn) ...[
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _socialButton('Twitter', const Color(0xFF1DA1F2), Icons.close),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _socialButton('Facebook', const Color(0xFF1877F2), Icons.facebook),
            ),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Forgot Password?', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            GestureDetector(
              onTap: () => setState(() { _isSignIn = false; _error = null; }),
              child: const Text('Sign Up', style: TextStyle(color: _pink, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _socialButton(String label, Color color, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 11),
        elevation: 0,
      ),
    );
  }

  Widget _pinkField(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscure = false,
    Widget? suffix,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _pink, fontSize: 12, fontWeight: FontWeight.w700),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        suffixIcon: suffix,
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _pink, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
