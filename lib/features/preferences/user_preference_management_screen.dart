import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/user_preference_service.dart';
import '../../shared/models/user_preference.dart';

/// Screen for managing comprehensive user preferences and campsite monitoring settings
class UserPreferenceManagementScreen extends ConsumerStatefulWidget {
  const UserPreferenceManagementScreen({super.key});

  @override
  ConsumerState<UserPreferenceManagementScreen> createState() =>
      _UserPreferenceManagementScreenState();
}

class _UserPreferenceManagementScreenState
    extends ConsumerState<UserPreferenceManagementScreen> {
  final UserPreferenceService _preferenceService = UserPreferenceService();

  UserPreference? _userPreference;
  BudgetSettings? _budgetSettings;
  RateLimitSettings? _rateLimitSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    try {
      await _preferenceService.initialize();

      final userPref = await _preferenceService.getUserPreference();
      final budgetSettings = await _preferenceService.getBudgetSettings();
      final rateLimitSettings = await _preferenceService.getRateLimitSettings();

      setState(() {
        _userPreference = userPref;
        _budgetSettings = budgetSettings;
        _rateLimitSettings = rateLimitSettings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing preferences: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Preferences'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPreferences,
            tooltip: 'Refresh Preferences',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload),
                    SizedBox(width: 8),
                    Text('Export Preferences'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reset All Preferences'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildPreferencesInterface(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading preferences...'),
        ],
      ),
    );
  }

  Widget _buildPreferencesInterface() {
    if (_userPreference == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralPreferencesSection(),
          const SizedBox(height: 24),
          _buildBudgetSettingsSection(),
          const SizedBox(height: 24),
          _buildRateLimitSettingsSection(),
          const SizedBox(height: 24),
          _buildCampsitePreferencesSection(),
          const SizedBox(height: 24),
          _buildDataManagementSection(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('Error loading preferences'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshPreferences,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGeneralPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General Settings', Icons.settings),
            const SizedBox(height: 16),

            // Preferred State
            DropdownButtonFormField<String>(
              value: _userPreference!.preferredState,
              decoration: const InputDecoration(
                labelText: 'Preferred State',
                prefixIcon: Icon(Icons.location_on),
              ),
              items: _getStateOptions(),
              onChanged: (value) => _updateUserPreference(
                _userPreference!.copyWith(preferredState: value),
              ),
            ),

            const SizedBox(height: 16),

            // Max Distance Slider
            Text(
              'Max Distance: ${_userPreference!.maxDistance?.toInt() ?? 50} miles',
            ),
            Slider(
              value: _userPreference!.maxDistance ?? 50.0,
              min: 10.0,
              max: 200.0,
              divisions: 19,
              label: '${_userPreference!.maxDistance?.toInt() ?? 50} miles',
              onChanged: (value) => _updateUserPreference(
                _userPreference!.copyWith(maxDistance: value),
              ),
            ),

            const SizedBox(height: 16),

            // Notifications Toggle
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive availability and price alerts'),
              value: _userPreference!.notificationsEnabled,
              onChanged: (value) => _updateUserPreference(
                _userPreference!.copyWith(notificationsEnabled: value),
              ),
            ),

            // Auto-Reserve Toggle
            SwitchListTile(
              title: const Text('Auto-Reserve'),
              subtitle: const Text(
                'Automatically attempt reservations when criteria met',
              ),
              value: _userPreference!.autoReserveEnabled,
              onChanged: (value) => _updateUserPreference(
                _userPreference!.copyWith(autoReserveEnabled: value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSettingsSection() {
    if (_budgetSettings == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Budget Settings',
              Icons.account_balance_wallet,
            ),
            const SizedBox(height: 16),

            // Max Price Per Night
            Text(
              'Max Price Per Night: \$${_budgetSettings!.maxPricePerNight.toInt()}',
            ),
            Slider(
              value: _budgetSettings!.maxPricePerNight,
              min: 10.0,
              max: 200.0,
              divisions: 19,
              label: '\$${_budgetSettings!.maxPricePerNight.toInt()}',
              onChanged: (value) => _updateBudgetSettings(
                BudgetSettings(
                  maxPricePerNight: value,
                  maxTotalBudget: _budgetSettings!.maxTotalBudget,
                  enableBudgetAlerts: _budgetSettings!.enableBudgetAlerts,
                  trackSpending: _budgetSettings!.trackSpending,
                  alertThreshold: _budgetSettings!.alertThreshold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Total Budget
            Text(
              'Max Total Budget: \$${_budgetSettings!.maxTotalBudget.toInt()}',
            ),
            Slider(
              value: _budgetSettings!.maxTotalBudget,
              min: 100.0,
              max: 2000.0,
              divisions: 19,
              label: '\$${_budgetSettings!.maxTotalBudget.toInt()}',
              onChanged: (value) => _updateBudgetSettings(
                BudgetSettings(
                  maxPricePerNight: _budgetSettings!.maxPricePerNight,
                  maxTotalBudget: value,
                  enableBudgetAlerts: _budgetSettings!.enableBudgetAlerts,
                  trackSpending: _budgetSettings!.trackSpending,
                  alertThreshold: _budgetSettings!.alertThreshold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Budget Alerts
            SwitchListTile(
              title: const Text('Budget Alerts'),
              subtitle: Text(
                'Alert when ${(_budgetSettings!.alertThreshold * 100).toInt()}% of budget spent',
              ),
              value: _budgetSettings!.enableBudgetAlerts,
              onChanged: (value) => _updateBudgetSettings(
                BudgetSettings(
                  maxPricePerNight: _budgetSettings!.maxPricePerNight,
                  maxTotalBudget: _budgetSettings!.maxTotalBudget,
                  enableBudgetAlerts: value,
                  trackSpending: _budgetSettings!.trackSpending,
                  alertThreshold: _budgetSettings!.alertThreshold,
                ),
              ),
            ),

            // Spending Tracking
            SwitchListTile(
              title: const Text('Track Spending'),
              subtitle: const Text('Monitor camping expenses and history'),
              value: _budgetSettings!.trackSpending,
              onChanged: (value) => _updateBudgetSettings(
                BudgetSettings(
                  maxPricePerNight: _budgetSettings!.maxPricePerNight,
                  maxTotalBudget: _budgetSettings!.maxTotalBudget,
                  enableBudgetAlerts: _budgetSettings!.enableBudgetAlerts,
                  trackSpending: value,
                  alertThreshold: _budgetSettings!.alertThreshold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateLimitSettingsSection() {
    if (_rateLimitSettings == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Rate Limiting', Icons.speed),
            const SizedBox(height: 16),

            Text(
              'Max Checks Per Hour: ${_rateLimitSettings!.maxChecksPerHour}',
            ),
            Slider(
              value: _rateLimitSettings!.maxChecksPerHour.toDouble(),
              min: 1.0,
              max: 12.0,
              divisions: 11,
              label: '${_rateLimitSettings!.maxChecksPerHour}',
              onChanged: (value) => _updateRateLimitSettings(
                RateLimitSettings(
                  maxChecksPerHour: value.round(),
                  maxNotificationsPerDay:
                      _rateLimitSettings!.maxNotificationsPerDay,
                  respectQuietHours: _rateLimitSettings!.respectQuietHours,
                  enableRateLimiting: _rateLimitSettings!.enableRateLimiting,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Max Notifications Per Day: ${_rateLimitSettings!.maxNotificationsPerDay}',
            ),
            Slider(
              value: _rateLimitSettings!.maxNotificationsPerDay.toDouble(),
              min: 5.0,
              max: 50.0,
              divisions: 9,
              label: '${_rateLimitSettings!.maxNotificationsPerDay}',
              onChanged: (value) => _updateRateLimitSettings(
                RateLimitSettings(
                  maxChecksPerHour: _rateLimitSettings!.maxChecksPerHour,
                  maxNotificationsPerDay: value.round(),
                  respectQuietHours: _rateLimitSettings!.respectQuietHours,
                  enableRateLimiting: _rateLimitSettings!.enableRateLimiting,
                ),
              ),
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Respect Quiet Hours'),
              subtitle: const Text('Pause notifications during quiet hours'),
              value: _rateLimitSettings!.respectQuietHours,
              onChanged: (value) => _updateRateLimitSettings(
                RateLimitSettings(
                  maxChecksPerHour: _rateLimitSettings!.maxChecksPerHour,
                  maxNotificationsPerDay:
                      _rateLimitSettings!.maxNotificationsPerDay,
                  respectQuietHours: value,
                  enableRateLimiting: _rateLimitSettings!.enableRateLimiting,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampsitePreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Campsite Preferences', Icons.park),
            const SizedBox(height: 16),

            // Preferred Amenities
            const Text(
              'Preferred Amenities',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Wrap(spacing: 8, children: _getAmenityChips()),

            const SizedBox(height: 16),

            // Favorites and History
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _viewFavorites,
                    icon: const Icon(Icons.favorite),
                    label: Text(
                      'Favorites (${_preferenceService.getFavoriteCampgrounds().length})',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _viewRecentSearches,
                    icon: const Icon(Icons.history),
                    label: Text(
                      'Recent (${_preferenceService.getRecentSearches().length})',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Data Management', Icons.cloud_sync),
            const SizedBox(height: 16),

            // Sync Information
            if (_preferenceService.getLastSyncTimestamp() != null) ...[
              Text(
                'Last Sync: ${_formatDateTime(_preferenceService.getLastSyncTimestamp()!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],

            // Data Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportPreferences,
                    icon: const Icon(Icons.upload),
                    label: const Text('Export'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearRecentData,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Recent'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getStateOptions() {
    final states = [
      'CA',
      'CO',
      'UT',
      'AZ',
      'WY',
      'MT',
      'ID',
      'NV',
      'OR',
      'WA',
      'AK',
      'HI',
      'TX',
      'FL',
      'NY',
      'NC',
      'TN',
      'VA',
      'WV',
      'KY',
    ];

    return states
        .map((state) => DropdownMenuItem(value: state, child: Text(state)))
        .toList();
  }

  List<Widget> _getAmenityChips() {
    final allAmenities = [
      'Restrooms',
      'Showers',
      'Potable Water',
      'Fire Rings',
      'Picnic Tables',
      'Electric Hookup',
      'Water Hookup',
      'Sewer Hookup',
      'Pet Friendly',
      'WiFi',
      'Store',
      'Laundry',
      'Dump Station',
      'Playground',
    ];

    final selectedAmenities = _userPreference!.preferredAmenities;

    return allAmenities.map((amenity) {
      final isSelected = selectedAmenities.contains(amenity);
      return FilterChip(
        label: Text(amenity),
        selected: isSelected,
        onSelected: (selected) {
          final newAmenities = List<String>.from(selectedAmenities);
          if (selected) {
            newAmenities.add(amenity);
          } else {
            newAmenities.remove(amenity);
          }
          _updateUserPreference(
            _userPreference!.copyWith(preferredAmenities: newAmenities),
          );
        },
      );
    }).toList();
  }

  // Helper methods

  Future<void> _updateUserPreference(UserPreference preference) async {
    await _preferenceService.saveUserPreference(preference);
    setState(() {
      _userPreference = preference;
    });
    _showSnackBar('Preferences updated');
  }

  Future<void> _updateBudgetSettings(BudgetSettings settings) async {
    await _preferenceService.saveBudgetSettings(settings);
    setState(() {
      _budgetSettings = settings;
    });
    _showSnackBar('Budget settings updated');
  }

  Future<void> _updateRateLimitSettings(RateLimitSettings settings) async {
    await _preferenceService.saveRateLimitSettings(settings);
    setState(() {
      _rateLimitSettings = settings;
    });
    _showSnackBar('Rate limit settings updated');
  }

  Future<void> _refreshPreferences() async {
    setState(() {
      _isLoading = true;
    });
    await _initializePreferences();
    _showSnackBar('Preferences refreshed');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportPreferences();
        break;
      case 'reset':
        _confirmResetPreferences();
        break;
    }
  }

  Future<void> _exportPreferences() async {
    try {
      final export = await _preferenceService.exportPreferences();
      _showSnackBar('Exported ${export.length} preferences');
      // In a real app, you'd implement actual export functionality
      debugPrint('Exported preferences: ${export.keys}');
    } catch (e) {
      _showSnackBar('Export failed: $e');
    }
  }

  void _confirmResetPreferences() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Preferences'),
        content: const Text(
          'This will permanently delete all your preferences, favorites, and history. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetAllPreferences();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllPreferences() async {
    await _preferenceService.clearAllPreferences();
    await _initializePreferences();
    _showSnackBar('All preferences reset');
  }

  Future<void> _clearRecentData() async {
    await _preferenceService.clearRecentSearches();
    _showSnackBar('Recent data cleared');
  }

  void _viewFavorites() {
    // Navigate to favorites view - would be implemented in a real app
    _showSnackBar(
      'Favorites: ${_preferenceService.getFavoriteCampgrounds().length} campgrounds',
    );
  }

  void _viewRecentSearches() {
    final searches = _preferenceService.getRecentSearches();
    _showSnackBar('Recent searches: ${searches.take(3).join(', ')}');
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
