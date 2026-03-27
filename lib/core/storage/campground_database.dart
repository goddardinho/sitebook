import 'dart:convert';
import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../../shared/models/campground.dart';

/// SQLite database for offline campground storage
class CampgroundDatabase {
  static const String _databaseName = 'sitebook_campgrounds.db';
  static const int _databaseVersion = 1;
  
  // Table names
  static const String _campgroundsTable = 'campgrounds';
  
  Database? _database;
  final Logger _logger = Logger();

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    _logger.i('Initializing database at: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creating database tables');

    await db.execute('''
      CREATE TABLE $_campgroundsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        state TEXT NOT NULL,
        park_name TEXT,
        reservation_url TEXT,
        phone_number TEXT,
        email TEXT,
        amenities TEXT NOT NULL,
        activities TEXT NOT NULL,
        image_urls TEXT NOT NULL,
        is_monitored INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        sync_timestamp INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_campgrounds_state ON $_campgroundsTable (state)');
    await db.execute('CREATE INDEX idx_campgrounds_monitored ON $_campgroundsTable (is_monitored)');
    await db.execute('CREATE INDEX idx_campgrounds_location ON $_campgroundsTable (latitude, longitude)');
    await db.execute('CREATE INDEX idx_campgrounds_name ON $_campgroundsTable (name)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Upgrading database from version $oldVersion to $newVersion');
    
    // Handle future database schema changes here
    if (oldVersion < 2) {
      // Example: Add new columns in version 2
      // await db.execute('ALTER TABLE $_campgroundsTable ADD COLUMN new_field TEXT');
    }
  }

  /// Save a single campground to database
  Future<void> saveCampground(Campground campground) async {
    try {
      final db = await database;
      await db.insert(
        _campgroundsTable,
        _campgroundToMap(campground),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.d('Saved campground: ${campground.name}');
    } catch (e) {
      _logger.e('Error saving campground ${campground.id}', error: e);
      rethrow;
    }
  }

  /// Save multiple campgrounds to database
  Future<void> saveCampgrounds(List<Campground> campgrounds) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final campground in campgrounds) {
        batch.insert(
          _campgroundsTable,
          _campgroundToMap(campground),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      _logger.i('Saved ${campgrounds.length} campgrounds to database');
    } catch (e) {
      _logger.e('Error saving campgrounds batch', error: e);
      rethrow;
    }
  }

  /// Get all campgrounds from database
  Future<List<Campground>> getAllCampgrounds() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(_campgroundsTable);
      return maps.map((map) => _mapToCampground(map)).toList();
    } catch (e) {
      _logger.e('Error getting all campgrounds', error: e);
      return [];
    }
  }

  /// Get campgrounds by state
  Future<List<Campground>> getCampgroundsByState(String stateCode) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _campgroundsTable,
        where: 'state = ?',
        whereArgs: [stateCode],
        orderBy: 'name ASC',
      );
      return maps.map((map) => _mapToCampground(map)).toList();
    } catch (e) {
      _logger.e('Error getting campgrounds for state $stateCode', error: e);
      return [];
    }
  }

  /// Get campground by ID
  Future<Campground?> getCampgroundById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _campgroundsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return _mapToCampground(maps.first);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting campground by ID $id', error: e);
      return null;
    }
  }

  /// Search campgrounds by text query
  Future<List<Campground>> searchByQuery(String query) async {
    try {
      final db = await database;
      final searchTerm = '%${query.toLowerCase()}%';
      
      final List<Map<String, dynamic>> maps = await db.query(
        _campgroundsTable,
        where: '''
          LOWER(name) LIKE ? OR 
          LOWER(description) LIKE ? OR 
          LOWER(state) LIKE ? OR 
          LOWER(park_name) LIKE ?
        ''',
        whereArgs: [searchTerm, searchTerm, searchTerm, searchTerm],
        orderBy: 'name ASC',
      );

      return maps.map((map) => _mapToCampground(map)).toList();
    } catch (e) {
      _logger.e('Error searching campgrounds with query: $query', error: e);
      return [];
    }
  }

  /// Search campgrounds near a location
  Future<List<Campground>> searchNearby({
    required double latitude,
    required double longitude,
    required double radiusMiles,
    String? stateFilter,
  }) async {
    try {
      final db = await database;
      
      // Convert miles to degrees (rough approximation)
      // 1 degree ≈ 69 miles, but we'll use a simple bounding box
      final latDelta = radiusMiles / 69.0;
      final lonDelta = radiusMiles / 69.0;
      
      final minLat = latitude - latDelta;
      final maxLat = latitude + latDelta;
      final minLon = longitude - lonDelta;
      final maxLon = longitude + lonDelta;

      String whereClause = '''
        latitude BETWEEN ? AND ? AND 
        longitude BETWEEN ? AND ?
      ''';
      List<dynamic> whereArgs = [minLat, maxLat, minLon, maxLon];

      if (stateFilter != null) {
        whereClause += ' AND state = ?';
        whereArgs.add(stateFilter);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        _campgroundsTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'name ASC',
      );

      // Filter by actual distance and sort by proximity
      final results = maps.map((map) => _mapToCampground(map)).toList();
      
      results.removeWhere((campground) {
        final distance = _calculateDistance(
          latitude, longitude,
          campground.latitude, campground.longitude,
        );
        return distance > radiusMiles;
      });

      // Sort by distance
      results.sort((a, b) {
        final distanceA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
        final distanceB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
        return distanceA.compareTo(distanceB);
      });

      return results;
    } catch (e) {
      _logger.e('Error searching nearby campgrounds', error: e);
      return [];
    }
  }

  /// Get monitored campgrounds
  Future<List<Campground>> getMonitoredCampgrounds() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _campgroundsTable,
        where: 'is_monitored = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return maps.map((map) => _mapToCampground(map)).toList();
    } catch (e) {
      _logger.e('Error getting monitored campgrounds', error: e);
      return [];
    }
  }

  /// Update campground monitoring status
  Future<void> updateMonitoringStatus(String campgroundId, bool isMonitored) async {
    try {
      final db = await database;
      await db.update(
        _campgroundsTable,
        {'is_monitored': isMonitored ? 1 : 0},
        where: 'id = ?',
        whereArgs: [campgroundId],
      );
    } catch (e) {
      _logger.e('Error updating monitoring status for $campgroundId', error: e);
      rethrow;
    }
  }

  /// Delete campground from database
  Future<void> deleteCampground(String campgroundId) async {
    try {
      final db = await database;
      await db.delete(
        _campgroundsTable,
        where: 'id = ?',
        whereArgs: [campgroundId],
      );
    } catch (e) {
      _logger.e('Error deleting campground $campgroundId', error: e);
      rethrow;
    }
  }

  /// Clear all cached campgrounds
  Future<void> clearCache() async {
    try {
      final db = await database;
      await db.delete(_campgroundsTable);
      _logger.i('Cleared campground cache');
    } catch (e) {
      _logger.e('Error clearing campground cache', error: e);
      rethrow;
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getStats() async {
    try {
      final db = await database;
      
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_campgroundsTable');
      final monitoredResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_campgroundsTable WHERE is_monitored = 1'
      );
      
      return {
        'total': totalResult.first['count'] as int,
        'monitored': monitoredResult.first['count'] as int,
      };
    } catch (e) {
      _logger.e('Error getting database stats', error: e);
      return {'total': 0, 'monitored': 0};
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Private helper methods

  /// Convert Campground model to database map
  Map<String, dynamic> _campgroundToMap(Campground campground) {
    return {
      'id': campground.id,
      'name': campground.name,
      'description': campground.description,
      'latitude': campground.latitude,
      'longitude': campground.longitude,
      'state': campground.state,
      'park_name': campground.parkName,
      'reservation_url': campground.reservationUrl,
      'phone_number': campground.phoneNumber,
      'email': campground.email,
      'amenities': jsonEncode(campground.amenities),
      'activities': jsonEncode(campground.activities),
      'image_urls': jsonEncode(campground.imageUrls),
      'is_monitored': campground.isMonitored ? 1 : 0,
      'created_at': campground.createdAt?.toIso8601String(),
      'updated_at': campground.updatedAt?.toIso8601String(),
      'sync_timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Convert database map to Campground model
  Campground _mapToCampground(Map<String, dynamic> map) {
    return Campground(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      state: map['state'] as String,
      parkName: map['park_name'] as String?,
      reservationUrl: map['reservation_url'] as String?,
      phoneNumber: map['phone_number'] as String?,
      email: map['email'] as String?,
      amenities: _parseJsonStringList(map['amenities'] as String),
      activities: _parseJsonStringList(map['activities'] as String),
      imageUrls: _parseJsonStringList(map['image_urls'] as String),
      isMonitored: (map['is_monitored'] as int) == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'] as String) 
          : null,
    );
  }

  /// Parse JSON string to List<String>
  List<String> _parseJsonStringList(String jsonString) {
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((item) => item.toString()).toList();
    } catch (e) {
      _logger.w('Error parsing JSON string list: $jsonString', error: e);
      return [];
    }
  }

  /// Calculate distance between two points in miles
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radiusOfEarth = 3959.0; // miles
    
    final double lat1Rad = lat1 * (math.pi / 180);
    final double lat2Rad = lat2 * (math.pi / 180);
    final double deltaLat = (lat2 - lat1) * (math.pi / 180);
    final double deltaLon = (lon2 - lon1) * (math.pi / 180);

    final double a = 0.5 * (1 - math.cos(deltaLat)) + 
        math.cos(lat1Rad) * math.cos(lat2Rad) * 0.5 * (1 - math.cos(deltaLon));
    
    return radiusOfEarth * 2 * math.asin(math.sqrt(a));
  }

  /// Clear all data from database (useful for testing)
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete(_campgroundsTable);
      _logger.i('Cleared all campground data');
    } catch (e) {
      _logger.e('Error clearing database', error: e);
      rethrow;
    }
  }
}