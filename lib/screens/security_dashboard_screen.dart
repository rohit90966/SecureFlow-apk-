import 'package:flutter/material.dart';
import '../services/security_service.dart';

class SecurityDashboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> passwords;

  const SecurityDashboardScreen({super.key, required this.passwords});

  @override
  Widget build(BuildContext context) {
    final securityService = SecurityService();
    final stats = securityService.getSecurityStats(passwords);
    final weakPasswords = securityService.auditAllPasswords(passwords)
        .where((p) => p['audit']['score'] < 60)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSecurityScoreCard(stats),
          const SizedBox(height: 20),
          _buildIssueCard(
            'Weak Passwords',
            weakPasswords.length,
            Icons.warning,
            Colors.orange,
            weakPasswords,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityScoreCard(Map<String, dynamic> stats) {
    final score = stats['securityScore'] ?? 0;
    Color scoreColor = Colors.green;
    String message = 'Excellent security!';

    if (score < 40) {
      scoreColor = Colors.red;
      message = 'Critical security issues!';
    } else if (score < 70) {
      scoreColor = Colors.orange;
      message = 'Needs improvement';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Overall Security Score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[300],
                    color: scoreColor,
                  ),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(String title, int count, IconData icon, Color color, List<Map<String, dynamic>> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: Text(count.toString()),
                  backgroundColor: color.withOpacity(0.2),
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...items.take(3).map((item) => ListTile(
                leading: const Icon(Icons.lock, size: 20),
                title: Text(item['title']),
                subtitle: Text('Score: ${item['audit']['score']}/100'),
                dense: true,
              )),
            ],
          ],
        ),
      ),
    );
  }
}