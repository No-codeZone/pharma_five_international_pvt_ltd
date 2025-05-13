import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ For orientation lock
import 'package:pharma_five/ui/splash_screen.dart';
import 'helper/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock the app orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SharedPreferenceHelper.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharma Five International Pvt.',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
