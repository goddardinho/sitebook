import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing notification preferences
class NotificationPreferencesService {
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyQuietHoursStart = 'quiet_hours_start';
  static const String _keyQuietHoursEnd = 'quiet_hours_end';
  static const String _keyCheckFrequency = 'check_frequency';
  static const String _keyInstantNotifications = 'instant_notifications';
  static const String _keySummaryNotifications = 'summary_notifications';
  static const String _keyVibration = 'vibration_enabled';
  static const String _keySound = 'sound_enabled';
  static const String _keyCampgroundSpecific = 'campground_specific_';

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get notifications enabled status
  bool get notificationsEnabled => _prefs?.getBool(_keyNotificationsEnabled) ?? true;

  /// Set notifications enabled status
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Get quiet hours start time (24-hour format, e.g., 22 for 10 PM)
  int get quietHoursStart => _prefs?.getInt(_keyQuietHoursStart) ?? 22;

  /// Set quiet hours start time
  Future<void> setQuietHoursStart(int hour) async {
    await _prefs?.setInt(_keyQuietHoursStart, hour);
  }

  /// Get quiet hours end time (24-hour format, e.g., 7 for 7 AM)
  int get quietHoursEnd => _prefs?.getInt(_keyQuietHoursEnd) ?? 7;

  /// Set quiet hours end time
  Future<void> setQuietHoursEnd(int hour) async {
    await _prefs?.setInt(_keyQuietHoursEnd, hour);
  }

  /// Get check frequency in hours
  int get checkFrequencyHours => _prefs?.getInt(_keyCheckFrequency) ?? 12;

  /// Set check frequency in hours
  Future<void> setCheckFrequencyHours(int hours) async {
    await _prefs?.setInt(_keyCheckFrequency, hours);
  }

  /// Get instant notifications enabled
  bool get instantNotificationsEnabled => _prefs?.getBool(_keyInstantNotifications) ?? true;

  /// Set instant notifications enabled
  Future<void> setInstantNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyInstantNotifications, enabled);
  }

  /// Get summary notifications enabled
  bool get summaryNotificationsEnabled => _prefs?.getBool(_keySummaryNotifications) ?? true;

  /// Set summary notifications enabled
  Future<void> setSummaryNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keySummaryNotifications, enabled);
  }

  /// Get vibration enabled
  bool get vibrationEnabled => _prefs?.getBool(_keyVibration) ?? true;

  /// Set vibration enabled
  Future<void> setVibrationEnabled(bool enabled) async {
    await _prefs?.setBool(_keyVibration, enabled);
  }

  /// Get sound enabled
  bool get soundEnabled => _prefs?.getBool(_keySound) ?? true;

  /// Set sound enabled
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs?.setBool(_keySound, enabled);
  }

  /// Get campground-specific notification settings
  bool getCampgroundNotificationsEnabled(String campgroundId) {
    return _prefs?.getBool('$_keyCampgroundSpecific$campgroundId') ?? true;
  }

  /// Set campground-specific notification settings
  Future<void> setCampgroundNotificationsEnabled(String campgroundId, bool enabled) async {
    await _prefs?.setBool('$_keyCampgroundSpecific$campgroundId', enabled);
  }

  /// Check if current time is within quiet hours
  bool get isQuietHours {
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // Handle quiet hours that span midnight
    if (quietHoursStart > quietHoursEnd) {
      return currentHour >= quietHoursStart || currentHour < quietHoursEnd;
    } else {
      return currentHour >= quietHoursStart && currentHour < quietHoursEnd;
    }
  }

  /// Get all preferences as a map for debugging
  Map<String, dynamic> getAllPreferences() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'checkFrequencyHours': checkFrequencyHours,
      'instantNotificationsEnabled': instantNotificationsEnabled,
      'summaryNotificationsEnabled': summaryNotificationsEnabled,
      'vibrationEnabled': vibrationEnabled,
      'soundEnabled': soundEnabled,
      'isQuietHours': isQuietHours,
    };
  }

  /// Reset all preferences to defaults
  Future<void> resetToDefaults() async {
    await _prefs?.clear();
  }
}

/// Provider for notification preferences service
final notificationPreferencesServiceProvider = Provider<NotificationPreferencesService>((ref) {
  final service = NotificationPreferencesService();
  // Initialize when first accessed
  service.initialize();
  return service;
});

/// Provider for notifications enabled status
final notificationsEnabledProvider = StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
  final service = ref.watch(notificationPreferencesServiceProvider);
  return NotificationsEnabledNotifier(service);
});

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  final NotificationPreferencesService _service;

  NotificationsEnabledNotifier(this._service) : super(true) {
    _loadState();
  }

  Future<void> _loadState() async {
    await _service.initialize();
    state = _service.notificationsEnabled;
  }

  Future<void> setEnabled(bool enabled) async {
    await _service.setNotificationsEnabled(enabled);
    state = enabled;
  }
}

/// Provider for quiet hours settings
final quietHoursProvider = StateNotifierProvider<QuietHoursNotifier, Map<String, int>>((ref) {
  final service = ref.watch(notificationPreferencesServiceProvider);
  return QuietHoursNotifier(service);
});

class QuietHoursNotifier extends StateNotifier<Map<String, int>> {
  final NotificationPreferencesService _service;

  QuietHoursNotifier(this._service) : super({'start': 22, 'end': 7}) {
    _loadState();
  }

  Future<void> _loadState() async {
    await _service.initialize();
    state = {
      'start': _service.quietHoursStart,
      'end': _service.quietHoursEnd,
    };
  }

  Future<void> setStartTime(int hour) async {
    await _service.setQuietHoursStart(hour);
    state = {...state, 'start': hour};
  }

  Future<void> setEndTime(int hour) async {
    await _service.setQuietHoursEnd(hour);
    state = {...state, 'end': hour};
  }
}

/// Provider for check frequency
final checkFrequencyProvider = StateNotifierProvider<CheckFrequencyNotifier, int>((ref) {
  final service = ref.watch(notificationPreferencesServiceProvider);
  return CheckFrequencyNotifier(service);
});

class CheckFrequencyNotifier extends StateNotifier<int> {
  final NotificationPreferencesService _service;

  CheckFrequencyNotifier(this._service) : super(12) {
    _loadState();
  }

  Future<void> _loadState() async {
    await _service.initialize();
    state = _service.checkFrequencyHours;
  }

  Future<void> setFrequency(int hours) async {
    await _service.setCheckFrequencyHours(hours);
    state = hours;
  }
}