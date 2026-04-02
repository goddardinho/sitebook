import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/campgrounds/campgrounds_screen_ios_compatible.dart';
import 'features/reservations/reservations_screen_ios_compatible.dart';
import 'features/maps/map_screen_ios_compatible.dart';
import 'features/profile/authenticated_profile_screen.dart';
import 'features/credentials/screens/reservation_systems_screen.dart';
import 'shared/services/availability_monitoring_service.dart';
import 'shared/services/enhanced_notification_service.dart';
import 'shared/services/notification_preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint(
    '🚀 SiteBook startup - iOS compatible with availability monitoring',
  );

  // Initialize availability monitoring and notification services
  await _initializeServices();

  runApp(const ProviderScope(child: SiteBookApp()));
}

/// Initialize background services for availability monitoring
Future<void> _initializeServices() async {
  try {
    debugPrint('🔧 Initializing availability monitoring services...');

    // Initialize enhanced notification service
    await EnhancedNotificationService.initialize();

    // Initialize notification preferences service
    final prefsService = NotificationPreferencesService();
    await prefsService.initialize();
    debugPrint('⚙️ Notification preferences service initialized');

    // Initialize availability monitoring service
    await AvailabilityMonitoringService.initialize();

    debugPrint('✅ All services initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing services: $e');
    // Continue app startup even if services fail to initialize
  }
}

class SiteBookApp extends ConsumerWidget {
  const SiteBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SiteBook - Full iOS Compatible',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const StableMainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StableMainScreen extends StatefulWidget {
  const StableMainScreen({super.key});

  @override
  State<StableMainScreen> createState() => _StableMainScreenState();
}

class _StableMainScreenState extends State<StableMainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    CampgroundsScreenIOSCompatible(),
    ReservationsScreenIOSCompatible(),
    MapScreenIOSCompatible(),
    AuthenticatedProfileScreen(),
    // Add Reservation Systems screen
    ReservationSystemsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.nature), label: 'Campgrounds'),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Reservations',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(icon: Icon(Icons.vpn_key), label: 'Systems'),
        ],
      ),
    );
  }
}

// Stable placeholder screens for iOS compatibility
class CampgroundsPlaceholder extends StatelessWidget {
  const CampgroundsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campgrounds'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nature, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Campgrounds - iOS Stable Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Advanced features temporarily disabled for iOS stability',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'Core functionality will be restored progressively',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class ReservationsPlaceholder extends StatelessWidget {
  const ReservationsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Reservations Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Manage your camping reservations',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Map Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Find campgrounds near you (iOS stable mode)',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.purple),
            SizedBox(height: 16),
            Text(
              'Profile Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Manage your account and preferences',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
