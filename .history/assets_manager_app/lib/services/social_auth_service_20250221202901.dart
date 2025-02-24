import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

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
      // Start the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Create/Update user document in Firestore
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userDoc = _firestore.collection('users').doc(user.uid);

        final userData = {
          'name': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'lastLogin': FieldValue.serverTimestamp(),
          'provider': 'google',
        };

        // Check if user exists
        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          // New user
          await userDoc.set({
            ...userData,
            'role': 'User',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Existing user - update login time and any changed fields
          await userDoc.update(userData);
        }
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Apple Sign In
  Future<UserCredential?> signInWithApple() async {
    try {
      // Check if platform supports Apple Sign In
      if (!await SignInWithApple.isAvailable()) {
        throw PlatformException(
          code: 'APPLE_SIGN_IN_NOT_AVAILABLE',
          message: 'Apple Sign In is not available on this device',
        );
      }

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an OAuthCredential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Create/Update user document in Firestore
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userDoc = _firestore.collection('users').doc(user.uid);

        // Combine first and last name if available
        String? fullName;
        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          fullName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        }

        final userData = {
          'name': fullName ?? user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'lastLogin': FieldValue.serverTimestamp(),
          'provider': 'apple',
        };

        // Check if user exists
        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          // New user
          await userDoc.set({
            ...userData,
            'role': 'User',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Existing user - update login time and any changed fields
          await userDoc.update(userData);
        }
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Apple: $e');
      rethrow;
    }
  }

  // Sign out from social providers
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Check if device supports biometric authentication
  Future<bool> isSocialAuthAvailable() async {
    if (kIsWeb) {
      return true; // Web supports Google Sign In
    }

    if (Platform.isIOS) {
      return true; // iOS supports both Google and Apple Sign In
    }

    if (Platform.isAndroid) {
      return true; // Android supports Google Sign In
    }

    return false;
  }

  // Get available social auth providers
  Future<List<String>> getAvailableProviders() async {
    List<String> providers = ['google']; // Google is available on all platforms

    if (kIsWeb) {
      return providers;
    }

    if (Platform.isIOS) {
      providers.add('apple');
    }

    return providers;
  }
} 