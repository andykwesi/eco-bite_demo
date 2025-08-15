import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../models/ingredient.dart';

class RecipeGenerationDialog extends StatefulWidget {
  final List<Ingredient> availableIngredients;

  const RecipeGenerationDialog({super.key, required this.availableIngredients});

  @override
  State<RecipeGenerationDialog> createState() => _RecipeGenerationDialogState();
}

class _RecipeGenerationDialogState extends State<RecipeGenerationDialog> {
  String? selectedCuisineType;
  String? selectedDietaryRestriction;
  int servings = 4;
  int maxCookingTime = 60;
  bool isLoading = false;
  List<String> cuisineTypes = [];
  List<String> dietaryRestrictions = [];
  final FirestoreService _firestoreService = FirestoreService();
  
  // New state for ingredient selection
  List<Ingredient> selectedIngredients = [];
  bool showIngredientSelection = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    // Initialize with all available ingredients selected
    selectedIngredients = List.from(widget.availableIngredients.where((i) => i.isOwned));
  }

  Future<void> _loadOptions() async {
    final cuisineTypesData = await AIService.getCuisineTypes();
    final dietaryRestrictionsData = await AIService.getDietaryRestrictions();

    setState(() {
      cuisineTypes = cuisineTypesData;
      dietaryRestrictions = dietaryRestrictionsData;
      selectedCuisineType = cuisineTypesData.first;
      selectedDietaryRestriction = dietaryRestrictionsData.first;
    });
  }

  void _toggleIngredientSelectionPanel() {
    setState(() {
      showIngredientSelection = !showIngredientSelection;
    });
  }

  void _toggleIngredientSelection(Ingredient ingredient) {
    setState(() {
      if (selectedIngredients.contains(ingredient)) {
        selectedIngredients.remove(ingredient);
      } else {
        selectedIngredients.add(ingredient);
      }
    });
  }

  void _selectAllIngredients() {
    setState(() {
      selectedIngredients = List.from(widget.availableIngredients.where((i) => i.isOwned));
    });
  }

  void _deselectAllIngredients() {
    setState(() {
      selectedIngredients.clear();
    });
  }

  Future<void> _generateRecipe() async {
    if (selectedCuisineType == null || selectedDietaryRestriction == null) {
      return;
    }

    if (selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one ingredient to generate a recipe.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
      isLoading = true;
    });

    try {
      // Use the selected ingredients instead of all available ingredients
      final recipe = await AIService.generateRecipeFromPantry(
        pantryIngredients: selectedIngredients,
        cuisineType: selectedCuisineType,
        dietaryRestriction: selectedDietaryRestriction,
        servings: servings,
        maxCookingTime: maxCookingTime,
      );

      if (recipe != null) {
        // Save to AI recipes collection
        await _firestoreService.addAIRecipe(recipe);

        setState(() {
          isLoading = false;
        });

        if (mounted) {
          Navigator.of(context).pop(recipe);
        }
      } else {
        setState(() {
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No suitable recipes could be generated. Try adjusting your preferences or selecting different ingredients.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating recipe: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'AI Recipe Generator',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cuisine Type
            const Text(
              'Cuisine Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCuisineType,
                  isExpanded: true,
                  hint: const Text('Select cuisine type'),
                  items:
                      cuisineTypes.map((String value) {
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
            const SizedBox(height: 20),

            // Dietary Restrictions
            const Text(
              'Dietary Restrictions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedDietaryRestriction,
                  isExpanded: true,
                  hint: const Text('Select dietary restriction'),
                  items:
                      dietaryRestrictions.map((String value) {
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
            const SizedBox(height: 20),

            // Servings
            const Text(
              'Servings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
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
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$servings',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Max Cooking Time
            const Text(
              'Maximum Cooking Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
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
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${maxCookingTime}min',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Available Ingredients Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_basket,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Select Pantry Ingredients',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleIngredientSelectionPanel,
                        icon: Icon(
                          showIngredientSelection ? Icons.expand_less : Icons.expand_more,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        tooltip: showIngredientSelection ? 'Hide ingredients' : 'Show ingredients',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${selectedIngredients.length} of ${widget.availableIngredients.where((i) => i.isOwned).length} ingredients selected',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _selectAllIngredients,
                        child: Text(
                          'Select All',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _deselectAllIngredients,
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showIngredientSelection) ...[
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Column(
                          children: widget.availableIngredients
                              .where((ingredient) => ingredient.isOwned)
                              .map((ingredient) {
                            final isSelected = selectedIngredients.contains(ingredient);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _toggleIngredientSelection(ingredient),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue.shade100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue.shade300
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: isSelected
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ingredient.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: isSelected
                                                      ? Colors.blue.shade900
                                                      : Colors.grey.shade800,
                                                ),
                                              ),
                                              if (ingredient.quantity != null && ingredient.unit != null)
                                                Text(
                                                  '${ingredient.quantity} ${ingredient.unit}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isSelected
                                                        ? Colors.blue.shade600
                                                        : Colors.grey.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (ingredient.isExpired)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Expired',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Recipe will prioritize using your selected ingredients',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Configuration Status
            GestureDetector(
              onTap:
                  !AIService.isConfigured
                      ? () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Setup Instructions'),
                                content: SingleChildScrollView(
                                  child: Text(
                                    AIService.getConfigurationInstructions(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                        );
                      }
                      : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      AIService.isConfigured
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        AIService.isConfigured
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          AIService.isConfigured
                              ? Icons.check_circle
                              : Icons.warning,
                          color:
                              AIService.isConfigured
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AIService.isConfigured
                              ? 'AI Service Ready'
                              : 'AI Service Not Configured',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                AIService.isConfigured
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AIService.getConfigurationStatus(),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            AIService.isConfigured
                                ? Colors.green.shade600
                                : Colors.orange.shade600,
                      ),
                    ),
                    if (!AIService.isConfigured) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tap here for setup instructions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                          fontStyle: FontStyle.italic,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (isLoading || !AIService.isConfigured)
                        ? null
                        : _generateRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child:
                    isLoading
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : !AIService.isConfigured
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Configure AI Service First',
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 20),
                            SizedBox(width: 8),
                            Text('Generate from Pantry'),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
