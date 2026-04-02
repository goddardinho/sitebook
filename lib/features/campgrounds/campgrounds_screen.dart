import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/campground_providers_demo.dart';
import '../maps/maps_screen.dart';
import 'widgets/campground_card.dart';

class CampgroundsScreen extends ConsumerStatefulWidget {
  const CampgroundsScreen({super.key});

  @override
  ConsumerState<CampgroundsScreen> createState() => _CampgroundsScreenState();
}

class _CampgroundsScreenState extends ConsumerState<CampgroundsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final actions = ref.read(campgroundActionsProvider);
      actions.updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: _isSearching ? 120 : 100,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                title: _isSearching
                    ? null
                    : Text(
                        'Campgrounds',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withAlpha(230),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isSearching) ...[
                            const SizedBox(height: 16),
                            _buildSearchBar(theme),
                          ],
                          if (!_isSearching) ...[
                            const SizedBox(height: 8),
                            Consumer(
                              builder: (context, ref, child) {
                                final monitoredCountAsync = ref.watch(
                                  monitoredCountProvider,
                                );
                                return monitoredCountAsync.when(
                                  data: (count) =>
                                      _buildHeaderStats(theme, count),
                                  loading: () => _buildHeaderStats(theme, 0),
                                  error: (error, stack) =>
                                      _buildHeaderStats(theme, 0),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: _openMapsView,
                  tooltip: 'Map view',
                ),
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: _toggleSearch,
                  tooltip: _isSearching ? 'Close search' : 'Search campgrounds',
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter campgrounds',
                ),
              ],
            ),
            if (!_isSearching && searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildQuickActions(theme),
                ),
              ),
            Consumer(
              builder: (context, ref, child) {
                if (searchQuery.isNotEmpty) {
                  final filteredCampgroundsAsync = ref.watch(
                    searchResultsProvider,
                  );
                  return filteredCampgroundsAsync.when(
                    data: (campgrounds) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _buildSearchResults(
                          theme,
                          campgrounds.length,
                          searchQuery.query,
                        ),
                      ),
                    ),
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (error, stack) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildSearchResults(theme, 0, searchQuery.query),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ];
        },
        body: Consumer(
          builder: (context, ref, child) {
            final filteredCampgroundsAsync = ref.watch(searchResultsProvider);
            return filteredCampgroundsAsync.when(
              data: (campgrounds) => _buildCampgroundsList(campgrounds),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search campgrounds, parks, or states...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats(ThemeData theme, int monitoredCount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary.withAlpha(51),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility,
                size: 16,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                '$monitoredCount Monitoring',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionChip(
                theme,
                icon: Icons.near_me,
                label: 'Nearby',
                onPressed: _findNearbyCampgrounds,
              ),
              const SizedBox(width: 8),
              _buildActionChip(
                theme,
                icon: Icons.favorite_outline,
                label: 'Popular',
                onPressed: _showPopularCampgrounds,
              ),
              const SizedBox(width: 8),
              _buildActionChip(
                theme,
                icon: Icons.visibility,
                label: 'Monitored',
                onPressed: _showMonitoredOnly,
              ),
              const SizedBox(width: 8),
              _buildActionChip(
                theme,
                icon: Icons.new_releases_outlined,
                label: 'Recently Added',
                onPressed: _showRecentlyAdded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSearchResults(ThemeData theme, int resultCount, String query) {
    return Row(
      children: [
        Icon(Icons.search, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$resultCount results for "$query"',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCampgroundsList(List campgrounds) {
    if (campgrounds.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: campgrounds.length,
      itemBuilder: (context, index) {
        final campground = campgrounds[index];
        return CampgroundCard(campground: campground);
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(searchQueryProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.nature_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'No campgrounds found'
                  : 'No campgrounds available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Check back later for new campgrounds',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openMapsView() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapsScreen()),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _clearSearch();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    final actions = ref.read(campgroundActionsProvider);
    actions.updateSearchQuery('');
  }

  void _showFilterDialog() {
    // TODO: Implement filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filter functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _findNearbyCampgrounds() {
    // TODO: Implement location-based search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nearby search coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPopularCampgrounds() {
    // TODO: Implement popular filter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Popular campgrounds filter coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showMonitoredOnly() {
    final actions = ref.read(campgroundActionsProvider);
    actions.updateSearchQuery(''); // Clear search first

    // TODO: Add monitored-only filter to providers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Showing monitored campgrounds filter coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRecentlyAdded() {
    // TODO: Implement recently added filter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recently added filter coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // Trigger a refresh
                ref.invalidate(searchResultsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
