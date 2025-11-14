import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/security_service.dart';

class EditPasswordScreen extends StatefulWidget {
  final Map<String, dynamic> passwordData;
  final String? previousPassword;

  const EditPasswordScreen({
    super.key,
    required this.passwordData,
    this.previousPassword,
  });

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  final SecurityService _securityService = SecurityService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'General';
  String _passwordStrength = 'Moderate';
  bool _isLoading = false;
  bool _showPassword = false;
  List<String> _previousPasswords = [];

  final List<String> _categories = [
    'General',
    'Banking',
    'Social Media',
    'Email',
    'Work',
    'Shopping',
    'Entertainment',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();

    // FIX DROPDOWN ERROR - ADDED THIS
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'General';
      print('🔄 Fixed dropdown category to "General"');
    }
  }

  void _initializeData() {
    _titleController.text = widget.passwordData['title'] ?? '';
    _usernameController.text = widget.passwordData['username'] ?? '';
    _passwordController.text = widget.passwordData['password'] ?? '';
    _websiteController.text = widget.passwordData['website'] ?? '';
    _notesController.text = widget.passwordData['notes'] ?? '';
    _selectedCategory = widget.passwordData['category'] ?? 'General';
    _passwordStrength = widget.passwordData['strength'] ?? 'Moderate';

    // Initialize previous passwords
    if (widget.previousPassword != null && widget.previousPassword!.isNotEmpty) {
      _previousPasswords = [widget.previousPassword!];
    }

    // Load any existing password history
    final existingHistory = widget.passwordData['passwordHistory'] ?? [];
    if (existingHistory is List) {
      _previousPasswords.addAll(existingHistory.cast<String>());
    }
  }

  void _analyzePassword() {
    final password = _passwordController.text;
    if (password.isNotEmpty) {
      final audit = _securityService.auditSinglePassword(password);
      setState(() {
        _passwordStrength = audit['strength'];
      });
    }
  }

  Future<void> _savePassword() async {
    print('🔄 Starting password update...');
    if (_formKey.currentState!.validate()) {
      print('✅ Form validation passed');

      setState(() {
        _isLoading = true;
      });

      try {
        final updates = {
          'title': _titleController.text,
          'username': _usernameController.text,
          'password': _passwordController.text,
          'website': _websiteController.text,
          'category': _selectedCategory,
          'notes': _notesController.text,
          'strength': _passwordStrength,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        print('📝 Update data: $updates');

        final passwordId = widget.passwordData['id'] ?? widget.passwordData['documentId'];
        print('🔑 Password ID: $passwordId');

        final success = await _storageService.updatePassword(passwordId, updates);
        print('✅ Update result: $success');

        if (success && mounted) {
          Navigator.of(context).pop(true);
        } else {
          throw Exception('Update returned false');
        }
      } catch (e) {
        print('❌ Error in _savePassword: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating password: $e'),
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
    } else {
      print('❌ Form validation failed');
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    Color color = Colors.grey;
    IconData icon = Icons.security;

    if (_passwordStrength.contains('Very Strong')) {
      color = Colors.green;
      icon = Icons.verified;
    } else if (_passwordStrength.contains('Strong')) {
      color = Colors.lightGreen;
      icon = Icons.verified;
    } else if (_passwordStrength.contains('Moderate')) {
      color = Colors.orange;
      icon = Icons.warning;
    } else if (_passwordStrength.contains('Weak') || _passwordStrength.contains('Very Weak')) {
      color = Colors.red;
      icon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Strength: $_passwordStrength',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousPasswords() {
    if (_previousPasswords.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, size: 20),
                SizedBox(width: 8),
                Text(
                  'Previous Passwords',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'For security reference only:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ..._previousPasswords.asMap().entries.map((entry) {
              final index = entry.key;
              final password = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${index + 1}. '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '•' * 8, // Show dots instead of actual password
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 16),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Previous Password ${index + 1}'),
                            content: SelectableText(
                              password,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Password'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _savePassword,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Username/Email
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username/Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                onChanged: (value) => _analyzePassword(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Password Strength
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 16),

              // Website
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // Previous Passwords
              _buildPreviousPasswords(),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _savePassword,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Update Password',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
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
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}