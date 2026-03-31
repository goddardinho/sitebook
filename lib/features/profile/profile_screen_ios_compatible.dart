import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../monitoring/monitoring_settings_screen.dart';
// Temporarily disabled: import '../notifications/notification_preferences_screen.dart';
import '../../shared/providers/campground_providers_ios_compatible.dart';

// Demo user profile data
class UserProfile {
  final String name;
  final String email;
  final String location;
  final DateTime? joinDate;
  final int totalReservations;
  final int totalNights;
  final int favoriteParks;
  final String avatarUrl;

  const UserProfile({
    required this.name,
    required this.email,
    required this.location,
    required this.joinDate,
    required this.totalReservations,
    required this.totalNights,
    required this.favoriteParks,
    required this.avatarUrl,
  });
}

// App settings data
class AppSettings {
  final bool notificationsEnabled;
  final bool locationEnabled;
  final bool darkModeEnabled;
  final String distanceUnit; // km or miles
  final String temperatureUnit; // celsius or fahrenheit

  const AppSettings({
    required this.notificationsEnabled,
    required this.locationEnabled,
    required this.darkModeEnabled,
    required this.distanceUnit,
    required this.temperatureUnit,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? locationEnabled,
    bool? darkModeEnabled,
    String? distanceUnit,
    String? temperatureUnit,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
    );
  }
}

// Demo data providers
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));
  
  return const UserProfile(
    name: 'Alex Thompson',
    email: 'alex.thompson@example.com',
    location: 'San Francisco, CA',
    joinDate: null, // Fixed demo date
    totalReservations: 24,
    totalNights: 87,
    favoriteParks: 12,
    avatarUrl: '', // Empty for demo - will show initials
  );
});

// Simple settings provider using Provider for iOS compatibility
final appSettingsProvider = Provider<AppSettings>((ref) {
  return const AppSettings(
    notificationsEnabled: true,
    locationEnabled: true,
    darkModeEnabled: false,
    distanceUnit: 'km',
    temperatureUnit: 'celsius',
  );
});

