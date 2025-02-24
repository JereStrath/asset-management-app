import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'add_asset_screen.dart';
import 'asset_details_screen.dart';
import '../models/asset.dart';
import 'package:intl/intl.dart';

class AssetManagementScreen extends StatefulWidget {
  @override
  _AssetManagementScreenState createState() => _AssetManagementScreenState();
}

class _AssetManagementScreenState extends State<AssetManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asset Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to add asset screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddAssetScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('assets').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final asset = Asset.fromFirestore(doc);

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Icon(Icons.inventory),
                  title: Text(asset.name),
                  subtitle: Text('Status: ${asset.status}'),
                  trailing: IconButton(
                    icon: Icon(Icons.qr_code),
                    onPressed: () {
                      // Show QR code for the asset
                      _showQRCode(context, asset.id);
                    },
                  ),
                  onTap: () {
                    // Navigate to asset details screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetDetailsScreen(asset: asset),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showQRCode(BuildContext context, String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asset QR Code'),
        content: Container(
          width: 200,
          height: 200,
          child: QrImage(
            data: barcode,
            version: QrVersions.auto,
            size: 200.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}