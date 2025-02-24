import 'package:cloud_firestore/cloud_firestore.dart';

class Asset {
  final String id;
  final String name;
  final String description;
  final String category;
  final String status;
  final String location;
  final DateTime purchaseDate;
  final double purchasePrice;
  final String assignedTo;
  final DateTime lastMaintenance;
  final DateTime nextMaintenance;
  Timestamp? lastLogin;

  Asset({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.status,
    required this.location,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.assignedTo,
    required this.lastMaintenance,
    required this.nextMaintenance,
    this.lastLogin,
  });

  factory Asset.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Asset(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'Available',
      location: data['location'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      purchasePrice: (data['purchasePrice'] ?? 0.0).toDouble(),
      assignedTo: data['assignedTo'] ?? '',
      lastMaintenance: (data['lastMaintenance'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextMaintenance: (data['nextMaintenance'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: data['lastLogin'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'status': status,
      'location': location,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'purchasePrice': purchasePrice,
      'assignedTo': assignedTo,
      'lastMaintenance': Timestamp.fromDate(lastMaintenance),
      'nextMaintenance': Timestamp.fromDate(nextMaintenance),
      'lastLogin': lastLogin,
    };
  }
} 