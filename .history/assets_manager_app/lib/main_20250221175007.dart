import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';  // Updated path
import 'screens/signup_screen.dart';  // Updated path
import 'screens/home_screen.dart';   // Updated path
import 'firebase_options.dart';      // Updated path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print('Initializing Firebase'); // Debug log
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully'); // Debug log
  } catch (e) {
    print('Failed to initialize Firebase: $e'); // Debug log
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asset Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(),
    );
  }
} 