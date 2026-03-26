import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/interview_screen.dart';
import 'screens/results_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/report_sent_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EntrevistatApp());
}

// Set to true to skip login (no API needed for UI review)
const bool kDevBypassLogin = true;

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
    GoRoute(path: '/landing', builder: (_, __) => const LandingScreen()),
    GoRoute(
      path: '/login',
      builder: (_, state) {
        final mode = state.uri.queryParameters['mode'];
        return LoginScreen(initialSignUp: mode == 'register');
      },
    ),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/interview/:categoryId',
      builder: (_, state) => InterviewScreen(
        categoryId: state.pathParameters['categoryId']!,
        categoryName: state.uri.queryParameters['name'],
      ),
    ),
    GoRoute(
      path: '/results/:sessionId',
      builder: (_, state) => ResultsScreen(sessionId: state.pathParameters['sessionId']!),
    ),
    GoRoute(
      path: '/report-sent/:sessionId',
      builder: (_, state) => ReportSentScreen(sessionId: state.pathParameters['sessionId']!),
    ),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
  ],
);

class EntrevistatApp extends StatelessWidget {
  const EntrevistatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Entrevista't",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
