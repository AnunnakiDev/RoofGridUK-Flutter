import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel?> get authStateChanges => _auth.authStateChanges().map(
        (User? user) => user != null ? UserModel.fromFirebaseUser(user) : null,
      );

  // Get current user with Firestore data
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Get additional user data from Firestore
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirebaseUser(
          user,
          isPro: docSnapshot.data()?['isPro'] ?? false,
          subscriptionEndDate:
              docSnapshot.data()?['subscriptionEndDate'] != null
                  ? (docSnapshot.data()?['subscriptionEndDate'] as Timestamp)
                      .toDate()
                  : null,
          createdAt: docSnapshot.data()?['createdAt'] != null
              ? (docSnapshot.data()?['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }

    // Fallback to basic Firebase user info
    return UserModel.fromFirebaseUser(user);
  }

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document in Firestore with default values
    if (userCredential.user != null) {
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': userCredential.user!.displayName,
        'isPro': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return userCredential;
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    return await _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> updateUserProfile(
      {String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Update Firebase Auth profile
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateSubscription(
      {required String userId,
      required bool isPro,
      DateTime? subscriptionEndDate}) async {
    await _firestore.collection('users').doc(userId).update({
      'isPro': isPro,
      'subscriptionEndDate': subscriptionEndDate,
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateStreamProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
});
