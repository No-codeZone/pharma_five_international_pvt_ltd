import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../helper/communication_handler.dart';
import '../../model/view_enquiry_response_model.dart';
import '../../service/api_service.dart';

enum EnquiryStatus {
  unread, // When read = 0 or null
  read // When read = 1
}

// 2. Update the EnquiryItem class to include more fields for debugging
class EnquiryItem {
  final int id;
  final String productName;
  final String userName;

  // final EnquiryStatus status;
  final int? readValue; // Add this for debugging

  EnquiryItem({
    required this.id,
    required this.productName,
    required this.userName,
    // required this.status,
    this.readValue,
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
  bool _isMarkingRead = false;
  bool _lastConnectionStatus = true;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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
    if (old.currentPage != widget.currentPage) {
      _loadPage(widget.currentPage);
    }
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      _isLoading = true;
      _items = [];
    });

    try {
      final resp = await ApiService().fetchAllEnquiries(
        index: page,
        limit: widget.pageSize,
      );

      final fetched = resp.data?.map((d) {
            // Simplified status logic
            final readValue = d.read ?? 0;
            final itemStatus =
                readValue == 0 ? EnquiryStatus.unread : EnquiryStatus.read;

            print(
                'Loading enquiry - ID: ${d.id}, read: $readValue, status: $itemStatus');

            return EnquiryItem(
              id: d.id ?? 0,
              productName: d.medicineName ?? '—',
              userName: d.empName ?? '—',
              // status: itemStatus,
              readValue: readValue,
            );
          }).toList() ??
          [];

      final totalCount = resp.totalCount ?? fetched.length;
      setState(() {
        _items = fetched;
        _totalPages = (totalCount + widget.pageSize - 1) ~/ widget.pageSize;
      });

      print('Current items after loading:');
      for (var item in _items) {
        print('ID: ${item.id}, ReadValue: ${item.readValue}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading enquiries: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildEnquiryDetailsDialog(
      ViewEnquiryData d, String userName, String productName) {
    return Stack(
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
              _buildInteractiveItem(
                  label: "Medicine Name",
                  value: productName,
                  icon: Icons.medication,
                  isInteractive: false),
              _buildInteractiveItem(
                  label: "User Name",
                  value: userName,
                  icon: Icons.person,
                  isInteractive: false),
              _buildInteractiveItem(
                  label: "Generic Name",
                  value: d.genericName,
                  icon: Icons.medication_outlined,
                  isInteractive: false),
              _buildInteractiveItem(
                  label: "Mobile",
                  value: d.mobileNumber,
                  icon: Icons.phone,
                  onTap: () => _handlePhoneNumberTap(d.mobileNumber)),
              _buildInteractiveItem(
                  label: "Email",
                  value: d.email,
                  icon: Icons.email,
                  onTap: () => _handleEmailTap(d.email)),
              _buildInteractiveItem(
                  label: "Organisation",
                  value: d.organisationName,
                  icon: Icons.business,
                  isInteractive: false),
              _buildInteractiveItem(
                  label: "Enquired",
                  value: formatDateTime(d.createdDatetime),
                  icon: Icons.calendar_today,
                  isInteractive: false),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                label:
                    const Text("Close", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: const Color(0xff185794),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
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
    );
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

  Future<void> _handleSuccessfulDownload(List<int> fileBytes, String filename) async {
    if (Platform.isAndroid) {
      await _handleAndroidDownload(fileBytes, filename);
    } else if (Platform.isIOS) {
      await _handleIOSDownload(fileBytes, filename);
    } else {
      await _handleOtherPlatformDownload(fileBytes, filename);
    }
  }

  Future<void> _handleAndroidDownload(List<int> fileBytes, String filename) async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      // Android 13+ - Use modern approach (no permissions needed)
      await _handleModernAndroidDownload(fileBytes, filename);
    } else {
      // Android 12 and below - Check permissions first
      final hasPermission = await Permission.storage.status;
      if (hasPermission.isGranted) {
        await _handleLegacyAndroidDownload(fileBytes, filename);
      } else {
        // No permission - use share as fallback
        await _shareFileAsFallback(fileBytes, filename);
      }
    }
  }

  Future<void> _handleModernAndroidDownload(List<int> fileBytes, String filename) async {
    try {
      // Option 1: Let user choose where to save using Storage Access Framework
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        // Save to user-selected directory
        final filePath = "$selectedDirectory/$filename";
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        _showToast("Excel file saved successfully to chosen location");
      } else {
        // User cancelled directory selection - use share as alternative
        await _shareFileAsFallback(fileBytes, filename);
      }
    } catch (e) {
      debugPrint("Modern Android download error: $e");
      // Fallback to share if SAF fails
      await _shareFileAsFallback(fileBytes, filename);
    }
  }

  Future<void> _handleLegacyAndroidDownload(List<int> fileBytes, String filename) async {
    try {
      // Try to save to Downloads or app directory
      final directory = await _getAppropriateDirectory();
      if (directory != null) {
        final filePath = "${directory.path}/$filename";
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        _showToast("Excel file saved to: ${directory.path}");
      } else {
        await _shareFileAsFallback(fileBytes, filename);
      }
    } catch (e) {
      debugPrint("Legacy Android download error: $e");
      await _shareFileAsFallback(fileBytes, filename);
    }
  }

  Future<void> _shareFileAsFallback(List<int> fileBytes, String filename) async {
    try {
      // Save to app directory first
      final directory = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/$filename";
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // Share the file so user can save it anywhere
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Excel file ready - Choose where to save',
      );

      _showToast("Excel file ready to save. Choose your preferred location.");
    } catch (e) {
      debugPrint("Share fallback error: $e");
      _showToast("Failed to prepare file for sharing", isError: true);
    }
  }

