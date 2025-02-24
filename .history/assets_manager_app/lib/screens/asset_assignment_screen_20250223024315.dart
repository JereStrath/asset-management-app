import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asset.dart';


class AssetAssignmentScreen extends StatefulWidget {
  @override
  _AssetAssignmentScreenState createState() => _AssetAssignmentScreenState();
}

class _AssetAssignmentScreenState extends State<AssetAssignmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asset Assignment'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Assets',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('assets')
                  .where('status', isEqualTo: 'Available')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final assets = snapshot.data!.docs
                    .map((doc) => Asset.fromFirestore(doc))
                    .where((asset) => asset.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                return ListView.builder(
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(asset.name),
                        subtitle: Text('Location: ${asset.location}'),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignmentDialog(BuildContext context, Asset asset) async {
    final TextEditingController assignToController = TextEditingController();
    final DateTime now = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Asset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Asset: ${asset.name}'),
            SizedBox(height: 16),
            TextField(
              controller: assignToController,
              decoration: InputDecoration(
                labelText: 'Assign to (Name/ID)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (assignToController.text.isNotEmpty) {
                await _firestore.collection('assets').doc(asset.id).update({
                  'status': 'In Use',
                  'assignedTo': assignToController.text,
                  'assignmentDate': Timestamp.fromDate(now),
                });
                
                // Create assignment record
                await _firestore.collection('assignments').add({
                  'assetId': asset.id,
                  'assetName': asset.name,
                  'assignedTo': assignToController.text,
                  'assignedDate': Timestamp.fromDate(now),
                  'status': 'Active',
                });

                Navigator.pop(context);
              }
            },
            child: Text('Assign'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}