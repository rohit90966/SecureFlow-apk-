import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'dart:math';

class AddPasswordScreen extends StatefulWidget {
  const AddPasswordScreen({super.key});

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Other';
  String _strength = 'Not analyzed';
  Color _strengthColor = Colors.grey;
  bool _isSaving = false;
  bool _showSuggestions = false;
  List<String> _suggestions = [];

  final List<String> _categories = [
    'Banking',
    'Social Media',
    'Email',
    'Work',
    'Shopping',
    'Entertainment',
    'Other'
  ];

  // Enhanced password analysis with detailed suggestions
  void _analyzePassword() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _strength = 'Not analyzed';
        _strengthColor = Colors.grey;
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    int score = 0;
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    List<String> newSuggestions = [];

    // Length scoring
    if (password.length >= 8) score += 25;
    if (password.length >= 12) score += 15;
    if (password.length >= 16) score += 10;

    // Character variety
    if (hasUpper) score += 15;
    if (hasLower) score += 15;
    if (hasDigit) score += 15;
    if (hasSpecial) score += 15;

    // Generate suggestions
    if (password.length < 8) {
      newSuggestions.add('🔒 Make password longer (at least 8 characters)');
    } else if (password.length < 12) {
      newSuggestions.add('🔒 Consider using 12+ characters for better security');
    }

    if (!hasUpper) {
      newSuggestions.add('🔤 Add uppercase letters (A-Z)');
    }

    if (!hasLower) {
      newSuggestions.add('🔡 Add lowercase letters (a-z)');
    }

    if (!hasDigit) {
      newSuggestions.add('🔢 Add numbers (0-9)');
    }

    if (!hasSpecial) {
      newSuggestions.add('⭐ Add special characters (!@#\$%^&*)');
    }

    // Check for common patterns
    if (password.contains('123')) {
      newSuggestions.add('🚫 Avoid sequential numbers (123)');
    }
    if (password.contains('abc')) {
      newSuggestions.add('🚫 Avoid sequential letters (abc)');
    }
    if (password.toLowerCase().contains('password')) {
      newSuggestions.add('🚫 Avoid common words like "password"');
    }

    setState(() {
      if (score >= 80) {
        _strength = 'Very Strong ($score/100)';
        _strengthColor = Colors.green;
      } else if (score >= 60) {
        _strength = 'Strong ($score/100)';
        _strengthColor = Colors.lightGreen;
      } else if (score >= 40) {
        _strength = 'Moderate ($score/100)';
        _strengthColor = Colors.orange;
      } else if (score >= 20) {
        _strength = 'Weak ($score/100)';
        _strengthColor = Colors.red;
      } else {
        _strength = 'Very Weak ($score/100)';
        _strengthColor = Colors.red;
      }

      _suggestions = newSuggestions;
      _showSuggestions = _suggestions.isNotEmpty && score < 80;
    });
  }

  Future<void> _savePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final passwordData = {
          'title': _titleController.text.trim(),
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'website': _websiteController.text.trim(),
          'category': _selectedCategory,
          'strength': _strength,
          'notes': _notesController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        };

        final success = await StorageService().savePassword(passwordData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${_titleController.text}" saved successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save password. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  void _generatePassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = StringBuffer();
    final rand = Random();

    for (int i = 0; i < 12; i++) {
      random.write(chars[rand.nextInt(chars.length)]);
    }

    setState(() {
      _passwordController.text = random.toString();
    });
    _analyzePassword();
  }

  void _clearForm() {
    _titleController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _websiteController.clear();
    _notesController.clear();
    setState(() {
      _selectedCategory = 'Other';
      _strength = 'Not analyzed';
      _strengthColor = Colors.grey;
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  void _toggleSuggestions() {
    setState(() {
      _showSuggestions = !_showSuggestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Password'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearForm,
            tooltip: 'Clear Form',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title Field
              _buildTextField(
                controller: _titleController,
                label: 'Title *',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Username Field
              _buildTextField(
                controller: _usernameController,
                label: 'Username/Email *',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username or email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password Field with Enhanced UI
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Icon(Icons.lock_outline, color: Colors.blue.shade600),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            onChanged: (value) => _analyzePassword(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 4) {
                                return 'Password must be at least 4 characters';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              hintText: 'Enter your password',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.autorenew, color: Colors.blue.shade600),
                          onPressed: _generatePassword,
                          tooltip: 'Generate Password',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Password Strength Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _strengthColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _strengthColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: _strengthColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password Strength',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _strength,
                            style: TextStyle(
                              color: _strengthColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_suggestions.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          _showSuggestions ? Icons.expand_less : Icons.expand_more,
                          color: Colors.blue.shade600,
                        ),
                        onPressed: _toggleSuggestions,
                        tooltip: 'Show Suggestions',
                      ),
                  ],
                ),
              ),

              // Password Suggestions Dropdown
              if (_showSuggestions && _suggestions.isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Suggestions to improve:',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._suggestions.map((suggestion) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 24),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Category Dropdown
              _buildDropdownField(),

              const SizedBox(height: 20),

              // Website Field
              _buildTextField(
                controller: _websiteController,
                label: 'Website URL',
                icon: Icons.language_outlined,
              ),

              const SizedBox(height: 20),

              // Notes Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 16),
                          child: Icon(Icons.notes_outlined, color: Colors.blue.shade600),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              hintText: 'Add any additional notes...',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_alt, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save Password',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(icon, color: Colors.blue.shade600),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  validator: validator,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    hintText: 'Enter $label',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(Icons.category_outlined, color: Colors.blue.shade600),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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