class ProfileScreenIOSCompatible extends ConsumerWidget {
  const ProfileScreenIOSCompatible({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Profile',
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
                    child: userProfileAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox(),
                      data: (profile) => _buildProfileHeader(theme, profile),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: userProfileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(theme),
          data: (profile) => _buildProfileContent(context, theme, ref, profile),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.secondary,
                child: profile.avatarUrl.isEmpty
                    ? Text(
                        _getInitials(profile.name),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: theme.colorScheme.onPrimary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.location,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load profile',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, ThemeData theme, WidgetRef ref, UserProfile profile) {
    final settings = ref.watch(appSettingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards
          _buildStatsSection(theme, profile),
          
          const SizedBox(height: 24),
          
          // Account section
          _buildSectionHeader(theme, 'Account'),
          const SizedBox(height: 12),
          _buildAccountSection(context, theme, profile),
          
          const SizedBox(height: 24),
          
          // Settings section
          _buildSectionHeader(theme, 'Settings'),
          const SizedBox(height: 12),
          _buildSettingsSection(context, theme, ref, settings),
          
          const SizedBox(height: 24),
          
          // Support section
          _buildSectionHeader(theme, 'Support & Info'),
          const SizedBox(height: 12),
          _buildSupportSection(context, theme),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme, UserProfile profile) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(theme, '${profile.totalReservations}', 'Total\nReservations', Icons.event_available),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(theme, '${profile.totalNights}', 'Nights\nCamped', Icons.nights_stay),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(theme, '${profile.favoriteParks}', 'Parks\nVisited', Icons.park),
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String value, String label, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, ThemeData theme, UserProfile profile) {
    return Card(
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: profile.email,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPersonalInfoDialog(context, profile),
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Password, 2FA, login history',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSecurityDialog(context),
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.payment_outlined,
            title: 'Payment Methods',
            subtitle: 'Manage cards and billing',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPaymentDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, ThemeData theme, WidgetRef ref, AppSettings settings) {
    return Card(
      child: Column(
        children: [
          // Add monitoring settings at the top
          _buildListTile(
            icon: Icons.monitor_outlined,
            title: 'Availability Monitoring',
            subtitle: 'Background service and notification settings',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MonitoringSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          // Temporarily disable notification preferences until compilation issues are fixed
          // _buildListTile(
          //   icon: Icons.tune_outlined,
          //   title: 'Notification Preferences',
          //   subtitle: 'Customize when and how notifications are sent',
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () {
          //     Navigator.of(context).push(
          //       MaterialPageRoute(
          //         builder: (context) => const NotificationPreferencesScreen(),
          //       ),
          //     );
          //   },
          // ),
          // const Divider(height: 1),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Get notified about availability',
            value: settings.notificationsEnabled,
            onChanged: (value) {
              // Demo functionality - settings changes not persisted
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Notifications enabled (demo)' : 'Notifications disabled (demo)',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSwitchTile(
            icon: Icons.location_on_outlined,
            title: 'Location Services',
            subtitle: 'For nearby campground suggestions',
            value: settings.locationEnabled,
            onChanged: (value) {
              // Demo functionality - settings changes not persisted
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Location enabled (demo)' : 'Location disabled (demo)',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.straighten_outlined,
            title: 'Distance Unit',
            subtitle: settings.distanceUnit == 'km' ? 'Kilometers' : 'Miles',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDistanceUnitDialog(context, ref, settings),
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.thermostat_outlined,
            title: 'Temperature Unit',
            subtitle: settings.temperatureUnit == 'celsius' ? 'Celsius (°C)' : 'Fahrenheit (°F)',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTemperatureUnitDialog(context, ref, settings),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context, ThemeData theme) {
    return Card(
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQ, contact us, tutorials',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHelpDialog(context),
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'About SiteBook',
            subtitle: 'Version 1.0.0, terms & privacy',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.star_outline,
            title: 'Rate App',
            subtitle: 'Share your feedback',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRateDialog(context),
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSignOutDialog(context),
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  // Dialog methods
  void _showPersonalInfoDialog(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', profile.name),
            _buildInfoRow('Email', profile.email),
            _buildInfoRow('Location', profile.location),
            _buildInfoRow('Member since', 'January 2023'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile coming soon!')),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Change password'),
            Text('• Two-factor authentication'),
            Text('• Login history'),
            Text('• Device management'),
            SizedBox(height: 16),
            Text(
              'Advanced security features coming soon!',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
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
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Methods'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No payment methods saved yet.'),
            SizedBox(height: 16),
            Text(
              'Payment integration coming soon!',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add payment method coming soon!')),
              );
            },
            child: const Text('Add Card'),
          ),
        ],
      ),
    );
  }

  void _showDistanceUnitDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Distance Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Kilometers'),
              value: 'km',
              groupValue: settings.distanceUnit,
              onChanged: (value) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Distance unit set to Kilometers (demo)')),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('Miles'),
              value: 'miles',
              groupValue: settings.distanceUnit,
              onChanged: (value) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Distance unit set to Miles (demo)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTemperatureUnitDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temperature Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Celsius (°C)'),
              value: 'celsius',
              groupValue: settings.temperatureUnit,
              onChanged: (value) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Temperature unit set to Celsius (demo)')),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('Fahrenheit (°F)'),
              value: 'fahrenheit',
              groupValue: settings.temperatureUnit,
              onChanged: (value) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Temperature unit set to Fahrenheit (demo)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Frequently Asked Questions'),
            Text('• Contact Support'),
            Text('• Video Tutorials'),
            Text('• User Guide'),
            SizedBox(height: 16),
            Text(
              'Need help? Contact us at support@sitebook.app',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
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
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SiteBook',
      applicationVersion: '1.0.0 (iOS Compatible)',
      applicationIcon: const FlutterLogo(),
      children: const [
        Text('Your camping companion for finding and booking the perfect campsite.'),
        SizedBox(height: 16),
        Text('Built with Flutter for iOS and Android.'),
      ],
    );
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate SiteBook'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enjoying SiteBook? Please rate us in the App Store!'),
            SizedBox(height: 16),
            Text(
              'Your feedback helps us improve the camping experience for everyone.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanks for your feedback!')),
              );
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sign out functionality coming soon!'),
                ),
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}