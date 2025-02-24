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
  String _selectedReportType = 'Asset Summary';
  String _selectedCategory = 'All';
  String _selectedTimeFrame = 'All Time';
  bool _isGenerating = false;

  final List<String> _reportTypes = [
    'Asset Summary',
    'Maintenance Schedule',
    'Asset Valuation',
    'Category Distribution',
    'Status Distribution'
  ];

  final List<String> _categories = [
    'All',
    'Electronics',
    'Furniture',
    'Vehicles',
    'Tools',
    'Other'
  ];

  final List<String> _timeFrames = [
    'All Time',
    'This Month',
    'This Quarter',
    'This Year'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedReportType,
                      decoration: InputDecoration(
                        labelText: 'Report Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _reportTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedReportType = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTimeFrame,
                      decoration: InputDecoration(
                        labelText: 'Time Frame',
                        border: OutlineInputBorder(),
                      ),
                      items: _timeFrames.map((timeFrame) {
                        return DropdownMenuItem(
                          value: timeFrame,
                          child: Text(timeFrame),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTimeFrame = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : () => _generateReport(),
              icon: Icon(Icons.description),
              label: Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Recent Reports',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getReportsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final reports = snapshot.data!.docs;

                  if (reports.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_outlined, 
                               size: 64, 
                               color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No reports generated yet'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.description),
                          title: Text(report['type']),
                          subtitle: Text(
                            DateFormat('MMM dd, yyyy HH:mm')
                                .format(report['generatedAt'].toDate()),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.download),
                            onPressed: () => _downloadReport(report.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getReportsStream() {
    return _firestore
        .collection('reports')
        .orderBy('generatedAt', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final pdf = pw.Document();
      final assets = await _getFilteredAssets();

      // Add report header
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Asset Management Report',
                      style: pw.TextStyle(fontSize: 24)),
                ),
                pw.Paragraph(
                  text: 'Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                ),
                pw.Paragraph(
                  text: 'Report Type: $_selectedReportType',
                ),
                pw.Paragraph(
                  text: 'Category: $_selectedCategory',
                ),
                pw.Paragraph(
                  text: 'Time Frame: $_selectedTimeFrame',
                ),
                pw.SizedBox(height: 20),
                _buildReportContent(assets),
              ],
            );
          },
        ),
      );

      // Save the PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/report.pdf');
      await file.writeAsBytes(await pdf.save());

      // Save report metadata to Firestore
      await _firestore.collection('reports').add({
        'type': _selectedReportType,
        'category': _selectedCategory,
        'timeFrame': _selectedTimeFrame,
        'generatedAt': Timestamp.now(),
        'filePath': file.path,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report generated successfully')),
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

  Future<List<Asset>> _getFilteredAssets() async {
    Query query = _firestore.collection('assets');
    
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    final DateTime now = DateTime.now();
    if (_selectedTimeFrame != 'All Time') {
      DateTime startDate;
      switch (_selectedTimeFrame) {
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'This Quarter':
          startDate = DateTime(now.year, (now.month - 1) ~/ 3 * 3 + 1, 1);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(2000);
      }
      query = query.where('purchaseDate', isGreaterThanOrEqualTo: startDate);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Asset.fromFirestore(doc)).toList();
  }

  pw.Widget _buildReportContent(List<Asset> assets) {
    switch (_selectedReportType) {
      case 'Asset Summary':
        return _buildAssetSummary(assets);
      case 'Maintenance Schedule':
        return _buildMaintenanceSchedule(assets);
      case 'Asset Valuation':
        return _buildAssetValuation(assets);
      case 'Category Distribution':
        return _buildCategoryDistribution(assets);
      case 'Status Distribution':
        return _buildStatusDistribution(assets);
      default:
        return pw.Container();
    }
  }

  pw.Widget _buildAssetSummary(List<Asset> assets) {
    return pw.Table.fromTextArray(
      headers: ['Name', 'Category', 'Status', 'Location', 'Purchase Price'],
      data: assets.map((asset) => [
        asset.name,
        asset.category,
        asset.status,
        asset.location,
        '\$${asset.purchasePrice.toStringAsFixed(2)}',
      ]).toList(),
    );
  }

  // Implementation for other report types...
  pw.Widget _buildMaintenanceSchedule(List<Asset> assets) {
    // Implementation coming in next part
    return pw.Container();
  }

  pw.Widget _buildAssetValuation(List<Asset> assets) {
    // Implementation coming in next part
    return pw.Container();
  }

  pw.Widget _buildCategoryDistribution(List<Asset> assets) {
    // Implementation coming in next part
    return pw.Container();
  }

  pw.Widget _buildStatusDistribution(List<Asset> assets) {
    // Implementation coming in next part
    return pw.Container();
  }

  Future<void> _downloadReport(String reportId) async {
    // Implementation coming in next part
  }
} 