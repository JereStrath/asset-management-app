import 'package:flutter/material.dart';

class SyncProgressIndicator extends StatelessWidget {
  final int totalItems;
  final int syncedItems;
  final bool isActive;
  final String? currentItemName;

  SyncProgressIndicator({
    required this.totalItems,
    required this.syncedItems,
    required this.isActive,
    this.currentItemName,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) return SizedBox.shrink();

    final progress = totalItems > 0 ? syncedItems / totalItems : 0.0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Syncing Assets...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text('$syncedItems/$totalItems'),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
          if (currentItemName != null) ...[
            SizedBox(height: 8),
            Text(
              'Syncing: $currentItemName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
} 