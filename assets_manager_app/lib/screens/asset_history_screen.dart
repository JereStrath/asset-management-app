import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/asset_history.dart';
import 'package:asset_manager_app/screens/asset_details_screen.dart';

class AssetHistoryScreen extends StatelessWidget {
  final String assetId;
  final String assetName;

  AssetHistoryScreen({
    required this.assetId,
    required this.assetName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asset History'),
        subtitle: Text(assetName),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assets')
            .where('assetId', isEqualTo: assetId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final histories = snapshot.data!.docs
              .map((doc) => AssetHistory.fromMap(doc.data() as Map<String, dynamic>))
              .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.builder(
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final history = histories[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(history.action),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('By: ${history.userName}'),
                      Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(history.timestamp)}'),
                      if (history.details != null)
                        Text('Details: ${history.details}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () => _showHistoryDetails(context, history),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showHistoryDetails(BuildContext context, AssetHistory history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('History Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Action: ${history.action}'),
              Text('User: ${history.userName}'),
              Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(history.timestamp)}'),
              if (history.details != null)
                Text('Details: ${history.details}'),
              if (history.changes != null) ...[
                SizedBox(height: 16),
                Text('Changes:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...history.changes!.entries.map(
                  (e) => Text('${e.key}: ${e.value}'),
                ),
              ],
            ],
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