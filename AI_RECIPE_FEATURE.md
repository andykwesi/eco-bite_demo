# AI Recipe Generation Features

## Overview

This document describes the new AI-powered recipe generation features that have been implemented in the EcoBite app.

## Features

### 1. AI Recipe Generation from Pantry

- **Location**: Pantry Screen
- **Functionality**: Generates recipes using ingredients available in the user's pantry
- **Access**:
  - Floating Action Button (FAB) with "AI Recipes" label
  - "Generate AI Recipe from Pantry" button at the top of the pantry
- **Smart Prioritization**:
  - Prioritizes fresh ingredients (expiring within 3 days)
  - Uses at least 80% of available pantry ingredients
  - Only suggests 1-2 additional ingredients if absolutely necessary

### 2. AI Recipe Search

- **Location**: New "AI Search" tab in bottom navigation
- **Functionality**:
  - Search for recipes using natural language queries
  - Generate recipes based on search terms and available ingredients
  - Customizable cuisine type, dietary restrictions, servings, and cooking time
- **Access**: Bottom navigation bar → "AI Search" tab

### 3. Recent Search History

- **Storage**: AI-generated recipes are automatically saved to Firestore
- **Display**: Shows up to 20 most recent AI-generated recipes
- **Management**:
  - Clear individual recipes
  - Clear entire history
  - Recipes are sorted by creation date (newest first)

### 4. Enhanced Recipe Generation Dialog

- **Location**: Accessible from pantry screen
- **Improvements**:
  - Uses new pantry-focused AI generation
  - Automatically saves generated recipes
  - Better ingredient prioritization
  - Clear indication of recipe source

## Technical Implementation

### AI Service Enhancements

- `generateRecipeFromPantry()`: Optimized for pantry ingredients
- `generateRecipeFromSearch()`: Handles search queries
- Smart ingredient filtering and prioritization
- Enhanced prompts for better recipe quality

### Data Storage

- New `aiRecipes` collection in Firestore
- Timestamp tracking for recipe generation
- Search query association
- Automatic cleanup and management

### UI Components

- New `SearchScreen` for AI recipe search
- Enhanced `RecipeCard` widget with cookability status
- Integrated search functionality in home screen
- Floating action buttons for quick access

## Usage Instructions

### Generating Recipes from Pantry

1. Navigate to Pantry screen
2. Tap the "Generate AI Recipe from Pantry" button or FAB
3. Configure recipe preferences (cuisine, diet, servings, time)
4. Tap "Generate from Pantry"
5. Recipe will be generated and saved automatically

### Searching for Recipes

1. Navigate to "AI Search" tab
2. Enter your search query (e.g., "chicken pasta", "vegetarian curry")
3. Configure recipe preferences
4. Tap "Search & Generate" or "From Pantry"
5. Recipe will be generated and added to recent history

### Managing Recent Recipes

1. View all recent AI-generated recipes in the search screen
2. Tap on any recipe to view details
3. Use the clear button to remove individual recipes
4. Use the clear history button to remove all recent recipes

## Benefits

1. **Reduces Food Waste**: Maximizes use of pantry ingredients
2. **Saves Money**: Minimizes need to buy additional ingredients
3. **Increases Creativity**: AI suggests unique recipe combinations
4. **Personalized**: Adapts to dietary preferences and available ingredients
5. **Convenient**: Quick access from multiple locations in the app

## Future Enhancements

- Recipe rating and feedback system
- Ingredient substitution suggestions
- Meal planning integration
- Shopping list generation for missing ingredients
- Recipe sharing and social features
- Nutritional information calculation
