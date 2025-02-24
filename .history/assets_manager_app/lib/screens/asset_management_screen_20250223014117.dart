import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode/barcode.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/asset.dart';
import 'asset_details_screen.dart';
import 'add_asset_screen.dart';

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
            onPressed: () => _navigateToAddAsset(context),
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

          final assets = snapshot.data!.docs
              .map((doc) => Asset.fromFirestore(doc))
              .toList();

          if (assets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No assets found'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _navigateToAddAsset(context),
                    child: Text('Add Asset'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(_getAssetIcon(asset.category)),
                  title: Text(asset.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: ${asset.category}'),
                      Text('Status: ${asset.status}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Text('View Details'),
                      ),
                      PopupMenuItem(
                        value: 'qr',
                        child: Text('Show QR Code'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssetDetailsScreen(asset: asset),
                          ),
                        );
                      } else if (value == 'qr') {
                        _showQRCode(context, asset.id);
                      }
                    },
                  ),
                  onTap: () {
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAsset(context),
        child: Icon(Icons.add),
        tooltip: 'Add Asset',
      ),
    );
  }

  IconData _getAssetIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.computer;
      case 'furniture':
        return Icons.chair;
      case 'vehicles':
        return Icons.directions_car;
      case 'tools':
        return Icons.build;
      default:
        return Icons.inventory;
    }
  }

    void _showQRCode(BuildContext context, String barcode) {
    final qr = Barcode.qrCode();
    final svg = qr.toSvg(barcode, width: 200, height: 200);
      builder: (context) => AlertDialog(
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asset QR Code'),
        content: SvgPicture.string(svg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );


  void _navigateToAddAsset(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAssetScreen()),
    );
  }
}