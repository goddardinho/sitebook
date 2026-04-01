import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/models/campground.dart';
import '../../shared/providers/campground_providers.dart';

class MapsScreen extends ConsumerStatefulWidget {
  final Campground? focusCampground;

  const MapsScreen({super.key, this.focusCampground});

  @override
  ConsumerState<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends ConsumerState<MapsScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Marker? _focusedCampgroundMarker;
  bool _isLoadingLocation = true;
  bool _isLoadingMarkers = false;
  MapType _currentMapType = MapType.normal;

  // Default location (San Francisco Bay Area - good for demo campgrounds)
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 8.0,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    if (widget.focusCampground != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusOnCampground(widget.focusCampground!);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final hasPermission = await _handleLocationPermision();
      if (!hasPermission) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      // Fall back to default location
    }
  }

  Future<bool> _handleLocationPermision() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void _focusOnCampground(Campground campground) {
    final campgroundLatLng = LatLng(campground.latitude, campground.longitude);

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: campgroundLatLng, zoom: 14.0),
      ),
    );

    // Add marker for focused campground
    setState(() {
      _focusedCampgroundMarker = Marker(
        markerId: MarkerId('focused_${campground.id}'),
        position: campgroundLatLng,
        infoWindow: InfoWindow(
          title: campground.name,
          snippet: campground.parkName ?? campground.state,
        ),
      );
    });

    // Show info for this campground after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _showCampgroundDetails(campground);
    });
  }

  Future<void> _createCampgroundMarkers() async {
    setState(() => _isLoadingMarkers = true);
    try {
      final campgrounds = await ref.read(searchResultsProvider.future);
      await _createCampgroundMarkersFromList(campgrounds);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading campgrounds: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMarkers = false);
      }
    }
  }

  Future<void> _createCampgroundMarkersFromList(
    List<Campground> campgrounds,
  ) async {
    final markers = <Marker>{};

    for (final campground in campgrounds) {
      final markerId = MarkerId(campground.id);
      final marker = Marker(
        markerId: markerId,
        position: LatLng(campground.latitude, campground.longitude),
        infoWindow: InfoWindow(
          title: campground.name,
          snippet:
              '${campground.state} • ${campground.activities.take(2).join(", ")}',
          onTap: () => _showCampgroundDetails(campground),
        ),
        icon: await _getCampgroundMarkerIcon(campground),
      );
      markers.add(marker);
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<BitmapDescriptor> _getCampgroundMarkerIcon(
    Campground campground,
  ) async {
    // Use different colored markers based on campground type or availability
    if (campground.isMonitored) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (campground.activities.contains('Hiking')) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _showCampgroundDetails(Campground campground) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCampgroundSheet(campground),
    );
  }

  Widget _buildCampgroundSheet(Campground campground) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              campground.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              campground.parkName ?? campground.state,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _navigateToCampground(campground),
                        icon: const Icon(Icons.directions),
                        tooltip: 'Get Directions',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Distance (if we have current location)
                  if (_currentPosition != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_calculateDistance(_currentPosition!, campground).toStringAsFixed(1)} miles away',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Activities
                  if (campground.activities.isNotEmpty) ...[
                    Text(
                      'Activities',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: campground.activities
                          .take(6)
                          .map((activity) => Chip(label: Text(activity)))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Amenities
                  if (campground.amenities.isNotEmpty) ...[
                    Text(
                      'Amenities',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: campground.amenities
                          .take(6)
                          .map(
                            (amenity) => Chip(
                              label: Text(amenity),
                              backgroundColor: Colors.blue[50],
                              side: BorderSide(color: Colors.blue[200]!),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const Spacer(),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to full details screen
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text('View Details'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to reservation screen
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Reserve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateDistance(Position userPosition, Campground campground) {
    return Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          campground.latitude,
          campground.longitude,
        ) /
        1609.344; // Convert meters to miles
  }

  Future<void> _navigateToCampground(Campground campground) async {
    try {
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${campground.latitude},${campground.longitude}&travelmode=driving',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps application'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening directions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> openDirections(
    double latitude,
    double longitude,
    BuildContext context,
  ) async {
    try {
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps application'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening directions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleMapType() {
    setState(() {
      switch (_currentMapType) {
        case MapType.normal:
          _currentMapType = MapType.satellite;
          break;
        case MapType.satellite:
          _currentMapType = MapType.terrain;
          break;
        case MapType.terrain:
          _currentMapType = MapType.hybrid;
          break;
        case MapType.hybrid:
        case MapType.none:
          _currentMapType = MapType.normal;
          break;
      }
    });
  }

  Future<void> _fitAllMarkers() async {
    if (_mapController == null || _markers.isEmpty) return;

    final bounds = _calculateBounds(_markers);
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  LatLngBounds _calculateBounds(Set<Marker> markers) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _createCampgroundMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campgrounds Map'),
        centerTitle: true,
        actions: [
          // Map type toggle
          IconButton(
            onPressed: _toggleMapType,
            icon: const Icon(Icons.layers),
            tooltip: 'Map Type',
          ),
          // Fit all markers
          if (_markers.isNotEmpty)
            IconButton(
              onPressed: _fitAllMarkers,
              icon: const Icon(Icons.fit_screen),
              tooltip: 'Fit All Markers',
            ),
          // Current location button
          if (_currentPosition != null)
            IconButton(
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.my_location),
              tooltip: 'My Location',
            ),
          // List view toggle
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.list),
            tooltip: 'List View',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _currentPosition != null
                ? CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 10.0,
                  )
                : _defaultPosition,
            mapType: _currentMapType,
            markers: {
              ..._markers,
              if (_focusedCampgroundMarker != null) _focusedCampgroundMarker!,
            },
            myLocationEnabled: _currentPosition != null,
            myLocationButtonEnabled: false, // We have our own button
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            padding: const EdgeInsets.only(
              bottom: 80,
            ), // Space for floating button
          ),
          // Loading indicator
          if (_isLoadingLocation || _isLoadingMarkers)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isLoadingLocation
                          ? 'Getting your location...'
                          : 'Loading campgrounds...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search nearby button
          FloatingActionButton.extended(
            onPressed: () => _searchNearbyPressed(),
            heroTag: 'search_nearby',
            icon: const Icon(Icons.search),
            label: const Text('Find Nearby'),
          ),
          const SizedBox(height: 12),
          // Refresh markers button
          FloatingActionButton(
            onPressed: _createCampgroundMarkers,
            heroTag: 'refresh_markers',
            tooltip: 'Refresh Campgrounds',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  void _searchNearbyPressed() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location not available. Please enable location services.',
          ),
        ),
      );
      return;
    }

    // Trigger real location-based search with 25-mile radius
    _performLocationBasedSearch(25.0);
  }

  Future<void> _performLocationBasedSearch(double radiusMiles) async {
    if (_currentPosition == null) return;

    try {
      final params = NearbySearchParams(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusMiles: radiusMiles,
      );

      final nearbyCampgrounds = await ref.read(
        nearbySearchProvider(params).future,
      );

      // Update markers with nearby campgrounds
      await _createCampgroundMarkersFromList(nearbyCampgrounds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Found ${nearbyCampgrounds.length} campgrounds within ${radiusMiles.toInt()} miles',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching nearby: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
