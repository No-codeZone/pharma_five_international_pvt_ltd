import 'package:flutter/material.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({Key? key}) : super(key: key);

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final _medicineController = TextEditingController();
  final _genericController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _indicationsController = TextEditingController();

  @override
  void dispose() {
    _medicineController.dispose();
    _genericController.dispose();
    _manufacturerController.dispose();
    _indicationsController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xff185794)!),
          ),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Header with logo and back
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.blue)),
                  Image.asset('assets/images/pharmafive_512x512.png',
                      width: 60, height: 60),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Add Products',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black),
              ),
              const SizedBox(height: 20),
              _buildTextField("Medicine name", _medicineController),
              _buildTextField("Generic name", _genericController),
              _buildTextField("Manufactured By", _manufacturerController),
              _buildTextField("Indications", _indicationsController),

              SizedBox(height: 10),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff185794),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  debugPrint("Add button clicked");
                },
                child: const Text('Add',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),

              const SizedBox(height: 12),
              const Text("Or", style: TextStyle(fontWeight: FontWeight.w600)),

              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  debugPrint("Upload bulk product clicked");
                },
                child: const Text('Upload Bulk Products',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),

              const Spacer(),

              // Bottom navigation
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blue, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}