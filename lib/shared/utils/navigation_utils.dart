import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationUtils {
  static Future<void> openDirections(
    double latitude,
    double longitude,
    BuildContext context,
  ) async {
    try {
      // Debug logging
      print(
        '🗺️ NavigationUtils.openDirections called with: $latitude, $longitude',
      );

      // Validate coordinates
      if (latitude == 0.0 && longitude == 0.0) {
        print('❌ Invalid coordinates: 0.0, 0.0');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid campground location coordinates'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Try multiple URL formats for better compatibility
      final urls = [
        // Google Maps with destination parameter (most compatible)
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
        // Apple Maps fallback (iOS)
        'https://maps.apple.com/?daddr=$latitude,$longitude',
        // Generic maps protocol
        'geo:$latitude,$longitude?q=$latitude,$longitude',
      ];

      print('🔗 Attempting to launch ${urls.length} different URL formats');
      bool launched = false;

      for (int i = 0; i < urls.length && !launched; i++) {
        final url = Uri.parse(urls[i]);
        print('🔗 Trying URL $i: ${url.toString()}');

        try {
          print('🔍 Checking canLaunchUrl for URL $i');
          if (await canLaunchUrl(url)) {
            print('✅ canLaunchUrl returned true for URL $i');
            await launchUrl(url, mode: LaunchMode.externalApplication);
            launched = true;
            print('✅ Successfully launched directions with URL $i');

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening directions...'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            break;
          } else {
            print('❌ canLaunchUrl returned false for URL $i');
          }
        } catch (urlError) {
          print('❌ URL $i failed with error: $urlError');
        }
      }

      if (!launched) {
        print('❌ All direction URLs failed to launch');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open maps application. Please install Google Maps or Apple Maps.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error in openDirections: $e');
      print('📍 Stack trace: $stackTrace');
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
}
