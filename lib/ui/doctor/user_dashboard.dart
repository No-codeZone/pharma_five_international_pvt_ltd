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

  Future<void> _searchProductsFromApi(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      _loadProductData(page: 0); // Load all products
      return;
    }

    setState(() {
      _isProductsLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService().searchProducts(searchTerm);

      if (result != null && result.searchProducts != null) {
        // Convert SearchProducts to Products
        final List<Products> converted = result.searchProducts!.map((searchProduct) {
          return Products(
            serialNo: searchProduct.serialNo,
            medicineName: searchProduct.medicineName,
            genericName: searchProduct.genericName,
          );
        }).toList();

        setState(() {
          _allProducts = converted;
          _filteredProducts = converted;
          _currentPage = 0;
          _totalProductCount = result.totalCount ?? converted.length;
          _hasMore = converted.length > _itemsPerPage;
          _selectedMedicalField = null;
          _isProductsLoading = false;
        });
      } else {
        setState(() {
          _filteredProducts = [];
          _errorMessage = "No products found for '$searchTerm'";
          _isProductsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Search failed: $e');
      setState(() {
        _filteredProducts = [];
        _errorMessage = "Search error: ${e.toString()}";
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

  /*void _paginateFieldProducts(int page) {
    final start = page * _itemsPerPage;
    final end = min(start + _itemsPerPage, _allProducts.length);

    if (start >= _allProducts.length) {
      setState(() {
        _filteredProducts = [];
        _currentPage = page;
        _hasMore = false;
      });
      return;
    }

    setState(() {
      _currentPage = page;
      _filteredProducts = _allProducts.sublist(start, end);
      _hasMore = end < _allProducts.length;
      _totalProductCount = _allProducts.length;
    });
  }*/

  Future<void> _downloadExcelFile() async {
    setState(() => _isLoading = true);

    try {
      if (!_isConnected) {
        _showToast("No internet connection", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Check if permission is granted first
      final hasPermission = await _checkAndRequestStoragePermission();
      if (!hasPermission) {
        setState(() => _isLoading = false);
        return;
      }

      // Show downloading progress indicator
      _showToast("Downloading Excel file...");

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

  Future<bool> _checkAndRequestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // Check permission status first
      PermissionStatus storageStatus;

      if (sdkInt >= 33) {
        // Android 13+ needs media-specific permissions
        storageStatus = await Permission.photos.status;
        PermissionStatus downloadStatus = await Permission.mediaLibrary.status;

        // If already granted, return true immediately
        if (storageStatus.isGranted && downloadStatus.isGranted) {
          return true;
        }

        // If denied previously but not permanently, show rationale before requesting again
        if (storageStatus.isDenied || downloadStatus.isDenied) {
          bool shouldContinue = await _showPermissionRationaleDialog(
              "Storage Permission Required",
              "We need permission to save the Excel file to your device. Please grant access to continue."
          );

          if (!shouldContinue) return false;
        }

        // Now request the permissions
        storageStatus = await Permission.photos.request();
        downloadStatus = await Permission.mediaLibrary.request();

        if (storageStatus.isGranted && downloadStatus.isGranted) {
          return true;
        } else if (storageStatus.isPermanentlyDenied || downloadStatus.isPermanentlyDenied) {
          _showPermissionPermanentlyDeniedDialog();
          return false;
        } else {
          _showToast("Media permissions needed to download files", isError: true);
          return false;
        }
      } else if (sdkInt >= 30) {
        // Android 11-12
        storageStatus = await Permission.storage.status;

        if (storageStatus.isGranted) {
          // Check the more powerful permission
          final manageStatus = await Permission.manageExternalStorage.status;
          if (manageStatus.isGranted) return true;

          // If manage status is not granted but needed, show rationale and request
          bool shouldContinue = await _showPermissionRationaleDialog(
              "Storage Access Required",
              "Additional storage permissions are needed for Android 11+. Please grant full storage access."
          );

          if (!shouldContinue) return false;

          final requestedStatus = await Permission.manageExternalStorage.request();
          return requestedStatus.isGranted;
        }

        // Basic storage not granted, show rationale
        if (storageStatus.isDenied) {
          bool shouldContinue = await _showPermissionRationaleDialog(
              "Storage Permission Required",
              "We need permission to save the Excel file to your device. Please grant access to continue."
          );

          if (!shouldContinue) return false;
        }

        // Request basic storage permission
        storageStatus = await Permission.storage.request();

        if (storageStatus.isGranted) {
          // Try the more powerful permission if basic is granted
          final manageStatus = await Permission.manageExternalStorage.request();
          return manageStatus.isGranted;
        } else if (storageStatus.isPermanentlyDenied) {
          _showPermissionPermanentlyDeniedDialog();
          return false;
        } else {
          _showToast("Storage permissions needed for Android 11+", isError: true);
          return false;
        }
      } else {
        // Android 10 and below
        storageStatus = await Permission.storage.status;

        if (storageStatus.isGranted) return true;

        if (storageStatus.isDenied) {
          bool shouldContinue = await _showPermissionRationaleDialog(
              "Storage Permission Required",
              "We need permission to save the Excel file to your device. Please grant access to continue."
          );

          if (!shouldContinue) return false;
        }

        storageStatus = await Permission.storage.request();

        if (storageStatus.isGranted) {
          return true;
        } else if (storageStatus.isPermanentlyDenied) {
          _showPermissionPermanentlyDeniedDialog();
          return false;
        } else {
          _showToast("Storage permission needed to download files", isError: true);
          return false;
        }
      }
    }

    // For iOS, request photos permission
    if (Platform.isIOS) {
      final status = await Permission.photos.status;

      if (status.isGranted) return true;

      if (status.isDenied) {
        bool shouldContinue = await _showPermissionRationaleDialog(
            "Photos Access Required",
            "We need access to your Photos to save the Excel file. Please grant access to continue."
        );

        if (!shouldContinue) return false;
      }

      final requestStatus = await Permission.photos.request();

      if (requestStatus.isGranted) {
        return true;
      } else if (requestStatus.isPermanentlyDenied) {
        _showPermissionPermanentlyDeniedDialog();
        return false;
      } else {
        _showToast("Photos access needed to save files", isError: true);
        return false;
      }
    }

    // Default allow for other platforms
    return true;
  }

  Future<bool> _showPermissionRationaleDialog(String title, String message) async {
    return (await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Builder(
          builder: (BuildContext localContext) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(localContext).pop(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Not Now"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(localContext).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff185794),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Continue"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    )) ?? false;
  }

  /*void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to download files but has been permanently denied. Please enable it in app settings.',
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
  }*/

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
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Permission Denied',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Storage permission is required to download files but has been permanently denied.\n\nPlease enable it manually in app settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Open Settings'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous button
            if (_currentPage > 0)
              InkWell(
                onTap: () {
                  if (_selectedMedicalField != null && _selectedMedicalField != 'All') {
                    _loadProductsByField(_selectedMedicalField!, page: _currentPage - 1);
                  } else {
                    _loadProductData(page: _currentPage - 1);
                  }
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

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6), // Adjust spacing here
                child: InkWell(
                  onTap: () {
                    if (_currentPage != pageNumber) {
                      if (_selectedMedicalField != null && _selectedMedicalField != 'All') {
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
                        color: const Color(0xff185794),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Next button
            if (((_currentPage + 1) * itemsPerPage) < _totalProductCount)
              InkWell(
                onTap: () {
                  if (_selectedMedicalField != null && _selectedMedicalField != 'All') {
                    _loadProductsByField(_selectedMedicalField!, page: _currentPage + 1);
                  } else {
                    _loadProductData(page: _currentPage + 1);
                  }
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
          setState(() {
            _isRefreshing = true;
            // Reset to "All" when refreshing
            _selectedMedicalField = null;
            _searchController.clear();
          });
          // First refresh the account status
          await _validateUserAndLoadData();
          // Then load all products (not filtered by field)
          await _loadProductData(page: 0);
        },
        color: const Color(0xff185794),
        backgroundColor: Colors.white,
        displacement: 40,
        strokeWidth: 3,
        child: Column(
          children: [
            _buildSearchBar(horizontalPadding),
            const SizedBox(height: 1),
            _buildHorizontalMenu(),
            const SizedBox(height: 1),
            _buildTableHeader(horizontalPadding),
            const SizedBox(height: 1),
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
            width: 250,
            height: 250,
            fit: BoxFit.contain,
          ),
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
            "assets/animations/internet.json",
            width: 250,
            height: 250,
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