import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../helper/file_downloader_helper.dart';
import '../../helper/shared_preferences.dart';
import '../../model/login_session_model.dart';
import '../../model/producr_search_logs_model.dart';
import '../../model/product_search_logs_model.dart';
import '../../service/api_service.dart';
import '../login_screen.dart';

class ReportTab extends StatefulWidget {
  final VoidCallback? onLogout;

  const ReportTab({Key? key, this.onLogout}) : super(key: key);

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> with SingleTickerProviderStateMixin {
  Future<LoginSessionModel>? _futureSessions;
  final ApiService _apiService = ApiService();
  int _touchedIndex = -1;
  // List<ProductSearchLogs> _searchLogs = [];
  List<ProductSearchLogsModel> _searchLogs = [];
  String? _filteredDayLabel;
  List<Sessions> _filteredSessions = [];
  late TabController _tabController;
  bool _isLoading = true;
  bool _isConnected = true;
  // Scroll controllers for horizontal scrolling
  final ScrollController _sessionsScrollController = ScrollController();
  final ScrollController _searchesScrollController = ScrollController();
  // Theme colors
  final Color _primaryColor = const Color(0xff185794);
  final Color _accentColor = const Color(0xff4a90e2);
  final Color _backgroundColor = const Color(0xfff5f7fa);
  final Color _cardColor = Colors.white;
  final Color _textPrimaryColor = const Color(0xff2d3748);
  final Color _textSecondaryColor = const Color(0xff718096);
  int _selectedDayFilter = 7;
  final Map<String, int> _dayFilters = {
    "Last 7 days": 7,
    "Last 30 days": 30,
    "Last 60 days": 60,
    "Last 90 days": 90,
    "All": 9999,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _checkLoginStatus();
    // Add listener to load search logs when tab changes
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // Load search logs when search tab is selected
        _loadSearchLogs();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sessionsScrollController.dispose();
    _searchesScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Now only load sessions initially
      final sessionsFuture = _apiService.fetchAllLoginSessions();

      setState(() {
        _futureSessions = sessionsFuture;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _futureSessions = Future.error(e);
      });
      print("Error loading data: $e");
    }
  }

  Future<void> _loadSearchLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logsModels = await _apiService.fetchSearchLogsByDay(days: _selectedDayFilter);

      // Properly use count and search
      final logs = logsModels.map((model) {
        return ProductSearchLogsModel(
          count: model.count,     // ✅ FIXED: use actual count
          search: model.search,
        );
      }).toList();

      setState(() {
        _searchLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading search logs: $e");
      setState(() {
        _searchLogs = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to load search logs. Please try again.'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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

  // Future<void> _downloadProductSearchLogExcel() async {
  //   try {
  //     // ✅ Step 1: Reliable Internet Check
  //     bool hasInternet = false;
  //     try {
  //       final result = await InternetAddress.lookup('google.com');
  //       if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
  //         hasInternet = true;
  //       }
  //     } on SocketException catch (_) {
  //       hasInternet = false;
  //     }
  //
  //     if (!hasInternet) {
  //       Fluttertoast.showToast(
  //         msg: "No internet connection",
  //         backgroundColor: Colors.red,
  //         textColor: Colors.white,
  //         gravity: ToastGravity.TOP,
  //         toastLength: Toast.LENGTH_LONG,
  //       );
  //       return;
  //     }
  //
  //     // ✅ Step 2: Request Permission
  //     final hasPermission = await FileDownloadHelper.requestStoragePermission(context);
  //     if (!hasPermission) return;
  //
  //     // ✅ Step 3: Get Directory
  //     final directory = await FileDownloadHelper.getDownloadDirectory();
  //     if (directory == null) {
  //       Fluttertoast.showToast(
  //         msg: "Unable to access storage",
  //         backgroundColor: Colors.red,
  //         textColor: Colors.white,
  //         gravity: ToastGravity.TOP,
  //         toastLength: Toast.LENGTH_LONG,
  //       );
  //       return;
  //     }
  //
  //     // ✅ Step 4: Make API Call
  //     final url = Uri.parse("http://13.49.224.44:8080/api/product/search-logs?days=$_selectedDayFilter&download=true");
  //     final filename = "product_search_logs_${DateTime.now().millisecondsSinceEpoch}.xlsx";
  //     final filePath = "${directory.path}/$filename";
  //
  //     final response = await http.get(url);
  //
  //     if (response.statusCode == 200) {
  //       final file = File(filePath);
  //       await file.writeAsBytes(response.bodyBytes);
  //       await FileDownloadHelper.showFileDownloadSnackBar(context, filePath, Platform.isIOS);
  //     } else {
  //       Fluttertoast.showToast(
  //         msg: "Download failed: Status ${response.statusCode}",
  //         backgroundColor: Colors.red,
  //         textColor: Colors.white,
  //         gravity: ToastGravity.TOP,
  //         toastLength: Toast.LENGTH_LONG,
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint("Download error: $e");
  //     Fluttertoast.showToast(
  //       msg: "Error: $e",
  //       backgroundColor: Colors.red,
  //       textColor: Colors.white,
  //       gravity: ToastGravity.TOP,
  //       toastLength: Toast.LENGTH_LONG,
  //     );
  //   }
  // }
  Future<void> _downloadProductSearchLogExcel() async {
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

      final url = Uri.parse("http://13.49.224.44:8080/api/product/search-logs?days=$_selectedDayFilter&download=true");
      final filename = "product_search_logs_${DateTime.now().millisecondsSinceEpoch}.xlsx";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        "Loading report data...",
                        style: TextStyle(
                            color: _textSecondaryColor,
                            fontWeight: FontWeight.w500
                        ),
                      )
                    ],
                  ),
                ),
              )
            else
              Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
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

