# 🚀 AI Recipe Generator Setup Guide

This guide will help you set up the OpenAI API integration for AI-powered recipe generation in EcoBite.

## 📋 Prerequisites

- An OpenAI account (free or paid)
- Access to OpenAI API keys
- Flutter development environment

## 🔑 Step 1: Get Your OpenAI API Key

1. **Visit OpenAI Platform**: Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. **Sign In/Up**: Create an account or sign in to your existing account
3. **Create API Key**: Click "Create new secret key"
4. **Copy the Key**: Save your API key securely (it starts with `sk-`)

> ⚠️ **Important**: Keep your API key private and never share it publicly.

## 📁 Step 2: Create Environment File

1. **Navigate to Project Root**: Go to your EcoBite project directory
2. **Create .env File**: Create a new file named `.env` (no file extension)
3. **Add API Key**: Add this line to the file:

```env
OPENAI_API_KEY=sk-your_actual_api_key_here
```

**Example:**

```env
OPENAI_API_KEY=sk-proj-abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
```

> 💡 **Note**: Replace `sk-your_actual_api_key_here` with your actual API key from Step 1.

## 🔄 Step 3: Restart the App

1. **Stop the App**: If running, stop your Flutter app
2. **Hot Restart**: Run `flutter run` again or hot restart
3. **Verify Loading**: Check the console for "Environment variables loaded successfully"

## ✅ Step 4: Verify Configuration

1. **Check Status**: Look for the AI service status indicator in the app
2. **Test Generation**: Try generating a recipe using the AI features
3. **Console Logs**: Check for successful API calls in the console

## 🎯 Available AI Features

Once configured, you'll have access to:

### **Recipe Generation Methods:**

- **Pantry-Based**: Generate recipes using ingredients you already have
- **Search-Based**: Generate recipes based on search queries
- **Ingredient-Based**: Generate recipes from selected ingredients

### **AI Capabilities:**

- **Smart Ingredient Usage**: AI prioritizes your available ingredients
- **Cuisine Variety**: Support for 20+ cuisine types
- **Dietary Options**: 18+ dietary restrictions and preferences
- **Customizable**: Adjust servings, cooking time, and preferences
- **High Quality**: Uses GPT-4 for better recipe generation

## 🛠️ Troubleshooting

### **"AI Service Not Configured" Error**

**Cause**: Missing or invalid API key in `.env` file
**Solution**:

1. Check if `.env` file exists in project root
2. Verify API key format (starts with `sk-`)
3. Ensure no extra spaces or characters
4. Restart the app

### **"API Key Not Found" Error**

**Cause**: `.env` file not being loaded
**Solution**:

1. Verify `.env` file is in project root (same level as `pubspec.yaml`)
2. Check file permissions
3. Ensure no file extension (should be `.env`, not `.env.txt`)

### **"Invalid API Key" Error**

**Cause**: API key format or validity issue
**Solution**:

1. Verify API key starts with `sk-`
2. Check if API key is active in OpenAI dashboard
3. Ensure sufficient API credits/balance

### **"Rate Limit Exceeded" Error**

**Cause**: Too many API calls
**Solution**:

1. Wait a few minutes before trying again
2. Check your OpenAI usage limits
3. Consider upgrading your OpenAI plan

### **"Network Error" Error**

**Cause**: Internet connection or API endpoint issue
**Solution**:

1. Check internet connection
2. Verify OpenAI service status
3. Try again later

## 🔒 Security Best Practices

1. **Never Commit .env**: Ensure `.env` is in your `.gitignore`
2. **Use Environment Variables**: In production, use secure environment variable management
3. **Rotate Keys**: Regularly rotate your API keys
4. **Monitor Usage**: Keep track of your API usage and costs

## 💰 Cost Considerations

- **Free Tier**: Limited API calls per month
- **Paid Plans**: Pay-per-use or subscription models
- **Recipe Generation**: Typically costs $0.01-$0.05 per recipe
- **Usage Monitoring**: Check your OpenAI dashboard for current usage

## 🆘 Getting Help

If you're still experiencing issues:

1. **Check Console Logs**: Look for detailed error messages
2. **Verify API Key**: Test your key in OpenAI's playground
3. **Check Documentation**: Review OpenAI's API documentation
4. **Community Support**: Ask for help in Flutter/OpenAI communities

## 🎉 Success Indicators

You'll know it's working when you see:

- ✅ "AI service is properly configured and ready to generate recipes"
- ✅ Successful recipe generation without errors
- ✅ Console logs showing successful API calls
- ✅ Generated recipes appearing in your app

---

**Happy Cooking with AI! 🍳✨**

For more information, visit:

- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- [EcoBite Project Repository](your-repo-url)
