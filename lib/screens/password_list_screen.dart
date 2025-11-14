import 'package:flutter/material.dart';
import 'add_password_screen.dart';
import 'edit_password_screen.dart';
import '../services/storage_service.dart';

class PasswordListScreen extends StatefulWidget {
  const PasswordListScreen({super.key});

  @override
  State<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  List<Map<String, dynamic>> _passwords = [];
  bool _isLoading = true;
  bool _hasError = false;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final passwords = await _storageService.loadPasswords();
      setState(() {
        _passwords = passwords;
        _isLoading = false;
      });

      print('✅ Loaded ${_passwords.length} passwords from cloud');
    } catch (e) {
      print('❌ Error loading passwords: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _refreshPasswords() async {
    await _loadPasswords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Passwords'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPasswords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
          ? _buildErrorState()
          : _passwords.isEmpty
          ? _buildEmptyState()
          : _buildPasswordList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddPassword(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your passwords...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load passwords',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your internet connection',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _refreshPasswords,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No Passwords Yet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add your first password to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddPassword(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordList() {
    return RefreshIndicator(
      onRefresh: _refreshPasswords,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.cloud, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${_passwords.length} ${_passwords.length == 1 ? 'Password' : 'Passwords'} (Cloud Synced)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.sync, size: 20),
                  onPressed: _refreshPasswords,
                  tooltip: 'Sync with cloud',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _passwords.length,
              itemBuilder: (context, index) {
                final password = _passwords[index];
                return _buildPasswordItem(password, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordItem(Map<String, dynamic> password, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getCategoryIcon(password['category']),
            color: Colors.blue,
          ),
        ),
        title: Text(
          password['title'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(password['username'] ?? 'No Username'),
            const SizedBox(height: 4),
            _buildStrengthIndicator(password['strength']),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility, color: Colors.grey),
          onPressed: () => _showPasswordDetails(context, password),
        ),
        onTap: () => _showPasswordDetails(context, password),
      ),
    );
  }

  Widget _buildStrengthIndicator(String strength) {
    Color color = Colors.grey;
    IconData icon = Icons.security;

    if (strength.contains('Very Strong')) {
      color = Colors.green;
      icon = Icons.verified;
    } else if (strength.contains('Strong')) {
      color = Colors.lightGreen;
      icon = Icons.verified;
    } else if (strength.contains('Moderate')) {
      color = Colors.orange;
      icon = Icons.warning;
    } else if (strength.contains('Weak') || strength.contains('Very Weak')) {
      color = Colors.red;
      icon = Icons.error;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          strength.split(' ')[0],
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
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

  void _navigateToAddPassword(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPasswordScreen()),
    ).then((success) {
      if (success == true && mounted) {
        _refreshPasswords();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _navigateToEditPassword(BuildContext context, Map<String, dynamic> password) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPasswordScreen(passwordData: password),
      ),
    ).then((success) {
      if (success == true && mounted) {
        _refreshPasswords();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showPasswordDetails(BuildContext context, Map<String, dynamic> password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getCategoryIcon(password['category']), color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                password['title'] ?? 'No Title',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Username', password['username'] ?? 'Not set'),
              _buildDetailRow('Password', '••••••••'),
              _buildDetailRow('Category', password['category'] ?? 'Other'),
              _buildDetailRow('Strength', password['strength'] ?? 'Not analyzed'),
              if (password['website'] != null && password['website'].isNotEmpty)
                _buildDetailRow('Website', password['website']),
              if (password['notes'] != null && password['notes'].isNotEmpty)
                _buildDetailRow('Notes', password['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEditPassword(context, password);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
}