import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:pharma_five/service/api_service.dart';
import 'package:pharma_five/ui/admin/product_details_screen.dart';
import 'package:pharma_five/ui/admin/product_details_screen_admin.dart';
import 'package:pharma_five/ui/admin/widget/bulk_upload_widget.dart';
import '../../model/get_product_listing_response_model.dart';
import '../../model/get_product_more_response_model.dart';
import '../../model/product_search_listing_response_model.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../model/update_product_listing_request_model.dart';
import 'edit_full_product_screen.dart';

class ProductListTab extends StatefulWidget {
  const ProductListTab({Key? key}) : super(key: key);

  @override
  State<ProductListTab> createState() => _ProductListTabState();
}
class _ProductListTabState extends State<ProductListTab> {
  final ApiService _apiService = ApiService();
  // final TextEditingController _searchController = TextEditingController();
  final TextEditingController _medicineNameEditController = TextEditingController();
  final TextEditingController _genericNameEditController = TextEditingController();
  final TextEditingController _manufacturerEditController = TextEditingController();
  final TextEditingController _indicationsEditController = TextEditingController();
  final TextEditingController _medicineNameAddController = TextEditingController();
  final TextEditingController _genericNameAddController = TextEditingController();
  final TextEditingController _manufacturerAddController = TextEditingController();
  final TextEditingController _indicationsAddController = TextEditingController();

  // Change this type to match what your API returns
  ///Checking if its updated or not
  List<GetProducts> products = [];
  List<GetProducts> filteredProducts = [];
  final int _itemsPerPage = 10;
  late final FocusNode _searchFocusNode;

  int _currentProductPage = 0;
  int _totalProductCount = 0;
  bool _hasMoreProduct = true;
  bool isProductLoading = false;
  bool _isConnected = true;
  bool _isAddingProduct = false;
  bool _isEditingProduct = false;
  bool _isUpdating = false;
  Map<String, String>? _selectedProductForEdit;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isCheckingConnectivity = false;
  bool _lastConnectionStatus = true;
  bool _isLoading = false;
  final String selectedStatus = 'all';
  Timer? _searchDebounce;
  late final Function(File file) onFileSelected;
  bool _isUploadingExcel = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchLoading = false;
  String _searchErrorMessage = '';
  String? _selectedMedicalField;
  bool _isProductsLoading = false; // Flag for product loading
  String _errorMessage = ''; // Store error messages from API calls
  List<Products> _allProducts = [];
  List<Products> _filteredProducts = [];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isSearchActive = false;
  String _activeSearchTerm = '';


  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();

    // First, check initial connection status
    _checkInitialInternetStatus().then((_) {
      // Only try to load products if we're connected
      if (_isConnected && mounted) {
        _selectedMedicalField = null;
        loadProducts(page: 0);
      }
    });

