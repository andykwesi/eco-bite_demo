import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../widgets/ingredient_list_item.dart';
import '../services/firestore_service.dart';
import '../widgets/error_dialog.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  List<Ingredient> _shoppingList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchGroceryList();
  }

  Future<void> _fetchGroceryList() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _firestoreService.fetchGroceryList();
      if (!mounted) return;
      setState(() {
        _shoppingList = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load grocery list.';
        _isLoading = false;
      });
    }
  }

  List<Ingredient> get _filteredShoppingList {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _shoppingList;
    return _shoppingList.where((ingredient) {
      return ingredient.name.toLowerCase().contains(query);
    }).toList();
  }

  void _showAddGrocerySheet({Ingredient? ingredient, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: _AddGrocerySheet(
              onAdd: (newIngredient) async {
                setState(() {
                  if (ingredient != null && index != null) {
                    _shoppingList[index] = newIngredient;
                  } else {
                    _shoppingList.add(newIngredient);
                  }
                });
                try {
                  await _firestoreService.addGroceryItem(newIngredient);
                  await _fetchGroceryList();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingredient added!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add: $e')),
                    );
                  }
                } finally {
                  if (mounted)
                    setState(() {
                      _isLoading = false;
                    });
                }
              },
              initial: ingredient,
            ),
          ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Grocery',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF4CAF50)),
            onPressed: () => _showAddGrocerySheet(),
            tooltip: 'Add Ingredient',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.search,
                      color: Color(0xFF8B8B8B),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search grocery...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 16),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                      : _filteredShoppingList.isEmpty
                      ? const Center(
                        child: Text('No items in your grocery list.'),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _filteredShoppingList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ingredient = _filteredShoppingList[index];
                          return Dismissible(
                            key: ValueKey(
                              ingredient.name +
                                  (ingredient.expiryDate?.toIso8601String() ??
                                      ''),
                            ),
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 24),
                              color: Colors.blue.shade100,
                              child: const Icon(Icons.edit, color: Colors.blue),
                            ),
                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              color: Colors.red.shade100,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                // Edit
                                _showAddGrocerySheet(
                                  ingredient: ingredient,
                                  index: index,
                                );
                                return false;
                              } else if (direction ==
                                  DismissDirection.endToStart) {
                                // Delete
                                final confirm = await showCustomConfirmDialog(
                                  context: context,
                                  title: 'Delete Grocery Item',
                                  message:
                                      'Are you sure you want to delete this item?',
                                  confirmText: 'Delete',
                                  cancelText: 'Cancel',
                                  isDestructive: true,
                                  icon: Icons.delete,
                                );
                                if (confirm == true) {
                                  setState(() {
                                    _shoppingList.removeAt(index);
                                  });
                                  await showCustomInfoDialog(
                                    context: context,
                                    title: 'Deleted',
                                    message:
                                        'Grocery item deleted successfully.',
                                    icon: Icons.check_circle,
                                  );
                                  return true;
                                }
                                return false;
                              }
                              return false;
                            },
                            child: _GroceryCard(
                              ingredient: ingredient,
                              onTap: () {},
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroceryCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;
  const _GroceryCard({required this.ingredient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Checkbox(
                value: ingredient.isOwned,
                onChanged: (_) {}, // Optionally implement mark as purchased
                activeColor: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8B8B8B)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddGrocerySheet extends StatefulWidget {
  final Function(Ingredient) onAdd;
  final Ingredient? initial;
  const _AddGrocerySheet({required this.onAdd, this.initial});
  @override
  State<_AddGrocerySheet> createState() => _AddGrocerySheetState();
}

class _AddGrocerySheetState extends State<_AddGrocerySheet> {
  final _nameController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameController.text = widget.initial!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addIngredient() async {
    if (_nameController.text.isEmpty) return;
    setState(() {
      _isAdding = true;
    });
    final ingredient = Ingredient(
      name: _nameController.text.trim(),
      isOwned: false,
    );
    await widget.onAdd(ingredient);
    if (mounted) {
      setState(() {
        _isAdding = false;
      });
      Navigator.of(context).pop();
      await showCustomInfoDialog(
        context: context,
        title: 'Success',
        message: 'Grocery item added successfully.',
        icon: Icons.check_circle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Grocery Item',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAdding ? null : _addIngredient,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isAdding
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Add Grocery Item',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
