import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../shared/models/campsite_monitoring_settings.dart';
import '../../shared/services/campsite_api_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/app_logger.dart';
import '../repositories/campsite_repository.dart';

/// Service for background monitoring of campsite availability
/// Runs periodic checks on monitored campsites and sends notifications
class CampsiteMonitoringService {
  final CampsiteRepository _repository;
  final NotificationService _notificationService;
  final Logger _logger = Logger();

  Timer? _monitoringTimer;
  bool _isRunning = false;

  /// Default monitoring intervals by priority (in minutes)
  static const Map<MonitoringPriority, int> _defaultIntervals = {
    MonitoringPriority.low: 120, // 2 hours
    MonitoringPriority.normal: 60, // 1 hour
    MonitoringPriority.high: 30, // 30 minutes
    MonitoringPriority.critical: 15, // 15 minutes
  };

  CampsiteMonitoringService({
    required CampsiteRepository repository,
    required NotificationService notificationService,
  }) : _repository = repository,
       _notificationService = notificationService;

  /// Start the monitoring service
  Future<void> start() async {
    if (_isRunning) {
      AppLogger.warning('⚠️ Monitoring service is already running');
      return;
    }

    try {
      _isRunning = true;
      AppLogger.info('🚀 Starting campsite monitoring service');

      // Schedule the first check after a short delay
      _scheduleNextCheck(delay: const Duration(seconds: 30));

      AppLogger.info('✅ Campsite monitoring service started');
    } catch (e) {
      AppLogger.error('❌ Failed to start monitoring service', e);
      _isRunning = false;
      rethrow;
    }
  }

  /// Stop the monitoring service
  Future<void> stop() async {
    if (!_isRunning) {
      AppLogger.warning('⚠️ Monitoring service is not running');
      return;
    }

    try {
      AppLogger.info('🛑 Stopping campsite monitoring service');

      _monitoringTimer?.cancel();
      _monitoringTimer = null;
      _isRunning = false;

      AppLogger.info('✅ Campsite monitoring service stopped');
    } catch (e) {
      AppLogger.error('❌ Failed to stop monitoring service', e);
    }
  }

  /// Check if the service is currently running
  bool get isRunning => _isRunning;

  /// Perform a manual monitoring check for all active settings
  Future<MonitoringCheckResult> performManualCheck() async {
    try {
      AppLogger.info('🔍 Performing manual monitoring check');

      final activeSettings = await _repository.getActiveMonitoringSettings();
      if (activeSettings.isEmpty) {
        AppLogger.info('📭 No active monitoring settings found');
        return MonitoringCheckResult.empty();
      }

      int totalResults = 0;
      int availableFound = 0;
      int notificationsSent = 0;
      List<CampsiteAvailabilityData> allResults = [];

      for (final settings in activeSettings) {
        try {
          final results = await _checkMonitoringSettings(settings);
          allResults.addAll(results);
          totalResults += results.length;

          final availableResults = results.where((r) => r.isAvailable).toList();
          availableFound += availableResults.length;

          if (availableResults.isNotEmpty) {
            final sent = await _sendAvailabilityNotifications(
              settings,
              availableResults,
            );
            notificationsSent += sent;
          }
        } catch (e) {
          AppLogger.error('❌ Failed to check settings: ${settings.id}', e);
        }
      }

      final result = MonitoringCheckResult(
        totalResults: totalResults,
        availableFound: availableFound,
        notificationsSent: notificationsSent,
        checkedAt: DateTime.now(),
        allResults: allResults,
      );

      AppLogger.info('✅ Manual check completed: ${result.summary}');
      return result;
    } catch (e) {
      AppLogger.error('❌ Manual monitoring check failed', e);
      rethrow;
    }
  }

