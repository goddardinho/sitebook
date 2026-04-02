import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/campground_providers_ios_compatible.dart';

class CampgroundsScreenIOSCompatible extends ConsumerStatefulWidget {
  const CampgroundsScreenIOSCompatible({super.key});

  @override
  ConsumerState<CampgroundsScreenIOSCompatible> createState() =>
      _CampgroundsScreenIOSCompatibleState();
}

class _CampgroundsScreenIOSCompatibleState
    extends ConsumerState<CampgroundsScreenIOSCompatible> {
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
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        final actions = ref.read(campgroundActionsProvider);
                        actions.updateSearchQuery('');
                      }
                    });
                  },
                ),
              ],
            ),
          ];
        },
        body: Consumer(
          builder: (context, ref, child) {
            final searchResultsAsync = ref.watch(searchResultsProvider);

            return searchResultsAsync.when(
              data: (campgrounds) =>
                  _buildCampgroundsList(context, campgrounds),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading campgrounds',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(searchResultsProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search campgrounds, parks, states...',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats(ThemeData theme, int monitoredCount) {
    return Row(
      children: [
        Icon(
          Icons.favorite,
          color: theme.colorScheme.onPrimary.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          '$monitoredCount Monitored',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildCampgroundsList(BuildContext context, List campgrounds) {
    if (campgrounds.isEmpty) {
      final theme = Theme.of(context);
      final searchQuery = ref.watch(searchQueryProvider);

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.terrain,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'No campgrounds found'
                  : 'No campgrounds available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: campgrounds.length,
      itemBuilder: (context, index) {
        final campground = campgrounds[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // iOS-compatible action - simple snackbar instead of complex navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected: ${campground.name}'),
                    action: SnackBarAction(
                      label: 'VIEW DETAILS',
                      onPressed: () {
                        // TODO: Implement iOS-compatible details view when ready
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(campground.name),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('State: ${campground.state}'),
                                if (campground.parkName != null)
                                  Text('Park: ${campground.parkName}'),
                                const SizedBox(height: 8),
                                Text(campground.description),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with name and monitor button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                campground.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    campground.state,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  if (campground.parkName != null) ...[
                                    Text(
                                      ' • ${campground.parkName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Monitor toggle button
                        IconButton.filledTonal(
                          onPressed: () {
                            final actions = ref.read(campgroundActionsProvider);
                            actions.toggleMonitoring(
                              campground.id,
                              !campground.isMonitored,
                            );
                          },
                          icon: Icon(
                            campground.isMonitored
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          tooltip: campground.isMonitored
                              ? 'Stop monitoring'
                              : 'Start monitoring',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Text(
                      campground.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (campground.amenities.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: campground.amenities.take(3).map<Widget>((
                          amenity,
                        ) {
                          return Chip(
                            label: Text(
                              amenity,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
