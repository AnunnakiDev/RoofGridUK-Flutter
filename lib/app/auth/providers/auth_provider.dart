import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/auth/models/user_model.dart';
import 'package:roofgrid_uk/app/auth/services/auth_service.dart';

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Authentication service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

// Auth state changes stream provider
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Current Firebase user provider
final currentFirebaseUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).value;
});

// Auth state provider (authenticated, unauthenticated, loading)
final authStateProvider = Provider<AuthState>((ref) {
  final authStateChanges = ref.watch(authStateChangesProvider);
  return authStateChanges.when(
    data: (user) => user != null 
      ? AuthState.authenticated 
      : AuthState.unauthenticated,
    loading: () => AuthState.loading,
    error: (_,__) => AuthState.unauthenticated,
  );
});

// Current UserModel provider (our application user model)
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final firebaseUser = ref.watch(currentFirebaseUserProvider);
  if (firebaseUser == null) return null;
  
  return ref.watch(authServiceProvider).getUserData(firebaseUser.uid);
});

// Auth state enum
enum AuthState {
  loading,
  authenticated,
  unauthenticated,
}
