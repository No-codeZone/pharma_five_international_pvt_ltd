import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';

class ReferenceWebViewScreen extends StatefulWidget {
  final String url;
  const ReferenceWebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  State<ReferenceWebViewScreen> createState() => _ReferenceWebViewScreenState();
}

class _ReferenceWebViewScreenState extends State<ReferenceWebViewScreen> {
  late final WebViewController controller;
  int loadingPercentage = 0;
  bool isConnected = true;
  late StreamSubscription connectivitySubscription;

  @override
  void initState() {
    super.initState();

    if (WebViewPlatform.instance is! AndroidWebViewPlatform) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }

    _initWebView();

    _checkInternetStatus();
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((_) {
      _checkInternetStatus();
    });
  }

  void _checkInternetStatus() async {
    final result = await Connectivity().checkConnectivity();
    final currentlyConnected = result != ConnectivityResult.none;

    if (mounted) {
      if (currentlyConnected && !isConnected) {
        controller.reload(); // ✅ Just reload instead of re-creating controller
      }
      setState(() => isConnected = currentlyConnected);
    }
  }

  void _initWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => loadingPercentage = 0),
          onProgress: (progress) => setState(() => loadingPercentage = progress),
          onPageFinished: (_) => setState(() => loadingPercentage = 100),
          onWebResourceError: (_) => setState(() => isConnected = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reference Link', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff185794),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: isConnected
          ? Stack(
        children: [
          WebViewWidget(controller: controller),
          if (loadingPercentage < 100)
            const LinearProgressIndicator(minHeight: 4),
        ],
      )
          : Center(
        child: Lottie.asset(
          'assets/animations/internet.json',
          width: 250,
        ),
      ),
    );
  }
}