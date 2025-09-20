import 'package:json_annotation/json_annotation.dart';

part 'menu_item.g.dart';

@JsonSerializable()
class MenuItem {
  final String name;
  final double price;
  final String? description;
  final double? protein;
  final double? calories;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final String? category;
  final List<String>? allergens;
  final double? sodium;
  final double? sugar;

  MenuItem({
    required this.name,
    required this.price,
    this.description,
    this.protein,
    this.calories,
    this.carbs,
    this.fat,
    this.fiber,
    this.category,
    this.allergens,
    this.sodium,
    this.sugar,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
      _$MenuItemFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemToJson(this);

  double calculateProteinPerDollar() {
    if (protein == null || price <= 0) return 0.0;
    return protein! / price;
  }

  double calculateCaloriesPerDollar() {
    if (calories == null || price <= 0) return 0.0;
    return calories! / price;
  }

  double calculateNutrientDensity() {
    if (protein == null || calories == null || calories == 0) return 0.0;
    return protein! / calories! * 100;
  }

  double calculateHealthScore() {
    double score = 0.0;
    int factors = 0;

    if (protein != null && protein! > 0) {
      score += protein! / 50.0;
      factors++;
    }

    if (fiber != null && fiber! > 0) {
      score += fiber! / 25.0;
      factors++;
    }

    if (sodium != null) {
      score += (2300 - sodium!) / 2300;
      factors++;
    }

    if (sugar != null) {
      score += (50 - sugar!) / 50;
      factors++;
    }

    return factors > 0 ? score / factors : 0.0;
  }

  MenuItem copyWith({
    String? name,
    double? price,
    String? description,
    double? protein,
    double? calories,
    double? carbs,
    double? fat,
    double? fiber,
    String? category,
    List<String>? allergens,
    double? sodium,
    double? sugar,
  }) {
    return MenuItem(
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      protein: protein ?? this.protein,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      category: category ?? this.category,
      allergens: allergens ?? this.allergens,
      sodium: sodium ?? this.sodium,
      sugar: sugar ?? this.sugar,
    );
  }

  @override
  String toString() {
    return 'MenuItem(name: $name, price: \$${price.toStringAsFixed(2)})';
  }
}