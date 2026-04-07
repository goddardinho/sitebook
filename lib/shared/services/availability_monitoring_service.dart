import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../models/campground.dart';
import '../models/campsite.dart';
import '../models/campsite_monitoring_settings.dart';
import '../../demo/demo_data_provider.dart';
import 'enhanced_notification_service.dart';
import 'notification_preferences_service.dart';
import 'advanced_notification_service.dart';
import 'availability_change_detection_service.dart';

/// Background task service for monitoring campground availability
///
/// This service runs periodic background checks for monitored campgrounds
/// and sends notifications when availability is found.
class AvailabilityMonitoringService {
  static const String _availabilityTaskName = 'campground_availability_check';
  static const String _uniqueTaskName = 'AVAILABILITY_MONITORING';

  // Minimum time between checks to respect API rate limits (6 hours)
  static const Duration _minimumCheckInterval = Duration(hours: 6);

  // Random jitter to distribute load (up to 1 hour)
  static const Duration _randomJitter = Duration(hours: 1);

  /// Initialize the background task service
  static Future<void> initialize() async {
    try {
      // Initialize WorkManager with callback dispatcher
      await Workmanager().initialize(callbackDispatcher);

      debugPrint('✅ AvailabilityMonitoringService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize AvailabilityMonitoringService: $e');
    }
  }

  /// Start periodic monitoring for all monitored campgrounds
  static Future<void> startMonitoring() async {
    try {
      // Cancel any existing monitoring task
      await stopMonitoring();

      // Calculate the next check time with intelligent scheduling
      final nextCheckTime = _calculateNextCheckTime();
      final delayMinutes = nextCheckTime.difference(DateTime.now()).inMinutes;

      // Schedule the periodic task
      await Workmanager().registerPeriodicTask(
        _uniqueTaskName,
        _availabilityTaskName,
        frequency: _minimumCheckInterval,
        initialDelay: Duration(minutes: delayMinutes > 0 ? delayMinutes : 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresCharging: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );

      debugPrint(
        '🔄 Availability monitoring started. Next check at: $nextCheckTime',
      );
    } catch (e) {
      debugPrint('❌ Failed to start availability monitoring: $e');
    }
  }

  /// Stop periodic monitoring
  static Future<void> stopMonitoring() async {
    try {
      await Workmanager().cancelByUniqueName(_uniqueTaskName);
      debugPrint('⏹️ Availability monitoring stopped');
    } catch (e) {
      debugPrint('❌ Failed to stop availability monitoring: $e');
    }
  }

  /// Check if monitoring is currently active
  static Future<bool> isMonitoringActive() async {
    try {
      // WorkManager doesn't provide a direct way to check if a task is scheduled
      // For now, we'll rely on user preferences to track this state
      return true; // TODO: Implement proper state tracking
    } catch (e) {
      debugPrint('❌ Failed to check monitoring status: $e');
      return false;
    }
  }

  /// Manually trigger an availability check (for testing/immediate checks)
  static Future<void> triggerImmediateCheck() async {
    try {
      await Workmanager().registerOneOffTask(
        'immediate_check_${DateTime.now().millisecondsSinceEpoch}',
        _availabilityTaskName,
        initialDelay: const Duration(seconds: 5),
        constraints: Constraints(networkType: NetworkType.connected),
      );

      debugPrint('🔍 Immediate availability check triggered');
    } catch (e) {
      debugPrint('❌ Failed to trigger immediate check: $e');
    }
  }

  /// Calculate the next check time with intelligent scheduling
  static DateTime _calculateNextCheckTime() {
    final now = DateTime.now();
    final random = math.Random();

    // Add base interval plus random jitter to distribute load
    final baseDelay = _minimumCheckInterval;
    final jitterMinutes = random.nextInt(_randomJitter.inMinutes);

    return now.add(baseDelay).add(Duration(minutes: jitterMinutes));
  }
}

/// Background task callback dispatcher
///
/// This function runs in an isolate and handles the actual availability checking
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('🏃‍♂️ Background task started: $task');

      switch (task) {
        case AvailabilityMonitoringService._availabilityTaskName:
          return await _performAvailabilityCheck();
        default:
          debugPrint('⚠️ Unknown background task: $task');
          return false;
      }
    } catch (e) {
      debugPrint('❌ Background task failed: $task - $e');
      return false;
    }
  });
}

