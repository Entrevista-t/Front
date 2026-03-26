import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart' show kDevBypassLogin;
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

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
    if (kDevBypassLogin) return;
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
    if (kDevBypassLogin) {
      // Skip API call — inject a fake "John Doe" session
      await ApiService.devBypassLogin(
        token: 'dev-bypass-token',
        name: 'John Doe',
        email: 'john@example.com',
      );
      if (mounted) context.go('/home');
      return;
    }
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 720) {
            return _buildWebLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  // ── WEB LAYOUT ────────────────────────────────────────────────────────────

  Widget _buildWebLayout(BuildContext context) {
    return Center(
      child: Container(
        width: 900,
        height: 600,
        margin: const EdgeInsets.all(kS32),
        decoration: BoxDecoration(
          color: kBgSurface,
          borderRadius: BorderRadius.circular(kRadiusLg),
          border: Border.all(color: kBorderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(flex: 5, child: _buildBrandingPanel(context)),
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
                child: _buildFormContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBgBase,
        border: Border(right: BorderSide(color: kBorderSubtle)),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo_entrevistat.png',
                width: 36, height: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: kS12),
              Text("Entrevista't",
                style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: kS32),
          Text(
            'Domina les teves\nentrevistes amb IA',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: kS12),
          Text(
            'Practica entrevistes simulades i rep feedback\npersonalitzat per millorar cada vegada.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
          ),
          const SizedBox(height: kS32),
          _brandingFeature(context, Icons.visibility_outlined, 'Eye Tracking en temps real'),
          const SizedBox(height: kS12),
          _brandingFeature(context, Icons.graphic_eq_rounded, 'Anàlisi de veu amb IA'),
          const SizedBox(height: kS12),
          _brandingFeature(context, Icons.auto_awesome_rounded, 'Feedback personalitzat'),
          const SizedBox(height: kS12),
          _brandingFeature(context, Icons.picture_as_pdf_outlined, 'Informe PDF detallat'),
        ],
      ),
    );
  }

  Widget _brandingFeature(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(kS8),
          decoration: BoxDecoration(
            color: kAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(kRadiusSm),
          ),
          child: Icon(icon, color: kAccent, size: 16),
        ),
        const SizedBox(width: kS12),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  // ── MOBILE LAYOUT ─────────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: kS24, vertical: kS24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: kS16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_entrevistat.png',
                    width: 30, height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: kS8),
                  Text("Entrevista't",
                    style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
            const SizedBox(height: kS32),
            _buildFormContent(context),
          ],
        ),
      ),
    );
  }

  // ── SHARED FORM ───────────────────────────────────────────────────────────

  Widget _buildFormContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _isSignIn ? 'Iniciar sessió' : 'Crear compte',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: kS8),
        Text(
          _isSignIn
              ? 'Benvingut de nou! Entra al teu compte.'
              : "Registra't per començar a practicar.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: kS24),

        if (!_isSignIn) ...[
          _formField(context, 'Nom', 'El teu nom complet', _nameController),
          const SizedBox(height: kS16),
        ],

        _formField(context, 'Correu electrònic', 'exemple@email.com', _emailController,
            type: TextInputType.emailAddress),
        const SizedBox(height: kS16),
        _formField(
          context,
          'Contrasenya',
          '••••••••••',
          _passwordController,
          obscure: _obscurePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: kS24),

        if (!_isSignIn) ...[
          Row(children: [
            Checkbox(
              value: _agreeTerms,
              onChanged: (v) => setState(() => _agreeTerms = v ?? false),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    const TextSpan(text: 'Accepto els '),
                    TextSpan(
                      text: "Termes d'ús",
                      style: const TextStyle(color: kAccent, fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' i la '),
                    TextSpan(
                      text: 'Política de privacitat',
                      style: const TextStyle(color: kAccent, fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: kS16),
        ],

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: kS16, vertical: kS12),
            decoration: BoxDecoration(
              color: kErrorRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(kRadiusMd),
              border: Border.all(color: kErrorRed.withValues(alpha: 0.3)),
            ),
            child: Text(_error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: kErrorRed)),
          ),
          const SizedBox(height: kS16),
        ],

        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(_isSignIn ? 'Iniciar sessió' : 'Crear compte'),
        ),
        const SizedBox(height: kS16),

        Center(
          child: _isSignIn
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  Text("No tens compte? ",
                      style: Theme.of(context).textTheme.bodySmall),
                  GestureDetector(
                    onTap: () => setState(() { _isSignIn = false; _error = null; }),
                    child: Text("Registra't",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: kAccent, fontWeight: FontWeight.w600,
                        )),
                  ),
                ])
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Ja tens compte? ',
                      style: Theme.of(context).textTheme.bodySmall),
                  GestureDetector(
                    onTap: () => setState(() { _isSignIn = true; _error = null; }),
                    child: Text('Inicia sessió',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: kAccent, fontWeight: FontWeight.w600,
                        )),
                  ),
                ]),
        ),
      ],
    );
  }

  Widget _formField(
    BuildContext context,
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
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: kTextSecondary, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: kS8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
