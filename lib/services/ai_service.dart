import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';

class AIService {
  static bool get isConfigured {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      print('DEBUG: Checking API key configuration...');
      print('DEBUG: API key found: ${apiKey != null ? 'Yes' : 'No'}');
      if (apiKey != null) {
        print('DEBUG: API key length: ${apiKey.length}');
        print(
          'DEBUG: API key starts with: ${apiKey.substring(0, min(20, apiKey.length))}',
        );
        print(
          'DEBUG: API key is placeholder: ${apiKey == 'your_openai_api_key_here'}',
        );
      }

      final isConfigured =
          apiKey != null &&
          apiKey.isNotEmpty &&
          apiKey != 'your_openai_api_key_here';

      print('DEBUG: AIService isConfigured: $isConfigured');
      return isConfigured;
    } catch (e) {
      print('DEBUG: Error checking API key configuration: $e');
      return false;
    }
  }

  static String get _apiKey {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'OpenAI API key not configured. Please add your API key to the .env file.',
      );
    }
    if (apiKey == 'your_openai_api_key_here') {
      throw Exception(
        'Please configure your OpenAI API key in the .env file. Get your API key from https://platform.openai.com/api-keys',
      );
    }
    return apiKey;
  }

  static const String _baseUrl = "https://api.openai.com/v1/chat/completions";

  /// Generate a recipe based on available ingredients
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
You are a professional chef and recipe creator. Generate a delicious, creative recipe based on the following requirements:

AVAILABLE INGREDIENTS: $availableIngredientNames
CUISINE TYPE: ${cuisineType ?? 'Any'}
DIETARY RESTRICTIONS: ${dietaryRestriction ?? 'None'}
SERVINGS: $servings
MAXIMUM COOKING TIME: $maxCookingTime minutes

REQUIREMENTS:
1. Use at least 70% of the available ingredients
2. Add only 2-3 additional ingredients if absolutely necessary
3. Ensure the recipe is practical and achievable
4. Make it delicious and creative
5. Follow the exact JSON format below

RESPONSE FORMAT (JSON only, no additional text):
{
  "name": "Creative Recipe Name",
  "imageUrl": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop",
  "ingredients": [
    {
      "name": "Ingredient Name",
      "isOwned": true,
      "quantity": 1.0,
      "unit": "cup"
    }
  ],
  "cookingTimeMinutes": 30,
  "servings": $servings,
  "source": "AI Generated",
  "instructions": [
    "Step 1: Detailed instruction",
    "Step 2: Detailed instruction",
    "Step 3: Detailed instruction"
  ],
  "category": "Main",
  "isFast": false,
  "difficulty": "Easy",
  "nutrition": {
    "calories": 350,
    "protein": "15g",
    "carbs": "45g",
    "fat": "12g"
  }
}

IMPORTANT: Return ONLY valid JSON. No markdown formatting, no explanations, just the JSON object.
''';

      print('DEBUG: Sending request to OpenAI...');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a professional chef and recipe creator. Always respond with valid JSON only.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1500,
          'temperature': 0.7,
          'top_p': 0.9,
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

          try {
            final recipeData = jsonDecode(jsonString);
            print('DEBUG: Recipe data extracted successfully');

            // Convert ingredients to Ingredient objects
            final ingredients =
                (recipeData['ingredients'] as List)
                    .map((ingredient) => Ingredient.fromMap(ingredient))
                    .toList();

            final recipe = Recipe(
              name: recipeData['name'] ?? 'AI Generated Recipe',
              imageUrl:
                  recipeData['imageUrl'] ??
                  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop',
              ingredients: ingredients,
              cookingTimeMinutes: recipeData['cookingTimeMinutes'] ?? 30,
              servings: recipeData['servings'] ?? servings,
              source: recipeData['source'] ?? 'AI Generated',
              instructions: List<String>.from(
                recipeData['instructions'] ?? ['Mix ingredients and cook'],
              ),
              category: recipeData['category'] ?? 'Main',
              isFast: recipeData['isFast'] ?? false,
            );

            print('DEBUG: Recipe created successfully: ${recipe.name}');
            return recipe;
          } catch (jsonError) {
            print('DEBUG: JSON parsing error: $jsonError');
            print('DEBUG: Raw JSON string: $jsonString');
            throw Exception(
              'Invalid JSON response from AI service: $jsonError',
            );
          }
        } else {
          print('DEBUG: Failed to extract JSON from response');
          print('DEBUG: Response content: $content');
          throw Exception(
            'Invalid response format from AI service - no JSON found',
          );
        }
      } else {
        print(
          'DEBUG: OpenAI API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to generate recipe: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('DEBUG: Error in generateRecipe: $e');
      rethrow;
    }
  }

  /// Generate a recipe based on search query
  static Future<Recipe?> generateRecipeFromSearch({
    required String searchQuery,
    required List<Ingredient> availableIngredients,
    String? cuisineType,
    String? dietaryRestriction,
    int servings = 4,
    int maxCookingTime = 60,
  }) async {
    try {
      print('DEBUG: Starting search-based recipe generation...');

      final availableIngredientNames = availableIngredients
          .where((ingredient) => ingredient.isOwned)
          .map((ingredient) => ingredient.name)
          .join(', ');

      final prompt = '''
