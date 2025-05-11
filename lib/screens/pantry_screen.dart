import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../widgets/ingredient_list_item.dart';
import 'barcode_scanner_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Ingredient> _ingredients = [
    Ingredient(
      name: 'Butter',
      isOwned: true,
      expiryDate: DateTime.now().add(const Duration(days: 14)),
      quantity: 250,
      unit: 'g',
    ),
    Ingredient(
      name: 'Dried Red Chillies',
      isOwned: true,
      expiryDate: DateTime.now().add(const Duration(days: 90)),
    ),
    Ingredient(
      name: 'Gluten Free Tamari',
      isOwned: true,
      expiryDate: DateTime.now().add(const Duration(days: 180)),
      quantity: 500,
      unit: 'ml',
    ),
    Ingredient(
      name: 'Olive Oil',
      isOwned: true,
      expiryDate: DateTime.now().add(const Duration(days: 365)),
      quantity: 750,
      unit: 'ml',
    ),
    Ingredient(
      name: 'Taco Seasoning',
      isOwned: true,
      expiryDate: DateTime.now().add(const Duration(days: 120)),
      quantity: 50,
      unit: 'g',
    ),
    Ingredient(
      name: 'Vegetable Stock',
      isOwned: true,
      expiryDate: DateTime.now().add(const Duration(days: 2)),
      quantity: 1,
      unit: 'L',
    ),
    Ingredient(
      name: 'White Cabbage',
      isOwned: true,
      expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      quantity: 1,
      unit: 'pcs',
    ),
  ];

  List<Ingredient> get _filteredIngredients {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _ingredients;

    return _ingredients.where((ingredient) {
      return ingredient.name.toLowerCase().contains(query);
    }).toList();
  }

  // Sort the ingredients with expiring ones first
  List<Ingredient> get _sortedIngredients {
    final sorted = List<Ingredient>.from(_filteredIngredients);
    sorted.sort((a, b) {
      // First, sort by expiry status (expired first, then expiring)
      if (a.isExpired && !b.isExpired) return -1;
      if (!a.isExpired && b.isExpired) return 1;
      if (a.isExpiring && !b.isExpiring && !b.isExpired) return -1;
      if (!a.isExpiring && !a.isExpired && b.isExpiring) return 1;

      // Then sort by expiry date (soonest first)
      if (a.expiryDate != null && b.expiryDate != null) {
        return a.expiryDate!.compareTo(b.expiryDate!);
      }

      // Items without expiry dates go last
      if (a.expiryDate == null && b.expiryDate != null) return 1;
      if (a.expiryDate != null && b.expiryDate == null) return -1;

      // If all else is equal, sort alphabetically
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (result != null) {
      setState(() {
        _ingredients.add(result);
      });
    }
  }

  void _addManually() {
    // Show dialog to add ingredient manually
    showDialog(
      context: context,
      builder:
          (context) => _AddIngredientDialog(
            onAdd: (ingredient) {
              setState(() {
                _ingredients.add(ingredient);
              });
            },
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
      backgroundColor: const Color(0xFF97B380),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Your Pantry',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Add Your Ingredients',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search garlic...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 20,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),

                      // Expiry alerts section
                      if (_sortedIngredients.any(
                        (i) => i.isExpired || i.isExpiring,
                      ))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Expiring soon',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_sortedIngredients.where((i) => i.isExpired).length} expired, ${_sortedIngredients.where((i) => i.isExpiring && !i.isExpired).length} expiring soon',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Expanded(
                        child: ListView.builder(
                          itemCount: _sortedIngredients.length,
                          itemBuilder: (context, index) {
                            final ingredient = _sortedIngredients[index];
                            return IngredientListItem(
                              ingredient: ingredient,
                              onTap: () {
                                // Show ingredient details
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
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'scan') {
                                  _scanBarcode();
                                } else if (value == 'manual') {
                                  _addManually();
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'scan',
                                      child: Row(
                                        children: [
                                          Icon(Icons.qr_code_scanner),
                                          SizedBox(width: 8),
                                          Text('Scan Barcode'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'manual',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Add Manually'),
                                        ],
                                      ),
                                    ),
                                  ],
                              child: ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Ingredient'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Show sorting options
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Sort By'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              title: const Text('Expiry Date'),
                                              onTap: () {
                                                Navigator.of(context).pop();
                                                // Already sorted by expiry by default
                                              },
                                            ),
                                            ListTile(
                                              title: const Text('Name'),
                                              onTap: () {
                                                Navigator.of(context).pop();
                                                setState(() {
                                                  _ingredients.sort(
                                                    (a, b) => a.name.compareTo(
                                                      b.name,
                                                    ),
                                                  );
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                );
                              },
                              icon: const Icon(Icons.sort),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddIngredientDialog extends StatefulWidget {
  final Function(Ingredient) onAdd;

  const _AddIngredientDialog({required this.onAdd});

  @override
  State<_AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<_AddIngredientDialog> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _expiryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default expiry date to 7 days from now
    _expiryController.text =
        DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String()
            .split('T')
            .first;
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
      firstDate: DateTime.now().subtract(
        const Duration(days: 30),
      ), // Allow backdating a month
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedDate != null) {
      setState(() {
        _expiryController.text = pickedDate.toIso8601String().split('T').first;
      });
    }
  }

  void _addIngredient() {
    if (_nameController.text.isEmpty) return;

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

    widget.onAdd(ingredient);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Ingredient'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addIngredient,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF97B380),
          ),
          child: const Text('Add'),
        ),
      ],
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
