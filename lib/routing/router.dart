// screens/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgriduk/providers/auth_provider.dart';
import 'package:roofgriduk/models/user_model.dart';
import 'package:roofgriduk/screens/login_screen.dart';
import 'package:roofgriduk/screens/auth/forgot_password_screen.dart';
import 'package:roofgriduk/screens/auth/register_screen.dart';
import 'package:roofgriduk/screens/calculator/calculator_screen.dart';
import 'package:roofgriduk/screens/home_screen.dart';
import 'package:roofgriduk/screens/splash/splash_screen.dart';
import 'package:roofgriduk/screens/admin/admin_dashboard_screen.dart';
import 'package:roofgriduk/screens/support/faq_screen.dart';
import 'package:roofgriduk/screens/support/legal_screen.dart';
import 'package:roofgriduk/screens/support/contact_screen.dart';
import 'package:roofgriduk/screens/subscription_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Placeholder screens (to be replaced with actual implementations)
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Results Screen')));
}

class TilesScreen extends StatelessWidget {
  const TilesScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Tiles Screen')));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final userAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final isLoggedIn = authState.isAuthenticated;
      final isGoingToAuth = state.uri.path.startsWith('/auth');

      // Wait for user data if authenticated
      if (isLoggedIn && authState.userId != null) {
        final user = userAsync.value; // Use value since redirect is sync
        if (user == null) {
          // User data not loaded yet; allow navigation to proceed or redirect to login
          if (!isGoingToAuth) return '/auth/login';
        } else if (state.uri.path == '/admin' && user.role != UserRole.admin) {
          await FirebaseAnalytics.instance.logEvent(
            name: 'access_denied',
            parameters: {'route': '/admin', 'role': user.role.toString()},
          );
          return '/home';
        }
      }

      if (!isLoggedIn && !isGoingToAuth && state.uri.path != '/splash') {
        return '/auth/login';
      }

      if (isLoggedIn && isGoingToAuth) {
        return '/home';
      }

      await FirebaseAnalytics.instance.logScreenView(
        screenName: state.uri.path,
      );

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/calculator',
        builder: (context, state) => const CalculatorScreen(),
        // Add sub-routes if needed
        // routes: [
        //   GoRoute(
        //     path: 'vertical',
        //     builder: (context, state) => const VerticalCalculatorScreen(),
        //   ),
        //   GoRoute(
        //     path: 'horizontal',
        //     builder: (context, state) => const HorizontalCalculatorScreen(),
        //   ),
        // ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/support/faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/support/legal',
        builder: (context, state) => const LegalScreen(),
      ),
      GoRoute(
        path: '/support/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/results',
        builder: (context, state) => const ResultsScreen(),
      ),
      GoRoute(
        path: '/tiles',
        builder: (context, state) => const TilesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Route not found: ${state.uri.path}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
    ),
  );
});
