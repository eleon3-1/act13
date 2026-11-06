import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    authStateChanges = _auth.authStateChanges();
  }

  final FirebaseAuth _auth;
  late final Stream<User?> authStateChanges;

  User? get currentUser => _auth.currentUser;

  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    return credential.user;
  }

  Future<User?> register(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    return credential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User _requireUser() {
    final user = currentUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'not-signed-in');
    }

    return user;
  }

  Future<void> updatePassword(String newPassword) async {
    await _requireUser().updatePassword(newPassword);
  }

  Future<void> reauthenticate(String currentPassword) async {
    final user = _requireUser();
    final email = user.email;

    if (email == null) {
      throw FirebaseAuthException(code: 'unsupported-provider');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
  }

  static String errorMessage(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'Check your internet connection and try again.';

      case 'too-many-requests':
        return 'Too many attempts. Wait a while and try again.';

      case 'weak-password':
        return 'Choose a stronger password that meets the project policy.';

      case 'invalid-email':
        return 'Enter a valid email address.';

      case 'email-already-in-use':
        return 'Unable to register with those details. Try signing in.';

      case 'operation-not-allowed':
        return 'Email/password sign-in is currently unavailable.';

      case 'not-signed-in':
      case 'user-token-expired':
      case 'invalid-user-token':
        return 'Please sign out and sign in again to continue.';

      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'wrong-password':
      case 'user-not-found':
      case 'user-disabled':
        return 'Check your email and password and try again.';

      default:
        return 'Unable to complete this request. Please try again.';
    }
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String? _error;

  bool _registering = false;
  bool _loading = false;

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_registering) {
        await widget.authService.register(_email, _password);
      } else {
        await widget.authService.signIn(_email, _password);
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = AuthService.errorMessage(error.code);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to continue. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_registering ? 'Register' : 'Sign In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Enter your email',
                ),
                onChanged: (value) => _email = value,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(email);

                  return valid ? null : 'Enter a valid email address.';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                enabled: !_loading,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Enter your password',
                ),
                onChanged: (value) => _password = value,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Use at least 6 characters.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_loading) const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_registering ? 'Register' : 'Sign In'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _registering = !_registering;
                          _error = null;
                        });
                      },
                child: Text(
                  _registering
                      ? 'Do you already have an account? Sign in'
                      : 'Create an account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
