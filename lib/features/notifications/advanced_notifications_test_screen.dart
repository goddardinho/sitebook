import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/campground.dart';
import '../../shared/models/campsite.dart';
import '../../shared/models/campsite_monitoring_settings.dart';
import '../../shared/services/advanced_notification_service.dart';
import '../../demo/demo_data_provider.dart';

/// Screen for testing and demonstrating advanced notification features
class AdvancedNotificationsTestScreen extends ConsumerStatefulWidget {
  const AdvancedNotificationsTestScreen({super.key});

  @override
  ConsumerState<AdvancedNotificationsTestScreen> createState() =>
      _AdvancedNotificationsTestScreenState();
}

class _AdvancedNotificationsTestScreenState
    extends ConsumerState<AdvancedNotificationsTestScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await AdvancedNotificationService.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Notifications Test'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isInitialized ? _buildTestInterface() : _buildLoadingState(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing Advanced Notification Service...'),
        ],
      ),
    );
  }

  Widget _buildTestInterface() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Test Advanced Notification Types'),
          const SizedBox(height: 16),

          _buildNotificationTestCard(
            title: '🎯 Site-Specific Availability',
            description: 'Test notifications with detailed site information',
            onTap: _testSiteSpecificNotification,
          ),

          const SizedBox(height: 12),

          _buildNotificationTestCard(
            title: '💰 Price Drop Alert',
            description:
                'Test price drop notifications with savings calculation',
            onTap: _testPriceDropAlert,
          ),

          const SizedBox(height: 12),

          _buildNotificationTestCard(
            title: '🔄 Alternative Sites',
            description: 'Test alternative campground suggestions',
            onTap: _testAlternativeSitesNotification,
          ),

          const SizedBox(height: 12),

          _buildNotificationTestCard(
            title: '🌟 Enhanced Details',
            description: 'Test comprehensive notification with all details',
            onTap: _testEnhancedDetailsNotification,
          ),

          const SizedBox(height: 32),

          _buildSectionHeader('Batch Test'),
          const SizedBox(height: 16),

          _buildNotificationTestCard(
            title: '🚀 Test All Notification Types',
            description: 'Run all notification types in sequence',
            color: Theme.of(context).colorScheme.primaryContainer,
            onTap: _testAllNotificationTypes,
          ),

          const SizedBox(height: 32),

          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildNotificationTestCard({
    required String title,
    required String description,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      color: color,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Text(
                  'About Advanced Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'This is a testing interface for the advanced notification system. '
              'In production, these notifications would be sent automatically when '
              'campsite availability changes are detected.\n\n'
              'Check the debug output to see detailed notification content.',
            ),
          ],
        ),
      ),
    );
  }

  // Test methods for each notification type

  Future<void> _testSiteSpecificNotification() async {
    final campground =
        DemoDataProvider.getAllCampgrounds().first; // Yosemite Valley
    final availableSites = _generateTestSites(campground);
    final settings = _generateTestMonitoringSettings(campground.id);

    await AdvancedNotificationService.sendSiteSpecificNotification(
      campground: campground,
      availableSites: availableSites,
      settings: settings,
    );

    _showSnackBar('Site-specific notification sent! Check debug output.');
  }

  Future<void> _testPriceDropAlert() async {
    final campground =
        DemoDataProvider.getAllCampgrounds().first; // Yosemite Valley
    final campsite = _generateTestSites(campground).first;
    final settings = _generateTestMonitoringSettings(campground.id);

    await AdvancedNotificationService.sendPriceDropAlert(
      campground: campground,
      campsite: campsite,
      previousPrice: 65.00,
      currentPrice: 45.00,
      settings: settings,
    );

    _showSnackBar('Price drop alert sent! Check debug output.');
  }

  Future<void> _testAlternativeSitesNotification() async {
    final primaryCampground =
        DemoDataProvider.getAllCampgrounds().first; // Yosemite Valley
    final alternatives = _generateAlternativeSuggestions();
    final settings = _generateTestMonitoringSettings(primaryCampground.id);

    await AdvancedNotificationService.sendAlternativeSitesNotification(
      primaryCampground: primaryCampground,
      alternatives: alternatives,
      settings: settings,
    );

    _showSnackBar('Alternative sites notification sent! Check debug output.');
  }

  Future<void> _testEnhancedDetailsNotification() async {
    final campground =
        DemoDataProvider.getAllCampgrounds().first; // Yosemite Valley
    final campsite = _generateTestSites(campground).first;
    final settings = _generateTestMonitoringSettings(campground.id);

    await AdvancedNotificationService.sendEnhancedDetailsNotification(
      campground: campground,
      campsite: campsite,
      settings: settings,
      weatherInfo: {
        'summary': 'Sunny, 75°F high / 45°F low • Perfect camping weather!',
      },
      crowdingInfo: {
        'level': 'Low crowds expected • Prime time for peaceful camping',
      },
    );

    _showSnackBar('Enhanced details notification sent! Check debug output.');
  }

  Future<void> _testAllNotificationTypes() async {
    _showSnackBar('Running all notification tests... Check debug output.');

    await _testSiteSpecificNotification();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testPriceDropAlert();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testAlternativeSitesNotification();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testEnhancedDetailsNotification();

    _showSnackBar('All notification tests completed!');
  }

  // Helper methods for generating test data

  List<Campsite> _generateTestSites(Campground campground) {
    return [
      Campsite(
        id: '${campground.id}_001',
        campgroundId: campground.id,
        siteNumber: '015',
        siteType: 'Electric',
        maxOccupancy: 6,
        accessibility: true,
        amenities: [
          'Fire Ring',
          'Picnic Table',
          'Electric Hookup',
          'Pet Friendly',
        ],
        pricePerNight: 45.00,
        isAvailable: true,
        nextAvailableDate: DateTime.now().add(const Duration(days: 3)),
        availableDates: [
          DateTime.now().add(const Duration(days: 3)),
          DateTime.now().add(const Duration(days: 4)),
          DateTime.now().add(const Duration(days: 5)),
        ],
        monitoringCount: 3,
      ),
      Campsite(
        id: '${campground.id}_002',
        campgroundId: campground.id,
        siteNumber: '023',
        siteType: 'Standard',
        maxOccupancy: 4,
        accessibility: false,
        amenities: ['Fire Ring', 'Picnic Table', 'Lake Access'],
        pricePerNight: 35.00,
        isAvailable: true,
        nextAvailableDate: DateTime.now().add(const Duration(days: 5)),
        availableDates: [
          DateTime.now().add(const Duration(days: 5)),
          DateTime.now().add(const Duration(days: 6)),
        ],
        monitoringCount: 1,
      ),
      Campsite(
        id: '${campground.id}_003',
        campgroundId: campground.id,
        siteNumber: '031',
        siteType: 'Full Hookup',
        maxOccupancy: 8,
        accessibility: false,
        amenities: [
          'Fire Ring',
          'Picnic Table',
          'Electric Hookup',
          'Water Hookup',
          'Sewer Hookup',
        ],
        pricePerNight: 55.00,
        isAvailable: true,
        nextAvailableDate: DateTime.now().add(const Duration(days: 2)),
        availableDates: [
          DateTime.now().add(const Duration(days: 2)),
          DateTime.now().add(const Duration(days: 3)),
          DateTime.now().add(const Duration(days: 4)),
        ],
        monitoringCount: 2,
      ),
    ];
  }

  CampsiteMonitoringSettings _generateTestMonitoringSettings(
    String campgroundId,
  ) {
    return CampsiteMonitoringSettings(
      id: '${campgroundId}_test_monitoring',
      campgroundId: campgroundId,
      userId: 'test_user',
      startDate: DateTime.now().add(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 6)),
      guestCount: 4,
      sitePreference: SitePreference.specificSites,
      preferredSiteNumbers: ['015', '023'],
      preferredSiteTypes: ['Electric', 'Standard'],
      requireAccessibility: true,
      maxPricePerNight: 50.00,
      alertOnPriceDrops: true,
      priority: MonitoringPriority.high,
      acceptNearbyCampgrounds: true,
      nearbyCampgroundRadiusMiles: 25.0,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    );
  }

  List<AlternativeSiteSuggestion> _generateAlternativeSuggestions() {
    final allCampgrounds = DemoDataProvider.getAllCampgrounds();
    final secondCampground = allCampgrounds.length > 1
        ? allCampgrounds[1]
        : allCampgrounds.first;
    final thirdCampground = allCampgrounds.length > 2
        ? allCampgrounds[2]
        : allCampgrounds.first;

    return [
      AlternativeSiteSuggestion(
        campground: secondCampground,
        availableSites: _generateTestSites(secondCampground),
        distanceMiles: 15.2,
        reason: 'Similar amenities and activities in the same park system',
      ),
      AlternativeSiteSuggestion(
        campground: thirdCampground,
        availableSites: _generateTestSites(thirdCampground).take(2).toList(),
        distanceMiles: 22.8,
        reason: 'Adjacent park with stunning canyon views',
      ),
    ];
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
