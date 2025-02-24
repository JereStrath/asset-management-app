import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/asset_history.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import 'asset_details_screen.dart';

class MaintenanceScheduleScreen extends StatefulWidget {
  final String assetId;
  final String assetName;
  final DateTime? lastMaintenanceDate;

  MaintenanceScheduleScreen({
    required this.assetId,
    required this.assetName,
    this.lastMaintenanceDate,
  });

  @override
  _MaintenanceScheduleScreenState createState() => _MaintenanceScheduleScreenState();
}

class _MaintenanceScheduleScreenState extends State<MaintenanceScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = Uuid();

  DateTime? _scheduledDate;
  String _maintenanceType = 'Preventive';
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedCostController;
  String _priority = 'Medium';

  final List<String> _maintenanceTypes = [
    'Preventive',
    'Corrective',
    'Condition-based',
    'Predictive',
    'Emergency',
  ];

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _estimatedCostController = TextEditingController();
  }

  Future<void> _selectScheduledDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _submitSchedule() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _auth.currentUser!;
        final timestamp = DateTime.now();

        // Create maintenance record
        final maintenanceData = {
          'scheduledDate': _scheduledDate,
          'maintenanceType': _maintenanceType,
          'description': _descriptionController.text,
          'estimatedCost': double.tryParse(_estimatedCostController.text) ?? 0.0,
          'priority': _priority,
          'status': 'SCHEDULED',
          'scheduledBy': user.uid,
          'scheduledByName': user.displayName ?? user.email,
          'createdAt': timestamp,
        };

        // Update asset document
        await _firestore.collection('assets').doc(widget.assetId).update({
          'nextMaintenanceDate': _scheduledDate,
          'maintenanceStatus': 'SCHEDULED',
        });

        // Create history entry
        final history = AssetHistory(
          id: _uuid.v4(),
          assetId: widget.assetId,
          action: 'MAINTENANCE_SCHEDULED',
          userId: user.uid,
          userName: user.displayName ?? user.email ?? 'Unknown User',
          details: 'Maintenance scheduled for ${DateFormat('MMM dd, yyyy').format(_scheduledDate!)}',
          timestamp: timestamp,
          changes: maintenanceData,
        );

        await _firestore
            .collection('assets')
            .doc(widget.assetId)
            .collection('history')
            .add(history.toMap());

        // Create maintenance record
        await _firestore.collection('maintenanceSchedules').add({
          'assetId': widget.assetId,
          'assetName': widget.assetName,
          ...maintenanceData,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maintenance scheduled successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling maintenance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Maintenance'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Asset: ${widget.assetName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.lastMaintenanceDate != null)
                Text(
                  'Last Maintenance: ${DateFormat('MMM dd, yyyy').format(widget.lastMaintenanceDate!)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Scheduled Date*'),
                subtitle: Text(_scheduledDate == null
                    ? 'Select date'
                    : DateFormat('MMM dd, yyyy').format(_scheduledDate!)),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectScheduledDate,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _maintenanceType,
                decoration: InputDecoration(
                  labelText: 'Maintenance Type*',
                  border: OutlineInputBorder(),
                ),
                items: _maintenanceTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _maintenanceType = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description*',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required field' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _estimatedCostController,
                decoration: InputDecoration(
                  labelText: 'Estimated Cost',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(
                  labelText: 'Priority*',
                  border: OutlineInputBorder(),
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitSchedule,
                child: Text('Schedule Maintenance'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _estimatedCostController.dispose();
    super.dispose();
  }
}