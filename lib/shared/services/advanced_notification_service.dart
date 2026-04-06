import 'package:flutter/foundation.dart';
import '../models/campground.dart';
import '../models/campsite.dart';
import '../models/campsite_monitoring_settings.dart';
import 'enhanced_notification_service.dart';

/// Advanced notification service with site-specific and price-aware notifications
///
/// Provides enhanced notifications with detailed campsite information,
/// price drop alerts, and alternative site suggestions
class AdvancedNotificationService {
  static bool _isInitialized = false;

  /// Initialize the advanced notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Ensure the base enhanced notification service is initialized
      await EnhancedNotificationService.initialize();

      debugPrint('✅ AdvancedNotificationService initialized');
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Failed to initialize AdvancedNotificationService: $e');
    }
  }

  /// Send site-specific availability notification with detailed campsite info
  static Future<void> sendSiteSpecificNotification({
    required Campground campground,
    required List<Campsite> availableSites,
    required CampsiteMonitoringSettings settings,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Group sites by type for better organization
      final sitesByType = <String, List<Campsite>>{};
      for (final site in availableSites) {
        sitesByType.putIfAbsent(site.siteType, () => []).add(site);
      }

      debugPrint('🎯 SITE-SPECIFIC AVAILABILITY FOUND!');
      debugPrint('🏕️ Campground: ${campground.name}');
      debugPrint('📍 Park: ${campground.parkName ?? 'Unknown Park'}');
      debugPrint(
        '📅 Dates: ${_formatDateRange(settings.startDate, settings.endDate)}',
      );
      debugPrint('👥 Guests: ${settings.guestCount}');
      debugPrint('');

      debugPrint('📋 AVAILABLE SITES (${availableSites.length} found):');

      for (final siteType in sitesByType.keys) {
        final sites = sitesByType[siteType]!;
        debugPrint('  🏷️ $siteType Sites:');

        for (final site in sites) {
          final priceInfo = site.pricePerNight != null
              ? '\$${site.pricePerNight!.toStringAsFixed(2)}/night'
              : 'Price TBD';

          final amenitiesInfo = site.amenities.isNotEmpty
              ? ' • ${site.amenities.take(3).join(', ')}'
              : '';

          debugPrint(
            '    🏕️ Site ${site.siteNumber} • $priceInfo • Max ${site.maxOccupancy} guests$amenitiesInfo',
          );

          if (site.accessibility) {
            debugPrint('      ♿ ADA Accessible');
          }
        }
        debugPrint('');
      }

      // Show preference matching
      _logPreferenceMatching(availableSites, settings);

      debugPrint('⏰ Notification sent at: ${DateTime.now()}');
      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Error sending site-specific notification: $e');
    }
  }

  /// Send price drop alert notification
  static Future<void> sendPriceDropAlert({
    required Campground campground,
    required Campsite campsite,
    required double previousPrice,
    required double currentPrice,
    required CampsiteMonitoringSettings settings,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final savings = previousPrice - currentPrice;
      final savingsPercent = ((savings / previousPrice) * 100).toStringAsFixed(
        1,
      );

      debugPrint('💰 PRICE DROP ALERT!');
      debugPrint('🏕️ Campground: ${campground.name}');
      debugPrint('🏷️ Site: ${campsite.siteNumber} (${campsite.siteType})');
      debugPrint(
        '📅 Dates: ${_formatDateRange(settings.startDate, settings.endDate)}',
      );
      debugPrint('');
      debugPrint('📉 Price Changed:');
      debugPrint('  ❌ Was: \$${previousPrice.toStringAsFixed(2)}/night');
      debugPrint('  ✅ Now: \$${currentPrice.toStringAsFixed(2)}/night');
      debugPrint(
        '  💰 You Save: \$${savings.toStringAsFixed(2)} ($savingsPercent%)',
      );
      debugPrint('');

      final totalNights = settings.endDate
          .difference(settings.startDate)
          .inDays;
      final totalSavings = savings * totalNights;
      if (totalNights > 1) {
        debugPrint(
          '📊 Total Savings for $totalNights nights: \$${totalSavings.toStringAsFixed(2)}',
        );
      }

      if (campsite.amenities.isNotEmpty) {
        debugPrint('🎯 Amenities: ${campsite.amenities.join(', ')}');
      }

      debugPrint('⏰ Alert sent at: ${DateTime.now()}');
      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Error sending price drop alert: $e');
    }
  }

  /// Send notification with alternative site suggestions
  static Future<void> sendAlternativeSitesNotification({
    required Campground primaryCampground,
    required List<AlternativeSiteSuggestion> alternatives,
    required CampsiteMonitoringSettings settings,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      debugPrint('🔄 ALTERNATIVE SITES AVAILABLE!');
      debugPrint('🎯 Your search: ${primaryCampground.name}');
      debugPrint(
        '📅 Dates: ${_formatDateRange(settings.startDate, settings.endDate)}',
      );
      debugPrint('👥 Guests: ${settings.guestCount}');
      debugPrint('');
      debugPrint('💡 Similar options found:');
      debugPrint('');

      for (int i = 0; i < alternatives.length; i++) {
        final alt = alternatives[i];
        final distanceInfo = alt.distanceMiles != null
            ? ' (${alt.distanceMiles!.toStringAsFixed(1)} miles away)'
            : '';

        debugPrint('${i + 1}. 🏕️ ${alt.campground.name}$distanceInfo');
        debugPrint('   📍 ${alt.campground.parkName ?? alt.campground.state}');

        if (alt.availableSites.isNotEmpty) {
          final siteCount = alt.availableSites.length;
          final priceRange = _getPriceRange(alt.availableSites);
          debugPrint('   ✅ $siteCount sites available • $priceRange');

          // Show a few specific sites
          final topSites = alt.availableSites.take(3);
          for (final site in topSites) {
            final price = site.pricePerNight != null
                ? '\$${site.pricePerNight!.toStringAsFixed(2)}'
                : 'TBD';
            debugPrint('      • Site ${site.siteNumber} ($price)');
          }
        }

        debugPrint('   🔗 ${alt.reason}');
        debugPrint('');
      }

      debugPrint('⏰ Alternatives sent at: ${DateTime.now()}');
      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Error sending alternatives notification: $e');
    }
  }

  /// Send comprehensive notification with enhanced campsite details
  static Future<void> sendEnhancedDetailsNotification({
    required Campground campground,
    required Campsite campsite,
    required CampsiteMonitoringSettings settings,
    Map<String, dynamic>? weatherInfo,
    Map<String, dynamic>? crowdingInfo,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      debugPrint('🌟 ENHANCED CAMPSITE DETAILS');
      debugPrint('🏕️ ${campground.name} - Site ${campsite.siteNumber}');
      debugPrint('📍 ${campground.parkName ?? campground.state}');
      debugPrint(
        '📅 ${_formatDateRange(settings.startDate, settings.endDate)}',
      );
      debugPrint('');

      // Site details
      debugPrint('🏷️ SITE INFORMATION:');
      debugPrint('  Type: ${campsite.siteType}');
      debugPrint('  Capacity: ${campsite.maxOccupancy} guests');
      if (campsite.pricePerNight != null) {
        debugPrint(
          '  Price: \$${campsite.pricePerNight!.toStringAsFixed(2)}/night',
        );
      }
      if (campsite.accessibility) {
        debugPrint('  ♿ ADA Accessible');
      }
      debugPrint('');

      // Amenities
      if (campsite.amenities.isNotEmpty) {
        debugPrint('🎯 AMENITIES:');
        for (final amenity in campsite.amenities) {
          debugPrint('  ✅ $amenity');
        }
        debugPrint('');
      }

      // Campground features
      if (campground.activities.isNotEmpty) {
        debugPrint('🏃 ACTIVITIES:');
        debugPrint('  ${campground.activities.take(5).join(' • ')}');
        debugPrint('');
      }

      // Weather info (if provided)
      if (weatherInfo != null) {
        debugPrint('🌤️ WEATHER FORECAST:');
        debugPrint('  ${weatherInfo['summary'] ?? 'Weather info available'}');
        debugPrint('');
      }

      // Crowding info (if provided)
      if (crowdingInfo != null) {
        debugPrint('📊 CROWD LEVELS:');
        debugPrint('  ${crowdingInfo['level'] ?? 'Moderate'}');
        debugPrint('');
      }

      // Booking urgency
      if (campsite.monitoringCount != null && campsite.monitoringCount! > 1) {
        debugPrint(
          '⚡ BOOKING TIP: ${campsite.monitoringCount} other users monitoring this site!',
        );
        debugPrint('');
      }

      debugPrint('⏰ Enhanced details sent at: ${DateTime.now()}');
      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Error sending enhanced details notification: $e');
    }
  }

  // Helper methods

  static String _formatDateRange(DateTime start, DateTime end) {
    final startStr = '${start.month}/${start.day}';
    final endStr = '${end.month}/${end.day}';
    return '$startStr - $endStr';
  }

  static void _logPreferenceMatching(
    List<Campsite> sites,
    CampsiteMonitoringSettings settings,
  ) {
    debugPrint('🎯 PREFERENCE MATCHING:');

    // Check specific site preferences
    if (settings.sitePreference == SitePreference.specificSites &&
        settings.preferredSiteNumbers.isNotEmpty) {
      final matchingSites = sites
          .where((s) => settings.preferredSiteNumbers.contains(s.siteNumber))
          .toList();
      if (matchingSites.isNotEmpty) {
        debugPrint(
          '  ✅ ${matchingSites.length} preferred sites found: ${matchingSites.map((s) => s.siteNumber).join(', ')}',
        );
      }
    }

    // Check accessibility requirements
    if (settings.requireAccessibility) {
      final accessibleSites = sites.where((s) => s.accessibility).length;
      debugPrint('  ♿ $accessibleSites accessible sites found');
    }

    // Check price preferences
    if (settings.maxPricePerNight != null) {
      final affordableSites = sites
          .where(
            (s) =>
                s.pricePerNight != null &&
                s.pricePerNight! <= settings.maxPricePerNight!,
          )
          .length;
      debugPrint(
        '  💰 $affordableSites sites under \$${settings.maxPricePerNight!.toStringAsFixed(2)}/night',
      );
    }

    debugPrint('');
  }

  static String _getPriceRange(List<Campsite> sites) {
    final prices = sites
        .where((s) => s.pricePerNight != null)
        .map((s) => s.pricePerNight!)
        .toList();

    if (prices.isEmpty) return 'Price TBD';
    if (prices.length == 1) return '\$${prices.first.toStringAsFixed(2)}/night';

    prices.sort();
    final min = prices.first;
    final max = prices.last;

    if (min == max) {
      return '\$${min.toStringAsFixed(2)}/night';
    }

    return '\$${min.toStringAsFixed(2)} - \$${max.toStringAsFixed(2)}/night';
  }
}

/// Data class for alternative site suggestions
class AlternativeSiteSuggestion {
  final Campground campground;
  final List<Campsite> availableSites;
  final double? distanceMiles;
  final String reason;

  const AlternativeSiteSuggestion({
    required this.campground,
    required this.availableSites,
    this.distanceMiles,
    required this.reason,
  });
}
