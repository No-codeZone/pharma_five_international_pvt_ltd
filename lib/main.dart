import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ For orientation lock
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';
import 'package:pharma_five/ui/splash_screen.dart';
import 'helper/shared_preferences.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /*const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  // ✅ No onDidReceiveLocalNotification here
  final DarwinInitializationSettings iOSInit = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  final InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iOSInit,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      if (response.payload != null) {
        OpenFile.open(response.payload);
      }
    },
    // ✅ Optionally handle foreground notification taps on older iOS
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );*/

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SharedPreferenceHelper.init();
  runApp(const MyApp());
}

/// If you need background response handler
/*@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.payload != null) {
    OpenFile.open(response.payload);
  }
}*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharma Five',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        // backgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
