import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'setup_screen.dart';
import '../services/storage_service.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _useBiometric = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.debugBiometricStatus();
    final biometricAvailable = await authService.isBiometricAvailable();
    final biometricEnabled = await authService.isBiometricEnabled();

    print('🔍 Biometric Status - Available: $biometricAvailable, Enabled: $biometricEnabled');

    setState(() {
      _biometricAvailable = biometricAvailable;
      _biometricEnabled = biometricEnabled;
      _useBiometric = biometricAvailable && biometricEnabled;
    });

    // Auto-trigger biometric if available and enabled
    if (_useBiometric) {
      print('🔄 Auto-triggering biometric authentication...');
      await _authenticateWithBiometric();
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.authenticate();

      if (success && mounted) {
        print('✅ Biometric authentication successful');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        print('❌ Biometric authentication failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Biometric authentication error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithEmailPassword() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.loginUser(_emailController.text, _passwordController.text);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && mounted) {
      print('✅ Login successful, recovering passwords from Firebase...');

      // NEW: Recover passwords from Firebase after successful login
      try {
        await StorageService().recoverPasswordsFromFirebase();
        print('✅ Password recovery completed after login');
      } catch (e) {
        print('⚠️ Password recovery failed after login: $e');
        // Continue anyway - user can manually sync later
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _tapCount++;
        if (_tapCount >= 3) {
          _tapCount = 0;
          Navigator.pushNamed(context, '/debug');
        }
        Future.delayed(const Duration(seconds: 2), () {
          _tapCount = 0;
        });
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Secure Password Manager',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to access your cloud-synced passwords',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                onSubmitted: (_) => _loginWithEmailPassword(),
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Signing in...'),
                  ],
                )
              else
                Column(
                  children: [
                    // Email/Password Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loginWithEmailPassword,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    // Biometric Button
                    if (_biometricAvailable && _biometricEnabled) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _authenticateWithBiometric,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Use Biometric Authentication'),
                        ),
                      ),
                    ],

                    // Debug Button
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: TextButton(
                        onPressed: () async {
                          final authService = Provider.of<AuthService>(context, listen: false);
                          await authService.debugBiometricStatus();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                        ),
                        child: const Text(
                          'DEBUG: Check Biometric Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),

                    // Register Link
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const SetupScreen()),
                        );
                      },
                      child: const Text(
                        'Don\'t have an account? Create one',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),
              if (!_biometricAvailable)
                const Text(
                  'Biometric authentication not available\non this device',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

              if (_biometricAvailable && !_biometricEnabled)
                const Text(
                  'Biometric available but not enabled\nEnable in settings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
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