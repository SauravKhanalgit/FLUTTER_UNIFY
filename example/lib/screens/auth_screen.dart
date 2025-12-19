import 'package:flutter/material.dart';
import 'package:flutter_unify/flutter_unify.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _statusMessage = '';
  bool _isLoading = false;
  UnifiedUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _listenToAuthChanges();
  }

  void _checkCurrentUser() {
    setState(() {
      _currentUser = Unify.auth.currentUser;
    });
  }

  void _listenToAuthChanges() {
    Unify.auth.onAuthStateChanged.listen((event) {
      setState(() {
        _currentUser = event.user;
        _statusMessage = event.user != null
            ? 'Signed in as ${event.user!.primaryIdentifier}'
            : 'Signed out';
      });
    });
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing in...';
    });

    try {
      final result = await Unify.performance.trackOperation(
        'auth_signin',
        () => Unify.auth.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        ),
      );

      if (result.success) {
        setState(() {
          _statusMessage = 'Signed in successfully!';
        });

        // Record event
        Unify.dev.recordEvent(DashboardEvent(
          type: EventType.auth,
          title: 'Email Sign In',
          timestamp: DateTime.now(),
          description: 'User signed in with email',
          data: {'email': _emailController.text},
          success: true,
        ));
      } else {
        setState(() {
          _statusMessage = 'Sign in failed: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating account...';
    });

    try {
      final result = await Unify.performance.trackOperation(
        'auth_signup',
        () => Unify.auth.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        ),
      );

      if (result.success) {
        setState(() {
          _statusMessage = 'Account created successfully!';
        });

        Unify.dev.recordEvent(DashboardEvent(
          type: EventType.auth,
          title: 'Email Sign Up',
          timestamp: DateTime.now(),
          description: 'User created account with email',
          data: {'email': _emailController.text},
          success: true,
        ));
      } else {
        setState(() {
          _statusMessage = 'Sign up failed: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing in anonymously...';
    });

    try {
      final result = await Unify.auth.signInAnonymously();

      if (result.success) {
        setState(() {
          _statusMessage = 'Signed in anonymously!';
        });

        Unify.dev.recordEvent(DashboardEvent(
          type: EventType.auth,
          title: 'Anonymous Sign In',
          timestamp: DateTime.now(),
          description: 'User signed in anonymously',
          success: true,
        ));
      } else {
        setState(() {
          _statusMessage = 'Anonymous sign in failed: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithProvider(AuthProvider provider) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing in with ${provider.name}...';
    });

    try {
      final result = await Unify.auth.signInWithProvider(provider);

      if (result.success) {
        setState(() {
          _statusMessage = 'Signed in with ${provider.name}!';
        });

        Unify.dev.recordEvent(DashboardEvent(
          type: EventType.auth,
          title: 'OAuth Sign In',
          timestamp: DateTime.now(),
          description: 'User signed in with OAuth provider',
          data: {'provider': provider.name},
          success: true,
        ));
      } else {
        setState(() {
          _statusMessage = 'OAuth sign in failed: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing out...';
    });

    try {
      final success = await Unify.auth.signOut();

      if (success) {
        setState(() {
          _statusMessage = 'Signed out successfully!';
        });

        Unify.dev.recordEvent(DashboardEvent(
          type: EventType.auth,
          title: 'Sign Out',
          timestamp: DateTime.now(),
          description: 'User signed out',
          success: true,
        ));
      } else {
        setState(() {
          _statusMessage = 'Sign out failed';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current User Status
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authentication Status',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (_currentUser != null) ...[
                    ListTile(
                      leading: CircleAvatar(
                        child: Text(_currentUser!.primaryIdentifier.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(_currentUser!.primaryIdentifier),
                      subtitle: Text(_currentUser!.isEmailVerified == true
                          ? 'Email verified'
                          : 'Email not verified'),
                      trailing: IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: _signOut,
                        tooltip: 'Sign out',
                      ),
                    ),
                  ] else ...[
                    const ListTile(
                      leading: Icon(Icons.person_off, size: 40),
                      title: Text('Not signed in'),
                      subtitle: Text('Sign in to access features'),
                    ),
                  ],
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_statusMessage),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Email Authentication
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email Authentication',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signInWithEmail,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _signUpWithEmail,
                          child: const Text('Sign Up'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // OAuth Providers
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OAuth Authentication',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign in with popular OAuth providers. These use mock implementations for demo purposes.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildOAuthButton(
                        'Google',
                        Colors.red,
                        () => _signInWithProvider(AuthProvider.google),
                      ),
                      _buildOAuthButton(
                        'Apple',
                        Colors.black,
                        () => _signInWithProvider(AuthProvider.apple),
                      ),
                      _buildOAuthButton(
                        'GitHub',
                        Colors.grey[800]!,
                        () => _signInWithProvider(AuthProvider.github),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Anonymous Authentication
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Anonymous Authentication',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign in without providing credentials. Useful for temporary sessions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signInAnonymously,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Sign In Anonymously'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOAuthButton(String provider, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: const Icon(Icons.login),
      label: Text('Sign in with $provider'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

