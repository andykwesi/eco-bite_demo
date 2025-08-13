import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import 'auth_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String? get _uid => _authService.currentUserId;

  // Recipes CRUD
  CollectionReference<Map<String, dynamic>> get _recipesRef =>
      _db.collection('users').doc(_uid).collection('recipes');

  Future<List<Recipe>> fetchRecipes() async {
    final snapshot = await _recipesRef.get();
    return snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList();
  }

  Future<void> addRecipe(Recipe recipe) async {
    await _recipesRef.add(recipe.toMap());
  }

  Future<void> updateRecipe(String docId, Recipe recipe) async {
    await _recipesRef.doc(docId).set(recipe.toMap());
  }

  Future<void> deleteRecipe(String docId) async {
    await _recipesRef.doc(docId).delete();
  }

  // AI Generated Recipes (Recent Search History)
  CollectionReference<Map<String, dynamic>> get _aiRecipesRef =>
      _db.collection('users').doc(_uid).collection('aiRecipes');

  Future<List<Recipe>> fetchAIRecipes() async {
    final snapshot =
        await _aiRecipesRef
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();
    return snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList();
  }

  Future<void> addAIRecipe(Recipe recipe) async {
    final recipeData = recipe.toMap();
    recipeData['createdAt'] = FieldValue.serverTimestamp();
    recipeData['searchQuery'] =
        recipe.source.contains('Search') ? recipe.source : '';
    await _aiRecipesRef.add(recipeData);
  }

  Future<void> deleteAIRecipe(String docId) async {
    await _aiRecipesRef.doc(docId).delete();
  }

  Future<void> clearAIRecipes() async {
    final snapshot = await _aiRecipesRef.get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Grocery List CRUD
  CollectionReference<Map<String, dynamic>> get _groceryRef =>
      _db.collection('users').doc(_uid).collection('groceryList');

  Future<List<Ingredient>> fetchGroceryList() async {
    final snapshot = await _groceryRef.get();
    return snapshot.docs.map((doc) => Ingredient.fromMap(doc.data())).toList();
  }

  Future<void> addGroceryItem(Ingredient ingredient) async {
    await _groceryRef.add(ingredient.toMap());
  }

  Future<void> updateGroceryItem(String docId, Ingredient ingredient) async {
    await _groceryRef.doc(docId).set(ingredient.toMap());
  }

  Future<void> deleteGroceryItem(String docId) async {
    await _groceryRef.doc(docId).delete();
  }

  // Pantry CRUD
  CollectionReference<Map<String, dynamic>> get _pantryRef =>
      _db.collection('users').doc(_uid).collection('pantry');

  Future<List<Ingredient>> fetchPantry() async {
    final snapshot = await _pantryRef.get();
    return snapshot.docs.map((doc) => Ingredient.fromMap(doc.data())).toList();
  }

  Future<void> addPantryItem(Ingredient ingredient) async {
    await _pantryRef.add(ingredient.toMap());
  }

  Future<void> updatePantryItem(String docId, Ingredient ingredient) async {
    await _pantryRef.doc(docId).set(ingredient.toMap());
  }

  Future<void> deletePantryItem(String docId) async {
    await _pantryRef.doc(docId).delete();
  }
}
