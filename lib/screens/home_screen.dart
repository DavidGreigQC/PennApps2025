import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../services/menu_optimization_service.dart';
import '../models/optimization_criteria.dart';
import '../widgets/file_upload_widget.dart';
import '../widgets/optimization_form_widget.dart';
import 'welcome_screen.dart';
import '../widgets/results_display_widget.dart';
import '../services/local_stats_service.dart';
import '../services/theme_service.dart';
import '../widgets/settings_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  int _currentPage = 0;
  List<String> _uploadedFilesAndUrls = [];
  OptimizationRequest? _optimizationRequest;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.isDarkMode ? const Color(0xFF0B1426) : Colors.grey[50],
      appBar: AppBar(
        title: Center(
          child: Image.asset(
            'assets/images/menumaxlogo.png',
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 100,
        flexibleSpace: Container(
          decoration: themeService.isDarkMode
              ? const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1A2742),
                      Color(0xFF16213E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                )
              : BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded, color: Colors.white),
              onPressed: () => SettingsPopup.show(context),
              tooltip: 'Settings',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _resetApp,
              tooltip: 'Reset App',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: themeService.isDarkMode
            ? ThemeService.darkGradientDecoration
            : null,
        child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _currentPage == 0
            ? Container(key: const ValueKey(0), child: _buildUploadPage(themeService))
            : _currentPage == 1
                ? Container(key: const ValueKey(1), child: _buildOptimizationPage(themeService))
                : Container(key: const ValueKey(2), child: _buildResultsPage(themeService)),
        ),
      ),
          bottomNavigationBar: _buildBottomNavigation(),
        );
      },
    );
  }


  Widget _buildUploadPage(ThemeService themeService) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: themeService.isDarkMode
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF1A2742),
                            Color(0xFF22334A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [Colors.blue[50]!, Colors.blue[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: themeService.isDarkMode
                      ? Border.all(
                          color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: themeService.isDarkMode
                          ? const Color(0xFF4A90E2).withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: themeService.isDarkMode
                              ? const Color(0xFF4A90E2)
                              : Colors.blue[600],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: themeService.isDarkMode
                                  ? const Color(0xFF4A90E2).withValues(alpha: 0.4)
                                  : Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.restaurant_menu_rounded, size: 32, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload Menu Files',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: themeService.isDarkMode
                                    ? Colors.white
                                    : Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload PDFs, images, or enter a menu URL to get started.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: themeService.isDarkMode
                                    ? Colors.white70
                                    : Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FileUploadWidget(
                onFilesSelected: (files) async {
                  final previousCount = _uploadedFilesAndUrls.length;
                  setState(() {
                    _uploadedFilesAndUrls = files;
                  });

                  // Increment menu count if new files were added
                  if (files.length > previousCount) {
                    final newMenus = files.length - previousCount;
                    await LocalStatsService.instance.incrementMenuCount(newMenus);
                  }
                },
              ),
            ],
          ),
        ),
        if (_uploadedFilesAndUrls.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: themeService.isDarkMode
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF4A90E2),
                          Color(0xFF357ABD),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: themeService.isDarkMode
                        ? const Color(0xFF4A90E2).withValues(alpha: 0.4)
                        : Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _goToOptimizationPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Continue to Optimization',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptimizationPage(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: themeService.isDarkMode
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF1A2742),
                        Color(0xFF22334A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [Colors.green[50]!, Colors.green[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: themeService.isDarkMode
                  ? Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: themeService.isDarkMode
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeService.isDarkMode
                          ? Colors.green[600]
                          : Colors.green[600],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: themeService.isDarkMode
                              ? Colors.green.withValues(alpha: 0.4)
                              : Colors.green.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.tune_rounded, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Optimization Criteria',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: themeService.isDarkMode
                                ? Colors.white
                                : Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set your preferences for finding the optimal menu items.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: themeService.isDarkMode
                                ? Colors.white70
                                : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
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
            Container(
              decoration: BoxDecoration(
                gradient: themeService.isDarkMode
                    ? const LinearGradient(
                        colors: [
                          Colors.green,
                          Color(0xFF27AE60),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.green[600]!, Colors.green[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: themeService.isDarkMode
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _startOptimization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Start Optimization',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsPage(ThemeService themeService) {
    return Consumer<MenuOptimizationService>(
      builder: (context, service, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: themeService.isDarkMode
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF1A2742),
                            Color(0xFF22334A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [Colors.purple[50]!, Colors.purple[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: themeService.isDarkMode
                      ? Border.all(
                          color: const Color(0xFF9C5AE0).withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: themeService.isDarkMode
                          ? const Color(0xFF9C5AE0).withValues(alpha: 0.2)
                          : Colors.purple.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: themeService.isDarkMode
                              ? const Color(0xFF9C5AE0)
                              : Colors.purple[600],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: themeService.isDarkMode
                                  ? const Color(0xFF9C5AE0).withValues(alpha: 0.4)
                                  : Colors.purple.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.analytics_rounded, size: 32, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Optimization Results',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: themeService.isDarkMode
                                    ? Colors.white
                                    : Colors.purple[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (service.isProcessing)
                              Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[600]!),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      service.status,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: themeService.isDarkMode
                                            ? Colors.white70
                                            : Colors.purple[700],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else if (service.results.isNotEmpty)
                              Text(
                                'Found ${service.results.length} optimal recommendations.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: themeService.isDarkMode
                                      ? Colors.white70
                                      : Colors.purple[700],
                                ),
                              )
                            else
                              Text(
                                'Your optimization results will appear here.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: themeService.isDarkMode
                                      ? Colors.white70
                                      : Colors.purple[700],
                                ),
                              ),
                          ],
                        ),
                      ),
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
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Consumer<MenuOptimizationService>(
          builder: (context, service, child) {
            return Container(
              decoration: BoxDecoration(
                color: themeService.isDarkMode
                    ? const Color(0xFF1A2742)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: themeService.isDarkMode
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Container(
                  height: 65,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _buildNavItems(service, themeService),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildNavItems(MenuOptimizationService service, ThemeService themeService) {
    List<Widget> navItems = [
      _buildNavItem(0, Icons.home_rounded, 'Home', service, themeService),
      _buildNavItem(1, Icons.upload_file_rounded, 'Upload', service, themeService),
    ];

    // Add Optimize tab if files are uploaded
    if (_uploadedFilesAndUrls.isNotEmpty) {
      navItems.add(_buildNavItem(2, Icons.tune_rounded, 'Optimize', service, themeService));
    }

    // Add Results tab if optimization has started
    if (service.results.isNotEmpty || service.isProcessing || service.status.isNotEmpty) {
      navItems.add(_buildNavItem(3, Icons.analytics_rounded, 'Results', service, themeService));
    }

    return navItems;
  }

  Widget _buildNavItem(int index, IconData icon, String label, MenuOptimizationService service, ThemeService themeService) {
    bool isSelected = (index == 0) ? false : _currentPage == (index - 1);
    bool canNavigate = _canNavigateToPage(index, service);

    Color backgroundColor = isSelected
        ? (index == 1 ? Colors.blue[600]! : index == 2 ? Colors.green[600]! : Colors.purple[600]!)
        : Colors.transparent;
    Color iconColor = isSelected
        ? Colors.white
        : canNavigate
            ? (themeService.isDarkMode ? Colors.white70 : Colors.grey[600]!)
            : (themeService.isDarkMode ? Colors.white30 : Colors.grey[400]!);
    Color textColor = isSelected
        ? Colors.white
        : canNavigate
            ? (themeService.isDarkMode ? Colors.white70 : Colors.grey[700]!)
            : (themeService.isDarkMode ? Colors.white30 : Colors.grey[400]!);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canNavigate ? () {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            } else {
              setState(() {
                _currentPage = index - 1;
              });
            }
          } : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canNavigateToPage(int page, MenuOptimizationService service) {
    switch (page) {
      case 0:
        return true; // Home/Welcome is always accessible
      case 1:
        return true; // Upload is always accessible
      case 2:
        return _uploadedFilesAndUrls.isNotEmpty; // Optimize needs uploaded files
      case 3:
        return _optimizationRequest != null &&
            (service.results.isNotEmpty || service.isProcessing || service.status.isNotEmpty);
      default:
        return false;
    }
  }

  void _goToOptimizationPage() {
    setState(() {
      _currentPage = 1; // Optimize page is now index 1 (was 1, now 2-1)
    });
  }

  Future<void> _startOptimization() async {
    if (_optimizationRequest == null || _uploadedFilesAndUrls.isEmpty) return;

    setState(() {
      _currentPage = 2; // Results page is now index 2 (was 2, now 3-1)
    });

    // Increment optimization count
    await LocalStatsService.instance.incrementOptimizationCount();

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
