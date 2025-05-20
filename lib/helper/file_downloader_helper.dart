
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class FileDownloadHelper {
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

      if (sdkInt >= 33) {
        var photos = await Permission.photos.request();
        var media = await Permission.mediaLibrary.request();

        if (photos.isGranted && media.isGranted) return true;
        if (photos.isPermanentlyDenied || media.isPermanentlyDenied) {
          openAppSettings();
        }
        return false;
      } else if (sdkInt >= 30) {
        var storage = await Permission.storage.request();
        var manage = await Permission.manageExternalStorage.request();

        if (storage.isGranted && manage.isGranted) return true;
        if (storage.isPermanentlyDenied || manage.isPermanentlyDenied) {
          openAppSettings();
        }
        return false;
      } else {
        var storage = await Permission.storage.request();
        if (storage.isGranted) return true;
        if (storage.isPermanentlyDenied) openAppSettings();
        return false;
      }
    }

    if (Platform.isIOS) {
      var status = await Permission.photos.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) openAppSettings();
      return false;
    }

    return true;
  }

  static Future<Directory?> getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Download');
        return await dir.exists() ? dir : await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      return await getApplicationDocumentsDirectory();
    }
    return null;
  }

  static Future<void> showFileDownloadSnackBar(
      BuildContext context, String filePath, bool isIOS) async {
    final fileName = filePath.split('/').last;
    final message = isIOS
        ? 'Excel file downloaded successfully'
        : 'Excel downloaded to: $filePath';

    final actionLabel = isIOS ? 'Share' : 'Open';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xff185794),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: () async {
            try {
              if (isIOS) {
                await Share.shareXFiles([XFile(filePath)], text: fileName);
              } else {
                await OpenFile.open(filePath);
              }
            } catch (e) {
              Fluttertoast.showToast(
                msg: 'Failed to open: \$e',
                backgroundColor: Colors.red,
              );
            }
          },
        ),
      ),
    );
  }
}