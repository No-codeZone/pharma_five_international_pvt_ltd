import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class BulkUploadWidget extends StatelessWidget {
  final Function(File file) onFileSelected;

  const BulkUploadWidget({Key? key, required this.onFileSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Upload Bulk Products",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['xlsx'],
                );
                if (result != null && result.files.single.path != null) {
                  final file = File(result.files.single.path!);
                  onFileSelected(file);
                  Navigator.pop(context); // Close the dialog
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32,horizontal: 64),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/bulk_upload.png', // your upload icon
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(height: 8),
                    const Text("Drag and Drop here",
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                    const SizedBox(height: 4),
                    const Text("Or",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, color: Colors.black)),
                    const SizedBox(height: 4),
                    const Text(
                      "Browse",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff185794)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