    // Set up ongoing connectivity monitoring
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) async {
      final connected = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);

      // Only process if connection state actually changed
      if (_isConnected != connected && mounted) {
        setState(() {
          _isConnected = connected;
        });

        // Fluttertoast.showToast(
        //   msg: connected ? "Internet connected" : "Internet disconnected",
        //   backgroundColor: connected ? Color(0xff185794) : Colors.red,
        // );

        // On reconnection, always refresh the current view
        if (connected && mounted) {
          // Short delay to ensure network is actually ready
          await Future.delayed(Duration(milliseconds: 500));

          // Refresh product list based on current state
          if (_selectedMedicalField != null) {
            await _loadProductsByField(_selectedMedicalField!, page: _currentPage);
          } else {
            await loadProducts(page: _currentPage);
          }
        }
      }
    });
  }

  Future<void> _checkInitialInternetStatus() async {
    if (_isCheckingConnectivity) return;
    _isCheckingConnectivity = true;

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isConnected = false);
      }
    } finally {
      _isCheckingConnectivity = false;
    }
  }

  Future<bool> _requestFileOperationPermissions() async {
    // Check current connection first
    if (!_isConnected) {
      _showToast("No internet connection", isError: true);
      return false;
    }

    // Platform-specific permission handling
    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      return await _requestIOSPermissions();
    } else {
      // Default fallback for other platforms
      _showToast("File operations may not be fully supported on this platform", isError: true);
      return true;
    }
  }

  Future<bool> _requestAndroidPermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // Android 13+ (API 33+)
    if (sdkInt >= 33) {
      // Request READ_MEDIA_IMAGES for accessing media files
      final photosStatus = await Permission.photos.request();
      // Request READ_MEDIA_DOCUMENTS for importing Excel files
      final documentsStatus = await Permission.mediaLibrary.request();

      if (photosStatus.isGranted && documentsStatus.isGranted) {
        return true;
      }

      if (photosStatus.isPermanentlyDenied || documentsStatus.isPermanentlyDenied) {
        _showPermissionSettingsDialog(
            "Media access required",
            "Access to photos and documents is required for importing and exporting Excel files."
        );
        return false;
      }

      if (photosStatus.isDenied || documentsStatus.isDenied) {
        _showToast("Media permissions are required for Excel operations", isError: true);
        return false;
      }
    }
    // Android 11-12 (API 30-32)
    else if (sdkInt >= 30) {
      // Try regular storage permission first
      final storageStatus = await Permission.storage.request();

      if (storageStatus.isGranted) {
        // For Android 11+, we need MANAGE_EXTERNAL_STORAGE for full access
        final manageStatus = await Permission.manageExternalStorage.request();
        if (manageStatus.isGranted) {
          return true;
        }

        // If basic storage permission is granted but not manage, we can still try
        // to use more restricted access methods (scoped storage)
        if (manageStatus.isPermanentlyDenied) {
          _showPermissionSettingsDialog(
              "Storage access limited",
              "For full access to manage files, additional permissions are needed. " +
                  "Excel files will be saved to app-specific folders.",
              isWarningOnly: true
          );
        }
        return true;
      }

      if (storageStatus.isPermanentlyDenied) {
        _showPermissionSettingsDialog(
            "Storage access required",
            "Storage access is required for importing and exporting Excel files."
        );
        return false;
      }
    }
    // Android 10 and below (API 29-)
    else {
      final status = await Permission.storage.request();

      if (status.isGranted) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        _showPermissionSettingsDialog(
            "Storage access required",
            "Storage access is required for importing and exporting Excel files."
        );
        return false;
      }
    }

    _showToast("Storage permissions are needed for Excel operations", isError: true);
    return false;
  }

  Future<bool> _requestIOSPermissions() async {
    final documentsStatus = await Permission.storage.request();

    if (documentsStatus.isGranted) {
      return true;
    }

    if (documentsStatus.isPermanentlyDenied) {
      _showPermissionSettingsDialog(
          "Storage access required",
          "This app needs permission to store Excel files in your device's Documents directory."
      );
      return false;
    }

    _showToast("Storage permission is required for Excel file operations.", isError: true);
    return false;
  }

  void _showPermissionSettingsDialog(String title, String message, {bool isWarningOnly = false}) {
    final ThemeData theme = Theme.of(context);
    final Color primaryColor = const Color(0xff185794);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(10)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xff185794),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (!isWarningOnly)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Please enable the required permissions in your device settings.',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: primaryColor),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Expanded(child: SizedBox(width: 10)),
              if (!isWarningOnly)
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Open Settings',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      openAppSettings();
                    },
                  ),
                ),
              if (isWarningOnly)
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue Anyway',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<Directory?> _getAppropriateDirectory() async {
    Directory? directory;

    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 30) {
          // Android 11+ (API 30+)
          final manageStatus = await Permission.manageExternalStorage.status;
          if (manageStatus.isGranted) {
            directory = Directory("/storage/emulated/0/Download");
            if (!await directory.exists()) {
              directory = await getExternalStorageDirectory();
            }
          } else {
            // Use app-specific external directory (scoped storage)
            directory = await getExternalStorageDirectory();
          }
        } else {
          // Android 10 and below
          directory = Directory("/storage/emulated/0/Download");
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        }
      } else if (Platform.isIOS) {
        // ✅ Use Documents directory – visible in Files app, safe for .xlsx
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Fallback for other platforms
        directory = await getApplicationDocumentsDirectory();
      }

      return directory;
    } catch (e) {
      // Catch any exception and fallback to application documents directory
      debugPrint("Directory access error: $e");
      return await getApplicationDocumentsDirectory();
    }
  }

  // 2️⃣ Search method
  Future<void> _searchProducts(String searchTerm, {int page = 0}) async {
    if (!_isConnected) {
      // _showToast("No internet connection", isError: true);
      return;
    }

    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isSearchActive = false;
        _activeSearchTerm = '';
        _searchErrorMessage = '';
        _currentProductPage = 0;
      });
      await loadProducts(page: 0);
      return;
    }

    setState(() {
      _isSearchActive = true;
      _activeSearchTerm = trimmed;
      _isSearchLoading = true;
      _searchErrorMessage = '';
      _currentProductPage = page;
    });

    try {
      final result = await _apiService.searchProducts(trimmed, index: page, limit: _itemsPerPage);
      if (result != null && result.searchProducts != null) {
        final converted = result.searchProducts!.map((sp) {
          return GetProducts(
            serialNo: sp.serialNo,
            medicineName: sp.medicineName,
            genericName: sp.genericName,
          );
        }).toList();

        setState(() {
          products = converted;
          filteredProducts = converted;
          _totalProductCount = result.totalCount ?? converted.length;
          _hasMoreProduct = ((page + 1) * _itemsPerPage) < _totalProductCount;
        });
      } else {
        setState(() {
          products = [];
          filteredProducts = [];
          _searchErrorMessage = 'No products found for "$trimmed"';
          _hasMoreProduct = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchErrorMessage = 'Search error: ${e.toString()}';
        products = [];
        filteredProducts = [];
        _hasMoreProduct = false;
      });
    } finally {
      setState(() {
        _isSearchLoading = false;
      });
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

  Future<void> _loadProductsByField(String field, {int page = 0}) async {
    if (!_isConnected) {
      // _showToast("No internet connection", isError: true);
      return;
    }

    setState(() {
      isProductLoading = true;
      _selectedMedicalField = field;
      _currentPage = page;
    });

    try {
      final resp = await _apiService.fetchProductsByField(
        field: field,
        index: page,
        limit: _itemsPerPage,
      );

      if (resp?.fieldProducts != null) {
        final converted = resp!.fieldProducts!
            .map((f) => GetProducts(
          serialNo: f.serialNo,
          medicineName: f.medicineName,
          genericName: f.genericName,
        ))
            .toList();

        if (mounted) {
          setState(() {
            products = converted;
            filteredProducts = converted;
            _totalProductCount = resp.totalCount ?? converted.length;
            _hasMoreProduct = ((page + 1) * _itemsPerPage) < _totalProductCount;
            isProductLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            products = [];
            filteredProducts = [];
            _hasMoreProduct = false;
            isProductLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProductLoading = false;
          products = [];
          filteredProducts = [];
        });
        _showToast("Error loading $field products: $e", isError: true);
      }
    }
  }

  Widget _buildMenuItem(IconData icon, String label) {
    final isSelected = (_selectedMedicalField == null && label == "All") ||
        (_selectedMedicalField != null && _selectedMedicalField == label);

    return OutlinedButton.icon(
      onPressed: () {
        // clear any search text
        _searchController.clear();

        if (label == "All") {
          setState(() {
            _selectedMedicalField = null;
            _currentPage = 0;
            isProductLoading = true; // Show loader immediately
          });
          loadProducts(page: 0);
        } else {
          setState(() {
            _selectedMedicalField = label;
            _currentPage = 0;
            isProductLoading = true; // Show loader immediately
          });
          _loadProductsByField(label, page: 0);
        }
      },
      icon: Icon(icon, color: isSelected ? Colors.white : Color(0xff185794)),
      label: Text(label,
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

  Future<void> loadProducts({int page = 0}) async {
    if (!_isConnected) {
      // _showToast("No internet connection", isError: true);
      return;
    }

    setState(() {
      isProductLoading = true;
      _currentPage = page;
    });

    try {
      final response = await _apiService.fetchPaginatedProducts(
        index: page,
        limit: _itemsPerPage,
      );

      if (response != null && response.getProducts != null) {
        final converted = response.getProducts!
            .map((p) => GetProducts(
          serialNo: p.serialNo,
          medicineName: p.medicineName,
          genericName: p.genericName,
        ))
            .toList();

        if (mounted) {
          setState(() {
            products = converted;
            filteredProducts = converted;
            _totalProductCount = response.totalCount ?? 0;
            _hasMoreProduct = ((page + 1) * _itemsPerPage) < _totalProductCount;
            isProductLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            products = [];
            filteredProducts = [];
            _hasMoreProduct = false;
            isProductLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProductLoading = false;
          products = [];
          filteredProducts = [];
        });
        _showToast("Error loading page $page: $e", isError: true);
      }
    }
  }

  Future<void> _pickAndUploadExcelFile() async {
    Navigator.of(context).pop(); // Close confirmation dialog

    final hasPermission = await _requestFileOperationPermissions();
    if (!hasPermission) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
        lockParentWindow: true,
      );

      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);

      if (!await file.exists()) {
        _showToast("Selected file doesn't exist", isError: true);
        return;
      }

      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        _showToast("File is too large. Max: 10MB", isError: true);
        return;
      }

      // Show loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loaderContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('assets/animations/uploading.json', width: 150, height: 150),
                const SizedBox(height: 16),
                const Text("This might take some time...", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Uploading...", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      );

      // Set 90s timeout
      bool timedOut = false;
      final timer = Timer(const Duration(seconds: 300), () {
        timedOut = true;
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close loader
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Timeout"),
              content: const Text("Try after sometime"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          );
        }
      });

      try {
        final response = await _apiService.uploadBulkProductList(file);
        if (timer.isActive) timer.cancel(); // Cancel timeout if finished early
        if (!mounted || timedOut) return;

        Navigator.of(context, rootNavigator: true).pop(); // Close loader

        if (response != null && response.toLowerCase().contains("uploaded")) {
          _showToast(response);
          await loadProducts(page: _currentProductPage);
        } else {
          _showToast(response ?? "Upload failed", isError: true);
        }
      } catch (e) {
        if (timer.isActive) timer.cancel();
        if (!mounted || timedOut) return;

        Navigator.of(context, rootNavigator: true).pop(); // Close loader
        _showToast("Upload failed: ${e.toString()}", isError: true);
      }
    } catch (e) {
      _showToast("Error: ${e.toString()}", isError: true);
    }
  }

  void _closeLoaderDialogIfOpen() {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _currentProductPage = 0;
      });
      loadProducts(page: _currentPage);
    });
  }

  List<GetProducts> getPaginatedProducts() {
    final startIndex = _currentProductPage * 10;
    if (startIndex >= filteredProducts.length) return [];
    final endIndex = startIndex + 10;
    return filteredProducts.sublist(
      startIndex,
      endIndex > filteredProducts.length ? filteredProducts.length : endIndex,
    );
  }

  void _showToast(String message, {bool isError = false, bool isWarning = false}) {
    Color backgroundColor;
    if (isError) {
      backgroundColor = Colors.red.shade700;
    } else if (isWarning) {
      backgroundColor = Colors.orange.shade700;
    } else {
      backgroundColor = Color(0xff185794);
    }

    Fluttertoast.showToast(
      msg: message,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _medicineNameEditController.dispose();
    _genericNameEditController.dispose();
    _manufacturerEditController.dispose();
    _indicationsEditController.dispose();
    _medicineNameAddController.dispose();
    _genericNameAddController.dispose();
    _manufacturerAddController.dispose();
    _indicationsAddController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: _isEditingProduct
          ? _buildEditProductScreen()
          : adminProductListing(),
    ); // Remove _isAddingProduct condition
  }

  Future<void> _downloadExcelFile() async {
    setState(() => _isLoading = true);

    try {
      final hasPermission = await _requestFileOperationPermissions();
      if (!hasPermission) {
        setState(() => _isLoading = false);
        return;
      }

      _showToast("Downloading Excel file...");

      final directory = await _getAppropriateDirectory();
      if (directory == null) {
        _showToast("Failed to access storage directory", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final url = Uri.parse("http://13.49.224.44:8080/api/product/download");
      final filename = "product_list_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final downloadPath = "${directory.path}/$filename";

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException("The connection timed out."),
      );

      if (response.statusCode == 200) {
        final file = File(downloadPath);
        await file.writeAsBytes(response.bodyBytes);

        if (Platform.isIOS) {
          try {
            await file.setLastModified(DateTime.now());
          } catch (e) {
            debugPrint("iOS file tag error: $e");
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Excel downloaded to: $downloadPath"),
              backgroundColor: Color(0xff185794),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: "Open",
                textColor: Colors.white,
                onPressed: () async {
                  try {
                    await OpenFile.open(downloadPath);
                  } catch (e) {
                    _showToast("Unable to open file: $e", isError: true);
                  }
                },
              ),
            ),
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _showToast("Authorization error. Please log in again.", isError: true);
      } else if (response.statusCode >= 500) {
        _showToast("Server error. Please try again later.", isError: true);
      } else {
        _showToast("Download failed: ${response.statusCode}", isError: true);
      }
    } on SocketException {
      _showToast("Network error. Please check your internet.", isError: true);
    } on TimeoutException {
      _showToast("Download timed out. Please try again.", isError: true);
    } catch (e) {
      debugPrint("Download error: $e");
      _showToast("Unexpected error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSearchError() {
    if (_searchErrorMessage.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        _searchErrorMessage,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }

  Widget adminProductListing() {
    if (_isUploadingExcel) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Lottie.asset("assets/animations/uploading.json", width: 150, height: 150),
        ),
      );
    }

    return Scaffold(
      body:
      Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Header Row with Logo and Search
              Row(
                children: [
                  // App Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Image.asset(
                      "assets/images/logo_pf.png",
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title (optional - you can remove if not needed)
                  const Spacer(),
                  // Search field moved to header row
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        autofocus: false,
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) async {
                          await _searchProducts(value);
                          FocusScope.of(context).unfocus();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search products…',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchProducts(''); // back to full list
                                  },
                                ),
                              IconButton(
                                icon: _isSearchLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Color(0xff185794),strokeWidth: 2),
                                )
                                    : const Icon(Icons.search, size: 20),
                                onPressed: () async {
                                  await _searchProducts(_searchController.text);
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ],
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // ✅ updated here
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Products",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _downloadExcelFile,
                        icon: const Icon(Icons.file_download, size: 18, color: Colors.white),
                        label: const Text("Excel", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade800,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showBulkUploadConfirmation(context);
                          setState(() {
                            _isAddingProduct = true;
                          });
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text("Add", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff185794),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _buildHorizontalMenu(),

              const SizedBox(height: 10),

              // Table Header
              buildTableHeader(),

              const SizedBox(height: 4),

              // Show search error if present
              _buildSearchError(),

              _buildConnectionBanner(),
              // Product List + Pull to Refresh
              Expanded(
                child: !_isConnected
                    ? _buildNoInternetWidget()
                    : isProductLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff185794),
                  ),
                )
                    : filteredProducts.isEmpty
                    ? _buildNoDataWidget()
                    :
                RefreshIndicator(
                  onRefresh: () async {
                    if (_selectedMedicalField != null) {
                      await _loadProductsByField(_selectedMedicalField!, page: _currentPage);
                    } else {
                      await loadProducts(page: _currentPage);
                    }
                    _showToast("Products refreshed", isError: false);
                  },
                  color: const Color(0xff185794),
                  strokeWidth: 2.5,
                  displacement: 40,
                  child: _buildProductList(),
                ),
              ),

              // Pagination
              if (!isProductLoading && filteredProducts.isNotEmpty)
                _buildPagination(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filteredProducts.length,
      // itemCount: getPaginatedProducts().length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final absoluteIndex = _currentProductPage * _itemsPerPage + index;
        return buildTableRow(absoluteIndex, product);
      },
    );
  }

  Widget _buildEditProductScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  onPressed: () {
                    setState(() {
                      _isEditingProduct = false;
                      _selectedProductForEdit = null;
                    });
                  },
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'Actions',
                onSelected: (value) {
                  if (value == 'clear') {
                    _medicineNameEditController.clear();
                    _genericNameEditController.clear();
                    _manufacturerEditController.clear();
                    _indicationsEditController.clear();
                    _showToast("Form cleared");
                  }
                  if (value == 'cancel') {
                    setState(() => _isEditingProduct = false);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.clear),
                      title: Text('Clear Form'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: ListTile(
                      leading: Icon(Icons.cancel),
                      title: Text('Cancel Edit'),
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            '${_medicineNameEditController.text} (${_genericNameEditController.text})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLabeledInput("Medicine name", _medicineNameEditController),
                    const SizedBox(height: 16),
                    _buildLabeledInput("Generic name", _genericNameEditController),
                    const SizedBox(height: 16),
                    _buildLabeledInput("Manufactured By", _manufacturerEditController),
                    const SizedBox(height: 16),
                    _buildLabeledInput("Indications", _indicationsEditController),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff262A88),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _showToast("Update logic not implemented yet", isError: true);
                      },
                      child: const Text("Update", style: TextStyle(color: Colors.white)),
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

  Widget _buildConnectionBanner() {
    if (_isConnected) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  void _showBulkUploadConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Upload Bulk Products",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickAndUploadExcelFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 64),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Image.asset('assets/images/bulk_upload.png', width: 60, height: 60),
                        const SizedBox(height: 8),
                        const Text("Drag and Drop here",
                            style: TextStyle(color: Colors.grey, fontSize: 10)),
                        const SizedBox(height: 4),
                        const Text("Or",
                            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                        const SizedBox(height: 4),
                        const Text("Browse",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff185794))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Supported file: Excel (.xlsx) | Max size: 10MB",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildTableHeader() {
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
              flex: 2,
              child: Center(
                  child: Text('Actions',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  // FIXED IMPLEMENTATION: Make the row responsive and prevent overflow
  Widget buildTableRow(int index, GetProducts product) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric( horizontal: 2,vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text('${index + 1}'), // Changed to start from 1 regardless of pagination
            ),
            Expanded(
              flex: 3,
              child: Text(
                product.medicineName ?? '-',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                product.genericName ?? '-',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            // Actions as PopupMenu
            PopupMenuButton<String>(
              color: const Color(0xff185794),
              elevation: 10,
              iconColor: Colors.white,
              tooltip: 'Actions',
              onSelected: (value) async {
                if (value == 'view') {
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
                        builder: (_) => ProductDetailsScreenAdmin(getProductsContent: detailedProduct),
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
                } else if (value == 'edit') {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Lottie.asset('assets/animations/more_product_loading.json', width: 200, height: 200),
                          const SizedBox(height: 12),
                          const Text("Fetching Product Details...", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  );

                  final response = await ApiService().fetchProductDetailsBySerialNo(product.serialNo ?? 0);
                  Navigator.pop(context); // Close the loader

                  if (response != null &&
                      response.getProductsContent != null &&
                      response.getProductsContent!.isNotEmpty) {
                    final detailedProduct = response.getProductsContent!.first;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditFullProductScreen(
                          product: UpdateProductListingRequestModel.fromJson(detailedProduct.toJson()),
                        ),
                      ),
                    ).then((shouldRefresh) {
                      if (shouldRefresh == true) loadProducts(page: _currentProductPage);
                    });
                  } else {
                    _showToast("Failed to load full product details", isError: true);
                  }
                } else if (value == 'delete') {
                  _showDeleteConfirmationDialog(product);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: ListTile(
                    leading: Icon(Icons.visibility, color: Colors.white),
                    title: Text('View', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const PopupMenuDivider(height: 1), // Divider 1
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit, color: Colors.white),
                    title: Text('Edit', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const PopupMenuDivider(height: 1), // Divider 2
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert, color: Color(0xff185794)),
            )
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
          _buildMenuItem(Icons.biotech, "Oncology"),
          const SizedBox(width: 12),
          _buildMenuItem(Icons.bloodtype, "Hematology"),
          const SizedBox(width: 12),
          _buildMenuItem(Icons.child_care, "Paediatric Oncology"),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(GetProducts product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this product?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'Medicine: ${product.medicineName ?? "N/A"}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Generic Name: ${product.genericName ?? "N/A"}',
                style: const TextStyle(fontSize: 14),
              ),
              // Text(
              //   'Manufacturer: ${product.manufacturedBy ?? "N/A"}',
              //   style: const TextStyle(fontSize: 14),
              // ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _deleteProduct(product);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

// Add this method to perform the actual delete operation
  Future<void> _deleteProduct(GetProducts product) async {
    if (product.serialNo == null) {
      _showToast("Product ID is missing", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.deleteProduct(product.serialNo.toString());

      if (result['success'] == true) {
        _showToast("Product deleted successfully");
        await loadProducts(page: _currentPage); // Refresh the product list
      } else {
        _showToast(result['message'] ?? "Failed to delete product", isError: true);
      }
    } catch (e) {
      _showToast("Error: ${e.toString()}", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildProductPagination() {
    if (filteredProducts.isEmpty && _currentProductPage == 0) {
      return const SizedBox.shrink(); // No pagination if no products on first page
    }
    // Calculate total pages based on total product count
    final int productsPerPage = 10;
    final int totalPages = (_totalProductCount / productsPerPage).ceil();
    // If we don't have total count but have hasMore flag
    final int maxPageToShow = _totalProductCount > 0
        ? totalPages
        : _currentProductPage + (_hasMoreProduct ? 2 : 1);
    // Don't show any pagination if we have nothing
    if (maxPageToShow <= 1 && filteredProducts.isEmpty) {
      return const SizedBox.shrink();
    }
    // Calculate a reasonable range of pages to show
    int totalPagesToShow = 5; // Show max 5 page buttons at a time
    int startPage = max(0, min(_currentProductPage - 2, maxPageToShow - totalPagesToShow));
    int endPage = min(startPage + totalPagesToShow - 1, maxPageToShow - 1);
    // Ensure we don't show non-existent pages
    endPage = max(0, min(endPage, maxPageToShow - 1));
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
            // Previous page button
            if (_currentProductPage > 0)
              InkWell(
                onTap: () {
                  setState(() {
                    _currentProductPage = _currentProductPage - 1;
                  });
                  loadProducts(page: _currentPage);
                },
                borderRadius: BorderRadius.circular(6),
                splashColor: Colors.grey.shade300,
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
            // Page number buttons - only show pages that should exist
            ...List.generate(endPage - startPage + 1, (index) {
              final int pageNumber = startPage + index;
              final bool isSelected = pageNumber == _currentProductPage;

              // Don't render buttons for pages beyond our maximum
              if (pageNumber >= maxPageToShow) {
                return const SizedBox.shrink();
              }
              return InkWell(
                onTap: () {
                  if (_currentProductPage != pageNumber) {
                    setState(() {
                      _currentProductPage = pageNumber;
                    });
                    loadProducts(page: _currentPage);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                splashColor: Colors.grey.shade300,
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
            // Next page button - only if there are more products
            if (_currentProductPage < maxPageToShow - 1 && _hasMoreProduct)
              InkWell(
                onTap: () {
                  setState(() {
                    _currentProductPage = _currentProductPage + 1;
                  });
                  loadProducts(page: _currentPage);
                },
                borderRadius: BorderRadius.circular(6),
                splashColor: Colors.grey.shade300,
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
  Widget _buildNoInternetWidget() {
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
          const SizedBox(height: 6),
        ],
      ),
    );
  }
// - _buildNoDataWidget
  Widget _buildNoDataWidget(){
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              "assets/animations/no_data_found.json",
              width: 200,
            ),
            const SizedBox(height: 10),
            const Text(
              "No products found.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
        ));
  }
  Widget _buildLabeledInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: const Color(0xfff5f5f5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xff262A88)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xff262A88), width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
  Widget _buildPagination() {
    if (filteredProducts.isEmpty && _currentProductPage == 0) {
      return const SizedBox.shrink(); // No pagination needed
    }

    final int totalPages = (_totalProductCount / _itemsPerPage).ceil();
    const int maxPagesToShow = 7;

    int startPage = max(0, min(_currentProductPage - (maxPagesToShow ~/ 2), totalPages - maxPagesToShow));
    int endPage = min(startPage + maxPagesToShow - 1, totalPages - 1);

    final double buttonSize = 30;
    final double fontSize = 14;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentProductPage > 0)
            _buildPageArrow(isNext: false, fontSize: fontSize, buttonSize: buttonSize),

          ...List.generate(endPage - startPage + 1, (index) {
            final int pageNumber = startPage + index;
            final bool isSelected = pageNumber == _currentProductPage;

            return InkWell(
              onTap: () {
                if (_currentProductPage != pageNumber) {
                  setState(() => _currentProductPage = pageNumber);

                  if (_searchController.text.trim().isNotEmpty) {
                    _searchProducts(_searchController.text.trim(), page: pageNumber);
                  } else if (_selectedMedicalField != null) {
                    _loadProductsByField(_selectedMedicalField!, page: pageNumber);
                  } else {
                    loadProducts(page: pageNumber);
                  }
                }
              },
              borderRadius: BorderRadius.circular(6),
              splashColor: Colors.grey.shade300,
              child: Container(
                width: buttonSize,
                height: buttonSize,
                margin: const EdgeInsets.symmetric(horizontal: 4),
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

          if (_currentProductPage < totalPages - 1 && _hasMoreProduct)
            _buildPageArrow(isNext: true, fontSize: fontSize, buttonSize: buttonSize),
        ],
      ),
    );
  }
  Widget _buildPageArrow({
    required bool isNext,
    required double fontSize,
    required double buttonSize,
  }) {
    final targetPage = isNext ? _currentProductPage + 1 : _currentProductPage - 1;

    return InkWell(
      onTap: () {
        setState(() => _currentProductPage = targetPage);

        if (_searchController.text.trim().isNotEmpty) {
          _searchProducts(_searchController.text.trim(), page: targetPage);
        } else if (_selectedMedicalField != null) {
          _loadProductsByField(_selectedMedicalField!, page: targetPage);
        } else {
          loadProducts(page: targetPage);
        }
      },
      borderRadius: BorderRadius.circular(6),
      splashColor: Colors.grey.shade300,
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
}