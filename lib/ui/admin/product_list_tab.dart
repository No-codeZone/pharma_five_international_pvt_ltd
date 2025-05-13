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
import 'package:pharma_five/ui/admin/widget/bulk_upload_widget.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _medicineNameEditController = TextEditingController();
  final TextEditingController _genericNameEditController = TextEditingController();
  final TextEditingController _manufacturerEditController = TextEditingController();
  final TextEditingController _indicationsEditController = TextEditingController();
  final TextEditingController _medicineNameAddController = TextEditingController();
  final TextEditingController _genericNameAddController = TextEditingController();
  final TextEditingController _manufacturerAddController = TextEditingController();
  final TextEditingController _indicationsAddController = TextEditingController();

  // Change this type to match what your API returns
  List<Products> products = [];
  List<Products> filteredProducts = [];

  int _currentProductPage = 0;
  int _totalProductCount = 0;
  bool _hasMoreProduct = true;
  bool isProductLoading = false;
  bool _isConnected = true;
  bool _isAddingProduct = false;
  bool _isEditingProduct = false;
  bool _isUpdating = false;
  Map<String, String>? _selectedProductForEdit;
  late StreamSubscription<List<ConnectivityResult>> _connectionSubscription;
  bool _lastConnectionStatus = true;
  bool _isLoading = false;
  final String selectedStatus = 'all';
  Timer? _searchDebounce;
  late final Function(File file) onFileSelected;
  bool _isUploadingExcel = false;

  @override
  void initState() {
    super.initState();
    _checkInternetStatus().then((connected) {
      if (connected) loadProducts();
    });

    _connectionSubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final connected = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);

      if (_lastConnectionStatus != connected) {
        _lastConnectionStatus = connected;
        setState(() {
          _isConnected = connected;
        });

        Fluttertoast.showToast(
          msg: connected ? "Internet connected" : "Internet disconnected",
          backgroundColor: connected ? Colors.green : Colors.red,
        );

        if (connected) await loadProducts();
      }
    });

    _searchController.addListener(onSearchChanged);
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

  Future<void> loadProducts() async {
    setState(() => isProductLoading = true);

    try {
      final response = await _apiService.fetchProductListWithPagination(
        index: _currentProductPage,
        limit: 10,
        search: _searchController.text.trim(),
      );

      // Parse the products directly from the API response
      final List<Products> productsData = List<Products>.from(response['products']);
      final hasMore = response['hasMore'] ?? false;

      // Store the total count if available in the response
      if (response.containsKey('totalCount')) {
        _totalProductCount = response['totalCount'];
      }

      setState(() {
        products = productsData;
        filteredProducts = productsData; // Set filtered products directly from API
        _hasMoreProduct = hasMore;
        isProductLoading = false;

        // If current page has no data and it's not the first page, go back one page
        if (productsData.isEmpty && _currentProductPage > 0) {
          _currentProductPage--;
          // Don't call loadProducts() here to avoid infinite loop if server returns empty
        }
      });
    } catch (e) {
      print("Error loading products: $e");
      setState(() {
        isProductLoading = false;
        products = [];
        filteredProducts = [];
      });
      _showToast("Failed to load products: $e", isError: true);
    }
  }

  void onSearchChanged() {
    // Don't need to do local filtering since we're going to call the API
    // Just trigger the API call with the current search text

    // Debounce the search input to prevent excessive API calls
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      // Reset to first page when searching
      setState(() {
        _currentProductPage = 0;
      });

      // Call API with search parameter
      loadProducts();
    });
  }

  List<Products> getPaginatedProducts() {
    final startIndex = _currentProductPage * 10;
    if (startIndex >= filteredProducts.length) return [];
    final endIndex = startIndex + 10;
    return filteredProducts.sublist(
      startIndex,
      endIndex > filteredProducts.length ? filteredProducts.length : endIndex,
    );
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

  @override
  void dispose() {
    // Cancel the debounce timer when disposing
    _searchDebounce?.cancel();
    _connectionSubscription.cancel();
    _searchController.dispose();
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

  /*@override
  Widget build(BuildContext context) {
    return _isEditingProduct
        ? _buildEditProductScreen()
        : _isAddingProduct
        ? _buildAddProductScreen()
        : adminProductListing();
  }*/

  @override
  Widget build(BuildContext context) {
    return _isEditingProduct
        ? _buildEditProductScreen()
        : adminProductListing(); // Remove _isAddingProduct condition
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

  Widget adminProductListing() {
    debugPrint(
        'Rendering AWS DB product listing... Found ${products.length} products');

    if (_isUploadingExcel) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Lottie.asset("assets/animations/uploading.json", width: 150, height: 150),
        ),
      );
    }


    return Scaffold(
      body: Container(
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
                      "assets/images/logo_pf.png", // Replace with your actual logo path
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
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add Product Button
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

              // Table Header
              buildTableHeader(),

              const SizedBox(height: 4),

              // Product List + Pull to Refresh
              Expanded(
                child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        isProductLoading = true;
                      });
                      await loadProducts();
                      Fluttertoast.showToast(
                        msg: "Products refreshed",
                        backgroundColor: Colors.green,
                      );
                    },
                    color: const Color(0xff185794),
                    strokeWidth: 2.5,
                    displacement: 40,
                    child: isProductLoading
                        ? const Center(child: CircularProgressIndicator())
                        : !_isConnected
                        ? _buildNoInternetWidget()
                        : filteredProducts.isEmpty
                        ? _buildNoDataWidget()
                        : _buildProductList()
                ),
              ),

              // Pagination
              buildProductPagination(),
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
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return buildTableRow(index, product);
        }
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

  /*Widget _buildAddProductScreen() {
    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              "assets/animations/internet.json",
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Internet Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return
      BulkUploadWidget(
      onFileSelected: (file) async {
        _showToast("Uploading Excel file...", isError: false);
        final response = await _apiService.uploadBulkProductList(file);
        _showToast(response ?? "Bulk upload completed.");
        await Future.delayed(const Duration(seconds: 2));
        try {
          await loadProducts();
        } catch (e) {
          _showToast("Upload succeeded but failed to refresh list.", isError: true);
        }
      },
    );

    //   SingleChildScrollView(
    //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Row(
    //         children: [
    //           Container(
    //             width: 40,
    //             height: 40,
    //             decoration: BoxDecoration(
    //               color: const Color(0xff185794),
    //               borderRadius: BorderRadius.circular(20),
    //               border: Border.all(color: Colors.blue.shade200, width: 3),
    //             ),
    //             child: IconButton(
    //               icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
    //               onPressed: () {
    //                 setState(() => _isAddingProduct = false);
    //               },
    //             ),
    //           ),
    //           const Spacer(),
    //           PopupMenuButton<String>(
    //             tooltip: 'More',
    //             onSelected: (value) {
    //               if (value == 'clear') {
    //                 _medicineNameAddController.clear();
    //                 _genericNameAddController.clear();
    //                 _manufacturerAddController.clear();
    //                 _indicationsAddController.clear();
    //                 _showToast("Form cleared");
    //               }
    //               if (value == 'close') {
    //                 setState(() => _isAddingProduct = false);
    //               }
    //             },
    //             itemBuilder: (context) => [
    //               const PopupMenuItem(
    //                 value: 'clear',
    //                 child: ListTile(
    //                   leading: Icon(Icons.clear),
    //                   title: Text('Clear Form'),
    //                 ),
    //               ),
    //               const PopupMenuItem(
    //                 value: 'close',
    //                 child: ListTile(
    //                   leading: Icon(Icons.close),
    //                   title: Text('Close Add Screen'),
    //                 ),
    //               ),
    //             ],
    //             icon: const Icon(Icons.more_vert),
    //           ),
    //         ],
    //       ),
    //       const SizedBox(height: 30),
    //       const Center(
    //         child: Text('Add Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    //       ),
    //       const SizedBox(height: 20),
    //       Center(
    //         child: Card(
    //           elevation: 6,
    //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    //           color: Colors.white,
    //           margin: const EdgeInsets.symmetric(horizontal: 10),
    //           child: Padding(
    //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    //             child: Column(
    //               mainAxisSize: MainAxisSize.min,
    //               children: [
    //                 _buildLabeledInput("Medicine name", _medicineNameAddController),
    //                 const SizedBox(height: 16),
    //                 _buildLabeledInput("Generic name", _genericNameAddController),
    //                 const SizedBox(height: 16),
    //                 _buildLabeledInput("Manufactured By", _manufacturerAddController),
    //                 const SizedBox(height: 16),
    //                 _buildLabeledInput("Indications", _indicationsAddController),
    //                 const SizedBox(height: 24),
    //                 ElevatedButton(
    //                   style: ElevatedButton.styleFrom(
    //                     backgroundColor: const Color(0xff262A88),
    //                     padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
    //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    //                   ),
    //                   onPressed: () async {
    //                     final medicineName = _medicineNameAddController.text.trim();
    //                     final genericName = _genericNameAddController.text.trim();
    //                     final manufacturedBy = _manufacturerAddController.text.trim();
    //                     final indication = _indicationsAddController.text.trim();
    //
    //                     if ([medicineName, genericName, manufacturedBy, indication].any((e) => e.isEmpty)) {
    //                       _showToast("All fields are required", isError: true);
    //                       return;
    //                     }
    //
    //                     final isDuplicate = products.any((p) =>
    //                     p.medicineName?.toLowerCase() == medicineName.toLowerCase() &&
    //                         p.genericName?.toLowerCase() == genericName.toLowerCase() &&
    //                         p.manufacturedBy?.toLowerCase() == manufacturedBy.toLowerCase() &&
    //                         p.indication?.toLowerCase() == indication.toLowerCase());
    //
    //                     if (isDuplicate) {
    //                       _showToast("Product already exists!", isError: true);
    //                       return;
    //                     }
    //
    //                     final requestModel = AddProductRequestModel(
    //                       medicineName: medicineName,
    //                       genericName: genericName,
    //                       manufacturedBy: manufacturedBy,
    //                       indication: indication,
    //                     );
    //
    //                     final result = await _apiService.addProduct(
    //                       medicineName: medicineName,
    //                       genericName: genericName,
    //                       manufacturedBy: manufacturedBy,
    //                       indication: indication,
    //                       requestModel: requestModel,
    //                     );
    //
    //                     if (result != null && result['success'] == true) {
    //                       _showToast("Product added successfully!", isError: false);
    //                       _medicineNameAddController.clear();
    //                       _genericNameAddController.clear();
    //                       _manufacturerAddController.clear();
    //                       _indicationsAddController.clear();
    //                       setState(() => _isAddingProduct = false);
    //                       await loadProducts();
    //                     } else {
    //                       _showToast(result?['message'] ?? 'Failed to add product', isError: true);
    //                     }
    //                   },
    //                   child: const Text("Add", style: TextStyle(color: Colors.white)),
    //                 ),
    //                 const SizedBox(height: 16),
    //                 const Text("Or"),
    //                 const SizedBox(height: 12),
    //                 ElevatedButton(
    //                   onPressed: () {
    //                     showDialog(
    //                       context: context,
    //                       builder: (_) =>
    //                           BulkUploadWidget(
    //                         onFileSelected: (file) async {
    //                           _showToast("Uploading Excel file...", isError: false);
    //                           final response = await _apiService.uploadBulkProductList(file);
    //                           _showToast(response ?? "Bulk upload completed.");
    //                           await Future.delayed(const Duration(seconds: 2));
    //                           try {
    //                             await loadProducts();
    //                           } catch (e) {
    //                             _showToast("Upload succeeded but failed to refresh list.", isError: true);
    //                           }
    //                         },
    //                       ),
    //                     );
    //                   },
    //                   style: ElevatedButton.styleFrom(
    //                     backgroundColor: Colors.green.shade700,
    //                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    //                   ),
    //                   child: const Text("Upload Bulk Products", style: TextStyle(color: Colors.white)),
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }*/

  Widget _buildAddProductScreen() {
    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              "assets/animations/internet.json",
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Internet Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Center(
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add Products', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Do you want to proceed with bulk upload?'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isAddingProduct = false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff262A88)),
            onPressed: () {
              Navigator.of(context).pop(); // Close AlertDialog
              showDialog(
                context: context,
                builder: (_) => BulkUploadWidget(
                  onFileSelected: (file) async {
                    _showToast("Uploading Excel file...", isError: false);
                    final response = await _apiService.uploadBulkProductList(file);
                    _showToast(response ?? "Bulk upload completed.");
                    await Future.delayed(const Duration(seconds: 2));
                    try {
                      await loadProducts();
                    } catch (e) {
                      _showToast("Upload succeeded but failed to refresh list.", isError: true);
                    }
                    setState(() => _isAddingProduct = false);
                  },
                ),
              );
            },
            child: const Text('Proceed', style: TextStyle(color: Colors.white)),
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
                    onTap: () async {
                      Navigator.of(dialogContext).pop(); // Close the confirmation dialog

                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['xlsx'],
                      );

                      if (result != null && result.files.single.path != null) {
                        final file = File(result.files.single.path!);

                        // Show loader dialog with Lottie
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext loaderContext) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Lottie.asset('assets/animations/uploading.json', width: 150, height: 150),
                                  const SizedBox(height: 16),
                                  const Text("Uploading...", style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          },
                        );

                        try {
                          final response = await _apiService.uploadBulkProductList(file);

                          if (!mounted) return;
                          Navigator.of(context, rootNavigator: true).pop(); // Close loader dialog

                          if (response != null) {
                            _showToast(response, isError: false);
                            await Future.delayed(const Duration(seconds: 2));
                            await loadProducts();
                          } else {
                            _showToast("No response from server.", isError: true);
                          }
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.of(context, rootNavigator: true).pop(); // Close loader dialog
                          _showToast("Upload failed: ${e.toString()}", isError: true);
                        }
                      }
                    },
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
  Widget buildTableRow(int index, Products product) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text('${(_currentProductPage * 10) + index + 1}.'),
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
              color: Color(0xff185794),
              elevation: 10,
              iconColor: Colors.white,
              tooltip: 'Actions',
              onSelected: (value) {
                if (value == 'view') {
                  // _viewProductDialog(product);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(product: product),
                    ),
                  );
                } else if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditFullProductScreen(
                        product: UpdateProductListingRequestModel.fromJson(product.toJson()),
                      ),
                    ),
                  ).then((shouldRefresh) {
                    if (shouldRefresh == true) loadProducts();
                  });
                }
                else if (value == 'delete') {
                  _showDeleteConfirmationDialog(product);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: ListTile(
                    leading: Icon(Icons.visibility),
                    title: Text('View'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              icon: Icon(Icons.more_vert, color: Color(0xff185794),),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Products product) {
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
              Text(
                'Manufacturer: ${product.manufacturedBy ?? "N/A"}',
                style: const TextStyle(fontSize: 14),
              ),
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
  Future<void> _deleteProduct(Products product) async {
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
        await loadProducts(); // Refresh the product list
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

  void _viewProductDialog(Products product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Product Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Medicine: ${product.medicineName ?? '-'}"),
            Text("Generic: ${product.genericName ?? '-'}"),
            Text("Manufactured By: ${product.manufacturedBy ?? '-'}"),
            Text("Indication: ${product.indication ?? '-'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _editProduct(Products product) {
    setState(() {
      _selectedProductForEdit = {
        'serialNo': product.serialNo?.toString() ?? '',
        'medicineName': product.medicineName ?? '',
        'genericName': product.genericName ?? '',
        'manufacturedBy': product.manufacturedBy ?? '',
        'indication': product.indication ?? '',
      };
      _isEditingProduct = true;
      _medicineNameEditController.text = product.medicineName ?? '';
      _genericNameEditController.text = product.genericName ?? '';
      _manufacturerEditController.text = product.manufacturedBy ?? '';
      _indicationsEditController.text = product.indication ?? '';
    });
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
                  loadProducts();
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
                    loadProducts();
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
                  loadProducts();
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
                color: Colors.grey
            ),
          ),
          /*const SizedBox(height: 8),
          IconButton(
            onPressed: () async {
              final connected = await _updateInternetStatus();
              if (connected) await loadProducts();
            },
            icon: Icon(Icons.refresh,color: Color(0xff185794), size: 40,),
          ),*/
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
}