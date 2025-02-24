import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asset.dart';
import 'package:intl/intl.dart';

class EditAssetScreen extends StatefulWidget {
  final Asset? asset;  // Null for new assets

  EditAssetScreen({this.asset});

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
  late TextEditingController _assignedToController;
  
  DateTime _purchaseDate = DateTime.now();
  DateTime _lastMaintenance = DateTime.now();
  DateTime _nextMaintenance = DateTime.now().add(Duration(days: 90));
  String _status = 'Available';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset?.name ?? '');
    _descriptionController = TextEditingController(text: widget.asset?.description ?? '');
    _locationController = TextEditingController(text: widget.asset?.location ?? '');
    _priceController = TextEditingController(
        text: widget.asset?.purchasePrice.toString() ?? '0.0');
    _assignedToController = TextEditingController(text: widget.asset?.assignedTo ?? '');

    if (widget.asset != null) {
      _purchaseDate = widget.asset!.purchaseDate;
      _lastMaintenance = widget.asset!.lastMaintenance;
      _nextMaintenance = widget.asset!.nextMaintenance;
      _status = widget.asset!.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asset == null ? 'Add Asset' : 'Edit Asset'),
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
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ['Available', 'In Use', 'Under Maintenance', 'Retired']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _status = newValue!;
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
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
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
                subtitle: Text(_purchaseDate.toString().split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, 'purchase'),
              ),
              ListTile(
                title: Text('Last Maintenance'),
                subtitle: Text(_lastMaintenance.toString().split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, 'last'),
              ),
              ListTile(
                title: Text('Next Maintenance'),
                subtitle: Text(_nextMaintenance.toString().split(' ')[0]),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, 'next'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveAsset,
                child: Text(widget.asset == null ? 'Add Asset' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
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
      final assetData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'status': _status,
        'location': _locationController.text,
        'purchaseDate': Timestamp.fromDate(_purchaseDate),
        'purchasePrice': double.parse(_priceController.text),
        'assignedTo': _assignedToController.text,
        'lastMaintenance': Timestamp.fromDate(_lastMaintenance),
        'nextMaintenance': Timestamp.fromDate(_nextMaintenance),
      };

      try {
        if (widget.asset == null) {
          await _firestore.collection('assets').add(assetData);
        } else {
          await _firestore
              .collection('assets')
              .doc(widget.asset!.id)
              .update(assetData);
        }
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
    _assignedToController.dispose();
    super.dispose();
  }
}
