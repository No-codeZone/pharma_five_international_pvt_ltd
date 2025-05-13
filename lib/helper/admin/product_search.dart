import 'package:flutter/material.dart';

class ProductSearch extends StatefulWidget {
  final List<Map<String, String>> productList;
  final Function(List<Map<String, String>>) onFilteredResults;

  const ProductSearch({
    Key? key,
    required this.productList,
    required this.onFilteredResults
  }) : super(key: key);

  @override
  _ProductSearchState createState() => _ProductSearchState();
}

class _ProductSearchState extends State<ProductSearch> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredProductList = [];

  @override
  void initState() {
    super.initState();
    _filteredProductList = widget.productList;
    _searchController.addListener(_filterProducts);
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();

    // Improved search logic with multiple search criteria
    final results = widget.productList.where((product) {
      final medicineName = product['medicineName']?.toLowerCase() ?? '';
      final genericName = product['genericName']?.toLowerCase() ?? '';

      return medicineName.contains(query) ||
          genericName.contains(query);
    }).toList();

    setState(() {
      _filteredProductList = results;
    });

    // Callback to parent widget with filtered results
    widget.onFilteredResults(_filteredProductList);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search Products',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _searchController.clear();
          },
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}