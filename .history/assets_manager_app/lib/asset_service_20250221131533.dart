import 'package:cloud_firestore/cloud_firestore.dart';

class AssetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addAsset(String id, Map<String, dynamic> assetData) async {
    await _db.collection('assets').doc(id).set(assetData);
  }

  Future<DocumentSnapshot> getAsset(String id) async {
    return await _db.collection('assets').doc(id).get();
  }

  Future<List<Map<String, dynamic>>> getAllAssets() async {
    QuerySnapshot querySnapshot = await _db.collection('assets').get();
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }
}
