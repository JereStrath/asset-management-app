import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('users').get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _db.collection('users').doc(userId).update({
        'role': newRole,
      });
    } catch (e) {
      print('Error updating user role: $e');
      throw e;
    }
  }
}