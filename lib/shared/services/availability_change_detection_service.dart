import 'package:flutter/foundation.dart';
import '../models/campground.dart';
import '../models/campsite.dart';
import '../models/campsite_monitoring_settings.dart';
import 'advanced_notification_service.dart';
import '../../core/storage/campsite_database.dart';

/// Service for detecting availability changes and triggering appropriate notifications
///
/// Handles comparison of campsite availability data to detect:
/// - New site availability
/// - Price drops
/// - Alternative site opportunities
class AvailabilityChangeDetectionService {
  static final CampsiteDatabase _database = CampsiteDatabase();

  /// Process availability updates and send appropriate notifications
  static Future<void> processAvailabilityUpdate({
    required Campground campground,
    required List<Campsite> currentAvailability,
    required List<CampsiteMonitoringSettings> activeMonitoring,
  }) async {
    try {
      debugPrint('🔍 Processing availability update for ${campground.name}...');

      // Get previous availability state from database
      final previousAvailability = await _database.getCampsitesByCampground(
        campground.id,
      );

      for (final settings in activeMonitoring) {
        await _processMonitoringSettings(
          campground: campground,
          currentAvailability: currentAvailability,
          previousAvailability: previousAvailability,
          settings: settings,
        );
      }

      // Update database with current availability
      await _updateAvailabilityDatabase(campground.id, currentAvailability);
    } catch (e) {
      debugPrint('❌ Error processing availability update: $e');
    }
  }

  /// Process a single monitoring settings configuration
  static Future<void> _processMonitoringSettings({
    required Campground campground,
    required List<Campsite> currentAvailability,
    required List<Campsite> previousAvailability,
    required CampsiteMonitoringSettings settings,
  }) async {
    try {
      // Filter sites that match user preferences
      final matchingSites = _filterSitesByPreferences(
        currentAvailability,
        settings,
      );

      if (matchingSites.isEmpty) {
        // Check for alternative suggestions
        await _checkForAlternatives(campground, settings);
        return;
      }

      // Check for newly available sites
      final newlyAvailable = _findNewlyAvailableSites(
        matchingSites,
        previousAvailability,
      );

      if (newlyAvailable.isNotEmpty) {
        await AdvancedNotificationService.sendSiteSpecificNotification(
          campground: campground,
          availableSites: newlyAvailable,
          settings: settings,
        );
      }

      // Check for price drops on existing availability
      await _checkForPriceDrops(
        campground: campground,
        currentSites: matchingSites,
        previousSites: previousAvailability,
        settings: settings,
      );

      // Send enhanced details for high-priority monitoring
      if (settings.priority == MonitoringPriority.critical &&
          matchingSites.isNotEmpty) {
        final bestSite = _selectBestSite(matchingSites, settings);
        await AdvancedNotificationService.sendEnhancedDetailsNotification(
          campground: campground,
          campsite: bestSite,
          settings: settings,
        );
      }
    } catch (e) {
      debugPrint('❌ Error processing monitoring settings: $e');
    }
  }

