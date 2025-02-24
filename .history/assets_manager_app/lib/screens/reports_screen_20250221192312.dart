import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/asset.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedReport = 'assets';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedReport,
                      decoration: InputDecoration(
                        labelText: 'Report Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'assets',
                          child: Text('Asset Inventory'),
                        ),
                        DropdownMenuItem(
                          value: 'maintenance',
                          child: Text('Maintenance History'),
                        ),
                        DropdownMenuItem(
                          value: 'assignments',
                          child: Text('Asset Assignments'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedReport = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: Icon(Icons.calendar_today),
                            label: Text(
                              DateFormat('MMM dd, yyyy').format(_startDate),
                            ),
                            onPressed: () => _selectDate(context, true),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextButton.icon(
                            icon: Icon(Icons.calendar_today),
                            label: Text(
                              DateFormat('MMM dd, yyyy').format(_endDate),
                            ),
                            onPressed: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.download),
                      label: Text('Generate Report'),
                      onPressed: _generateReport,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _buildReportPreview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPreview() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getReportStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return _buildReportContent(snapshot.data!.docs);
      },
    );
  }

  Stream<QuerySnapshot> _getReportStream() {
    switch (_selectedReport) {
      case 'assets':
        return _firestore.collection('assets').snapshots();
      case 'maintenance':
        return _firestore
            .collection('assets')
            .where('nextMaintenance', 
                isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
            .where('nextMaintenance', 
                isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
            .snapshots();
      case 'assignments':
        return _firestore
            .collection('assignments')
            .where('assignedDate', 
                isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
            .where('assignedDate', 
                isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
            .snapshots();
      default:
        return _firestore.collection('assets').snapshots();
    }
  }

  Widget _buildReportContent(List<DocumentSnapshot> docs) {
    switch (_selectedReport) {
      case 'assets':
        return _buildAssetReport(docs);
      case 'maintenance':
        return _buildMaintenanceReport(docs);
      case 'assignments':
        return _buildAssignmentReport(docs);
      default:
        return Container();
    }
  }

  Widget _buildAssetReport(List<DocumentSnapshot> docs) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final asset = Asset.fromFirestore(docs[index]);
        return Card(
          child: ListTile(
            title: Text(asset.name),
            subtitle: Text('Status: ${asset.status}'),
            trailing: Text('\$${asset.purchasePrice.toStringAsFixed(2)}'),
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceReport(List<DocumentSnapshot> docs) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final asset = Asset.fromFirestore(docs[index]);
        return Card(
          child: ListTile(
            title: Text(asset.name),
            subtitle: Text(
              'Next Maintenance: ${DateFormat('MMM dd, yyyy').format(asset.nextMaintenance)}',
            ),
            trailing: Icon(
              Icons.warning,
              color: asset.nextMaintenance.isBefore(DateTime.now())
                  ? Colors.red
                  : Colors.green,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentReport(List<DocumentSnapshot> docs) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final assignment = docs[index].data() as Map<String, dynamic>;
        return Card(
          child: ListTile(
            title: Text(assignment['assetName']),
            subtitle: Text('Assigned to: ${assignment['assignedTo']}'),
            trailing: Text(
              DateFormat('MMM dd, yyyy').format(
                (assignment['assignedDate'] as Timestamp).toDate(),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    try {
      final pdf = pw.Document();
      
      // Add report header
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Column(
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Asset Management Report'),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Report Type: $_selectedReport'),
                pw.Text(
                  'Period: ${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                ),
                pw.SizedBox(height: 20),
                // Add report content based on type
                // Implementation details coming in next part
              ],
            );
          },
        ),
      );

      // Save the PDF
      final output = await getTemporaryDirectory();
      final file = File(
        '${output.path}/report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to: ${file.path}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              // Implement file opening logic
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }
} 