/// Perform the actual availability checking logic
Future<bool> _performAvailabilityCheck() async {
  try {
    debugPrint('🔍 Starting background availability check...');

    // Get list of monitored campgrounds
    final monitoredCampgrounds = DemoDataProvider.getMonitoredCampgrounds();

    if (monitoredCampgrounds.isEmpty) {
      debugPrint('📭 No campgrounds being monitored, skipping check');
      return true;
    }

    debugPrint(
      '🏕️ Checking availability for ${monitoredCampgrounds.length} campgrounds',
    );

    // Initialize the advanced notification service
    await AdvancedNotificationService.initialize();

    // Check availability for each monitored campground
    for (final campground in monitoredCampgrounds) {
      await _checkCampgroundWithAdvancedNotifications(campground);
    }

    debugPrint('✅ Advanced availability check completed');
    return true;
  } catch (e) {
    debugPrint('❌ Error during availability check: $e');
    return false;
  }
}

/// Check campground availability with advanced notification support
Future<void> _checkCampgroundWithAdvancedNotifications(
  Campground campground,
) async {
  try {
    // Get current availability data (simulate API call for demo)
    final currentSites = await _fetchCurrentCampsiteAvailability(campground);

    // Get active monitoring settings for this campground (simulate for demo)
    final activeMonitoring = await _getActiveMonitoringSettings(campground.id);

    if (activeMonitoring.isEmpty) {
      debugPrint('📭 No active monitoring for ${campground.name}');
      return;
    }

    // Process availability changes with advanced notifications
    await AvailabilityChangeDetectionService.processAvailabilityUpdate(
      campground: campground,
      currentAvailability: currentSites,
      activeMonitoring: activeMonitoring,
    );
  } catch (e) {
    debugPrint(
      '❌ Error checking ${campground.name} with advanced notifications: $e',
    );
  }
}

/// Fetch current campsite availability (demo implementation)
Future<List<Campsite>> _fetchCurrentCampsiteAvailability(
  Campground campground,
) async {
  // Simulate API delay
  await Future.delayed(const Duration(milliseconds: 500));

  final random = math.Random();
  final sites = <Campsite>[];

  // Generate 3-8 sites with varying availability
  final siteCount = 3 + random.nextInt(6);

  for (int i = 1; i <= siteCount; i++) {
    final isAvailable = random.nextDouble() < 0.3; // 30% chance
    final siteType = [
      'Standard',
      'Electric',
      'Full Hookup',
      'Tent Only',
    ][random.nextInt(4)];
    final basePrice = 25.0 + (random.nextDouble() * 50.0); // $25-75

    sites.add(
      Campsite(
        id: '${campground.id}_site_$i',
        campgroundId: campground.id,
        siteNumber: i.toString().padLeft(3, '0'),
        siteType: siteType,
        maxOccupancy: 4 + random.nextInt(4), // 4-8 people
        accessibility: random.nextDouble() < 0.15, // 15% accessible
        amenities: _generateRandomAmenities(random),
        pricePerNight: basePrice.round().toDouble(),
        isAvailable: isAvailable,
        nextAvailableDate: isAvailable
            ? DateTime.now().add(Duration(days: random.nextInt(30)))
            : null,
        availableDates: isAvailable ? _generateAvailableDates(random) : [],
        monitoringCount: isAvailable
            ? 1 + random.nextInt(5)
            : null, // 1-5 people monitoring if available
      ),
    );
  }

  return sites;
}

/// Get active monitoring settings for a campground (demo implementation)
Future<List<CampsiteMonitoringSettings>> _getActiveMonitoringSettings(
  String campgroundId,
) async {
  final random = math.Random();
  final settings = <CampsiteMonitoringSettings>[];

  // Simulate 1-3 active monitoring configurations
  final settingsCount = 1 + random.nextInt(3);

  for (int i = 0; i < settingsCount; i++) {
    final startDate = DateTime.now().add(Duration(days: random.nextInt(60)));
    final endDate = startDate.add(Duration(days: 2 + random.nextInt(10)));

    settings.add(
      CampsiteMonitoringSettings(
        id: '${campgroundId}_monitoring_$i',
        campgroundId: campgroundId,
        userId: 'demo_user_$i',
        startDate: startDate,
        endDate: endDate,
        guestCount: 2 + random.nextInt(4), // 2-5 guests
        sitePreference:
            SitePreference.values[random.nextInt(SitePreference.values.length)],
        preferredSiteNumbers: random.nextBool() ? ['001', '002', '003'] : [],
        preferredSiteTypes: ['Standard', 'Electric'],
        requireAccessibility:
            random.nextDouble() < 0.2, // 20% need accessibility
        maxPricePerNight: 40.0 + (random.nextDouble() * 30.0), // $40-70 max
        alertOnPriceDrops: random.nextBool(),
        priority: MonitoringPriority
            .values[random.nextInt(MonitoringPriority.values.length)],
        acceptNearbyCampgrounds: random.nextBool(),
        nearbyCampgroundRadiusMiles: 25.0,
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
      ),
    );
  }

  return settings;
}

