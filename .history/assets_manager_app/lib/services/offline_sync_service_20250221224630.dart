import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  late Database _database;
  final _firestore = FirebaseFirestore.instance;
  final _connectivity = Connectivity();

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
    final pendingChanges = await _database.query('pending_changes');
    
    for (var change in pendingChanges) {
      try {
        final data = jsonDecode(change['data'] as String);
        final type = change['type'] as String;
        final id = change['id'] as String;

        switch (type) {
          case 'create':
            await _firestore.collection('assets').doc(id).set(data);
            break;
          case 'update':
            await _firestore.collection('assets').doc(id).update(data);
            break;
          case 'delete':
            await _firestore.collection('assets').doc(id).delete();
            break;
        }

        await _database.delete(
          'pending_changes',
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (e) {
        print('Error syncing change: $e');
      }
    }
  }
} 