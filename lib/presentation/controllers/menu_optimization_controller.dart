import 'package:flutter/foundation.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/optimization_result.dart';
import '../../domain/entities/optimization_criteria.dart';
import '../../domain/usecases/optimize_menu_usecase.dart';

/// Controller for managing menu optimization UI state
/// Separates UI concerns from business logic
class MenuOptimizationController extends ChangeNotifier {
  final OptimizeMenuUseCase _optimizeMenuUseCase;

  MenuOptimizationController(this._optimizeMenuUseCase);

  // UI State
  bool _isProcessing = false;
  String _status = '';
  List<OptimizationResult> _results = [];
  ParetoFrontier? _paretoFrontier;
  String? _error;

  // Getters for UI
  bool get isProcessing => _isProcessing;
  String get status => _status;
  List<OptimizationResult> get results => _results;
  ParetoFrontier? get paretoFrontier => _paretoFrontier;
  String? get error => _error;

  /// Process menu files and perform optimization
  Future<void> processMenuFiles(
    List<String> filePaths,
    OptimizationRequest criteria, {
    String? userId,
    String? restaurantId,
  }) async {
    try {
      _setProcessingState(true, 'Starting menu processing...');

      final params = OptimizeMenuParams(
        filePaths: filePaths,
        criteria: criteria,
        userId: userId,
        restaurantId: restaurantId,
      );

      _updateStatus('Extracting menu items...');

      final result = await _optimizeMenuUseCase.execute(params);

      if (result.isSuccess) {
        _updateStatus('Optimization complete!');
        _setResults(result.optimizationResults!);
        _error = null;
      } else {
        _setError(result.error!);
      }

    } catch (e) {
      _setError('An unexpected error occurred: $e');
    } finally {
      _setProcessingState(false, '');
    }
  }

  /// Clear all results and reset state
  void clearResults() {
    _results.clear();
    _paretoFrontier = null;
    _error = null;
    _status = '';
    notifyListeners();
  }

  // Private methods for state management
  void _setProcessingState(bool processing, String status) {
    _isProcessing = processing;
    _status = status;
    notifyListeners();
  }

  void _updateStatus(String status) {
    _status = status;
    notifyListeners();
  }

  void _setResults(List<OptimizationResult> results) {
    _results = results;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isProcessing = false;
    notifyListeners();
  }
}

/// UI state for menu optimization
enum MenuOptimizationState {
  initial,
  processing,
  success,
  error,
}

/// Extension to get current state
extension MenuOptimizationControllerExtension on MenuOptimizationController {
  MenuOptimizationState get currentState {
    if (error != null) return MenuOptimizationState.error;
    if (isProcessing) return MenuOptimizationState.processing;
    if (results.isNotEmpty) return MenuOptimizationState.success;
    return MenuOptimizationState.initial;
  }
}