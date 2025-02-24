import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart'; // Import UserService

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
}
  Future<String?> getUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await _userService.getUserRole(user.uid);
    }
    return null;
  }
}
