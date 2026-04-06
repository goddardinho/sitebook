import 'package:flutter/material.dart';
import '../../shared/models/campground.dart';
import '../../shared/models/campsite.dart';
import '../../shared/models/campsite_monitoring_settings.dart';
import '../../core/utils/app_logger.dart';

/// Dialog for setting up campsite monitoring preferences
class CampsiteMonitoringSetupDialog extends StatefulWidget {
  final Campground campground;
  final Campsite? initialCampsite;
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final int initialGuestCount;
  final CampsiteMonitoringSettings? existingSettings;

  const CampsiteMonitoringSetupDialog({
    super.key,
    required this.campground,
    this.initialCampsite,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.initialGuestCount,
    this.existingSettings,
  });

  @override
  State<CampsiteMonitoringSetupDialog> createState() =>
      _CampsiteMonitoringSetupDialogState();
}

class _CampsiteMonitoringSetupDialogState
    extends State<CampsiteMonitoringSetupDialog>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form controllers
  late DateTime _startDate;
  late DateTime _endDate;
  late int _guestCount;
  SitePreference _sitePreference = SitePreference.anyAvailable;
  final Set<String> _preferredSiteNumbers = {};
  final Set<String> _preferredSiteTypes = {};
  bool _requireAccessibility = false;
  double? _maxPricePerNight;
  double? _maxTotalCost;
  bool _alertOnPriceDrops = true;
  MonitoringPriority _priority = MonitoringPriority.normal;
  bool _autoReserve = false;
  int _maxNotificationsPerDay = 5;
  bool _enableQuietHours = true;
  int _quietHourStart = 22;
  int _quietHourEnd = 8;
  bool _acceptNearbyCampgrounds = false;
  double _nearbyCampgroundRadiusMiles = 25.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeFromProps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Initialize form values from props or existing settings
  void _initializeFromProps() {
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _guestCount = widget.initialGuestCount;

    final existing = widget.existingSettings;
    if (existing != null) {
      _startDate = existing.startDate;
      _endDate = existing.endDate;
      _guestCount = existing.guestCount;
      _sitePreference = existing.sitePreference;
      _preferredSiteNumbers.addAll(existing.preferredSiteNumbers);
      _preferredSiteTypes.addAll(existing.preferredSiteTypes);
      _requireAccessibility = existing.requireAccessibility;
      _maxPricePerNight = existing.maxPricePerNight;
      _maxTotalCost = existing.maxTotalCost;
      _alertOnPriceDrops = existing.alertOnPriceDrops;
      _priority = existing.priority;
      _autoReserve = existing.autoReserve;
      _maxNotificationsPerDay = existing.maxNotificationsPerDay;
      _enableQuietHours = existing.enableQuietHours;
      _quietHourStart = existing.quietHourStart;
      _quietHourEnd = existing.quietHourEnd;
      _acceptNearbyCampgrounds = existing.acceptNearbyCampgrounds;
      _nearbyCampgroundRadiusMiles = existing.nearbyCampgroundRadiusMiles;
    } else if (widget.initialCampsite != null) {
      // Initialize with specific campsite
      _sitePreference = SitePreference.specificSites;
      _preferredSiteNumbers.add(widget.initialCampsite!.siteNumber);
      if (widget.initialCampsite!.accessibility) {
        _requireAccessibility = true;
      }
      _preferredSiteTypes.add(widget.initialCampsite!.siteType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicSettingsTab(),
                    _buildAdvancedSettingsTab(),
                    _buildNotificationSettingsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomActions(),
      ),
    );
  }

  /// App bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.existingSettings != null
            ? 'Edit Monitoring'
            : 'Set Up Monitoring',
      ),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        TextButton(
          onPressed: _isValid() ? _saveSettings : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  /// Header with campground info
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.campground.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.campground.state} • ${_formatDateRange()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (widget.initialCampsite != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Site ${widget.initialCampsite!.siteNumber}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tab bar
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.settings), text: 'Basic'),
        Tab(icon: Icon(Icons.tune), text: 'Advanced'),
        Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
      ],
    );
  }

  /// Basic settings tab
  Widget _buildBasicSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelection(),
          const SizedBox(height: 24),
          _buildSitePreereences(),
          const SizedBox(height: 24),
          _buildPricePreferences(),
        ],
      ),
    );
  }

  /// Advanced settings tab
  Widget _buildAdvancedSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPrioritySettings(),
          const SizedBox(height: 24),
          _buildAlternativeOptions(),
          const SizedBox(height: 24),
          _buildAutoReserveSettings(),
        ],
      ),
    );
  }

  /// Notification settings tab
  Widget _buildNotificationSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationFrequency(),
          const SizedBox(height: 24),
          _buildQuietHours(),
          const SizedBox(height: 24),
          _buildAlertPreferences(),
        ],
      ),
    );
  }

  /// Date selection section
  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stay Dates',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Check-in',
                date: _startDate,
                onTap: () => _selectDate(true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'Check-out',
                date: _endDate,
                onTap: () => _selectDate(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Guests: ', style: Theme.of(context).textTheme.bodyMedium),
            DropdownButton<int>(
              value: _guestCount,
              items: List.generate(12, (index) {
                final count = index + 1;
                return DropdownMenuItem(value: count, child: Text('$count'));
              }),
              onChanged: (value) => setState(() => _guestCount = value ?? 1),
            ),
          ],
        ),
      ],
    );
  }

  /// Site preferences section
  Widget _buildSitePreereences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Site Preferences',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Site preference type
        DropdownButtonFormField<SitePreference>(
          value: _sitePreference,
          decoration: const InputDecoration(
            labelText: 'Monitoring Type',
            border: OutlineInputBorder(),
          ),
          items: SitePreference.values.map((pref) {
            return DropdownMenuItem(
              value: pref,
              child: Text(_getSitePreferenceLabel(pref)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _sitePreference = value!),
        ),

        const SizedBox(height: 16),

        // Specific preferences based on selection
        if (_sitePreference == SitePreference.specificSites)
          _buildSpecificSiteSelection(),
        if (_sitePreference == SitePreference.siteType)
          _buildSiteTypeSelection(),

        // Accessibility requirement
        CheckboxListTile(
          title: const Text('Require accessible sites'),
          value: _requireAccessibility,
          onChanged: (value) =>
              setState(() => _requireAccessibility = value ?? false),
        ),
      ],
    );
  }

  /// Price preferences section
  Widget _buildPricePreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Preferences',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _maxPricePerNight?.toStringAsFixed(0),
                decoration: const InputDecoration(
                  labelText: 'Max per night (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxPricePerNight = double.tryParse(value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _maxTotalCost?.toStringAsFixed(0),
                decoration: const InputDecoration(
                  labelText: 'Max total (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxTotalCost = double.tryParse(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Priority settings section
  Widget _buildPrioritySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority Settings',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<MonitoringPriority>(
          value: _priority,
          decoration: const InputDecoration(
            labelText: 'Monitoring Priority',
            border: OutlineInputBorder(),
          ),
          items: MonitoringPriority.values.map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Text(_getPriorityLabel(priority)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _priority = value!),
        ),
      ],
    );
  }

  /// Alternative options section
  Widget _buildAlternativeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alternative Options',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        CheckboxListTile(
          title: const Text('Accept nearby campgrounds'),
          subtitle: Text(
            'Within ${_nearbyCampgroundRadiusMiles.toInt()} miles',
          ),
          value: _acceptNearbyCampgrounds,
          onChanged: (value) =>
              setState(() => _acceptNearbyCampgrounds = value ?? false),
        ),

        if (_acceptNearbyCampgrounds) ...[
          Slider(
            value: _nearbyCampgroundRadiusMiles,
            min: 5,
            max: 100,
            divisions: 19,
            label: '${_nearbyCampgroundRadiusMiles.toInt()} miles',
            onChanged: (value) =>
                setState(() => _nearbyCampgroundRadiusMiles = value),
          ),
        ],
      ],
    );
  }

  /// Auto-reserve settings section
  Widget _buildAutoReserveSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auto-Reserve',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        SwitchListTile(
          title: const Text('Automatically reserve when available'),
          subtitle: const Text('Requires stored payment information'),
          value: _autoReserve,
          onChanged: (value) => setState(() => _autoReserve = value),
        ),
      ],
    );
  }

  /// Notification frequency section
  Widget _buildNotificationFrequency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Frequency',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: _maxNotificationsPerDay.toString(),
          decoration: const InputDecoration(
            labelText: 'Max notifications per day',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _maxNotificationsPerDay = int.tryParse(value) ?? 5;
          },
        ),
      ],
    );
  }

  /// Quiet hours section
  Widget _buildQuietHours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiet Hours',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        SwitchListTile(
          title: const Text('Enable quiet hours'),
          subtitle: const Text('Pause notifications during specified hours'),
          value: _enableQuietHours,
          onChanged: (value) => setState(() => _enableQuietHours = value),
        ),

        if (_enableQuietHours) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _quietHourStart,
                  decoration: const InputDecoration(
                    labelText: 'Start time',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(24, (index) {
                    return DropdownMenuItem(
                      value: index,
                      child: Text(_formatHour(index)),
                    );
                  }),
                  onChanged: (value) =>
                      setState(() => _quietHourStart = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _quietHourEnd,
                  decoration: const InputDecoration(
                    labelText: 'End time',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(24, (index) {
                    return DropdownMenuItem(
                      value: index,
                      child: Text(_formatHour(index)),
                    );
                  }),
                  onChanged: (value) => setState(() => _quietHourEnd = value!),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Alert preferences section
  Widget _buildAlertPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alert Preferences',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        CheckboxListTile(
          title: const Text('Price drop alerts'),
          subtitle: const Text('Get notified when prices decrease'),
          value: _alertOnPriceDrops,
          onChanged: (value) =>
              setState(() => _alertOnPriceDrops = value ?? true),
        ),
      ],
    );
  }

  /// Specific site numbers selection
  Widget _buildSpecificSiteSelection() {
    // TODO: Implement site number selection
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Site number selection will be available once campsite data is loaded',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  /// Site type selection
  Widget _buildSiteTypeSelection() {
    final siteTypes = ['Tent', 'RV', 'Group', 'Cabin', 'Standard'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: siteTypes.map((type) {
        return FilterChip(
          label: Text(type),
          selected: _preferredSiteTypes.contains(type),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _preferredSiteTypes.add(type);
              } else {
                _preferredSiteTypes.remove(type);
              }
            });
          },
        );
      }).toList(),
    );
  }

  /// Date field widget
  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          '${date.month}/${date.day}/${date.year}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  /// Bottom action buttons
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isValid() ? _saveSettings : null,
              child: Text(
                widget.existingSettings != null ? 'Update' : 'Start Monitoring',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HELPER METHODS

  /// Select date (start or end)
  Future<void> _selectDate(bool isStart) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = selectedDate;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = selectedDate;
        }
      });
    }
  }

  /// Check if form is valid
  bool _isValid() {
    return _startDate.isBefore(_endDate) &&
        _guestCount > 0 &&
        (_sitePreference != SitePreference.specificSites ||
            _preferredSiteNumbers.isNotEmpty) &&
        (_sitePreference != SitePreference.siteType ||
            _preferredSiteTypes.isNotEmpty);
  }

  /// Save monitoring settings
  void _saveSettings() {
    if (!_formKey.currentState!.validate() || !_isValid()) return;

    final settings = CampsiteMonitoringSettings(
      id:
          widget.existingSettings?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      campgroundId: widget.campground.id,
      userId: 'local_user', // TODO: Use actual user ID if implemented
      startDate: _startDate,
      endDate: _endDate,
      guestCount: _guestCount,
      sitePreference: _sitePreference,
      preferredSiteNumbers: _preferredSiteNumbers.toList(),
      preferredSiteTypes: _preferredSiteTypes.toList(),
      requireAccessibility: _requireAccessibility,
      maxPricePerNight: _maxPricePerNight,
      maxTotalCost: _maxTotalCost,
      alertOnPriceDrops: _alertOnPriceDrops,
      priority: _priority,
      autoReserve: _autoReserve,
      maxNotificationsPerDay: _maxNotificationsPerDay,
      enableQuietHours: _enableQuietHours,
      quietHourStart: _quietHourStart,
      quietHourEnd: _quietHourEnd,
      acceptNearbyCampgrounds: _acceptNearbyCampgrounds,
      nearbyCampgroundRadiusMiles: _nearbyCampgroundRadiusMiles,
      createdAt: widget.existingSettings?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    AppLogger.info('💾 Saving monitoring settings: ${settings.id}');
    Navigator.of(context).pop(settings);
  }

  /// Get site preference label
  String _getSitePreferenceLabel(SitePreference preference) {
    switch (preference) {
      case SitePreference.anyAvailable:
        return 'Any available site';
      case SitePreference.specificSites:
        return 'Specific site numbers';
      case SitePreference.siteType:
        return 'Specific site types';
      case SitePreference.accessibleOnly:
        return 'Accessible sites only';
    }
  }

  /// Get priority label
  String _getPriorityLabel(MonitoringPriority priority) {
    switch (priority) {
      case MonitoringPriority.low:
        return 'Low - Check every 6 hours';
      case MonitoringPriority.normal:
        return 'Normal - Check every 2 hours';
      case MonitoringPriority.high:
        return 'High - Check every hour';
      case MonitoringPriority.critical:
        return 'Critical - Check every 15 minutes';
    }
  }

  /// Format hour for display
  String _formatHour(int hour) {
    final amPm = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $amPm';
  }

  /// Format date range
  String _formatDateRange() {
    return '${_startDate.month}/${_startDate.day} - ${_endDate.month}/${_endDate.day}';
  }
}