  /// Schedule the next monitoring check based on active settings
  void _scheduleNextCheck({Duration? delay}) {
    if (!_isRunning) return;

    _monitoringTimer?.cancel();

    if (delay != null) {
      // Use provided delay directly
      _monitoringTimer = Timer(delay, () {
        if (_isRunning) {
          _performScheduledCheck();
        }
      });

      AppLogger.debug(
        '⏰ Next monitoring check scheduled in: ${delay.inMinutes} minutes',
      );
    } else {
      // Calculate interval asynchronously
      _calculateNextInterval().then((interval) {
        if (_isRunning) {
          _monitoringTimer = Timer(interval, () {
            if (_isRunning) {
              _performScheduledCheck();
            }
          });

          AppLogger.debug(
            '⏰ Next monitoring check scheduled in: ${interval.inMinutes} minutes',
          );
        }
      });
    }
  }

  /// Perform a scheduled monitoring check
  Future<void> _performScheduledCheck() async {
    try {
      AppLogger.info('🔔 Performing scheduled monitoring check');

      final result = await performManualCheck();
      AppLogger.info('📊 Scheduled check completed: ${result.summary}');

      // Schedule the next check
      _scheduleNextCheck();
    } catch (e) {
      AppLogger.error('❌ Scheduled check failed', e);

      // Retry in 5 minutes on error
      _scheduleNextCheck(delay: const Duration(minutes: 5));
    }
  }

  /// Calculate the next check interval based on active settings
  Future<Duration> _calculateNextInterval() async {
    try {
      final activeSettings = await _repository.getActiveMonitoringSettings();

      if (activeSettings.isEmpty) {
        return const Duration(hours: 1); // Default interval
      }

      // Get the shortest interval from all active settings
      final highestPriority = activeSettings
          .map((s) => s.priority)
          .reduce((a, b) => a.index > b.index ? a : b);

      final intervalMinutes = _defaultIntervals[highestPriority] ?? 60;
      return Duration(minutes: intervalMinutes);
    } catch (e) {
      AppLogger.error('❌ Failed to calculate next interval', e);
      return const Duration(hours: 1);
    }
  }

  /// Check a specific monitoring settings configuration
  Future<List<CampsiteAvailabilityData>> _checkMonitoringSettings(
    CampsiteMonitoringSettings settings,
  ) async {
    try {
      AppLogger.debug('🔍 Checking monitoring settings: ${settings.id}');

      // Check if it's within quiet hours
      if (_isInQuietHours(settings)) {
        AppLogger.debug('🌙 Skipping check during quiet hours: ${settings.id}');
        return [];
      }

      // Perform the monitoring check
      final results = await _repository.monitorCampsitesByCriteria(
        settings.campgroundId,
        settings,
      );

      AppLogger.debug(
        '✅ Checked ${results.length} campsites for settings: ${settings.id}',
      );
      return results;
    } catch (e) {
      AppLogger.error(
        '❌ Failed to check monitoring settings: ${settings.id}',
        e,
      );
      return [];
    }
  }

  /// Send availability notifications for found campsites
  Future<int> _sendAvailabilityNotifications(
    CampsiteMonitoringSettings settings,
    List<CampsiteAvailabilityData> availableResults,
  ) async {
    try {
      int notificationsSent = 0;

      // Group notifications by type to avoid spam
      // TODO: Use high priority results for prioritized notifications
      // final highPriorityResults = availableResults
      //     .where(
      //       (r) =>
      //           r.averagePricePerNight != null &&
      //           r.averagePricePerNight! <=
      //               (settings.maxPricePerNight ?? double.infinity),
      //     )
      //     .toList();

      final priceDropResults = availableResults
          .where((r) => _isPriceDrop(r, settings))
          .toList();

      // Send main availability notification
      if (availableResults.isNotEmpty) {
        await _notificationService.sendAvailabilityNotification(
          campgroundName: settings.campgroundId,
          availableCount: availableResults.length,
          bestPrice: availableResults
              .map((r) => r.averagePricePerNight ?? 0)
              .where((p) => p > 0)
              .fold(double.infinity, (a, b) => a < b ? a : b),
          checkInDate: settings.startDate,
        );
        notificationsSent++;
      }

      // Send price drop notification for significant drops
      if (priceDropResults.isNotEmpty && settings.alertOnPriceDrops) {
        await _notificationService.sendPriceDropNotification(
          campgroundName: settings.campgroundId,
          newPrice: priceDropResults.first.averagePricePerNight ?? 0,
          oldPrice:
              priceDropResults.first.averagePricePerNight! *
              1.2, // Estimated previous price
          checkInDate: settings.startDate,
        );
        notificationsSent++;
      }

      AppLogger.info(
        '📤 Sent $notificationsSent notifications for settings: ${settings.id}',
      );
      return notificationsSent;
    } catch (e) {
      AppLogger.error('❌ Failed to send notifications', e);
      return 0;
    }
  }

