import 'package:flutter/material.dart';
import '../../model/product.dart';

class AdminProductListWidget extends StatefulWidget {
  @override
  _AdminProductListWidgetState createState() => _AdminProductListWidgetState();
}

class _AdminProductListWidgetState extends State<AdminProductListWidget> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with 10 default products
    _products = List.generate(
      10,
          (index) => Product(
        medicineName: 'Medicine name ${index + 1}',
        genericName: 'Generic Name ${index + 1}',
      ),
    );
    _filteredProducts = _products;
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _products
          .where((product) =>
      product.medicineName.toLowerCase().contains(query.toLowerCase()) ||
          product.genericName.toLowerCase().contains(query.toLowerCase())
      )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Products',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: _filterProducts,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text('${index + 1}'),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(_filteredProducts[index].medicineName),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(_filteredProducts[index].genericName),
                    ),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          // Edit functionality
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}