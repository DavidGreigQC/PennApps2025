import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import '../services/menu_optimization_service.dart';
import '../services/theme_service.dart';
import '../services/optimization_progress_service.dart';
import '../services/money_savings_service.dart';
import '../widgets/settings_popup.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with AutomaticKeepAliveClientMixin {
  final int _currentPage = 0; // Always 0 for home page

  double _estimatedSavings = 0.0;
  List<double> _optimizationPercents = [];
  bool _isLoadingData = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOptimizationData();
  }

  Future<void> _loadOptimizationData() async {
    try {
      final optimizationData = await OptimizationProgressService.instance.getOptimizationHistory();
      final savingsData = await MoneySavingsService.instance.getTotalSavings();

      if (mounted) {
        setState(() {
          _optimizationPercents = optimizationData;
          _estimatedSavings = savingsData;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimizationPercents = [];
          _estimatedSavings = 0.0;
          _isLoadingData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeService = Provider.of<ThemeService>(context);

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
            margin: const EdgeInsets.only(right: 16),
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
        ],
      ),
      body: Container(
        decoration: themeService.isDarkMode
            ? ThemeService.darkGradientDecoration
            : null,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
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
                          color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: themeService.isDarkMode
                          ? const Color(0xFF4A90E2).withValues(alpha: 0.2)
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
                              ? const Color(0xFF4A90E2)
                              : Colors.green[600],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: themeService.isDarkMode
                                  ? const Color(0xFF4A90E2).withValues(alpha: 0.4)
                                  : Colors.green.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.home_rounded, size: 32, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: themeService.isDarkMode
                                    ? Colors.white
                                    : Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track your savings and optimization progress.',
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
              const SizedBox(height: 20),

              // Money Saved Card
              Container(
                decoration: BoxDecoration(
                  color: themeService.isDarkMode
                      ? const Color(0xFF1A2742)
                      : Colors.white,
                  border: themeService.isDarkMode
                      ? Border.all(
                          color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: themeService.isDarkMode
                          ? const Color(0xFF4A90E2).withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: themeService.isDarkMode
                                  ? const Color(0xFF4A90E2).withValues(alpha: 0.2)
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.savings_rounded,
                              color: themeService.isDarkMode
                                  ? const Color(0xFF4A90E2)
                                  : Colors.green[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Estimated Money Saved',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: themeService.isDarkMode
                                    ? Colors.white
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.info_outline_rounded,
                            color: themeService.isDarkMode
                                ? Colors.white60
                                : Colors.grey[500],
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '\$${_estimatedSavings.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: themeService.isDarkMode
                              ? const Color(0xFF4A90E2)
                              : Colors.green[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on your optimization choices',
                        style: TextStyle(
                          color: themeService.isDarkMode
                              ? Colors.white60
                              : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: themeService.isDarkMode
                              ? const Color(0xFFFF8A50).withValues(alpha: 0.1)
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: themeService.isDarkMode
                                ? const Color(0xFFFF8A50).withValues(alpha: 0.3)
                                : Colors.orange[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: themeService.isDarkMode
                                  ? const Color(0xFFFF8A50)
                                  : Colors.orange[600],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This is an AI estimate based on typical food costs and may not reflect actual savings.',
                                style: TextStyle(
                                  color: themeService.isDarkMode
                                      ? const Color(0xFFFF8A50)
                                      : Colors.orange[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Optimization Progress Chart
              Container(
                decoration: BoxDecoration(
                  color: themeService.isDarkMode
                      ? const Color(0xFF1A2742)
                      : Colors.white,
                  border: themeService.isDarkMode
                      ? Border.all(
                          color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: themeService.isDarkMode
                          ? const Color(0xFF4A90E2).withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: themeService.isDarkMode
                                  ? const Color(0xFF9C5AE0).withValues(alpha: 0.2)
                                  : Colors.purple[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.trending_up_rounded,
                              color: themeService.isDarkMode
                                  ? const Color(0xFF9C5AE0)
                                  : Colors.purple[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Optimization Progress',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: themeService.isDarkMode
                                    ? Colors.white
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Last 10 Best Optimization Results',
                        style: TextStyle(
                          color: themeService.isDarkMode
                              ? Colors.white60
                              : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _optimizationPercents.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      size: 48,
                                      color: themeService.isDarkMode
                                          ? Colors.white30
                                          : Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No optimization data yet',
                                      style: TextStyle(
                                        color: themeService.isDarkMode
                                            ? Colors.white60
                                            : Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Complete an optimization to see your progress',
                                      style: TextStyle(
                                        color: themeService.isDarkMode
                                            ? Colors.white.withValues(alpha: 0.4)
                                            : Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : LineChart(
                          LineChartData(
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor: themeService.isDarkMode
                                    ? const Color(0xFF22334A)
                                    : const Color.fromARGB(255, 246, 246, 246),
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.all(8),
                                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                  return touchedBarSpots.map((barSpot) {
                                    return LineTooltipItem(
                                      '${barSpot.y.toStringAsFixed(1)}%',
                                      TextStyle(
                                        color: themeService.isDarkMode
                                            ? Colors.white
                                            : const Color.fromARGB(255, 124, 37, 137),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 10,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: themeService.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey[200]!,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 2,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt() + 1}',
                                      style: TextStyle(
                                        color: themeService.isDarkMode
                                            ? Colors.white60
                                            : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 10,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()}%',
                                      style: TextStyle(
                                        color: themeService.isDarkMode
                                            ? Colors.white60
                                            : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                bottom: BorderSide(
                                  color: themeService.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.grey[300]!,
                                ),
                                left: BorderSide(
                                  color: themeService.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.grey[300]!,
                                ),
                              ),
                            ),
                            minX: 0,
                            maxX: _optimizationPercents.length > 1 ? (_optimizationPercents.length - 1).toDouble() : 9,
                            minY: 0,
                            maxY: _optimizationPercents.isEmpty ? 50 : (_optimizationPercents.reduce((a, b) => a > b ? a : b) * 1.2).clamp(10, double.infinity),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _optimizationPercents.asMap().entries.map((e) {
                                  return FlSpot(e.key.toDouble(), e.value);
                                }).toList(),
                                isCurved: true,
                                gradient: themeService.isDarkMode
                                    ? const LinearGradient(
                                        colors: [Color(0xFF9C5AE0), Color(0xFF4A90E2)],
                                      )
                                    : LinearGradient(
                                        colors: [Colors.purple[400]!, Colors.purple[600]!],
                                      ),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: themeService.isDarkMode
                                          ? const Color(0xFF9C5AE0)
                                          : Colors.purple[600]!,
                                      strokeWidth: 2,
                                      strokeColor: themeService.isDarkMode
                                          ? const Color(0xFF1A2742)
                                          : Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: themeService.isDarkMode
                                      ? LinearGradient(
                                          colors: [
                                            const Color(0xFF9C5AE0).withValues(alpha: 0.2),
                                            const Color(0xFF4A90E2).withValues(alpha: 0.1),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.purple[100]!.withValues(alpha: 0.3),
                                            Colors.purple[50]!.withValues(alpha: 0.1),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Average',
                                style: TextStyle(
                                  color: themeService.isDarkMode
                                      ? Colors.white60
                                      : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${_optimizationPercents.isEmpty ? "0.0" : (_optimizationPercents.reduce((a, b) => a + b) / _optimizationPercents.length).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: themeService.isDarkMode
                                      ? const Color(0xFF9C5AE0)
                                      : Colors.purple[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Best',
                                style: TextStyle(
                                  color: themeService.isDarkMode
                                      ? Colors.white60
                                      : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${_optimizationPercents.isEmpty ? "0.0" : _optimizationPercents.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: themeService.isDarkMode
                                      ? const Color(0xFF4A90E2)
                                      : Colors.green[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Consumer<MenuOptimizationService>(
        builder: (context, service, child) {
          // Refresh optimization data when optimization completes
          if (!service.isProcessing && service.results.isNotEmpty && !_isLoadingData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadOptimizationData();
            });
          }
          return _buildBottomNavigation();
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final themeService = Provider.of<ThemeService>(context);

    return Consumer<MenuOptimizationService>(
      builder: (context, service, child) {
        List<Widget> navItems = [
          _buildNavItem(0, Icons.home_rounded, 'Home', service),
          _buildNavItem(1, Icons.upload_file_rounded, 'Upload', service),
        ];

        // Add Optimize tab if files are uploaded
        if (_shouldShowOptimizeTab(service)) {
          navItems.add(_buildNavItem(2, Icons.tune_rounded, 'Optimize', service));
        }

        // Add Results tab if optimization has started
        if (_shouldShowResultsTab(service)) {
          navItems.add(_buildNavItem(3, Icons.analytics_rounded, 'Results', service));
        }

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
                children: navItems,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, MenuOptimizationService service) {
    final themeService = Provider.of<ThemeService>(context);
    bool isSelected = _currentPage == index;
    bool canNavigate = _canNavigateToPage(index, service);

    Color backgroundColor = isSelected
        ? (index == 0 ? const Color(0xFF4A90E2) : index == 1 ? const Color(0xFF4A90E2) : index == 2 ? Colors.green[600]! : Colors.purple[600]!)
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
            if (index == 1 || index == 2 || index == 3) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
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
        return true; // Optimize is accessible from welcome to start workflow
      case 3:
        return service.results.isNotEmpty || service.isProcessing || service.status.isNotEmpty;
      default:
        return false;
    }
  }

  bool _shouldShowOptimizeTab(MenuOptimizationService service) {
    // Show optimize tab if there are uploaded files or optimization has been attempted
    return service.status.isNotEmpty || service.results.isNotEmpty || service.isProcessing;
  }

  bool _shouldShowResultsTab(MenuOptimizationService service) {
    // Show results tab if optimization has started
    return service.results.isNotEmpty || service.isProcessing || service.status.isNotEmpty;
  }
}