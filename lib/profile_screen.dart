import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'authservice.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  final User user;
  final AuthService authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _currentPassword = TextEditingController();

  bool _loading = false;
  bool _needsReauthentication = false;
  bool _feedbackIsError = false;
  String? _feedback;

  @override
  void dispose() {
    _newPassword.dispose();
    _currentPassword.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_loading || !_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _feedback = null;
    });

    try {
      if (_needsReauthentication) {
        await widget.authService.reauthenticate(_currentPassword.text);
      }

      await widget.authService.updatePassword(_newPassword.text);

      if (!mounted) return;

      _newPassword.clear();
      _currentPassword.clear();

      setState(() {
        _needsReauthentication = false;
        _feedbackIsError = false;
        _feedback = 'Password updated successfully.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _feedbackIsError = true;

        if (error.code == 'requires-recent-login') {
          _needsReauthentication = true;
          _feedback =
              'For security, enter your current password below, '
              'then tap Update Password again.';
        } else {
          _feedback = AuthService.errorMessage(error.code);
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _feedbackIsError = true;
        _feedback = 'Unable to update your password. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _feedback = null;
    });

    try {
      await widget.authService.signOut();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _feedbackIsError = true;
        _feedback = AuthService.errorMessage(error.code);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _feedbackIsError = true;
        _feedback = 'Unable to sign out. Please try again.';
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
      appBar: AppBar(title: const Text('Your profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('you are signed in as:'),
              Text(
                widget.user.email ?? 'Email unavailable',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _newPassword,
                enabled: !_loading,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Use at least 6 characters.';
                  }

                  return null;
                },
              ),
              if (_needsReauthentication) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _currentPassword,
                  enabled: !_loading,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your current password to continue.';
                    }

                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              if (_feedback != null)
                Text(
                  _feedback!,
                  style: TextStyle(
                    color: _feedbackIsError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              if (_loading) const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _updatePassword,
                child: const Text('Update Password'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loading ? null : _signOut,
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
