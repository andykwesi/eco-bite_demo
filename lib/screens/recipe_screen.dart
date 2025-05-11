import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../widgets/ingredient_list_item.dart';

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample recipe data
    final recipe = Recipe(
      name: 'Garlic Butter Salmon',
      imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2',
      cookingTimeMinutes: 8,
      servings: 4,
      source: 'Recipe Tin Eats',
      isFast: true,
      ingredients: [
        Ingredient(name: 'Butter', isOwned: true),
        Ingredient(name: 'Garlic', isOwned: true),
        Ingredient(name: 'Olive Oil', isOwned: true),
        Ingredient(name: 'Lemon Juice'),
        Ingredient(name: 'Parsley'),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF97B380),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Get Cooking with muraad!',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Find, Cook, Repeat!',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Image.network(
                            recipe.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: const Icon(
                                Icons.favorite_border,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Fast',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${recipe.cookingTimeMinutes}m',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.people,
                                  size: 20,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${recipe.servings}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  recipe.source,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ingredients',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Owned',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...recipe.ingredients
                                                .where(
                                                  (ingredient) =>
                                                      ingredient.isOwned,
                                                )
                                                .map(
                                                  (ingredient) => Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 4,
                                                        ),
                                                    child: Text(
                                                      ingredient.name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Unowned',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...recipe.ingredients
                                                .where(
                                                  (ingredient) =>
                                                      !ingredient.isOwned,
                                                )
                                                .map(
                                                  (ingredient) => Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 4,
                                                        ),
                                                    child: Text(
                                                      ingredient.name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.restaurant),
                                  label: const Text('Cook!'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('Go To Recipe'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown.shade300,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
