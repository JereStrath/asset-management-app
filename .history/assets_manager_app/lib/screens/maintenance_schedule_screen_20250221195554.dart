import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';

class MaintenanceScheduleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }

  void _scheduleNewMaintenance(BuildContext context) {
    final TextEditingController dateController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule Maintenance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Select Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (picked != null) {
                  selectedDate = picked;
                  dateController.text = DateFormat('MMM dd, yyyy').format(picked);
                }
              },
            ),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Maintenance Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implementation for saving the maintenance schedule
              Navigator.pop(context);
            },
            child: Text('Schedule'),
          ),
        ],
      ),
    );
  }
}