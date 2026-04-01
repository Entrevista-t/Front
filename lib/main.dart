import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/interview_screen.dart';
import 'screens/results_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/report_sent_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EntrevistatApp());
}

// Set to true to skip login (no API needed for UI review)
const bool kDevBypassLogin = true;

/// Global theme notifier — accessible via [EntrevistatApp.themeNotifier].
final _themeNotifier = ThemeNotifier();

CustomTransitionPage<void> _fadePage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

final _router = GoRouter(
  initialLocation: '/landing',
  debugLogDiagnostics: true,
  redirect: (context, state) async {
    final path = state.uri.path;
    if (kDevBypassLogin) {
      // When bypassing auth, redirect bare root to landing
      if (path == '/') return '/landing';
      return null;
    }
    final loggedIn = await ApiService.isLoggedIn();
    if (path == '/') return loggedIn ? '/home' : '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/landing', pageBuilder: (_, __) => _fadePage(const LandingScreen())),
    GoRoute(path: '/faq', pageBuilder: (_, __) => _fadePage(const FaqScreen())),
    GoRoute(path: '/privacy', pageBuilder: (_, __) => _fadePage(const PrivacyPolicyScreen())),
    GoRoute(
      path: '/login',
      pageBuilder: (_, state) {
        final mode = state.uri.queryParameters['mode'];
        return _fadePage(LoginScreen(initialSignUp: mode == 'register'));
      },
    ),
    GoRoute(path: '/home', pageBuilder: (_, __) => _fadePage(const HomeScreen())),
    GoRoute(
      path: '/interview/:categoryId',
      pageBuilder: (_, state) => _fadePage(InterviewScreen(
        categoryId: state.pathParameters['categoryId']!,
        categoryName: state.uri.queryParameters['name'],
      )),
    ),
    GoRoute(
      path: '/results/:sessionId',
      pageBuilder: (_, state) => _fadePage(ResultsScreen(sessionId: state.pathParameters['sessionId']!)),
    ),
    GoRoute(
      path: '/report-sent/:sessionId',
      pageBuilder: (_, state) => _fadePage(ReportSentScreen(sessionId: state.pathParameters['sessionId']!)),
    ),
    GoRoute(path: '/profile', pageBuilder: (_, __) => _fadePage(const ProfileScreen())),
    GoRoute(path: '/profile/edit', pageBuilder: (_, __) => _fadePage(const EditProfileScreen())),
  ],
);

/// Smooth scrolling on all platforms (no clamping edge effect).
class _SmoothScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class EntrevistatApp extends StatelessWidget {
  const EntrevistatApp({super.key});

  /// Provides access to the global theme notifier.
  static ThemeNotifier get themeNotifier => _themeNotifier;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeNotifier,
      builder: (context, _) {
        return MaterialApp.router(
          title: "Entrevista't",
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _themeNotifier.mode,
          scrollBehavior: _SmoothScrollBehavior(),
          routerConfig: _router,
          builder: (context, child) {
            return Stack(
              children: [
                child!,
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _ThemeToggleBubble(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Floating bubble for toggling between light and dark mode.
class _ThemeToggleBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _themeNotifier.toggle(),
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
