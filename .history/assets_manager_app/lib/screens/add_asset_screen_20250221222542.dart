import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class AddAssetScreen extends StatefulWidget {
  @override
  _AddAssetScreenState createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  
  final _assetNameController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _modelNumberController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _supplierController = TextEditingController();
  final _warrantyInfoController = TextEditingController();
  
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiryDate;
  DateTime? _lastMaintenanceDate;
  DateTime? _nextMaintenanceDate;
  
  String _selectedCategory = 'IT Equipment';
  String _selectedCondition = 'New';
  String _selectedStatus = 'In Use';
  String _selectedDepartment = 'IT';
  
  bool _isScanning = false;

  final List<String> _categories = [
    'IT Equipment',
    'Office Furniture',
    'Vehicles',
    'Machinery',
    'Tools',
    'Laboratory Equipment',
    'Medical Equipment',
    'Safety Equipment',
    'Communication Devices',
    'Audio/Visual Equipment',
    'Sports Equipment',
    'Kitchen Equipment',
    'HVAC Systems',
    'Electrical Equipment',
    'Building Infrastructure',
    'Software Licenses',
  ];

  final List<String> _conditions = [
    'New',
    'Excellent',
    'Good',
    'Fair',
    'Poor',
    'Needs Repair',
    'Obsolete',
  ];

  final List<String> _statuses = [
    'In Use',
    'In Storage',
    'Under Maintenance',
    'Out for Repair',
    'Reserved',
    'Disposed',
    'Lost/Stolen',
    'In Transit',
  ];

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
    'Security',
    'Training',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Asset'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: _startScanning,
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
              if (_isScanning)
                Container(
                  height: 300,
                  child: MobileScanner(
                    onDetect: _onScanDetect,
                  ),
                ),
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
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category*',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _serialNumberController,
                      decoration: InputDecoration(
                        labelText: 'Serial Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: () => _scanSpecificField('serial'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _modelNumberController,
                decoration: InputDecoration(
                  labelText: 'Model Number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _manufacturerController,
                decoration: InputDecoration(
                  labelText: 'Manufacturer',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _purchasePriceController,
                decoration: InputDecoration(
                  labelText: 'Purchase Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter purchase price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Purchase Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_purchaseDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, 'purchase'),
              ),
              ListTile(
                title: Text('Warranty Expiry Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_warrantyExpiryDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, 'warranty'),
              ),
              ListTile(
                title: Text('Last Maintenance'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_lastMaintenanceDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, 'last'),
              ),
              ListTile(
                title: Text('Next Maintenance'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_nextMaintenanceDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, 'next'),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: _conditions.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: InputDecoration(
                  labelText: 'Department',
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
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _supplierController,
                decoration: InputDecoration(
                  labelText: 'Supplier',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _warrantyInfoController,
                decoration: InputDecoration(
                  labelText: 'Warranty Information',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Add Asset'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });
  }

  void _onScanDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        _processScanResult(code);
      }
    }
  }

  void _processScanResult(String code) {
    try {
      Map<String, dynamic> data = _parseScannedData(code);
      
      setState(() {
        _assetNameController.text = data['name'] ?? '';
        _serialNumberController.text = data['serial'] ?? '';
        _modelNumberController.text = data['model'] ?? '';
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _serialNumberController.text = code;
        _isScanning = false;
      });
    }
  }

  Map<String, dynamic> _parseScannedData(String code) {
    try {
      return Map<String, dynamic>.from(json.decode(code));
    } catch (e) {
      Map<String, dynamic> result = {};
      code.split('|').forEach((part) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          result[keyValue[0].toLowerCase()] = keyValue[1];
        }
      });
      return result;
    }
  }

  void _scanSpecificField(String field) {
    // Implement specific field scanning
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: type == 'purchase' 
          ? _purchaseDate ?? DateTime.now() 
          : type == 'warranty' 
              ? _warrantyExpiryDate ?? DateTime.now() 
              : type == 'last' 
                  ? _lastMaintenanceDate ?? DateTime.now() 
                  : _nextMaintenanceDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        switch (type) {
          case 'purchase':
            _purchaseDate = picked;
            break;
          case 'warranty':
            _warrantyExpiryDate = picked;
            break;
          case 'last':
            _lastMaintenanceDate = picked;
            break;
          case 'next':
            _nextMaintenanceDate = picked;
            break;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final asset = {
          'name': _assetNameController.text,
          'category': _selectedCategory,
          'serialNumber': _serialNumberController.text,
          'modelNumber': _modelNumberController.text,
          'manufacturer': _manufacturerController.text,
          'purchasePrice': double.tryParse(_purchasePriceController.text) ?? 0.0,
          'purchaseDate': _purchaseDate,
          'warrantyExpiryDate': _warrantyExpiryDate,
          'lastMaintenanceDate': _lastMaintenanceDate,
          'nextMaintenanceDate': _nextMaintenanceDate,
          'condition': _selectedCondition,
          'status': _selectedStatus,
          'department': _selectedDepartment,
          'location': _locationController.text,
          'supplier': _supplierController.text,
          'warrantyInfo': _warrantyInfoController.text,
          'notes': _notesController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('assets').add(asset);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asset added successfully')),
        );
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding asset: $e')),
        );
      }
    }
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