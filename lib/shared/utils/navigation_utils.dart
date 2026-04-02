import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationUtils {
  static Future<void> openDirections(
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
}
