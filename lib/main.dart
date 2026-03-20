import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/interview_screen.dart';
import 'screens/results_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EntrevistatApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/interview/:categoryId',
      builder: (_, state) => InterviewScreen(categoryId: state.pathParameters['categoryId']!),
    ),
    GoRoute(
      path: '/results/:sessionId',
      builder: (_, state) => ResultsScreen(sessionId: state.pathParameters['sessionId']!),
    ),
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
          seedColor: const Color(0xFFE91E8C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      routerConfig: _router,
    );
  }
}
