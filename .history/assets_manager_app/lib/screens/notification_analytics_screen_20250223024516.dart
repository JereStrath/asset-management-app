import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';  
import 'package:your_package_name/screens/asset_details_screen.dart';

class NotificationAnalyticsScreen extends StatefulWidget {
  @override
  _NotificationAnalyticsScreenState createState() => _NotificationAnalyticsScreenState();
}

class _NotificationAnalyticsScreenState extends State<NotificationAnalyticsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _timeRange = 'Week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Analytics'),
        actions: [
          DropdownButton<String>(
            value: _timeRange,
            items: ['Week', 'Month', 'Year'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _timeRange = newValue;
                });
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;
          final analytics = _processNotifications(notifications);

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildSummaryCards(analytics),
                _buildTypeChart(analytics),
                _buildTimeChart(analytics),
                _buildInteractionRateChart(analytics),
              ],
            ),
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getNotificationsStream() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_timeRange) {
      case 'Week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'Month':
        startDate = now.subtract(Duration(days: 30));
        break;
      case 'Year':
        startDate = now.subtract(Duration(days: 365));
        break;
      default:
        startDate = now.subtract(Duration(days: 7));
    }

    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('notifications')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Map<String, dynamic> _processNotifications(List<QueryDocumentSnapshot> notifications) {
    final types = <String, int>{};
    final timeDistribution = <DateTime, int>{};
    int totalInteractions = 0;
    int totalNotifications = notifications.length;

    for (var notification in notifications) {
      final data = notification.data() as Map<String, dynamic>;
      
      // Count by type
      final type = data['type'] as String;
      types[type] = (types[type] ?? 0) + 1;

      // Time distribution
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
      timeDistribution[date] = (timeDistribution[date] ?? 0) + 1;

      // Count interactions
      if (data['interacted'] == true) {
        totalInteractions++;
      }
    }

    return {
      'types': types,
      'timeDistribution': timeDistribution,
      'interactionRate': totalNotifications > 0 
          ? totalInteractions / totalNotifications 
          : 0.0,
      'total': totalNotifications,
    };
  }

  Widget _buildSummaryCards(Map<String, dynamic> analytics) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCard(
            'Total',
            analytics['total'].toString(),
            Icons.notifications,
          ),
          _buildSummaryCard(
            'Interaction Rate',
            '${(analytics['interactionRate'] * 100).toStringAsFixed(1)}%',
            Icons.touch_app,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 16)),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChart(Map<String, dynamic> analytics) {
    final types = analytics['types'] as Map<String, int>;
    final entries = types.entries.toList();
    
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: types.values.reduce((a, b) => a > b ? a : b).toDouble(),
          barGroups: entries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  color: Colors.blue,
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= entries.length) return Text('');
                  return Text(
                    entries[value.toInt()].key,
                    style: TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChart(Map<String, dynamic> analytics) {
    final timeData = analytics['timeDistribution'] as Map<DateTime, int>;
    final sortedData = timeData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: sortedData.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value.value.toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: true),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sortedData.length) return Text('');
                  return Text(
                    DateFormat('MM/dd').format(sortedData[value.toInt()].key),
                    style: TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionRateChart(Map<String, dynamic> analytics) {
    final interactionRate = analytics['interactionRate'] as double;
    
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: interactionRate * 100,
              title: '${(interactionRate * 100).toStringAsFixed(1)}%',
              color: Colors.blue,
            ),
            PieChartSectionData(
              value: (1 - interactionRate) * 100,
              title: '${((1 - interactionRate) * 100).toStringAsFixed(1)}%',
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
} 