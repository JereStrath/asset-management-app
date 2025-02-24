import 'package:flutter/material.dart';
import '../../models/asset.dart'; // Import the Asset model
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class AssetDetailsScreen extends StatefulWidget {
  final Asset asset; // Add the asset property

  const AssetDetailsScreen({Key? key, required this.asset}) : super(key: key); // Add to constructor

  @override
  _AssetDetailsScreenState createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _updateLastLogin(); // Call in initState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Details'),
      ),
      body: Center(
        child: Text('Asset Details: ${widget.asset.name}'), // Access asset via widget
      ),
    );
  }

  Future<void> _updateLastLogin() async {
    try {
      final updatedAsset = Asset(
        id: widget.asset.id,
        name: widget.asset.name,
        description: widget.asset.description,
        category: widget.asset.category,
        status: widget.asset.status,
        location: widget.asset.location,
        purchaseDate: widget.asset.purchaseDate,
        purchasePrice: widget.asset.purchasePrice,
        assignedTo: widget.asset.assignedTo,
        lastMaintenance: widget.asset.lastMaintenance,
        nextMaintenance: widget.asset.nextMaintenance,
        lastLogin: Timestamp.now(), // Set to current time
      );
      await FirebaseFirestore.instance
          .collection('assets')
          .doc(widget.asset.id)
          .update(updatedAsset.toMap());
    } catch (e) {
      print("Error updating lastLogin: $e");
    }
  }
} 