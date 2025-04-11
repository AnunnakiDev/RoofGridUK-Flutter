import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgridk_app/providers/auth_provider.dart';
import 'package:roofgridk_app/utils/firebase_error_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _resetSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.resetPassword(
          _emailController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _resetSent = true;
            _isLoading = false;
          });
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = FirebaseErrorHandler.getAuthErrorMessage(e);
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'An unexpected error occurred. Please try again.';
            _isLoading = false;
          });
        }
      }
    }
  }

  String _getFirebaseErrorMessage(String errorCode) {
    if (errorCode.contains('user-not-found')) {
      return 'No account found with this email address.';
    } else if (errorCode.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (errorCode.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    _resetSent ? Icons.check_circle_outline : Icons.lock_reset,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ).animate().fadeIn().scale(),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _resetSent ? 'Reset Link Sent' : 'Forgot Password',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),

                  // Instructions
                  Text(
                    _resetSent
                        ? 'We\'ve sent a password reset link to ${_emailController.text}. Please check your inbox and follow the instructions to reset your password.'
                        : 'Enter your email address below and we\'ll send you a link to reset your password.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 32),

                  if (!_resetSent) ...[
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ).animate().shake(),
                    if (_errorMessage != null) const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 24),

                    // Reset Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send Reset Link'),
                    ).animate().fadeIn(delay: 500.ms),
                  ] else ...[
                    // Back to Login Button when reset sent
                    ElevatedButton(
                      onPressed: () => context.go('/auth/login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Back to Login'),
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
