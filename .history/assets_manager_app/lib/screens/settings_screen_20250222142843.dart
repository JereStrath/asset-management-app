import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<SharedPreferences> _prefs;
  
  bool _notificationEnabled = false;
  bool _darkModeEnabled = false;
  bool _maintenanceAlerts = true;
  bool _lowStockAlerts = true;
  String _currency = 'USD';
  String _dateFormat = 'MM/dd/yyyy';
  String _language = 'English';
  String _version = '1.0.0';
  
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'KSH', 'AUD'];
  final List<String> _dateFormats = [
    'MM/dd/yyyy',
    'dd/MM/yyyy',
    'yyyy-MM-dd',
    'dd-MM-yyyy'
  ];

  @override
  void initState() {
    super.initState();
    _prefs = SharedPreferences.getInstance();
    _loadSettings();
    _loadPackageInfo();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await _prefs;
      if (mounted) {
        setState(() {
          _notificationEnabled = prefs.getBool('notification_enabled') ?? false;
          _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;        _maintenanceAlerts = prefs.getBool('maintenanceAlerts') ?? true;
          _lowStockAlerts = prefs.getBool('lowStockAlerts') ?? true;
          _currency = prefs.getString('currency') ?? 'USD';
          _dateFormat = prefs.getString('dateFormat') ?? 'MM/dd/yyyy';
          _language = prefs.getString('language') ?? 'English';
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await _prefs;
      await prefs.setBool('notification_enabled', _notificationEnabled);
      await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
      await prefs.setBool('maintenanceAlerts', _maintenanceAlerts);
      await prefs.setBool('lowStockAlerts', _lowStockAlerts);
      await prefs.setString('currency', _currency);
      await prefs.setString('dateFormat', _dateFormat);
      await prefs.setString('language', _language);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Enable push notifications'),
              value: _notificationEnabled,
              onChanged: (bool newValue) async {
                setState(() {
                  _notificationEnabled = newValue;
                });
                if (newValue) {
                  await NotificationService.requestNotificationPermissions();
                }
                await _saveSettings();
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme'),
              value: _darkModeEnabled,
              onChanged: (bool newValue) async {
                setState(() {
                  _darkModeEnabled = newValue;
                });
                await _saveSettings();
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Language'),
              subtitle: Text(_language),
              trailing: DropdownButton<String>(
                value: _language,
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                  DropdownMenuItem(value: 'French', child: Text('French')),
                ],
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    setState(() {
                      _language = newValue;
                    });
                    await _saveSettings();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('About'),
              subtitle: Text('Version $_version'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Assets Manager',
                  applicationVersion: _version,
                  applicationLegalese: '©2024 Your Company',
                );
              },
            ),
          ),
          _buildSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: Text('Maintenance Alerts'),
                subtitle: Text('Get alerts for upcoming maintenance'),
                value: _maintenanceAlerts,
                onChanged: _notificationEnabled
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
                onChanged: _notificationEnabled
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