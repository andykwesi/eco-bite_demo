import 'package:flutter/material.dart';
import '../models/ingredient.dart';

import '../services/firestore_service.dart';
import '../widgets/error_dialog.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  List<Ingredient> _shoppingList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchGroceryList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen gains focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchGroceryList();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload data when app becomes visible
      _fetchGroceryList();
    }
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
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: AlertDialog(
                        backgroundColor: Colors.white,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              ingredient != null
                                  ? 'Updating item...'
                                  : 'Adding item...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );

                try {
                  setState(() {
                    if (ingredient != null && index != null) {
                      _shoppingList[index] = newIngredient;
                    } else {
                      _shoppingList.add(newIngredient);
                    }
                  });

                  if (ingredient != null && index != null) {
                    await _firestoreService.updateGroceryItem(
                      ingredient.name,
                      newIngredient,
                    );
                  } else {
                    await _firestoreService.addGroceryItem(newIngredient);
                  }

                  // Close loading dialog
                  if (mounted) {
                    Navigator.of(context).pop();
                  }

                  // Close bottom sheet
                  if (mounted) {
                    Navigator.of(context).pop();
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ingredient != null
                              ? 'Item updated successfully!'
                              : 'Item added successfully!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  if (mounted) {
                    Navigator.of(context).pop();
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to ${ingredient != null ? 'update' : 'add'} item: $e',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              initial: ingredient,
            ),
          ),
    );
  }

  void _showMoveToPantryModal(Ingredient ingredient, int index) {
    showDialog(
      context: context,
      builder:
          (context) => _MoveToPantryDialog(
            ingredient: ingredient,
            onMove: (pantryIngredient) async {
              try {
                // Add to pantry
                await _firestoreService.addPantryItem(pantryIngredient);

                // Remove from grocery list
                await _firestoreService.deleteGroceryItem(ingredient.name);

                // Update local state
                setState(() {
                  _shoppingList.removeAt(index);
                });

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${ingredient.name} moved to pantry!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to move to pantry: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
    );
  }

  Future<void> _deleteGroceryItem(int index) async {
    final ingredient = _shoppingList[index];
    final confirm = await showCustomConfirmDialog(
      context: context,
      title: 'Delete Grocery Item',
      message: 'Are you sure you want to delete "${ingredient.name}"?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
      icon: Icons.delete,
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteGroceryItem(ingredient.name);
        setState(() {
          _shoppingList.removeAt(index);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grocery item deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchGroceryList,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : _filteredShoppingList.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No items in your grocery list.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add some ingredients to get started!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _fetchGroceryList,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _filteredShoppingList.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
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
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
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
                                  await _deleteGroceryItem(index);
                                  return true;
                                }
                                return false;
                              },
                              child: _GroceryCard(
                                ingredient: ingredient,
                                onTap: () {},
                                onCheckChanged: (isChecked) {
                                  if (isChecked) {
                                    _showMoveToPantryModal(ingredient, index);
                                  }
                                },
                              ),
                            );
                          },
                        ),
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
  final Function(bool)? onCheckChanged;

  const _GroceryCard({
    required this.ingredient,
    required this.onTap,
    this.onCheckChanged,
  });

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
                onChanged: (value) {
                  if (onCheckChanged != null) {
                    onCheckChanged!(value ?? false);
                  }
                },
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

class _MoveToPantryDialog extends StatefulWidget {
  final Ingredient ingredient;
  final Function(Ingredient) onMove;

  const _MoveToPantryDialog({required this.ingredient, required this.onMove});

  @override
  State<_MoveToPantryDialog> createState() => _MoveToPantryDialogState();
}

class _MoveToPantryDialogState extends State<_MoveToPantryDialog> {
  final _quantityController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: 'piece');
  DateTime? _selectedExpiryDate;
  bool _isMoving = false;

  final List<String> _commonUnits = [
    'piece',
    'cup',
    'tablespoon',
    'teaspoon',
    'gram',
    'kilogram',
    'ounce',
    'pound',
    'liter',
    'milliliter',
    'can',
    'bottle',
    'pack',
    'bunch',
    'head',
    'clove',
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  Future<void> _moveToPantry() async {
    if (_quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a quantity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isMoving = true;
    });

    try {
      final quantity = double.tryParse(_quantityController.text.trim()) ?? 1.0;

      final pantryIngredient = Ingredient(
        name: widget.ingredient.name,
        isOwned: true,
        quantity: quantity,
        unit: _unitController.text.trim(),
        expiryDate: _selectedExpiryDate,
      );

      await widget.onMove(pantryIngredient);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMoving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.kitchen, color: Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          const Text('Move to Pantry'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add "${widget.ingredient.name}" to your pantry:',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Quantity
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
                hintText: '1',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Unit
            DropdownButtonFormField<String>(
              value: _unitController.text,
              decoration: const InputDecoration(
                labelText: 'Unit',
                border: OutlineInputBorder(),
              ),
              items:
                  _commonUnits.map((unit) {
                    return DropdownMenuItem(value: unit, child: Text(unit));
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _unitController.text = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Expiry Date
            InkWell(
              onTap: _selectExpiryDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedExpiryDate != null
                            ? 'Expires: ${_selectedExpiryDate!.toIso8601String().split('T').first}'
                            : 'Select expiry date (optional)',
                        style: TextStyle(
                          color:
                              _selectedExpiryDate != null
                                  ? Colors.black
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isMoving ? null : _moveToPantry,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
          ),
          child:
              _isMoving
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Move to Pantry'),
        ),
      ],
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.initial != null ? 'Edit Grocery Item' : 'Add Grocery Item',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                      : Text(
                        widget.initial != null
                            ? 'Update Item'
                            : 'Add Grocery Item',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
