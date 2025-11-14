import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Services
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/native_password_service.dart';
import 'services/storage_service.dart';
import 'services/app_lock_service.dart';
import 'services/app_pin_service.dart';

// Screens
import 'screens/setup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/debug_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/app_lock_setup_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/pin_verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PasswordManagerApp());
}

class PasswordManagerApp extends StatelessWidget {
  const PasswordManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => FirebaseService()),
        Provider(create: (context) => AppLockService()),
        Provider(create: (context) => AppPinService()),
      ],
      child: MaterialApp(
        title: 'Secure Password Manager',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const AppWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/setup': (context) => const SetupScreen(),
          '/debug': (context) => const DebugScreen(),
          '/lock': (context) => const LockScreen(),
          '/app-lock-setup': (context) => const AppLockSetupScreen(),
          '/pin-setup': (context) => const PinSetupScreen(isInitialSetup: false),
          '/pin-verify': (context) => const PinVerificationScreen(),
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoading = true;
  bool _needsSetup = true;
  bool _needsPinSetup = false;
  bool _needsPinVerification = false;
  String _errorMessage = '';
  bool _hasError = false;
  List<String> _completedSteps = [];
  bool _shouldShowLock = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('🚀 Initializing Password Manager App...');
      _updateCompletedStep('Starting...');

      // Step 1: Initialize Firebase Services
      _updateCompletedStep('Initializing Firebase...');
      print('Step 1: Initializing Firebase services...');
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.checkAuthState();
      _updateCompletedStep('Firebase Ready');
      print('✓ Firebase services initialized');

      // Step 2: Initialize Storage Service (Encryption + Cloud Sync)
      _updateCompletedStep('Setting Up Encryption...');
      print('Step 2: Initializing storage and encryption service...');
      await StorageService().initialize();
      _updateCompletedStep('Encryption Ready');
      print('✓ Storage service initialized');

      // Step 3: Initialize Native Database
      _updateCompletedStep('Loading Database...');
      print('Step 3: Initializing native database...');
      await NativePasswordService.initializeDatabase();
      _updateCompletedStep('Database Ready');
      print('✓ Database initialized successfully');

      // Step 4: Initialize Auth Service
      _updateCompletedStep('Setting Up Security...');
      print('Step 4: Initializing auth service...');
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.initialize();
      _updateCompletedStep('Security Ready');
      print('✓ Auth service initialized');

      // Step 5: Initialize App Lock Service
      _updateCompletedStep('Setting Up App Lock...');
      print('Step 5: Initializing app lock service...');
      final appLockService = Provider.of<AppLockService>(context, listen: false);
      await appLockService.initialize();
      _updateCompletedStep('App Lock Ready');
      print('✓ App lock service initialized');

      // Step 6: Check PIN status
      _updateCompletedStep('Checking PIN Security...');
      print('Step 6: Checking PIN status...');
      final pinService = AppPinService();
      final isLoggedIn = firebaseService.isLoggedIn;

      if (isLoggedIn) {
        final pinEnabled = await pinService.isPinEnabled();
        final pinSetupCompleted = await pinService.isPinSetupCompleted();

        print('📱 PIN Status - Enabled: $pinEnabled, Setup Completed: $pinSetupCompleted');

        if (pinEnabled && pinSetupCompleted) {
          // PIN is enabled and setup completed, show verification
          print('🔐 PIN verification required');
          setState(() {
            _needsPinVerification = true;
            _isLoading = false;
          });
          return;
        } else if (pinEnabled && !pinSetupCompleted) {
          // PIN enabled but setup not completed, show setup
          print('🔐 PIN setup required');
          setState(() {
            _needsPinSetup = true;
            _isLoading = false;
          });
          return;
        }
      }

      // Step 7: Check if user is already logged in with Firebase
      print('Step 7: Checking Firebase authentication status...');
      print('✓ Firebase auth check completed - logged in: $isLoggedIn');

      if (isLoggedIn) {
        // User is already logged in, sync data from cloud
        print('✅ User already logged in: ${firebaseService.userEmail}');

        // Step 8: Check app lock status
        _updateCompletedStep('Checking Security...');
        print('Step 8: Checking app lock status...');
        final shouldLock = await appLockService.shouldShowLock();
        print('✓ App lock check completed - should lock: $shouldLock');

        // Step 9: Sync data from Firebase AND recover passwords
        if (!shouldLock) {
          _updateCompletedStep('Syncing Cloud Data...');
          print('Step 9: Syncing and recovering data from cloud...');
          try {
            // First, try to sync normally
            await StorageService().syncData();

            // Force recover passwords from Firebase to ensure data persistence
            await StorageService().recoverPasswordsFromFirebase();

            _updateCompletedStep('Cloud Sync Complete');
            print('✓ Cloud sync and recovery completed');
          } catch (e) {
            _updateCompletedStep('Cloud Sync Complete');
            print('⚠️ Cloud sync failed but continuing: $e');
          }
        }

        if (mounted) {
          setState(() {
            _needsSetup = false;
            _isLoading = false;
            _hasError = false;
            _shouldShowLock = shouldLock;
          });
        }
      } else {
        // Step 8: Check if this is first time setup (local check)
        print('Step 8: Checking if first time setup...');
        final needsSetup = await authService.isFirstTime();
        print('✓ Setup check completed - needsSetup: $needsSetup');

        // Step 9: Check if biometric is available
        print('Step 9: Checking biometric availability...');
        final isBiometricAvailable = await authService.isBiometricAvailable();
        print('✓ Biometric check completed - available: $isBiometricAvailable');

        _updateCompletedStep('Ready to Start');

        if (mounted) {
          setState(() {
            _needsSetup = needsSetup;
            _isLoading = false;
            _hasError = false;
            _shouldShowLock = false;
          });
        }
      }

      print('🎉 App initialization completed successfully');

    } catch (e) {
      print('❌ Error during app initialization: $e');
      _updateCompletedStep('Initialization Failed');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
          _shouldShowLock = false;
          _needsPinSetup = false;
          _needsPinVerification = false;
        });
      }
    }
  }

  void _updateCompletedStep(String step) {
    if (mounted) {
      setState(() {
        _completedSteps.add(step);
      });
    }
  }

  void _retryInitialization() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _completedSteps.clear();
      _shouldShowLock = false;
      _needsPinSetup = false;
      _needsPinVerification = false;
    });
    _initializeApp();
  }

  void _onPinVerificationComplete(bool success) {
    print('PIN verification completed with success: $success');

    if (success) {
      // PIN verification successful, proceed to home
      if (mounted) {
        setState(() {
          _needsPinVerification = false;
          _isLoading = false;
        });

        // Use Navigator to ensure proper navigation stack
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        });
      }
    } else {
      // PIN verification failed, stay on verification screen
      print('❌ PIN verification failed - user must enter correct PIN');
      // Don't change state - keep showing verification screen
    }
  }

  void _onPinSetupComplete(bool success) {
    print('PIN setup completed with success: $success');

    if (mounted) {
      setState(() {
        _needsPinSetup = false;
        _isLoading = false;
      });

      final firebaseService = Provider.of<FirebaseService>(context, listen: false);

      if (success) {
        // PIN setup successful
        print('✅ PIN setup successful');

        if (firebaseService.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          });
        }
      } else {
        // PIN setup skipped or failed
        print('⚠️ PIN setup skipped or failed');

        if (firebaseService.isLoggedIn) {
          // User skipped PIN setup but is logged in, go to home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          });
        } else {
          // Go back to setup/login flow
          setState(() {
            _needsSetup = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_hasError) {
      return _buildErrorScreen();
    }

    // Show PIN verification if needed
    if (_needsPinVerification) {
      return PinVerificationScreen(
        onVerificationComplete: _onPinVerificationComplete,
      );
    }

    // Show PIN setup if needed
    if (_needsPinSetup) {
      return PinSetupScreen(
        isInitialSetup: false,
        onSetupComplete: _onPinSetupComplete,
      );
    }

    // Show app lock screen if needed
    if (_shouldShowLock) {
      return const LockScreen();
    }

    // Check if user is already logged in with Firebase
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    if (firebaseService.isLoggedIn) {
      return const HomeScreen(); // User is logged in, go directly to home
    }

    return _needsSetup ? const SetupScreen() : const LoginScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // App Title
              const Text(
                'Secure Vault',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Password Manager',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              // Loading Indicator with percentage
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _completedSteps.length / 9,
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                      backgroundColor: Colors.blue.shade100,
                    ),
                  ),
                  Text(
                    '${((_completedSteps.length / 9) * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Loading Text
              Text(
                _completedSteps.isNotEmpty ? _completedSteps.last : 'Starting...',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),

              // Loading Steps
              _buildLoadingSteps(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSteps() {
    final allSteps = [
      'Initializing Firebase...',
      'Setting Up Encryption...',
      'Loading Database...',
      'Setting Up Security...',
      'Setting Up App Lock...',
      'Checking PIN Security...',
      'Checking Security...',
      'Syncing Cloud Data...',
      'Ready to Start'
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: allSteps.map((step) {
          final isCompleted = _completedSteps.contains(step);
          final isCurrent = _completedSteps.isNotEmpty &&
              _completedSteps.last == step &&
              _isLoading;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : isCurrent
                        ? Colors.blue
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : isCurrent
                      ? const Icon(Icons.refresh, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step,
                    style: TextStyle(
                      color: isCompleted
                          ? Colors.green
                          : isCurrent
                          ? Colors.blue
                          : Colors.grey,
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Error Title
              const Text(
                'Initialization Failed',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Error Message
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : 'Unable to initialize the password manager. Please check your internet connection and try again.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Retry Button
              ElevatedButton.icon(
                onPressed: _retryInitialization,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Retry Initialization',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 20),

              // Debug Button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/debug');
                },
                icon: const Icon(Icons.bug_report_rounded),
                label: const Text('Debug Information'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              const SizedBox(height: 20),

              // Continue Anyway Button
              TextButton(
                onPressed: () {
                  // Try to continue with limited functionality
                  final firebaseService = Provider.of<FirebaseService>(context, listen: false);
                  if (firebaseService.isLoggedIn) {
                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    Navigator.pushReplacementNamed(context, '/setup');
                  }
                },
                child: const Text(
                  'Continue with Limited Functionality',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}