import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/barcode_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _barcodeService = BarcodeService();
  bool _isScanning = false;
  Ingredient? _scannedIngredient;
  String? _errorMessage;
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
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _scannedIngredient = null;
    });

    try {
      final barcode = await _barcodeService.scanBarcode();
      if (barcode == null) {
        throw Exception('Failed to scan barcode');
      }

      final ingredient = await _barcodeService.getProductFromBarcode(barcode);
      if (ingredient == null) {
        throw Exception('Product not found for barcode: $barcode');
      }

      setState(() {
        _scannedIngredient = ingredient;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final currentDate =
        _expiryController.text.isNotEmpty
            ? DateTime.parse(_expiryController.text)
            : DateTime.now().add(const Duration(days: 7));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedDate != null) {
      setState(() {
        _expiryController.text = pickedDate.toIso8601String().split('T').first;
      });
    }
  }

  void _addToInventory() {
    if (_scannedIngredient == null) return;

    // Create a new ingredient with the updated expiry date
    final updatedIngredient = Ingredient(
      name: _scannedIngredient!.name,
      quantity: _scannedIngredient!.quantity,
      unit: _scannedIngredient!.unit,
      isOwned: true,
      expiryDate: DateTime.parse(_expiryController.text),
    );

    // Return the ingredient to the calling screen
    Navigator.of(context).pop(updatedIngredient);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF97B380),
      appBar: AppBar(
        title: const Text(
          'Scan Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isScanning)
                        Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            const Text(
                              'Scanning...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else if (_scannedIngredient != null)
                        Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 60,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _scannedIngredient!.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_scannedIngredient!.quantity} ${_scannedIngredient!.unit}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 30),
                            const Text(
                              'Set Expiry Date',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: _selectExpiryDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _addToInventory,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 16,
                                ),
                                backgroundColor: const Color(0xFF97B380),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Add to Inventory'),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            const Icon(
                              Icons.qr_code_scanner,
                              size: 100,
                              color: Color(0xFF97B380),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Scan barcode to add product',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Position the barcode within the frame to scan',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 20),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _scanBarcode,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 16,
                                ),
                                backgroundColor: const Color(0xFF97B380),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Start Scanning'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
