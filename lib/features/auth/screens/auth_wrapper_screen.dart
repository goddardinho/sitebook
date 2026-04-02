import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class AuthWrapperScreen extends ConsumerWidget {
  final Widget authenticatedChild;

  const AuthWrapperScreen({super.key, required this.authenticatedChild});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildChild(authState, theme),
    );
  }

  Widget _buildChild(AuthState authState, ThemeData theme) {
    if (authState.status == AuthStatus.unknown) {
      return _buildLoadingScreen(theme);
    } else if (authState.status == AuthStatus.authenticating) {
      return _buildAuthenticatingScreen(theme);
    } else if (authState.status == AuthStatus.authenticated) {
      return authenticatedChild;
    } else {
      return const LoginScreen();
    }
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.park,
                color: theme.colorScheme.onPrimary,
                size: 50,
              ),
            ),

            const SizedBox(height: 32),

            // Loading indicator
            CircularProgressIndicator(color: theme.colorScheme.primary),

            const SizedBox(height: 16),

            Text(
              'SiteBook',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Loading your camping experience...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatingScreen(ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Signing you in...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
