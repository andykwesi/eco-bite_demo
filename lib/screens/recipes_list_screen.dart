import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';

class RecipesListScreen extends StatefulWidget {
  const RecipesListScreen({super.key});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Sample recipes data
  final List<Recipe> _recipes = [
    Recipe(
      name: 'Crispy Parmesan Crusted Chicken Breast',
      imageUrl: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b',
      cookingTimeMinutes: 30,
      servings: 4,
      source: 'Recipe Tin Eats',
      ingredients: [
        Ingredient(name: 'Chicken Breast', isOwned: true),
        Ingredient(name: 'Parmesan', isOwned: true),
        Ingredient(name: 'Breadcrumbs', isOwned: true),
        Ingredient(name: 'Garlic', isOwned: true),
      ],
    ),
    Recipe(
      name: 'Crispy Skin Salmon',
      imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2',
      cookingTimeMinutes: 15,
      servings: 2,
      source: 'Recipe Tin Eats',
      ingredients: [
        Ingredient(name: 'Salmon', isOwned: true),
        Ingredient(name: 'Olive Oil', isOwned: true),
        Ingredient(name: 'Salt', isOwned: true),
        Ingredient(name: 'Pepper', isOwned: true),
      ],
    ),
    Recipe(
      name: 'Crostini',
      imageUrl: 'https://images.unsplash.com/photo-1573739733027-0958a92da56f',
      cookingTimeMinutes: 20,
      servings: 6,
      source: 'Food Network',
      ingredients: [
        Ingredient(name: 'Baguette', isOwned: false),
        Ingredient(name: 'Olive Oil', isOwned: true),
        Ingredient(name: 'Garlic', isOwned: true),
      ],
    ),
    Recipe(
      name: 'Garlic Sautéed Spinach',
      imageUrl: 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39',
      cookingTimeMinutes: 10,
      servings: 4,
      source: 'Barefoot Contessa',
      ingredients: [
        Ingredient(name: 'Spinach', isOwned: false),
        Ingredient(name: 'Garlic', isOwned: true),
        Ingredient(name: 'Olive Oil', isOwned: true),
        Ingredient(name: 'Butter', isOwned: true),
        Ingredient(name: 'Salt', isOwned: true),
      ],
    ),
    Recipe(
      name: 'Ginger Sautéed Spinach',
      imageUrl: 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39',
      cookingTimeMinutes: 10,
      servings: 4,
      source: 'Barefoot Contessa',
      ingredients: [
        Ingredient(name: 'Spinach', isOwned: false),
        Ingredient(name: 'Garlic', isOwned: true),
        Ingredient(name: 'Olive Oil', isOwned: true),
        Ingredient(name: 'Butter', isOwned: true),
        Ingredient(name: 'Salt', isOwned: true),
      ],
    ),
  ];

  List<Recipe> get _filteredRecipes {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _recipes;

    return _recipes.where((recipe) {
      return recipe.name.toLowerCase().contains(query) ||
          recipe.ingredients.any(
            (ingredient) => ingredient.name.toLowerCase().contains(query),
          );
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cookableRecipes =
        _filteredRecipes.where((recipe) => recipe.isFullyCookable).toList();
    final nearlyCookableRecipes =
        _filteredRecipes.where((recipe) => recipe.isNearlyCookable).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF97B380),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Find Recipes',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '2000+',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Suggestions Based on\nWhat You Own',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search recipes...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 20,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (cookableRecipes.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Cookable',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 220,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: cookableRecipes.length,
                                  itemBuilder: (context, index) {
                                    return SizedBox(
                                      width: 170,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: RecipeCard(
                                          recipe: cookableRecipes[index],
                                          onTap: () {
                                            // Navigate to recipe details
                                          },
                                          onFavorite: () {
                                            // Toggle favorite
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            if (nearlyCookableRecipes.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Nearly Cookable',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 220,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: nearlyCookableRecipes.length,
                                  itemBuilder: (context, index) {
                                    return SizedBox(
                                      width: 170,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: RecipeCard(
                                          recipe: nearlyCookableRecipes[index],
                                          onTap: () {
                                            // Navigate to recipe details
                                          },
                                          onFavorite: () {
                                            // Toggle favorite
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