            // Expanded widget to center the "Analytics" text
            Expanded(
              child: Center(
                child: const Text(
                  "Analytics",
                  style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: _primaryColor),
              tooltip: 'Logout',
              onPressed: _showLogoutDialog,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return FutureBuilder<LoginSessionModel>(
      future: _futureSessions,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Unable to load report data",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Error: ${snapshot.error}",
                    style: TextStyle(color: _textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() {
                        _futureSessions = _apiService.fetchAllLoginSessions();
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data?.sessions == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /*Icon(Icons.info_outline, size: 48, color: _accentColor),
                const SizedBox(height: 16),
                Text(
                  "No session data available",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimaryColor,
                  ),
                ),*/
                SizedBox()
              ],
            ),
          );
        }

        final sessions = snapshot.data!.sessions!;
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 48, color: _accentColor),
                const SizedBox(height: 16),
                Text(
                  "No sessions found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        final allSessions = snapshot.data!.sessions ?? [];
        final totalSessions = snapshot.data!.totalCount ?? allSessions.length;
        final displayedSessions = _filteredDayLabel != null ? _filteredSessions : allSessions;
        final activeSessions = displayedSessions.where((s) => s.active == true).length;
        final inactiveSessions = displayedSessions.length - activeSessions;
        final avgDuration = _calculateAvgDuration(displayedSessions);

        return Column(
          children: [
            _buildFilterBar(allSessions),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    _buildMetricsGrid(displayedSessions, activeSessions, inactiveSessions, avgDuration, totalSessions),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: _primaryColor,
                        unselectedLabelColor: _textSecondaryColor,
                        indicatorColor: _primaryColor,
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: const [
                          Tab(text: "Sessions by Day"),
                          Tab(text: "Product Searches"),
                        ],
                      ),
                    ),
                    // Charts section
                    SizedBox(
                      height: 400, // Or adjust based on need
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSessionsTab(sessions),
                          _buildSearchesTab(_searchLogs),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(List<Sessions> allSessions) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_filteredDayLabel != null) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list, size: 16, color: _primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Filtered: $_filteredDayLabel",
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _filteredDayLabel = null;
                          _filteredSessions = [];
                        });
                      },
                      child: Icon(Icons.clear, size: 16, color: _primaryColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else
            Expanded(
              child: Text(
                "All Sessions",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _textPrimaryColor,
                ),
              ),
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text("Filter by Date"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2024, 1),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: _primaryColor,
                        onPrimary: Colors.white,
                        surface: _cardColor,
                        onSurface: _textPrimaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (selectedDate != null) {
                final filteredLabel = "May ${selectedDate.day}";
                setState(() {
                  _filteredDayLabel = filteredLabel;
                  _filteredSessions = allSessions.where((s) {
                    final loginDate = DateTime.parse(s.loginTime!).toLocal();
                    return loginDate.year == selectedDate.year &&
                        loginDate.month == selectedDate.month &&
                        loginDate.day == selectedDate.day;
                  }).toList();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(List<Sessions> displayedSessions, int activeSessions,
      int inactiveSessions, String avgDuration, int totalSessions) {
    final List<Widget> metricCards = [
      _buildMetricCardGrid(
        icon: Icons.people_alt_outlined,
        title: _filteredDayLabel != null ? "Sessions" : "Total Sessions",
        value: _filteredDayLabel != null
            ? "${displayedSessions.length} of $totalSessions"
            : "$totalSessions",
        color: _primaryColor,
      ),
      _buildMetricCardGrid(
        icon: Icons.check_circle_outline,
        title: "Active",
        value: "$activeSessions",
        color: Colors.green,
      ),
      _buildMetricCardGrid(
        icon: Icons.cancel_outlined,
        title: "Inactive",
        value: "$inactiveSessions",
        color: Colors.red.shade400,
      ),
      _buildMetricCardGrid(
        icon: Icons.timer_outlined,
        title: "Avg Duration",
        value: avgDuration,
        color: _accentColor,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: metricCards.map((card) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width / 2) - 24,
            child: card,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricCardGrid({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white, // Light background for visibility
      // color: const Color(0xffF7F1FB), // Light background for visibility
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsTab(List<Sessions> sessions) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive chart container
                    return _buildSessionsBarChart(sessions, constraints);
                  }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchesTab(List<ProductSearchLogsModel> logs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Excel icon
                  IconButton(
                    icon: Image.asset(
                      'assets/images/excel_icon.png',
                      height: 24,
                    ),
                    tooltip: 'Download Excel',
                    onPressed: _downloadProductSearchLogExcel,
                  ),
                  const SizedBox(width: 8),
                  // Day Filter Dropdown
                  PopupMenuButton<int>(
                    tooltip: 'Filter by Day',
                    onSelected: (value) {
                      setState(() {
                        _selectedDayFilter = value;
                        _isLoading = true;
                      });
                      _loadSearchLogs();
                    },
                    itemBuilder: (context) => _dayFilters.entries.map((entry) {
                      return PopupMenuItem<int>(
                        value: entry.value,
                        child: ListTile(
                          leading: Icon(Icons.calendar_today, color: _primaryColor, size: 20),
                          title: Text(
                            entry.key,
                            style: TextStyle(fontSize: 14, color: _textPrimaryColor),
                          ),
                        ),
                      );
                    }).toList(),
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: _primaryColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, color: _primaryColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _dayFilters.entries
                                .firstWhere((e) => e.value == _selectedDayFilter)
                                .key,
                            style: TextStyle(
                              fontSize: 13,
                              color: _primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                ),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildSearchLogChartFromData(logs);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsBarChart(List<Sessions> sessions, BoxConstraints constraints) {
    final Map<String, int> sessionCountByDate = {};

    for (var session in sessions) {
      if (session.loginTime != null) {
        final date = DateTime.parse(session.loginTime!).toLocal();
        final label = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        sessionCountByDate[label] = (sessionCountByDate[label] ?? 0) + 1;
      }
    }

    final sortedEntries = sessionCountByDate.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Descending

    if (sortedEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No session data to display",
              style: TextStyle(color: _textSecondaryColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final maxSessions = sortedEntries.first.value.toDouble();
    const double barHeight = 28.0;
    const double labelWidth = 80;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: sortedEntries.length,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final dateLabel = entry.key;
              final sessionCount = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Date label
                    SizedBox(
                      width: labelWidth,
                      child: Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Middle: Bar with Tooltip
                    Expanded(
                      child: Tooltip(
                        message: "$sessionCount sessions on $dateLabel",
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: sessionCount / maxSessions,
                              child: Container(
                                height: barHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryColor, _accentColor],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  '$sessionCount',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
// SEARCH CHART FIXES
  Widget _buildSearchLogChartFromData(List<ProductSearchLogsModel> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No product search data available",
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    logs.sort((a, b) => (b.count ?? 0).compareTo(a.count ?? 0));
    final List<int> counts = logs.map((log) => log.count ?? 0).toList();
    final double maxCount = counts.reduce((a, b) => a > b ? a : b).toDouble();

    const double barHeight = 28.0;
    const double countLabelWidth = 50.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 12.0, top: 10, bottom: 8),
          child: Text(
            "TOP PRODUCT SEARCHES",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: logs.length,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              final count = log.count ?? 0;
              final displayText = log.search ?? 'Unknown';
              final truncatedText = displayText.length > 30
                  ? '${displayText.substring(0, 30)}...'
                  : displayText;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Left: Count label
                    SizedBox(
                      width: countLabelWidth,
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Right: Bar with tooltip
                    Expanded(
                      child:
                      Tooltip(
                        message: "$count search${count != 1 ? 'es' : ''} for \"$displayText\"",
                        preferBelow: false, // Tooltip appears above the bar
                        verticalOffset: 20, // Distance between bar and tooltip
                        waitDuration: const Duration(milliseconds: 300), // Delay before showing
                        showDuration: const Duration(seconds: 3), // Visible duration
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: count / maxCount,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_accentColor, const Color(0xff7AB0FF)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                truncatedText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
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

  String _calculateAvgDuration(List<Sessions> sessions) {
    final durations = sessions
        .where((s) => s.loginTime != null && s.logoutTime != null)
        .map((s) {
      try {
        final start = DateTime.parse(s.loginTime!);
        final end = DateTime.parse(s.logoutTime!);
        return end.difference(start).inSeconds;
      } catch (e) {
        return 0;
      }
    }).toList();

    if (durations.isEmpty) return "00:00:00";
    final avg = durations.reduce((a, b) => a + b) ~/ durations.length;
    return Duration(seconds: avg).toString().split('.').first;
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
                    /*onPressed: () async {
                      try {
                        await SharedPreferenceHelper.clearSession();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      } catch (e) {
                        print('Logout failed: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Logout failed. Please try again.')),
                        );
                      }
                    },*/
                    onPressed: _logout,
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

  Future<void> _logout() async {
    try {
      final email = await SharedPreferenceHelper.getUserEmail();
      if (email != null && email.isNotEmpty) {
        await _apiService.logoutUser(userEmail: email);
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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Logout failed. Please try again.'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      bool isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
      String? userType = await SharedPreferenceHelper.getUserType();

      if (!isLoggedIn || userType != 'admin') {
        await SharedPreferenceHelper.clearSession(); // Auto clear broken state
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      print('Error checking login status: $e');
      // Fallback to login screen in case of any error
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }
}