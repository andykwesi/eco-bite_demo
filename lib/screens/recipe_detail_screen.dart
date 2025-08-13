import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../widgets/error_dialog.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isGeneratingImage = false;

  late TextEditingController _nameController;
  late TextEditingController _servingsController;
  late TextEditingController _cookingTimeController;
  late TextEditingController _categoryController;
  late List<TextEditingController> _instructionControllers;
  late List<Ingredient> _ingredients;

  String? _selectedCuisineType;
  String? _selectedDietaryRestriction;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print(
      'DEBUG: RecipeDetailScreen initState called for recipe: ${widget.recipe.name}',
    );
    try {
      _initializeControllers();
      _loadRecipeData();
    } catch (e, stackTrace) {
      print('DEBUG: Error in initState: $e');
      print('DEBUG: Stack trace: $stackTrace');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen gains focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadRecipeData();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _servingsController.dispose();
    _cookingTimeController.dispose();
    _categoryController.dispose();
    for (final controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload data when app becomes visible
      _loadRecipeData();
    }
  }

  void _initializeControllers() {
    try {
      print(
        'DEBUG: Initializing controllers for recipe: ${widget.recipe.name}',
      );
      _nameController = TextEditingController(text: widget.recipe.name);
      _servingsController = TextEditingController(
        text: widget.recipe.servings.toString(),
      );
      _cookingTimeController = TextEditingController(
        text: widget.recipe.cookingTimeMinutes.toString(),
      );
      _categoryController = TextEditingController(text: widget.recipe.category);
      _instructionControllers =
          widget.recipe.instructions
              .map((instruction) => TextEditingController(text: instruction))
              .toList();
      _ingredients = List.from(widget.recipe.ingredients);
      _isFavorite = widget.recipe.isFavorite;
      print('DEBUG: Controllers initialized successfully');
    } catch (e, stackTrace) {
      print('DEBUG: Error initializing controllers: $e');
      print('DEBUG: Stack trace: $stackTrace');
      rethrow;
    }
  }

  void _loadRecipeData() {
    try {
      print('DEBUG: Loading recipe data for: ${widget.recipe.name}');
      print(
        'DEBUG: Recipe has ${widget.recipe.ingredients.length} ingredients',
      );
      print(
        'DEBUG: Recipe has ${widget.recipe.instructions.length} instructions',
      );
      // Load any additional data if needed
    } catch (e, stackTrace) {
      print('DEBUG: Error loading recipe data: $e');
      print('DEBUG: Stack trace: $stackTrace');
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset to original values if canceling edit
        _initializeControllers();
      }
    });
  }

  void _addInstruction() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstruction(int index) {
    if (_instructionControllers.length > 1) {
      setState(() {
        _instructionControllers[index].dispose();
        _instructionControllers.removeAt(index);
      });
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(
        Ingredient(
          name: 'New Ingredient',
          isOwned: false,
          quantity: 1.0,
          unit: 'piece',
        ),
      );
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedRecipe = Recipe(
        name: _nameController.text.trim(),
        imageUrl: widget.recipe.imageUrl,
        ingredients: _ingredients,
        cookingTimeMinutes: int.tryParse(_cookingTimeController.text) ?? 30,
        servings: int.tryParse(_servingsController.text) ?? 4,
        source: widget.recipe.source,
        instructions:
            _instructionControllers
                .where((controller) => controller.text.trim().isNotEmpty)
                .map((controller) => controller.text.trim())
                .toList(),
        isFavorite: _isFavorite,
        category: _categoryController.text.trim(),
        isFast: widget.recipe.isFast,
        createdAt: widget.recipe.createdAt,
        searchQuery: widget.recipe.searchQuery,
      );

      // For now, we'll just show a success message since we don't have proper docId
      // In a real app, you'd need to store the document ID when fetching recipes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recipe updated successfully! (Note: Changes not saved to database)',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteRecipe() async {
    final confirm = await showCustomConfirmDialog(
      context: context,
      title: 'Delete Recipe',
      message:
          'Are you sure you want to delete "${widget.recipe.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
      icon: Icons.delete,
    );

    if (confirm == true) {
      try {
        // For now, we'll just navigate back since we don't have proper docId
        // In a real app, you'd need to store the document ID when fetching recipes
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Recipe deleted successfully (Note: Not removed from database)',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete recipe: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _generateRecipeImage() async {
    setState(() {
      _isGeneratingImage = true;
    });

    try {
      // For now, we'll just show a success message since the AI service might not be fully implemented
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recipe image generation is not fully implemented yet',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      print(
        'DEBUG: Building RecipeDetailScreen for recipe: ${widget.recipe.name}',
      );

      final screenWidth = MediaQuery.of(context).size.width;
      final isTablet = screenWidth > 600;
      final horizontalPadding = isTablet ? 24.0 : 16.0;

      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            _isEditing ? 'Edit Recipe' : widget.recipe.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            if (!_isEditing) ...[
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: _toggleEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteRecipe,
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: _toggleEdit,
              ),
              IconButton(
                icon: const Icon(Icons.save, color: Colors.green),
                onPressed: _isSaving ? null : _saveRecipe,
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image Section
              Container(
                width: double.infinity,
                height: 250,
                margin: EdgeInsets.all(horizontalPadding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.recipe.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.restaurant,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.recipe.source,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (!_isEditing)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton.small(
                            onPressed:
                                _isGeneratingImage
                                    ? null
                                    : _generateRecipeImage,
                            backgroundColor: const Color(0xFF4CAF50),
                            child:
                                _isGeneratingImage
                                    ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                    ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Recipe Details Section
              Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe Name
                    if (_isEditing) ...[
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Recipe Name',
                        ),
                      ),
                    ] else ...[
                      Text(
                        widget.recipe.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Recipe Stats
                    Row(
                      children: [
                        _buildStatItem(
                          icon: Icons.timer,
                          label: 'Time',
                          value: '${widget.recipe.cookingTimeMinutes} min',
                          isEditing: _isEditing,
                          controller: _cookingTimeController,
                        ),
                        const SizedBox(width: 24),
                        _buildStatItem(
                          icon: Icons.people,
                          label: 'Servings',
                          value: '${widget.recipe.servings}',
                          isEditing: _isEditing,
                          controller: _servingsController,
                        ),
                        const SizedBox(width: 24),
                        _buildStatItem(
                          icon: Icons.category,
                          label: 'Category',
                          value: widget.recipe.category,
                          isEditing: _isEditing,
                          controller: _categoryController,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Ingredients Section
                    _buildSectionHeader('Ingredients', Icons.shopping_basket),
                    const SizedBox(height: 8),
                    if (_isEditing) ...[
                      ..._ingredients.asMap().entries.map((entry) {
                        final index = entry.key;
                        final ingredient = entry.value;
                        return _buildEditableIngredient(index, ingredient);
                      }),
                      TextButton.icon(
                        onPressed: _addIngredient,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Ingredient'),
                      ),
                    ] else ...[
                      ...widget.recipe.ingredients.map(
                        (ingredient) => _buildIngredientItem(ingredient),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Instructions Section
                    _buildSectionHeader(
                      'Instructions',
                      Icons.format_list_numbered,
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing) ...[
                      ..._instructionControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;
                        return _buildEditableInstruction(index, controller);
                      }),
                      TextButton.icon(
                        onPressed: _addInstruction,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Step'),
                      ),
                    ] else ...[
                      ...widget.recipe.instructions.asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final instruction = entry.value;
                        return _buildInstructionItem(index, instruction);
                      }),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('DEBUG: Error in build method: $e');
      print('DEBUG: Stack trace: $stackTrace');

      // Return an error screen instead of crashing
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Error',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Try to rebuild
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    TextEditingController? controller,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4CAF50), size: 24),
            const SizedBox(height: 8),
            if (isEditing && controller != null) ...[
              TextField(
                controller: controller,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ] else ...[
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(Ingredient ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            ingredient.isOwned
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: ingredient.isOwned ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(ingredient.name, style: const TextStyle(fontSize: 16)),
          ),
          if (ingredient.quantity != null || ingredient.unit != null)
            Text(
              '${ingredient.quantity ?? ''} ${ingredient.unit ?? ''}'.trim(),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableIngredient(int index, Ingredient ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeIngredient(index),
            iconSize: 20,
          ),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: ingredient.name),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Ingredient name',
              ),
              onChanged: (value) {
                // Create a new ingredient with updated values
                _ingredients[index] = Ingredient(
                  name: value,
                  isOwned: ingredient.isOwned,
                  quantity: ingredient.quantity,
                  unit: ingredient.unit,
                  expiryDate: ingredient.expiryDate,
                );
              },
            ),
          ),
          SizedBox(
            width: 60,
            child: TextField(
              controller: TextEditingController(
                text: ingredient.quantity?.toString() ?? '',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Qty',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // Create a new ingredient with updated values
                _ingredients[index] = Ingredient(
                  name: ingredient.name,
                  isOwned: ingredient.isOwned,
                  quantity: double.tryParse(value),
                  unit: ingredient.unit,
                  expiryDate: ingredient.expiryDate,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextField(
              controller: TextEditingController(text: ingredient.unit ?? ''),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Unit',
                isDense: true,
              ),
              onChanged: (value) {
                // Create a new ingredient with updated values
                _ingredients[index] = Ingredient(
                  name: ingredient.name,
                  isOwned: ingredient.isOwned,
                  quantity: ingredient.quantity,
                  unit: value,
                  expiryDate: ingredient.expiryDate,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(int index, String instruction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInstruction(
    int index,
    TextEditingController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter instruction step',
              ),
            ),
          ),
          if (_instructionControllers.length > 1)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeInstruction(index),
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}
