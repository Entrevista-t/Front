import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

const _green    = Color(0xFF00D4A1);
const _bgDark   = Color(0xFF0F1117);
const _cardDark = Color(0xFF1A1E2E);
const _textLight = Color(0xFFE8EAF0);
const _textMuted = Color(0xFF7B8099);

class LoginScreen extends StatefulWidget {
  final bool initialSignUp;
  const LoginScreen({super.key, this.initialSignUp = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _isSignIn = !widget.initialSignUp;
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController();
  bool _loading         = false;
  bool _agreeTerms      = false;
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
      backgroundColor: _bgDark,
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
        height: 600,
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.08),
              blurRadius: 60,
              spreadRadius: 0,
              offset: const Offset(0, 20),
            ),
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
      decoration: BoxDecoration(
        color: _bgDark,
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      padding: const EdgeInsets.all(40),
      child: Stack(
        children: [
          // Decorative glow circles
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _green.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -40, left: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _green.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo_entrevistat.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  const Text("Entrevista't",
                    style: TextStyle(color: _textLight, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                'Domina les teves\nentrevistes amb IA',
                style: TextStyle(color: _textLight, fontSize: 28, fontWeight: FontWeight.bold, height: 1.25),
              ),
              const SizedBox(height: 14),
              const Text(
                'Practica entrevistes simulades i rep feedback\npersonalitzat per millorar cada vegada.',
                style: TextStyle(color: _textMuted, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 36),
              _brandingFeature(Icons.visibility_outlined,  'Eye Tracking en temps real'),
              const SizedBox(height: 14),
              _brandingFeature(Icons.graphic_eq_rounded,   'Anàlisi de veu amb IA'),
              const SizedBox(height: 14),
              _brandingFeature(Icons.auto_awesome_rounded, 'Feedback personalitzat'),
              const SizedBox(height: 14),
              _brandingFeature(Icons.picture_as_pdf_outlined, 'Informe PDF detallat'),
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
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _green, size: 16),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: _textMuted, fontSize: 13)),
      ],
    );
  }

  // ── MOBILE LAYOUT ─────────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_entrevistat.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  const Text("Entrevista't",
                    style: TextStyle(color: _textLight, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 36),
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
          _isSignIn ? 'Iniciar sessió' : 'Crear compte',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textLight),
        ),
        const SizedBox(height: 6),
        Text(
          _isSignIn
              ? 'Benvingut de nou! Entra al teu compte.'
              : 'Registra\'t per començar a practicar.',
          style: const TextStyle(color: _textMuted, fontSize: 13),
        ),
        const SizedBox(height: 28),

        if (!_isSignIn) ...[
          _darkField('Nom', 'El teu nom complet', _nameController),
          const SizedBox(height: 18),
        ],

        _darkField('Correu electrònic', 'exemple@email.com', _emailController,
            type: TextInputType.emailAddress),
        const SizedBox(height: 18),
        _darkField(
          'Contrasenya',
          '••••••••••',
          _passwordController,
          obscure: _obscurePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: _textMuted, size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 24),

        if (!_isSignIn) ...[
          Row(children: [
            Checkbox(
              value: _agreeTerms,
              onChanged: (v) => setState(() => _agreeTerms = v ?? false),
              activeColor: _green,
              checkColor: _bgDark,
              side: const BorderSide(color: _textMuted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            Expanded(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: _textMuted, fontSize: 12),
                  children: [
                    TextSpan(text: 'Accepto els '),
                    TextSpan(text: 'Termes d\'ús',
                        style: TextStyle(color: _green, fontWeight: FontWeight.w600)),
                    TextSpan(text: ' i la '),
                    TextSpan(text: 'Política de privacitat',
                        style: TextStyle(color: _green, fontWeight: FontWeight.w600)),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Text(_error!,
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
          ),
          const SizedBox(height: 14),
        ],

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: _bgDark,
              disabledBackgroundColor: _green.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: _bgDark, strokeWidth: 2.5))
                : Text(
                    _isSignIn ? 'Iniciar sessió' : 'Crear compte',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // Toggle
        Center(
          child: _isSignIn
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text("No tens compte? ",
                      style: TextStyle(color: _textMuted, fontSize: 13)),
                  GestureDetector(
                    onTap: () => setState(() { _isSignIn = false; _error = null; }),
                    child: const Text('Registra\'t',
                        style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ])
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Ja tens compte? ',
                      style: TextStyle(color: _textMuted, fontSize: 13)),
                  GestureDetector(
                    onTap: () => setState(() { _isSignIn = true; _error = null; }),
                    child: const Text('Inicia sessió',
                        style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ]),
        ),

       
      ],
    );
  }

  Widget _darkField(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscure = false,
    Widget? suffix,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: _textLight, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textMuted.withValues(alpha: 0.5), fontSize: 14),
            suffixIcon: suffix,
            filled: true,
            fillColor: _bgDark,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
