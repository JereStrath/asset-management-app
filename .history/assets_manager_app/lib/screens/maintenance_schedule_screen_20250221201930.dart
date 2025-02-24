import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import 'asset_details_screen.dart';

class MaintenanceScheduleScreen extends StatefulWidget {
  @override
  _MaintenanceScheduleScreenState createState() => _MaintenanceScheduleScreenState();
}

class _MaintenanceScheduleScreenState extends State<MaintenanceScheduleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maintenance Schedule'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMaintenanceStream(),
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
                        Icon(Icons.build_circle_outlined, 
                             size: 64, 
                             color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No maintenance scheduled for this period'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    final daysUntilMaintenance = asset.nextMaintenance
                        .difference(DateTime.now())
                        .inDays;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          daysUntilMaintenance <= 0
                              ? Icons.warning
                              : Icons.build,
                          color: daysUntilMaintenance <= 0
                              ? Colors.red
                              : daysUntilMaintenance <= 7
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                        title: Text(asset.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Next Maintenance: ${DateFormat('MMM dd, yyyy').format(asset.nextMaintenance)}'),
                            Text(
                              daysUntilMaintenance <= 0
                                  ? 'Maintenance Overdue!'
                                  : 'Due in $daysUntilMaintenance days',
                              style: TextStyle(
                                color: daysUntilMaintenance <= 0
                                    ? Colors.red
                                    : daysUntilMaintenance <= 7
                                        ? Colors.orange
                                        : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'complete',
                              child: Text('Complete Maintenance'),
                            ),
                            PopupMenuItem(
                              value: 'reschedule',
                              child: Text('Reschedule'),
                            ),
                            PopupMenuItem(
                              value: 'details',
                              child: Text('View Details'),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'complete':
                                _completeMaintenance(asset);
                                break;
                              case 'reschedule':
                                _rescheduleMaintenance(context, asset);
                                break;
                              case 'details':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => 
                                        AssetDetailsScreen(asset: asset),
                                  ),
                                );
                                break;
                            }
                          },
                        ),
                        onTap: () => _showMaintenanceDetails(context, asset),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scheduleNewMaintenance(context),
        child: Icon(Icons.add),
        tooltip: 'Schedule New Maintenance',
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Maintenance Schedule:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getMaintenanceStream() {
    return _firestore
        .collection('assets')
        .where('nextMaintenance', 
            isLessThanOrEqualTo: 
                DateTime(_selectedDate.year, _selectedDate.month + 1, 0))
        .orderBy('nextMaintenance')
        .snapshots();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _completeMaintenance(Asset asset) async {
    final now = DateTime.now();
    try {
      await _firestore.collection('assets').doc(asset.id).update({
        'lastMaintenance': Timestamp.fromDate(now),
        'nextMaintenance': Timestamp.fromDate(
          now.add(Duration(days: 90)), // Default to 90 days
        ),
        'status': 'Available',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maintenance completed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing maintenance: $e')),
      );
    }
  }

  Future<void> _rescheduleMaintenance(BuildContext context, Asset asset) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: asset.nextMaintenance,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      try {
        await _firestore.collection('assets').doc(asset.id).update({
          'nextMaintenance': Timestamp.fromDate(picked),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maintenance rescheduled successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rescheduling maintenance: $e')),
        );
      }
    }
  }

  void _showMaintenanceDetails(BuildContext context, Asset asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Maintenance Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asset: ${asset.name}'),
            SizedBox(height: 8),
            Text('Category: ${asset.category}'),
            SizedBox(height: 8),
            Text('Location: ${asset.location}'),
            SizedBox(height: 8),
            Text('Last Maintenance: ${DateFormat('MMM dd, yyyy').format(asset.lastMaintenance)}'),
            SizedBox(height: 8),
            Text('Next Maintenance: ${DateFormat('MMM dd, yyyy').format(asset.nextMaintenance)}'),
            SizedBox(height: 8),
            Text('Status: ${asset.status}'),
          ],
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

  void _scheduleNewMaintenance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetDetailsScreen(
          asset: Asset(
            id: '',
            name: '',
            description: '',
            category: '',
            status: '',
            location: '',
            purchaseDate: DateTime.now(),
            purchasePrice: 0,
            assignedTo: '',
            lastMaintenance: DateTime.now(),
            nextMaintenance: DateTime.now(),
          ),
        ),
      ),
    );
  }
}