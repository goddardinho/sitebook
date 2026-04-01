import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/models/user.dart';
import '../monitoring/monitoring_settings_screen.dart';
// Temporarily disabled: import '../notifications/notification_preferences_screen.dart';

class AuthenticatedProfileScreen extends ConsumerWidget {
  const AuthenticatedProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final authActions = ref.read(authActionsProvider);

    // Show loading if user data is not available
    if (!authState.isAuthenticated || authState.user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Loading profile...', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    final user = authState.user!;

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
                    child: _buildProfileHeader(context, theme, user),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _buildProfileContent(context, theme, user, authActions),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ThemeData theme, User user) {
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
                backgroundImage: user.avatarUrl?.isNotEmpty == true
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl?.isEmpty ?? true
                    ? Text(
                        _getInitials(user.name),
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
                      user.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user.location != null) ...[
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
                              user.location!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary.withOpacity(
                                  0.8,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showEditProfileDialog(context, theme, user),
                icon: Icon(Icons.edit, color: theme.colorScheme.onPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    ThemeData theme,
    User user,
    AuthActions authActions,
  ) {
    final userProfile = user.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats section
          if (userProfile != null) ...[
            _buildStatsSection(theme, userProfile),
            const SizedBox(height: 24),
          ],

          // Account section
          _buildSectionHeader(theme, 'Account'),
          const SizedBox(height: 12),
          _buildAccountSection(context, theme, user, authActions),

          const SizedBox(height: 24),

          // Settings section
          _buildSectionHeader(theme, 'Settings'),
          const SizedBox(height: 12),
          _buildSettingsSection(context, theme),

          const SizedBox(height: 24),

          // Support section
          _buildSectionHeader(theme, 'Support & Info'),
          const SizedBox(height: 12),
          _buildSupportSection(context, theme, authActions),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme, UserProfile profile) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            '${profile.totalReservations}',
            'Total\nReservations',
            Icons.event_available,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            '${profile.totalNights}',
            'Nights\nCamped',
            Icons.nights_stay,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            '${profile.favoriteParks}',
            'Parks\nVisited',
            Icons.park,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String value,
    String label,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
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
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    ThemeData theme,
    User user,
    AuthActions authActions,
  ) {
    return Card(
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.person_outlined,
            title: 'Personal Information',
            subtitle: 'Name, email, location',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEditProfileDialog(context, theme, user),
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Password, account security',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSecurityDialog(context),
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.history,
            title: 'Login History',
            subtitle: user.lastLoginAt != null
                ? 'Last login: ${_formatDate(user.lastLoginAt!)}'
                : 'No recent logins',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLoginHistoryDialog(context, user),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, ThemeData theme) {
    return Card(
      child: Column(
        children: [
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
          // Temporarily disable notification preferences until compilation issues are fixed
          // const Divider(height: 1),
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
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Theme and display preferences',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAppearanceDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(
    BuildContext context,
    ThemeData theme,
    AuthActions authActions,
  ) {
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
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSignOutDialog(context, authActions),
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

  String _getInitials(String name) {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Dialog methods
  void _showEditProfileDialog(
    BuildContext context,
    ThemeData theme,
    User user,
  ) {
    final nameController = TextEditingController(text: user.name);
    final locationController = TextEditingController(text: user.location ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully! (Demo)'),
                ),
              );
            },
            child: const Text('Save'),
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
            Text('• Account security'),
            Text('• Two-factor authentication'),
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

  void _showLoginHistoryDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            if (user.lastLoginAt != null)
              Text('Last login: ${_formatDate(user.lastLoginAt!)}'),
            Text('Account created: ${_formatDate(user.createdAt)}'),
            const SizedBox(height: 16),
            const Text(
              'Detailed login history coming soon!',
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

  void _showAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appearance Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Dark/Light theme'),
            Text('• Color scheme customization'),
            Text('• Font size preferences'),
            SizedBox(height: 16),
            Text(
              'Theme customization coming soon!',
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Getting started guide'),
            Text('• Frequently asked questions'),
            Text('• Contact support team'),
            Text('• Report a bug'),
            Text('• Feature requests'),
            SizedBox(height: 16),
            Text(
              'Email: support@sitebook.app\nPhone: 1-800-SITEBOOK',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SiteBook'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            Text('Build: 2026.03.31'),
            SizedBox(height: 16),
            Text(
              'SiteBook helps you find and book the perfect campsite for your outdoor adventures.',
            ),
            SizedBox(height: 16),
            Text(
              '© 2026 SiteBook App. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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

  void _showSignOutDialog(BuildContext context, AuthActions authActions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              authActions.signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
