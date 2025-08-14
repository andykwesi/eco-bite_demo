import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';

class AIService {
  static String get _apiKey {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found in environment variables');
    }
    return apiKey;
  }

  static const String _baseUrl = "https://api.openai.com/v1/chat/completions"\;

  static Future<Recipe?> generateRecipe({
    required List<Ingredient> availableIngredients,
    String? cuisineType,
    String? dietaryRestriction,
    int servings = 4,
    int maxCookingTime = 60,
  }) async {
    try {
      print('DEBUG: Starting AI recipe generation...');

      final availableIngredientNames = availableIngredients
          .where((ingredient) => ingredient.isOwned)
          .map((ingredient) => ingredient.name)
          .join(', ');

      final prompt = '''
Generate a recipe based on the following requirements:

Available ingredients: $availableIngredientNames
Cuisine type: ${cuisineType ?? 'Any'}
Dietary restrictions: ${dietaryRestriction ?? 'None'}
Servings: $servings
Maximum cooking time: $maxCookingTime minutes

Please provide the recipe in the following JSON format:
{
  "name": "Recipe Name",
  "imageUrl": "https://example.com/placeholder-image.jpg",
  "ingredients": [
    {
      "name": "Ingredient Name",
      "isOwned": true/false,
      "quantity": 1.0,
      "unit": "cup"
    }
  ],
  "cookingTimeMinutes": 30,
  "servings": 4,
  "source": "AI Generated",
  "instructions": [
    "Step 1 instruction",
    "Step 2 instruction"
  ],
  "category": "Main",
  "isFast": false
}

Make sure the recipe is creative, delicious, and uses mostly the available ingredients. Add a few additional ingredients if needed to make the recipe complete.
''';

      print('DEBUG: Sending request to OpenAI...');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1000,
          'temperature': 0.8,
        }),
      );

      print('DEBUG: OpenAI response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        print('DEBUG: Processing OpenAI response...');

        // Extract JSON from the response content
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;

        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonString = content.substring(jsonStart, jsonEnd);
          final recipeData = jsonDecode(jsonString);

          print('DEBUG: Recipe data extracted successfully');

          // Convert ingredients to Ingredient objects
          final ingredients =
              (recipeData['ingredients'] as List)
                  .map((ingredient) => Ingredient.fromMap(ingredient))
                  .toList();

          final recipe = Recipe(
            name: recipeData['name'],
            imageUrl: recipeData['imageUrl'],
            ingredients: ingredients,
            cookingTimeMinutes: recipeData['cookingTimeMinutes'],
            servings: recipeData['servings'],
            source: recipeData['source'],
            instructions: List<String>.from(recipeData['instructions']),
            category: recipeData['category'] ?? 'Main',
            isFast: recipeData['isFast'] ?? false,
          );

          print('DEBUG: Recipe created successfully: ${recipe.name}');
          return recipe;
        } else {
          print('DEBUG: Failed to extract JSON from response');
          throw Exception('Invalid response format from AI service');
        }
      } else {
        print(
          'DEBUG: OpenAI API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to generate recipe: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in generateRecipe: $e');
      rethrow;
    }
  }

  static Future<Recipe?> generateRecipeFromSearch({
    required String searchQuery,
    required List<Ingredient> availableIngredients,
    String? cuisineType,
    String? dietaryRestriction,
    int servings = 4,
    int maxCookingTime = 60,
  }) async {
    try {
      final availableIngredientNames = availableIngredients
          .where((ingredient) => ingredient.isOwned)
          .map((ingredient) => ingredient.name)
          .join(', ');

      final prompt = '''
Generate a recipe based on the following search query and requirements:

Search query: $searchQuery
Available ingredients: $availableIngredientNames
Cuisine type: ${cuisineType ?? 'Any'}
Dietary restrictions: ${dietaryRestriction ?? 'None'}
Servings: $servings
Maximum cooking time: $maxCookingTime minutes

Please provide the recipe in the following JSON format:
{
  "name": "Recipe Name",
  "imageUrl": "https://example.com/placeholder-image.jpg",
  "ingredients": [
    {
      "name": "Ingredient Name",
      "isOwned": true/false,
      "quantity": 1.0,
      "unit": "cup"
    }
  ],
  "cookingTimeMinutes": 30,
  "servings": 4,
  "source": "AI Generated from Search",
  "instructions": [
    "Step 1 instruction",
    "Step 2 instruction"
  ],
  "category": "Main",
  "isFast": false
}

Make sure the recipe is creative, delicious, incorporates the search query, and uses mostly the available ingredients. Add a few additional ingredients if needed to make the recipe complete.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1000,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Extract JSON from the response content
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;

        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonString = content.substring(jsonStart, jsonEnd);
          final recipeData = jsonDecode(jsonString);

          // Convert ingredients to Ingredient objects
          final ingredients =
              (recipeData['ingredients'] as List)
                  .map((ingredient) => Ingredient.fromMap(ingredient))
                  .toList();

          return Recipe(
            name: recipeData['name'],
            imageUrl: recipeData['imageUrl'],
            ingredients: ingredients,
            cookingTimeMinutes: recipeData['cookingTimeMinutes'],
            servings: recipeData['servings'],
            source: recipeData['source'],
            instructions: List<String>.from(recipeData['instructions']),
            category: recipeData['category'] ?? 'Main',
            isFast: recipeData['isFast'] ?? false,
          );
        }
      }

      return null;
    } catch (e) {
      print('Error generating recipe from search: $e');
      return null;
    }
  }

  static Future<Recipe?> generateRecipeFromPantry({
    required List<Ingredient> pantryIngredients,
    String? cuisineType,
    String? dietaryRestriction,
    int servings = 4,
    int maxCookingTime = 60,
  }) async {
    try {
      // Filter out expired ingredients and get available ones
      final availableIngredients =
          pantryIngredients
              .where(
                (ingredient) => ingredient.isOwned && !ingredient.isExpired,
              )
              .toList();

      if (availableIngredients.isEmpty) {
        return null;
      }

      final ingredientNames = availableIngredients
          .map((ingredient) => ingredient.name)
          .join(', ');

      final prompt = '''
Generate a recipe that maximizes the use of these pantry ingredients:

Available ingredients: $ingredientNames
Cuisine type: ${cuisineType ?? 'Any'}
Dietary restrictions: ${dietaryRestriction ?? 'None'}
Servings: $servings
Maximum cooking time: $maxCookingTime minutes

IMPORTANT: Prioritize using the available ingredients. Only suggest 1-2 additional ingredients if absolutely necessary for the recipe to work.

Please provide the recipe in the following JSON format:
{
  "name": "Recipe Name",
  "imageUrl": "https://example.com/placeholder-image.jpg",
  "ingredients": [
    {
      "name": "Ingredient Name",
      "isOwned": true/false,
      "quantity": 1.0,
      "unit": "cup"
    }
  ],
  "cookingTimeMinutes": 30,
  "servings": 4,
  "source": "AI Generated from Pantry",
  "instructions": [
    "Step 1 instruction",
    "Step 2 instruction"
  ],
  "category": "Main",
  "isFast": false
}

Make sure the recipe is creative, delicious, and uses at least 80% of the available ingredients. The recipe should be practical and achievable with what's in the pantry.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1000,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Extract JSON from the response content
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;

        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonString = content.substring(jsonStart, jsonEnd);
          final recipeData = jsonDecode(jsonString);

          // Convert ingredients to Ingredient objects
          final ingredients =
              (recipeData['ingredients'] as List)
                  .map((ingredient) => Ingredient.fromMap(ingredient))
                  .toList();

          return Recipe(
            name: recipeData['name'],
            imageUrl: recipeData['imageUrl'],
            ingredients: ingredients,
            cookingTimeMinutes: recipeData['cookingTimeMinutes'],
            servings: recipeData['servings'],
            source: recipeData['source'],
            instructions: List<String>.from(recipeData['instructions']),
            category: recipeData['category'] ?? 'Main',
            isFast: recipeData['isFast'] ?? false,
          );
        }
      }

      return null;
    } catch (e) {
      print('Error generating recipe from pantry: $e');
      return null;
    }
  }

  static Future<List<String>> getCuisineTypes() async {
    return [
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
      'Any',
    ];
  }

  static Future<List<String>> getDietaryRestrictions() async {
    return [
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
    ];
  }

  static Future<String?> generateRecipeImage(String recipeName) async {
    try {
      final prompt = '''
Generate a beautiful, appetizing food image for this recipe: $recipeName
The image should be high quality, well-lit, and showcase the dish in an appealing way.
Please provide a realistic food photography URL.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Extract URL from the response
        final urlRegex = RegExp(r'https?://[^\s]+');
        final match = urlRegex.firstMatch(content);

        if (match != null) {
          return match.group(0);
        }
      }

      // Fallback to a placeholder image
      return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop';
    } catch (e) {
      print('Error generating recipe image: $e');
      // Return fallback image
      return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop';
    }
  }
}
