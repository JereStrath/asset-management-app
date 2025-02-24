import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/notification_service.dart';
import 'package:your_package_name/screens/asset_details_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<SharedPreferences> _prefs;
  
  bool _notificationsEnabled = false;
  bool _darkModeEnabled = false;
  bool _maintenanceAlerts = true;
  bool _lowStockAlerts = true;
  String _currency = 'USD';
  String _dateFormat = 'MM/dd/yyyy';
  String _selectedLanguage = 'English';
  String _appVersion = '1.0.0';
  
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
          _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
          _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
          _maintenanceAlerts = prefs.getBool('maintenanceAlerts') ?? true;
          _lowStockAlerts = prefs.getBool('lowStockAlerts') ?? true;
          _currency = prefs.getString('currency') ?? 'USD';
          _dateFormat = prefs.getString('dateFormat') ?? 'MM/dd/yyyy';
          _selectedLanguage = prefs.getString('selected_language') ?? 'English';
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
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await _prefs;
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
      await prefs.setBool('maintenanceAlerts', _maintenanceAlerts);
      await prefs.setBool('lowStockAlerts', _lowStockAlerts);
      await prefs.setString('currency', _currency);
      await prefs.setString('dateFormat', _dateFormat);
      await prefs.setString('selected_language', _selectedLanguage);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: Text('Settings Page Content Here'),
      ),
    );
  }
} 