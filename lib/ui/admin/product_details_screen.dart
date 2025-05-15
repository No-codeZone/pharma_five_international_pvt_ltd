import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pharma_five/model/product_search_listing_response_model.dart';
import 'package:pharma_five/ui/admin/widget/reference_web_view_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../../helper/shared_preferences.dart';
import '../../model/get_product_more_response_model.dart';
import '../../model/request_enquiry_model.dart';
import '../../service/api_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final GetProductsContent getProductsContent;

  const ProductDetailsScreen({Key? key, required this.getProductsContent}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int? _expandedIndex;
  bool _isLoadingDrugInteractions = false;
  bool _isLoadingBrandPrescriptions = false;
  bool _isLoadingPackSizes = false;
  bool _showAllDrugInteractions = false;

  // For tracking highlighted rows
  int? _highlightedPackSizeIndex;
  int? _highlightedDrugInteractionIndex;
  int? _highlightedBrandPrescriptionIndex;

  @override
  void dispose() {
    super.dispose(); // Clean up if needed
  }

  Widget _buildSection(int index, String title, bool isLoading,
      Future<void> Function()? onExpand, Widget content) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: _expandedIndex == index,
        onExpansionChanged: (expanded) async {
          setState(() => _expandedIndex = expanded ? index : null);
          if (expanded && onExpand != null && mounted) {
            await onExpand();
            if (mounted) setState(() {});
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: isLoading ? _buildShimmer() : content,
          ),
        ],
      ),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _submitEnquiry() async {
    final empId = await SharedPreferenceHelper.getUserSno(); // Get logged-in user sno
    final productId = widget.getProductsContent.serialNo;   // Treat serialNo as productId
    print("empID/viewMore\t${empId}");
    print("productID/viewMore\t${productId}");
    if (empId == null || productId == null) {
      _showToast("Something went wrong!",isError: true);
      return;
    }

    final request = RequestEnquiryModel(empId: empId, productId: productId);

    try {
      final response = await ApiService().submitEnquiry(request);
      if (response != null) {
        _showToast("${response.responseMessage}",isError: false);
      } else {
        _showToast("Something went wrong!",isError: true);
      }
    } catch (e) {
      _showToast("${e.toString()}",isError: true);
    }
  }


  @override
  Widget build(BuildContext context) {
    final p = widget.getProductsContent;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(p.medicineName),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductDetails(p),
                      _buildSection(
                        1,
                        "Pack Sizes",
                        _isLoadingPackSizes,
                            () async {
                          if (mounted) {
                            setState(() => _isLoadingPackSizes = true);
                            await Future.delayed(const Duration(seconds: 1));
                            if (mounted) setState(() => _isLoadingPackSizes = false);
                          }
                        },
                        _buildPackSizes(p),
                      ),
                      _buildSection(
                        2,
                        "Drug Interactions",
                        _isLoadingDrugInteractions,
                            () async {
                          if (mounted) {
                            setState(() => _isLoadingDrugInteractions = true);
                            await Future.delayed(const Duration(seconds: 1));
                            if (mounted) setState(() => _isLoadingDrugInteractions = false);
                          }
                        },
                        _buildDrugInteractions(p),
                      ),
                      _buildSection(
                        3,
                        "Brand Prescriptions",
                        _isLoadingBrandPrescriptions,
                            () async {
                          if (mounted) {
                            setState(() => _isLoadingBrandPrescriptions = true);
                            await Future.delayed(const Duration(seconds: 1));
                            if (mounted) setState(() => _isLoadingBrandPrescriptions = false);
                          }
                        },
                        _buildBrandPrescriptions(p),
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

  Widget _buildTopBar(String? title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
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
              tooltip: 'Back',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title ?? '-',
              style: const TextStyle(
                color: Color(0xff185794),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Improved enquiry button with text
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xff185794),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _submitEnquiry();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Text(
                        'Enquiry',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(GetProductsContent p) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xff185794).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Color(0xff185794),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.medicineName ?? '-',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff185794),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.genericName ?? '-',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            if (p.indication != null && p.indication!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Indication",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xff185794),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.indication!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            if (p.manufacturedBy != null && p.manufacturedBy!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Color(0xff185794)),
                  const SizedBox(width: 6),
                  Text(
                    p.manufacturedBy!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String key, String? value) {
    if (value == null || value.trim().isEmpty || value.trim().toUpperCase() == "-NA") {
      return const SizedBox.shrink();
    }

    final isReferenceLink = key == "Reference Link";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: Colors.white.withOpacity(0.95),
        title: Text(
          key,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xff185794),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: isReferenceLink
              ? GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReferenceWebViewScreen(url: value),
                ),
              );
            },
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          )
              : Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductDetails(GetProductsContent p) {
    final fields = {
      "Summary": p.summary,
      "Background": p.background,
      "Type": p.type,
      "Groups": p.groups,
      "Chemical Formula": p.chemicalFormula,
      "Synonyms": p.synonyms,
      "Biologic Classification": p.biologicClassification,
      "Pharmacodynamics": p.pharmacodynamics,
      "Mechanism of Action": p.mechanismOfAction,
      "Absorption": p.absorption,
      "Metabolism": p.metabolism,
      "Route of Elimination": p.routeOfElimination,
      "Half Life": p.halfLife,
      "Clearance": p.clearance,
      "Toxicity": p.toxicity,
      "Food Interactions": p.foodInteractions,
      "Drug Categories": p.drugCategories,
      "Reference Link": p.referenceLink,
    };

    final filteredFields = fields.entries.where((entry) {
      final val = entry.value?.trim().toUpperCase();
      return val != null && val.isNotEmpty && val != "-NA";
    });

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: const Text(
          "Product Information",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xff185794),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GENERIC & INDICATION
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xff185794).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: Color(0xff185794),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Generic Name",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff185794),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.genericName ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Indication block
                if (p.indication != null && p.indication!.isNotEmpty) ...[
                  const Text(
                    "Indication",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xff185794),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.indication!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // —— Your DISCLAIMER ——
                  // … inside your _buildProductDetails Column, after the Indication …
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffffecb5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        // Header stays at default bold size (inherited from Theme or ~14–16)
                        Text(
                          "Disclaimer",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff664d03),
                          ),
                        ),
                        SizedBox(height: 4),
                        // Content lines are smaller
                        Text(
                          "Product data taken from web sources",
                          style: TextStyle(
                            color: Color(0xff664d03),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "At most care is taken for accuracy",
                          style: TextStyle(
                            color: Color(0xff664d03),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "PFIPL is not responsible for any source errors",
                          style: TextStyle(
                            color: Color(0xff664d03),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                // Manufactured by
                if (p.manufacturedBy != null && p.manufacturedBy!.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: Color(0xff185794)),
                      const SizedBox(width: 6),
                      Text(
                        p.manufacturedBy!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // rest of your info cards...
                ...filteredFields.map((e) => _buildInfoCard(e.key, e.value)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          3,
              (index) => Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _styledAccordionItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPackSizes(GetProductsContent product) {
    final items = product.packSizes ?? [];
    if (items.isEmpty) return _styledAccordionItem("Pack Sizes", "No data available.");

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: 600,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xff185794),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(width: 180, child: Text("Strength", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                SizedBox(width: 180, child: Text("Pack Size", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                SizedBox(width: 200, child: Text("Storage", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 600,
            height: items.length > 4 ? 200 : null,
            child: ListView.builder(
              shrinkWrap: items.length <= 4,
              physics: items.length <= 4 ? NeverScrollableScrollPhysics() : ClampingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final pack = items[index];
                final isHighlighted = _highlightedPackSizeIndex == index;
                final bgColor = isHighlighted
                    ? const Color(0xFFE1F5FE)
                    : (index % 2 == 0 ? Colors.white : const Color(0xFFF5F9FF));

                return GestureDetector(
                  onTap: () => setState(() => _highlightedPackSizeIndex = isHighlighted ? null : index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 180, child: Text(pack.strength ?? '-', style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal))),
                        SizedBox(width: 180, child: Text(pack.packSize ?? '-', style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal))),
                        SizedBox(width: 200, child: Text(pack.storage ?? '-', style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  // Improved drug interactions widget with better styling and row highlighting
  Widget _buildDrugInteractions(GetProductsContent product) {
    final items = product.drugInteractions ?? [];

    if (items.isEmpty) {
      return _styledAccordionItem("Drug Interactions", "No data available.");
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Get the available width to make responsive design decisions
        final availableWidth = constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Container(
              width: availableWidth,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xff185794),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Drug Name",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Interaction",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Data rows in a fixed height scrollable box
            Container(
              width: availableWidth,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListView.builder(
                  itemCount: _showAllDrugInteractions ? items.length : (items.length > 5 ? 5 : items.length),
                  itemBuilder: (context, index) {
                    final d = items[index];
                    final isHighlighted = _highlightedDrugInteractionIndex == index;
                    final bgColor = isHighlighted
                        ? const Color(0xFFE1F5FE)
                        : (index % 2 == 0 ? Colors.white : const Color(0xFFF5F9FF));

                    return GestureDetector(
                      onTap: () => setState(() {
                        _highlightedDrugInteractionIndex =
                        isHighlighted ? null : index;
                      }),
                      onLongPress: () {
                        final msg = '${d.drug ?? '-'}: ${d.interaction ?? '-'}';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                          boxShadow: isHighlighted
                              ? [
                            BoxShadow(
                              color: const Color(0xff185794).withOpacity(0.3),
                              blurRadius: 0,
                              spreadRadius: 1,
                            )
                          ]
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                d.drug ?? '-',
                                style: TextStyle(
                                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                                  color: const Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                d.interaction ?? '-',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            if (items.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _showAllDrugInteractions = !_showAllDrugInteractions);
                  },
                  icon: Icon(
                    _showAllDrugInteractions ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xff185794),
                    size: 18,
                  ),
                  label: Text(
                    _showAllDrugInteractions
                        ? "Show Less"
                        : "Show More (${items.length - 5} more)",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff185794),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBrandPrescriptions(GetProductsContent product) {
    final items = product.brandPrescriptions ?? [];
    if (items.isEmpty) return _styledAccordionItem("Brand Prescriptions", "No data available.");

    return LayoutBuilder(
      builder: (context, constraints) {
        // Total width of the table
        const double tableWidth = 740;

        final table = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xff185794),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  SizedBox(
                    width: 100,
                    child: Text("Dosage", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text("Strength", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text("Route", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text("Labeller", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text("Marketing Start", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text("Marketing End", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Table Body
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListView.builder(
                  itemCount: items.length,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final b = items[index];
                    final isHighlighted = _highlightedBrandPrescriptionIndex == index;
                    final backgroundColor = isHighlighted
                        ? const Color(0xFFE1F5FE)
                        : (index % 2 == 0 ? Colors.white : const Color(0xFFF5F9FF));

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _highlightedBrandPrescriptionIndex =
                          _highlightedBrandPrescriptionIndex == index ? null : index;
                        });
                      },
                      onLongPress: () {
                        final info = '${b.dosage ?? '-'} (${b.strength ?? '-'}) - ${b.labeller ?? '-'}';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected: $info'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                          boxShadow: isHighlighted
                              ? [
                            BoxShadow(
                              color: const Color(0xff185794).withOpacity(0.3),
                              blurRadius: 0,
                              spreadRadius: 1,
                            )
                          ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(b.dosage ?? '-', style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal)),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(b.strength ?? '-', style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal)),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(b.route ?? '-', style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal)),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(b.labeller ?? '-', style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal)),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(b.marketingStart ?? '-', style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal)),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(b.marketingEnd ?? '-', style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: table,
          ),
        );
      },
    );
  }


}