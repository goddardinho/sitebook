import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/models/user.dart';
import '../monitoring/monitoring_settings_screen.dart';
import '../credentials/models/reservation_credential.dart';
import '../credentials/services/credential_storage_service.dart';
// Temporarily disabled: import '../notifications/notification_preferences_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final CredentialStorageService _credentialStorage =
      CredentialStorageService();
  List<ReservationCredential> _credentials = [];
  bool _credentialsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    var creds = await _credentialStorage.loadCredentials();
    if (creds.isEmpty) {
      // Pre-populate with recreation.gov
      final defaultCred = ReservationCredential(
        id: 'recreation-gov',
        name: 'National Park (recreation.gov)',
        url: 'https://www.recreation.gov/',
        username: '',
        password: '',
      );
      await _credentialStorage.upsertCredential(defaultCred);
      creds = [defaultCred];
    }
    setState(() {
      _credentials = creds;
      _credentialsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Loading settings...', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildProfileHeader(context, theme, authState.user!),
            const SizedBox(height: 24),
            _buildStatsSection(context, theme, authState.user!),
            const SizedBox(height: 24),
            _buildReservationSystemsSection(context, theme),
            const SizedBox(height: 24),
            _buildAppPreferencesSection(context, theme),
            const SizedBox(height: 24),
            _buildSupportSection(context, theme, authActions),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ThemeData theme, User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    user.email.isNotEmpty ? user.email[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Local Account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, ThemeData theme, User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Saved Sites',
                  '0',
                  Icons.bookmark_border,
                  theme,
                ),
                _buildStatItem('Searches', '0', Icons.search, theme),
                _buildStatItem('Visits', '0', Icons.place, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildReservationSystemsSection(
    BuildContext context,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reservation Systems',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddOrEditCredentialDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your login credentials for reservation systems',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_credentialsLoading)
              const Center(child: CircularProgressIndicator())
            else if (_credentials.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.vpn_key_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No credentials saved',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._credentials.map(
                (credential) => _buildCredentialTile(credential, theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialTile(
    ReservationCredential credential,
    ThemeData theme,
  ) {
    return ListTile(
      leading: Icon(Icons.vpn_key, color: theme.colorScheme.primary),
      title: Text(credential.name),
      subtitle: Text(credential.url),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showAddOrEditCredentialDialog(credential),
            tooltip: 'Edit credential',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmation(credential),
            tooltip: 'Delete credential',
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferencesSection(BuildContext context, ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'App Preferences',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Help & Support',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
            subtitle: 'Version info and legal',
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
            titleColor: Colors.red,
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
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: titleColor != null ? TextStyle(color: titleColor) : null,
      ),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showAddOrEditCredentialDialog([
    ReservationCredential? credential,
  ]) async {
    final result = await showDialog<ReservationCredential>(
      context: context,
      builder: (context) => ReservationCredentialDialog(credential: credential),
    );
    if (result != null) {
      await _credentialStorage.upsertCredential(result);
      _loadCredentials();
    }
  }

  void _showDeleteConfirmation(ReservationCredential credential) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credential'),
        content: Text(
          'Are you sure you want to delete credentials for ${credential.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _credentialStorage.removeCredential(credential.id);
              _loadCredentials();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appearance'),
        content: const Text(
          'Appearance settings will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        content: const Text(
          'Help and support features will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SiteBook',
      applicationVersion: '1.6.0',
      applicationIcon: const FlutterLogo(size: 48),
      children: [
        const Text(
          'Find and reserve the perfect campsite for your next outdoor adventure.',
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context, AuthActions authActions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authActions.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class ReservationCredentialDialog extends StatefulWidget {
  final ReservationCredential? credential;
  const ReservationCredentialDialog({this.credential, super.key});

  @override
  State<ReservationCredentialDialog> createState() =>
      _ReservationCredentialDialogState();
}

class _ReservationCredentialDialogState
    extends State<ReservationCredentialDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.credential?.name ?? '',
    );
    _urlController = TextEditingController(text: widget.credential?.url ?? '');
    _usernameController = TextEditingController(
      text: widget.credential?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.credential?.password ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.credential == null ? 'Add Credential' : 'Edit Credential',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'System Name'),
              validator: (value) =>
                  value?.isEmpty == true ? 'Please enter a name' : null,
            ),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL'),
              validator: (value) =>
                  value?.isEmpty == true ? 'Please enter a URL' : null,
            ),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              final credential = ReservationCredential(
                id: widget.credential?.id ?? DateTime.now().toString(),
                name: _nameController.text,
                url: _urlController.text,
                username: _usernameController.text,
                password: _passwordController.text,
              );
              Navigator.pop(context, credential);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
