import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/asset_history.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:your_package_name/screens/asset_details_screen.dart';

class MaintenanceCompletionScreen extends StatefulWidget {
  final String maintenanceId;
  final String assetId;
  final String assetName;
  final Map<String, dynamic> maintenanceData;

  MaintenanceCompletionScreen({
    required this.maintenanceId,
    required this.assetId,
    required this.assetName,
    required this.maintenanceData,
  });

  @override
  _MaintenanceCompletionScreenState createState() => _MaintenanceCompletionScreenState();
}

class _MaintenanceCompletionScreenState extends State<MaintenanceCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = Uuid();

  late TextEditingController _workDoneController;
  late TextEditingController _actualCostController;
  late TextEditingController _partsReplacedController;
  late TextEditingController _technicianNotesController;
  DateTime? _completionDate;
  String _maintenanceOutcome = 'Completed';
  List<String> _attachedPhotos = [];

  final List<String> _outcomes = [
    'Completed',
    'Partially Completed',
    'Needs Further Work',
    'Parts Required',
    'Referred to Specialist',
  ];

  @override
  void initState() {
    super.initState();
    _workDoneController = TextEditingController();
    _actualCostController = TextEditingController();
    _partsReplacedController = TextEditingController();
    _technicianNotesController = TextEditingController();
    _completionDate = DateTime.now();
  }

  Future<void> _selectCompletionDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _completionDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _completionDate = picked;
      });
    }
  }

  Future<void> _submitCompletion() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _auth.currentUser!;
        final timestamp = DateTime.now();

        // Create completion record
        final completionData = {
          'completionDate': _completionDate,
          'workDone': _workDoneController.text,
          'actualCost': double.tryParse(_actualCostController.text) ?? 0.0,
          'partsReplaced': _partsReplacedController.text,
          'technicianNotes': _technicianNotesController.text,
          'outcome': _maintenanceOutcome,
          'completedBy': user.uid,
          'completedByName': user.displayName ?? user.email,
          'attachedPhotos': _attachedPhotos,
          'completedAt': timestamp,
        };

        // Update maintenance record
        await _firestore.collection('maintenanceSchedules').doc(widget.maintenanceId).update({
          'status': 'COMPLETED',
          'completion': completionData,
        });

        // Update asset document
        await _firestore.collection('assets').doc(widget.assetId).update({
          'lastMaintenanceDate': _completionDate,
          'maintenanceStatus': 'COMPLETED',
          'nextMaintenanceDate': _completionDate!.add(Duration(days: 90)), // Default to 90 days
        });

        // Create history entry
        final history = AssetHistory(
          id: _uuid.v4(),
          assetId: widget.assetId,
          action: 'MAINTENANCE_COMPLETED',
          userId: user.uid,
          userName: user.displayName ?? user.email ?? 'Unknown User',
          details: 'Maintenance completed on ${DateFormat('MMM dd, yyyy').format(_completionDate!)}',
          timestamp: timestamp,
          changes: completionData,
        );

        await _firestore
            .collection('assets')
            .doc(widget.assetId)
            .collection('history')
            .add(history.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maintenance completion recorded successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording completion: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Maintenance'),
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
              Text(
                'Scheduled: ${DateFormat('MMM dd, yyyy').format(widget.maintenanceData['scheduledDate'].toDate())}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Completion Date*'),
                subtitle: Text(_completionDate == null
                    ? 'Select date'
                    : DateFormat('MMM dd, yyyy').format(_completionDate!)),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectCompletionDate,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _workDoneController,
                decoration: InputDecoration(
                  labelText: 'Work Done*',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required field' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _actualCostController,
                decoration: InputDecoration(
                  labelText: 'Actual Cost*',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required field' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _partsReplacedController,
                decoration: InputDecoration(
                  labelText: 'Parts Replaced',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _maintenanceOutcome,
                decoration: InputDecoration(
                  labelText: 'Maintenance Outcome*',
                  border: OutlineInputBorder(),
                ),
                items: _outcomes.map((outcome) {
                  return DropdownMenuItem(
                    value: outcome,
                    child: Text(outcome),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _maintenanceOutcome = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _technicianNotesController,
                decoration: InputDecoration(
                  labelText: 'Technician Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitCompletion,
                child: Text('Complete Maintenance'),
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
    _workDoneController.dispose();
    _actualCostController.dispose();
    _partsReplacedController.dispose();
    _technicianNotesController.dispose();
    super.dispose();
  }
} 