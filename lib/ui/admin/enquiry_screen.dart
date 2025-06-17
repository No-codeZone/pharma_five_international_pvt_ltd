import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../helper/communication_handler.dart';
import '../../helper/file_downloader_helper.dart';
import '../../service/api_service.dart';


enum EnquiryStatus { newEnquiry, viewed }
class EnquiryItem {
  final int id;
  final String productName;
  final String userName;
  final EnquiryStatus status;

  EnquiryItem({
    required this.id,
    required this.productName,
    required this.userName,
    required this.status,
  });
}
/// A tab that displays a single page of Enquiries
/// and lets the parent manage currentPage / onPageChange.
class EnquiryTab extends StatefulWidget {
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChange;

  const EnquiryTab({
    Key? key,
    required this.currentPage,
    required this.onPageChange,
    this.pageSize = 10,
  }) : super(key: key);

  @override
  _EnquiryTabState createState() => _EnquiryTabState();
}
class _EnquiryTabState extends State<EnquiryTab> {
  bool _isLoading = false;
  int _totalPages = 1;
  List<EnquiryItem> _items = [];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectionSubscription;
  bool _isConnected = true;
  bool _lastConnectionStatus = true;

  @override
  void initState() {
    super.initState();
    _monitorInternetConnectivity();
    // _loadPage(widget.currentPage);
  }

