import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final authActions = ref.read(authActionsProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // App logo and title
              _buildHeader(theme),

              const SizedBox(height: 48),

              // Login form
              _buildLoginForm(theme, authState, authActions),

              const SizedBox(height: 24),

              // Sign up link
              _buildSignUpLink(theme),

              const SizedBox(height: 32),

              // Additional options
              _buildAdditionalOptions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.park, color: theme.colorScheme.onPrimary, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to SiteBook',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No SiteBook account required. Use Demo mode or add credentials for reservation systems.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(ThemeData theme, authState, AuthActions authActions) {
    return const SizedBox.shrink(); // Hide email/password form
  }

  Widget _buildSignUpLink(ThemeData theme) {
    return const SizedBox.shrink(); // Hide sign up link
  }

  Widget _buildAdditionalOptions(ThemeData theme) {
    return Column(
      children: [
        // Divider with "or"
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),

        const SizedBox(height: 24),

        // Demo login button
        OutlinedButton(
          onPressed: () => _handleDemoLogin(ref.read(authActionsProvider)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Continue as Demo User',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleDemoLogin(AuthActions authActions) {
    // Clear any previous error
    authActions.clearError();

    // Use demo credentials
    _emailController.text = 'demo@sitebook.app';
    _passwordController.text = 'demo123';

    authActions.signIn('demo@sitebook.app', 'demo123');
  }
}
