import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class RecipesListScreen extends StatefulWidget {
  const RecipesListScreen({super.key});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();

  List<Recipe> _recipes = [];
  List<Recipe> _aiRecipes = [];
  List<Ingredient> _pantryIngredients = [];
  List<Ingredient> _selectedIngredients = [];
  List<String> _recentSearches = ['Jollof rice', 'Chicken', 'Pasta'];
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;
  String _searchQuery = '';
  int _selectedTabIndex = 0;
  bool _isBannerMinimized = false;

  String? selectedCuisineType;
  String? selectedDietaryRestriction;
  int servings = 4;
  int maxCookingTime = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen gains focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload data when app becomes visible
      _loadData();
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_isBannerMinimized) {
      setState(() {
        _isBannerMinimized = true;
      });
    } else if (_scrollController.offset <= 100 && _isBannerMinimized) {
      setState(() {
        _isBannerMinimized = false;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        _firestoreService.fetchRecipes(),
        _firestoreService.fetchAIRecipes(),
        _firestoreService.fetchPantry(),
        AIService.getCuisineTypes(),
        AIService.getDietaryRestrictions(),
      ]);

      setState(() {
        _recipes = futures[0] as List<Recipe>;
        _aiRecipes = futures[1] as List<Recipe>;
        _pantryIngredients = futures[2] as List<Ingredient>;
        final cuisineTypes = futures[3] as List<String>;
        final dietaryRestrictions = futures[4] as List<String>;

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

  List<Recipe> get _filteredRecipes {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return _recipes;
    return _recipes.where((recipe) {
      return recipe.name.toLowerCase().contains(query) ||
          recipe.ingredients.any(
            (ingredient) => ingredient.name.toLowerCase().contains(query),
          );
    }).toList();
  }

  List<Recipe> get _filteredAIRecipes {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return _aiRecipes;
    return _aiRecipes.where((recipe) {
      return recipe.name.toLowerCase().contains(query) ||
          recipe.ingredients.any(
            (ingredient) => ingredient.name.toLowerCase().contains(query),
          );
    }).toList();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Search',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text('Time', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Newest'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Oldest'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Popularity'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Rate', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('5★'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('4★'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('3★'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('2★'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('1★'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Cereal'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Vegetables'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Dinner'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Chinese'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Local Dish'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Fruit'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Breakfast'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Spanish'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text('Lunch'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Filter'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showIngredientSelectionDialog() {
    // Reset selected ingredients when opening dialog
    _selectedIngredients.clear();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.kitchen, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    const Text('Select Ingredients'),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    children: [
                      const Text(
                        'Choose ingredients from your pantry to include in recipe generation:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      if (_pantryIngredients.isEmpty)
                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.kitchen, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No ingredients in pantry',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Add some ingredients first',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: _pantryIngredients.length,
                            itemBuilder: (context, index) {
                              final ingredient = _pantryIngredients[index];
                              final isSelected = _selectedIngredients.any(
                                (selected) => selected.name == ingredient.name,
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(
                                            0xFF4CAF50,
                                          ).withOpacity(0.1)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? const Color(0xFF4CAF50)
                                            : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  title: Text(
                                    ingredient.name,
                                    style: TextStyle(
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          isSelected
                                              ? const Color(0xFF4CAF50)
                                              : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${ingredient.quantity ?? 0} ${ingredient.unit ?? ''} - Expires: ${ingredient.expiryDate?.toIso8601String().split('T').first ?? 'No expiry'}',
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? const Color(0xFF4CAF50)
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                  value: isSelected,
                                  activeColor: const Color(0xFF4CAF50),
                                  checkColor: Colors.white,
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        // Check if ingredient is already selected by name
                                        if (!_selectedIngredients.any(
                                          (selected) =>
                                              selected.name == ingredient.name,
                                        )) {
                                          _selectedIngredients.add(ingredient);
                                        }
                                      } else {
                                        // Remove ingredient by name
                                        _selectedIngredients.removeWhere(
                                          (selected) =>
                                              selected.name == ingredient.name,
                                        );
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      if (_pantryIngredients.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: const Color(0xFF4CAF50),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_selectedIngredients.length} ingredient${_selectedIngredients.length == 1 ? '' : 's'} selected',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        _selectedIngredients.clear();
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                  TextButton(
                    onPressed: () {
                      _selectedIngredients.clear();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _selectedIngredients.isEmpty
                            ? null
                            : () {
                              Navigator.of(context).pop();
                              _generateRecipeFromSelectedIngredients();
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Generate Recipe'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _generateRecipeFromSelectedIngredients() async {
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one ingredient'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      print('DEBUG: Starting pantry recipe generation');
      print(
        'DEBUG: Selected ingredients: ${_selectedIngredients.map((i) => i.name).join(', ')}',
      );
      print('DEBUG: Cuisine type: $selectedCuisineType');
      print('DEBUG: Dietary restriction: $selectedDietaryRestriction');
      print('DEBUG: Servings: $servings');
      print('DEBUG: Max cooking time: $maxCookingTime');

      final recipe = await AIService.generateRecipeFromPantry(
        pantryIngredients: _selectedIngredients,
        cuisineType: selectedCuisineType,
        dietaryRestriction: selectedDietaryRestriction,
        servings: servings,
        maxCookingTime: maxCookingTime,
      );

      print('DEBUG: Recipe generated: ${recipe?.name ?? 'null'}');

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
                'No suitable recipe could be generated with selected ingredients.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error in pantry recipe generation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

  Future<void> _generateRecipeFromSearch() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a search query'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_pantryIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No ingredients found in pantry. Please add some ingredients first.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      print('DEBUG: Starting search recipe generation');
      print('DEBUG: Search query: ${_searchController.text.trim()}');
      print(
        'DEBUG: Available ingredients: ${_pantryIngredients.map((i) => i.name).join(', ')}',
      );
      print('DEBUG: Cuisine type: $selectedCuisineType');
      print('DEBUG: Dietary restriction: $selectedDietaryRestriction');
      print('DEBUG: Servings: $servings');
      print('DEBUG: Max cooking time: $maxCookingTime');

      final recipe = await AIService.generateRecipeFromSearch(
        searchQuery: _searchController.text.trim(),
        availableIngredients: _pantryIngredients,
        cuisineType: selectedCuisineType,
        dietaryRestriction: selectedDietaryRestriction,
        servings: servings,
        maxCookingTime: maxCookingTime,
      );

      print('DEBUG: Recipe generated: ${recipe?.name ?? 'null'}');

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
              content: Text('Failed to generate recipe. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error in search recipe generation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
    if (_pantryIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No ingredients found in pantry. Please add some ingredients first.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
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
              content: Text('Recipe "${recipe.name}" generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No suitable ingredients found in pantry.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

  void _navigateToRecipeDetail(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    ).then((_) {
      // Refresh data when returning from detail screen
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;
    final verticalPadding = isTablet ? 20.0 : 16.0;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F8F8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Search and Filter (no back button)
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
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
                                hintText:
                                    'Search recipes or generate AI recipes...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 16),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: Colors.white),
                      onPressed: _showFilterModal,
                    ),
                  ),
                ],
              ),
            ),

            // AI Recipe Generation Section (minimizable)
            if (_searchQuery.isEmpty) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isBannerMinimized ? 80 : null,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    verticalPadding,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFE1BEE7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C27B0).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child:
                        _isBannerMinimized
                            ? Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'AI Recipe Generator',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isBannerMinimized = false;
                                    });
                                    _scrollController.animateTo(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.expand_less,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Text(
                                        'AI Recipe Generator',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _isBannerMinimized = true;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.expand_more,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Generate personalized recipes using AI based on your available ingredients',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16.0 : 14.0,
                                    color: Colors.white,
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
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(
                                            0xFF9C27B0,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                                : _showIngredientSelectionDialog,
                                        icon: const Icon(Icons.kitchen),
                                        label: const Text('Select Ingredients'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(
                                            0xFF9C27B0,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (_pantryIngredients.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${_pantryIngredients.where((i) => i.isOwned).length} ingredients available in pantry',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                  ),
                ),
              ),
            ],

            // Tab Bar
            if (_searchQuery.isEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: 'All Recipes',
                        isSelected: _selectedTabIndex == 0,
                        onTap: () => setState(() => _selectedTabIndex = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(
                        label: 'AI Generated',
                        isSelected: _selectedTabIndex == 1,
                        onTap: () => setState(() => _selectedTabIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Content based on selected tab
            Expanded(child: _buildTabContent(horizontalPadding)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(double horizontalPadding) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults(horizontalPadding);
    }

    switch (_selectedTabIndex) {
      case 0:
        return _buildAllRecipes(horizontalPadding);
      case 1:
        return _buildAIRecipes(horizontalPadding);
      default:
        return _buildAllRecipes(horizontalPadding);
    }
  }

  Widget _buildAllRecipes(double horizontalPadding) {
    if (_recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No recipes yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by generating some AI recipes!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        itemCount: _recipes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return GestureDetector(
            onTap: () => _navigateToRecipeDetail(recipe),
            child: RecipeCard(recipe: recipe),
          );
        },
      ),
    );
  }

  Widget _buildAIRecipes(double horizontalPadding) {
    if (_aiRecipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No AI recipes yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate your first AI recipe using the button above!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        itemCount: _aiRecipes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final recipe = _aiRecipes[index];
          return GestureDetector(
            onTap: () => _navigateToRecipeDetail(recipe),
            child: RecipeCard(recipe: recipe),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(double horizontalPadding) {
    final allResults = [..._filteredRecipes, ..._filteredAIRecipes];

    if (allResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No recipes found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term or generate a new recipe',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Search Results',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '${allResults.length} results',
                style: const TextStyle(color: Color(0xFF8B8B8B), fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              itemCount: allResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final recipe = allResults[index];
                return GestureDetector(
                  onTap: () => _navigateToRecipeDetail(recipe),
                  child: RecipeCard(recipe: recipe),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