  void _monitorInternetConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    final initialConnected = results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);

    _isConnected = initialConnected;
    _lastConnectionStatus = initialConnected;

    if (initialConnected) {
      _loadPage(widget.currentPage);
    }

    _connectionSubscription =
        _connectivity.onConnectivityChanged.listen((results) async {
      final connected = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);

      if (_lastConnectionStatus != connected) {
        setState(() {
          _isConnected = connected;
          _lastConnectionStatus = connected;
        });

        if (connected) {
          await Future.delayed(
              const Duration(milliseconds: 500)); // allow stabilization
          _loadPage(widget.currentPage);
        } else {
          // Fluttertoast.showToast(
          //   msg: "Internet connection lost",
          //   backgroundColor: Colors.red,
          // );
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant EnquiryTab old) {
    super.didUpdateWidget(old);
    // If parent changed the page, reload:
    if (old.currentPage != widget.currentPage) {
      _loadPage(widget.currentPage);
    }
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      _isLoading = true;
      _items = []; // 👈 clears list immediately to show blank white background
    });

    try {
      final resp = await ApiService().fetchAllEnquiries(
        index: page, // or page * pageSize if backend uses offset
        limit: widget.pageSize,
        // sortOrder: 'desc', // Add sort parameter to get latest enquiries first
      );

      final fetched = resp.data
              ?.map((d) => EnquiryItem(
                    id: d.id ?? 0,
                    productName: d.medicineName ?? '—',
                    userName: d.empName ?? '—',
                    status: d.status == 1
                        ? EnquiryStatus.newEnquiry
                        : EnquiryStatus.viewed,
                  ))
              .toList() ??
          [];

      final totalCount = resp.totalCount ?? fetched.length;
      setState(() {
        _items = fetched;
        _totalPages = (totalCount + widget.pageSize - 1) ~/ widget.pageSize;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading enquiries: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() => _loadPage(widget.currentPage);
  // Handle tap on phone number - direct without using url_launcher
  void _handlePhoneNumberTap(String? phoneNumber) {
    CommunicationHandler.makePhoneCall(context, phoneNumber);
  }
  // Handle tap on email - direct without using url_launcher
  void _handleEmailTap(String? email) {
    CommunicationHandler.sendEmail(context, email);
  }

  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return "N/A";

    try {
      final parsed = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy hh:mm a').format(parsed);
    } catch (e) {
      return "Invalid Date";
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

  Future<void> _markEnquiryAsRead(int id) async {
    final url = Uri.parse("http://13.233.209.211:8080/api/enquiry/$id/update-status");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"read": 1}), // ✅ must be int, not bool
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _items.indexWhere((e) => e.id == id);
          if (index != -1) {
            _items[index] = EnquiryItem(
              id: _items[index].id,
              productName: _items[index].productName,
              userName: _items[index].userName,
              status: EnquiryStatus.viewed,
            );
          }
        });
      } else {
        _showToast("Failed to mark as read: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showToast("Error marking enquiry as read: $e", isError: true);
    }
  }

  Future<void> _markEnquiryAsDeleted(int id) async {
    try {
      final deletedData = await ApiService().deleteEnquiryById(id);

      if (deletedData != null) {
        setState(() {
          _items.removeWhere((e) => e.id == id);
        });
        _showToast("Enquiry deleted successfully");
      } else {
        _showToast("Delete failed: No data returned", isError: true);
      }
    } catch (e) {
      _showToast("Error deleting enquiry: $e", isError: true);
    }
  }

  void _confirmDeleteEnquiry(int id) {
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
            'Do you want to delete this enquiry?',
            textAlign: TextAlign.center,
          ),
          actions: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      side: const BorderSide(color: Color(0xff262A88)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text('Cancel'),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const Expanded(child: SizedBox(width: 80)),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text('Yes, Delete'),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _markEnquiryAsDeleted(id);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
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

  Future<void> _downloadEnquiryExcelFile() async {
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

      final url = Uri.parse("http://13.233.209.211:8080/api/enquiry/download");
      final filename = "enquiry_list_${DateTime.now().millisecondsSinceEpoch}.xlsx";
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

  Widget _buildInteractiveItem({
    required String label,
    required String? value,
    required IconData icon,
    bool isInteractive = true,
    VoidCallback? onTap,
  }) {
    final displayValue = (value == null || value.trim().isEmpty || value == "-") ? "N/A" : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: isInteractive ? onTap : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Color(0xff185794)),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110, // fixed label width for alignment
                    child: Text(
                      "$label:",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xff185794),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      displayValue!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isInteractive ? Colors.blue : Colors.black87,
                        decoration: isInteractive
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Styled viewEnquiry function based on logout dialog styling
  Future<void> _viewEnquiry(int id, String userName, String productName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xff185794)),
      ),
    );

    try {
      final d = await ApiService().fetchEnquiryById(id); // returns EnquiryItem?
      Navigator.pop(context); // remove loader

      if (d == null) throw Exception("No enquiry found");

      await showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          backgroundColor: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Enquiry Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff185794),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      width: 40,
                      color: const Color(0xff185794).withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),

                    _buildInteractiveItem(label: "Medicine Name", value: productName, icon: Icons.medication, isInteractive: false),
                    _buildInteractiveItem(label: "User Name", value: userName, icon: Icons.person, isInteractive: false),
                    _buildInteractiveItem(label: "Generic Name", value: d.genericName, icon: Icons.medication_outlined, isInteractive: false),
                    _buildInteractiveItem(label: "Mobile", value: d.mobileNumber, icon: Icons.phone, onTap: () => _handlePhoneNumberTap(d.mobileNumber)),
                    _buildInteractiveItem(label: "Email", value: d.email, icon: Icons.email, onTap: () => _handleEmailTap(d.email)),
                    _buildInteractiveItem(label: "Organisation", value: d.organisationName, icon: Icons.business, isInteractive: false),
                    _buildInteractiveItem(label: "Enquired", value: formatDateTime(d.createdDatetime), icon: Icons.calendar_today, isInteractive: false),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // close dialog
                      },
                      icon: const Icon(Icons.close, size: 18, color: Colors.white),
                      label: const Text("Close", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: const Color(0xff185794),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -28,
                left: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.info_outline, size: 30, color: Color(0xff185794)),
                ),
              ),
            ],
          ),
        ),
      );

      await _markEnquiryAsRead(id); // after dialog close
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("Unable to load enquiry details: $e"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      );
    }
  }

  Widget _buildPagination() {
    if (_items.length < widget.pageSize && widget.currentPage == 0) {
      return const SizedBox.shrink(); // Hide if no need to paginate
    }

    const int maxPagesToShow = 5;
    final double buttonSize = 30;
    final double fontSize = 14;

    int startPage = max(0, min(widget.currentPage - (maxPagesToShow ~/ 2), _totalPages - maxPagesToShow));
    int endPage = min(startPage + maxPagesToShow - 1, _totalPages - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ← Previous
          if (widget.currentPage > 0)
            _buildArrowButton(false, () => widget.onPageChange(widget.currentPage - 1), buttonSize, fontSize),

          // Page buttons
          ...List.generate(endPage - startPage + 1, (index) {
            final int pageNumber = startPage + index;
            final bool isSelected = pageNumber == widget.currentPage;
            return InkWell(
              onTap: isSelected ? null : () => widget.onPageChange(pageNumber),
              child: Container(
                width: buttonSize,
                height: buttonSize,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 4),
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
            );
          }),

          // → Next
          if (widget.currentPage < _totalPages - 1)
            _buildArrowButton(true, () => widget.onPageChange(widget.currentPage + 1), buttonSize, fontSize),
        ],
      ),
    );
  }

  Widget _buildArrowButton(bool isNext, VoidCallback onTap, double size, double fontSize) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Icon(
          isNext ? Icons.chevron_right : Icons.chevron_left,
          size: fontSize + 4,
          color: const Color(0xff185794),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Image.asset(
                          "assets/images/logo_pf.png",
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Enquiry",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child:
                        IconButton(
                          icon: Image.asset(
                            'assets/images/excel_icon.png',
                            height: 24,
                          ),
                          tooltip: 'Download Enquiry Excel',
                          onPressed: _downloadEnquiryExcelFile,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            buildTableHeader(),
            // List view + loader
            Expanded(
              child: Column(
                children: [
                  if (!_isConnected)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.orange.shade100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Waiting for connection...',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                    ),
                  Expanded(
                    child: !_isConnected
                        ? _buildNoInternetWidget()
                        : _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xff185794),
                                  strokeWidth: 3,
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _refresh,
                                color: const Color(0xff185794),
                      child: _items.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              "assets/animations/no_data_found.json",
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "No enquiries found.",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                                        itemCount: _items.length,
                                        itemBuilder: (context, index) =>
                                            _buildEnquiryCard(
                                                _items[index], index),
                                      ),
                              ),
                  ),
                ],
              ),
            ),
            // Pagination
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildPagination(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryCard(EnquiryItem item, int index) {
    final isNew = item.status == EnquiryStatus.newEnquiry;
    final sideColor = isNew ? const Color(0xff185794) : Colors.grey;
    final bgColor = isNew ? Color(0xffeff4f8) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.0),
        // Increased vertical margin for better separation
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        // Increased vertical padding for better touch target
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isNew
              ? Border(
                  left: BorderSide(color: sideColor, width: 4),
                  top: BorderSide(color: sideColor, width: 1),
                  right: BorderSide(color: sideColor, width: 1),
                  bottom: BorderSide(color: sideColor, width: 1),
                )
              : Border(
                  left: BorderSide(color: sideColor, width: 4),
                ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Center(child: Text('${index + 1}')),
            ),
            Expanded(
              flex: 4,
              child: isNew
                  ? Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                        item.productName,
                        style: TextStyle(
                            fontWeight:
                                isNew ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                            color: Color(0xff185794)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  )
                  : Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                        item.productName,
                        style: TextStyle(
                          fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ),
            ),
            isNew
                ? Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        item.userName,
                        style: const TextStyle(
                            fontSize: 15, color: Color(0xff185794)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                : Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        item.userName,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
            Expanded(
              flex: 2,
              child: IconButton(
                icon: Icon(
                  isNew ? Icons.visibility_off : Icons.delete_outline,
                  color: isNew ? const Color(0xff185794) : Colors.red.shade400,
                  size: 24,
                ),
                padding: const EdgeInsets.all(8.0),
                onPressed: () async {
                  if (isNew) {
                    await _viewEnquiry(item.id, item.userName, item.productName);
                  } else {
                    _confirmDeleteEnquiry(item.id);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, bottom: 5.0, right: 20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xff185794),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: const [
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'No.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: Text(
                    'Product name',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    'User name',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoInternetWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset("assets/animations/internet.json",
              width: 200, height: 200),
          const SizedBox(height: 16),
          const Text(
            'No Internet Connection',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }
}