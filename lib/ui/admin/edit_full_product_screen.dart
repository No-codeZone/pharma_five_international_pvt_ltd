import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../model/update_product_listing_request_model.dart';
import '../../service/api_service.dart';

class EditFullProductScreen extends StatefulWidget {
  final UpdateProductListingRequestModel product;

  const EditFullProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<EditFullProductScreen> createState() => _EditFullProductScreenState();
}

class _EditFullProductScreenState extends State<EditFullProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late UpdateProductListingRequestModel updatedProduct;
  bool _isUpdating = false;
  bool _isLoadingAccordions = true;

  @override
  void initState() {
    super.initState();
    updatedProduct = UpdateProductListingRequestModel.fromJson(widget.product.toJson());

    // Simulate fetch delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoadingAccordions = false;
        });
      }
    });
  }

  Widget _buildTextField(String label, String? value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          maxLines: null,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: const Color(0xfff5f5f5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xff185794), width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildShimmerBlock({int lines = 3}) {
    return Column(
      children: List.generate(lines, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 20.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAccordion<T>({
    required String title,
    required List<T>? items,
    required Widget Function(T item, int index) itemBuilder,
  }) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: items
          .asMap()
          .entries
          .map((entry) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: itemBuilder(entry.value, entry.key),
      ))
          .toList(),
    );
  }

  Widget _buildPackSizeEditor(PackSizesRequest packSize, int index) {
    return Column(
      children: [
        _buildTextField("Strength", packSize.strength, (val) => packSize.strength = val),
        _buildTextField("Pack Size", packSize.packSize, (val) => packSize.packSize = val),
        _buildTextField("Storage", packSize.storage, (val) => packSize.storage = val),
      ],
    );
  }

  Widget _buildDrugInteractionEditor(DrugInteractionsRequest interaction, int index) {
    return Column(
      children: [
        _buildTextField("Drug", interaction.drug, (val) => interaction.drug = val),
        _buildTextField("Interaction", interaction.interaction, (val) => interaction.interaction = val),
      ],
    );
  }

  Widget _buildBrandPrescriptionEditor(BrandPrescriptionsRequest prescription, int index) {
    return Column(
      children: [
        _buildTextField("Dosage", prescription.dosage, (val) => prescription.dosage = val),
        _buildTextField("Strength", prescription.strength, (val) => prescription.strength = val),
        _buildTextField("Route", prescription.route, (val) => prescription.route = val),
        _buildTextField("Labeller", prescription.labeller, (val) => prescription.labeller = val),
        _buildTextField("Marketing Start", prescription.marketingStart, (val) => prescription.marketingStart = val),
        _buildTextField("Marketing End", prescription.marketingEnd, (val) => prescription.marketingEnd = val),
      ],
    );
  }

  // Add this method to your EditFullProductScreen class
  void _validateDataBeforeSubmit() {
    // Check for empty required fields that might cause API errors
    List<String> missingFields = [];

    if (updatedProduct.medicineName == null || updatedProduct.medicineName!.isEmpty) {
      missingFields.add("Medicine Name");
    }

    if (updatedProduct.genericName == null || updatedProduct.genericName!.isEmpty) {
      missingFields.add("Generic Name");
    }

    // Validate serialNo - this is critical
    if (updatedProduct.serialNo == null) {
      print("WARNING: serialNo is null - this will likely cause an update failure");
    }

    // Check other potential issues
    if (updatedProduct.packSizes != null) {
      for (var packSize in updatedProduct.packSizes!) {
        if (packSize.id == null) {
          print("WARNING: Pack Size has null ID - this may cause update issues");
        }
      }
    }

    if (updatedProduct.drugInteractions != null) {
      for (var interaction in updatedProduct.drugInteractions!) {
        if (interaction.id == null) {
          print("WARNING: Drug Interaction has null ID - this may cause update issues");
        }
      }
    }

    if (updatedProduct.brandPrescriptions != null) {
      for (var prescription in updatedProduct.brandPrescriptions!) {
        if (prescription.id == null) {
          print("WARNING: Brand Prescription has null ID - this may cause update issues");
        }
      }
    }

    // Print validation results
    if (missingFields.isEmpty) {
      print("Request validation: All required fields appear to be present");
    } else {
      print("Request validation: Missing required fields: ${missingFields.join(', ')}");
    }

    // Print full request model for inspection
    final requestJson = updatedProduct.toJson();
    print("Full request model for validation:");
    print(const JsonEncoder.withIndent('  ').convert(requestJson));
  }

// Now modify your _submit method to include this validation
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Add validation before submitting
    _validateDataBeforeSubmit();

    setState(() => _isUpdating = true);
    final response = await ApiService().updateProductListing(updatedProduct);
    setState(() => _isUpdating = false);

    if (response != null) {
      if (response.status == 1 || response.serialNo != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          ),
        );
        Navigator.pop(context, true);
      } else {
        // Show the error message from the API if available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.medicineName ?? 'Failed to update product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update product: No response from server'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar("Edit Product"), // Your custom top bar with back and menu
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTextField("Medicine Name", updatedProduct.medicineName, (val) => updatedProduct.medicineName = val),
                    _buildTextField("Generic Name", updatedProduct.genericName, (val) => updatedProduct.genericName = val),
                    _buildTextField("Manufactured By", updatedProduct.manufacturedBy, (val) => updatedProduct.manufacturedBy = val),
                    _buildTextField("Indication", updatedProduct.indication, (val) => updatedProduct.indication = val),
                    _buildTextField("Reference Link", updatedProduct.referenceLink, (val) => updatedProduct.referenceLink = val),
                    _buildTextField("Medical Field", updatedProduct.medicalField, (val) => updatedProduct.medicalField = val),
                    _buildTextField("Summary", updatedProduct.summary, (val) => updatedProduct.summary = val),
                    _buildTextField("Brand Names", updatedProduct.brandNames, (val) => updatedProduct.brandNames = val),
                    _buildTextField("Background", updatedProduct.background, (val) => updatedProduct.background = val),
                    _buildTextField("Type", updatedProduct.type, (val) => updatedProduct.type = val),
                    _buildTextField("Groups", updatedProduct.groups, (val) => updatedProduct.groups = val),
                    _buildTextField("Chemical Formula", updatedProduct.chemicalFormula, (val) => updatedProduct.chemicalFormula = val),
                    _buildTextField("Synonyms", updatedProduct.synonyms, (val) => updatedProduct.synonyms = val),
                    _buildTextField("Biologic Classification", updatedProduct.biologicClassification, (val) => updatedProduct.biologicClassification = val),
                    _buildTextField("Pharmacodynamics", updatedProduct.pharmacodynamics, (val) => updatedProduct.pharmacodynamics = val),
                    _buildTextField("Mechanism of Action", updatedProduct.mechanismOfAction, (val) => updatedProduct.mechanismOfAction = val),
                    _buildTextField("Absorption", updatedProduct.absorption, (val) => updatedProduct.absorption = val),
                    _buildTextField("Metabolism", updatedProduct.metabolism, (val) => updatedProduct.metabolism = val),
                    _buildTextField("Route of Elimination", updatedProduct.routeOfElimination, (val) => updatedProduct.routeOfElimination = val),
                    _buildTextField("Half Life", updatedProduct.halfLife, (val) => updatedProduct.halfLife = val),
                    _buildTextField("Clearance", updatedProduct.clearance, (val) => updatedProduct.clearance = val),
                    _buildTextField("Toxicity", updatedProduct.toxicity, (val) => updatedProduct.toxicity = val),
                    _buildTextField("Food Interactions", updatedProduct.foodInteractions, (val) => updatedProduct.foodInteractions = val),
                    _buildTextField("Drug Categories", updatedProduct.drugCategories, (val) => updatedProduct.drugCategories = val),

                    _isLoadingAccordions
                        ? Column(
                      children: [
                        _buildShimmerBlock(lines: 3),
                        const SizedBox(height: 12),
                        _buildShimmerBlock(lines: 2),
                        const SizedBox(height: 12),
                        _buildShimmerBlock(lines: 6),
                      ],
                    )
                        : Column(
                      children: [
                        _buildAccordion<PackSizesRequest>(
                          title: "Pack Sizes",
                          items: updatedProduct.packSizes,
                          itemBuilder: _buildPackSizeEditor,
                        ),
                        _buildAccordion<DrugInteractionsRequest>(
                          title: "Drug Interactions",
                          items: updatedProduct.drugInteractions,
                          itemBuilder: _buildDrugInteractionEditor,
                        ),
                        _buildAccordion<BrandPrescriptionsRequest>(
                          title: "Brand Prescriptions",
                          items: updatedProduct.brandPrescriptions,
                          itemBuilder: _buildBrandPrescriptionEditor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isUpdating ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff185794),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isUpdating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Update", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(String? title) {
    return Padding(
      padding: const EdgeInsets.only(top: 44, left: 12, right: 12, bottom: 10),
      child: Row(
        children: [
          // Back Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xff185794),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200, width: 3),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              title ?? '-',
              style: const TextStyle(
                color: Color(0xff185794),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Menu Options
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'close') Navigator.pop(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'close',
                child: ListTile(
                  leading: Icon(Icons.close),
                  title: Text('Close Details'),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Color(0xff185794)),
          ),
        ],
      ),
    );
  }
}