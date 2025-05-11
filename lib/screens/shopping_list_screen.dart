import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../widgets/ingredient_list_item.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Sample shopping list data
  final List<Ingredient> _shoppingList = [
    Ingredient(name: 'Olive Oil', isOwned: false),
    Ingredient(name: 'Taco Seasoning', isOwned: false),
    Ingredient(name: 'Vegetable Stock', isOwned: false),
    Ingredient(name: 'White Cabbage', isOwned: false),
    Ingredient(name: 'Butter', isOwned: false),
    Ingredient(name: 'Dried Red Chillies', isOwned: false),
    Ingredient(name: 'Gluten Free Tamari', isOwned: false),
    Ingredient(name: 'Olive Oil', isOwned: false),
  ];

  List<Ingredient> get _filteredShoppingList {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _shoppingList;

    return _shoppingList.where((ingredient) {
      return ingredient.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Shopping List',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Track What You Need',
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
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search garlic...',
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
                        child: ListView.builder(
                          itemCount: _filteredShoppingList.length,
                          itemBuilder: (context, index) {
                            final ingredient = _filteredShoppingList[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                elevation: 0,
                                color: Colors.grey.shade100,
                                child: IngredientListItem(
                                  ingredient: ingredient,
                                  onTap: () {
                                    // Handle item tap (e.g., mark as purchased)
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                // Add ingredient to shopping list
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Ingredient'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Sort or filter shopping list
                              },
                              icon: const Icon(Icons.sort),
                            ),
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
