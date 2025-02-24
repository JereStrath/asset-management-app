import 'package:flutter/material.dart';
import '../services/report_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class ReportGenerationScreen extends StatefulWidget {
  @override
  _ReportGenerationScreenState createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  final _reportService = ReportService();
  String _selectedReportType = 'general';
  String _selectedFormat = 'pdf';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;

  final _reportTypes = {
    'general': 'General Asset Report',
    'inventory': 'Inventory Report',
    'maintenance': 'Maintenance Report',
    'financial': 'Financial Report',
  };

  final _exportFormats = {
    'pdf': 'PDF',
    'excel': 'Excel',
    'csv': 'CSV',
  };

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final file = switch (_selectedFormat) {
        'pdf' => await _reportService.generatePDFReport(
            _selectedReportType, _startDate, _endDate),
        'excel' => await _reportService.generateExcelReport(
            _selectedReportType, _startDate, _endDate),
        'csv' => await _reportService.generateCSVReport(
            _selectedReportType, _startDate, _endDate),
        _ => throw Exception('Unsupported format'),
      };

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Asset Management Report',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Report'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedReportType,
                      items: _reportTypes.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedReportType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    ListTile(
                      title: Text(
                        '${DateFormat('MMM dd, yyyy').format(_startDate)} - '
                        '${DateFormat('MMM dd, yyyy').format(_endDate)}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: _selectDateRange,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Format',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedFormat,
                      items: _exportFormats.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFormat = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateReport,
              child: _isGenerating
                  ? CircularProgressIndicator()
                  : Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 