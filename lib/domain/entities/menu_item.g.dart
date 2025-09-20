// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => MenuItem(
  name: json['name'] as String,
  price: (json['price'] as num).toDouble(),
  description: json['description'] as String?,
  protein: (json['protein'] as num?)?.toDouble(),
  calories: (json['calories'] as num?)?.toDouble(),
  carbs: (json['carbs'] as num?)?.toDouble(),
  fat: (json['fat'] as num?)?.toDouble(),
  fiber: (json['fiber'] as num?)?.toDouble(),
  category: json['category'] as String?,
  allergens: (json['allergens'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  sodium: (json['sodium'] as num?)?.toDouble(),
  sugar: (json['sugar'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MenuItemToJson(MenuItem instance) => <String, dynamic>{
  'name': instance.name,
  'price': instance.price,
  'description': instance.description,
  'protein': instance.protein,
  'calories': instance.calories,
  'carbs': instance.carbs,
  'fat': instance.fat,
  'fiber': instance.fiber,
  'category': instance.category,
  'allergens': instance.allergens,
  'sodium': instance.sodium,
  'sugar': instance.sugar,
};
