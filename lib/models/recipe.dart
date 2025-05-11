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

  Recipe({
    required this.name,
    required this.imageUrl,
    required this.ingredients,
    required this.cookingTimeMinutes,
    required this.servings,
    required this.source,
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
}
