import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_service.dart'; // Import UserService

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user role
  Future<String?> getUserRole() async {
    if (currentUser == null) return null;
    
    try {
      DocumentSnapshot doc = await _db
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      final data = doc.data() as Map<String, dynamic>?;
      return data?['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    User? user = currentUser;
    if (user != null) {
      String? role = await getUserRole();
      return role == 'admin';
    }
    return false;
  }
}
