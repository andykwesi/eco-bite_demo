import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../widgets/recipe_card.dart';
import '../widgets/ai_search_modal.dart';
import 'recipe_detail_screen.dart';

class RecipesListScreen extends StatefulWidget {
  const RecipesListScreen({super.key});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();

  List<Recipe> _recipes = [];
  List<Recipe> _aiRecipes = [];
  List<Ingredient> _pantryIngredients = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String _searchQuery = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Handle scroll behavior if needed
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        _firestoreService.fetchRecipes(),
        _firestoreService.fetchAIRecipes(),
        _firestoreService.fetchPantry(),
      ]);

      setState(() {
        _recipes = futures[0] as List<Recipe>;
        _aiRecipes = futures[1] as List<Recipe>;
        _pantryIngredients = futures[2] as List<Ingredient>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAISearchModal() async {
    if (!mounted) return;

    final recipe = await showDialog<Recipe>(
      context: context,
      builder:
          (context) => AISearchModal(pantryIngredients: _pantryIngredients),
    );

    if (recipe != null && mounted) {
      // Refresh data to show the new recipe
      await _loadData();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe "${recipe.name}" generated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showPantryBasedGeneration() async {
    if (_pantryIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Your pantry is empty. Add some ingredients first!',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
      );

      if (recipe != null) {
        // Save to AI recipes collection
        await _firestoreService.addAIRecipe(recipe);

        // Refresh data
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Recipe "${recipe.name}" generated from your pantry!',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'No suitable recipes could be generated from your pantry.',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  void _navigateToRecipeDetail(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  List<Recipe> get _filteredRecipes {
    if (_searchQuery.isEmpty) return _recipes;
    return _recipes.where((recipe) {
      return recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          recipe.ingredients.any(
            (ingredient) => ingredient.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          );
    }).toList();
  }

  List<Recipe> get _filteredAIRecipes {
    if (_searchQuery.isEmpty) return _aiRecipes;
    return _aiRecipes.where((recipe) {
      return recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          recipe.ingredients.any(
            (ingredient) => ingredient.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),

            // Search Bar
            _buildSearchBar(),

            // AI Generation Section
            _buildAIGenerationSection(),

            // Tab Bar
            _buildTabBar(),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllRecipesTab(),
                  _buildAIRecipesTab(),
                  _buildRegularRecipesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Recipe Collection',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Discover and create amazing recipes',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search recipes...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAIGenerationSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildAIGenerationCard(
              icon: Icons.auto_awesome,
              title: 'AI Search',
              subtitle: 'Generate from ideas',
              color: const Color(0xFF9C27B0),
              onTap: _showAISearchModal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildAIGenerationCard(
              icon: Icons.kitchen,
              title: 'Pantry Magic',
              subtitle: 'Generate from ingredients',
              color: const Color(0xFF4CAF50),
              onTap: _showPantryBasedGeneration,
              isLoading: _isGenerating,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIGenerationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            // _selectedTabIndex = index; // Removed unused field
          });
        },
        indicator: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'All Recipes'),
          Tab(text: 'AI Generated'),
          Tab(text: 'Regular'),
        ],
      ),
    );
  }

  Widget _buildAllRecipesTab() {
    final allRecipes = [..._filteredRecipes, ..._filteredAIRecipes];

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (allRecipes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_menu,
        title: 'No recipes found',
        subtitle:
            _searchQuery.isEmpty
                ? 'Start by generating some AI recipes!'
                : 'Try a different search term or generate a new recipe',
      );
    }

    return _buildRecipesList(allRecipes);
  }

  Widget _buildAIRecipesTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_filteredAIRecipes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_awesome,
        title: 'No AI recipes yet',
        subtitle: 'Generate your first AI recipe using the buttons above!',
      );
    }

    return _buildRecipesList(_filteredAIRecipes);
  }

  Widget _buildRegularRecipesTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_filteredRecipes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.book,
        title: 'No regular recipes',
        subtitle: 'Add some recipes to your collection!',
      );
    }

    return _buildRecipesList(_filteredRecipes);
  }

  Widget _buildRecipesList(List<Recipe> recipes) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: recipes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return GestureDetector(
            onTap: () => _navigateToRecipeDetail(recipe),
            child: RecipeCard(recipe: recipe),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4CAF50)),
          SizedBox(height: 16),
          Text(
            'Loading recipes...',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 64, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
