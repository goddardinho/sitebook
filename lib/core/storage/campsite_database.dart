import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import '../../shared/models/campsite.dart';
import '../../shared/models/campsite_monitoring_settings.dart';

/// SQLite database for campsite and monitoring data storage
class CampsiteDatabase {
  static const String _databaseName = 'sitebook_campsites.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _campsitesTable = 'campsites';
  static const String _monitoringSettingsTable = 'monitoring_settings';
  static const String _availabilityHistoryTable = 'availability_history';

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
    final path = '$dbPath/$_databaseName';

    _logger.i('Initializing campsite database at: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creating campsite database tables');

    // Campsites table
    await db.execute('''
      CREATE TABLE $_campsitesTable (
        id TEXT PRIMARY KEY,
        campground_id TEXT NOT NULL,
        site_number TEXT NOT NULL,
        site_type TEXT NOT NULL,
        max_occupancy INTEGER NOT NULL,
        accessibility INTEGER NOT NULL DEFAULT 0,
        amenities TEXT NOT NULL,
        price_per_night REAL,
        is_available INTEGER NOT NULL DEFAULT 0,
        next_available_date TEXT,
        image_url TEXT,
        description TEXT,
        rate_pricing TEXT,
        available_dates TEXT,
        amenities_details TEXT,
        reservation_url TEXT,
        is_monitored INTEGER NOT NULL DEFAULT 0,
        monitoring_count INTEGER DEFAULT 0,
        last_availability_check TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Monitoring settings table
    await db.execute('''
      CREATE TABLE $_monitoringSettingsTable (
        id TEXT PRIMARY KEY,
        campground_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        guest_count INTEGER NOT NULL,
        site_preference TEXT NOT NULL DEFAULT 'any_available',
        preferred_site_numbers TEXT,
        preferred_site_types TEXT,
        require_accessibility INTEGER NOT NULL DEFAULT 0,
        max_price_per_night REAL,
        max_total_cost REAL,
        alert_on_price_drops INTEGER NOT NULL DEFAULT 1,
        priority TEXT NOT NULL DEFAULT 'normal',
        auto_reserve INTEGER NOT NULL DEFAULT 0,
        max_notifications_per_day INTEGER NOT NULL DEFAULT 5,
        enable_quiet_hours INTEGER NOT NULL DEFAULT 1,
        quiet_hour_start INTEGER NOT NULL DEFAULT 22,
        quiet_hour_end INTEGER NOT NULL DEFAULT 8,
        alternative_campground_ids TEXT,
        accept_nearby_campgrounds INTEGER NOT NULL DEFAULT 0,
        nearby_campground_radius_miles REAL NOT NULL DEFAULT 25.0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        last_checked_at TEXT,
        successful_checks INTEGER NOT NULL DEFAULT 0,
        failed_checks INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Availability history table
    await db.execute('''
      CREATE TABLE $_availabilityHistoryTable (
        id TEXT PRIMARY KEY,
        campsite_id TEXT NOT NULL,
        check_date TEXT NOT NULL,
        was_available INTEGER NOT NULL,
        price REAL,
        monitoring_settings_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (campsite_id) REFERENCES $_campsitesTable (id),
        FOREIGN KEY (monitoring_settings_id) REFERENCES $_monitoringSettingsTable (id)
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);
  }

  /// Create performance indexes
  Future<void> _createIndexes(Database db) async {
    // Campsite indexes
    await db.execute(
      'CREATE INDEX idx_campsites_campground_id ON $_campsitesTable (campground_id)',
    );
    await db.execute(
      'CREATE INDEX idx_campsites_availability ON $_campsitesTable (is_available)',
    );
    await db.execute(
      'CREATE INDEX idx_campsites_monitored ON $_campsitesTable (is_monitored)',
    );
    await db.execute(
      'CREATE INDEX idx_campsites_site_type ON $_campsitesTable (site_type)',
    );
    await db.execute(
      'CREATE INDEX idx_campsites_accessibility ON $_campsitesTable (accessibility)',
    );

    // Monitoring settings indexes
    await db.execute(
      'CREATE INDEX idx_monitoring_campground_id ON $_monitoringSettingsTable (campground_id)',
    );
    await db.execute(
      'CREATE INDEX idx_monitoring_user_id ON $_monitoringSettingsTable (user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_monitoring_active ON $_monitoringSettingsTable (is_active)',
    );
    await db.execute(
      'CREATE INDEX idx_monitoring_dates ON $_monitoringSettingsTable (start_date, end_date)',
    );

    // Availability history indexes
    await db.execute(
      'CREATE INDEX idx_availability_campsite_id ON $_availabilityHistoryTable (campsite_id)',
    );
    await db.execute(
      'CREATE INDEX idx_availability_date ON $_availabilityHistoryTable (check_date)',
    );
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i(
      'Upgrading campsite database from version $oldVersion to $newVersion',
    );

    // Handle future schema changes here
  }

  // CAMPSITE OPERATIONS

  /// Save a single campsite
  Future<void> saveCampsite(Campsite campsite) async {
    try {
      final db = await database;
      await db.insert(
        _campsitesTable,
        _campsiteToMap(campsite),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.d(
        'Saved campsite: ${campsite.siteNumber} at ${campsite.campgroundId}',
      );
    } catch (e) {
      _logger.e('Error saving campsite ${campsite.id}', error: e);
      rethrow;
    }
  }

  /// Save multiple campsites
  Future<void> saveCampsites(List<Campsite> campsites) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final campsite in campsites) {
        batch.insert(
          _campsitesTable,
          _campsiteToMap(campsite),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      _logger.i('Saved ${campsites.length} campsites to database');
    } catch (e) {
      _logger.e('Error saving campsites batch', error: e);
      rethrow;
    }
  }

  /// Get all campsites for a campground
  Future<List<Campsite>> getCampsitesByCampground(String campgroundId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _campsitesTable,
        where: 'campground_id = ?',
        whereArgs: [campgroundId],
        orderBy: 'site_number ASC',
      );
      return maps.map((map) => _mapToCampsite(map)).toList();
    } catch (e) {
      _logger.e(
        'Error getting campsites for campground $campgroundId',
        error: e,
      );
      return [];
    }
  }

  /// Get available campsites for a campground
  Future<List<Campsite>> getAvailableCampsites(
    String campgroundId, {
    String? siteType,
    bool? accessibility,
    double? maxPrice,
  }) async {
    try {
      final db = await database;

      String whereClause = 'campground_id = ? AND is_available = 1';
      List<Object?> whereArgs = [campgroundId];

      if (siteType != null) {
        whereClause += ' AND site_type = ?';
        whereArgs.add(siteType);
      }

      if (accessibility == true) {
        whereClause += ' AND accessibility = 1';
      }

      if (maxPrice != null) {
        whereClause += ' AND (price_per_night IS NULL OR price_per_night <= ?)';
        whereArgs.add(maxPrice);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        _campsitesTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'price_per_night ASC',
      );

      return maps.map((map) => _mapToCampsite(map)).toList();
    } catch (e) {
      _logger.e(
        'Error getting available campsites for $campgroundId',
        error: e,
      );
      return [];
    }
  }

  /// Get monitored campsites
  Future<List<Campsite>> getMonitoredCampsites() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _campsitesTable,
        where: 'is_monitored = 1',
        orderBy: 'campground_id, site_number ASC',
      );
      return maps.map((map) => _mapToCampsite(map)).toList();
    } catch (e) {
      _logger.e('Error getting monitored campsites', error: e);
      return [];
    }
  }

  /// Update campsite monitoring status
  Future<void> updateCampsiteMonitoring(
    String campsiteId,
    bool isMonitored,
  ) async {
    try {
      final db = await database;
      await db.update(
        _campsitesTable,
        {
          'is_monitored': isMonitored ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [campsiteId],
      );
      _logger.d('Updated monitoring for campsite $campsiteId: $isMonitored');
    } catch (e) {
      _logger.e('Error updating campsite monitoring $campsiteId', error: e);
      rethrow;
    }
  }

  // MONITORING SETTINGS OPERATIONS

  /// Save monitoring settings
  Future<void> saveMonitoringSettings(
    CampsiteMonitoringSettings settings,
  ) async {
    try {
      final db = await database;
      await db.insert(
        _monitoringSettingsTable,
        _monitoringSettingsToMap(settings),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.d('Saved monitoring settings: ${settings.id}');
    } catch (e) {
      _logger.e('Error saving monitoring settings ${settings.id}', error: e);
      rethrow;
    }
  }

  /// Get active monitoring settings
  Future<List<CampsiteMonitoringSettings>> getActiveMonitoringSettings() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _monitoringSettingsTable,
        where: 'is_active = 1',
        orderBy: 'priority DESC, created_at ASC',
      );
      return maps.map((map) => _mapToMonitoringSettings(map)).toList();
    } catch (e) {
      _logger.e('Error getting active monitoring settings', error: e);
      return [];
    }
  }

  /// Get monitoring settings for a campground
  Future<List<CampsiteMonitoringSettings>> getMonitoringSettingsByCampground(
    String campgroundId,
  ) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _monitoringSettingsTable,
        where: 'campground_id = ?',
        whereArgs: [campgroundId],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => _mapToMonitoringSettings(map)).toList();
    } catch (e) {
      _logger.e(
        'Error getting monitoring settings for campground $campgroundId',
        error: e,
      );
      return [];
    }
  }

  /// Update monitoring settings activity status
  Future<void> updateMonitoringSettingsStatus(
    String settingsId,
    bool isActive,
  ) async {
    try {
      final db = await database;
      await db.update(
        _monitoringSettingsTable,
        {
          'is_active': isActive ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [settingsId],
      );
      _logger.d('Updated monitoring settings $settingsId status: $isActive');
    } catch (e) {
      _logger.e(
        'Error updating monitoring settings status $settingsId',
        error: e,
      );
      rethrow;
    }
  }

  /// Record availability check
  Future<void> recordAvailabilityCheck(
    String campsiteId,
    bool wasAvailable,
    double? price,
    String? monitoringSettingsId,
  ) async {
    try {
      final db = await database;
      await db.insert(_availabilityHistoryTable, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'campsite_id': campsiteId,
        'check_date': DateTime.now().toIso8601String(),
        'was_available': wasAvailable ? 1 : 0,
        'price': price,
        'monitoring_settings_id': monitoringSettingsId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Error recording availability check', error: e);
    }
  }

  // CONVERSION METHODS

  /// Convert Campsite to database map
  Map<String, dynamic> _campsiteToMap(Campsite campsite) {
    return {
      'id': campsite.id,
      'campground_id': campsite.campgroundId,
      'site_number': campsite.siteNumber,
      'site_type': campsite.siteType,
      'max_occupancy': campsite.maxOccupancy,
      'accessibility': campsite.accessibility ? 1 : 0,
      'amenities': jsonEncode(campsite.amenities),
      'price_per_night': campsite.pricePerNight,
      'is_available': campsite.isAvailable ? 1 : 0,
      'next_available_date': campsite.nextAvailableDate?.toIso8601String(),
      'image_url': campsite.imageUrl,
      'description': campsite.description,
      'rate_pricing': jsonEncode(campsite.ratePricing),
      'available_dates': jsonEncode(
        campsite.availableDates.map((d) => d.toIso8601String()).toList(),
      ),
      'amenities_details': jsonEncode(campsite.amenitiesDetails),
      'reservation_url': campsite.reservationUrl,
      'is_monitored': campsite.isMonitored ? 1 : 0,
      'monitoring_count': campsite.monitoringCount,
      'last_availability_check': campsite.lastAvailabilityCheck
          ?.toIso8601String(),
      'notes': campsite.notes,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert database map to Campsite
  Campsite _mapToCampsite(Map<String, dynamic> map) {
    return Campsite(
      id: map['id'],
      campgroundId: map['campground_id'],
      siteNumber: map['site_number'],
      siteType: map['site_type'],
      maxOccupancy: map['max_occupancy'],
      accessibility: map['accessibility'] == 1,
      amenities: List<String>.from(jsonDecode(map['amenities'])),
      pricePerNight: map['price_per_night']?.toDouble(),
      isAvailable: map['is_available'] == 1,
      nextAvailableDate: map['next_available_date'] != null
          ? DateTime.parse(map['next_available_date'])
          : null,
      imageUrl: map['image_url'],
      description: map['description'],
      ratePricing: Map<String, double>.from(
        jsonDecode(
          map['rate_pricing'] ?? '{}',
        ).map((k, v) => MapEntry(k, v?.toDouble() ?? 0.0)),
      ),
      availableDates: (jsonDecode(map['available_dates'] ?? '[]') as List)
          .map((dateStr) => DateTime.parse(dateStr))
          .toList(),
      amenitiesDetails: Map<String, bool>.from(
        jsonDecode(map['amenities_details'] ?? '{}'),
      ),
      reservationUrl: map['reservation_url'],
      isMonitored: map['is_monitored'] == 1,
      monitoringCount: map['monitoring_count'],
      lastAvailabilityCheck: map['last_availability_check'] != null
          ? DateTime.parse(map['last_availability_check'])
          : null,
      notes: map['notes'],
    );
  }

  /// Convert monitoring settings to database map
  Map<String, dynamic> _monitoringSettingsToMap(
    CampsiteMonitoringSettings settings,
  ) {
    return {
      'id': settings.id,
      'campground_id': settings.campgroundId,
      'user_id': settings.userId,
      'start_date': settings.startDate.toIso8601String(),
      'end_date': settings.endDate.toIso8601String(),
      'guest_count': settings.guestCount,
      'site_preference': settings.sitePreference.name,
      'preferred_site_numbers': jsonEncode(settings.preferredSiteNumbers),
      'preferred_site_types': jsonEncode(settings.preferredSiteTypes),
      'require_accessibility': settings.requireAccessibility ? 1 : 0,
      'max_price_per_night': settings.maxPricePerNight,
      'max_total_cost': settings.maxTotalCost,
      'alert_on_price_drops': settings.alertOnPriceDrops ? 1 : 0,
      'priority': settings.priority.name,
      'auto_reserve': settings.autoReserve ? 1 : 0,
      'max_notifications_per_day': settings.maxNotificationsPerDay,
      'enable_quiet_hours': settings.enableQuietHours ? 1 : 0,
      'quiet_hour_start': settings.quietHourStart,
      'quiet_hour_end': settings.quietHourEnd,
      'alternative_campground_ids': jsonEncode(
        settings.alternativeCampgroundIds,
      ),
      'accept_nearby_campgrounds': settings.acceptNearbyCampgrounds ? 1 : 0,
      'nearby_campground_radius_miles': settings.nearbyCampgroundRadiusMiles,
      'is_active': settings.isActive ? 1 : 0,
      'created_at': settings.createdAt.toIso8601String(),
      'updated_at': settings.updatedAt?.toIso8601String(),
      'last_checked_at': settings.lastCheckedAt?.toIso8601String(),
      'successful_checks': settings.successfulChecks,
      'failed_checks': settings.failedChecks,
    };
  }

  /// Convert database map to monitoring settings
  CampsiteMonitoringSettings _mapToMonitoringSettings(
    Map<String, dynamic> map,
  ) {
    return CampsiteMonitoringSettings(
      id: map['id'],
      campgroundId: map['campground_id'],
      userId: map['user_id'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      guestCount: map['guest_count'],
      sitePreference: SitePreference.values.firstWhere(
        (e) => e.name == map['site_preference'],
        orElse: () => SitePreference.anyAvailable,
      ),
      preferredSiteNumbers: List<String>.from(
        jsonDecode(map['preferred_site_numbers'] ?? '[]'),
      ),
      preferredSiteTypes: List<String>.from(
        jsonDecode(map['preferred_site_types'] ?? '[]'),
      ),
      requireAccessibility: map['require_accessibility'] == 1,
      maxPricePerNight: map['max_price_per_night']?.toDouble(),
      maxTotalCost: map['max_total_cost']?.toDouble(),
      alertOnPriceDrops: map['alert_on_price_drops'] == 1,
      priority: MonitoringPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => MonitoringPriority.normal,
      ),
      autoReserve: map['auto_reserve'] == 1,
      maxNotificationsPerDay: map['max_notifications_per_day'],
      enableQuietHours: map['enable_quiet_hours'] == 1,
      quietHourStart: map['quiet_hour_start'],
      quietHourEnd: map['quiet_hour_end'],
      alternativeCampgroundIds: List<String>.from(
        jsonDecode(map['alternative_campground_ids'] ?? '[]'),
      ),
      acceptNearbyCampgrounds: map['accept_nearby_campgrounds'] == 1,
      nearbyCampgroundRadiusMiles:
          map['nearby_campground_radius_miles']?.toDouble() ?? 25.0,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      lastCheckedAt: map['last_checked_at'] != null
          ? DateTime.parse(map['last_checked_at'])
          : null,
      successfulChecks: map['successful_checks'] ?? 0,
      failedChecks: map['failed_checks'] ?? 0,
    );
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete all data (for testing)
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete(_campsitesTable);
      await db.delete(_monitoringSettingsTable);
      await db.delete(_availabilityHistoryTable);
      _logger.i('Cleared all campsite database data');
    } catch (e) {
      _logger.e('Error clearing campsite database', error: e);
      rethrow;
    }
  }
}
