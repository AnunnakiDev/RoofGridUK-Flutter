import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrorHandler {
  static String getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already in use. Try signing in instead.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'The email address is invalid. Please check and try again.';
      case 'too-many-requests':
        return 'Too many unsuccessful login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'This operation is sensitive and requires recent authentication. Please log in again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Contact support.';
      default:
        return error.message ?? 'An error occurred. Please try again.';
    }
  }

  static String getFirestoreErrorMessage(String errorCode) {
    if (errorCode.contains('permission-denied')) {
      return 'You do not have permission to perform this action.';
    } else if (errorCode.contains('unavailable')) {
      return 'The service is currently unavailable. Please try again later.';
    } else if (errorCode.contains('not-found')) {
      return 'The requested document was not found.';
    } else if (errorCode.contains('already-exists')) {
      return 'The document already exists.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}
