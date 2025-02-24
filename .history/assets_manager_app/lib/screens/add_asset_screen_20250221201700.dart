import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddAssetScreen extends StatefulWidget {
  @override
  _AddAssetScreenState createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _selectedCategory = 'Electronics';
  String _selectedStatus = 'Available';
  DateTime _purchaseDate = DateTime.now();
  DateTime _lastMaintenance = DateTime.now();
  DateTime _nextMaintenance = DateTime.now().add(Duration(days: 90));

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Asset'),
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
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAsset,
                  child: Text('Save Asset'),
                ),
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
        await _firestore.collection('assets').add({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'category': _selectedCategory,
          'status': _selectedStatus,
          'location': _locationController.text,
          'purchaseDate': Timestamp.fromDate(_purchaseDate),
          'purchasePrice': double.parse(_priceController.text),
          'assignedTo': '',
          'lastMaintenance': Timestamp.fromDate(_lastMaintenance),
          'nextMaintenance': Timestamp.fromDate(_nextMaintenance),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asset saved successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving asset: $e')),
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