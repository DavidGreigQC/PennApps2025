import '../../domain/entities/menu_item.dart';
import '../../domain/entities/optimization_result.dart';
import '../../domain/entities/optimization_criteria.dart';

/// Data source interface for optimization operations
abstract class OptimizationDataSource {
  /// Perform optimization on menu items based on criteria
  Future<List<OptimizationResult>> optimize(
    List<MenuItem> items,
    OptimizationRequest criteria,
  );

  /// Generate Pareto frontier analysis
  Future<ParetoFrontier?> generateParetoFrontier(
    List<MenuItem> items,
    OptimizationRequest criteria,
  );
}

/// Implementation that wraps existing optimization engine
class OptimizationDataSourceImpl implements OptimizationDataSource {
  // We'll inject the existing optimization engine here
  final dynamic _optimizationEngine; // Replace with actual service type

  OptimizationDataSourceImpl(this._optimizationEngine);

  @override
  Future<List<OptimizationResult>> optimize(
    List<MenuItem> items,
    OptimizationRequest criteria,
  ) async {
    // Delegate to existing optimization engine
    return await _optimizationEngine.optimize(items, criteria);
  }

  @override
  Future<ParetoFrontier?> generateParetoFrontier(
    List<MenuItem> items,
    OptimizationRequest criteria,
  ) async {
    // Delegate to existing optimization engine
    return await _optimizationEngine.generateParetoFrontier(items, criteria);
  }
}