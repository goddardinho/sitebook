import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/campground.dart';
import '../../../shared/providers/campground_providers_demo.dart';
import '../../../shared/utils/navigation_utils.dart';
import '../../reservations/reservation_form_screen.dart';
import 'widgets/campground_image_carousel.dart';
import 'widgets/campground_info_section.dart';
import 'widgets/campground_action_buttons.dart';

class CampgroundDetailsScreen extends ConsumerStatefulWidget {
  final Campground campground;

  const CampgroundDetailsScreen({
    super.key,
    required this.campground,
  });

  @override
  ConsumerState<CampgroundDetailsScreen> createState() => _CampgroundDetailsScreenState();
}

class _CampgroundDetailsScreenState extends ConsumerState<CampgroundDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final isCollapsed = _scrollController.offset > 200;
    if (isCollapsed != _isAppBarCollapsed) {
      setState(() {
        _isAppBarCollapsed = isCollapsed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final campground = widget.campground;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(theme, campground),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Carousel
                Hero(
                  tag: 'campground-image-${campground.id}',
                  child: CampgroundImageCarousel(
                    imageUrls: campground.imageUrls,
                    campgroundName: campground.name,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CampgroundActionButtons(
                    campground: campground,
                    onReservePressed: _handleReservePressed,
                    onDirectionsPressed: _handleDirectionsPressed,
                    onSharePressed: _handleSharePressed,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Information Sections
                CampgroundInfoSection(campground: campground),
                
                // Safe area padding at bottom
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, Campground campground) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: _isAppBarCollapsed ? 4 : 0,
      backgroundColor: _isAppBarCollapsed 
          ? theme.colorScheme.surface
          : Colors.transparent,
      foregroundColor: _isAppBarCollapsed
          ? theme.colorScheme.onSurface
          : Colors.white,
      title: _isAppBarCollapsed
          ? Text(
              campground.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(102),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(102),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              campground.isMonitored ? Icons.visibility : Icons.visibility_off,
              color: campground.isMonitored ? theme.colorScheme.primary : Colors.white,
            ),
            onPressed: _toggleMonitoring,
            tooltip: campground.isMonitored ? 'Stop monitoring' : 'Start monitoring',
          ),
        ),
      ],
    );
  }

  void _toggleMonitoring() {
    final actions = ref.read(campgroundActionsProvider);
    actions.toggleMonitoring(widget.campground.id, !widget.campground.isMonitored);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.campground.isMonitored 
              ? 'Stopped monitoring ${widget.campground.name}'
              : 'Started monitoring ${widget.campground.name}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleReservePressed() {
    // Navigate to reservation form
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReservationFormScreen(
          campground: widget.campground,
        ),
      ),
    );
  }

  void _handleDirectionsPressed() {
    final latitude = widget.campground.latitude;
    final longitude = widget.campground.longitude;
    
    if (latitude != null && longitude != null) {
      NavigationUtils.openDirections(latitude, longitude, context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location not available for ${widget.campground.name}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${widget.campground.name}...'),
      ),
    );
  }
}