import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Timer _timer;
  bool _isEmailVerified = false;
  bool _canResendEmail = true;
  int _timeLeft = 60;

  @override
  void initState() {
    super.initState();
    _isEmailVerified = _auth.currentUser?.emailVerified ?? false;

    if (!_isEmailVerified) {
      _sendVerificationEmail();
      _startVerificationCheck();
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      final user = _auth.currentUser!;
      await user.sendEmailVerification();
      
      setState(() {
        _canResendEmail = false;
        _timeLeft = 60;
      });

      _startResendTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending verification email. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startResendTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        setState(() {
          _canResendEmail = true;
        });
        timer.cancel();
      }
    });
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(Duration(seconds: 3), (_) async {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      
      if (user?.emailVerified ?? false) {
        setState(() {
          _isEmailVerified = true;
        });
        
        _timer.cancel();
        
        // Update user status in Firestore
        await _firestore.collection('users').doc(user!.uid).update({
          'emailVerified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Your Email'),
        actions: [
          TextButton(
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_unread,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 32),
            Text(
              'Verify Your Email Address',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'We\'ve sent a verification email to:\n${_auth.currentUser?.email}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                children: [
                  Text(
                    'Please check your email and click the verification link to continue.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Didn\'t receive the email? Check your spam folder.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _canResendEmail
                  ? _sendVerificationEmail
                  : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _canResendEmail
                    ? 'Resend Verification Email'
                    : 'Resend in $_timeLeft seconds',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await _auth.currentUser?.reload();
                final user = _auth.currentUser;
                if (user?.emailVerified ?? false) {
                  setState(() {
                    _isEmailVerified = true;
                  });
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Email not verified yet. Please check your email.'),
                    ),
                  );
                }
              },
              child: Text('I\'ve verified my email'),
            ),
          ],
        ),
      ),
    );
  }
} 