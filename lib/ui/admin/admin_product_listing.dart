import 'package:flutter/material.dart';
import 'package:pharma_five/ui/admin/add_product.dart';

import '../../helper/admin/product_search.dart';

class AdminProductListing extends StatefulWidget {
  @override
  _AdminProductListingState createState() => _AdminProductListingState();
}

class _AdminProductListingState extends State<AdminProductListing> {
  final TextEditingController _searchController = TextEditingController();
  late int _currentProductPage = 0;
  bool _hasMoreProduct = true;

  List<Map<String, String>> allProducts = List.generate(
    10,
    (index) => {
      "medicine": "Medicine name${index + 1}",
      "generic": "Generic Name ${index + 1}",
    },
  );

  void _updateFilteredProducts(List<Map<String, String>> filteredList) {
    setState(() {
      filteredProducts = filteredList;
    });
  }

  List<Map<String, String>> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(allProducts);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredProducts = allProducts
          .where((product) =>
              product["medicine"]!.toLowerCase().contains(query) ||
              product["generic"]!.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Color(0xff185794),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: const [
          Expanded(
              flex: 1,
              child: Center(
                  child: Text('No.',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
          Expanded(
              flex: 3,
              child: Center(
                  child: Text('Medicine name',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
          Expanded(
              flex: 3,
              child: Center(
                  child: Text('Generic Name',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
          Expanded(
              flex: 1,
              child: Center(
                  child: Text('Edit',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildTableRow(int index, Map<String, String> product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 1, child: Text('${index + 1}.')),
            Expanded(flex: 3, child: Text(product["medicine"]!)),
            Expanded(flex: 3, child: Text(product["generic"]!)),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, color: Colors.grey.shade800, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      // decoration: BoxDecoration(
                      //   color: Colors.grey.shade200,
                      //   borderRadius: BorderRadius.circular(10),
                      // ),
                      child: const Text("Products Lists",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff185794),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(15),
                                left: Radius.circular(15))),
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () {
                        debugPrint("Add product..!");

                      },
                      child: const Icon(Icons.add,color: Colors.white,),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTableHeader(),
                const SizedBox(height: 4),
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(child: Text("No products found."))
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) =>
                              _buildTableRow(index, filteredProducts[index]),
                        ),
                ),
                buildProductPagination()
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildProductPagination() {
    // Dynamically calculate total pages based on _hasMore flag
    final int totalPages = _hasMoreProduct ? 5 : _currentProductPage + 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(totalPages, (index) {
          final pageNumber = index + 1;
          final isSelected = index == _currentProductPage;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentProductPage = index;
                // _fetchUsers();
                ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) =>
                      _buildTableRow(index, filteredProducts[index]),
                );
              });
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              child: Text(
                '$pageNumber',
                style: TextStyle(
                    color: const Color(0xff262A88),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isSelected ? 18 : 14),
              ),
            ),
          );
        }),
      ),
    );
  }
}
