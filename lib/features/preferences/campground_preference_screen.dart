import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/campground_preference_service.dart';
import '../../shared/services/user_preference_service.dart';
import '../../shared/models/campground.dart';
import '../../shared/models/campsite_monitoring_settings.dart';

/// Screen for managing campground-specific preferences and global site settings
class CampgroundPreferenceScreen extends ConsumerStatefulWidget {
  final String? campgroundId;

  const CampgroundPreferenceScreen({super.key, this.campgroundId});

  @override
  ConsumerState<CampgroundPreferenceScreen> createState() =>
      _CampgroundPreferenceScreenState();
}

class _CampgroundPreferenceScreenState
    extends ConsumerState<CampgroundPreferenceScreen>
    with TickerProviderStateMixin {
  final CampgroundPreferenceService _campgroundService =
      CampgroundPreferenceService();
  final UserPreferenceService _userService = UserPreferenceService();

  late TabController _tabController;

  // Global preferences
  GlobalSitePreferences? _globalPreferences;
  DeviceSyncSettings? _syncSettings;

  // Campground-specific preferences
  Map<String, CampgroundSpecificPreferences> _campgroundPreferences = {};

  // UI state
  bool _isLoading = true;
  bool _hasChanges = false;
  List<Campground> _demoCampgrounds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _campgroundService.initialize();
      await _userService.initialize();

      _globalPreferences = await _campgroundService.getGlobalSitePreferences();
      _syncSettings = await _campgroundService.getDeviceSyncSettings();
      _campgroundPreferences = await _campgroundService
          .getAllCampgroundPreferences();

      // Create mock campgrounds for demo
      _demoCampgrounds = [
        Campground(
          id: 'demo_1',
          name: 'Yosemite Valley',
          description: 'Iconic valley campground',
          latitude: 37.7749,
          longitude: -119.4194,
          state: 'California',
          parkName: 'Yosemite National Park',
          amenities: ['Restrooms', 'Water'],
          activities: ['Hiking', 'Photography'],
          imageUrls: [],
          isMonitored: false,
        ),
        Campground(
          id: 'demo_2',
          name: 'Grand Canyon South Rim',
          description: 'Canyon rim campground',
          latitude: 36.0544,
          longitude: -112.1401,
          state: 'Arizona',
          parkName: 'Grand Canyon National Park',
          amenities: ['Showers', 'Store'],
          activities: ['Sightseeing', 'Hiking'],
          imageUrls: [],
          isMonitored: false,
        ),
      ];

      // If campground ID specified, switch to campground-specific tab
      if (widget.campgroundId != null) {
        _tabController.index = 1;
      }
    } catch (e) {
      debugPrint('❌ Error loading campground preferences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGlobalPreferences() async {
    if (_globalPreferences != null) {
      await _campgroundService.saveGlobalSitePreferences(_globalPreferences!);
      setState(() => _hasChanges = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Global site preferences saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _saveCampgroundPreferences(String campgroundId) async {
    final preferences = _campgroundPreferences[campgroundId];
    if (preferences != null) {
      await _campgroundService.saveCampgroundPreferences(
        campgroundId,
        preferences,
      );
      setState(() => _hasChanges = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Preferences saved for ${_getCampgroundName(campgroundId)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _saveSyncSettings() async {
    if (_syncSettings != null) {
      await _campgroundService.configureDeviceSync(_syncSettings!);
      setState(() => _hasChanges = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Device sync settings saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _performSync() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Syncing preferences...'),
            ],
          ),
        );
      },
    );

    await _campgroundService.performDeviceSync();
    await _loadData(); // Refresh data after sync

    if (mounted) {
      Navigator.of(context).pop(); // Close progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Device sync completed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _getCampgroundName(String campgroundId) {
    try {
      final campground = _demoCampgrounds.firstWhere(
        (c) => c.id == campgroundId,
      );
      return campground.name;
    } catch (e) {
      return 'Unknown Campground';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campground Preferences'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.public), text: 'Global'),
            Tab(icon: Icon(Icons.location_on), text: 'Campgrounds'),
            Tab(icon: Icon(Icons.sync), text: 'Device Sync'),
          ],
        ),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _showSaveDialog(),
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGlobalPreferencesTab(),
                _buildCampgroundPreferencesTab(),
                _buildDeviceSyncTab(),
              ],
            ),
    );
  }

  Widget _buildGlobalPreferencesTab() {
    if (_globalPreferences == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.public, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Global Site Preferences',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These preferences apply to all campgrounds unless overridden by campground-specific settings.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Preferred Site Types
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferred Site Types',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                              'Standard',
                              'Electric',
                              'Water/Electric',
                              'Full Hookup',
                              'Tent-Only',
                              'RV-Only',
                              'Group',
                            ]
                            .map(
                              (type) => FilterChip(
                                label: Text(type),
                                selected: _globalPreferences!.preferredSiteTypes
                                    .contains(type),
                                onSelected: (selected) {
                                  setState(() {
                                    _hasChanges = true;
                                    final types = List<String>.from(
                                      _globalPreferences!.preferredSiteTypes,
                                    );
                                    if (selected) {
                                      types.add(type);
                                    } else {
                                      types.remove(type);
                                    }
                                    _globalPreferences = GlobalSitePreferences(
                                      preferredSiteTypes: types,
                                      requireAccessibility: _globalPreferences!
                                          .requireAccessibility,
                                      maxPricePerNight:
                                          _globalPreferences!.maxPricePerNight,
                                      defaultPriority:
                                          _globalPreferences!.defaultPriority,
                                      enableSmartDefaults: _globalPreferences!
                                          .enableSmartDefaults,
                                      lastUpdated: DateTime.now(),
                                    );
                                  });
                                },
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Accessibility and Pricing
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Site Requirements',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: const Text('Require Accessibility'),
                    subtitle: const Text('Only show accessible campsites'),
                    value: _globalPreferences!.requireAccessibility ?? false,
                    onChanged: (value) {
                      setState(() {
                        _hasChanges = true;
                        _globalPreferences = GlobalSitePreferences(
                          preferredSiteTypes:
                              _globalPreferences!.preferredSiteTypes,
                          requireAccessibility: value,
                          maxPricePerNight:
                              _globalPreferences!.maxPricePerNight,
                          defaultPriority: _globalPreferences!.defaultPriority,
                          enableSmartDefaults:
                              _globalPreferences!.enableSmartDefaults,
                          lastUpdated: DateTime.now(),
                        );
                      });
                    },
                  ),

                  const Divider(),

                  ListTile(
                    title: const Text('Maximum Price Per Night'),
                    subtitle: Text(
                      '\$${_globalPreferences!.maxPricePerNight?.toStringAsFixed(0) ?? "No limit"}',
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showPriceEditor(),
                  ),

                  const Divider(),

                  ListTile(
                    title: const Text('Default Priority'),
                    subtitle: Text(
                      _globalPreferences!.defaultPriority?.name.toUpperCase() ??
                          'Normal',
                    ),
                    trailing: DropdownButton<MonitoringPriority>(
                      value:
                          _globalPreferences!.defaultPriority ??
                          MonitoringPriority.normal,
                      onChanged: (priority) {
                        if (priority != null) {
                          setState(() {
                            _hasChanges = true;
                            _globalPreferences = GlobalSitePreferences(
                              preferredSiteTypes:
                                  _globalPreferences!.preferredSiteTypes,
                              requireAccessibility:
                                  _globalPreferences!.requireAccessibility,
                              maxPricePerNight:
                                  _globalPreferences!.maxPricePerNight,
                              defaultPriority: priority,
                              enableSmartDefaults:
                                  _globalPreferences!.enableSmartDefaults,
                              lastUpdated: DateTime.now(),
                            );
                          });
                        }
                      },
                      items: MonitoringPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority.name.toUpperCase()),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _hasChanges ? _saveGlobalPreferences : null,
              icon: const Icon(Icons.save),
              label: const Text('Save Global Preferences'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampgroundPreferencesTab() {
    final campgrounds = widget.campgroundId != null
        ? _demoCampgrounds.where((c) => c.id == widget.campgroundId).toList()
        : _demoCampgrounds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Campground-Specific Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Customize settings for individual campgrounds. These override global preferences.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (campgrounds.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('No campgrounds found'),
                subtitle: Text(
                  'Campground preferences will appear here once you start monitoring sites.',
                ),
              ),
            )
          else
            ...campgrounds.map(
              (campground) => _buildCampgroundPreferenceCard(campground),
            ),
        ],
      ),
    );
  }

  Widget _buildCampgroundPreferenceCard(Campground campground) {
    final preferences =
        _campgroundPreferences[campground.id] ??
        CampgroundSpecificPreferences.defaultSettings(campground.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.landscape, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          campground.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${campground.state} • ${preferences.preferredSiteNumbers.length} preferred sites',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preferred Site Numbers
                Text(
                  'Preferred Site Numbers',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: preferences.preferredSiteNumbers.join(', '),
                  decoration: const InputDecoration(
                    hintText: 'e.g., A-15, B-22, C-08',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final siteNumbers = value
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();

                    _updateCampgroundPreference(
                      campground.id,
                      preferences.copyWith(
                        preferredSiteNumbers: siteNumbers,
                        lastUpdated: DateTime.now(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Max Notifications
                Text(
                  'Maximum Notifications Per Day',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Slider(
                  value: (preferences.maxNotificationsPerDay ?? 10).toDouble(),
                  min: 0,
                  max: 50,
                  divisions: 10,
                  label: '${preferences.maxNotificationsPerDay ?? 10}',
                  onChanged: (value) {
                    _updateCampgroundPreference(
                      campground.id,
                      preferences.copyWith(
                        maxNotificationsPerDay: value.round(),
                        lastUpdated: DateTime.now(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Quiet Hours
                SwitchListTile(
                  title: const Text('Respect Quiet Hours'),
                  subtitle: const Text(
                    'Limit notifications during quiet times',
                  ),
                  value: preferences.respectQuietHours ?? false,
                  onChanged: (value) {
                    _updateCampgroundPreference(
                      campground.id,
                      preferences.copyWith(
                        respectQuietHours: value,
                        lastUpdated: DateTime.now(),
                      ),
                    );
                  },
                ),

                if (preferences.respectQuietHours == true) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Quiet Start'),
                          subtitle: Text(
                            '${preferences.customQuietHourStart ?? 22}:00',
                          ),
                          onTap: () => _showTimePicker(
                            campground.id,
                            preferences,
                            isStartTime: true,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Quiet End'),
                          subtitle: Text(
                            '${preferences.customQuietHourEnd ?? 7}:00',
                          ),
                          onTap: () => _showTimePicker(
                            campground.id,
                            preferences,
                            isStartTime: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _hasChanges
                        ? () => _saveCampgroundPreferences(campground.id)
                        : null,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Preferences'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSyncTab() {
    if (_syncSettings == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sync, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Device Synchronization',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep your preferences synchronized across all your devices.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sync Settings
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Auto Sync'),
                  subtitle: const Text(
                    'Automatically sync preferences across devices',
                  ),
                  value: _syncSettings!.enableAutoSync,
                  onChanged: (value) {
                    setState(() {
                      _hasChanges = true;
                      _syncSettings = DeviceSyncSettings(
                        enableAutoSync: value,
                        syncIntervalHours: _syncSettings!.syncIntervalHours,
                        syncOverWifiOnly: _syncSettings!.syncOverWifiOnly,
                        syncPreferences: _syncSettings!.syncPreferences,
                        syncHistory: _syncSettings!.syncHistory,
                        syncFavorites: _syncSettings!.syncFavorites,
                        cloudProvider: _syncSettings!.cloudProvider,
                      );
                    });
                  },
                ),

                if (_syncSettings!.enableAutoSync) ...[
                  const Divider(),

                  ListTile(
                    title: const Text('Sync Interval'),
                    subtitle: Text(
                      'Every ${_syncSettings!.syncIntervalHours} hours',
                    ),
                    trailing: DropdownButton<int>(
                      value: _syncSettings!.syncIntervalHours,
                      onChanged: (hours) {
                        if (hours != null) {
                          setState(() {
                            _hasChanges = true;
                            _syncSettings = DeviceSyncSettings(
                              enableAutoSync: _syncSettings!.enableAutoSync,
                              syncIntervalHours: hours,
                              syncOverWifiOnly: _syncSettings!.syncOverWifiOnly,
                              syncPreferences: _syncSettings!.syncPreferences,
                              syncHistory: _syncSettings!.syncHistory,
                              syncFavorites: _syncSettings!.syncFavorites,
                              cloudProvider: _syncSettings!.cloudProvider,
                            );
                          });
                        }
                      },
                      items: [1, 2, 6, 12, 24].map((hours) {
                        return DropdownMenuItem(
                          value: hours,
                          child: Text(
                            '$hours ${hours == 1 ? 'hour' : 'hours'}',
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const Divider(),

                  SwitchListTile(
                    title: const Text('WiFi Only'),
                    subtitle: const Text('Only sync when connected to WiFi'),
                    value: _syncSettings!.syncOverWifiOnly,
                    onChanged: (value) {
                      setState(() {
                        _hasChanges = true;
                        _syncSettings = DeviceSyncSettings(
                          enableAutoSync: _syncSettings!.enableAutoSync,
                          syncIntervalHours: _syncSettings!.syncIntervalHours,
                          syncOverWifiOnly: value,
                          syncPreferences: _syncSettings!.syncPreferences,
                          syncHistory: _syncSettings!.syncHistory,
                          syncFavorites: _syncSettings!.syncFavorites,
                          cloudProvider: _syncSettings!.cloudProvider,
                        );
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sync Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Last Sync'),
                    subtitle: Text(
                      _campgroundService.getLastFullSyncTimestamp() != null
                          ? 'Synced ${_formatTimestamp(_campgroundService.getLastFullSyncTimestamp()!)}'
                          : 'Never synced',
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.cloud),
                    title: const Text('Cloud Provider'),
                    subtitle: Text(
                      _syncSettings!.cloudProvider ?? 'Local only',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasChanges ? _saveSyncSettings : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Settings'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _performSync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateCampgroundPreference(
    String campgroundId,
    CampgroundSpecificPreferences preferences,
  ) {
    setState(() {
      _hasChanges = true;
      _campgroundPreferences[campgroundId] = preferences;
    });
  }

  void _showPriceEditor() {
    final controller = TextEditingController(
      text: _globalPreferences!.maxPricePerNight?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Price Per Night'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Max Price (\$)',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final price = double.tryParse(controller.text);
              setState(() {
                _hasChanges = true;
                _globalPreferences = GlobalSitePreferences(
                  preferredSiteTypes: _globalPreferences!.preferredSiteTypes,
                  requireAccessibility:
                      _globalPreferences!.requireAccessibility,
                  maxPricePerNight: price,
                  defaultPriority: _globalPreferences!.defaultPriority,
                  enableSmartDefaults: _globalPreferences!.enableSmartDefaults,
                  lastUpdated: DateTime.now(),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(
    String campgroundId,
    CampgroundSpecificPreferences preferences, {
    required bool isStartTime,
  }) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: isStartTime
            ? (preferences.customQuietHourStart ?? 22)
            : (preferences.customQuietHourEnd ?? 7),
        minute: 0,
      ),
    ).then((time) {
      if (time != null) {
        _updateCampgroundPreference(
          campgroundId,
          preferences.copyWith(
            customQuietHourStart: isStartTime
                ? time.hour
                : preferences.customQuietHourStart,
            customQuietHourEnd: !isStartTime
                ? time.hour
                : preferences.customQuietHourEnd,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    });
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Changes'),
        content: const Text(
          'You have unsaved changes. What would you like to save?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (_tabController.index == 0)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _saveGlobalPreferences();
              },
              child: const Text('Save Global'),
            ),
          if (_tabController.index == 2)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _saveSyncSettings();
              },
              child: const Text('Save Sync'),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
  }
}