  /// Filter available sites by user preferences
  static List<Campsite> _filterSitesByPreferences(
    List<Campsite> sites,
    CampsiteMonitoringSettings settings,
  ) {
    return sites.where((site) {
      // Check date availability
      if (!_isSiteAvailableForDates(
        site,
        settings.startDate,
        settings.endDate,
      )) {
        return false;
      }

      // Check occupancy
      if (site.maxOccupancy < settings.guestCount) {
        return false;
      }

      // Check accessibility requirements
      if (settings.requireAccessibility && !site.accessibility) {
        return false;
      }

      // Check price limits
      if (settings.maxPricePerNight != null &&
          site.pricePerNight != null &&
          site.pricePerNight! > settings.maxPricePerNight!) {
        return false;
      }

      // Check specific site preferences
      if (settings.sitePreference == SitePreference.specificSites) {
        if (!settings.preferredSiteNumbers.contains(site.siteNumber)) {
          return false;
        }
      }

      // Check site type preferences
      if (settings.preferredSiteTypes.isNotEmpty &&
          !settings.preferredSiteTypes.contains(site.siteType)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Find sites that are newly available compared to previous check
  static List<Campsite> _findNewlyAvailableSites(
    List<Campsite> currentSites,
    List<Campsite> previousSites,
  ) {
    final previousSiteIds = previousSites
        .where((s) => s.isAvailable)
        .map((s) => s.id)
        .toSet();

    return currentSites
        .where((site) => site.isAvailable && !previousSiteIds.contains(site.id))
        .toList();
  }

  /// Check for price drops on monitored sites
  static Future<void> _checkForPriceDrops({
    required Campground campground,
    required List<Campsite> currentSites,
    required List<Campsite> previousSites,
    required CampsiteMonitoringSettings settings,
  }) async {
    if (!settings.alertOnPriceDrops) return;

    final previousPrices = <String, double>{};
    for (final site in previousSites) {
      if (site.pricePerNight != null) {
        previousPrices[site.id] = site.pricePerNight!;
      }
    }

    for (final currentSite in currentSites) {
      if (currentSite.pricePerNight == null) continue;

      final previousPrice = previousPrices[currentSite.id];
      if (previousPrice == null) continue;

      final currentPrice = currentSite.pricePerNight!;

      // Check if price dropped significantly (at least $5 or 10%)
      final priceDrop = previousPrice - currentPrice;
      final percentDrop = (priceDrop / previousPrice) * 100;

      if (priceDrop >= 5.0 || percentDrop >= 10.0) {
        await AdvancedNotificationService.sendPriceDropAlert(
          campground: campground,
          campsite: currentSite,
          previousPrice: previousPrice,
          currentPrice: currentPrice,
          settings: settings,
        );
      }
    }
  }

  /// Check for alternative campground suggestions
  static Future<void> _checkForAlternatives(
    Campground primaryCampground,
    CampsiteMonitoringSettings settings,
  ) async {
    if (!settings.acceptNearbyCampgrounds) return;

    try {
      // This would typically query nearby campgrounds from the database
      // For now, we'll simulate finding alternatives
      final alternatives = await _findAlternativeCampgrounds(
        primaryCampground: primaryCampground,
        settings: settings,
      );

      if (alternatives.isNotEmpty) {
        await AdvancedNotificationService.sendAlternativeSitesNotification(
          primaryCampground: primaryCampground,
          alternatives: alternatives,
          settings: settings,
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking for alternatives: $e');
    }
  }

  /// Find alternative campgrounds with availability
  static Future<List<AlternativeSiteSuggestion>> _findAlternativeCampgrounds({
    required Campground primaryCampground,
    required CampsiteMonitoringSettings settings,
  }) async {
    // This is a placeholder implementation
    // In a real app, this would query nearby campgrounds from the database
    // and check their availability

    final alternatives = <AlternativeSiteSuggestion>[];

    // Simulate finding alternative campgrounds (this would be real database queries)
    // For demo purposes, we'll just log that we're looking for alternatives
    debugPrint(
      '🔍 Searching for alternatives within ${settings.nearbyCampgroundRadiusMiles} miles...',
    );

    return alternatives;
  }

  /// Select the best site based on user preferences
  static Campsite _selectBestSite(
    List<Campsite> sites,
    CampsiteMonitoringSettings settings,
  ) {
    if (sites.length == 1) return sites.first;

    // Sort by preference matching
    sites.sort((a, b) {
      int scoreA = _calculateSiteScore(a, settings);
      int scoreB = _calculateSiteScore(b, settings);
      return scoreB.compareTo(scoreA); // Higher score first
    });

    return sites.first;
  }

  /// Calculate a preference score for a site
  static int _calculateSiteScore(
    Campsite site,
    CampsiteMonitoringSettings settings,
  ) {
    int score = 0;

    // Preferred site numbers get highest priority
    if (settings.preferredSiteNumbers.contains(site.siteNumber)) {
      score += 100;
    }

    // Preferred site types
    if (settings.preferredSiteTypes.contains(site.siteType)) {
      score += 50;
    }

    // Accessibility match
    if (settings.requireAccessibility && site.accessibility) {
      score += 30;
    }

    // Price considerations (lower price = higher score)
    if (site.pricePerNight != null && settings.maxPricePerNight != null) {
      final priceDiff = settings.maxPricePerNight! - site.pricePerNight!;
      score += (priceDiff / 10).round(); // $10 difference = 1 point
    }

    // More amenities = higher score
    score += site.amenities.length * 2;

    return score;
  }

  /// Check if a site is available for the requested date range
  static bool _isSiteAvailableForDates(
    Campsite site,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (!site.isAvailable) return false;

    // If the site has specific available dates, check those
    if (site.availableDates.isNotEmpty) {
      // Check if our requested range overlaps with available dates
      for (final availableDate in site.availableDates) {
        if (availableDate.isAfter(
              startDate.subtract(const Duration(days: 1)),
            ) &&
            availableDate.isBefore(endDate.add(const Duration(days: 1)))) {
          return true;
        }
      }
      return false;
    }

    // If no specific dates, assume available if nextAvailableDate is within range
    if (site.nextAvailableDate != null) {
      return site.nextAvailableDate!.isBefore(endDate);
    }

    // Default to available if marked as available
    return site.isAvailable;
  }

  /// Update the availability database with current state
  static Future<void> _updateAvailabilityDatabase(
    String campgroundId,
    List<Campsite> currentSites,
  ) async {
    try {
      for (final site in currentSites) {
        await _database.saveCampsite(site);
      }
    } catch (e) {
      debugPrint('❌ Error updating availability database: $e');
    }
  }
}
