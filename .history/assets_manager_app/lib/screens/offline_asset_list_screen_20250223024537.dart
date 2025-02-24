import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/offline_status_indicator.dart';
import '../widgets/sync_progress_indicator.dart';
import '../widgets/conflict_resolution_dialog.dart';
import 'package:your_package_name/screens/asset_details_screen.dart';
class OfflineAssetListScreen extends StatefulWidget {
  @override
  _OfflineAssetListScreenState createState() => _OfflineAssetListScreenState();
}

class _OfflineAssetListScreenState extends State<OfflineAssetListScreen> {
  final _offlineSyncService = OfflineSyncService();
  List<Map<String, dynamic>> _offlineAssets = [];
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineAssets();
    _setupConflictResolutionListener();
  }

  void _setupConflictResolutionListener() {
    _offlineSyncService.conflictResolution.listen((request) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ConflictResolutionDialog(
          localVersion: request.localVersion,
          serverVersion: request.serverVersion,
          onResolve: (resolvedVersion) {
            request.completer.complete(resolvedVersion);
            Navigator.pop(context);
          },
        ),
      );
    });
  }

  Future<void> _loadOfflineAssets() async {
    final assets = await _offlineSyncService.getAllOfflineAssets();
    setState(() {
      _offlineAssets = assets;
    });
  }

  Future<void> _syncAssets() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _offlineSyncService.syncPendingChanges();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assets synced successfully')),
      );
      await _loadOfflineAssets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error syncing assets: $e')),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Offline Assets'),
        actions: [
          StreamBuilder<ConnectivityResult>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              final isOnline = snapshot.data != ConnectivityResult.none;
              return IconButton(
                icon: Icon(Icons.sync),
                onPressed: isOnline && !_isSyncing ? _syncAssets : null,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineStatusIndicator(),
          StreamBuilder<SyncProgress>(
            stream: _offlineSyncService.syncProgress,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.all(16),
                child: SyncProgressIndicator(
                  totalItems: snapshot.data!.total,
                  syncedItems: snapshot.data!.current,
                  isActive: _isSyncing,
                  currentItemName: snapshot.data!.currentItemName,
                ),
              );
            },
          ),
          Expanded(
            child: _offlineAssets.isEmpty
                ? Center(
                    child: Text('No offline assets available'),
                  )
                : ListView.builder(
                    itemCount: _offlineAssets.length,
                    itemBuilder: (context, index) {
                      final asset = _offlineAssets[index];
                      return OfflineAssetCard(
                        asset: asset,
                        onEdit: () => _editOfflineAsset(asset),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOfflineAsset(),
        child: Icon(Icons.add),
        tooltip: 'Add Offline Asset',
      ),
    );
  }

  Future<void> _editOfflineAsset(Map<String, dynamic> asset) async {
    // Navigate to edit screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfflineAssetEditScreen(asset: asset),
      ),
    );

    if (result == true) {
      await _loadOfflineAssets();
    }
  }

  Future<void> _addOfflineAsset() async {
    // Navigate to add screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfflineAssetEditScreen(),
      ),
    );

    if (result == true) {
      await _loadOfflineAssets();
    }
  }
}

class OfflineAssetCard extends StatelessWidget {
  final Map<String, dynamic> asset;
  final VoidCallback onEdit;

  OfflineAssetCard({
    required this.asset,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          asset['synced'] == 1 ? Icons.check_circle : Icons.pending,
          color: asset['synced'] == 1 ? Colors.green : Colors.orange,
        ),
        title: Text(asset['name'] ?? 'Unnamed Asset'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${asset['id']}'),
            Text(
              'Last Modified: ${DateTime.fromMillisecondsSinceEpoch(asset['lastModified']).toString()}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit),
          onPressed: onEdit,
        ),
        onTap: onEdit,
      ),
    );
  }
} 