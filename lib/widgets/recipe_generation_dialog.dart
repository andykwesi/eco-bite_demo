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

  @override
  void initState() {
    super.initState();
    _loadOptions();
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

  Future<void> _generateRecipe() async {
    if (selectedCuisineType == null || selectedDietaryRestriction == null) {
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
      // Use the new pantry-focused generation method
      final recipe = await AIService.generateRecipeFromPantry(
        pantryIngredients: widget.availableIngredients,
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
                'No suitable recipes could be generated. Try adjusting your preferences or adding more ingredients to your pantry.',
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

            // Available Ingredients Info
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
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Available Ingredients',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.availableIngredients.where((i) => i.isOwned).length} ingredients available',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recipe will prioritize using your pantry ingredients',
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
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, size: 20),
                            SizedBox(width: 8),
                            Text('Configure AI Service First'),
                          ],
                        )
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
