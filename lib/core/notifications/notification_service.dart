import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Notification service for handling push and local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  
  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging handlers
      await _initializeFirebaseMessaging();
      
      _initialized = true;
      debugPrint('🔔 Notification service initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Notification service initialization failed: $e');
    }
  }
  
  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    
    // TODO: Fix API compatibility with flutter_local_notifications 21.0.0
    // await _localNotifications.initialize(initializationSettings);
    debugPrint('🔔 Local notifications initialization skipped - API compatibility issue');
    
    // Create notification channels for Android
    await _createNotificationChannels();
  }
  
  /// Initialize Firebase messaging handlers
  static Future<void> _initializeFirebaseMessaging() async {
    try {
      // Only initialize Firebase messaging if Firebase is available
      if (FirebaseMessaging.instance != null) {
        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Handle notification taps when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
        // Handle notification tap when app is terminated
        RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
        
        debugPrint('📱 Firebase messaging handlers initialized');
      } else {
        debugPrint('⚠️  Firebase messaging not available, using local notifications only');
      }
    } catch (e) {
      debugPrint('❌ Firebase messaging initialization failed: $e');
      debugPrint('⚠️  Continuing with local notifications only');
    }
  }
  
  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    // Availability alerts channel
    const AndroidNotificationChannel availabilityChannel =
        AndroidNotificationChannel(
      'availability_alerts',
      'Campground Availability Alerts',
      description: 'Notifications when monitored campgrounds become available',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );
    
    // General notifications channel
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
      'general_notifications',
      'General Notifications',
      description: 'General app notifications and updates',
      importance: Importance.defaultImportance,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(availabilityChannel);
        
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }
  
  /// Handle background Firebase messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📱 Background message received: ${message.messageId}');
    
    // Show local notification for background messages
    await showLocalNotification(
      title: message.notification?.title ?? 'SiteBook',
      body: message.notification?.body ?? 'New notification',
      payload: message.data.toString(),
      channel: 'availability_alerts',
    );
  }
  
  /// Handle foreground Firebase messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Foreground message received: ${message.messageId}');
    
    // Show local notification even when app is in foreground
    await showLocalNotification(
      title: message.notification?.title ?? 'SiteBook',
      body: message.notification?.body ?? 'New notification',
      payload: message.data.toString(),
      channel: 'availability_alerts',
    );
  }
  
  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📱 Notification tapped: ${message.messageId}');
    
    // Extract campground ID from message data
    String? campgroundId = message.data['campground_id'];
    if (campgroundId != null) {
      // TODO: Navigate to campground details
      debugPrint('🏕️ Navigate to campground: $campgroundId');
    }
  }
  
  /// Handle local notification tap
  static void _onNotificationTap(NotificationResponse notificationResponse) {
    debugPrint('🔔 Local notification tapped: ${notificationResponse.payload}');
    
    if (notificationResponse.payload != null) {
      // Parse payload and navigate accordingly
      // TODO: Implement navigation based on payload
    }
  }
  
  /// Show local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channel = 'general_notifications',
    int? id,
  }) async {
    id ??= DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'availability_alerts',
      'Campground Availability Alerts',
      channelDescription: 'Notifications when campgrounds become available',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Campground Available',
      icon: '@mipmap/ic_launcher',
      color: Colors.green,
    );
    
    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // TODO: Fix API compatibility with flutter_local_notifications 21.0.0  
    /*await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );*/
    debugPrint('🔔 Local notification: $title - $body');
  }
  
  /// Show availability notification
  static Future<void> showAvailabilityNotification({
    required String campgroundName,
    required String dateRange,
    required String campgroundId,
  }) async {
    await showLocalNotification(
      title: 'Campground Available! 🏕️',
      body: '$campgroundName has availability for $dateRange',
      payload: 'campground_available:$campgroundId',
      channel: 'availability_alerts',
    );
  }
  
  /// Cancel notification
  static Future<void> cancelNotification(int id) async {
    // TODO: Fix API compatibility with flutter_local_notifications 21.0.0
    // await _localNotifications.cancel(id);
    debugPrint('🔔 Cancel notification: $id');
  }
  
  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
  
  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}