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
      
      // Initialize Firebase with default configuration
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      
      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      
      // Initialize Messaging
      _messaging = FirebaseMessaging.instance;
      await _setupMessaging();
      
      debugPrint('🔥 Firebase initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      // In development, continue without Firebase
      debugPrint('⚠️  Continuing in development mode without Firebase');
    }
  }
  
  /// Setup Firebase Messaging permissions and handlers
  static Future<void> _setupMessaging() async {
    if (_messaging == null) return;
    
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
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('🔔 Notification permissions granted (provisional)');
    } else {
      debugPrint('🚫 Notification permissions not granted');
    }
    
    // Get FCM token for this device
    String? token = await _messaging!.getToken();
    if (token != null) {
      debugPrint('📱 FCM Token: ${token.substring(0, 20)}...');
      // TODO: Send token to your server for targeted notifications
    }
    
    // Handle token refresh
    _messaging!.onTokenRefresh.listen((String token) {
      debugPrint('🔄 FCM Token refreshed: ${token.substring(0, 20)}...');
      // TODO: Send updated token to your server
    });
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
  static Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (_analytics != null) {
      await _analytics!.logEvent(name: name, parameters: parameters);
    }
  }
}