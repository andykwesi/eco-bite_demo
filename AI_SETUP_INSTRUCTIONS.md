# AI Recipe Generation Setup Instructions

## Overview

EcoBite includes AI-powered recipe generation features that can create recipes based on your pantry ingredients, search queries, and dietary preferences.

## Prerequisites

- OpenAI API key (required for AI features)
- Flutter development environment

## Setup Steps

### 1. Get Your OpenAI API Key

1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Sign in or create an account
3. Navigate to API Keys section
4. Create a new API key
5. Copy the API key (keep it secure)

### 2. Configure the API Key

1. Create a `.env` file in your project root directory
2. Add the following line to the `.env` file:
   ```
   OPENAI_API_KEY=your_actual_api_key_here
   ```
3. Replace `your_actual_api_key_here` with your real API key
4. Save the file

### 3. Restart the App

- Stop the app if it's running
- Run `flutter clean` (optional but recommended)
- Restart the app

### 4. Verify Configuration

- The AI service status should show "✅ AI service is properly configured"
- Recipe generation buttons should be enabled
- You should be able to generate recipes from pantry ingredients and search queries

## Features Available After Setup

### Pantry-Based Recipe Generation

- Generate recipes using ingredients you have in your pantry
- Specify cuisine type, dietary restrictions, servings, and cooking time
- AI will prioritize using your available ingredients

### Search-Based Recipe Generation

- Search for specific types of recipes
- AI generates recipes based on your search query and preferences
- Incorporates your pantry ingredients when possible

### Recipe Management

- Generated recipes are automatically saved
- View and manage your AI-generated recipe collection
- Clear recipe history when needed

## Troubleshooting

### "AI Service Not Configured" Error

- Ensure the `.env` file exists in the project root
- Check that the API key is correctly formatted
- Verify the file is named exactly `.env` (not `.env.txt`)

### "No suitable recipes could be generated" Message

- Try adjusting cuisine type or dietary restrictions
- Ensure you have enough ingredients in your pantry
- Check that ingredients are not expired

### API Key Errors

- Verify your OpenAI API key is valid and active
- Check your OpenAI account for any usage limits or billing issues
- Ensure you have sufficient API credits

## Security Notes

- Never commit your `.env` file to version control
- The `.env` file is already in `.gitignore` for security
- Keep your API key private and secure
- Consider using environment variables in production deployments

## Support

If you continue to experience issues:

1. Check the console logs for detailed error messages
2. Verify your OpenAI API key is working with a simple test
3. Ensure all dependencies are properly installed
4. Check your internet connection and firewall settings
