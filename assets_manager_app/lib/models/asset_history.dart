import 'package:cloud_firestore/cloud_firestore.dart';

class AssetHistory {
  final String id;
  final String assetId;
  final String action;
  final String userId;
  final String userName;
  final String? details;
  final DateTime timestamp;
  final Map<String, dynamic>? changes;

  AssetHistory({
    required this.id,
    required this.assetId,
    required this.action,
    required this.userId,
    required this.userName,
    this.details,
    required this.timestamp,
    this.changes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetId': assetId,
      'action': action,
      'userId': userId,
      'userName': userName,
      'details': details,
      'timestamp': timestamp,
      'changes': changes,
    };
  }

  factory AssetHistory.fromMap(Map<String, dynamic> map) {
    return AssetHistory(
      id: map['id'],
      assetId: map['assetId'],
      action: map['action'],
      userId: map['userId'],
      userName: map['userName'],
      details: map['details'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      changes: map['changes'],
    );
  }
} 