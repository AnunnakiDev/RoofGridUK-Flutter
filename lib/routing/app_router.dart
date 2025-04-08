import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/auth/providers/auth_provider.dart';
import 'package:roofgrid_uk/screens/auth/forgot_password_screen.dart';
import 'package:roofgrid_uk/screens/auth/login_screen.dart';
import 'package:roofgrid_uk/screens/auth/register_screen.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';
import 'package:roofgrid_uk/screens/home/home_screen.dart';
import 'package:roofgrid_uk/screens/splash/splash_screen.dart';
import 'package:roofgrid_uk/screens/admin/admin_dashboard_screen.dart';
import 'package:roofgrid_uk/screens/support/faq_screen.dart';
import 'package:roofgrid_uk/screens/support/legal_screen.dart';
import 'package:roofgrid_uk/screens/support/contact_screen.dart';

class AppRouter {
  static GoRouter router(AuthState authState) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        // Handle splash screen redirect
        if (state.uri.path == '/') {
          return '/splash';
        }

        // Handle auth redirects
        final isLoggedIn = authState == AuthState.authenticated;
        final isGoingToAuth = state.uri.path.startsWith('/auth');

        // If not logged in and not going to auth, redirect to login
        if (!isLoggedIn && !isGoingToAuth && state.uri.path != '/splash') {
          return '/auth/login';
        }

        // If logged in and going to auth, redirect to home
        if (isLoggedIn && isGoingToAuth) {
          return '/home';
        }

        // Allow other routes to proceed
        return null;
      },
      routes: [
        // Splash Screen
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth Routes
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
        ), // Main App Routes
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/calculator',
          builder: (context, state) => const CalculatorScreen(),
        ), // Admin Routes
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),

        // Support Routes
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
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Route not found: ${state.uri.path}'),
        ),
      ),
    );
  }
}
