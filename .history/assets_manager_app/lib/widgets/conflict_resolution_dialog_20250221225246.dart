import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConflictResolutionDialog extends StatelessWidget {
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> serverVersion;
  final Function(Map<String, dynamic>) onResolve;

  ConflictResolutionDialog({
    required this.localVersion,
    required this.serverVersion,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Conflict Detected'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This asset has been modified both locally and on the server. '
              'Please choose which version to keep:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            _buildComparisonTable(context),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => onResolve(localVersion),
          child: Text('Keep Local'),
        ),
        TextButton(
          onPressed: () => onResolve(serverVersion),
          child: Text('Keep Server'),
        ),
        TextButton(
          onPressed: () => _showMergeDialog(context),
          child: Text('Merge Changes'),
        ),
      ],
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    return Table(
      border: TableBorder.all(),
      columnWidths: {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: [
            TableCell(child: Padding(
              padding: EdgeInsets.all(8),
              child: Text('Field'),
            )),
            TableCell(child: Padding(
              padding: EdgeInsets.all(8),
              child: Text('Local Version'),
            )),
            TableCell(child: Padding(
              padding: EdgeInsets.all(8),
              child: Text('Server Version'),
            )),
          ],
        ),
        ...['name', 'serialNumber', 'location', 'notes'].map((field) {
          final localValue = localVersion[field]?.toString() ?? '';
          final serverValue = serverVersion[field]?.toString() ?? '';
          final isDifferent = localValue != serverValue;

          return TableRow(
            decoration: BoxDecoration(
              color: isDifferent ? Colors.yellow.shade50 : null,
            ),
            children: [
              TableCell(child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(field),
              )),
              TableCell(child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(localValue),
              )),
              TableCell(child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(serverValue),
              )),
            ],
          );
        }).toList(),
        TableRow(
          children: [
            TableCell(child: Padding(
              padding: EdgeInsets.all(8),
              child: Text('Modified'),
            )),
            TableCell(child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(DateFormat('MMM dd, HH:mm').format(
                DateTime.fromMillisecondsSinceEpoch(localVersion['lastModified']),
              )),
            )),
            TableCell(child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(DateFormat('MMM dd, HH:mm').format(
                DateTime.fromMillisecondsSinceEpoch(serverVersion['lastModified']),
              )),
            )),
          ],
        ),
      ],
    );
  }

  void _showMergeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MergeChangesDialog(
        localVersion: localVersion,
        serverVersion: serverVersion,
        onMerge: onResolve,
      ),
    );
  }
}

class MergeChangesDialog extends StatefulWidget {
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> serverVersion;
  final Function(Map<String, dynamic>) onMerge;

  MergeChangesDialog({
    required this.localVersion,
    required this.serverVersion,
    required this.onMerge,
  });

  @override
  _MergeChangesDialogState createState() => _MergeChangesDialogState();
}

class _MergeChangesDialogState extends State<MergeChangesDialog> {
  late Map<String, String> selectedVersions;

  @override
  void initState() {
    super.initState();
    selectedVersions = {
      'name': 'local',
      'serialNumber': 'local',
      'location': 'local',
      'notes': 'local',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Merge Changes'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...['name', 'serialNumber', 'location', 'notes'].map((field) {
              return _buildFieldSelector(field);
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _mergeChanges,
          child: Text('Merge'),
        ),
      ],
    );
  }

  Widget _buildFieldSelector(String field) {
    final localValue = widget.localVersion[field]?.toString() ?? '';
    final serverValue = widget.serverVersion[field]?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field, style: TextStyle(fontWeight: FontWeight.bold)),
        RadioListTile<String>(
          title: Text('Local: $localValue'),
          value: 'local',
          groupValue: selectedVersions[field],
          onChanged: (value) {
            setState(() {
              selectedVersions[field] = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: Text('Server: $serverValue'),
          value: 'server',
          groupValue: selectedVersions[field],
          onChanged: (value) {
            setState(() {
              selectedVersions[field] = value!;
            });
          },
        ),
        Divider(),
      ],
    );
  }

  void _mergeChanges() {
    final mergedVersion = Map<String, dynamic>.from(widget.localVersion);
    selectedVersions.forEach((field, version) {
      mergedVersion[field] = version == 'local'
          ? widget.localVersion[field]
          : widget.serverVersion[field];
    });
    mergedVersion['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    widget.onMerge(mergedVersion);
    Navigator.pop(context); // Close merge dialog
    Navigator.pop(context); // Close conflict dialog
  }
} 