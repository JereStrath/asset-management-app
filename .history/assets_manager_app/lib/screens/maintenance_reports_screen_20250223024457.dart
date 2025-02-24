import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:your_package_name/screens/asset_details_screen.dart';
class MaintenanceReportsScreen extends StatefulWidget {
  @override
  _MaintenanceReportsScreenState createState() => _MaintenanceReportsScreenState();
}

class _MaintenanceReportsScreenState extends State<MaintenanceReportsScreen> {
  final _firestore = FirebaseFirestore.instance;
  DateTime? _startDate;
  DateTime? _endDate;
  String _reportType = 'All';

  final List<String> _reportTypes = [
    'All',
    'Completed',
    'Pending',
    'Overdue',
    'Cost Analysis',
  ];

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<Map<String, dynamic>> _getMaintenanceStats() async {
    final query = _firestore.collection('maintenanceSchedules')
        .where('scheduledDate', isGreaterThanOrEqualTo: _startDate)
        .where('scheduledDate', isLessThanOrEqualTo: _endDate);

    final snapshots = await query.get();
    final records = snapshots.docs;

    return {
      'total': records.length,
      'completed': records.where((r) => r.data()['status'] == 'COMPLETED').length,
      'pending': records.where((r) => r.data()['status'] == 'SCHEDULED').length,
      'overdue': records.where((r) {
        final scheduled = (r.data()['scheduledDate'] as Timestamp).toDate();
        return r.data()['status'] != 'COMPLETED' && scheduled.isBefore(DateTime.now());
      }).length,
      'totalCost': records
          .where((r) => r.data()['completion'] != null)
          .fold(0.0, (sum, r) => sum + (r.data()['completion']['actualCost'] ?? 0.0)),
    };
  }

  Future<void> _generatePDFReport() async {
    final stats = await _getMaintenanceStats();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Maintenance Report',
                    style: pw.TextStyle(fontSize: 24)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Period: ${DateFormat('MMM dd, yyyy').format(_startDate!)} - '
                  '${DateFormat('MMM dd, yyyy').format(_endDate!)}'),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Total Maintenance'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('${stats['total']}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Completed'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('${stats['completed']}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Pending'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('${stats['pending']}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Overdue'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('${stats['overdue']}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Total Cost'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('\$${stats['totalCost'].toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maintenance Reports'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: _startDate != null ? _generatePDFReport : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _startDate == null
                        ? 'Select date range'
                        : '${DateFormat('MMM dd, yyyy').format(_startDate!)} - '
                            '${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                DropdownButton<String>(
                  value: _reportType,
                  items: _reportTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _reportType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _startDate == null
                ? Center(child: Text('Select a date range to view reports'))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('maintenanceSchedules')
                        .where('scheduledDate',
                            isGreaterThanOrEqualTo: _startDate)
                        .where('scheduledDate', isLessThanOrEqualTo: _endDate)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final records = snapshot.data!.docs;
                      final filteredRecords = _filterRecords(records);

                      return ListView.builder(
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index].data() as Map<String, dynamic>;
                          return MaintenanceRecordCard(record: record);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generatePDFReport,
        child: Icon(Icons.download),
        tooltip: 'Generate Report',
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterRecords(List<QueryDocumentSnapshot> records) {
    switch (_reportType) {
      case 'Completed':
        return records.where((r) => r.get('status') == 'COMPLETED').toList();
      case 'Pending':
        return records.where((r) => r.get('status') == 'SCHEDULED').toList();
      case 'Overdue':
        return records.where((r) {
          final scheduled = (r.get('scheduledDate') as Timestamp).toDate();
          return r.get('status') != 'COMPLETED' && scheduled.isBefore(DateTime.now());
        }).toList();
      case 'Cost Analysis':
        return records.where((r) => r.get('completion') != null).toList();
      default:
        return records;
    }
  }
}

class MaintenanceRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;

  MaintenanceRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final scheduledDate = (record['scheduledDate'] as Timestamp).toDate();
    final status = record['status'];
    final completion = record['completion'];

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(record['assetName']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scheduled: ${DateFormat('MMM dd, yyyy').format(scheduledDate)}'),
            Text('Status: $status'),
            if (completion != null)
              Text('Cost: \$${completion['actualCost'].toStringAsFixed(2)}'),
          ],
        ),
        trailing: Icon(_getStatusIcon(status)),
        onTap: () => _showDetails(context),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'COMPLETED':
        return Icons.check_circle;
      case 'SCHEDULED':
        return Icons.schedule;
      default:
        return Icons.warning;
    }
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Maintenance Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Asset: ${record['assetName']}'),
              Text('Type: ${record['maintenanceType']}'),
              Text('Description: ${record['description']}'),
              if (record['completion'] != null) ...[
                Divider(),
                Text('Completion Details:'),
                Text('Work Done: ${record['completion']['workDone']}'),
                Text('Cost: \$${record['completion']['actualCost'].toStringAsFixed(2)}'),
                Text('Outcome: ${record['completion']['outcome']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
} 