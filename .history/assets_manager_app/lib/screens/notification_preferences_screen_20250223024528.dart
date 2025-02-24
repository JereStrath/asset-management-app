import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';
import '../services/notification_service.dart';
import 'package:your_package_name/screens/asset_details_screen.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  @override
  _NotificationPreferencesScreenState createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final _prefs = SharedPreferences.getInstance();
  bool _weekBefore = true;
  bool _dayBefore = true;
  bool _dayOf = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  TimeOfDay _notificationTime = TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefs;
    setState(() {
      _weekBefore = prefs.getBool('notify_week_before') ?? true;
      _dayBefore = prefs.getBool('notify_day_before') ?? true;
      _dayOf = prefs.getBool('notify_day_of') ?? true;
      _emailNotifications = prefs.getBool('notify_email') ?? true;
      _pushNotifications = prefs.getBool('notify_push') ?? true;
      final hour = prefs.getInt('notify_time_hour') ?? 9;
      final minute = prefs.getInt('notify_time_minute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await _prefs;
    await prefs.setBool('notify_week_before', _weekBefore);
    await prefs.setBool('notify_day_before', _dayBefore);
    await prefs.setBool('notify_day_of', _dayOf);
    await prefs.setBool('notify_email', _emailNotifications);
    await prefs.setBool('notify_push', _pushNotifications);
    await prefs.setInt('notify_time_hour', _notificationTime.hour);
    await prefs.setInt('notify_time_minute', _notificationTime.minute);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preferences saved')),
    );
  }

  Future<void> _selectNotificationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Preferences'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePreferences,
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Notification Time'),
            subtitle: Text(_notificationTime.format(context)),
            trailing: Icon(Icons.access_time),
            onTap: _selectNotificationTime,
          ),
          Divider(),
          SwitchListTile(
            title: Text('Week Before'),
            subtitle: Text('Notify 7 days before maintenance'),
            value: _weekBefore,
            onChanged: (value) {
              setState(() {
                _weekBefore = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Day Before'),
            subtitle: Text('Notify 1 day before maintenance'),
            value: _dayBefore,
            onChanged: (value) {
              setState(() {
                _dayBefore = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Day Of'),
            subtitle: Text('Notify on the day of maintenance'),
            value: _dayOf,
            onChanged: (value) {
              setState(() {
                _dayOf = value;
              });
            },
          ),
          Divider(),
          SwitchListTile(
            title: Text('Email Notifications'),
            subtitle: Text('Receive email notifications'),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Push Notifications'),
            subtitle: Text('Receive push notifications'),
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
        ],
      ),
    );
  }
} 