  Future<void> _handleIOSDownload(List<int> fileBytes, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/$filename";
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // iOS - Share the file so user can save to Files app or other locations
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Excel file downloaded. Choose where to save.',
      );

      _showToast("Excel file ready to save");
    } catch (e) {
      debugPrint("iOS download error: $e");
      _showToast("Failed to prepare Excel file", isError: true);
    }
  }

  Future<void> _handleOtherPlatformDownload(List<int> fileBytes, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/$filename";
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      _showToast("Excel file saved to: ${directory.path}");
    } catch (e) {
      debugPrint("Other platform download error: $e");
      _showToast("Failed to save Excel file", isError: true);
    }
  }

  void _handleDownloadError(int statusCode) {
    switch (statusCode) {
      case 401:
        _showToast("Authentication required. Please log in again.", isError: true);
        break;
      case 403:
        _showToast("Access forbidden. Check your permissions.", isError: true);
        break;
      case 404:
        _showToast("Excel file not found on server.", isError: true);
        break;
      case 408:
        _showToast("Request timeout. Please try again.", isError: true);
        break;
      case 500:
        _showToast("Server error. Please try again later.", isError: true);
        break;
      case 502:
        _showToast("Bad gateway. Server may be down.", isError: true);
        break;
      case 503:
        _showToast("Service unavailable. Please try again later.", isError: true);
        break;
      default:
        _showToast("Download failed with error code: $statusCode", isError: true);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    // Call your setState here if this is in a StatefulWidget
    // setState(() => _isLoading = loading);
  }

  void _showPermissionSettingsDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
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

  Future<void> _markEnquiryAsRead(int id) async {
    if (_isMarkingRead) return;
    _isMarkingRead = true;
    final url =
        Uri.parse("http://13.233.209.211:8080/api/enquiry/$id/update-status");
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"read": 1}),
      );
      if (response.statusCode == 200) {
        setState(() {
          final index = _items.indexWhere((e) => e.id == id);
          if (index != -1) {
            _items[index] = EnquiryItem(
              id: _items[index].id,
              productName: _items[index].productName,
              userName: _items[index].userName,
              // status: EnquiryStatus.read,
            );
          }
        });
      }
    } catch (e) {
      _showToast("Error marking enquiry as read: $e", isError: true);
    } finally {
      _isMarkingRead = false;
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
                      // await _markEnquiryAsDeleted(id);
                      await _markEnquiryAsDeleted(id);
                      await Future.delayed(const Duration(milliseconds: 300));
                      await _loadPage(widget.currentPage);
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

  /*Future<void> _downloadEnquiryExcelFile() async {
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
      final filename =
          "enquiry_list_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final downloadPath = "${directory.path}/$filename";

      final response = await http.get(url).timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException("The connection timed out."),
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
  }*/

  Future<void> _downloadEnquiryExcelFile() async {
    if (_isLoading) return;

    try {
      setState(() => _isLoading = true);

      // Check if permissions are needed (Android 12 and below)
      bool needsPermission = false;
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        needsPermission = androidInfo.version.sdkInt < 33;
      }

      // Request permissions only if needed
      if (needsPermission) {
        final hasPermission = await _requestFileOperationPermissions();
        if (!hasPermission) {
          debugPrint("Permissions denied, will use share functionality");
          // Continue to download & use share as fallback
        }
      }

      _showToast("Preparing Excel file...");

      final filename = "enquiry_list_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      String? downloadPath;

      if (Platform.isAndroid) {
        final selectedDir = await FilePicker.platform.getDirectoryPath();
        if (selectedDir == null) {
          _showToast("Download cancelled by user.");
          return;
        }
        downloadPath = "$selectedDir/$filename";
      } else {
        final directory = await getApplicationDocumentsDirectory();
        downloadPath = "${directory.path}/$filename";
      }

      final url = Uri.parse("http://13.233.209.211:8080/api/enquiry/download");

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

          await Share.shareXFiles(
            [XFile(downloadPath)],
            text: 'Enquiry Excel downloaded. Choose where to save or share.',
          );
        } else if (Platform.isAndroid) {
          _showToast("Excel downloaded to: $downloadPath");
          // await _showAndroidDownloadNotification(downloadPath);
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

  Future<void> _showAndroidDownloadNotification(String filePath) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Notifications for file downloads',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notifDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Download Complete',
      'Enquiry Excel downloaded to: $filePath',
      notifDetails,
      payload: filePath,
    );
  }

  Future<bool> _requestFileOperationPermissions() async {
    if (!_isConnected) {
      _showToast("No internet connection", isError: true);
      return false;
    }

    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      return await _requestIOSPermissions();
    } else {
      _showToast("File operations may not be fully supported on this platform", isError: true);
      return true;
    }
  }

  Future<bool> _requestAndroidPermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // Android 13+ (API 33+) - NO PERMISSIONS NEEDED
    if (sdkInt >= 33) {
      // Modern Android uses:
      // 1. Storage Access Framework (SAF) via FilePicker - no permissions needed
      // 2. App-specific directories - no permissions needed
      // 3. Share intent - no permissions needed
      return true;
    }
    // Android 11-12 (API 30-32) - Only READ_EXTERNAL_STORAGE needed
    else if (sdkInt >= 30) {
      final storageStatus = await Permission.storage.request();

      if (storageStatus.isGranted) {
        return true;
      }

      if (storageStatus.isPermanentlyDenied) {
        _showPermissionSettingsDialog(
            "Storage Access Required",
            "Storage access is needed to save Excel files. Please enable it in app settings."
        );
        return false;
      }

      if (storageStatus.isDenied) {
        _showToast("Storage permission denied. File will be shared instead.", isError: true);
        return false;
      }

      return storageStatus.isGranted;
    }
    // Android 10 and below (API 29 and below) - WRITE_EXTERNAL_STORAGE needed
    else {
      final status = await Permission.storage.request();

      if (status.isGranted) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        _showPermissionSettingsDialog(
            "Storage Access Required",
            "Storage access is needed to save Excel files. Please enable it in app settings."
        );
        return false;
      }

      if (status.isDenied) {
        _showToast("Storage permission denied. File will be shared instead.", isError: true);
        return false;
      }

      return status.isGranted;
    }
  }

  Future<bool> _requestIOSPermissions() async {
    // iOS doesn't need explicit permissions for document operations
    // Files are saved to app's Documents directory which is accessible via Files app
    return true;
  }

  Widget _buildInteractiveItem({
    required String label,
    required String? value,
    required IconData icon,
    bool isInteractive = true,
    VoidCallback? onTap,
  }) {
    final displayValue =
        (value == null || value.trim().isEmpty || value == "-") ? "N/A" : value;

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

  Future<void> _viewEnquiry(int id, String userName, String productName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xff185794)),
      ),
    );
    try {
      // 1️⃣ Fetch enquiry details
      final d = await ApiService().fetchEnquiryById(id);
      Navigator.pop(context); // remove loader
      if (d == null) throw Exception("No enquiry found");
      print('After fetchEnquiryById - ID: $id, read: ${d.read}');
      // 2️⃣ Call backend to mark as read
      await _markEnquiryAsRead(id);
      // 3️⃣ Update local UI immediately
      final index = _items.indexWhere((e) => e.id == id);
      if (index != -1) {
        setState(() {
          _items[index] = EnquiryItem(
            id: _items[index].id,
            productName: _items[index].productName,
            userName: _items[index].userName,
            readValue: d.read == true ? 1 : 0,
          );
        });
      }
      // 4️⃣ Show the dialog
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          backgroundColor: Colors.transparent,
          child: _buildEnquiryDetailsDialog(d, userName, productName),
        ),
      );
      // 5️⃣ Refresh the page to ensure data reflects server-side status
      print('Dialog closed, refreshing page...');
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadPage(widget.currentPage);
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("Unable to load enquiry details: $e"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK")),
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

    int startPage = max(
        0,
        min(widget.currentPage - (maxPagesToShow ~/ 2),
            _totalPages - maxPagesToShow));
    int endPage = min(startPage + maxPagesToShow - 1, _totalPages - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ← Previous
          if (widget.currentPage > 0)
            _buildArrowButton(
                false,
                () => widget.onPageChange(widget.currentPage - 1),
                buttonSize,
                fontSize),

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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: const Color(0xff185794),
                  ),
                ),
              ),
            );
          }),

          // → Next
          if (widget.currentPage < _totalPages - 1)
            _buildArrowButton(
                true,
                () => widget.onPageChange(widget.currentPage + 1),
                buttonSize,
                fontSize),
        ],
      ),
    );
  }

  Widget _buildArrowButton(
      bool isNext, VoidCallback onTap, double size, double fontSize) {
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
                        child: IconButton(
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
    final isUnread = item.readValue == 0;
    final sideColor = isUnread ? Colors.grey : const Color(0xff185794);
    final bgColor = isUnread ? Colors.white : const Color(0xffeff4f8);

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: InkWell(
        onTap: () async {
          await _viewEnquiry(item.id, item.userName, item.productName);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: isUnread
                ? Border(left: BorderSide(color: sideColor, width: 4))
                : Border(
              left: BorderSide(color: sideColor, width: 4),
              top: BorderSide(color: sideColor, width: 1),
              right: BorderSide(color: sideColor, width: 1),
              bottom: BorderSide(color: sideColor, width: 1),
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
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text(
                    item.productName,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.normal : FontWeight.bold,
                      fontSize: isUnread ? 14 : 16,
                      color: isUnread ? Colors.black : const Color(0xff185794),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    item.userName,
                    style: TextStyle(
                      fontSize: isUnread ? 13 : 15,
                      color: isUnread ? Colors.black : const Color(0xff185794),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: IconButton(
                  icon: Icon(
                    isUnread ? Icons.delete_outline : Icons.visibility_off,
                    color: isUnread
                        ? Colors.red.shade400
                        : const Color(0xff185794),
                  ),
                  onPressed: () async {
                    if (isUnread) {
                      _confirmDeleteEnquiry(item.id);
                    } else {
                      await _viewEnquiry(item.id, item.userName, item.productName);
                    }
                  },
                ),
              ),
            ],
          ),
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
