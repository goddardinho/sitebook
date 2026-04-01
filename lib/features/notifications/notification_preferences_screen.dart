import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/notification_preferences_service.dart';
import '../../shared/models/campground.dart';
import '../../shared/providers/campground_providers_ios_compatible.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final quietHours = ref.watch(quietHoursProvider);
    final checkFrequency = ref.watch(checkFrequencyProvider);
    final monitoredCampgrounds = ref.watch(monitoredCampgroundsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master toggle for notifications
            _buildMasterToggleSection(theme, notificationsEnabled),

            const SizedBox(height: 24),

            // Notification Types section
            _buildNotificationTypesSection(theme, notificationsEnabled),

            const SizedBox(height: 24),

            // Timing and Frequency section
            _buildTimingSection(
              theme,
              notificationsEnabled,
              quietHours,
              checkFrequency,
            ),

            const SizedBox(height: 24),

            // Alert Style section
            _buildAlertStyleSection(theme, notificationsEnabled),

            const SizedBox(height: 24),

            // Campground-specific section
            _buildCampgroundSpecificSection(
              theme,
              notificationsEnabled,
              monitoredCampgrounds,
            ),

            const SizedBox(height: 24),

            // Reset section
            _buildResetSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterToggleSection(ThemeData theme, bool notificationsEnabled) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Master Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: Text(
                notificationsEnabled
                    ? 'Receive notifications about campsite availability'
                    : 'All notifications are disabled',
              ),
              value: notificationsEnabled,
              onChanged: (value) async {
                final service = ref.read(
                  notificationPreferencesServiceProvider,
                );
                await service.setNotificationsEnabled(value);
                // Refresh the UI
                ref.invalidate(notificationsEnabledProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypesSection(
    ThemeData theme,
    bool notificationsEnabled,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Types',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose what types of notifications to receive',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildNotificationTypeSwitch(
              title: 'Instant Alerts',
              subtitle: 'Get notified immediately when availability changes',
              icon: Icons.flash_on,
              enabled: notificationsEnabled,
              providerKey: 'instant',
            ),
            _buildNotificationTypeSwitch(
              title: 'Daily Summaries',
              subtitle: 'Receive daily reports of availability changes',
              icon: Icons.summarize,
              enabled: notificationsEnabled,
              providerKey: 'summary',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required String providerKey,
  }) {
    // For now, use local state - in a complete implementation, these would have their own providers
    return ListTile(
      leading: Icon(icon, color: enabled ? null : Colors.grey),
      title: Text(title, style: TextStyle(color: enabled ? null : Colors.grey)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      trailing: Switch(
        value: enabled, // This would be from the specific provider
        onChanged: enabled
            ? (value) {
                // Implementation would update the specific provider
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${title.toLowerCase()} ${value ? 'enabled' : 'disabled'}',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            : null,
      ),
    );
  }

  Widget _buildTimingSection(
    ThemeData theme,
    bool notificationsEnabled,
    Map<String, int> quietHours,
    int checkFrequency,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timing & Frequency',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Check Frequency
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Check Frequency'),
              subtitle: Text('Check availability every $checkFrequency hours'),
              trailing: DropdownButton<int>(
                value: checkFrequency,
                items: [4, 6, 8, 12, 24].map((hours) {
                  return DropdownMenuItem(
                    value: hours,
                    child: Text('$hours hours'),
                  );
                }).toList(),
                onChanged: notificationsEnabled
                    ? (value) async {
                        if (value != null) {
                          final service = ref.read(
                            notificationPreferencesServiceProvider,
                          );
                          await service.setCheckFrequencyHours(value);
                          ref.invalidate(checkFrequencyProvider);
                        }
                      }
                    : null,
              ),
            ),

            const Divider(),

            // Quiet Hours
            ListTile(
              leading: const Icon(Icons.bedtime),
              title: const Text('Quiet Hours'),
              subtitle: Text(
                'No notifications from ${_formatHour(quietHours['start']!)} to ${_formatHour(quietHours['end']!)}',
              ),
              trailing: TextButton(
                onPressed: notificationsEnabled
                    ? () => _showQuietHoursDialog(context, quietHours)
                    : null,
                child: const Text('Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertStyleSection(ThemeData theme, bool notificationsEnabled) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert Style',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate device for notifications'),
              value: notificationsEnabled,
              onChanged: notificationsEnabled
                  ? (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Vibration ${value ? 'enabled' : 'disabled'}',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.volume_up),
              title: const Text('Sound'),
              subtitle: const Text('Play sound for notifications'),
              value: notificationsEnabled,
              onChanged: notificationsEnabled
                  ? (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sound ${value ? 'enabled' : 'disabled'}',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampgroundSpecificSection(
    ThemeData theme,
    bool notificationsEnabled,
    AsyncValue<List<Campground>> monitoredCampgroundsAsync,
  ) {
    return monitoredCampgroundsAsync.when(
      data: (monitoredCampgrounds) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campground-Specific Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Control notifications for individual campgrounds',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (monitoredCampgrounds.isEmpty)
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('No monitored campgrounds'),
                  subtitle: const Text(
                    'Add campgrounds to monitoring to configure individual settings',
                  ),
                )
              else
                ...monitoredCampgrounds
                    .take(5)
                    .map(
                      (campground) => _buildCampgroundNotificationSwitch(
                        campground,
                        notificationsEnabled,
                      ),
                    ),
              if (monitoredCampgrounds.length > 5)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '... and ${monitoredCampgrounds.length - 5} more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading campgrounds: $error'),
        ),
      ),
    );
  }

  Widget _buildCampgroundNotificationSwitch(
    Campground campground,
    bool globalEnabled,
  ) {
    return SwitchListTile(
      title: Text(
        campground.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        campground.state,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      value: globalEnabled, // This would be from campground-specific provider
      onChanged: globalEnabled
          ? (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Notifications for ${campground.name} ${value ? 'enabled' : 'disabled'}',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          : null,
    );
  }

  Widget _buildResetSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('Reset to Defaults'),
              subtitle: const Text(
                'Reset all notification preferences to default values',
              ),
              trailing: OutlinedButton(
                onPressed: () => _showResetConfirmationDialog(context),
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }

  void _showQuietHoursDialog(
    BuildContext context,
    Map<String, int> quietHours,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Quiet Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('During quiet hours, no notifications will be sent.'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Start: '),
                DropdownButton<int>(
                  value: quietHours['start'],
                  items: List.generate(
                    24,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(_formatHour(index)),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value != null) {
                      final service = ref.read(
                        notificationPreferencesServiceProvider,
                      );
                      await service.setQuietHoursStart(value);
                      ref.invalidate(quietHoursProvider);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('End: '),
                DropdownButton<int>(
                  value: quietHours['end'],
                  items: List.generate(
                    24,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(_formatHour(index)),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value != null) {
                      final service = ref.read(
                        notificationPreferencesServiceProvider,
                      );
                      await service.setQuietHoursEnd(value);
                      ref.invalidate(quietHoursProvider);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Notification Preferences'),
        content: const Text(
          'This will reset all notification preferences to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(notificationPreferencesServiceProvider)
                  .resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification preferences reset to defaults'),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
