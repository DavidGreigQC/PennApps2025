import 'menu_item.dart';

class OptimizationResult {
  final MenuItem menuItem;
  final double optimizationScore;
  final Map<String, double> criteriaScores;
  final String reasoning;

  OptimizationResult({
    required this.menuItem,
    required this.optimizationScore,
    required this.criteriaScores,
    required this.reasoning,
  });

  @override
  String toString() {
    return 'OptimizationResult(item: ${menuItem.name}, score: ${optimizationScore.toStringAsFixed(2)})';
  }
}

class ParetoFrontier {
  final List<OptimizationResult> results;
  final Map<String, List<double>> frontierPoints;

  ParetoFrontier({
    required this.results,
    required this.frontierPoints,
  });

  List<OptimizationResult> getTopResults(int count) {
    var sortedResults = List<OptimizationResult>.from(results);
    sortedResults.sort((a, b) => b.optimizationScore.compareTo(a.optimizationScore));
    return sortedResults.take(count).toList();
  }
}