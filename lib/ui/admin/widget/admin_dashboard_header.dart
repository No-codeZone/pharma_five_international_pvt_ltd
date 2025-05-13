import 'package:flutter/material.dart';
import 'package:pharma_five/service/internet_connectivity_service.dart';

import '../../../service/api_service.dart';

class AdminDashboardHeader extends StatefulWidget {
  const AdminDashboardHeader({super.key});

  @override
  State<AdminDashboardHeader> createState() => _AdminDashboardHeaderState();
}

class _AdminDashboardHeaderState extends State<AdminDashboardHeader> {
  int _selectedItemPosition = 0;
  String selectedStatus = 'Pending';
  int currentPage = 1;
  late int totalPages = 5;
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool selectedBottomMenu = false;
  final ApiService _apiService = ApiService();
  List<dynamic> _usersList = [];
  late int _currentPage = 0;
  bool _hasMore = true;
  bool _isConnected = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredProductList = List.generate(
      10,
          (index) => {
        'medicineName': 'Medicine name${index + 1}',
        'genericName': 'Generic Name ${index + 1}'
      }
  );
  // Mock data for each list type
  final Map<String, List<Map<String, dynamic>>> mockData = {
    'Pending': List.generate(
        10,
            (index) => {
          'id': index + 1,
          'name': 'John',
          'organization': 'Organization',
          'status': 'Pending'
        }),
    'Approved': List.generate(
        10,
            (index) => {
          'id': index + 1,
          'name': 'John',
          'organization': 'Organization',
          'status': 'Approved'
        }),
    'Rejected': List.generate(
        10,
            (index) => {
          'id': index + 1,
          'name': 'John',
          'organization': 'Organization',
          'status': 'Rejected'
        }),
  };

  final List<Map<String, String>> _productList = List.generate(
      10,
          (index) => {
        'medicineName': 'Medicine name${index + 1}',
        'genericName': 'Generic Name ${index + 1}'
      }
  );

  Future<void> _fetchUsers() async {
    // Check internet connectivity first
    bool isConnected = await InternetConnectivityService().checkInternetConnectivity();

    if (!isConnected) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
        _usersList = [];
      });
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getUsers(
        page: _currentPage,
        size: 10,
        status: selectedStatus,
        // excludeAdmin: true, // Add this parameter to exclude admin users
      );

      setState(() {
        // Extract the content from the response
        _usersList = (response['content'] ?? []).map((user) {
          // Additional mapping if needed
          return {
            ...user,
            'status': _mapStatusToFrontend(user['status'] ?? 'PENDING')
          };
        }).toList();

        _isLoading = false;

        // Update pagination information
        _hasMore = !(response['last'] ?? true);
        totalPages = response['totalPages'] ?? 1;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
        _usersList = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  String _mapStatusToFrontend(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'active':
        return 'Approved';
      case 'reject':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProductList = List.from(_productList);
      } else {
        _filteredProductList = _productList.where((product) {
          final medicineName = product['medicineName']!.toLowerCase();
          final genericName = product['genericName']!.toLowerCase();
          return medicineName.contains(query.toLowerCase()) ||
              genericName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    selectedStatus = 'Pending';
    _fetchUsers();
    _filteredProductList = List.from(_productList);
    _searchController.addListener(() {
      _filterProducts(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
  Widget _buildStatusDropdown() {
    return DropdownButton<String>(
      value: selectedStatus,
      underline: Container(),
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff262A88)),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectedStatus = newValue;
            _currentPage = 0; // Reset to first page
            _hasMore = true; // Reset has more flag
          });
          _fetchUsers();
        }
      },
      items: <String>['Pending', 'Approved', 'Rejected']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/images/pharmafive_512x512.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.language,
                  size: 40,
                  color: Colors.blue,
                );
              },
            ),
          ),
          const Spacer(),
          if (_selectedItemPosition == 0)
            Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xff262A88),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _buildStatusDropdown())
          else if(_selectedItemPosition==1)
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Products',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _filterProducts('');
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
              ),
            ),
        ],
      ),
    );
  }
}