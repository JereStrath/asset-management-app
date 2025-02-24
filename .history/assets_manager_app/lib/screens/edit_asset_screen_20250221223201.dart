import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/asset_history.dart';
import 'package:uuid/uuid.dart';

class EditAssetScreen extends StatefulWidget {
  final String assetId;
  final Map<String, dynamic> assetData;

  EditAssetScreen({
    required this.assetId,
    required this.assetData,
  });

  @override
  _EditAssetScreenState createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = Uuid();
  
  late TextEditingController _assetNameController;
  late TextEditingController _serialNumberController;
  late TextEditingController _modelNumberController;
  late TextEditingController _manufacturerController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _notesController;
  late TextEditingController _locationController;
  late TextEditingController _supplierController;
  late TextEditingController _warrantyInfoController;

  Map<String, dynamic> _originalData = {};
  Map<String, dynamic> _changes = {};

  @override
  void initState() {
    super.initState();
    _originalData = Map.from(widget.assetData);
    
    _assetNameController = TextEditingController(text: widget.assetData['name']);
    _serialNumberController = TextEditingController(text: widget.assetData['serialNumber']);
    _modelNumberController = TextEditingController(text: widget.assetData['modelNumber']);
    _manufacturerController = TextEditingController(text: widget.assetData['manufacturer']);
    _purchasePriceController = TextEditingController(text: widget.assetData['purchasePrice'].toString());
    _notesController = TextEditingController(text: widget.assetData['notes']);
    _locationController = TextEditingController(text: widget.assetData['location']);
    _supplierController = TextEditingController(text: widget.assetData['supplier']);
    _warrantyInfoController = TextEditingController(text: widget.assetData['warrantyInfo']);
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedData = {
          'name': _assetNameController.text,
          'serialNumber': _serialNumberController.text,
          'modelNumber': _modelNumberController.text,
          'manufacturer': _manufacturerController.text,
          'purchasePrice': double.tryParse(_purchasePriceController.text) ?? 0.0,
          'notes': _notesController.text,
          'location': _locationController.text,
          'supplier': _supplierController.text,
          'warrantyInfo': _warrantyInfoController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Calculate changes
        _changes = {};
        updatedData.forEach((key, value) {
          if (_originalData[key] != value) {
            _changes[key] = {
              'from': _originalData[key],
              'to': value,
            };
          }
        });

        if (_changes.isNotEmpty) {
          // Update asset
          await _firestore
              .collection('assets')
              .doc(widget.assetId)
              .update(updatedData);

          // Create history entry
          final user = _auth.currentUser!;
          final history = AssetHistory(
            id: _uuid.v4(),
            assetId: widget.assetId,
            action: 'UPDATED',
            userId: user.uid,
            userName: user.displayName ?? user.email ?? 'Unknown User',
            details: 'Asset updated',
            timestamp: DateTime.now(),
            changes: _changes,
          );

          await _firestore
              .collection('assets')
              .doc(widget.assetId)
              .collection('history')
              .add(history.toMap());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Asset updated successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No changes detected')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating asset: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Asset'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _assetNameController,
                decoration: InputDecoration(
                  labelText: 'Asset Name*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required field' : null,
              ),
              SizedBox(height: 16),
              // Add more form fields similar to AddAssetScreen
              // ...
              ElevatedButton(
                onPressed: _saveChanges,
                child: Text('Save Changes'),
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
    _assetNameController.dispose();
    _serialNumberController.dispose();
    _modelNumberController.dispose();
    _manufacturerController.dispose();
    _purchasePriceController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _supplierController.dispose();
    _warrantyInfoController.dispose();
    super.dispose();
  }
}
