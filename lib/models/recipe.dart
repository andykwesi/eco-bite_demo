import 'ingredient.dart';

class Recipe {
  final String name;
  final String imageUrl;
  final List<Ingredient> ingredients;
  final int cookingTimeMinutes;
  final int servings;
  final String source;
  final bool isFavorite;
  final String category;
  final bool isFast;
  final List<String> instructions;

  Recipe({
    required this.name,
    required this.imageUrl,
    required this.ingredients,
    required this.cookingTimeMinutes,
    required this.servings,
    required this.source,
    required this.instructions,
    this.isFavorite = false,
    this.category = 'Main',
    this.isFast = false,
  });

  bool get isFullyCookable {
    return ingredients.every((ingredient) => ingredient.isOwned);
  }

  bool get isNearlyCookable {
    final ownedCount =
        ingredients.where((ingredient) => ingredient.isOwned).length;
    return ownedCount >= ingredients.length * 0.7 && !isFullyCookable;
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      name: map['name'],
      imageUrl: map['imageUrl'],
      ingredients:
          (map['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      cookingTimeMinutes: map['cookingTimeMinutes'],
      servings: map['servings'],
      source: map['source'],
      instructions: List<String>.from(map['instructions'] ?? []),
      isFavorite: map['isFavorite'] ?? false,
      category: map['category'] ?? 'Main',
      isFast: map['isFast'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
      'cookingTimeMinutes': cookingTimeMinutes,
      'servings': servings,
      'source': source,
      'instructions': instructions,
      'isFavorite': isFavorite,
      'category': category,
      'isFast': isFast,
    };
  }
}
