import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';

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
              stream: _firestore
                  .collection('assets')
                  .where('nextMaintenance', 
                      isLessThanOrEqualTo: 
                          DateTime(_selectedDate.year, _selectedDate.month + 1, 0))
                  .orderBy('nextMaintenance')
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
                    .toList();

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
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.check_circle_outline),
                          onPressed: () => _completeMaintenance(asset),
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
        tooltip: 'Schedule Maintenance',
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
            'Showing maintenance for:',
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
    await _firestore.collection('assets').doc(asset.id).update({
      'lastMaintenance': Timestamp.fromDate(now),
      'nextMaintenance': Timestamp.fromDate(
        now.add(Duration(days: 90)), // Default to 90 days
      ),
      'status': 'Available',
    });
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
            Text('Location: ${asset.location}'),
            SizedBox(height: 8),
            Text('Last Maintenance: ${DateFormat('MMM dd, yyyy').format(asset.lastMaintenance)}'),
            SizedBox(height: 8),
            Text('Next Maintenance: ${DateFormat('MMM dd, yyyy').format(asset.nextMaintenance)}'),
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
    // Navigate to maintenance scheduling screen
    // Implementation coming in next part
  }
}