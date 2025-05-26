import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';

class WebsiteWebViewScreen extends StatefulWidget {
  final String url;
  const WebsiteWebViewScreen({Key? key, required this.url}) : super(key: key);

  @override
  State<WebsiteWebViewScreen> createState() => _WebsiteWebViewScreenState();
}

class _WebsiteWebViewScreenState extends State<WebsiteWebViewScreen> {
  late final WebViewController controller;
  int loadingPercentage = 0;
  bool isConnected = true;
  late StreamSubscription connectivitySubscription;

  @override
  void initState() {
    super.initState();

    // Remove the platform-specific initialization that's causing issues
    // WebViewPlatform.instance check is not needed and causes issues on iOS

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
        controller.reload(); // Just reload instead of re-creating controller
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
            LinearProgressIndicator(
              value: loadingPercentage / 100,
              minHeight: 4,
            ),
        ],
      )
          : Center(
        child: Lottie.asset(
          'assets/animations/internet.json',
          width: 180,
        ),
      ),
    );
  }
}

// The buildInfoCard method without changes
Widget buildInfoCard(BuildContext context, String key, String? value) {
  if (value == null || value.trim().isEmpty || value.trim().toUpperCase() == "-NA") {
    return const SizedBox.shrink();
  }

  final isReferenceLink = key == "Website Link";

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 1,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: Colors.white.withOpacity(0.95),
      title: Text(
        key,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Color(0xff185794),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: isReferenceLink
            ? GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WebsiteWebViewScreen(url: value),
              ),
            );
          },
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        )
            : Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[800],
            height: 1.4,
          ),
        ),
      ),
    ),
  );
}