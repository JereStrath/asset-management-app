import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> setUserRole(String userId, String role) async {
    await _db.collection('users').doc(userId).set({'role': role});
  }

  String? getUserRole(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return data?['role'] as String?;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    QuerySnapshot querySnapshot = await _db.collection('users').get();
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }
}
