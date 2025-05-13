import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pharma_five/ui/login_screen.dart';

import '../../helper/shared_preferences.dart';
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


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _validateUserAndLoadData();
    _updateInternetStatus();
  }

  void _updateInternetStatus() async {
    final wasConnected = _isConnected;
    _isConnected = await _checkInternetConnectivity();

    if (_isConnected != wasConnected) {
      final message =
          _isConnected ? "Internet connected" : "Internet disconnected";
      final color = _isConnected ? Colors.green : Colors.red;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    setState(() {}); // Trigger UI update
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

      /*ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Showing cached data.'),
          backgroundColor: Colors.orange,
        ),
      );*/

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
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      textColor: Colors.white,
      fontSize: 16.0,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
    );
  }


  Future<void> _downloadExcelFile() async {
    setState(() => _isLoading = true);

    try {
      if (!_isConnected) {
        _showToast("No internet connection", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        setState(() => _isLoading = false);
        return;
      }

      final url = Uri.parse("http://13.49.224.44:8080/api/product/download");
      final filename = "product_list_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      // Get appropriate directory per platform
      Directory? directory;
      if (Platform.isAndroid) {
        // First try the Download directory
        try {
          directory = Directory("/storage/emulated/0/Download");
          if (!(await directory.exists())) {
            // Fall back to app-specific directory
            directory = await getExternalStorageDirectory();
          }
        } catch (e) {
          // Final fallback
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        _showToast("Failed to access storage directory", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final downloadPath = "${directory.path}/$filename";

      // Show downloading progress indicator
      _showToast("Downloading Excel file...");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final file = File(downloadPath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Excel downloaded to: $downloadPath"),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: "Open",
                textColor: Colors.white,
                onPressed: () => OpenFile.open(downloadPath),
              ),
            ),
          );
        }
      } else {
        _showToast("Failed to download Excel file (Status: ${response.statusCode})", isError: true);
      }
    } catch (e) {
      print("Download error: $e");
      _showToast("Error: ${e.toString()}", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+ needs media-specific permissions instead of general storage
        var status = await Permission.photos.request();
        // For downloading in public directories like Downloads
        var downloadStatus = await Permission.mediaLibrary.request();

        if (status.isGranted && downloadStatus.isGranted) return true;

        if (status.isPermanentlyDenied || downloadStatus.isPermanentlyDenied) {
          _showPermissionPermanentlyDeniedDialog();
          return false;
        }

        _showToast("Media permissions needed to download files", isError: true);
        return false;
      } else if (sdkInt >= 30) {
        // Android 11-12 needs storage access + manage external storage
        var status = await Permission.storage.request();

        if (status.isGranted) {
          // Try the more powerful permission
          var manageStatus = await Permission.manageExternalStorage.request();
          if (manageStatus.isGranted) return true;
        }

        if (status.isPermanentlyDenied) {
          _showPermissionPermanentlyDeniedDialog();
          return false;
        }

        _showToast("Storage permissions needed for Android 11+", isError: true);
        return false;
      } else {
        // Android 10 and below just needs storage permission
        var status = await Permission.storage.request();
        if (status.isGranted) return true;

        if (status.isPermanentlyDenied) {
          _showPermissionPermanentlyDeniedDialog();
          return false;
        }

        _showToast("Storage permission needed to download files", isError: true);
        return false;
      }
    }

    // For iOS or other platforms, we need photos permission
    if (Platform.isIOS) {
      var status = await Permission.photos.request();
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        _showPermissionPermanentlyDeniedDialog();
        return false;
      }

      _showToast("Photos access needed to save files", isError: true);
      return false;
    }

    // Default allow for other platforms
    return true;
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to download files. Please enable it in app settings.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _checkInternetStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
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
      final response = await ApiService().fetchProductListWithPagination(
        index: page,
        limit: _itemsPerPage,
        search: _searchController.text.trim(),
      );

      final List<Products> products = List<Products>.from(response['products']);
      final int totalCount = response['totalCount'] ?? 0;

      // Move this setState outside and combine with the next one
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _currentPage = page; // Make sure this is set correctly
        _totalProductCount = totalCount;
        _hasMore = ((page + 1) * _itemsPerPage) < totalCount;
        _isProductsLoading = false;
      });

      // Debug print to verify total count and current page
      debugPrint('Loaded Products: ${_filteredProducts.length}');
      debugPrint('Total Product Count: $_totalProductCount');
      debugPrint('Current Page: $_currentPage');

      // Force UI to update
      if (mounted) {
        setState(() {
          // This empty setState forces the build method to run again
          // which will redraw the pagination with the correct selected page
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

  void _navigateToApprovalScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminApprovalScreen()),
    );
  }

  void _navigateToLogin() {
    SharedPreferenceHelper.clearSession().then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  void _searchProducts(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredProducts = _allProducts;
        _currentPage = 0;
        _updateHasMore();
      });
      return;
    }

    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final medicineName = product.medicineName?.toLowerCase() ?? '';
        final genericName = product.genericName?.toLowerCase() ?? '';
        return medicineName.contains(query.toLowerCase()) ||
            genericName.contains(query.toLowerCase());
      }).toList();
      _currentPage = 0;
      _updateHasMore();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateUserAndLoadData();
    }
  }

  void _updateHasMore() {
    _hasMore = ((_currentPage + 1) * _itemsPerPage) < _totalProductCount;
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

  List<Map<String, String>> _getCurrentPageItems() {
    // Handle empty list case
    if (_filteredProducts.isEmpty) {
      return [];
    }

    int start = _currentPage * _itemsPerPage;

    // Ensure start index is valid
    if (start >= _filteredProducts.length) {
      // If current page is too large, reset to page 0
      _currentPage = 0;
      start = 0;
    }

    int end = min(start + _itemsPerPage, _filteredProducts.length);

    // Convert Products objects to Map<String, String>
    return _filteredProducts.sublist(start, end).map((product) {
      return {
        'medicineName': product.medicineName ?? 'Unknown Medicine',
        'genericName': product.genericName ?? 'Unknown Generic Name',
        'manufacturedBy': product.manufacturedBy ?? 'Not Available',
        'indication': product.indication ?? 'Not Available',
      };
    }).toList();
  }

  Widget _buildPagination() {
    if (_filteredProducts.isEmpty && _currentPage == 0) {
      return const SizedBox.shrink(); // No pagination needed
    }

    const int itemsPerPage = 10;
    final int totalPages = (_totalProductCount / itemsPerPage).ceil();
    final int maxPagesToShow = 5;

    // Debug print for pagination state
    debugPrint('Building pagination UI with _currentPage = $_currentPage');
    debugPrint('Total pages: $totalPages');

    // Calculate which pages to show
    int startPage = max(0, min(_currentPage - 2, totalPages - maxPagesToShow));
    int endPage = min(startPage + maxPagesToShow - 1, totalPages - 1);

    debugPrint('Pagination range: $startPage to $endPage');

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 400;
    final bool isTablet = screenWidth >= 600;

    final double buttonSize = isSmallScreen ? 26 : isTablet ? 36 : 30;
    final double fontSize = isSmallScreen ? 13 : isTablet ? 17 : 15;

    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous button
            if (_currentPage > 0)
              InkWell(
                onTap: () {
                  _loadProductData(page: _currentPage - 1);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_left,
                    color: const Color(0xff185794),
                    size: fontSize + 2,
                  ),
                ),
              ),

            // Page number buttons
            ...List.generate(endPage - startPage + 1, (index) {
              final int pageNumber = startPage + index;

              // Debug the check for selected page
              final bool isSelected = pageNumber == _currentPage;
              debugPrint('Page ${pageNumber + 1}: isSelected = $isSelected, _currentPage = $_currentPage');

              return InkWell(
                onTap: () {
                  debugPrint('Tapped on page ${pageNumber + 1}');
                  if (_currentPage != pageNumber) {
                    _loadProductData(page: pageNumber);
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
                      color: const Color(0xff185794),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              );
            }),

            // Next button
            if (((_currentPage + 1) * itemsPerPage) < _totalProductCount)
              InkWell(
                onTap: () {
                  _loadProductData(page: _currentPage + 1);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_right,
                    color: const Color(0xff185794),
                    size: fontSize + 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isSmallScreen ? 12.0 : 24.0;

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/pharmafive_512x512.png',
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
        return 'Pending Review';
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
            Lottie.asset("assets/animations/waiting.json",
                width: 300, height: 150),
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
                  // ? "Your application was not approved. Please contact support."
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
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isRefreshing = true);
          await _validateUserAndLoadData();
        },
        color: const Color(0xff185794),
        backgroundColor: Colors.white,
        displacement: 40,
        strokeWidth: 3,
        child: Column(
          children: [
            _buildSearchBar(horizontalPadding),
            const SizedBox(height: 12),
            _buildTableHeader(horizontalPadding),
            const SizedBox(height: 8),
            Expanded(
              child: _isProductsLoading
                  ? _buildLoadingIndicator()
                  : _errorMessage.isNotEmpty
                  ? _buildErrorWidget()
                  : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : _buildProductListView(horizontalPadding),
            ),
            if (!_isProductsLoading &&
                _errorMessage.isEmpty &&
                _filteredProducts.isNotEmpty)
              _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: TextField(
        controller: _searchController,
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
                    _loadProductData(page: 0); // Clear and reload all
                  },
                ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  _loadProductData(page: 0); // Trigger search on icon click
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
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadProductData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff185794),
              foregroundColor: Colors.white,
            ),
            child: const Text("Try Again"),
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
            _isConnected
                ? "assets/animations/no_data_found.json"
                : "assets/animations/internet.json",
            width: 250,
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
              color: _isConnected ? Colors.grey.shade700 : Colors.redAccent,
            ),
          ),
          const SizedBox(height: 12),
          if (!_isConnected)
            IconButton(
              onPressed: () {
                _updateInternetStatus();
                _loadProductData();
              },
              icon: const Icon(Icons.refresh, color: Color(0xff185794), size: 40),
            ),
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
              width: 250,
              height: 250,
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
            ElevatedButton(
              onPressed: () {
                _updateInternetStatus();
                _loadProductData();
              },
              child: const Text('Retry'),
            ),
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "↓ Pull down to refresh account status ↓",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Image.asset('assets/images/excel_icon.png', height: 24),
                    onPressed: () {
                      debugPrint("Excel file downloaded!");
                      _downloadExcelFile();
                      // _downloadExcel();
                    },
                    tooltip: 'Download as Excel',
                  ),
                ],
              ),
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
                PopupMenuButton<String>(
                  color: const Color(0xff185794),
                  onSelected: (value) {
                    if (value == 'view') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(product: product),
                        ),
                      );
                      /*_showProductDetails({
                        'medicineName': product.medicineName ?? 'N/A',
                        'genericName': product.genericName ?? 'N/A',
                        'manufacturedBy': product.manufacturedBy ?? 'N/A',
                        'indication': product.indication ?? 'N/A',
                      });*/
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility, color: Colors.white),
                        title: Text(
                          "View",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert, color: Color(0xff185794)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadExcel() async {
    const downloadUrl = 'https://yourapi.com/download-excel'; // Replace with your API

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await http.get(Uri.parse(downloadUrl));

      Navigator.of(context).pop(); // Close loading indicator

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/product_report.xlsx';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download complete!')),
        );

        await OpenFile.open(filePath);
      } else {
        throw Exception('Failed to download Excel. Status: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Ensure dialog is closed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showProductDetails(Map<String, String> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient background
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff262A88), Color(0xff185794)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      product['medicineName'] ?? 'Product Details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Content
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _detailRow('Generic Name',
                          product['genericName'] ?? 'Not available',
                          Icons.medication),
                      const Divider(),
                      _detailRow('Manufactured By',
                          product['manufacturedBy'] ?? 'Not available',
                          Icons.factory),
                      const Divider(),
                      _detailRow('Indications',
                          product['indication'] ?? 'Not available',
                          Icons.healing),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Close button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff185794),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xff262A88).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xff262A88),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xff262A88),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: ValueKey<int>(_currentPage), // Force rebuild when page changes
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (visible for both active and pending/rejected users)
            _buildAppBar(),

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