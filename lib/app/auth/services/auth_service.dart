import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roofgrid_uk/app/auth/models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService(this._firebaseAuth);

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login timestamp
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }
      
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Set display name
      await credential.user?.updateDisplayName(displayName);
      
      // Create user document in Firestore
      if (credential.user != null) {
        final now = DateTime.now();
        final trialEndDate = now.add(const Duration(days: 14));
        
        final user = UserModel(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
          photoURL: credential.user!.photoURL,
          role: UserRole.free,
          proTrialStartDate: now,
          proTrialEndDate: trialEndDate,
          createdAt: now,
          lastLoginAt: now,
        );
        
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(user.toFirestore());
      }
      
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Start pro trial
  Future<void> startProTrial(String uid) async {
    final now = DateTime.now();
    final trialEndDate = now.add(const Duration(days: 14));
    
    await _firestore.collection('users').doc(uid).update({
      'proTrialStartDate': now,
      'proTrialEndDate': trialEndDate,
      'role': UserRole.pro.toString(),
    });
  }

  // Upgrade to pro
  Future<void> upgradeToPro(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'role': UserRole.pro.toString(),
    });
  }

  // Check if email is in use
  Future<bool> isEmailInUse(String email) async {
    try {
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
