import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/auth_repository.dart';
import 'auth_providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Sign-in could not be completed. Try again shortly.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthPageFrame(
    eyebrow: 'YOUR PERSONAL SPACE',
    title: 'Welcome back.',
    subtitle: 'Sign in to continue with LIFE OS.',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('sign_in_email'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: validateEmail,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('sign_in_password'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _busy ? null : _signIn(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter your password.' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => context.go('/auth/reset-password'),
              child: const Text('Forgot password?'),
            ),
          ),
          if (_error != null) ...[
            _InlineError(message: _error!),
            const SizedBox(height: AppSpacing.md),
          ],
          FilledButton(
            key: const Key('sign_in_submit'),
            onPressed: _busy ? null : _signIn,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'There is no sign-up form in this app. Until server-side access restrictions are enabled, any existing account in this Firebase project may be able to sign in.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _sent = false;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_emailController.text);
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'The request could not be completed. Try again shortly.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthPageFrame(
    eyebrow: 'ACCOUNT RECOVERY',
    title: 'Reset password.',
    subtitle: 'We’ll send a reset link if that account is registered.',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('reset_email'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: validateEmail,
          ),
          if (_sent) ...[
            const SizedBox(height: AppSpacing.md),
            const _InlineSuccess(
              message:
                  'If that account is registered, a password reset email is on its way.',
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            _InlineError(message: _error!),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const Key('reset_submit'),
            onPressed: _busy ? null : _sendReset,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send reset link'),
          ),
          TextButton.icon(
            onPressed: _busy ? null : () => context.go('/auth/sign-in'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to sign in'),
          ),
        ],
      ),
    ),
  );
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => AuthPageFrame(
    eyebrow: 'SETUP REQUIRED',
    title: 'Connect your Firebase project.',
    subtitle:
        'Authentication is not available until Firebase is configured for this build.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _InlineError(
          message:
              'Firebase configuration is missing or could not be initialized.',
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Follow the Firebase setup steps in the README. This screen does not create an account or store passwords.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Firebase client options are supplied when the app is built. Restart the app after configuration is added.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class AuthPageFrame extends StatelessWidget {
  const AuthPageFrame({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bubble_chart_rounded,
                      color: AppColors.cyan,
                      size: 30,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'LIFE OS',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(letterSpacing: 1.3),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                SurfaceCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        eyebrow,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.cyan,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      child,
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Built for Abdullah and Jannat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0x22FF7D91),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF9CAC), size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFFC3CB)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InlineSuccess extends StatelessWidget {
  const _InlineSuccess({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0x2278E0B1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.green)),
    ),
  );
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email address.';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}
