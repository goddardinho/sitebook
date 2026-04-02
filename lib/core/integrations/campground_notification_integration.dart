import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_config.dart';
import '../notifications/notification_service.dart';
import '../../shared/models/campground.dart';
import '../../shared/providers/campground_providers.dart';

/// Integration service that connects campground monitoring with notifications
class CampgroundNotificationIntegration {
  static final _instance = CampgroundNotificationIntegration._internal();
  factory CampgroundNotificationIntegration() => _instance;
  CampgroundNotificationIntegration._internal();

  /// Initialize the integration between campground monitoring and notifications
  static Future<void> initialize() async {
    try {
      // Ensure Firebase and NotificationService are initialized
      if (!FirebaseConfig.isAvailable) {
        await FirebaseConfig.initialize();
      }
      await NotificationService.initialize();

      // Set up notification tap handling
      await _setupNotificationTapHandling();

      debugPrint('🏕️ Campground notification integration initialized');
    } catch (e) {
      debugPrint(
        '❌ Failed to initialize campground notification integration: $e',
      );
    }
  }

  /// Setup notification tap handling for navigation
  static Future<void> _setupNotificationTapHandling() async {
    // This will be enhanced when we implement navigation handling
    debugPrint('🔔 Notification tap handling configured');
  }

  /// Send availability notification for a campground
  static Future<void> notifyCampgroundAvailable({
    required Campground campground,
    required DateTime startDate,
    required DateTime endDate,
    String? specificSite,
  }) async {
    try {
      final dateRange = _formatDateRange(startDate, endDate);

      await NotificationService.showAvailabilityNotification(
        campgroundName: campground.name,
        dateRange: dateRange,
        campgroundId: campground.id,
      );

      // Log analytics event
      await FirebaseConfig.logEvent(
        'campground_availability_notification',
        parameters: {
          'campground_id': campground.id,
          'campground_name': campground.name,
          'date_range': dateRange,
          'park_name': campground.parkName ?? 'Unknown',
          'state': campground.state,
        },
      );

      debugPrint('🔔 Availability notification sent for ${campground.name}');
    } catch (e) {
      debugPrint('❌ Failed to send availability notification: $e');
    }
  }

  /// Send monitoring status notification
  static Future<void> notifyMonitoringUpdate({
    required Campground campground,
    required bool isMonitored,
  }) async {
    try {
      final title = isMonitored
          ? '✅ Monitoring Started'
          : '⏸️ Monitoring Stopped';

      final body = isMonitored
          ? 'Now monitoring ${campground.name} for availability'
          : 'Stopped monitoring ${campground.name}';

      await NotificationService.showLocalNotification(
        title: title,
        body: body,
        payload: 'monitoring_update:${campground.id}',
      );

      // Log analytics event
      await FirebaseConfig.logEvent(
        'campground_monitoring_update',
        parameters: {
          'campground_id': campground.id,
          'campground_name': campground.name,
          'is_monitored': isMonitored
              .toString(), // Convert boolean to string for Firebase Analytics
          'action': isMonitored ? 'start_monitoring' : 'stop_monitoring',
        },
      );

      debugPrint(
        '🔔 Monitoring update notification sent for ${campground.name}',
      );
    } catch (e) {
      debugPrint('❌ Failed to send monitoring update notification: $e');
    }
  }

  /// Check availability for all monitored campgrounds and send notifications
  static Future<void> checkMonitoredCampgroundsAvailability(
    WidgetRef ref,
  ) async {
    try {
      // Get all monitored campgrounds
      final campgrounds = await ref.read(searchResultsProvider.future);
      final monitoredCampgrounds = campgrounds
          .where((c) => c.isMonitored)
          .toList();

      if (monitoredCampgrounds.isEmpty) {
        debugPrint('🏕️ No campgrounds being monitored');
        return;
      }

      debugPrint(
        '🏕️ Checking availability for ${monitoredCampgrounds.length} monitored campgrounds',
      );

      for (final campground in monitoredCampgrounds) {
        // Check if campground has availability
        // This is a simplified check - in production you'd query the actual API
        final hasAvailability = await _checkCampgroundAvailability(campground);

        if (hasAvailability) {
          await notifyCampgroundAvailable(
            campground: campground,
            startDate: DateTime.now().add(const Duration(days: 7)),
            endDate: DateTime.now().add(const Duration(days: 9)),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to check monitored campgrounds availability: $e');
    }
  }

  /// Simple availability check (placeholder for actual API integration)
  static Future<bool> _checkCampgroundAvailability(
    Campground campground,
  ) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate random availability (25% chance)
    // In production, this would call the actual Recreation.gov or state park APIs
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final hasAvailability = random < 25;

    if (hasAvailability) {
      debugPrint('🏕️ ${campground.name} has availability!');
    }

    return hasAvailability;
  }

  /// Send daily summary notification for monitored campgrounds
  static Future<void> sendDailySummary(WidgetRef ref) async {
    try {
      final campgrounds = await ref.read(searchResultsProvider.future);
      final monitoredCount = campgrounds.where((c) => c.isMonitored).length;

      if (monitoredCount == 0) {
        return;
      }

      await NotificationService.showLocalNotification(
        title: '🏕️ Daily Campground Summary',
        body:
            'You are monitoring $monitoredCount ${monitoredCount == 1 ? 'campground' : 'campgrounds'}. Tap to view details.',
        payload: 'daily_summary',
        channel: 'general_notifications',
      );

      // Log analytics event
      await FirebaseConfig.logEvent(
        'daily_summary_notification',
        parameters: {'monitored_count': monitoredCount},
      );

      debugPrint('🔔 Daily summary notification sent');
    } catch (e) {
      debugPrint('❌ Failed to send daily summary: $e');
    }
  }

  /// Send welcome notification after first campground is monitored
  static Future<void> sendWelcomeNotification() async {
    try {
      await NotificationService.showLocalNotification(
        title: '🎉 Welcome to SiteBook Monitoring!',
        body:
            'We\'ll notify you when your monitored campgrounds become available. Happy camping!',
        payload: 'welcome',
      );

      await FirebaseConfig.logEvent('welcome_notification_sent');
      debugPrint('🔔 Welcome notification sent');
    } catch (e) {
      debugPrint('❌ Failed to send welcome notification: $e');
    }
  }

  /// Format date range for display
  static String _formatDateRange(DateTime startDate, DateTime endDate) {
    final start = '${startDate.month}/${startDate.day}';
    final end = '${endDate.month}/${endDate.day}';
    return '$start - $end';
  }

  /// Get notification settings status
  static Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final areEnabled = await NotificationService.areNotificationsEnabled();
      final firebaseAvailable = FirebaseConfig.isAvailable;

      return {
        'notifications_enabled': areEnabled,
        'firebase_available': firebaseAvailable,
        'push_notifications_available': firebaseAvailable && areEnabled,
        'local_notifications_available': areEnabled,
      };
    } catch (e) {
      debugPrint('❌ Failed to get notification status: $e');
      return {
        'notifications_enabled': false,
        'firebase_available': false,
        'push_notifications_available': false,
        'local_notifications_available': false,
      };
    }
  }
}
