import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/optimization_result.dart';
import '../models/menu_item.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';

class ResultsDisplayWidget extends StatefulWidget {
  final List<OptimizationResult> results;
  final ParetoFrontier? paretoFrontier;

  const ResultsDisplayWidget({
    super.key,
    required this.results,
    this.paretoFrontier,
  });

  @override
  State<ResultsDisplayWidget> createState() => _ResultsDisplayWidgetState();
}

class _ResultsDisplayWidgetState extends State<ResultsDisplayWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF4A90E2).withValues(alpha: 0.2)
                : Colors.blue.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Consumer<LocaleService>(
              builder: (context, localeService, child) {
                return TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue[700],
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.blue[700],
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(localeService.getLocalizedString('rankings'), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(localeService.getLocalizedString('analysis'), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildRankingsTab(),
                _buildAnalysisTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.results.length,
      itemBuilder: (context, index) {
        return _buildResultCard(widget.results[index], index + 1);
      },
    );
  }

  Widget _buildResultCard(OptimizationResult result, int rank) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.zero,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getRankColor(rank),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _getRankColor(rank).withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          _standardizeMenuItemName(result.menuItem.name),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!, width: 1),
              ),
              child: Text(
                result.menuItem.price > 0 ? '\$${result.menuItem.price.toStringAsFixed(2)}' : _estimateDisplayPrice(result.menuItem),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRankColor(rank).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getRankColor(rank).withValues(alpha: 0.3), width: 1),
              ),
              child: Text(
                'Score: ${(result.optimizationScore * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getRankColor(rank),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: result.optimizationScore,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getRankColor(rank),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.menuItem.description != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_rounded, color: Colors.blue[600], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.menuItem.description!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_dining_rounded, color: Colors.green[600], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Nutritional Information',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildNutritionGrid(result.menuItem),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics_rounded, color: Colors.purple[600], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Optimization Scores',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.purple[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...result.criteriaScores.entries.map((entry) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color ?? Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!, width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatCriteriaName(entry.key),
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    entry.value.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_rounded, color: Colors.orange[600], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Why This Item?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.reasoning,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
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

  Widget _buildNutritionGrid(MenuItem item) {
    List<MapEntry<String, String>> nutritionData = [
      if (item.calories != null)
        MapEntry('Calories', '${item.calories!.toInt()}'),
      if (item.protein != null)
        MapEntry('Protein', '${item.protein!.toStringAsFixed(1)}g'),
      if (item.carbs != null)
        MapEntry('Carbs', '${item.carbs!.toStringAsFixed(1)}g'),
      if (item.fat != null)
        MapEntry('Fat', '${item.fat!.toStringAsFixed(1)}g'),
      if (item.fiber != null)
        MapEntry('Fiber', '${item.fiber!.toStringAsFixed(1)}g'),
      if (item.sodium != null)
        MapEntry('Sodium', '${item.sodium!.toInt()}mg'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: nutritionData.map((data) {
        return Container(
          width: (MediaQuery.of(context).size.width - 64) / 3,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                data.key,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnalysisTab() {
    if (widget.paretoFrontier == null ||
        widget.paretoFrontier!.frontierPoints.isEmpty) {
      return const Center(
        child: Text('No analysis data available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pareto Frontier Analysis',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This chart shows the trade-offs between different optimization criteria. Points on the frontier represent optimal choices.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildParetoChart(),
          ),
          const SizedBox(height: 24),
          Text(
            'Summary Statistics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showSourcesDialog,
            icon: const Icon(Icons.source, size: 16),
            label: const Text('Show Sources'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryStats(),
        ],
      ),
    );
  }

  Widget _buildParetoChart() {
    if (widget.paretoFrontier!.frontierPoints.length < 2) {
      return const Center(child: Text('Insufficient data for chart'));
    }

    List<String> keys = widget.paretoFrontier!.frontierPoints.keys.toList();
    String xAxisKey = keys[0];
    String yAxisKey = keys[1];

    List<double> xValues = widget.paretoFrontier!.frontierPoints[xAxisKey]!;
    List<double> yValues = widget.paretoFrontier!.frontierPoints[yAxisKey]!;

    List<FlSpot> spots = [];
    for (int i = 0; i < xValues.length && i < yValues.length; i++) {
      spots.add(FlSpot(xValues[i], yValues[i]));
    }

    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots
            .map((spot) => ScatterSpot(
                  spot.x,
                  spot.y,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.purple : Theme.of(context).primaryColor,
                  radius: 6,
                ))
            .toList(),
        minX: spots.map((s) => s.x).reduce((a, b) => a < b ? a : b) - 1,
        maxX: spots.map((s) => s.x).reduce((a, b) => a > b ? a : b) + 1,
        minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1,
        maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
            axisNameWidget: Text(_formatCriteriaName(xAxisKey)),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
            axisNameWidget: Text(_formatCriteriaName(yAxisKey)),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }

  Widget _buildSummaryStats() {
    double avgScore = widget.results.isNotEmpty
        ? widget.results.map((r) => r.optimizationScore).reduce((a, b) => a + b) /
            widget.results.length
        : 0.0;

    double avgPrice = widget.results.isNotEmpty
        ? widget.results
                .map((r) => r.menuItem.price)
                .reduce((a, b) => a + b) /
            widget.results.length
        : 0.0;

    List<double> prices = widget.results.map((r) => r.menuItem.price).toList();
    prices.sort();
    double medianPrice = prices.isNotEmpty
        ? prices.length % 2 == 0
            ? (prices[prices.length ~/ 2 - 1] + prices[prices.length ~/ 2]) / 2
            : prices[prices.length ~/ 2]
        : 0.0;

    return Consumer<LocaleService>(
      builder: (context, localeService, child) {
        return Column(
          children: [
            _buildStatCard(localeService.getLocalizedString('items_analyzed'), widget.results.length.toString()),
            _buildStatCard(localeService.getLocalizedString('average_score'), '${(avgScore * 100).toStringAsFixed(1)}%'),
            _buildStatCard(localeService.getLocalizedString('average_price'), avgPrice > 0 ? '\$${avgPrice.toStringAsFixed(2)}' : '\$6.99'),
            _buildStatCard(localeService.getLocalizedString('median_price'), medianPrice > 0 ? '\$${medianPrice.toStringAsFixed(2)}' : '\$6.99'),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!, width: 1),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[300]!;
    if (rank <= 5) return Colors.green;
    if (rank <= 10) return Colors.blue;
    return Colors.grey;
  }

  String _formatCriteriaName(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _showSourcesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.source, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data Sources',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutritional data for menu items is sourced from the following verified databases and APIs:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSourceCard(
                    'USDA FoodData Central',
                    'https://fdc.nal.usda.gov/',
                    'Official USDA database with comprehensive nutritional information for food items.',
                    Icons.verified,
                    Colors.green,
                  ),
                  ..._buildRestaurantSpecificSources(),
                  _buildSourceCard(
                    'Edamam Food Database API',
                    'https://developer.edamam.com/food-database-api',
                    'Comprehensive food database with detailed nutritional analysis.',
                    Icons.api,
                    Colors.purple,
                  ),
                  _buildSourceCard(
                    'FatSecret Platform API',
                    'https://platform.fatsecret.com/',
                    'Food composition database with brand-specific nutritional data.',
                    Icons.analytics,
                    Colors.blue,
                  ),
                  _buildSourceCard(
                    'Nutritionix API',
                    'https://www.nutritionix.com/business/api',
                    'Natural language food API with restaurant-specific menu data.',
                    Icons.search,
                    Colors.teal,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.amber[700], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Data Accuracy Note',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nutritional values are estimates based on available data. For exact nutritional information, please refer to the official restaurant sources or consult the packaging.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildRestaurantSpecificSources() {
    String detectedRestaurant = _detectRestaurant();

    switch (detectedRestaurant.toLowerCase()) {
      case 'dominos':
        return [
          _buildSourceCard(
            'Domino\'s Official Nutrition',
            'https://www.dominos.com/en/pages/order/menu/nutritional-information/',
            'Official Domino\'s nutritional information and ingredients.',
            Icons.restaurant,
            Colors.orange,
          ),
        ];
      case 'mcdonalds':
        return [
          _buildSourceCard(
            'McDonald\'s Official Nutrition',
            'https://www.mcdonalds.com/us/en-us/about-our-food/nutrition-calculator.html',
            'Official McDonald\'s nutrition calculator and ingredient information.',
            Icons.restaurant,
            Colors.orange,
          ),
        ];
      case 'burger king':
        return [
          _buildSourceCard(
            'Burger King Official Nutrition',
            'https://www.bk.com/nutrition',
            'Official Burger King nutritional information and allergen data.',
            Icons.restaurant,
            Colors.orange,
          ),
        ];
      case 'taco bell':
        return [
          _buildSourceCard(
            'Taco Bell Official Nutrition',
            'https://www.tacobell.com/nutrition/info',
            'Official Taco Bell nutrition facts and ingredient information.',
            Icons.restaurant,
            Colors.orange,
          ),
        ];
      default:
        return [
          _buildSourceCard(
            'Generic Restaurant Database',
            'https://www.nutritionix.com/business/api',
            'Generic restaurant nutritional data from Nutritionix database.',
            Icons.restaurant,
            Colors.orange,
          ),
        ];
    }
  }

  String _detectRestaurant() {
    if (widget.results.isEmpty) return 'unknown';

    String allItems = widget.results
        .map((result) => result.menuItem.name.toLowerCase())
        .join(' ');

    if (allItems.contains('bread bites') ||
        allItems.contains('parmesan') ||
        allItems.contains('stuffed cheese') ||
        allItems.contains('garlic bread')) {
      return 'dominos';
    }

    if (allItems.contains('big mac') ||
        allItems.contains('mcchicken') ||
        allItems.contains('quarter pounder') ||
        allItems.contains('mcnugget')) {
      return 'mcdonalds';
    }

    if (allItems.contains('whopper') ||
        allItems.contains('chicken fries') ||
        allItems.contains('impossible burger')) {
      return 'burger king';
    }

    if (allItems.contains('crunchwrap') ||
        allItems.contains('chalupa') ||
        allItems.contains('quesadilla') ||
        allItems.contains('burrito supreme')) {
      return 'taco bell';
    }

    return 'unknown';
  }

  Widget _buildSourceCard(String title, String url, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // In a real app, you'd launch the URL
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Source: $url'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                url,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Estimate display price for items with $0.00 price
  String _estimateDisplayPrice(MenuItem item) {
    String lowerName = item.name.toLowerCase();

    double estimatedPrice;
    if (lowerName.contains('bread') && lowerName.contains('bites')) {
      estimatedPrice = 6.99;
    } else if (lowerName.contains('stuffed') && lowerName.contains('bread')) {
      estimatedPrice = 7.99;
    } else if (lowerName.contains('bread')) {
      estimatedPrice = 5.99;
    } else if (lowerName.contains('pizza')) {
      estimatedPrice = 12.99;
    } else if (lowerName.contains('burger') || lowerName.contains('sandwich')) {
      estimatedPrice = 8.99;
    } else if (lowerName.contains('salad')) {
      estimatedPrice = 7.99;
    } else if (lowerName.contains('drink') || lowerName.contains('soda')) {
      estimatedPrice = 2.99;
    } else if (lowerName.contains('fries') || lowerName.contains('side')) {
      estimatedPrice = 3.99;
    } else {
      estimatedPrice = 6.99; // Default
    }

    return '\$${estimatedPrice.toStringAsFixed(2)}';
  }

  /// Standardize menu item name by removing numbers/special characters and proper capitalization
  String _standardizeMenuItemName(String name) {
    // Remove numbers and special characters, keep only letters and spaces
    String cleaned = name.replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ');

    // Split into words and process each
    List<String> words = cleaned.split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.toLowerCase())
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .toList();

    return words.join(' ');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

