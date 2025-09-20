import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../services/menu_optimization_service.dart';
import '../models/optimization_criteria.dart';
import '../widgets/file_upload_widget.dart';
import '../widgets/optimization_form_widget.dart';
import '../widgets/results_display_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPage = 0;
  List<String> _uploadedFilesAndUrls = [];
  OptimizationRequest? _optimizationRequest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Menu Optimizer'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Navigator.pushNamed(context, '/test-caching'),
            tooltip: 'Test Data Caching',
          ),
          if (_currentPage > 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetApp,
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getCurrentPage(),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentPage) {
      case 0:
        return Container(key: const ValueKey('upload'), child: _buildUploadPage());
      case 1:
        return Container(key: const ValueKey('optimize'), child: _buildOptimizationPage());
      case 2:
        return Container(key: const ValueKey('results'), child: _buildResultsPage());
      default:
        return Container(key: const ValueKey('upload'), child: _buildUploadPage());
    }
  }

  Widget _buildUploadPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.restaurant_menu, size: 48, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 16),
                  Text('Upload Menu Files', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Upload PDFs, images, or enter a menu URL to get started.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FileUploadWidget(
            onFilesSelected: (files) {
              setState(() {
                _uploadedFilesAndUrls = files;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_uploadedFilesAndUrls.isNotEmpty)
            ElevatedButton(
              onPressed: _goToOptimizationPage,
              child: const Text('Continue to Optimization'),
            ),
        ],
      ),
    );
  }

  Widget _buildOptimizationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tune, size: 48, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 16),
                  Text('Optimization Criteria', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Set your preferences for finding the optimal menu items.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OptimizationFormWidget(
            onOptimizationRequest: (request) {
              setState(() {
                _optimizationRequest = request;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_optimizationRequest != null)
            ElevatedButton(
              onPressed: _startOptimization,
              child: const Text('Start Optimization'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsPage() {
    return Consumer<MenuOptimizationService>(
      builder: (context, service, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.analytics, size: 48, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 16),
                      Text('Optimization Results', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      if (service.isProcessing)
                        Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(service.status),
                          ],
                        )
                      else if (service.results.isNotEmpty)
                        Text('Found ${service.results.length} optimal recommendations.',
                            style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!service.isProcessing && service.results.isNotEmpty)
                ResultsDisplayWidget(results: service.results, paretoFrontier: service.paretoFrontier),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Consumer<MenuOptimizationService>(
      builder: (context, service, child) {
        return BottomNavigationBar(
          currentIndex: _currentPage,
          onTap: (index) {
            if (_canNavigateToPage(index, service)) {
              setState(() {
                _currentPage = index;
              });
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Upload'),
            BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Optimize'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Results'),
          ],
        );
      },
    );
  }

  bool _canNavigateToPage(int page, MenuOptimizationService service) {
    switch (page) {
      case 0:
        return true;
      case 1:
        return _uploadedFilesAndUrls.isNotEmpty;
      case 2:
        return _optimizationRequest != null &&
            (service.results.isNotEmpty || service.isProcessing || service.status.isNotEmpty);
      default:
        return false;
    }
  }

  void _goToOptimizationPage() {
    setState(() {
      _currentPage = 1;
    });
  }

  Future<void> _startOptimization() async {
    if (_optimizationRequest == null || _uploadedFilesAndUrls.isEmpty) return;

    setState(() {
      _currentPage = 2;
    });

    final service = Provider.of<MenuOptimizationService>(context, listen: false);

    for (String input in _uploadedFilesAndUrls) {
      if (input.startsWith('http')) {
        try {
          String localPath = await _downloadFileFromUrl(input);
          await service.processMenuFiles([localPath], _optimizationRequest!);
        } catch (e) {
          print('Failed to download URL $input: $e');
        }
      } else {
        await service.processMenuFiles([input], _optimizationRequest!);
      }
    }
  }

  Future<String> _downloadFileFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${url.split('/').last}';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } else {
      throw Exception('Failed to download file: $url');
    }
  }

  void _resetApp() {
    setState(() {
      _uploadedFilesAndUrls.clear();
      _optimizationRequest = null;
      _currentPage = 0;
    });

    final service = Provider.of<MenuOptimizationService>(context, listen: false);
    service.clearResults();
  }
}
