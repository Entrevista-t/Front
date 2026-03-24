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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EntrevistatApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  debugLogDiagnostics: true,
  redirect: (context, state) async {
    final loggedIn = await ApiService.isLoggedIn();
    final path = state.uri.path;
    if (path == '/' ) return loggedIn ? '/home' : '/login';
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
      builder: (_, state) => InterviewScreen(categoryId: state.pathParameters['categoryId']!),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4A1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F1117),
      ),
      routerConfig: _router,
    );
  }
}
