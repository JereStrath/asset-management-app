import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:assets_manager_app/screens/details/asset_details_screen.dart';

class OfflineAssetEditScreen extends StatefulWidget {
  final Map<String, dynamic>? asset;

  OfflineAssetEditScreen({this.asset});

  @override
  _OfflineAssetEditScreenState createState() => _OfflineAssetEditScreenState();
}

class _OfflineAssetEditScreenState extends State<OfflineAssetEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _offlineSyncService = OfflineSyncService();
  final _uuid = Uuid();

  late TextEditingController _nameController;
  late TextEditingController _serialNumberController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset?['name'] ?? '');
    _serialNumberController = TextEditingController(text: widget.asset?['serialNumber'] ?? '');
    _locationController = TextEditingController(text: widget.asset?['location'] ?? '');
    _notesController = TextEditingController(text: widget.asset?['notes'] ?? '');
  }

  Future<void> _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      try {
        final assetData = {
          'id': widget.asset?['id'] ?? _uuid.v4(),
          'name': _nameController.text,
          'serialNumber': _serialNumberController.text,
          'location': _locationController.text,
          'notes': _notesController.text,
          'lastModified': DateTime.now().millisecondsSinceEpoch,
          'synced': 0,
        };

        await _offlineSyncService.saveOfflineData(
          assetData['id'] as String,
          assetData,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asset saved offline')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving asset: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asset == null ? 'Add Offline Asset' : 'Edit Offline Asset'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveAsset,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Asset Name*',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required field' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _serialNumberController,
              decoration: InputDecoration(
                labelText: 'Serial Number*',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required field' : null,
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
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialNumberController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
} 