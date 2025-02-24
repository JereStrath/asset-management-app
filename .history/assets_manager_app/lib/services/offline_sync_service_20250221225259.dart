import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SyncProgress {
  final int total;
  final int current;
  final String? currentItemName;

  SyncProgress(this.total, this.current, this.currentItemName);
}

class ConflictResolutionRequest {
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> serverVersion;
  final Completer<Map<String, dynamic>?> completer;

  ConflictResolutionRequest(this.localVersion, this.serverVersion, this.completer);
}

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  late Database _database;
  final _firestore = FirebaseFirestore.instance;
  final _connectivity = Connectivity();

  // Add stream controller for sync progress
  final _syncProgressController = StreamController<SyncProgress>.broadcast();
  Stream<SyncProgress> get syncProgress => _syncProgressController.stream;

  // Add stream controller for conflict resolution
  final _conflictResolutionController = StreamController<ConflictResolutionRequest>.broadcast();
  Stream<ConflictResolutionRequest> get conflictResolution => _conflictResolutionController.stream;

  Future<void> initialize() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'asset_manager.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE assets(
            id TEXT PRIMARY KEY,
            data TEXT,
            synced INTEGER,
            lastModified INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_changes(
            id TEXT PRIMARY KEY,
            type TEXT,
            data TEXT,
            timestamp INTEGER
          )
        ''');
      },
      version: 1,
    );

    // Start listening to connectivity changes
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    if (result != ConnectivityResult.none) {
      await syncPendingChanges();
    }
  }

  Future<void> saveOfflineData(String id, Map<String, dynamic> data) async {
    await _database.insert(
      'assets',
      {
        'id': id,
        'data': jsonEncode(data),
        'synced': 0,
        'lastModified': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getOfflineData(String id) async {
    final result = await _database.query(
      'assets',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return jsonDecode(result.first['data'] as String);
    }
    return null;
  }

  Future<void> syncPendingChanges() async {
    final pendingChanges = await _database.query('assets',
        where: 'synced = ?', whereArgs: [0]);

    _syncProgressController.add(
        SyncProgress(pendingChanges.length, 0, null));

    for (var i = 0; i < pendingChanges.length; i++) {
      final change = pendingChanges[i];
      final localData = jsonDecode(change['data'] as String);
      
      try {
        // Check for conflicts
        final serverDoc = await _firestore
            .collection('assets')
            .doc(change['id'] as String)
            .get();

        if (serverDoc.exists) {
          final serverData = serverDoc.data()!;
          if (serverData['lastModified'] > localData['lastModified']) {
            // Conflict detected
            final resolution = await _handleConflict(localData, serverData);
            if (resolution != null) {
              await _firestore
                  .collection('assets')
                  .doc(change['id'] as String)
                  .set(resolution);
            }
          } else {
            // No conflict, update server
            await _firestore
                .collection('assets')
                .doc(change['id'] as String)
                .set(localData);
          }
        } else {
          // New document, create on server
          await _firestore
              .collection('assets')
              .doc(change['id'] as String)
              .set(localData);
        }

        // Update local sync status
        await _database.update(
          'assets',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [change['id']],
        );

        _syncProgressController.add(
            SyncProgress(pendingChanges.length, i + 1, localData['name']));
      } catch (e) {
        print('Error syncing asset ${change['id']}: $e');
        // Continue with next item
      }
    }
  }

  Future<Map<String, dynamic>?> _handleConflict(
    Map<String, dynamic> localVersion,
    Map<String, dynamic> serverVersion,
  ) async {
    final completer = Completer<Map<String, dynamic>?>();
    
    // This needs to be handled in the UI layer
    _conflictResolutionController.add(
      ConflictResolutionRequest(
        localVersion,
        serverVersion,
        completer,
      ),
    );

    return await completer.future;
  }
} 