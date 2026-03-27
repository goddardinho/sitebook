// Smoke tests for the reservation system
//
// These tests verify that all major components can be instantiated and basic functionality works

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sitebook_flutter/features/reservations/reservation_form_screen.dart';
import 'package:sitebook_flutter/features/reservations/widgets/date_selection_section.dart';
import 'package:sitebook_flutter/features/reservations/widgets/guest_selection_section.dart';
import 'package:sitebook_flutter/features/reservations/widgets/contact_information_section.dart';
import 'helpers/test_helpers.dart';

void main() {
  group('Smoke Tests - Component Instantiation', () {
    
    testWidgets('ReservationFormScreen can be instantiated', (WidgetTester tester) async {
      // This test verifies the screen can be created without crashing
      await tester.pumpWidget(
        TestUtils.wrapWithNavigatorApp(
          ReservationFormScreen(
            campground: TestData.testCampground,
          ),
        ),
      );

      // Just verify it doesn't crash during widget creation
      expect(find.byType(ReservationFormScreen), findsOneWidget);
    });

    testWidgets('DateSelectionSection can be instantiated', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithApp(
          SingleChildScrollView(
            child: DateSelectionSection(
              checkInDate: null,
              checkOutDate: null,
              onCheckInChanged: (date) {},
              onCheckOutChanged: (date) {},
            ),
          ),
        ),
      );

      expect(find.byType(DateSelectionSection), findsOneWidget);
      expect(find.text('When would you like to stay?'), findsOneWidget);
    });

    testWidgets('GuestSelectionSection can be instantiated', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithApp(
          SingleChildScrollView(
            child: GuestSelectionSection(
              numberOfGuests: 2,
              selectedCampsiteType: null,
              onGuestCountChanged: (count) {},
              onCampsiteTypeChanged: (type) {},
            ),
          ),
        ),
      );

      expect(find.byType(GuestSelectionSection), findsOneWidget);
      expect(find.text('Tell us about your group'), findsOneWidget);
    });

    testWidgets('ContactInformationSection can be instantiated', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestUtils.wrapWithApp(
          SingleChildScrollView(
            child: ContactInformationSection(
              firstName: '',
              lastName: '',
              email: '',
              phone: '',
              specialRequests: '',
              onFirstNameChanged: (value) {},
              onLastNameChanged: (value) {},
              onEmailChanged: (value) {},
              onPhoneChanged: (value) {},
              onSpecialRequestsChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.byType(ContactInformationSection), findsOneWidget);
      expect(find.text('Contact Information'), findsOneWidget);
    });
  });

  group('Business Logic Tests', () {
    
    test('Pricing calculation - standard scenario', () {
      final price = TestUtils.calculateExpectedPrice(
        siteType: 'Standard Site',
        nights: 2,
        guests: 4,
        includeTax: false,
      );
      
      // Base: $25 * 2 nights = $50
      // Extra guests: none (4 guests is at limit)
      // Reservation fee: $5
      // Total before tax: $55
      expect(price, equals(55.0));
    });

    test('Pricing calculation - premium with extra guests', () {
      final price = TestUtils.calculateExpectedPrice(
        siteType: 'Premium Site (Waterfront)',
        nights: 3,
        guests: 6,
        includeTax: false,
      );
      
      // Base: $55 * 3 nights = $165
      // Extra guests: 2 guests * $5 * 3 nights = $30
      // Reservation fee: $5
      // Total before tax: $200
      expect(price, equals(200.0));
    });

    test('Email validation works correctly', () {
      expect(TestUtils.isValidEmail('user@example.com'), isTrue);
      expect(TestUtils.isValidEmail('test.user+tag@domain.co.uk'), isTrue);
      expect(TestUtils.isValidEmail('invalid-email'), isFalse);
      expect(TestUtils.isValidEmail('user@'), isFalse);
      expect(TestUtils.isValidEmail('@example.com'), isFalse);
    });

    test('Phone number formatting works correctly', () {
      expect(TestUtils.formatPhoneNumber('5551234567'), equals('(555) 123-4567'));
      expect(TestUtils.isValidPhoneNumber('(555) 123-4567'), isTrue);
      expect(TestUtils.isValidPhoneNumber('555-123-4567'), isFalse);
      expect(TestUtils.isValidPhoneNumber('5551234567'), isFalse);
    });

    test('Date validation logic', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final nextWeek = today.add(const Duration(days: 7));
      
      expect(CustomMatchers.isInFuture(tomorrow), isTrue);
      expect(CustomMatchers.isValidDateRange(tomorrow, nextWeek), isTrue);
      expect(CustomMatchers.isValidDateRange(nextWeek, tomorrow), isFalse);
    });
  });

  group('Test Data Integrity', () {
    
    test('Test campground data is valid', () {
      final campground = TestData.testCampground;
      
      expect(campground.id, isNotEmpty);
      expect(campground.name, isNotEmpty);
      expect(campground.state, isNotEmpty);
      expect(campground.latitude, isA<double>());
      expect(campground.longitude, isA<double>());
      expect(campground.amenities, isNotEmpty);
      expect(campground.activities, isNotEmpty);
    });

    test('Campsite test data is valid', () {
      expect(TestData.testCampsite1.id, isNotEmpty);
      expect(TestData.testCampsite1.siteNumber, isNotEmpty);
      expect(TestData.testCampsite1.maxOccupancy, greaterThan(0));
      expect(TestData.testCampsite1.pricePerNight, greaterThan(0));
    });

    test('Test scenarios are realistic', () {
      final weekend = TestScenarios.weekendStay;
      final checkIn = weekend['checkIn'] as DateTime;
      final checkOut = weekend['checkOut'] as DateTime;
      
      expect(checkIn.isBefore(checkOut), isTrue);
      expect(weekend['guests'], greaterThan(0));
      expect(weekend['siteType'], isNotNull);
    });
  });
}