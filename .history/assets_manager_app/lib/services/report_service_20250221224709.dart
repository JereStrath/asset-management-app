import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final _firestore = FirebaseFirestore.instance;

  Future<File> generatePDFReport(String reportType, DateTime startDate, DateTime endDate) async {
    final pdf = pw.Document();
    final data = await _getReportData(reportType, startDate, endDate);

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Asset Management Report',
                style: pw.TextStyle(fontSize: 24)),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Period: ${DateFormat('MMM dd, yyyy').format(startDate)} - '
              '${DateFormat('MMM dd, yyyy').format(endDate)}'),
          pw.SizedBox(height: 20),
          _buildPDFTable(data),
          pw.SizedBox(height: 20),
          _buildPDFCharts(data),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> generateExcelReport(String reportType, DateTime startDate, DateTime endDate) async {
    final excel = Excel.createExcel();
    final sheet = excel['Report'];
    final data = await _getReportData(reportType, startDate, endDate);

    // Add headers
    sheet.insertRow(0, data['headers']);

    // Add data
    for (var i = 0; i < data['rows'].length; i++) {
      sheet.insertRow(i + 1, data['rows'][i]);
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  Future<File> generateCSVReport(String reportType, DateTime startDate, DateTime endDate) async {
    final data = await _getReportData(reportType, startDate, endDate);
    final csvData = [
      data['headers'],
      ...data['rows'],
    ];

    final csvString = const ListToCsvConverter().convert(csvData);
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvString);
    return file;
  }

  Future<Map<String, dynamic>> _getReportData(String reportType, DateTime startDate, DateTime endDate) async {
    final query = _firestore.collection('assets')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate);

    final snapshots = await query.get();
    final assets = snapshots.docs.map((doc) => doc.data()).toList();

    switch (reportType) {
      case 'inventory':
        return _processInventoryData(assets);
      case 'maintenance':
        return _processMaintenanceData(assets);
      case 'financial':
        return _processFinancialData(assets);
      default:
        return _processGeneralData(assets);
    }
  }

  pw.Widget _buildPDFTable(Map<String, dynamic> data) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: data['headers'].map<pw.Widget>((header) {
            return pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text(header),
            );
          }).toList(),
        ),
        ...data['rows'].map((row) {
          return pw.TableRow(
            children: row.map<pw.Widget>((cell) {
              return pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: pw.Text(cell.toString()),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  pw.Widget _buildPDFCharts(Map<String, dynamic> data) {
    // Implementation depends on the type of charts needed
    return pw.Container();
  }
} 