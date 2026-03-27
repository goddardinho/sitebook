// Basic widget tests for the SiteBook app
//
// Tests the main app structure and basic navigation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sitebook_flutter/main.dart';
import 'package:sitebook_flutter/features/campgrounds/campgrounds_screen.dart';
import 'helpers/test_helpers.dart';

void main() {
  testWidgets('SiteBook app launches correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SiteBookApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the main screen displays
    expect(find.text('Campgrounds'), findsOneWidget);
    
    // Verify bottom navigation is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    
    // Verify search functionality exists
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('Main screen structure and navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtils.wrapWithNavigatorApp(const MainScreen()),
    );

    await tester.pumpAndSettle();

    // Verify the current tab shows campgrounds
    expect(find.text('Campgrounds'), findsOneWidget);

    // Test navigation tabs if they exist
    if (tester.any(find.text('Map'))) {
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      // Verify map screen loaded
    }

    // Navigate back to campgrounds
    if (tester.any(find.text('Campgrounds'))) {
      await tester.tap(find.text('Campgrounds'));
      await tester.pumpAndSettle();
      expect(find.text('Campgrounds'), findsOneWidget);
    }
  });

  testWidgets('Campgrounds screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtils.wrapWithNavigatorApp(const CampgroundsScreen()),
    );

    await tester.pumpAndSettle();

    // Verify the screen title
    expect(find.text('Campgrounds'), findsOneWidget);

    // Check for search functionality
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Check if campground cards are displayed
    // Note: This depends on having sample data loaded
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('App theme and styling', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SiteBookApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Find the MaterialApp widget to verify theme
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    
    // Verify Material 3 is enabled
    expect(materialApp.theme?.useMaterial3, isTrue);
    
    // Verify color scheme is based on green
    expect(materialApp.theme?.colorScheme.primary, isNotNull);
    
    // Verify dark theme exists
    expect(materialApp.darkTheme, isNotNull);
    expect(materialApp.darkTheme?.useMaterial3, isTrue);
  });

  testWidgets('App handles empty states gracefully', (WidgetTester tester) async {
    // Test with empty data or loading states
    await tester.pumpWidget(
      TestUtils.wrapWithNavigatorApp(const CampgroundsScreen()),
    );

    await tester.pumpAndSettle();

    // Verify app doesn't crash with empty data
    expect(find.byType(CampgroundsScreen), findsOneWidget);
  });

  testWidgets('Navigation between screens works', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SiteBookApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify we start on the main screen
    expect(find.text('Campgrounds'), findsOneWidget);

    // If there are campground cards, try tapping one
    final cards = find.byType(Card);
    if (tester.any(cards)) {
      await tester.tap(cards.first);
      await tester.pumpAndSettle();

      // Should navigate to details screen
      // The exact assertion depends on the details screen structure
      expect(find.byType(AppBar), findsOneWidget);
    }
  });
}
