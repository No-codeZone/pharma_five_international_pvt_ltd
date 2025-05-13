import 'package:flutter/material.dart';
import 'package:pharma_five/model/product_search_listing_response_model.dart';
import 'package:pharma_five/ui/admin/widget/reference_web_view_screen.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Products product;

  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int? _expandedIndex;
  bool _isLoadingDrugInteractions = false;
  bool _isLoadingBrandPrescriptions = false;

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

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffe0f7fa), Color(0xfff1f8e9)],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        // color: Color(0xff185794),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
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
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title ?? '-',
              style: const TextStyle(color: Color(0xff185794), fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
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

  Widget _buildInfoCard(String key, String? value) {
    if (value == null || value.trim().isEmpty || value.trim().toUpperCase() == "-NA") {
      return const SizedBox.shrink();
    }

    final isReferenceLink = key == "Reference Link";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        tileColor: Colors.white.withOpacity(0.9),
        title: Text(
          key,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: isReferenceLink
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
            : Text(value),
      ),
    );
  }

  Widget _buildProductDetails(Products p) {
    final fields = {
      "Generic Name": p.genericName,
      "Manufactured By": p.manufacturedBy,
      "Indication": p.indication,
      "Medical Field": p.medicalField,
      "Brand Names": p.brandNames,
      "Summary": p.summary,
      "Reference Link": p.referenceLink,
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
    };

    final filteredFields = fields.entries.where((entry) {
      final val = entry.value?.trim().toUpperCase();
      return val != null && val.isNotEmpty && val != "-NA";
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filteredFields.map((e) => _buildInfoCard(e.key, e.value)).toList(),
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

  Widget _buildDrugInteractions(Products product) {
    final items = product.drugInteractions ?? [];
    if (items.isEmpty) return _styledAccordionItem("Drug Interactions", "No data available.");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((d) {
        return Column(
          children: [
            _styledAccordionItem("Drug", d.drug ?? '-'),
            _styledAccordionItem("Interaction", d.interaction ?? '-'),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBrandPrescriptions(Products product) {
    final items = product.brandPrescriptions ?? [];
    if (items.isEmpty) return _styledAccordionItem("Brand Prescriptions", "No data available.");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((b) {
        return Column(
          children: [
            _styledAccordionItem("Dosage", b.dosage ?? '-'),
            _styledAccordionItem("Strength", b.strength ?? '-'),
            _styledAccordionItem("Route", b.route ?? '-'),
            _styledAccordionItem("Labeller", b.labeller ?? '-'),
            _styledAccordionItem("Marketing Start", b.marketingStart ?? '-'),
            _styledAccordionItem("Marketing End", b.marketingEnd ?? '-'),
          ],
        );
      }).toList(),
    );
  }
}