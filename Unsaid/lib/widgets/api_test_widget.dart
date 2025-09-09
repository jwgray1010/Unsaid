import 'package:flutter/material.dart';
import '../services/keyboard_data_service.dart';

class APITestWidget extends StatefulWidget {
  const APITestWidget({super.key});

  @override
  State<APITestWidget> createState() => _APITestWidgetState();
}

class _APITestWidgetState extends State<APITestWidget> {
  final KeyboardDataService _keyboardDataService = KeyboardDataService();
  bool _isLoading = false;
  String _status = 'Ready to test';
  Map<String, dynamic>? _apiData;
  Map<String, dynamic>? _userData;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.api, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'API Connection Test',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                border: Border.all(color: _getStatusColor()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(), color: _getStatusColor()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _status,
                      style: TextStyle(color: _getStatusColor()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testConnection,
                  icon: const Icon(Icons.wifi_find),
                  label: const Text('Test Connection'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getUserData,
                  icon: const Icon(Icons.person),
                  label: const Text('Get User Data'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getAPIData,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Get API Data'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _performFullSync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Full Sync'),
                ),
              ],
            ),

            // User Data Display
            if (_userData != null) ...[
              const SizedBox(height: 16),
              _buildDataSection('User Data', _userData!),
            ],

            // API Data Display
            if (_apiData != null) ...[
              const SizedBox(height: 16),
              _buildDataSection('API Data', _apiData!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(String title, Map<String, dynamic> data) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _formatData(data),
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  String _formatData(Map<String, dynamic> data) {
    String result = '';
    data.forEach((key, value) {
      if (value is Map) {
        result += '$key: {\n';
        value.forEach((k, v) {
          result += '  $k: $v\n';
        });
        result += '}\n';
      } else if (value is List) {
        result += '$key: [${value.length} items]\n';
        if (value.isNotEmpty) {
          result += '  First item: ${value.first}\n';
        }
      } else {
        result += '$key: $value\n';
      }
    });
    return result;
  }

  Color _getStatusColor() {
    if (_status.contains('✅') || _status.contains('Success')) {
      return Colors.green;
    } else if (_status.contains('❌') || _status.contains('Failed')) {
      return Colors.red;
    } else if (_status.contains('⚠️') || _status.contains('Warning')) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    if (_status.contains('✅') || _status.contains('Success')) {
      return Icons.check_circle;
    } else if (_status.contains('❌') || _status.contains('Failed')) {
      return Icons.error;
    } else if (_status.contains('⚠️') || _status.contains('Warning')) {
      return Icons.warning;
    } else {
      return Icons.info;
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing API connection...';
    });

    try {
      final success = await _keyboardDataService.testAPIConnection();
      setState(() {
        _status = success
            ? '✅ API connection test successful'
            : '⚠️ No API data found - use keyboard first';
      });
    } catch (e) {
      setState(() {
        _status = '❌ API connection test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserData() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting user data...';
    });

    try {
      final userData = await _keyboardDataService.getUserData();
      setState(() {
        _userData = userData;
        _status = userData != null
            ? '✅ User data retrieved successfully'
            : '⚠️ No user data found';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to get user data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getAPIData() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting API data...';
    });

    try {
      final apiData = await _keyboardDataService.getAPIResponses();
      setState(() {
        _apiData = apiData;
        _status = apiData != null
            ? '✅ API data retrieved successfully'
            : '⚠️ No API data found - use keyboard to generate data';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to get API data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performFullSync() async {
    setState(() {
      _isLoading = true;
      _status = 'Performing full data sync...';
    });

    try {
      final success = await _keyboardDataService.performDataSync();
      setState(() {
        _status = success
            ? '✅ Full data sync completed successfully'
            : '❌ Full data sync failed';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Full data sync failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
