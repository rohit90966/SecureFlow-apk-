import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/app_lock_service.dart';
import 'add_password_screen.dart';
import 'security_dashboard_screen.dart';
import 'password_generator_screen.dart';
import 'edit_password_screen.dart';
import  'pin_setup_screen.dart';
import 'pin_verification_screen.dart';
import '../services/app_pin_service.dart';
import 'app_lock_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _passwords = [];
  final StorageService _storageService = StorageService();
  bool _isLoading = true;

  // Color Theme
  final Color _primaryColor = const Color(0xFF007AFF); // Azure Blue
  final Color _backgroundColor = const Color(0xFFF4F4F9); // Off-White/Light Gray
  final Color _textColor = const Color(0xFF1C1C1E); // Dark Charcoal
  final Color _successColor = const Color(0xFF34C759); // Success Green
  final Color _warningColor = const Color(0xFFFF9500); // Warning Orange
  final Color _dangerColor = const Color(0xFFFF3B30); // Danger Red

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final savedPasswords = await _storageService.loadPasswords();

      setState(() {
        _passwords = savedPasswords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
// In HomeScreen, add a method to manage PIN:
  void _showPinSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<bool>(
                future: AppPinService().isPinEnabled(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final pinEnabled = snapshot.data ?? false;

                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.lock, color: _primaryColor),
                        title: const Text('App PIN Lock'),
                        subtitle: Text(pinEnabled ? 'Enabled' : 'Disabled'),
                        trailing: Switch(
                          value: pinEnabled,
                          onChanged: (value) {
                            Navigator.pop(context);
                            if (value) {
                              _enablePin();
                            } else {
                              _disablePin();
                            }
                          },
                        ),
                      ),
                      if (pinEnabled) ...[
                        ListTile(
                          leading: Icon(Icons.vpn_key, color: _primaryColor),
                          title: const Text('Change PIN'),
                          onTap: () {
                            Navigator.pop(context);
                            _changePin();
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _enablePin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PinSetupScreen(isInitialSetup: false)),
    );
  }

  void _disablePin() async {
    final success = await AppPinService().disablePin();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIN disabled'),
          backgroundColor: _successColor,
        ),
      );
    }
  }

  void _changePin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PinSetupScreen(isInitialSetup: false)),
    );
  }
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final refreshedPasswords = await _storageService.loadPasswords();

      setState(() {
        _passwords = refreshedPasswords;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Loaded ${_passwords.length} passwords'),
            backgroundColor: _successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createBackup() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _storageService.backupToCloud();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Backup created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Backup creation failed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Backup error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAppLockSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'App Lock Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, dynamic>>(
                future: _getAppLockStatus(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final status = snapshot.data ?? {};
                  final isEnabled = status['enabled'] ?? false;
                  final lockType = status['type'] ?? 'none';
                  final timeout = status['timeout'] ?? 0;

                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Enable App Lock',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _textColor,
                            ),
                          ),
                          value: isEnabled,
                          onChanged: (value) {
                            Navigator.pop(context);
                            if (value) {
                              _setupAppLock();
                            } else {
                              _disableAppLock();
                            }
                          },
                        ),
                      ),
                      if (isEnabled) ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Icon(Icons.security, color: _primaryColor),
                            title: Text(
                              'Lock Type',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            subtitle: Text(
                              lockType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.edit, color: _primaryColor),
                              onPressed: _setupAppLock,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Icon(Icons.timer, color: _primaryColor),
                            title: Text(
                              'Auto-lock',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            subtitle: Text(
                              timeout == 0 ? 'Immediately' : 'After $timeout minutes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.settings, color: _primaryColor),
                              onPressed: _changeLockTimeout,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: _primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: _primaryColor),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getAppLockStatus() async {
    final appLockService = Provider.of<AppLockService>(context, listen: false);
    final isEnabled = await appLockService.isLockEnabled();
    final lockType = await appLockService.getLockType();
    final timeout = await appLockService.getLockTimeout();

    return {
      'enabled': isEnabled,
      'type': lockType,
      'timeout': timeout,
    };
  }

  void _setupAppLock() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppLockSetupScreen()),
    ).then((success) {
      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('App lock configured successfully!'),
            backgroundColor: _successColor,
          ),
        );
      }
    });
  }

  void _disableAppLock() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Disable App Lock',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        content: Text(
          'Are you sure you want to disable app lock?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: _textColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final appLockService = Provider.of<AppLockService>(context, listen: false);
              await appLockService.disableAppLock();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('App lock disabled'),
                  backgroundColor: _warningColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _dangerColor),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _changeLockTimeout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Auto-lock Timeout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppLockService.timeoutOptions.map((timeout) {
              return ListTile(
                title: Text(
                  timeout == 0 ? 'Lock immediately' : 'Lock after $timeout minutes',
                  style: TextStyle(
                    fontSize: 16,
                    color: _textColor,
                  ),
                ),
                trailing: Icon(Icons.check, color: _primaryColor),
                onTap: () async {
                  final appLockService = Provider.of<AppLockService>(context, listen: false);
                  await appLockService.setLockTimeout(timeout);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Timeout updated'),
                      backgroundColor: _successColor,
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Secure Vault',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: _createBackup,
            tooltip: 'Create Backup',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          // IconButton(
          //   icon: const Icon(Icons.lock),
          //   onPressed: _showAppLockSettings,
          //   tooltip: 'App Lock',
          // ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingScreen() : _getCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _currentIndex == 0 && !_isLoading
          ? FloatingActionButton(
        onPressed: () => _addPassword(context),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.lock_outline),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lock, color: _primaryColor),
              ),
              label: 'Vault',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.security_outlined),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.security, color: _primaryColor),
              ),
              label: 'Security',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.vpn_key_outlined),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.vpn_key, color: _primaryColor),
              ),
              label: 'Generator',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading your passwords...',
            style: TextStyle(
              fontSize: 16,
              color: _textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildPasswordList();
      case 1:
        return SecurityDashboardScreen(passwords: _passwords);
      case 2:
        return const PasswordGeneratorScreen();
      default:
        return _buildPasswordList();
    }
  }

  Widget _buildPasswordList() {
    return Column(
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.lock, color: _primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_passwords.length} ${_passwords.length == 1 ? 'Password' : 'Passwords'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
              if (_passwords.isNotEmpty)
                TextButton(
                  onPressed: () => _clearAllPasswords(),
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: _dangerColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _passwords.isEmpty ? _buildEmptyState() : _buildPasswordListView(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'No Passwords Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first password to start securing your digital life',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _addPassword(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add First Password',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: _passwords.length,
      itemBuilder: (context, index) {
        final password = _passwords[index];
        return _buildPasswordItem(password, index);
      },
    );
  }

  Widget _buildPasswordItem(Map<String, dynamic> password, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Dismissible(
        key: Key(password['id'].toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: _dangerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_forever, color: Colors.white, size: 24),
        ),
        onDismissed: (direction) => _deletePassword(password['id']),
        child: Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                _getCategoryIcon(password['category']),
                color: _primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              password['title'] ?? 'No Title',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  password['username'] ?? 'No Username',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildStrengthIndicator(password['strength']),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.visibility_outlined, color: Colors.grey.shade600),
              onPressed: () => _showPasswordDetails(context, password),
            ),
            onTap: () => _showPasswordDetails(context, password),
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator(String? strength) {
    Color color = Colors.grey;
    IconData icon = Icons.security;

    if (strength != null) {
      if (strength.contains('Very Strong')) {
        color = _successColor;
        icon = Icons.verified;
      } else if (strength.contains('Strong')) {
        color = _successColor;
        icon = Icons.verified;
      } else if (strength.contains('Moderate')) {
        color = _warningColor;
        icon = Icons.warning_amber;
      } else if (strength.contains('Weak') || strength.contains('Very Weak')) {
        color = _dangerColor;
        icon = Icons.error_outline;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          strength?.split(' ')[0] ?? 'Unknown',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Banking':
        return Icons.account_balance;
      case 'Social Media':
        return Icons.people;
      case 'Email':
        return Icons.email;
      case 'Work':
        return Icons.work;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  void _addPassword(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPasswordScreen()),
    );

    if (result == true && mounted) {
      await _loadPasswords();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Password saved successfully!'),
          backgroundColor: _successColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateToEditPassword(BuildContext context, Map<String, dynamic> password) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPasswordScreen(passwordData: password),
      ),
    ).then((success) {
      if (success == true && mounted) {
        _loadPasswords();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Password updated successfully!'),
            backgroundColor: _successColor,
          ),
        );
      }
    });
  }

  void _deletePassword(String id) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Deleting password...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      final passwordToDelete = _passwords.firstWhere(
            (pwd) => pwd['id'] == id,
        orElse: () => {},
      );

      if (passwordToDelete.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Password not found'),
            backgroundColor: _dangerColor,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      final documentId = passwordToDelete['documentId'] ?? passwordToDelete['id'].toString();
      final success = await _storageService.deletePassword(documentId);

      if (success) {
        setState(() {
          _passwords.removeWhere((password) => password['id'] == id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Password deleted successfully'),
            backgroundColor: _successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Failed to delete from cloud'),
            backgroundColor: _dangerColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Error deleting password'),
          backgroundColor: _dangerColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearAllPasswords() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear All Passwords',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        content: Text(
          'This will remove all passwords from this device. Continue?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: _textColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _passwords.clear();
              });

              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('saved_passwords');

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✅ All passwords cleared'),
                  backgroundColor: _successColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _dangerColor),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDetails(BuildContext context, Map<String, dynamic> password) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getCategoryIcon(password['category']), color: _primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      password['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Username', password['username'] ?? 'Not set'),
              _buildDetailRow('Password', '••••••••'),
              _buildDetailRow('Category', password['category'] ?? 'Other'),
              _buildDetailRow('Strength', password['strength'] ?? 'Not analyzed'),
              if (password['website'] != null && (password['website'] as String).isNotEmpty)
                _buildDetailRow('Website', password['website']),
              if (password['notes'] != null && (password['notes'] as String).isNotEmpty)
                _buildDetailRow('Notes', password['notes']),
              _buildDetailRow('Created', _formatDate(password['createdAt'])),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showActualPassword(context, password),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Show Password'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToEditPassword(context, password);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _warningColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActualPassword(BuildContext context, Map<String, dynamic> password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Password'),
        content: SelectableText(
          password['password'] ?? 'No password',
          style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        content: Text(
          'Are you sure you want to logout? Your passwords are safely stored.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: _textColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).logout();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}