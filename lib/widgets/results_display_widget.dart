import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/optimization_result.dart';
import '../models/menu_item.dart';

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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Rankings'),
            Tab(icon: Icon(Icons.scatter_plot), text: 'Analysis'),
          ],
        ),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRankingsTab(),
              _buildAnalysisTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.results.length,
      itemBuilder: (context, index) {
        return _buildResultCard(widget.results[index], index + 1);
      },
    );
  }

  Widget _buildResultCard(OptimizationResult result, int rank) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRankColor(rank),
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          result.menuItem.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${result.menuItem.price.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: result.optimizationScore,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getRankColor(rank)),
            ),
            const SizedBox(height: 4),
            Text(
              'Score: ${(result.optimizationScore * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.menuItem.description != null) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(result.menuItem.description!),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Nutritional Information',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _buildNutritionGrid(result.menuItem),
                const SizedBox(height: 12),
                Text(
                  'Optimization Scores',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...result.criteriaScores.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatCriteriaName(entry.key)),
                        Text(
                          entry.value.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Text(
                  'Why This Item?',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(result.reasoning),
              ],
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: nutritionData.length,
      itemBuilder: (context, index) {
        MapEntry<String, String> data = nutritionData[index];
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                data.key,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Summary Statistics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton.icon(
                onPressed: _showSourcesDialog,
                icon: const Icon(Icons.source, size: 16),
                label: const Text('Show Sources'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[700],
                ),
              ),
            ],
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
                  color: Theme.of(context).primaryColor,
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

    return Column(
      children: [
        _buildStatCard('Items Analyzed', widget.results.length.toString()),
        _buildStatCard('Average Score', '${(avgScore * 100).toStringAsFixed(1)}%'),
        _buildStatCard('Average Price', '\$${avgPrice.toStringAsFixed(2)}'),
        _buildStatCard('Median Price', '\$${medianPrice.toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
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
              Text('Data Sources & Verification'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
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
                  _buildSourceCard(
                    'McDonald\'s Official Nutrition',
                    'https://www.mcdonalds.com/us/en-us/about-our-food/nutrition-calculator.html',
                    'Official McDonald\'s nutrition calculator and ingredient information.',
                    Icons.restaurant,
                    Colors.orange,
                  ),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

