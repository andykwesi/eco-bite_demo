import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/firestore_service.dart';
import '../widgets/error_dialog.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  List<Ingredient> _ingredients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPantry();
  }

  Future<void> _fetchPantry() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _firestoreService.fetchPantry();
      setState(() {
        _ingredients = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load pantry.';
        _isLoading = false;
      });
    }
  }

  List<Ingredient> get _filteredIngredients {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _ingredients;
    return _ingredients.where((ingredient) {
      return ingredient.name.toLowerCase().contains(query);
    }).toList();
  }

  void _showAddIngredientSheet({Ingredient? ingredient, int? index}) {
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
            child: _AddIngredientSheet(
              onAdd: (newIngredient) {
                setState(() {
                  if (ingredient != null && index != null) {
                    _ingredients[index] = newIngredient;
                  } else {
                    _ingredients.add(newIngredient);
                  }
                });
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
          'Pantry',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF4CAF50)),
            onPressed: () => _showAddIngredientSheet(),
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
                          hintText: 'Search pantry...',
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
                      : _filteredIngredients.isEmpty
                      ? const Center(
                        child: Text('No ingredients in your pantry.'),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _filteredIngredients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ingredient = _filteredIngredients[index];
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
                                _showAddIngredientSheet(
                                  ingredient: ingredient,
                                  index: index,
                                );
                                return false;
                              } else if (direction ==
                                  DismissDirection.endToStart) {
                                // Delete
                                final confirm = await showCustomConfirmDialog(
                                  context: context,
                                  title: 'Delete Ingredient',
                                  message:
                                      'Are you sure you want to delete this ingredient?',
                                  confirmText: 'Delete',
                                  cancelText: 'Cancel',
                                  isDestructive: true,
                                  icon: Icons.delete,
                                );
                                if (confirm == true) {
                                  setState(() {
                                    _ingredients.removeAt(index);
                                  });
                                  await showCustomInfoDialog(
                                    context: context,
                                    title: 'Deleted',
                                    message: 'Ingredient deleted successfully.',
                                    icon: Icons.check_circle,
                                  );
                                  return true;
                                }
                                return false;
                              }
                              return false;
                            },
                            child: _IngredientCard(
                              ingredient: ingredient,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => _IngredientDetailsDialog(
                                        ingredient: ingredient,
                                        onDelete: () {
                                          setState(() {
                                            _ingredients.removeWhere(
                                              (i) => i.name == ingredient.name,
                                            );
                                          });
                                        },
                                      ),
                                );
                              },
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

class _IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;
  const _IngredientCard({required this.ingredient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (ingredient.isExpired) {
      statusColor = Colors.red;
    } else if (ingredient.isExpiring) {
      statusColor = Colors.orange;
    } else {
      statusColor = const Color(0xFF4CAF50);
    }
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
              Container(
                width: 12,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (ingredient.quantity != null)
                          Text(
                            '${ingredient.quantity} ',
                            style: const TextStyle(fontSize: 14),
                          ),
                        if (ingredient.unit != null)
                          Text(
                            ingredient.unit!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        if (ingredient.quantity != null ||
                            ingredient.unit != null)
                          const SizedBox(width: 8),
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Color(0xFF8B8B8B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ingredient.expiryDate != null
                              ? '${ingredient.expiryDate!.year}-${ingredient.expiryDate!.month.toString().padLeft(2, '0')}-${ingredient.expiryDate!.day.toString().padLeft(2, '0')}'
                              : 'No expiry',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                      ],
                    ),
                  ],
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

class _AddIngredientSheet extends StatefulWidget {
  final Function(Ingredient) onAdd;
  final Ingredient? initial;
  const _AddIngredientSheet({required this.onAdd, this.initial});
  @override
  State<_AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<_AddIngredientSheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _expiryController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameController.text = widget.initial!.name;
      _quantityController.text = widget.initial!.quantity?.toString() ?? '';
      _unitController.text = widget.initial!.unit ?? '';
      _expiryController.text =
          widget.initial!.expiryDate?.toIso8601String().split('T').first ??
          DateTime.now()
              .add(const Duration(days: 7))
              .toIso8601String()
              .split('T')
              .first;
    } else {
      _expiryController.text =
          DateTime.now()
              .add(const Duration(days: 7))
              .toIso8601String()
              .split('T')
              .first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final currentDate =
        _expiryController.text.isNotEmpty
            ? DateTime.parse(_expiryController.text)
            : DateTime.now().add(const Duration(days: 7));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null) {
      setState(() {
        _expiryController.text = pickedDate.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _addIngredient() async {
    if (_nameController.text.isEmpty) return;
    setState(() {
      _isAdding = true;
    });
    double? quantity;
    if (_quantityController.text.isNotEmpty) {
      quantity = double.tryParse(_quantityController.text);
    }
    final ingredient = Ingredient(
      name: _nameController.text,
      isOwned: true,
      quantity: quantity,
      unit: _unitController.text.isEmpty ? null : _unitController.text,
      expiryDate: DateTime.parse(_expiryController.text),
    );
    try {
      await FirestoreService().addPantryItem(ingredient);
      if (mounted) {
        Navigator.of(context).pop();
        await showCustomInfoDialog(
          context: context,
          title: 'Success',
          message: 'Ingredient added successfully.',
          icon: Icons.check_circle,
        );
        widget.onAdd(ingredient);
      }
    } catch (e) {
      if (mounted) {
        await showCustomInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to add: $e',
          icon: Icons.error,
          isDestructive: true,
        );
      }
    } finally {
      if (mounted)
        setState(() {
          _isAdding = false;
        });
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
            'Add Ingredient',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Expiry Date'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectExpiryDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _expiryController.text,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Icon(Icons.calendar_today),
                ],
              ),
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
                        'Add Ingredient',
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

class _IngredientDetailsDialog extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onDelete;

  const _IngredientDetailsDialog({
    required this.ingredient,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(ingredient.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ingredient.quantity != null) ...[
            const Text(
              'Quantity:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${ingredient.quantity} ${ingredient.unit ?? ''}'),
            const SizedBox(height: 8),
          ],
          const Text(
            'Expiry Date:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            ingredient.expiryDate != null
                ? '${ingredient.expiryDate!.year}-${ingredient.expiryDate!.month.toString().padLeft(2, '0')}-${ingredient.expiryDate!.day.toString().padLeft(2, '0')}'
                : 'Not set',
            style: TextStyle(
              color:
                  ingredient.isExpired
                      ? Colors.red
                      : ingredient.isExpiring
                      ? Colors.orange
                      : null,
            ),
          ),
          if (ingredient.isExpired || ingredient.isExpiring) ...[
            const SizedBox(height: 8),
            Text(
              ingredient.expiryStatus,
              style: TextStyle(
                color: ingredient.isExpired ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            onDelete();
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
