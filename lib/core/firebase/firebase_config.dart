import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

/// Firebase configuration service for SiteBook
/// Handles Firebase initialization and core services setup
class FirebaseConfig {
  static FirebaseAnalytics? _analytics;
  static FirebaseMessaging? _messaging;

  /// Initialize Firebase and core services
  static Future<void> initialize() async {
    try {
      // First check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        debugPrint('🔥 Firebase already initialized');
        return;
      }

      // Initialize Firebase
      // Try platform-specific configuration first, fallback to development options
      FirebaseOptions? config;
      try {
        // This will automatically read relevant config files if they exist
        await Firebase.initializeApp();
        debugPrint('🔥 Firebase initialized with platform configuration');
      } catch (e) {
        debugPrint('⚠️  Platform Firebase config failed: $e');
        debugPrint('🔄 Falling back to development configuration');

        // Fallback to development configuration
        config = _getFirebaseOptions();
        await Firebase.initializeApp(options: config);
        debugPrint('🔥 Firebase initialized with development configuration');
      }

      // Initialize Analytics (only if Firebase is available)
      try {
        _analytics = FirebaseAnalytics.instance;
        await _analytics!.setAnalyticsCollectionEnabled(true);
        debugPrint('📊 Firebase Analytics initialized');
      } catch (e) {
        debugPrint('⚠️  Firebase Analytics failed: $e');
        _analytics = null;
      }

      // Initialize Messaging (only if Firebase is available)
      try {
        _messaging = FirebaseMessaging.instance;
        await _setupMessaging();
        debugPrint('📱 Firebase Messaging initialized');
      } catch (e) {
        debugPrint('⚠️  Firebase Messaging failed: $e');
        _messaging = null;
      }

      debugPrint('🔥 Firebase initialization completed');
    } catch (e) {
      debugPrint('❌ Firebase initialization completely failed: $e');
      debugPrint('⚠️  Continuing in offline mode without Firebase services');
      // Don't rethrow - continue without Firebase
    }
  }

  /// Setup Firebase Messaging permissions and handlers
  static Future<void> _setupMessaging() async {
    if (_messaging == null) return;

    try {
      // Request notification permissions
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 Notification permissions granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('🔔 Notification permissions granted (provisional)');
      } else {
        debugPrint('🚫 Notification permissions not granted');
      }

      // Get FCM token for this device (with error handling)
      try {
        String? token = await _messaging!.getToken();
        if (token != null) {
          debugPrint('📱 FCM Token: ${token.substring(0, 20)}...');
          // TODO: Send token to your server for targeted notifications
        }
      } catch (e) {
        debugPrint('⚠️  FCM Token retrieval failed: $e');
      }

      // Handle token refresh (with error handling)
      try {
        _messaging!.onTokenRefresh.listen(
          (String token) {
            debugPrint('🔄 FCM Token refreshed: ${token.substring(0, 20)}...');
            // TODO: Send updated token to your server
          },
          onError: (error) {
            debugPrint('⚠️  FCM Token refresh failed: $error');
          },
        );
      } catch (e) {
        debugPrint('⚠️  FCM Token refresh setup failed: $e');
      }
    } catch (e) {
      debugPrint('❌ Firebase Messaging setup failed: $e');
      // Don't rethrow - continue without messaging
    }
  }

  /// Get Firebase options for the current platform
  /// In production, these would come from Firebase console generated files
  static FirebaseOptions _getFirebaseOptions() {
    // TODO: Replace with actual Firebase configuration from Firebase console
    // These are placeholder values for development
    return const FirebaseOptions(
      apiKey: 'development-api-key',
      appId: 'com.sitebook.sitebook-flutter',
      messagingSenderId: '123456789',
      projectId: 'sitebook-dev',
      storageBucket: 'sitebook-dev.appspot.com',
    );
  }

  /// Get Firebase Analytics instance
  static FirebaseAnalytics? get analytics => _analytics;

  /// Get Firebase Messaging instance
  static FirebaseMessaging? get messaging => _messaging;

  /// Check if Firebase is available
  static bool get isAvailable => Firebase.apps.isNotEmpty;

  /// Log analytics events
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    try {
      if (_analytics != null) {
        await _analytics!.logEvent(name: name, parameters: parameters);
        debugPrint('📊 Analytics event logged: $name');
      } else {
        debugPrint('⚠️  Analytics not available, skipping event: $name');
      }
    } catch (e) {
      debugPrint('❌ Analytics event failed: $name, error: $e');
    }
  }
}
