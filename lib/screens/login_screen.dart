import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart' show kDevBypassLogin;
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart' show kFontSerif, kFontSans;
import '../widgets/dot_grid_background.dart';

class LoginScreen extends StatefulWidget {
  final bool initialSignUp;
  const LoginScreen({super.key, this.initialSignUp = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late bool _isSignIn = !widget.initialSignUp;
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController();
  bool _loading         = false;
  bool _agreeTerms      = false;
  bool _obscurePassword = true;
  String? _error;

  // Entrance animation
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _checkAlreadyLoggedIn();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    ));

    // Delay slightly for polish
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  Future<void> _checkAlreadyLoggedIn() async {
    if (kDevBypassLogin) return;
    if (await ApiService.isLoggedIn() && mounted) context.go('/home');
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (kDevBypassLogin) {
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

  void _toggleMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgBase,
      body: DotGridBackground(
        showGlows: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: kPagePadding, vertical: kS32),
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Logo + Title ────────────────────────────
                      _buildHeader(),
                      const SizedBox(height: kS32),

                      // ── Card ────────────────────────────────────
                      _buildCard(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "Entrevista't",
          style: TextStyle(
            fontFamily: kFontSerif,
            fontSize: 32,
            fontWeight: FontWeight.w500,
            color: context.colors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GLASS CARD
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCard(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusGlass),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kBlurGlass, sigmaY: kBlurGlass),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.glassBg,
              borderRadius: BorderRadius.circular(kRadiusGlass),
              border: Border.all(color: context.colors.glassBorder),
              boxShadow: kShadowGlass,
            ),
            child: Padding(
              padding: const EdgeInsets.all(kS24),
              child: AnimatedSize(
                duration: kDurationNormal,
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _buildFormContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FORM CONTENT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFormContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title + subtitle
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey(_isSignIn),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSignIn ? 'Iniciar sessió' : 'Crear compte',
                style: TextStyle(
                  fontFamily: kFontSerif,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: kS6),
              Text(
                _isSignIn
                    ? 'Benvingut de nou! Entra al teu compte.'
                    : "Registra't per començar a practicar.",
                style: TextStyle(
                  fontFamily: kFontSans,
                  fontSize: 14,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: kS24),

        // ── Name field (sign-up only) ──────────────────────
        if (!_isSignIn) ...[
          _buildField(
            label: 'Nom',
            hint: 'El teu nom complet',
            controller: _nameController,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: kS16),
        ],

        // ── Email ──────────────────────────────────────────
        _buildField(
          label: 'Correu electrònic',
          hint: 'exemple@email.com',
          controller: _emailController,
          icon: Icons.email_outlined,
          type: TextInputType.emailAddress,
        ),
        const SizedBox(height: kS16),

        // ── Password ───────────────────────────────────────
        _buildField(
          label: 'Contrasenya',
          hint: '••••••••••',
          controller: _passwordController,
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: context.colors.textTertiary,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        // ── Checkbox row ───────────────────────────────────
        const SizedBox(height: kS16),
        if (_isSignIn)
          _buildForgotPassword()
        else
          _buildTermsCheckbox(),

        // ── Error ──────────────────────────────────────────
        if (_error != null) ...[
          const SizedBox(height: kS16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: kS16, vertical: kS12),
            decoration: BoxDecoration(
              color: kErrorRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(kRadiusMd),
              border: Border.all(color: kErrorRed.withValues(alpha: 0.3)),
            ),
            child: Text(
              _error!,
              style: TextStyle(
                fontFamily: kFontSans,
                fontSize: 13,
                color: kErrorRed,
              ),
            ),
          ),
        ],

        // ── Submit button ──────────────────────────────────
        const SizedBox(height: kS24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(_isSignIn ? 'Iniciar sessió' : 'Crear compte'),
          ),
        ),

        // ── "or" divider ───────────────────────────────────
        // TODO: Uncomment when GitHub/Google OAuth is implemented
        // const SizedBox(height: kS20),
        // _buildOrDivider(),
        // const SizedBox(height: kS20),

        // ── Social buttons ─────────────────────────────────
        // TODO: Uncomment when GitHub/Google OAuth is implemented
        // Row(
        //   children: [
        //     Expanded(
        //       child: _SocialButton(
        //         icon: Icons.code_rounded,
        //         label: 'GitHub',
        //         onTap: () {},
        //       ),
        //     ),
        //     const SizedBox(width: kS12),
        //     Expanded(
        //       child: _SocialButton(
        //         icon: Icons.g_mobiledata_rounded,
        //         label: 'Google',
        //         onTap: () {},
        //       ),
        //     ),
        //   ],
        // ),

        // ── Toggle footer ──────────────────────────────────
        const SizedBox(height: kS24),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isSignIn ? 'No tens compte? ' : 'Ja tens compte? ',
                style: TextStyle(
                  fontFamily: kFontSans,
                  fontSize: 13,
                  color: context.colors.textTertiary,
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _toggleMode,
                  child: Text(
                    _isSignIn ? "Registra't" : 'Inicia sessió',
                    style: TextStyle(
                      fontFamily: kFontSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INPUT FIELD WITH ICON
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: kFontSans,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: kS6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18,
                color: context.colors.textTertiary),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 0),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FORGOT PASSWORD (sign-in)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {},
          child: Text(
            'Has oblidat la contrasenya?',
            style: TextStyle(
              fontFamily: kFontSans,
              fontSize: 13,
              color: context.colors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TERMS CHECKBOX (sign-up)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _agreeTerms,
            onChanged: (v) => setState(() => _agreeTerms = v ?? false),
          ),
        ),
        const SizedBox(width: kS8),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreeTerms = !_agreeTerms),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: kFontSans,
                  fontSize: 13,
                  color: context.colors.textTertiary,
                ),
                children: [
                  const TextSpan(text: 'Accepto els '),
                  TextSpan(
                    text: "Termes d'ús",
                    style: const TextStyle(
                        color: kAccent, fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' i la '),
                  TextSpan(
                    text: 'Política de privacitat',
                    style: const TextStyle(
                        color: kAccent, fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // "OR" DIVIDER
  // ══════════════════════════════════════════════════════════════════════════

  // TODO: Uncomment when GitHub/Google OAuth is implemented
  // Widget _buildOrDivider() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: Divider(
  //             color: context.colors.borderSubtle, thickness: 0.5)),
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: kS12),
  //         child: Text(
  //           'o',
  //           style: TextStyle(
  //             fontFamily: kFontSans,
  //             fontSize: 12,
  //             fontWeight: FontWeight.w500,
  //             color: context.colors.textDisabled,
  //             letterSpacing: 1.5,
  //           ),
  //         ),
  //       ),
  //       Expanded(
  //         child: Divider(
  //             color: context.colors.borderSubtle, thickness: 0.5)),
  //     ],
  //   );
  // }
}

// ══════════════════════════════════════════════════════════════════════════════
// Social login button
// TODO: Uncomment when GitHub/Google OAuth is implemented
// ══════════════════════════════════════════════════════════════════════════════

// class _SocialButton extends StatefulWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;
//
//   const _SocialButton({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });
//
//   @override
//   State<_SocialButton> createState() => _SocialButtonState();
// }
//
// class _SocialButtonState extends State<_SocialButton> {
//   bool _hovering = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       onEnter: (_) => setState(() => _hovering = true),
//       onExit: (_) => setState(() => _hovering = false),
//       child: GestureDetector(
//         onTap: widget.onTap,
//         child: AnimatedContainer(
//           duration: kDurationFast,
//           curve: kCurveHover,
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           decoration: BoxDecoration(
//             color: _hovering
//                 ? context.colors.bgSurface
//                 : Colors.transparent,
//             borderRadius: BorderRadius.circular(kRadiusMd),
//             border: Border.all(
//               color: _hovering
//                   ? context.colors.borderStrong
//                   : context.colors.borderSubtle,
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(widget.icon,
//                   size: 20, color: context.colors.textSecondary),
//               const SizedBox(width: 8),
//               Text(
//                 widget.label,
//                 style: TextStyle(
//                   fontFamily: kFontSans,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: context.colors.textSecondary,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
