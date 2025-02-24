import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/asset_history.dart';
import 'package:uuid/uuid.dart';

class AssetTransferScreen extends StatefulWidget {
  final String assetId;
  final String currentLocation;
  final String currentDepartment;

  AssetTransferScreen({
    required this.assetId,
    required this.currentLocation,
    required this.currentDepartment,
  });

  @override
  _AssetTransferScreenState createState() => _AssetTransferScreenState();
}

class _AssetTransferScreenState extends State<AssetTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = Uuid();

  late TextEditingController _newLocationController;
  late TextEditingController _transferReasonController;
  String _selectedDepartment = '';
  DateTime? _transferDate;

  final List<String> _departments = [
    'IT',
    'HR',
    'Finance',
    'Operations',
    'Sales',
    'Marketing',
    'R&D',
    'Production',
    'Quality Control',
    'Maintenance',
    'Logistics',
    'Administration',
  ];

  @override
  void initState() {
    super.initState();
    _newLocationController = TextEditingController();
    _transferReasonController = TextEditingController();
    _selectedDepartment = widget.currentDepartment;
  }

  Future<void> _selectTransferDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _transferDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _transferDate = picked;
      });
    }
  }

  Future<void> _submitTransfer() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _auth.currentUser!;
        final timestamp = DateTime.now();

        // Create transfer record
        final transferData = {
          'fromLocation': widget.currentLocation,
          'toLocation': _newLocationController.text,
          'fromDepartment': widget.currentDepartment,
          'toDepartment': _selectedDepartment,
          'transferDate': _transferDate ?? timestamp,
          'reason': _transferReasonController.text,
          'requestedBy': user.uid,
          'requestedByName': user.displayName ?? user.email,
          'status': 'PENDING',
          'createdAt': timestamp,
        };

        // Update asset document
        await _firestore.collection('assets').doc(widget.assetId).update({
          'transferPending': true,
          'pendingTransfer': transferData,
        });

        // Create history entry
        final history = AssetHistory(
          id: _uuid.v4(),
          assetId: widget.assetId,
          action: 'TRANSFER_REQUESTED',
          userId: user.uid,
          userName: user.displayName ?? user.email ?? 'Unknown User',
          details: 'Transfer requested to ${_newLocationController.text} (${_selectedDepartment})',
          timestamp: timestamp,
          changes: transferData,
        );

        await _firestore
            .collection('assets')
            .doc(widget.assetId)
            .collection('history')
            .add(history.toMap());

        // Create transfer request
        await _firestore.collection('transferRequests').add({
          'assetId': widget.assetId,
          ...transferData,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer request submitted successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting transfer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer Asset'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Current Location: ${widget.currentLocation}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _newLocationController,
                decoration: InputDecoration(
                  labelText: 'New Location*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required field' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: InputDecoration(
                  labelText: 'New Department*',
                  border: OutlineInputBorder(),
                ),
                items: _departments.map((department) {
                  return DropdownMenuItem(
                    value: department,
                    child: Text(department),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Transfer Date*'),
                subtitle: Text(_transferDate == null
                    ? 'Select date'
                    : '${_transferDate!.day}/${_transferDate!.month}/${_transferDate!.year}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectTransferDate,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _transferReasonController,
                decoration: InputDecoration(
                  labelText: 'Transfer Reason*',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required field' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitTransfer,
                child: Text('Submit Transfer Request'),
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
    _newLocationController.dispose();
    _transferReasonController.dispose();
    super.dispose();
  }
} 