You are a professional chef and recipe creator. Generate a delicious recipe based on this search query and available ingredients:

SEARCH QUERY: "$searchQuery"
AVAILABLE INGREDIENTS: $availableIngredientNames
CUISINE TYPE: ${cuisineType ?? 'Any'}
DIETARY RESTRICTIONS: ${dietaryRestriction ?? 'None'}
SERVINGS: $servings
MAXIMUM COOKING TIME: $maxCookingTime minutes

REQUIREMENTS:
1. The recipe should match the search query
2. Use at least 60% of available ingredients
3. Add only 3-4 additional ingredients if needed
4. Ensure the recipe is practical and achievable
5. Make it delicious and creative
6. Follow the exact JSON format below

RESPONSE FORMAT (JSON only, no additional text):
{
  "name": "Recipe Name Based on Search",
  "imageUrl": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop",
  "ingredients": [
    {
      "name": "Ingredient Name",
      "isOwned": true,
      "quantity": 1.0,
      "unit": "cup"
    }
  ],
  "cookingTimeMinutes": 30,
  "servings": $servings,
  "source": "AI Generated from Search",
  "instructions": [
    "Step 1: Detailed instruction",
    "Step 2: Detailed instruction",
    "Step 3: Detailed instruction"
  ],
  "category": "Main",
  "isFast": false,
  "difficulty": "Easy",
  "nutrition": {
    "calories": 350,
    "protein": "15g",
    "carbs": "45g",
    "fat": "12g"
  }
}

