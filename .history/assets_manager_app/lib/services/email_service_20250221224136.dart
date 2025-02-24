import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final _functions = FirebaseFunctions.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> sendMaintenanceNotification({
    required String assetId,
    required String assetName,
    required DateTime maintenanceDate,
    required String maintenanceType,
    String? details,
  }) async {
    try {
      await _functions.httpsCallable('sendMaintenanceEmail').call({
        'userId': _auth.currentUser?.uid,
        'userEmail': _auth.currentUser?.email,
        'assetId': assetId,
        'assetName': assetName,
        'maintenanceDate': maintenanceDate.toIso8601String(),
        'maintenanceType': maintenanceType,
        'details': details,
      });
    } catch (e) {
      print('Error sending email notification: $e');
      // Handle error appropriately
    }
  }

  Future<void> sendTransferNotification({
    required String assetId,
    required String assetName,
    required String fromLocation,
    required String toLocation,
    required DateTime transferDate,
  }) async {
    try {
      await _functions.httpsCallable('sendTransferEmail').call({
        'userId': _auth.currentUser?.uid,
        'userEmail': _auth.currentUser?.email,
        'assetId': assetId,
        'assetName': assetName,
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'transferDate': transferDate.toIso8601String(),
      });
    } catch (e) {
      print('Error sending transfer email notification: $e');
      // Handle error appropriately
    }
  }
} 