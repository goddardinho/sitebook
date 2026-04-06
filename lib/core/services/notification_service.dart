import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/app_logger.dart';

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
    AppLogger.info('🔔 Notification service initialized');
  }

  /// Send availability notification
  Future<void> sendAvailabilityNotification({
    required String campgroundName,
    required int availableCount,
    required double bestPrice,
    required DateTime checkInDate,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'campsite_availability',
        'Campsite Availability',
        channelDescription: 'Notifications for campsite availability',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id: DateTime.now().millisecondsSinceEpoch % 1000000,
        title: 'Campsites Available!',
        body:
            '$availableCount sites available at $campgroundName starting \$${bestPrice.toStringAsFixed(2)}/night',
        notificationDetails: notificationDetails,
      );

      AppLogger.info('📤 Sent availability notification for $campgroundName');
    } catch (e) {
      AppLogger.error('❌ Failed to send availability notification', e);
    }
  }

  /// Send price drop notification
  Future<void> sendPriceDropNotification({
    required String campgroundName,
    required double newPrice,
    required double oldPrice,
    required DateTime checkInDate,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'price_drop',
        'Price Drops',
        channelDescription: 'Notifications for price drops',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final savings = oldPrice - newPrice;
      await _notifications.show(
        id: DateTime.now().millisecondsSinceEpoch % 1000000 + 1,
        title: 'Price Drop Alert!',
        body:
            '$campgroundName - Save \$${savings.toStringAsFixed(2)}/night! Now \$${newPrice.toStringAsFixed(2)}',
        notificationDetails: notificationDetails,
      );

      AppLogger.info('💰 Sent price drop notification for $campgroundName');
    } catch (e) {
      AppLogger.error('❌ Failed to send price drop notification', e);
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      AppLogger.info('🔐 Notification permissions: ${result ?? false}');
      return result ?? false;
    } catch (e) {
      AppLogger.error('❌ Failed to request notification permissions', e);
      return false;
    }
  }
}
