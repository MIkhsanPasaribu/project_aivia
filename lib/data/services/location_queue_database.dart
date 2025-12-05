import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:project_aivia/data/models/location.dart' as models;

/// Local SQLite database untuk offline location queue
///
/// Purpose: Store locations saat no network, auto-sync when online
/// Best Practice: Offline-first architecture untuk prevent data loss
class LocationQueueDatabase {
  static const String databaseName = 'aivia_location_queue.db';
  static const int databaseVersion = 1;
  static const String tableName = 'location_queue';

  // Singleton pattern
  static LocationQueueDatabase? _instance;
  static Database? _database;

  LocationQueueDatabase._();

  factory LocationQueueDatabase() {
    _instance ??= LocationQueueDatabase._();
    return _instance!;
  }

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database dengan schema
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create table schema
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        altitude REAL,
        speed REAL,
        heading REAL,
        battery_level INTEGER,
        is_background INTEGER NOT NULL DEFAULT 0,
        timestamp TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_retry_at TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_patient_id (patient_id),
        INDEX idx_synced (synced),
        INDEX idx_timestamp (timestamp)
      )
    ''');
  }

  /// Handle database upgrades (future migrations)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations akan ditambahkan di sini
  }

  /// Insert location to queue
  Future<int> insert(QueuedLocation location) async {
    final db = await database;
    return await db.insert(
      tableName,
      location.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all unsynced locations (synced = 0, retry_count < max)
  Future<List<QueuedLocation>> getUnsynced({int maxRetries = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'synced = ? AND retry_count < ?',
      whereArgs: [0, maxRetries],
      orderBy: 'timestamp ASC', // Oldest first
      limit: 100, // Batch size
    );

    return List.generate(maps.length, (i) => QueuedLocation.fromMap(maps[i]));
  }

  /// Get failed locations (retry_count >= max)
  Future<List<QueuedLocation>> getFailedLocations({int maxRetries = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'synced = ? AND retry_count >= ?',
      whereArgs: [0, maxRetries],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => QueuedLocation.fromMap(maps[i]));
  }

  /// Mark location as synced
  Future<void> markSynced(int id) async {
    final db = await database;
    await db.update(
      tableName,
      {'synced': 1, 'last_retry_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Increment retry count
  Future<void> incrementRetry(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $tableName SET retry_count = retry_count + 1, '
      'last_retry_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  /// Delete synced locations (cleanup)
  Future<int> deleteSynced() async {
    final db = await database;
    return await db.delete(tableName, where: 'synced = ?', whereArgs: [1]);
  }

  /// Delete old locations (older than X days)
  Future<int> deleteOlderThan(Duration duration) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(duration).toIso8601String();

    return await db.delete(
      tableName,
      where: 'timestamp < ?',
      whereArgs: [cutoffDate],
    );
  }

  /// Get queue statistics
  Future<QueueStats> getStats() async {
    final db = await database;

    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
    );

    final unsynced = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE synced = 0'),
    );

    final failed = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE synced = 0 AND retry_count >= 5',
      ),
    );

    return QueueStats(
      total: total ?? 0,
      unsynced: unsynced ?? 0,
      synced: (total ?? 0) - (unsynced ?? 0),
      failed: failed ?? 0,
    );
  }

  /// Clear all data (testing only)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(tableName);
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

/// Model untuk queued location di local database
class QueuedLocation {
  final int? id; // Local DB ID
  final String patientId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final int? batteryLevel;
  final bool isBackground;
  final DateTime timestamp;
  final bool synced;
  final int retryCount;
  final DateTime? lastRetryAt;
  final DateTime createdAt;

  QueuedLocation({
    this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.batteryLevel,
    this.isBackground = false,
    required this.timestamp,
    this.synced = false,
    this.retryCount = 0,
    this.lastRetryAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from Location model
  factory QueuedLocation.fromLocation(
    models.Location location, {
    double? altitude,
    double? speed,
    double? heading,
    int? batteryLevel,
    bool isBackground = false,
  }) {
    return QueuedLocation(
      patientId: location.patientId,
      latitude: location.latitude,
      longitude: location.longitude,
      accuracy: location.accuracy,
      altitude: altitude,
      speed: speed,
      heading: heading,
      batteryLevel: batteryLevel,
      isBackground: isBackground,
      timestamp: location.timestamp,
    );
  }

  /// Convert to Map untuk database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'battery_level': batteryLevel,
      'is_background': isBackground ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced ? 1 : 0,
      'retry_count': retryCount,
      'last_retry_at': lastRetryAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from Map (database result)
  factory QueuedLocation.fromMap(Map<String, dynamic> map) {
    return QueuedLocation(
      id: map['id'] as int?,
      patientId: map['patient_id'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      accuracy: map['accuracy'] as double?,
      altitude: map['altitude'] as double?,
      speed: map['speed'] as double?,
      heading: map['heading'] as double?,
      batteryLevel: map['battery_level'] as int?,
      isBackground: (map['is_background'] as int) == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
      synced: (map['synced'] as int) == 1,
      retryCount: map['retry_count'] as int,
      lastRetryAt: map['last_retry_at'] != null
          ? DateTime.parse(map['last_retry_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to Location model untuk Supabase sync
  Map<String, dynamic> toSupabaseMap() {
    return {
      'patient_id': patientId,
      'coordinates': 'POINT($longitude $latitude)', // PostGIS format
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'battery_level': batteryLevel,
      'is_background': isBackground,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Statistics untuk monitoring queue
class QueueStats {
  final int total;
  final int unsynced;
  final int synced;
  final int failed;

  QueueStats({
    required this.total,
    required this.unsynced,
    required this.synced,
    required this.failed,
  });

  @override
  String toString() {
    return 'QueueStats(total: $total, unsynced: $unsynced, synced: $synced, failed: $failed)';
  }
}
