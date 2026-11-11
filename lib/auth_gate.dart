import 'package:flutter/material.dart';

import 'auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    required this.authService,
    required this.authenticatedBuilder,
    super.key,
  });

  final UserAuthService authService;
  final WidgetBuilder authenticatedBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AuthStatusPage(
            message:
                'Could not check your sign-in status. Please restart the app.',
          );
        }
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.active) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return SignInPage(authService: authService);
        }
        return authenticatedBuilder(context);
      },
    );
  }
}

class FirebaseSetupPage extends StatelessWidget {
  const FirebaseSetupPage({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return _AuthStatusPage(
      message: message ??
          'Firebase is not configured. Set the Firebase app values and Google OAuth client ID using the FIREBASE_* and GOOGLE_SERVER_CLIENT_ID build options.',
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({required this.authService, super.key});

  final UserAuthService authService;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isSigningIn = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });
    try {
      await widget.authService.signInWithGoogle();
    } on AuthServiceException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'pricegent',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A clearer path to what you learn.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 28),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: _isSigningIn ? null : _signIn,
                    icon: _isSigningIn
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthStatusPage extends StatelessWidget {
  const _AuthStatusPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