/// Generate random amenities for a campsite
List<String> _generateRandomAmenities(math.Random random) {
  final availableAmenities = [
    'Fire Ring',
    'Picnic Table',
    'Water Hookup',
    'Electric Hookup',
    'Restroom Access',
    'Shower Access',
    'Pet Friendly',
    'Lake Access',
    'Trail Access',
    'WiFi',
  ];

  final amenitiesCount = 2 + random.nextInt(5); // 2-6 amenities
  availableAmenities.shuffle(random);
  return availableAmenities.take(amenitiesCount).toList();
}

/// Generate random available dates
List<DateTime> _generateAvailableDates(math.Random random) {
  final dates = <DateTime>[];
  final baseDate = DateTime.now();

  // Generate 3-10 available dates in the next 90 days
  final dateCount = 3 + random.nextInt(8);

  for (int i = 0; i < dateCount; i++) {
    dates.add(baseDate.add(Duration(days: random.nextInt(90))));
  }

  dates.sort();
  return dates;
}

/// Send notifications for found availability
/// TODO: Integrate with availability checking workflow
Future<void> _sendAvailabilityNotifications(
  List<CampgroundAvailability> availabilities,
) async {
  try {
    // Initialize notification preferences service
    final prefsService = NotificationPreferencesService();
    await prefsService.initialize();

    // Check if notifications are enabled globally
    if (!prefsService.notificationsEnabled) {
      debugPrint('🔕 Notifications disabled globally, skipping notifications');
      return;
    }

    // Check if we're in quiet hours
    if (prefsService.isQuietHours) {
      debugPrint('🌙 Currently in quiet hours, skipping notifications');
      return;
    }

    // Initialize enhanced notification service
    await EnhancedNotificationService.initialize();

    // Send notifications for each available campground
    for (final availability in availabilities) {
      final campground = availability.campground;

      // Check campground-specific settings
      if (!prefsService.getCampgroundNotificationsEnabled(campground.id)) {
        debugPrint(
          '🔕 Notifications disabled for ${campground.name}, skipping',
        );
        continue;
      }

      // Check if instant notifications are enabled
      if (!prefsService.instantNotificationsEnabled) {
        debugPrint(
          '📬 Instant notifications disabled, will include in summary only',
        );
        continue;
      }

      final dates = availability.availableDates.first;

      debugPrint('🔥 AVAILABILITY FOUND: ${campground.name}');
      debugPrint(
        '📅 Available: ${dates.startDate.toString().split(' ')[0]} - ${dates.endDate.toString().split(' ')[0]}',
      );
      debugPrint('🏞️ Park: ${campground.parkName}');
      debugPrint(
        '⚙️ Notification preferences: vibration=${prefsService.vibrationEnabled}, sound=${prefsService.soundEnabled}',
      );

      // Send availability notification using enhanced service
      await EnhancedNotificationService.sendAvailabilityNotification(
        campgroundName: campground.name,
        parkName: campground.parkName ?? 'Unknown Park',
        availableDates: dates,
      );
    }
  } catch (e) {
    debugPrint('❌ Error sending availability notifications: $e');
  }
}

/// Data model for campground availability results
class CampgroundAvailability {
  final Campground campground;
  final bool hasAvailability;
  final List<DateRange> availableDates;
  final DateTime checkedAt;
  final String? error;

  const CampgroundAvailability({
    required this.campground,
    required this.hasAvailability,
    required this.availableDates,
    required this.checkedAt,
    this.error,
  });
}

/// Date range model for available periods
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({required this.startDate, required this.endDate});

  int get nights => endDate.difference(startDate).inDays;

  @override
  String toString() {
    return '${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]} ($nights nights)';
  }
}
