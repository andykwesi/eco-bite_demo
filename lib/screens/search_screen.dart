import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../widgets/recipe_card.dart';
import '../widgets/error_dialog.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  List<Recipe> _recentRecipes = [];
  List<Ingredient> _pantryIngredients = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  String? selectedCuisineType;
  String? selectedDietaryRestriction;
  int servings = 4;
  int maxCookingTime = 60;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        _firestoreService.fetchAIRecipes(),
        _firestoreService.fetchPantry(),
        AIService.getCuisineTypes(),
        AIService.getDietaryRestrictions(),
      ]);

      setState(() {
        _recentRecipes = futures[0] as List<Recipe>;
        _pantryIngredients = futures[1] as List<Ingredient>;
        final cuisineTypes = futures[2] as List<String>;
        final dietaryRestrictions = futures[3] as List<String>;

        selectedCuisineType = cuisineTypes.first;
        selectedDietaryRestriction = dietaryRestrictions.first;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateRecipeFromSearch() async {
    // Check if AI service is configured
    if (!AIService.isConfigured) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('AI Service Not Configured'),
                content: Text(AIService.getConfigurationInstructions()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
      return;
    }

    if (_searchController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a search query'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final recipe = await AIService.generateRecipeFromSearch(
        searchQuery: _searchController.text.trim(),
        availableIngredients: _pantryIngredients,
        cuisineType: selectedCuisineType,
        dietaryRestriction: selectedDietaryRestriction,
        servings: servings,
        maxCookingTime: maxCookingTime,
      );

      if (recipe != null) {
        // Save to AI recipes collection
        await _firestoreService.addAIRecipe(recipe);

        // Refresh the list
        await _loadData();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recipe "${recipe.name}" generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to generate recipe. Please try again with different search terms or preferences.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating recipe: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _generateRecipeFromPantry() async {
    // Check if AI service is configured
    if (!AIService.isConfigured) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('AI Service Not Configured'),
                content: Text(AIService.getConfigurationInstructions()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final recipe = await AIService.generateRecipeFromPantry(
        pantryIngredients: _pantryIngredients,
        cuisineType: selectedCuisineType,
        dietaryRestriction: selectedDietaryRestriction,
        servings: servings,
        maxCookingTime: maxCookingTime,
      );

      if (recipe != null) {
        // Save to AI recipes collection
        await _firestoreService.addAIRecipe(recipe);

        // Refresh the list
        await _loadData();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recipe "${recipe.name}" generated from pantry!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No suitable recipes could be generated. Try adjusting your preferences or adding more ingredients to your pantry.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating recipe: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showCustomConfirmDialog(
      context: context,
      title: 'Clear History',
      message:
          'Are you sure you want to clear all recent AI-generated recipes?',
      confirmText: 'Clear',
      cancelText: 'Cancel',
      isDestructive: true,
      icon: Icons.delete_forever,
    );

    if (confirm == true) {
      try {
        await _firestoreService.clearAIRecipes();
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('History cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear history: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'AI Recipe Search',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          if (_recentRecipes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: _clearHistory,
              tooltip: 'Clear History',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Search Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.search,
                                color: Color(0xFF8B8B8B),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search for recipes...',
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick Actions
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isGenerating
                                        ? null
                                        : _generateRecipeFromSearch,
                                icon: const Icon(Icons.search),
                                label: const Text('Search & Generate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isGenerating
                                        ? null
                                        : _generateRecipeFromPantry,
                                icon: const Icon(Icons.kitchen),
                                label: const Text('From Pantry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Options
                        _buildOptionsSection(),
                      ],
                    ),
                  ),

                  // Recent Recipes Section
                  Expanded(
                    child:
                        _recentRecipes.isEmpty
                            ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No recent recipes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Search for recipes or generate from pantry to see them here',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Recent AI Recipes',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_recentRecipes.length} recipes',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    itemCount: _recentRecipes.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      final recipe = _recentRecipes[index];
                                      return RecipeCard(recipe: recipe);
                                    },
                                  ),
                                ),
                              ],
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recipe Options',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Cuisine Type
        Row(
          children: [
            const Text('Cuisine: ', style: TextStyle(fontSize: 14)),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCuisineType,
                    isExpanded: true,
                    hint: const Text('Any'),
                    items:
                        [
                          'Any',
                          'Italian',
                          'Mexican',
                          'Chinese',
                          'Indian',
                          'Japanese',
                          'Thai',
                          'Mediterranean',
                          'French',
                          'American',
                          'Greek',
                          'Spanish',
                          'Korean',
                          'Vietnamese',
                          'Lebanese',
                          'Turkish',
                          'Moroccan',
                          'Ethiopian',
                          'Caribbean',
                          'African',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCuisineType = newValue;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Dietary Restrictions
        Row(
          children: [
            const Text('Diet: ', style: TextStyle(fontSize: 14)),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDietaryRestriction,
                    isExpanded: true,
                    hint: const Text('None'),
                    items:
                        [
                          'None',
                          'Vegetarian',
                          'Vegan',
                          'Gluten-Free',
                          'Dairy-Free',
                          'Low-Carb',
                          'Keto',
                          'Paleo',
                          'Halal',
                          'Kosher',
                          'Nut-Free',
                          'Seafood-Free',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDietaryRestriction = newValue;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Servings and Time
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Servings: $servings',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Slider(
                    value: servings.toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    activeColor: const Color(0xFF4CAF50),
                    onChanged: (value) {
                      setState(() {
                        servings = value.round();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max Time: ${maxCookingTime}min',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Slider(
                    value: maxCookingTime.toDouble(),
                    min: 15,
                    max: 120,
                    divisions: 7,
                    activeColor: const Color(0xFF4CAF50),
                    onChanged: (value) {
                      setState(() {
                        maxCookingTime = value.round();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
