import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../models/ingredient.dart';

class AISearchModal extends StatefulWidget {
  final List<Ingredient> pantryIngredients;

  const AISearchModal({super.key, required this.pantryIngredients});

  @override
  State<AISearchModal> createState() => _AISearchModalState();
}

class _AISearchModalState extends State<AISearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String? selectedCuisineType;
  String? selectedDietaryRestriction;
  int servings = 4;
  int maxCookingTime = 60;
  bool isLoading = false;
  List<String> cuisineTypes = [];
  List<String> dietaryRestrictions = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final futures = await Future.wait([
        AIService.getCuisineTypes(),
        AIService.getDietaryRestrictions(),
      ]);

      setState(() {
        cuisineTypes = futures[0];
        dietaryRestrictions = futures[1];
        selectedCuisineType = cuisineTypes.first;
        selectedDietaryRestriction = dietaryRestrictions.first;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _generateRecipe() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a search query'),
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
      final recipe = await AIService.generateRecipeFromSearch(
        searchQuery: _searchController.text.trim(),
        availableIngredients: widget.pantryIngredients,
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
          // Close the modal and return the generated recipe
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
                'Failed to generate recipe. Please try again with different search terms or preferences.',
              ),
              backgroundColor: Colors.red,
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight:
              MediaQuery.of(context).size.height *
              0.9, // Limit height to 90% of screen
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Fixed at top
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
                    'AI Recipe Search',
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

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Input
                    const Text(
                      'What would you like to cook?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g., pasta with chicken, vegetarian curry...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _generateRecipe(),
                    ),
                    const SizedBox(height: 20),

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
                    const SizedBox(height: 24),

                    // Configuration Status
                    Container(
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
                            GestureDetector(
                              onTap: () {
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
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                );
                              },
                              child: Text(
                                'Tap here for setup instructions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade600,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Generate Button - Fixed at bottom
            const SizedBox(height: 16),
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
                            Text('Generate Recipe'),
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
