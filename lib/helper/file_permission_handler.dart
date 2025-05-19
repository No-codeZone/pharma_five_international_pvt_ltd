import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class FilePermissionHandler {
  // Singleton instance
  static final FilePermissionHandler _instance = FilePermissionHandler._internal();
  factory FilePermissionHandler() => _instance;
  FilePermissionHandler._internal();

  // Device info plugin to check Android SDK version
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// Shows a toast message to the user
  void showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xff185794),
      textColor: Colors.white,
      fontSize: 16.0,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 3,
    );
  }

  /// Shows a permission rationale dialog to the user
  Future<bool> showPermissionRationaleDialog(
      BuildContext context,
      String title,
      String message
      ) async {
    return (await showDialog<bool>(
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
                        onPressed: () => Navigator.of(context).pop(false),
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
                        onPressed: () => Navigator.of(context).pop(true),
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
    )) ?? false;
  }

  /// Shows a dialog when permissions are permanently denied
  void showPermissionPermanentlyDeniedDialog(BuildContext context) {
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
                Text(
                  Platform.isIOS
                      ? 'File access permission is required to download and save files. Please enable it in Settings.'
                      : 'Storage permission is required to download files but has been permanently denied.\n\nPlease enable it manually in app settings.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
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

  /// Gets required download permissions based on platform and Android SDK version
  Future<Map<Permission, PermissionStatus>> _getDownloadPermissions() async {
    final permissions = <Permission, PermissionStatus>{};

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // Android 13+ (SDK 33+)
      if (sdkInt >= 33) {
        final photos = await Permission.photos.request();
        final media = await Permission.mediaLibrary.request();
        permissions[Permission.photos] = photos;
        permissions[Permission.mediaLibrary] = media;
      }
      // Android 11-12 (SDK 30-32)
      else if (sdkInt >= 30) {
        final storage = await Permission.storage.request();
        permissions[Permission.storage] = storage;

        // For these Android versions, we try to get manage external storage
        // but it's not a deal-breaker if it fails
        final manageExternal = await Permission.manageExternalStorage.request();
        permissions[Permission.manageExternalStorage] = manageExternal;
      }
      // Android 10 and below (SDK < 30)
      else {
        final storage = await Permission.storage.request();
        permissions[Permission.storage] = storage;
      }
    }
    // iOS handling
    else if (Platform.isIOS) {
      final photos = await Permission.photos.request();
      permissions[Permission.photos] = photos;
    }

    return permissions;
  }

  /// Gets required upload permissions based on platform and Android SDK version
  Future<Map<Permission, PermissionStatus>> _getUploadPermissions() async {
    final permissions = <Permission, PermissionStatus>{};

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // Android 13+ (SDK 33+)
      if (sdkInt >= 33) {
        final photos = await Permission.photos.request();
        final media = await Permission.mediaLibrary.request();
        permissions[Permission.photos] = photos;
        permissions[Permission.mediaLibrary] = media;
      }
      // Android 11-12 (SDK 30-32)
      else if (sdkInt >= 30) {
        final storage = await Permission.storage.request();
        permissions[Permission.storage] = storage;
      }
      // Android 10 and below (SDK < 30)
      else {
        final storage = await Permission.storage.request();
        permissions[Permission.storage] = storage;
      }
    }
    // iOS handling - file picker doesn't need explicit permissions on iOS
    else if (Platform.isIOS) {
      // No explicit permissions needed for file picking on iOS
      permissions[Permission.photos] = PermissionStatus.granted;
    }

    return permissions;
  }

  /// Checks if permissions are granted based on a map of permission statuses
  bool _arePermissionsGranted(Map<Permission, PermissionStatus> statuses) {
    for (final status in statuses.values) {
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  /// Checks if any permission is permanently denied
  bool _isAnyPermissionPermanentlyDenied(Map<Permission, PermissionStatus> statuses) {
    for (final status in statuses.values) {
      if (status == PermissionStatus.permanentlyDenied) {
        return true;
      }
    }
    return false;
  }

  /// Handles permission flow for downloading files
  Future<bool> requestDownloadPermissions(BuildContext context) async {
    // Show rationale dialog first
    final shouldContinue = await showPermissionRationaleDialog(
      context,
      "Storage Permission Required",
      Platform.isIOS
          ? "We need permission to save files to your device. Please grant access to Photos."
          : "We need permission to save files to your device. Please grant access to continue.",
    );

    if (!shouldContinue) return false;

    // Request permissions
    final permissions = await _getDownloadPermissions();

    // Check if permissions are granted
    if (_arePermissionsGranted(permissions)) {
      return true;
    }

    // Check if any permission is permanently denied
    if (_isAnyPermissionPermanentlyDenied(permissions)) {
      showPermissionPermanentlyDeniedDialog(context);
      return false;
    }

    // Permissions denied but not permanently
    showToast("Storage permissions are required to download files", isError: true);
    return false;
  }

  /// Handles permission flow for uploading files
  Future<bool> requestUploadPermissions(BuildContext context) async {
    // For iOS, we can directly use file picker without explicit permissions
    if (Platform.isIOS) {
      return true;
    }

    // For Android, show rationale dialog first
    final shouldContinue = await showPermissionRationaleDialog(
      context,
      "Storage Permission Required",
      "We need permission to access files on your device. Please grant access to continue.",
    );

    if (!shouldContinue) return false;

    // Request permissions
    final permissions = await _getUploadPermissions();

    // Check if permissions are granted
    if (_arePermissionsGranted(permissions)) {
      return true;
    }

    // Check if any permission is permanently denied
    if (_isAnyPermissionPermanentlyDenied(permissions)) {
      showPermissionPermanentlyDeniedDialog(context);
      return false;
    }

    // Permissions denied but not permanently
    showToast("Storage permissions are required to upload files", isError: true);
    return false;
  }

  /// Downloads an Excel file with proper permissions handling
  Future<void> downloadExcelFile(BuildContext context, String apiUrl) async {
    try {
      // Check if permission is granted first
      final hasPermission = await requestDownloadPermissions(context);
      if (!hasPermission) {
        return;
      }

      // Show downloading progress indicator
      showToast("Downloading Excel file...");

      final url = Uri.parse(apiUrl);
      final filename = "product_list_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      // Get appropriate directory per platform
      Directory? directory;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // For Android 10+ (Q+, API 29+), use getExternalStorageDirectory or app-specific directory
        if (sdkInt >= 29) {
          try {
            // Try Download directory first
            directory = Directory("/storage/emulated/0/Download");
            if (!(await directory.exists())) {
              // Then try external storage
              directory = await getExternalStorageDirectory();
            }
          } catch (e) {
            // Fall back to application documents directory
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          // For Android 9 and below
          try {
            directory = await getExternalStorageDirectory();
          } catch (e) {
            directory = await getApplicationDocumentsDirectory();
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, use the documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        showToast("Failed to access storage directory", isError: true);
        return;
      }

      final downloadPath = "${directory.path}/$filename";
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final file = File(downloadPath);
        await file.writeAsBytes(response.bodyBytes);

        showToast("Excel file downloaded successfully");

        if (Platform.isIOS) {
          // iOS requires special handling to make downloaded files visible
          // in Files app or accessible by the user
          final result = await OpenFile.open(downloadPath);
          if (result.type != ResultType.done) {
            showToast("Could not open the downloaded file", isError: true);
          }
        } else {
          // For Android, show a snackbar with option to open
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
        showToast("Failed to download Excel file (Status: ${response.statusCode})", isError: true);
      }
    } catch (e) {
      debugPrint("Download error: $e");
      showToast("Error: ${e.toString()}", isError: true);
    }
  }

  /// Uploads an Excel file with proper permissions handling
  Future<File?> pickExcelFile(BuildContext context) async {
    try {
      // Request upload permissions
      final hasPermission = await requestUploadPermissions(context);
      if (!hasPermission) {
        return null;
      }

      // Use FilePicker to pick Excel files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        return file;
      } else {
        // User canceled the picker
        return null;
      }
    } catch (e) {
      debugPrint("File picking error: $e");
      showToast("Error selecting file: ${e.toString()}", isError: true);
      return null;
    }
  }
}