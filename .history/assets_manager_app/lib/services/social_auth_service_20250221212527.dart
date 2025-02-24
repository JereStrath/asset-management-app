import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userDoc = _firestore.collection('users').doc(user.uid);

        final userData = {
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoURL': user.photoURL ?? '',
          'lastLogin': FieldValue.serverTimestamp(),
          'provider': 'google',
          'role': 'User',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        };

        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set(userData);
        } else {
          await userDoc.update({
            ...userData,
            'createdAt': docSnapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
            'role': docSnapshot.data()?['role'] ?? 'User',
          });
        }
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Future<bool> isSocialAuthAvailable() async {
    if (kIsWeb) {
      return true;
    }
    return true; // Google Sign In is available on all platforms
  }

  Future<List<String>> getAvailableProviders() async {
    return ['google']; // Only Google sign-in for now
  }
} 