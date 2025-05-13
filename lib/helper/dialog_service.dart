import 'package:flutter/material.dart';

class DialogService {
  static void showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
    Color confirmColor = Colors.green,
    String confirmText = 'Confirm',
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          content: Text(
            content,
            textAlign: TextAlign.center,
          ),
          actions: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCancelButton(context),
                const Expanded(child: SizedBox(width: 80)),
                _buildConfirmButton(
                    context,
                    onConfirm,
                    confirmText,
                    confirmColor
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))
          ),
          side: const BorderSide(color: Color(0xff262A88)),
        ),
        child: const Text('Cancel'),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  static Widget _buildConfirmButton(
      BuildContext context,
      VoidCallback onConfirm,
      String text,
      Color color
      ) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))
          ),
        ),
        child: Text(text),
        onPressed: () {
          Navigator.of(context).pop();
          onConfirm();
        },
      ),
    );
  }
}