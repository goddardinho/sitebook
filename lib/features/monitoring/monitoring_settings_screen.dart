import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/campground_providers_ios_compatible.dart';
import '../../shared/models/campground.dart';
import '../../demo/demo_data_provider.dart';
// Temporarily disabled: import '../notifications/notification_preferences_screen.dart';

/// Availability monitoring settings and status screen
class MonitoringSettingsScreen extends ConsumerWidget {
  const MonitoringSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundStatusAsync = ref.watch(backgroundMonitoringStatusProvider);
    final monitoringControls = ref.read(monitoringControlsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Monitoring'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: backgroundStatusAsync.when(
        data: (status) =>
            _buildContent(context, status, monitoringControls, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading monitoring status: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BackgroundMonitoringStatus status,
    MonitoringControls controls,
    WidgetRef ref,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(context, status),
          const SizedBox(height: 16),
          _buildQuickActionsCard(context, controls),
          const SizedBox(height: 16),
          _buildMonitoredCampgroundsCard(context, ref),
          const SizedBox(height: 16),
          _buildSettingsCard(context, status, controls),
          const SizedBox(height: 16),
          _buildInformationCard(context),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    BackgroundMonitoringStatus status,
  ) {
    final theme = Theme.of(context);

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.pause_circle_outline;

    if (status.hasMonitoredCampgrounds &&
        status.isActive &&
        status.notificationsEnabled) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status.hasMonitoredCampgrounds &&
        status.isActive &&
        !status.notificationsEnabled) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else if (status.hasMonitoredCampgrounds && !status.isActive) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monitoring Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.statusText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Monitored',
                    '${status.monitoredCampgrounds}',
                    Icons.nature,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Notifications',
                    status.notificationsEnabled ? 'Enabled' : 'Disabled',
                    status.notificationsEnabled
                        ? Icons.notifications
                        : Icons.notifications_off,
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Service',
                    status.isActive ? 'Running' : 'Stopped',
                    status.isActive ? Icons.play_circle : Icons.stop_circle,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Last Check',
                    _formatLastCheck(status.lastCheckTime),
                    Icons.update,
                    theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    String title,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(
    BuildContext context,
    MonitoringControls controls,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => controls.triggerImmediateCheck(),
                  icon: const Icon(Icons.search),
                  label: const Text('Check Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => controls.startBackgroundMonitoring(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Service'),
                ),
                OutlinedButton.icon(
                  onPressed: () => controls.stopBackgroundMonitoring(),
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Service'),
                ),
                // Temporarily disable preferences until compilation issues are fixed
                // OutlinedButton.icon(
                //   onPressed: () => Navigator.of(context).push(
                //     MaterialPageRoute(
                //       builder: (context) => const NotificationPreferencesScreen(),
                //     ),
                //   ),
                //   icon: const Icon(Icons.notifications),
                //   label: const Text('Preferences'),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoredCampgroundsCard(BuildContext context, WidgetRef ref) {
    final monitoredCampgrounds = DemoDataProvider.getMonitoredCampgrounds();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monitored Campgrounds (${monitoredCampgrounds.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (monitoredCampgrounds.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No campgrounds are currently being monitored.\nGo to the Campgrounds tab to start monitoring.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...monitoredCampgrounds.map(
                (campground) =>
                    _buildMonitoredCampgroundItem(context, campground, ref),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoredCampgroundItem(
    BuildContext context,
    Campground campground,
    WidgetRef ref,
  ) {
    final campgroundActions = ref.read(campgroundActionsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.nature,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campground.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  campground.parkName ?? 'Unknown Park',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              campgroundActions.toggleMonitoring(campground.id, false);
            },
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Stop monitoring',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    BackgroundMonitoringStatus status,
    MonitoringControls controls,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                status.notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: status.notificationsEnabled ? Colors.green : Colors.red,
              ),
              title: const Text('Push Notifications'),
              subtitle: Text(
                status.notificationsEnabled
                    ? 'You\'ll receive alerts when availability is found'
                    : 'Enable notifications to receive availability alerts',
              ),
              trailing: status.notificationsEnabled
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : ElevatedButton(
                      onPressed: () =>
                          controls.requestNotificationPermissions(),
                      child: const Text('Enable'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It Works',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Availability checks run automatically every 6-24 hours in the background\n'
              '• Intelligent scheduling respects API rate limits and battery optimization\n'
              '• Notifications are sent immediately when availability is found\n'
              '• Background monitoring requires at least one campground to be monitored\n'
              '• Service automatically stops when no campgrounds are monitored',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Demo mode: 15% chance of simulated availability per check',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastCheck(DateTime lastCheck) {
    final now = DateTime.now();
    final difference = now.difference(lastCheck);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
