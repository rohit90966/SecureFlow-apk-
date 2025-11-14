// services/security_service.dart
class SecurityService {

  Map<String, dynamic> auditSinglePassword(String password) {
    return _auditPassword(password);
  }
  // Get overall security statistics
  Map<String, dynamic> getSecurityStats(List<Map<String, dynamic>> passwords) {
    if (passwords.isEmpty) {
      return {
        'securityScore': 100,
        'totalPasswords': 0,
        'weakPasswords': 0,
        'reusedPasswords': 0,
      };
    }

    final weakPasswords = auditAllPasswords(passwords)
        .where((p) => p['audit']['score'] < 60)
        .length;

    final reusedCount = _findReusedPasswords(passwords).length;
    final total = passwords.length;

    // Calculate security score (0-100)
    double score = 100.0;

    // Deduct for weak passwords
    if (weakPasswords > 0) {
      score -= (weakPasswords / total) * 50;
    }

    // Deduct for reused passwords
    if (reusedCount > 0) {
      score -= (reusedCount / total) * 30;
    }

    // Deduct for no passwords
    if (total == 0) {
      score = 0;
    }

    return {
      'securityScore': score.round(),
      'totalPasswords': total,
      'weakPasswords': weakPasswords,
      'reusedPasswords': reusedCount,
    };
  }

  // Audit all passwords for security issues
  List<Map<String, dynamic>> auditAllPasswords(List<Map<String, dynamic>> passwords) {
    return passwords.map((password) {
      final audit = _auditPassword(password['password']?.toString() ?? '');
      return {
        ...password,
        'audit': audit,
      };
    }).toList();
  }

  // Audit single password
  Map<String, dynamic> _auditPassword(String password) {
    int score = 0;
    List<String> issues = [];

    // Length check
    if (password.length >= 12) {
      score += 30;
    } else if (password.length >= 8) {
      score += 20;
      issues.add('Password should be at least 12 characters');
    } else {
      issues.add('Password is too short (min 8 characters)');
    }

    // Character variety checks
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (hasUpper) score += 15;
    else issues.add('Add uppercase letters');

    if (hasLower) score += 15;
    else issues.add('Add lowercase letters');

    if (hasDigit) score += 15;
    else issues.add('Add numbers');

    if (hasSpecial) score += 15;
    else issues.add('Add special characters');

    // Common password check
    if (_isCommonPassword(password)) {
      score = max(0, score - 30);
      issues.add('This is a commonly used password');
    }

    // Sequential characters check
    if (_hasSequentialChars(password)) {
      score = max(0, score - 20);
      issues.add('Avoid sequential characters');
    }

    return {
      'score': min(100, score),
      'issues': issues,
      'strength': _getStrengthLevel(score),
    };
  }

  bool _isCommonPassword(String password) {
    final commonPasswords = [
      'password', '123456', '12345678', '1234', 'qwerty',
      'letmein', 'admin', 'welcome', 'password1'
    ];
    return commonPasswords.contains(password.toLowerCase());
  }

  bool _hasSequentialChars(String password) {
    final sequentialPatterns = [
      '123', '234', '345', '456', '567', '678', '789',
      'abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'ghi',
      'qwe', 'wer', 'ert', 'rty', 'tyu', 'yui', 'uio'
    ];

    final lowerPassword = password.toLowerCase();
    return sequentialPatterns.any((pattern) => lowerPassword.contains(pattern));
  }

  String _getStrengthLevel(int score) {
    if (score >= 80) return 'Very Strong';
    if (score >= 60) return 'Strong';
    if (score >= 40) return 'Moderate';
    if (score >= 20) return 'Weak';
    return 'Very Weak';
  }

  List<Map<String, dynamic>> _findReusedPasswords(List<Map<String, dynamic>> passwords) {
    final passwordCounts = <String, int>{};
    final reused = <Map<String, dynamic>>[];

    // Count occurrences of each password
    for (final pwd in passwords) {
      final password = pwd['password']?.toString() ?? '';
      passwordCounts[password] = (passwordCounts[password] ?? 0) + 1;
    }

    // Find reused passwords
    for (final pwd in passwords) {
      final password = pwd['password']?.toString() ?? '';
      if (passwordCounts[password]! > 1) {
        reused.add(pwd);
      }
    }

    return reused;
  }

  int max(int a, int b) => a > b ? a : b;
  int min(int a, int b) => a < b ? a : b;
}