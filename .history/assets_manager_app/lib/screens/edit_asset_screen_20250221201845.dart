import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';

class EditAssetScreen extends StatefulWidget {
  final Asset asset;

  EditAssetScreen({required this.asset});

  @override
  _EditAssetScreenState createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  
  late String _selectedCategory;
  late String _selectedStatus;
  late DateTime _purchaseDate;
  late DateTime _lastMaintenance;
  late DateTime _nextMaintenance;

  final List<String> _categories = [
    'Electronics',
    'Furniture',
    'Vehicles',
    'Tools',
    'Other'
  ];

  final List<String> _statuses = [
    'Available',
    'In Use',
    'Under Maintenance',
    'Retired'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset.name);
    _descriptionController = TextEditingController(text: widget.asset.description);
    _locationController = TextEditingController(text: widget.asset.location);
    _priceController = TextEditingController(
        text: widget.asset.purchasePrice.toStringAsFixed(2));
    
    _selectedCategory = widget.asset.category;
    _selectedStatus = widget.asset.status;
    _purchaseDate = widget.asset.purchaseDate;
    _lastMaintenance = widget.asset.lastMaintenance;
    _nextMaintenance = widget.asset.nextMaintenance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Asset'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveAsset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Asset Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter asset name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
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
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
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
                title: Text('Last Maintenance'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_lastMaintenance)),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, 'last'),
              ),
              ListTile(
                title: Text('Next Maintenance'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_nextMaintenance)),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, 'next'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: type == 'purchase' 
          ? _purchaseDate 
          : type == 'last' 
              ? _lastMaintenance 
              : _nextMaintenance,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        switch (type) {
          case 'purchase':
            _purchaseDate = picked;
            break;
          case 'last':
            _lastMaintenance = picked;
            break;
          case 'next':
            _nextMaintenance = picked;
            break;
        }
      });
    }
  }

  Future<void> _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _firestore.collection('assets').doc(widget.asset.id).update({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'category': _selectedCategory,
          'status': _selectedStatus,
          'location': _locationController.text,
          'purchaseDate': Timestamp.fromDate(_purchaseDate),
          'purchasePrice': double.parse(_priceController.text),
          'lastMaintenance': Timestamp.fromDate(_lastMaintenance),
          'nextMaintenance': Timestamp.fromDate(_nextMaintenance),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asset updated successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating asset: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
