import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/campground.dart';
import '../../shared/models/campsite.dart';
import '../../shared/models/campsite_monitoring_settings.dart';
import '../widgets/campsite_card.dart';
import '../widgets/campsite_filter_bar.dart';
import '../widgets/campsite_monitoring_setup_dialog.dart';
import '../../core/utils/app_logger.dart';

/// Screen for selecting and configuring campsite monitoring
class CampsiteSelectionScreen extends ConsumerStatefulWidget {
  final Campground campground;
  final DateTime startDate;
  final DateTime endDate;
  final int guestCount;

  const CampsiteSelectionScreen({
    super.key,
    required this.campground,
    required this.startDate,
    required this.endDate,
    required this.guestCount,
  });

  @override
  ConsumerState<CampsiteSelectionScreen> createState() =>
      _CampsiteSelectionScreenState();
}

class _CampsiteSelectionScreenState
    extends ConsumerState<CampsiteSelectionScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Filter state
  String _searchQuery = '';
  Set<String> _selectedSiteTypes = {};
  bool _accessibilityFilter = false;
  double? _maxPriceFilter;
  bool _availableOnlyFilter = true;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    AppLogger.info(
      '🏕️ Campsite Selection Screen opened for ${widget.campground.name}',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCampsiteListView(),
                _buildCampsiteMapView(),
                _buildMyMonitoringView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildQuickActionsFAB(),
    );
  }

  /// App bar with campground context
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Campsites',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            widget.campground.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(_showMap ? Icons.list : Icons.map),
          tooltip: _showMap ? 'List View' : 'Map View',
          onPressed: () => setState(() => _showMap = !_showMap),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'monitor_any',
              child: ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Monitor Any Available'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'view_alternatives',
              child: ListTile(
                leading: Icon(Icons.alt_route),
                title: Text('View Alternatives'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'price_alerts',
              child: ListTile(
                leading: Icon(Icons.trending_down),
                title: Text('Price Drop Alerts'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Header with date range and guest info
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
                  'Stay Dates',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(widget.startDate)} - ${_formatDate(widget.endDate)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_calculateNights()} nights',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Guests',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${widget.guestCount}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Filter and search bar
  Widget _buildFilterBar() {
    return CampsiteFilterBar(
      searchController: _searchController,
      onSearchChanged: (query) => setState(() => _searchQuery = query),
      selectedSiteTypes: _selectedSiteTypes,
      onSiteTypesChanged: (types) => setState(() => _selectedSiteTypes = types),
      accessibilityFilter: _accessibilityFilter,
      onAccessibilityChanged: (value) =>
          setState(() => _accessibilityFilter = value),
      maxPrice: _maxPriceFilter,
      onMaxPriceChanged: (price) => setState(() => _maxPriceFilter = price),
      availableOnly: _availableOnlyFilter,
      onAvailableOnlyChanged: (value) =>
          setState(() => _availableOnlyFilter = value),
    );
  }

  /// Tab bar for different views
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.list), text: 'Campsites'),
        Tab(icon: Icon(Icons.map), text: 'Site Map'),
        Tab(icon: Icon(Icons.favorite), text: 'Monitoring'),
      ],
    );
  }

  /// List view of campsites
  Widget _buildCampsiteListView() {
    return Consumer(
      builder: (context, ref, child) {
        // TODO: Watch campsites provider
        final campsitesAsync = ref.watch(
          campsitesByCampgroundProvider(widget.campground.id),
        );

        return campsitesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorView(error.toString()),
          data: (campsites) {
            final filteredCampsites = _filterCampsites(campsites);

            if (filteredCampsites.isEmpty) {
              return _buildEmptyStateView();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredCampsites.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final campsite = filteredCampsites[index];
                return CampsiteCard(
                  campsite: campsite,
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                  guestCount: widget.guestCount,
                  onMonitorTap: () => _showMonitoringDialog(campsite),
                  onReserveTap: () => _handleReservation(campsite),
                  onDetailsTap: () => _showCampsiteDetails(campsite),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Map view of campsites (placeholder)
  Widget _buildCampsiteMapView() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Interactive Site Map',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon: Interactive campground map with individual site selection',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _tabController.animateTo(0),
            icon: const Icon(Icons.list),
            label: const Text('View Site List'),
          ),
        ],
      ),
    );
  }

  /// My monitoring view
  Widget _buildMyMonitoringView() {
    return Consumer(
      builder: (context, ref, child) {
        // TODO: Watch monitoring settings provider
        final monitoringAsync = ref.watch(
          monitoringSettingsByCampgroundProvider(widget.campground.id),
        );

        return monitoringAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorView(error.toString()),
          data: (settings) {
            if (settings.isEmpty) {
              return _buildNoMonitoringView();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: settings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final setting = settings[index];
                return _buildMonitoringCard(setting);
              },
            );
          },
        );
      },
    );
  }

  /// Error view
  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load campsites',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Retry loading
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Empty state when no campsites match filters
  Widget _buildEmptyStateView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No campsites found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _clearFilters,
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  /// No monitoring setup view
  Widget _buildNoMonitoringView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No monitoring setup',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Set up monitoring to get notified when campsites become available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showMonitoringDialog(null),
            icon: const Icon(Icons.add_alert),
            label: const Text('Set Up Monitoring'),
          ),
        ],
      ),
    );
  }

  /// Monitoring settings card
  Widget _buildMonitoringCard(CampsiteMonitoringSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: settings.isActive
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    settings.isActive ? 'Active' : 'Paused',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: settings.isActive
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: settings.isActive,
                  onChanged: (value) => _toggleMonitoring(settings.id, value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getMonitoringDescription(settings),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(settings.startDate)} - ${_formatDate(settings.endDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (settings.maxPricePerNight != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Max \$${settings.maxPricePerNight!.toStringAsFixed(2)}/night',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _editMonitoring(settings),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteMonitoring(settings.id),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Quick actions floating action button
  Widget _buildQuickActionsFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showMonitoringDialog(null),
      icon: const Icon(Icons.add_alert),
      label: const Text('Monitor Sites'),
    );
  }

  // HELPER METHODS

  /// Filter campsites based on current filters
  List<Campsite> _filterCampsites(List<Campsite> campsites) {
    return campsites.where((campsite) {
      if (_searchQuery.isNotEmpty &&
          !campsite.siteNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) &&
          !campsite.siteType.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          )) {
        return false;
      }

      if (_selectedSiteTypes.isNotEmpty &&
          !_selectedSiteTypes.contains(campsite.siteType)) {
        return false;
      }

      if (_accessibilityFilter && !campsite.accessibility) {
        return false;
      }

      if (_maxPriceFilter != null &&
          campsite.pricePerNight != null &&
          campsite.pricePerNight! > _maxPriceFilter!) {
        return false;
      }

      if (_availableOnlyFilter && !campsite.isAvailable) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedSiteTypes.clear();
      _accessibilityFilter = false;
      _maxPriceFilter = null;
      _availableOnlyFilter = false;
    });
    _searchController.clear();
  }

  /// Show monitoring setup dialog
  void _showMonitoringDialog(Campsite? campsite) {
    showDialog(
      context: context,
      builder: (context) => CampsiteMonitoringSetupDialog(
        campground: widget.campground,
        initialCampsite: campsite,
        initialStartDate: widget.startDate,
        initialEndDate: widget.endDate,
        initialGuestCount: widget.guestCount,
      ),
    );
  }

  /// Show campsite details
  void _showCampsiteDetails(Campsite campsite) {
    // TODO: Navigate to campsite details screen
    AppLogger.info('📋 Showing details for campsite ${campsite.siteNumber}');
  }

  /// Handle reservation
  void _handleReservation(Campsite campsite) {
    // TODO: Open reservation URL or navigate to reservation screen
    AppLogger.info(
      '🎫 Handling reservation for campsite ${campsite.siteNumber}',
    );
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'monitor_any':
        _showMonitoringDialog(null);
        break;
      case 'view_alternatives':
        // TODO: Show alternative campgrounds
        break;
      case 'price_alerts':
        // TODO: Set up price drop alerts
        break;
    }
  }

  /// Toggle monitoring status
  void _toggleMonitoring(String settingsId, bool isActive) {
    // TODO: Update monitoring settings
    AppLogger.info('🔔 Toggling monitoring $settingsId to $isActive');
  }

  /// Edit monitoring settings
  void _editMonitoring(CampsiteMonitoringSettings settings) {
    // TODO: Open edit monitoring dialog
    AppLogger.info('✏️ Editing monitoring settings ${settings.id}');
  }

  /// Delete monitoring settings
  void _deleteMonitoring(String settingsId) {
    // TODO: Delete monitoring settings with confirmation
    AppLogger.info('🗑️ Deleting monitoring settings $settingsId');
  }

  /// Get monitoring description text
  String _getMonitoringDescription(CampsiteMonitoringSettings settings) {
    switch (settings.sitePreference) {
      case SitePreference.specificSites:
        return 'Monitoring sites: ${settings.preferredSiteNumbers.join(', ')}';
      case SitePreference.siteType:
        return 'Monitoring ${settings.preferredSiteTypes.join(', ')} sites';
      case SitePreference.accessibleOnly:
        return 'Monitoring accessible sites only';
      case SitePreference.anyAvailable:
        return 'Monitoring any available site';
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Calculate number of nights
  int _calculateNights() {
    return widget.endDate.difference(widget.startDate).inDays;
  }
}

// PLACEHOLDER PROVIDERS (to be implemented)
final campsitesByCampgroundProvider =
    FutureProvider.family<List<Campsite>, String>((ref, campgroundId) async {
      // TODO: Implement actual provider
      return [];
    });

final monitoringSettingsByCampgroundProvider =
    FutureProvider.family<List<CampsiteMonitoringSettings>, String>((
      ref,
      campgroundId,
    ) async {
      // TODO: Implement actual provider
      return [];
    });
