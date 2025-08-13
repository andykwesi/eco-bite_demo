import 'ingredient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final DateTime? createdAt;
  final String? searchQuery;

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
    this.createdAt,
    this.searchQuery,
  }) {
    // Debug logging
    print('DEBUG: Creating Recipe: $name');
    print('DEBUG: - Image URL: $imageUrl');
    print('DEBUG: - Ingredients count: ${ingredients.length}');
    print('DEBUG: - Cooking time: $cookingTimeMinutes');
    print('DEBUG: - Servings: $servings');
    print('DEBUG: - Source: $source');
    print('DEBUG: - Instructions count: ${instructions.length}');
    print('DEBUG: - Category: $category');
    print('DEBUG: - Is favorite: $isFavorite');
    print('DEBUG: - Is fast: $isFast');
  }

  bool get isFullyCookable {
    return ingredients.every((ingredient) => ingredient.isOwned);
  }

  bool get isNearlyCookable {
    final ownedCount =
        ingredients.where((ingredient) => ingredient.isOwned).length;
    return ownedCount >= ingredients.length * 0.7 && !isFullyCookable;
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    try {
      print('DEBUG: Creating Recipe from map: ${map['name']}');

      final recipe = Recipe(
        name: map['name'] ?? 'Unknown Recipe',
        imageUrl:
            map['imageUrl'] ??
            'https://via.placeholder.com/300x200?text=No+Image',
        ingredients:
            (map['ingredients'] as List<dynamic>?)
                ?.map((e) => Ingredient.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        cookingTimeMinutes: map['cookingTimeMinutes'] ?? 30,
        servings: map['servings'] ?? 4,
        source: map['source'] ?? 'Unknown Source',
        instructions: List<String>.from(map['instructions'] ?? []),
        isFavorite: map['isFavorite'] ?? false,
        category: map['category'] ?? 'Main',
        isFast: map['isFast'] ?? false,
        createdAt:
            map['createdAt'] != null
                ? (map['createdAt'] is Timestamp
                    ? (map['createdAt'] as Timestamp).toDate()
                    : DateTime.parse(map['createdAt'].toString()))
                : null,
        searchQuery: map['searchQuery'],
      );

      print('DEBUG: Recipe created successfully: ${recipe.name}');
      return recipe;
    } catch (e, stackTrace) {
      print('DEBUG: Error creating Recipe from map: $e');
      print('DEBUG: Stack trace: $stackTrace');
      print('DEBUG: Map data: $map');

      // Return a default recipe to prevent crashes
      return Recipe(
        name: map['name'] ?? 'Error Recipe',
        imageUrl: 'https://via.placeholder.com/300x200?text=Error',
        ingredients: [],
        cookingTimeMinutes: 30,
        servings: 4,
        source: 'Error',
        instructions: ['Error loading recipe'],
        category: 'Error',
        isFast: false,
      );
    }
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
      'createdAt': createdAt?.toIso8601String(),
      'searchQuery': searchQuery,
    };
  }
}
