import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asset.dart';
import 'edit_asset_screen.dart';
import 'package:intl/intl.dart';

class AssetDetailsScreen extends StatelessWidget {
  final Asset asset;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AssetDetailsScreen({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asset Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              title: 'Basic Information',
              children: [
                _buildDetailRow('Name', asset.name),
                _buildDetailRow('Description', asset.description),
                _buildDetailRow('Status', asset.status),
                _buildDetailRow('Location', asset.location),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoCard(
              title: 'Financial Information',
              children: [
                _buildDetailRow('Purchase Date', 
                    asset.purchaseDate.toString().split(' ')[0]),
                _buildDetailRow('Purchase Price', 
                    '\$${asset.purchasePrice.toStringAsFixed(2)}'),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoCard(
              title: 'Maintenance Information',
              children: [
                _buildDetailRow('Last Maintenance', 
                    asset.lastMaintenance.toString().split(' ')[0]),
                _buildDetailRow('Next Maintenance', 
                    asset.nextMaintenance.toString().split(' ')[0]),
                _buildDetailRow('Assigned To', asset.assignedTo),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _scheduleMaintenanceDialog(context),
              child: Text('Schedule Maintenance'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAssetScreen(asset: asset),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Asset'),
        content: Text('Are you sure you want to delete this asset?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('assets').doc(asset.id).delete();
      Navigator.pop(context);
    }
  }

  Future<void> _scheduleMaintenanceDialog(BuildContext context) async {
    DateTime selectedDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      await _firestore.collection('assets').doc(asset.id).update({
        'nextMaintenance': Timestamp.fromDate(picked),
      });
    }
  }
}
