import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgriduk/models/user_model.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(const AuthState());

  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _analytics.logLogin(loginMethod: 'email');
      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user?.uid,
        isLoading: false,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: mapFirebaseError(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'An unexpected error occurred.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false; // User cancelled
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      await _analytics.logLogin(loginMethod: 'google');
      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user?.uid,
        isLoading: false,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: mapFirebaseError(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'An unexpected error occurred.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _auth.sendPasswordResetEmail(email: email);
      await _analytics.logEvent(name: 'password_reset');
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        error: mapFirebaseError(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'An unexpected error occurred.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await _analytics.logEvent(name: 'sign_out');
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: 'Failed to sign out: $e');
    }
  }

  Future<bool> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user?.uid,
        isLoading: false,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: mapFirebaseError(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'An unexpected error occurred.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> updateUserProfile(
      {String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> upgradeToProStatus() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No user logged in.',
        );
        return false;
      }
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'role': 'pro',
        'proTrialStartDate': Timestamp.now(),
        'proTrialEndDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
      }, SetOptions(merge: true));
      await _analytics.logEvent(name: 'upgrade_to_pro');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to upgrade: $e',
      );
      return false;
    }
  }

  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  String mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final authStateStreamProvider = StreamProvider<UserModel?>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return authNotifier._auth.authStateChanges().map(
        (User? user) => user != null ? UserModel.fromFirebaseUser(user) : null,
      );
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.userId == null) {
    return Stream.value(null);
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(authState.userId)
      .snapshots()
      .map((snapshot) =>
          snapshot.exists ? UserModel.fromFirestore(snapshot) : null);
});