IMPORTANT: Return ONLY valid JSON. No markdown formatting, no explanations, just the JSON object.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a professional chef and recipe creator. Always respond with valid JSON only.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1500,
          'temperature': 0.8,
          'top_p': 0.9,
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

          try {
            final recipeData = jsonDecode(jsonString);

            // Convert ingredients to Ingredient objects
            final ingredients =
                (recipeData['ingredients'] as List)
                    .map((ingredient) => Ingredient.fromMap(ingredient))
                    .toList();

            return Recipe(
              name: recipeData['name'] ?? 'AI Generated Recipe',
              imageUrl:
                  recipeData['imageUrl'] ??
                  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop',
              ingredients: ingredients,
              cookingTimeMinutes: recipeData['cookingTimeMinutes'] ?? 30,
              servings: recipeData['servings'] ?? servings,
              source: recipeData['source'] ?? 'AI Generated from Search',
              instructions: List<String>.from(
                recipeData['instructions'] ?? ['Mix ingredients and cook'],
              ),
              category: recipeData['category'] ?? 'Main',
              isFast: recipeData['isFast'] ?? false,
            );
          } catch (jsonError) {
            print('DEBUG: JSON parsing error in search generation: $jsonError');
            return null;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error generating recipe from search: $e');
      return null;
    }
  }

  /// Generate a recipe from pantry ingredients
  static Future<Recipe?> generateRecipeFromPantry({
    required List<Ingredient> pantryIngredients,
    String? cuisineType,
    String? dietaryRestriction,
    int servings = 4,
    int maxCookingTime = 60,
  }) async {
    try {
      print('DEBUG: Starting pantry-based recipe generation...');

      // Filter out expired ingredients and get available ones
      final availableIngredients =
          pantryIngredients
              .where(
                (ingredient) => ingredient.isOwned && !ingredient.isExpired,
              )
              .toList();

      if (availableIngredients.isEmpty) {
        print('DEBUG: No available ingredients in pantry');
        return null;
      }

      final ingredientNames = availableIngredients
          .map((ingredient) => ingredient.name)
          .join(', ');

      final prompt = '''
You are a professional chef and recipe creator. Generate a delicious recipe that maximizes the use of these pantry ingredients:

AVAILABLE INGREDIENTS: $ingredientNames
CUISINE TYPE: ${cuisineType ?? 'Any'}
DIETARY RESTRICTIONS: ${dietaryRestriction ?? 'None'}
SERVINGS: $servings
MAXIMUM COOKING TIME: $maxCookingTime minutes

REQUIREMENTS:
1. Use at least 80% of the available ingredients
2. Add only 1-2 additional ingredients if absolutely necessary
3. Ensure the recipe is practical and achievable
4. Make it delicious and creative
5. The recipe should be a complete meal
6. Follow the exact JSON format below

RESPONSE FORMAT (JSON only, no additional text):
{
  "name": "Creative Recipe Using Pantry Ingredients",
  "imageUrl": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop",
  "ingredients": [
    {
      "name": "Ingredient Name",
      "isOwned": true,
      "quantity": 1.0,
      "unit": "cup"
    }
  ],
  "cookingTimeMinutes": 30,
  "servings": $servings,
  "source": "AI Generated from Pantry",
  "instructions": [
    "Step 1: Detailed instruction",
    "Step 2: Detailed instruction",
    "Step 3: Detailed instruction"
  ],
  "category": "Main",
  "isFast": false,
  "difficulty": "Easy",
  "nutrition": {
    "calories": 350,
    "protein": "15g",
    "carbs": "45g",
    "fat": "12g"
  }
}

IMPORTANT: Return ONLY valid JSON. No markdown formatting, no explanations, just the JSON object.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a professional chef and recipe creator. Always respond with valid JSON only.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1500,
          'temperature': 0.7,
          'top_p': 0.9,
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

          try {
            final recipeData = jsonDecode(jsonString);

            // Convert ingredients to Ingredient objects
            final ingredients =
                (recipeData['ingredients'] as List)
                    .map((ingredient) => Ingredient.fromMap(ingredient))
                    .toList();

            return Recipe(
              name: recipeData['name'] ?? 'AI Generated Recipe',
              imageUrl:
                  recipeData['imageUrl'] ??
                  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=600&fit=crop',
              ingredients: ingredients,
              cookingTimeMinutes: recipeData['cookingTimeMinutes'] ?? 30,
              servings: recipeData['servings'] ?? servings,
              source: recipeData['source'] ?? 'AI Generated from Pantry',
              instructions: List<String>.from(
                recipeData['instructions'] ?? ['Mix ingredients and cook'],
              ),
              category: recipeData['category'] ?? 'Main',
              isFast: recipeData['isFast'] ?? false,
            );
          } catch (jsonError) {
            print('DEBUG: JSON parsing error in pantry generation: $jsonError');
            return null;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error generating recipe from pantry: $e');
      return null;
    }
  }

  /// Get available cuisine types
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
      'Middle Eastern',
      'Asian Fusion',
      'Latin American',
      'European',
      'Any',
    ];
  }

  /// Get available dietary restrictions
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
      'Low-Sodium',
      'Low-Fat',
      'High-Protein',
      'Low-Calorie',
      'Diabetic-Friendly',
      'Heart-Healthy',
    ];
  }

  /// Generate a recipe image using AI
  static Future<String?> generateRecipeImage(String recipeName) async {
    try {
      final prompt = '''
Generate a beautiful, appetizing food image for this recipe: $recipeName

The image should be:
- High quality and well-lit
- Showcase the dish in an appealing way
- Professional food photography style
- Suitable for a recipe app

Please provide a realistic, high-quality food photography URL.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a food photography expert. Provide only image URLs.',
            },
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

  /// Get configuration instructions for users
  static String getConfigurationInstructions() {
    return '''
To enable AI recipe generation, you need to configure your OpenAI API key:

1. Get your API key from https://platform.openai.com/api-keys
2. Create a .env file in your project root
3. Add this line to the .env file:
   OPENAI_API_KEY=your_actual_api_key_here
4. Restart the app

Note: The API key is required for AI-powered recipe generation features.
''';
  }

  /// Get current configuration status
  static String getConfigurationStatus() {
    if (isConfigured) {
      return '✅ AI service is properly configured and ready to generate recipes';
    } else {
      return '❌ AI service is not configured. Please add your OpenAI API key to the .env file.';
    }
  }

  /// Test the API connection
  static Future<bool> testConnection() async {
    try {
      if (!isConfigured) {
        return false;
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
          'max_tokens': 10,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
