import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final IconData? icon;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 48,
                color: isDestructive ? Colors.red : const Color(0xFF4CAF50),
              ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (cancelText != null)
                  TextButton(
                    onPressed:
                        onCancel ?? () => Navigator.of(context).pop(false),
                    child: Text(cancelText!),
                  ),
                ElevatedButton(
                  onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDestructive ? Colors.red : const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(confirmText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showCustomConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    builder:
        (context) => CustomAlertDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          isDestructive: isDestructive,
          icon: icon,
        ),
  );
}

Future<void> showCustomInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'OK',
  IconData? icon,
  bool isDestructive = false,
}) {
  return showDialog<void>(
    context: context,
    builder:
        (context) => CustomAlertDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          isDestructive: isDestructive,
          icon: icon,
        ),
  );
}
