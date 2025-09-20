import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/datasources/mongodb_datasource.dart';
import '../data/datasources/auth0_datasource.dart';
import '../domain/entities/menu_item.dart';

/// Data Caching Test Page
/// Test and verify that AI scraped menu data is being cached properly
class DataCachingTestPage extends StatefulWidget {
  const DataCachingTestPage({super.key});

  @override
  State<DataCachingTestPage> createState() => _DataCachingTestPageState();
}

class _DataCachingTestPageState extends State<DataCachingTestPage> {
  bool _isRunningTest = false;
  Map<String, dynamic>? _testResults;
  Map<String, dynamic>? _storageData;

  Future<void> _runDataCachingTest() async {
    setState(() {
      _isRunningTest = true;
      _testResults = null;
    });

    try {
      // Use Provider.of with listen: false to safely access providers
      final mongoDataSource = Provider.of<MongoDBDataSource>(context, listen: false);

      // Get user ID - use a test user if Auth0 isn't available
      String userId;
      try {
        final auth0DataSource = Provider.of<Auth0DataSource>(context, listen: false);
        userId = auth0DataSource.userId ?? 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      } catch (e) {
        print('⚠️ Auth0 not available, using test user ID');
        userId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Generate test data
      final testRestaurantId = 'test_restaurant_${DateTime.now().millisecondsSinceEpoch}';
      final testItems = MongoDBDataSource.generateTestMenuItems('TestCafe');

      print('🧪 Starting test with restaurant ID: $testRestaurantId');
      print('🧪 Test user ID: $userId');
      print('🧪 Test items count: ${testItems.length}');

      // Run comprehensive caching test
      final results = await mongoDataSource.testDataCaching(testRestaurantId, testItems, userId);

      setState(() {
        _testResults = results;
        _isRunningTest = false;
      });

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Data caching test ${results['overall_status']}!'),
            backgroundColor: results['overall_status'] == 'success' ? Colors.green : Colors.red,
          ),
        );
      }

    } catch (e) {
      print('❌ Test error: $e');
      setState(() {
        _isRunningTest = false;
        _testResults = {
          'overall_status': 'error',
          'error': e.toString(),
          'timestamp': DateTime.now(),
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewStoredData() async {
    try {
      final mongoDataSource = Provider.of<MongoDBDataSource>(context, listen: false);
      final data = await mongoDataSource.viewAllStoredData();

      setState(() {
        _storageData = data;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📊 Storage data loaded!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading storage data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error loading storage data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Caching Test'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 Local Storage Data Caching Tests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test if AI scraped menu data is being cached properly in local storage. MongoDB Atlas tests are skipped due to known timeout issues.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRunningTest ? null : _runDataCachingTest,
                          icon: _isRunningTest
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(_isRunningTest ? 'Running Test...' : 'Run Caching Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _viewStoredData,
                          icon: const Icon(Icons.storage),
                          label: const Text('View Stored Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Results
            if (_testResults != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _testResults!['overall_status'] == 'success'
                                ? Icons.check_circle
                                : Icons.error,
                            color: _testResults!['overall_status'] == 'success'
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Test Results: ${_testResults!['overall_status']?.toString().toUpperCase()}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _testResults!['overall_status'] == 'success'
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTestResultDetails(_testResults!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Storage Data
            if (_storageData != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Storage Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStorageDataDetails(_storageData!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultDetails(Map<String, dynamic> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Restaurant ID: ${results['restaurant_id']}'),
        Text('Items Tested: ${results['item_count']}'),
        Text('Test Started: ${results['test_started']}'),
        if (results['test_completed'] != null)
          Text('Test Completed: ${results['test_completed']}'),

        const SizedBox(height: 12),
        const Text('Individual Tests:', style: TextStyle(fontWeight: FontWeight.bold)),

        if (results['tests'] != null) ...[
          ...results['tests'].entries.map((entry) => Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Row(
              children: [
                Icon(
                  entry.value['status'] == 'completed' ? Icons.check : Icons.error,
                  size: 16,
                  color: entry.value['status'] == 'completed' ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${entry.key}: ${entry.value}'),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildStorageDataDetails(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Timestamp: ${data['timestamp']}'),

        const SizedBox(height: 8),
        const Text('MongoDB Atlas:', style: TextStyle(fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available: ${data['mongodb_data']['available']}'),
              if (data['mongodb_data']['available'] == true)
                Text('Documents: ${data['mongodb_data']['document_count']}')
              else
                Text('Reason: ${data['mongodb_data']['reason']}'),
            ],
          ),
        ),

        const SizedBox(height: 8),
        const Text('Local Storage:', style: TextStyle(fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Menu Items: ${data['local_data']['menu_keys']?.length ?? 0}'),
              Text('User Records: ${data['local_data']['user_keys']?.length ?? 0}'),
              Text('Total Keys: ${data['local_data']['total_keys']}'),
            ],
          ),
        ),
      ],
    );
  }
}