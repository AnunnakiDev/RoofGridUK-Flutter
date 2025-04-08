import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBNG0Vkaid36qLuMzbNtLPT4j3iwGvLMUo',
    appId: '1:796676497165:web:9b33d87571a7a3cd4b9a44',
    messagingSenderId: '796676497165',
    projectId: 'roofgriduk',
    authDomain: 'roofgriduk.firebaseapp.com',
    storageBucket: 'roofgriduk.firebasestorage.app',
    measurementId: 'G-NSLE7J6VG0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBNG0Vkaid36qLuMzbNtLPT4j3iwGvLMUo',
    appId: '1:796676497165:android:9b33d87571a7a3cd4b9a44',
    messagingSenderId: '796676497165',
    projectId: 'roofgriduk',
    storageBucket: 'roofgriduk.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBNG0Vkaid36qLuMzbNtLPT4j3iwGvLMUo',
    appId: '1:796676497165:ios:9b33d87571a7a3cd4b9a44',
    messagingSenderId: '796676497165',
    projectId: 'roofgriduk',
    storageBucket: 'roofgriduk.firebasestorage.app',
    iosBundleId: 'com.roofgriduk.app',
  );
}
