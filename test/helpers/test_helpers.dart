// Test helpers and utilities for reservation form testing
//
// Provides mock data, common test widgets, and utility functions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitebook_flutter/shared/models/campground.dart';
import 'package:sitebook_flutter/shared/models/campsite.dart';

// Test data
class TestData {
  static final testCampground = Campground(
    id: 'test-camp-1',
    name: 'Pine Valley Campground',
    state: 'CA',
    description:
        'A beautiful campground nestled in the pine forests with stunning mountain views. Perfect for families and outdoor enthusiasts.',
    imageUrls: [
      'https://example.com/pine-valley-1.jpg',
      'https://example.com/pine-valley-2.jpg',
      'https://example.com/pine-valley-3.jpg',
    ],
    latitude: 37.7749,
    longitude: -122.4194,
    phoneNumber: '(555) 123-4567',
    email: 'info@pinevalleycampground.com',
    reservationUrl: 'https://pinevalleycampground.com/reservations',
    amenities: [
      'WiFi',
      'Restrooms',
      'Showers',
      'Fire Pits',
      'Picnic Tables',
      'Hiking Trails',
      'Lake Access',
    ],
    activities: [
      'Hiking',
      'Fishing',
      'Swimming',
      'Kayaking',
      'Nature Photography',
    ],
    isMonitored: false,
    createdAt: DateTime(2026, 2, 27),
    updatedAt: DateTime(2026, 3, 26),
  );

  static const testCampsite1 = Campsite(
    id: 'site-001',
    campgroundId: 'test-camp-1',
    siteNumber: '001',
    siteType: 'Standard Site',
    maxOccupancy: 6,
    accessibility: false,
    amenities: ['Fire Pit', 'Picnic Table'],
    pricePerNight: 25.0,
    isAvailable: true,
    nextAvailableDate: null,
  );

  static const testCampsite2 = Campsite(
    id: 'site-002',
    campgroundId: 'test-camp-1',
    siteNumber: '002',
    siteType: 'Electric Hookup',
    maxOccupancy: 8,
    accessibility: true,
    amenities: ['30 Amp Electric', 'Fire Pit', 'Picnic Table'],
    pricePerNight: 35.0,
    isAvailable: true,
    nextAvailableDate: null,
  );

  static const testCampsite3 = Campsite(
    id: 'site-003',
    campgroundId: 'test-camp-1',
    siteNumber: '003',
    siteType: 'Premium Site (Waterfront)',
    maxOccupancy: 10,
    accessibility: false,
    amenities: ['Waterfront', 'Fire Pit', 'Picnic Table', 'Boat Launch Access'],
    pricePerNight: 55.0,
    isAvailable: false,
    nextAvailableDate: null,
  );

  static final multipleCampgrounds = [
    testCampground,
    Campground(
      id: 'test-camp-2',
      name: 'Desert Oasis Campground',
      state: 'AZ',
      description: 'Experience the beauty of the desert landscape',
      imageUrls: ['https://example.com/desert-oasis.jpg'],
      latitude: 33.4484,
      longitude: -112.0740,
      phoneNumber: '(555) 987-6543',
      email: 'info@desertoasis.com',
      reservationUrl: null, // No online reservations
      amenities: ['Restrooms', 'Desert Views', 'Star Gazing'],
      activities: ['Star Gazing', 'Desert Photography', 'Geology Tours'],
      isMonitored: true,
      createdAt: DateTime(2026, 1, 27),
      updatedAt: DateTime(2026, 3, 27),
    ),
  ];
}

// Test utilities
class TestUtils {
  /// Wrap a widget with necessary providers and Material app
  static Widget wrapWithApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  /// Create a full app wrapper for navigation testing
  static Widget wrapWithNavigatorApp(Widget home) {
    return ProviderScope(
      child: MaterialApp(
        home: home,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
      ),
    );
  }

  /// Simulate a delay (useful for testing loading states)
  static Future<void> delay([int milliseconds = 100]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// Calculate expected pricing for testing
  static double calculateExpectedPrice({
    required String siteType,
    required int nights,
    required int guests,
    bool includeTax = true,
  }) {
    double basePrice = _getSiteTypeBasePrice(siteType);
    double subtotal = basePrice * nights;

    double extraGuestFee = guests > 4 ? (guests - 4) * 5.0 * nights : 0.0;
    double reservationFee = 5.0;

    double beforeTax = subtotal + extraGuestFee + reservationFee;

    if (!includeTax) return beforeTax;

    double tax = beforeTax * 0.08; // 8% tax rate
    return beforeTax + tax;
  }

  static double _getSiteTypeBasePrice(String siteType) {
    switch (siteType) {
      case 'Standard Site':
        return 25.0;
      case 'Electric Hookup':
        return 35.0;
      case 'Full Hookup (Water + Electric + Sewer)':
        return 45.0;
      case 'Premium Site (Waterfront)':
        return 55.0;
      case 'Group Site':
        return 75.0;
      case 'RV Site':
        return 40.0;
      case 'Tent-Only Site':
        return 20.0;
      default:
        return 25.0;
    }
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\-\.\+]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate phone number format (XXX) XXX-XXXX
  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^\(\d{3}\) \d{3}-\d{4}$').hasMatch(phone);
  }

  /// Format phone number for testing
  static String formatPhoneNumber(String digits) {
    if (digits.length != 10) return digits;
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
  }
}

// Mock providers for testing
class TestProviders {
  // Add any provider overrides needed for testing here
  // Example:
  // static final mockCampgroundProvider = Provider<List<Campground>>((ref) {
  //   return TestData.multipleCampgrounds;
  // });
}

// Custom matchers for more specific testing
class CustomMatchers {
  /// Check if a date is in the future
  static bool isInFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Check if checkout date is after checkin date
  static bool isValidDateRange(DateTime checkIn, DateTime checkOut) {
    return checkOut.isAfter(checkIn);
  }

  /// Check if pricing calculation is within expected range
  static bool isPricingValid(
    double actual,
    double expected, {
    double tolerance = 0.01,
  }) {
    return (actual - expected).abs() <= tolerance;
  }
}

// Test scenarios for different use cases
class TestScenarios {
  static final weekendStay = {
    'checkIn': DateTime(2026, 4, 5), // Saturday
    'checkOut': DateTime(2026, 4, 7), // Monday
    'guests': 4,
    'siteType': 'Standard Site',
  };

  static final longWeekStay = {
    'checkIn': DateTime(2026, 4, 10),
    'checkOut': DateTime(2026, 4, 17),
    'guests': 6,
    'siteType': 'Full Hookup (Water + Electric + Sewer)',
  };

  static final premiumStay = {
    'checkIn': DateTime(2026, 5, 15),
    'checkOut': DateTime(2026, 5, 18),
    'guests': 2,
    'siteType': 'Premium Site (Waterfront)',
  };

  static final groupBooking = {
    'checkIn': DateTime(2026, 6, 20),
    'checkOut': DateTime(2026, 6, 23),
    'guests': 12,
    'siteType': 'Group Site',
  };
}
