import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SharedPreferences _prefs = await SharedPreferences.getInstance();
  
  bool _darkMode = false;
  bool _notifications = true;
  bool _maintenanceAlerts = true;
  bool _lowStockAlerts = true;
  String _currency = 'USD';
  String _dateFormat = 'MM/dd/yyyy';
  String _appVersion = '';
  
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD'];
  final List<String> _dateFormats = [
    'MM/dd/yyyy',
    'dd/MM/yyyy',
    'yyyy-MM-dd',
    'dd-MM-yyyy'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _darkMode = _prefs.getBool('darkMode') ?? false;
      _notifications = _prefs.getBool('notifications') ?? true;
      _maintenanceAlerts = _prefs.getBool('maintenanceAlerts') ?? true;
      _lowStockAlerts = _prefs.getBool('lowStockAlerts') ?? true;
      _currency = _prefs.getString('currency') ?? 'USD';
      _dateFormat = _prefs.getString('dateFormat') ?? 'MM/dd/yyyy';
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('darkMode', _darkMode);
    await _prefs.setBool('notifications', _notifications);
    await _prefs.setBool('maintenanceAlerts', _maintenanceAlerts);
    await _prefs.setBool('lowStockAlerts', _lowStockAlerts);
    await _prefs.setString('currency', _currency);
    await _prefs.setString('dateFormat', _dateFormat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Appearance',
            children: [
              SwitchListTile(
                title: Text('Dark Mode'),
                subtitle: Text('Enable dark theme'),
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                    _saveSettings();
                  });
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: Text('Enable Notifications'),
                subtitle: Text('Receive push notifications'),
                value: _notifications,
                onChanged: (value) {
                  setState(() {
                    _notifications = value;
                    _saveSettings();
                  });
                },
              ),
              SwitchListTile(
                title: Text('Maintenance Alerts'),
                subtitle: Text('Get alerts for upcoming maintenance'),
                value: _maintenanceAlerts,
                enabled: _notifications,
                onChanged: _notifications
                    ? (value) {
                        setState(() {
                          _maintenanceAlerts = value;
                          _saveSettings();
                        });
                      }
                    : null,
              ),
              SwitchListTile(
                title: Text('Low Stock Alerts'),
                subtitle: Text('Get alerts for low inventory'),
                value: _lowStockAlerts,
                enabled: _notifications,
                onChanged: _notifications
                    ? (value) {
                        setState(() {
                          _lowStockAlerts = value;
                          _saveSettings();
                        });
                      }
                    : null,
              ),
            ],
          ),
          _buildSection(
            title: 'Regional Settings',
            children: [
              ListTile(
                title: Text('Currency'),
                subtitle: Text(_currency),
                trailing: DropdownButton<String>(
                  value: _currency,
                  items: _currencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _currency = value!;
                      _saveSettings();
                    });
                  },
                ),
              ),
              ListTile(
                title: Text('Date Format'),
                subtitle: Text(_dateFormat),
                trailing: DropdownButton<String>(
                  value: _dateFormat,
                  items: _dateFormats.map((format) {
                    return DropdownMenuItem(
                      value: format,
                      child: Text(format),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _dateFormat = value!;
                      _saveSettings();
                    });
                  },
                ),
              ),
            ],
          ),
          _buildSection(
            title: 'Account',
            children: [
              ListTile(
                title: Text('Change Password'),
                leading: Icon(Icons.lock_outline),
                onTap: () => _showChangePasswordDialog(context),
              ),
              ListTile(
                title: Text('Export Data'),
                leading: Icon(Icons.download_outlined),
                onTap: () => _exportData(),
              ),
              ListTile(
                title: Text('Delete Account'),
                leading: Icon(Icons.delete_outline),
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ),
          _buildSection(
            title: 'About',
            children: [
              ListTile(
                title: Text('Version'),
                subtitle: Text(_appVersion),
              ),
              ListTile(
                title: Text('Terms of Service'),
                onTap: () => _showTermsOfService(context),
              ),
              ListTile(
                title: Text('Privacy Policy'),
                onTap: () => _showPrivacyPolicy(context),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _signOut(context),
              child: Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...children,
        Divider(),
      ],
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              try {
                final user = _auth.currentUser!;
                await user.updatePassword(newPasswordController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating password: $e')),
                );
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    // Implementation for data export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data export started...')),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = _auth.currentUser!;
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
        await _signOut(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  void _showTermsOfService(BuildContext context) {
    // Implementation for showing terms of service
  }

  void _showPrivacyPolicy(BuildContext context) {
    // Implementation for showing privacy policy
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }
} 