  /// Check if current time is within quiet hours for the settings
  bool _isInQuietHours(CampsiteMonitoringSettings settings) {
    if (!settings.enableQuietHours) {
      return false;
    }

    final now = DateTime.now();
    final currentHour = now.hour;

    final startHour = settings.quietHourStart;
    final endHour = settings.quietHourEnd;

    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (startHour > endHour) {
      return currentHour >= startHour || currentHour <= endHour;
    }

    // Handle same-day quiet hours (e.g., 12:00 to 14:00)
    return currentHour >= startHour && currentHour <= endHour;
  }

  /// Check if the availability represents a price drop
  bool _isPriceDrop(
    CampsiteAvailabilityData availability,
    CampsiteMonitoringSettings settings,
  ) {
    // TODO: Implement price history comparison
    // For now, just check if price is significantly below max price
    final price = availability.averagePricePerNight;
    final maxPrice = settings.maxPricePerNight;

    if (price == null || maxPrice == null) return false;

    return price <= maxPrice * 0.8; // 20% below max price
  }

  /// Get monitoring statistics
  Future<MonitoringStatistics> getStatistics() async {
    try {
      final allSettings = await _repository.getAllMonitoringSettings();
      final activeSettings = await _repository.getActiveMonitoringSettings();

      final totalChecks = allSettings
          .map((s) => s.successfulChecks + s.failedChecks)
          .fold<int>(0, (a, b) => a + b);

      final successfulChecks = allSettings
          .map((s) => s.successfulChecks)
          .fold<int>(0, (a, b) => a + b);

      return MonitoringStatistics(
        totalSettings: allSettings.length,
        activeSettings: activeSettings.length,
        totalChecks: totalChecks,
        successfulChecks: successfulChecks,
        successRate: totalChecks > 0 ? successfulChecks / totalChecks : 0.0,
        isRunning: _isRunning,
        nextCheckIn: null, // TODO: Calculate actual next check time
      );
    } catch (e) {
      AppLogger.error('❌ Failed to get monitoring statistics', e);
      return MonitoringStatistics.empty();
    }
  }

  /// Dispose of resources
  void dispose() {
    stop();
  }
}

/// Result of a monitoring check run
class MonitoringCheckResult {
  final int totalResults;
  final int availableFound;
  final int notificationsSent;
  final DateTime checkedAt;
  final List<CampsiteAvailabilityData> allResults;

  const MonitoringCheckResult({
    required this.totalResults,
    required this.availableFound,
    required this.notificationsSent,
    required this.checkedAt,
    required this.allResults,
  });

  factory MonitoringCheckResult.empty() {
    return MonitoringCheckResult(
      totalResults: 0,
      availableFound: 0,
      notificationsSent: 0,
      checkedAt: DateTime.now(),
      allResults: [],
    );
  }

  String get summary =>
      '$totalResults checked, $availableFound available, $notificationsSent notifications sent';
}

/// Monitoring service statistics
class MonitoringStatistics {
  final int totalSettings;
  final int activeSettings;
  final int totalChecks;
  final int successfulChecks;
  final double successRate;
  final bool isRunning;
  final Duration? nextCheckIn;

  const MonitoringStatistics({
    required this.totalSettings,
    required this.activeSettings,
    required this.totalChecks,
    required this.successfulChecks,
    required this.successRate,
    required this.isRunning,
    this.nextCheckIn,
  });

  factory MonitoringStatistics.empty() {
    return const MonitoringStatistics(
      totalSettings: 0,
      activeSettings: 0,
      totalChecks: 0,
      successfulChecks: 0,
      successRate: 0.0,
      isRunning: false,
    );
  }
}
