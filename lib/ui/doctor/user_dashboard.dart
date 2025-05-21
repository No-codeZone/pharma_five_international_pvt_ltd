import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pharma_five/ui/login_screen.dart';
import 'package:share_plus/share_plus.dart';

import '../../helper/file_downloader_helper.dart';
import '../../helper/shared_preferences.dart';
import '../../model/get_product_search_model.dart';
import '../../model/product_search_listing_response_model.dart';
import '../../model/update_product_listing_request_model.dart';
import '../../service/api_service.dart';
import '../admin/edit_full_product_screen.dart';
import '../admin/product_details_screen.dart';
import '../admin_approval_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<Products> _allProducts = [];
  List<Products> _filteredProducts = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isProductsLoading = false; // Flag for product loading
  bool isUserActive = false;
  bool _isRefreshing = false;
  String _userStatus = 'pending'; // Store the actual status string
  String _lastRefreshed = ''; // Track when status was last checked
  String _errorMessage = ''; // Store error messages from API calls
  bool _isConnected = true;
  int _totalProductCount = 0;
  bool _isUploadingExcel = false;
  int? _userSno;
  String? _selectedMedicalField;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  ApiService apiService=ApiService();
  bool _lastConnectionStatus = true;
  // Key for product list refresh
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _validateUserAndLoadData();
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) async {
          final connected = results.contains(ConnectivityResult.mobile) ||
              results.contains(ConnectivityResult.wifi) ||
              results.contains(ConnectivityResult.ethernet);

          if (_lastConnectionStatus != connected) {
            setState(() {
              _isConnected = connected;
              _lastConnectionStatus = connected;
            });

            // Fluttertoast.showToast(
            //   msg: connected ? "Internet connected" : "Internet disconnected",
            //   backgroundColor: connected ? Color(0xff185794) : Colors.red,
            // );

            if (connected) {
              // Auto reload product list
              if (_selectedMedicalField != null) {
                await _loadProductsByField(_selectedMedicalField!);
              } else {
                await _loadProductData(page: _currentPage);
              }
            }
          }
        });
  }

  Future<bool> _checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _validateUserAndLoadData() async {
    setState(() {
      _isLoading = true;
    });

    await SharedPreferenceHelper.init();
    final isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
    final email = await SharedPreferenceHelper.getUserEmail();
    _userSno = await SharedPreferenceHelper.getUserSno();

    if (!isLoggedIn || email == null || email.isEmpty) {
      _navigateToLogin();
      return;
    }

    _isConnected = await _checkInternetConnectivity();

    if (!_isConnected) {
      // Use local stored status without navigating away
      final localStatus =
          (await SharedPreferenceHelper.getUserStatus())?.toLowerCase() ??
              'pending';

      setState(() {
        _userStatus = localStatus;
        isUserActive = localStatus == 'active';
        _isLoading = false;
        _isRefreshing = false;
        _lastRefreshed = _getCurrentTimeFormatted();
      });
      // Load cached product data (if any)
      if (isUserActive) {
        _loadProductData(); // might fail if also requires internet, but handles its own try/catch
      }

      return;
    }

    // If internet is available, proceed with API call
    try {
      final result = await ApiService().getUsers(search: email);
      final users = result['content'] ?? [];

      if (users.isNotEmpty) {
        final currentStatus = users[0]['status'].toString().toLowerCase();
        await SharedPreferenceHelper.setUserStatus(currentStatus);

        setState(() {
          _userStatus = currentStatus;
          isUserActive = currentStatus == 'active';
          _isLoading = false;
          _isRefreshing = false;
          _lastRefreshed = _getCurrentTimeFormatted();
        });

        if (isUserActive) {
          _loadProductData();
        }
      } else {
        setState(() {
          _userStatus = 'not found';
          isUserActive = false;
          _isLoading = false;
          _isRefreshing = false;
          _lastRefreshed = _getCurrentTimeFormatted();
        });
      }
    } catch (e) {
      debugPrint('Status check failed: $e');

      final status =
          (await SharedPreferenceHelper.getUserStatus())?.toLowerCase() ??
              'pending';

      setState(() {
        _userStatus = status;
        isUserActive = status == 'active';
        _isLoading = false;
        _isRefreshing = false;
        _lastRefreshed = _getCurrentTimeFormatted();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not connect to server. Using local status.'),
          backgroundColor: Colors.orange,
        ),
      );

      if (isUserActive) {
        _loadProductData();
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isError ? Colors.red.shade700 : Color(0xff185794),
      textColor: Colors.white,
      fontSize: 16.0,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
    );
  }

  Future<void> _searchProductsFromApi(String searchTerm, {int page = 0}) async {
    if (searchTerm.trim().isEmpty) {
      _loadProductData(page: 0);
      return;
    }

    setState(() {
      _isProductsLoading = true;
      _errorMessage = '';
    });

    try {
      String searchProduct=apiService.baseUrlProduct;
      final response = await http.get(Uri.parse(
          '$searchProduct/product/list?search=$searchTerm&index=$page&limit=$_itemsPerPage'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List productsJson = data['products'] ?? [];
        final int total = data['totalCount'] ?? productsJson.length;

        final List<Products> converted = productsJson.map((p) => Products(
          serialNo: p['serialNo'],
          medicineName: p['medicineName'],
          genericName: p['genericName'],
        )).toList();

        setState(() {
          _allProducts = converted;
          _filteredProducts = converted;
          _currentPage = page;
          _totalProductCount = total;
          _hasMore = ((page + 1) * _itemsPerPage) < total;
          _selectedMedicalField = null;
          _isProductsLoading = false;
        });
      } else {
        throw Exception("Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _filteredProducts = [];
        _errorMessage = 'Search error: ${e.toString()}';
        _isProductsLoading = false;
      });
    }
  }

  Future<void> _loadProductsByField(String field, {int page = 0}) async {
    setState(() {
      _isProductsLoading = true;
      _errorMessage = '';
      _selectedMedicalField = field;
    });

    try {
      final response = await ApiService().fetchProductsByField(
        field: field,
        index: page,  // Use the provided page parameter
        limit: _itemsPerPage,
      );

      if (response != null && response.fieldProducts != null) {
        final converted = response.fieldProducts!.map((f) => Products(
          serialNo: f.serialNo,
          medicineName: f.medicineName,
          genericName: f.genericName,
        )).toList();

        setState(() {
          _allProducts = converted;
          _filteredProducts = converted;
          _totalProductCount = response.totalCount ?? converted.length;
          _currentPage = page;  // Update current page
          _hasMore = ((page + 1) * _itemsPerPage) < _totalProductCount;
          _isProductsLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No products found in this field.';
          _filteredProducts = [];
          _isProductsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Field filter error: $e');
      setState(() {
        _errorMessage = 'Error loading field-specific products.';
        _isProductsLoading = false;
      });
    }
  }

  Future<void> _downloadExcelFile() async {
    // First check if the connection is available right now
    bool isCurrentlyConnected = await _checkInternetConnectivity();

    if (!isCurrentlyConnected) {
      _showToast("No internet connection", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Step 2: Request permission
      final hasPermission = await FileDownloadHelper.requestStoragePermission(context);
      if (!hasPermission) {
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Step 3: Get download directory
      final directory = await FileDownloadHelper.getDownloadDirectory();
      if (directory == null) {
        _showToast("Unable to access storage", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Step 4: Download file
      final url = Uri.parse("http://13.49.224.44:8080/api/product/download");
      final filename = "product_list_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final downloadPath = "${directory.path}/$filename";

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final file = File(downloadPath);
        await file.writeAsBytes(response.bodyBytes);
        await FileDownloadHelper.showFileDownloadSnackBar(context, downloadPath, Platform.isIOS);
      } else {
        _showToast("Failed to download file: Status ${response.statusCode}", isError: true);
      }
    } catch (e) {
      debugPrint("Excel download error: $e");
      _showToast("Download error: ${e.toString()}", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getCurrentTimeFormatted() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadProductData({int page = 0}) async {
    setState(() {
      _isProductsLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService().fetchPaginatedProducts(
        index: page,
        limit: _itemsPerPage,
      );

      if (response != null && response.getProducts != null) {
        // Convert GetProducts to Products
        List<Products> convertedProducts = response.getProducts!.map((getProduct) {
          return Products(
            serialNo: getProduct.serialNo,
            medicineName: getProduct.medicineName,
            genericName: getProduct.genericName,
          );
        }).toList();

        setState(() {
          _allProducts = convertedProducts;
          _filteredProducts = convertedProducts;
          _currentPage = page;
          _totalProductCount = response.totalCount ?? 0;
          _hasMore = ((page + 1) * _itemsPerPage) < _totalProductCount;
          _isProductsLoading = false;
        });
      } else {
        setState(() {
          _isProductsLoading = false;
          // _errorMessage = 'No products found.';
          _filteredProducts = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading product data: $e');
      setState(() {
        _isProductsLoading = false;
        _errorMessage = 'Failed to load products. Please try again later.';
        _filteredProducts = [];
      });
    }
  }

  void _navigateToLogin() {
    SharedPreferenceHelper.clearSession().then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateUserAndLoadData();
    }
  }

  Future<void> _logout() async {
    try {
      final email = await SharedPreferenceHelper.getUserEmail();
      if (email != null && email.isNotEmpty) {
        await ApiService().logoutUser(userEmail: email);
      }

      await SharedPreferenceHelper.clearSession();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      debugPrint('Logout failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  Widget _buildPagination() {
    if (_filteredProducts.isEmpty && _currentPage == 0) {
      return const SizedBox.shrink(); // No pagination needed
    }

    const int itemsPerPage = 10;
    final int totalPages = (_totalProductCount / itemsPerPage).ceil();
    const int maxPagesToShow = 7; // ✅ Show fewer pages to avoid overflow

    int startPage = max(0, min(_currentPage - (maxPagesToShow ~/ 2), totalPages - maxPagesToShow));
    int endPage = min(startPage + maxPagesToShow - 1, totalPages - 1);

    // ✅ Slightly smaller, fixed-size buttons and font
    final double buttonSize = 30;
    final double fontSize = 14;

    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous Button
            if (_currentPage > 0)
              _buildPageArrow(isNext: false, fontSize: fontSize, buttonSize: buttonSize),

            // Page Numbers
            ...List.generate(endPage - startPage + 1, (index) {
              final int pageNumber = startPage + index;
              final bool isSelected = pageNumber == _currentPage;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    if (_currentPage != pageNumber) {
                      if (_searchController.text.trim().isNotEmpty) {
                        _searchProductsFromApi(_searchController.text.trim(), page: pageNumber);
                      } else if (_selectedMedicalField != null && _selectedMedicalField != 'All') {
                        _loadProductsByField(_selectedMedicalField!, page: pageNumber);
                      } else {
                        _loadProductData(page: pageNumber);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    alignment: Alignment.center,
                    decoration: isSelected
                        ? BoxDecoration(
                      color: const Color(0xff185794).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    )
                        : null,
                    child: Text(
                      '${pageNumber + 1}',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: const Color(0xff185794),
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Next Button
            if (((_currentPage + 1) * itemsPerPage) < _totalProductCount)
              _buildPageArrow(isNext: true, fontSize: fontSize, buttonSize: buttonSize),
          ],
        ),
      ),
    );
  }

  Widget _buildPageArrow({required bool isNext, required double fontSize, required double buttonSize}) {
    return InkWell(
      onTap: () {
        final newPage = isNext ? _currentPage + 1 : _currentPage - 1;
        if (_searchController.text.trim().isNotEmpty) {
          _searchProductsFromApi(_searchController.text.trim(), page: newPage);
        } else if (_selectedMedicalField != null && _selectedMedicalField != 'All') {
          _loadProductsByField(_selectedMedicalField!, page: newPage);
        } else {
          _loadProductData(page: newPage);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        alignment: Alignment.center,
        child: Icon(
          isNext ? Icons.chevron_right : Icons.chevron_left,
          color: const Color(0xff185794),
          size: fontSize + 4,
        ),
      ),
    );
  }

  Widget _buildHorizontalMenu() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildMenuItem(Icons.dashboard, "All"),
          const SizedBox(width: 12),
          _buildMenuItem(Icons.biotech, "Oncology"), // Changed
          const SizedBox(width: 12),
          _buildMenuItem(Icons.bloodtype, "Hematology"), // Changed
          const SizedBox(width: 12),
          _buildMenuItem(Icons.child_care, "Paediatric Oncology"), // Changed
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label) {
    final isSelected = (_selectedMedicalField ?? "All") == label;

    return OutlinedButton.icon(
      onPressed: () {
        debugPrint("Clicked $label");
        _searchController.clear();
        if (label == "All") {
          _selectedMedicalField = null;
          _loadProductData(page: 0);
        } else {
          _loadProductsByField(label);
        }
      },
      icon: Icon(icon, color: isSelected ? Colors.white : Color(0xff185794)),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Color(0xff185794),
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Color(0xff185794) : Colors.transparent,
        side: const BorderSide(color: Color(0xff185794)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildActiveAppBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isSmallScreen ? 12.0 : 24.0;

    return Padding(
      padding:
      EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_pf.png',
            width: 60,
            height: 60,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.local_pharmacy, size: 40, color: Colors.blue),
          ),
          const Spacer(),
          IconButton(
            icon: Image.asset('assets/images/excel_icon.png', height: 24),
            onPressed: () {
              debugPrint("Excel file downloaded!");
              _downloadExcelFile();
            },
            tooltip: 'Download as Excel',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xff262A88), size: 28),
            onPressed: _showLogoutDialog,
          )
        ],
      ),
    );
  }

  Widget _buildInactiveAppBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isSmallScreen ? 12.0 : 24.0;

    return Padding(
      padding:
      EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_pf.png',
            width: 60,
            height: 60,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.local_pharmacy, size: 40, color: Colors.blue),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xff262A88), size: 28),
            onPressed: _showLogoutDialog,
          )
        ],
      ),
    );
  }

  // Get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'reject':
        return Colors.red;
      case 'blocked':
        return Colors.red.shade800;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get status display text
  String _getStatusText() {
    switch (_userStatus.toLowerCase()) {
      case 'active':
        return 'Approved ✓';
      case 'reject':
        return 'Rejected ✗';
      case 'blocked':
        return 'Blocked ✗';
      case 'pending':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  Widget _buildPendingApprovalMessage() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset("assets/animations/user_waiting.json",
                width: 350, height: 200),
            const SizedBox(height: 24),

            // Status indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Account Status: ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff262A88),
                  ),
                ),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_userStatus),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text(
              _userStatus == 'active'
                  ? "Your account is now approved! You can view products."
                  : "Your account has to be approved by Admin. Please wait.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _userStatus == 'active'
                    ? Colors.green
                    : const Color(0xff262A88),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _userStatus.toLowerCase() == 'rejected'
                  ? "Your account has been rejected by the admin. Please contact support."
                  : (_userStatus.toLowerCase() == 'blocked'
                  ? "Your account has been blocked. Please contact support."
                  : "You will be able to view product listings once approved."),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _userStatus.toLowerCase() == 'rejected' ||
                    _userStatus.toLowerCase() == 'blocked'
                    ? Colors.red.shade700
                    : Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 20),

            // Refresh button with loading indicator
            _isRefreshing
                ? Column(
              children: [
                const CircularProgressIndicator(color: Color(0xff185794)),
                const SizedBox(height: 8),
                Text(
                  "Checking status...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            )
                : Column(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isRefreshing = true;
                    });
                    // Check status
                    _validateUserAndLoadData();
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xff185794),
                    size: 40,
                  ),
                ),
              ],
            ),

            // If active, show a button to view products
            if (_userStatus.toLowerCase() == 'active') ...[
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // This will rebuild the UI with the product listing
                    // since isUserActive is already true at this point
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff185794),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                const Text("View Products", style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductListing() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isSmallScreen ? 12.0 : 24.0;

    return Expanded(
      child: Column(
        children: [
          _buildSearchBar(horizontalPadding),
          const SizedBox(height: 1),
          _buildHorizontalMenu(),
          const SizedBox(height: 1),
          _buildTableHeader(horizontalPadding),
          _buildConnectionBanner(),
          const SizedBox(height: 1),

          // Only wrap the product list with RefreshIndicator, not the entire column
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () async {
                // Only refresh the product listing, not the whole screen
                if (_isConnected) {
                  if (_searchController.text.trim().isNotEmpty) {
                    await _searchProductsFromApi(_searchController.text.trim(), page: 0);
                  } else if (_selectedMedicalField != null && _selectedMedicalField != 'All') {
                    await _loadProductsByField(_selectedMedicalField!, page: 0);
                  } else {
                    await _loadProductData(page: 0);
                  }
                }
              },
              color: const Color(0xff185794),
              backgroundColor: Colors.white,
              displacement: 40,
              strokeWidth: 3,
              child: _isProductsLoading
                  ? _buildLoadingIndicator()
                  : _errorMessage.isNotEmpty
                  ? _buildErrorWidget()
                  : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : _buildProductListView(horizontalPadding),
            ),
          ),

          if (!_isProductsLoading &&
              _errorMessage.isEmpty &&
              _filteredProducts.isNotEmpty)
            _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearchBar(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: TextField(
        controller: _searchController,
        onSubmitted: (value) {
          _searchProductsFromApi(value);
        },
        decoration: InputDecoration(
          hintText: 'Search Products',
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadProductData(page: 0); // Reload all products
                  },
                ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  _searchProductsFromApi(_searchController.text);
                },
              ),
            ],
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
  Widget _buildTableHeader(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: const Color(0xff185794),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: const [
              Expanded(
                flex: 1,
                child: Text('No.',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Expanded(
                flex: 3,
                child: Text('Medicine Name',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Expanded(
                flex: 3,
                child: Text('Generic Name',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xff185794)),
          SizedBox(height: 16),
          Text(
            "Loading products...",
            style: TextStyle(
              color: Color(0xff262A88),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            "assets/animations/internet.json",
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          /*Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),*/
          // ElevatedButton(
          //   onPressed: _loadProductData,
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: const Color(0xff185794),
          //     foregroundColor: Colors.white,
          //   ),
          //   child: const Text("Try Again"),
          // ),
        ],
      ),
    );
  }
  Widget _buildConnectionBanner() {
    if (_isConnected) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6,),
      color: Colors.orange.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wifi_off, size: 16, color: Colors.orange),
          SizedBox(width: 8),
          Text(
            'Waiting for connection...',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            "assets/animations/internet.json",
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            _isConnected
                ? (_searchController.text.isEmpty
                ? "No products available"
                : "No products match your search")
                : "No Internet Connection",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              // color: _isConnected ? Colors.grey.shade700 : Colors.redAccent,
            ),
          ),
          // const SizedBox(height: 12),
          // if (!_isConnected)
          //   IconButton(
          //     onPressed: () {
          //       _startConnectivityListener();
          //       _loadProductData();
          //     },
          //     icon: const Icon(Icons.refresh, color: Color(0xff185794), size: 40),
          //   ),
        ],
      ),
    );
  }
  // Extracted method for the ListView to use with RefreshIndicator
  Widget _buildProductListView(double horizontalPadding) {
    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              "assets/animations/internet.json",
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            // ElevatedButton(
            //   onPressed: () {
            //     _startConnectivityListener();
            //     _loadProductData();
            //   },
            //   child: const Text('Retry'),
            // ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: _filteredProducts.length + 1, // +1 for pull-to-refresh note
      itemBuilder: (context, index) {
        if (index == 0) {
          return
            Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text(
                //   "↓ Pull down to refresh account status ↓",
                //   style: TextStyle(
                //     color: Colors.grey.shade400,
                //     fontSize: 13,
                //     fontStyle: FontStyle.italic,
                //   ),
                // ),
                // const SizedBox(width: 10),
              ],
            ),
          );
        }

        final adjustedIndex = index - 1;
        final product = _filteredProducts[adjustedIndex];
        final serial = _currentPage * _itemsPerPage + adjustedIndex + 1;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: Colors.white,
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(flex: 1, child: Text('$serial')),
                Expanded(flex: 3, child: Text(product.medicineName ?? '-')),
                Expanded(flex: 3, child: Text(product.genericName ?? '-')),
                IconButton(
                  icon: const Icon(Icons.visibility, color: Color(0xff185794)),
                  tooltip: 'View Details',
                  onPressed: () async {
                    // Show Lottie animation dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => AlertDialog(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Lottie.asset(
                              'assets/animations/more_product_loading.json',
                              width: 200,
                              height: 200,
                              repeat: true,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Product Loading...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final response = await ApiService().fetchProductDetailsBySerialNo(product.serialNo ?? 0);

                    Navigator.of(context).pop(); // Close Lottie loader

                    if (response != null &&
                        response.getProductsContent != null &&
                        response.getProductsContent!.isNotEmpty) {
                      final detailedProduct = response.getProductsContent!.first;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(getProductsContent: detailedProduct),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to load product details.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xff185794))),
      );
    }

    return Scaffold(
      key: ValueKey<int>(_currentPage), // Force rebuild when page changes
      backgroundColor: !isUserActive ? Color(0xffeceef3) :Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (visible for both active and pending/rejected users)
            isUserActive ? _buildActiveAppBar() : _buildInactiveAppBar(),
            // Content based on user status
            isUserActive
                ? _buildProductListing()
                : _buildPendingApprovalMessage(),
          ],
        ),
      ),
    );
  }
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      side: const BorderSide(color: Color(0xff262A88)),
                      elevation: 0,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const Expanded(child: SizedBox(width: 80)),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}