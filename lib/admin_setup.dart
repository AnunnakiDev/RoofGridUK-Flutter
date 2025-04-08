// This file is used once to set up the admin account
// Run with: flutter run -t lib/admin_setup.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const AdminSetupApp());
}

class AdminSetupApp extends StatelessWidget {
  const AdminSetupApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AdminSetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminSetupScreen extends StatefulWidget {
  @override
  _AdminSetupScreenState createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  String _status = 'Ready to create admin account';
  bool _isLoading = false;
  
  Future<void> _createAdminAccount() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating admin account...';
    });
    
    try {
      // First check if user already exists
      try {
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail('support@roofgrid.uk');
        if (methods.isNotEmpty) {
          setState(() {
            _status = 'Admin account already exists. You can login with it.';
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Error checking if email exists: $e');
      }
      
      // Create the user
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'support@roofgrid.uk',
        password: 'Password123!',
      );
      
      // Set user data in Firestore
      if (credential.user != null) {
        final now = DateTime.now();
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'uid': credential.user!.uid,
          'email': 'support@roofgrid.uk',
          'displayName': 'Admin',
          'photoURL': null,
          'role': 'admin',
          'createdAt': now,
          'lastLoginAt': now,
        });
        
        setState(() {
          _status = 'Admin account created successfully! 🎉\n\n'
              'Email: support@roofgrid.uk\n'
              'Password: Password123!\n\n'
              'You can now go back to the app and login.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error creating admin account: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Account Setup'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
              SizedBox(height: 24),
              Text(
                'RoofGrid UK Admin Setup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 40),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _createAdminAccount,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text('Create Admin Account'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
