class OptimizationCriteria {
  final String name;
  final double weight;
  final bool isMaximize;
  final String description;

  OptimizationCriteria({
    required this.name,
    required this.weight,
    required this.isMaximize,
    required this.description,
  });
}

class OptimizationRequest {
  final String? restaurantName;
  final String? restaurantLocation;
  final String? websiteUrl;
  final List<OptimizationCriteria> criteria;
  final double? maxPrice;
  final List<String>? allergenRestrictions;
  final List<String>? dietaryRestrictions;
  final String? additionalNotes;

  OptimizationRequest({
    this.restaurantName,
    this.restaurantLocation,
    this.websiteUrl,
    required this.criteria,
    this.maxPrice,
    this.allergenRestrictions,
    this.dietaryRestrictions,
    this.additionalNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'restaurantName': restaurantName,
      'restaurantLocation': restaurantLocation,
      'websiteUrl': websiteUrl,
      'criteria': criteria.map((c) => {
        'name': c.name,
        'weight': c.weight,
        'isMaximize': c.isMaximize,
        'description': c.description,
      }).toList(),
      'maxPrice': maxPrice,
      'allergenRestrictions': allergenRestrictions,
      'dietaryRestrictions': dietaryRestrictions,
      'additionalNotes': additionalNotes,
    };
  }
}