import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pharma_five/ui/doctor/website_reference_link.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helper/shared_preferences.dart';
import '../../service/api_service.dart';
import '../admin/widget/reference_web_view_screen.dart';
import '../login_screen.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool isUserActive = false;
  bool _isRefreshing = false;
  String _userStatus = 'pending';
  String _lastRefreshed = '';
  bool _isConnected = true;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _validateUserAndLoadData();
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) async {
          final connected = results.contains(ConnectivityResult.mobile) ||
              results.contains(ConnectivityResult.wifi) ||
              results.contains(ConnectivityResult.ethernet);

          if (mounted) {
            setState(() {
              _isConnected = connected;
            });
            if (connected) {
              await _validateUserAndLoadData();
            }
          }
        });
  }

  Future<bool> _checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _validateUserAndLoadData() async {
    setState(() {
      _isLoading = true;
    });

    await SharedPreferenceHelper.init();
    final isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
    final email = await SharedPreferenceHelper.getUserEmail();

    if (!isLoggedIn || email == null || email.isEmpty) {
      _navigateToLogin();
      return;
    }

    _isConnected = await _checkInternetConnectivity();

    if (!_isConnected) {
      // Use local stored status without navigating away
      final localStatus =
          (await SharedPreferenceHelper.getUserStatus())?.toLowerCase() ??
              'pending';

      setState(() {
        _userStatus = localStatus;
        isUserActive = localStatus == 'active';
        _isLoading = false;
        _isRefreshing = false;
        _lastRefreshed = _getCurrentTimeFormatted();
      });
      return;
    }

    // If internet is available, proceed with API call
    try {
      final result = await ApiService().getUsers(search: email);
      final users = result['content'] ?? [];

      if (users.isNotEmpty) {
        final currentStatus = users[0]['status'].toString().toLowerCase();
        await SharedPreferenceHelper.setUserStatus(currentStatus);

        setState(() {
          _userStatus = currentStatus;
          isUserActive = currentStatus == 'active';
          _isLoading = false;
          _isRefreshing = false;
          _lastRefreshed = _getCurrentTimeFormatted();
        });
      } else {
        setState(() {
          _userStatus = 'not found';
          isUserActive = false;
          _isLoading = false;
          _isRefreshing = false;
          _lastRefreshed = _getCurrentTimeFormatted();
        });
      }
    } catch (e) {
      debugPrint('Status check failed: $e');

      final status =
          (await SharedPreferenceHelper.getUserStatus())?.toLowerCase() ??
              'pending';

      setState(() {
        _userStatus = status;
        isUserActive = status == 'active';
        _isLoading = false;
        _isRefreshing = false;
        _lastRefreshed = _getCurrentTimeFormatted();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not connect to server. Using local status.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _getCurrentTimeFormatted() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToLogin() {
    SharedPreferenceHelper.clearSession().then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateUserAndLoadData();
    }
  }

  // Get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'reject':
        return Colors.red;
      case 'blocked':
        return Colors.red.shade800;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get status display text
  String _getStatusText() {
    switch (_userStatus.toLowerCase()) {
      case 'active':
        return 'Approved ✓';
      case 'reject':
        return 'Rejected ✗';
      case 'blocked':
        return 'Blocked ✗';
      case 'pending':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  Future<void> _logout() async {
    try {
      final email = await SharedPreferenceHelper.getUserEmail();
      if (email != null && email.isNotEmpty) {
        await ApiService().logoutUser(userEmail: email);
      }

      await SharedPreferenceHelper.clearSession();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      debugPrint('Logout failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout failed. Please try again.')),
        );
      }
    }
  }

  Widget _buildInactiveAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: SizedBox(
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/logo_pf.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.local_pharmacy, size: 40, color: Colors.blue),
              ),
            ),
            // const Center(
            //   child: Text(
            //     "Information",
            //     style: TextStyle(
            //       fontSize: 20,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.black,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 60,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Image.asset(
                  "assets/images/logo_pf.png",
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // const Align(
            //   alignment: Alignment.center,
            //   child: Text(
            //     "Information",
            //     style: TextStyle(
            //       fontSize: 20,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.black,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovalMessage() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset("assets/animations/user_waiting.json",
                width: 350, height: 200),
            const SizedBox(height: 24),

            // Status indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Account Status: ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff262A88),
                  ),
                ),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_userStatus),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text(
              _userStatus == 'active'
                  ? "Your account is now approved! You can view information."
                  : "Your account has to be approved by Admin. Please wait.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _userStatus == 'active'
                    ? Colors.green
                    : const Color(0xff262A88),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _userStatus.toLowerCase() == 'rejected'
                  ? "Your account has been rejected by the admin. Please contact support."
                  : (_userStatus.toLowerCase() == 'blocked'
                  ? "Your account has been blocked. Please contact support."
                  : "You will be able to view information once approved."),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _userStatus.toLowerCase() == 'rejected' ||
                    _userStatus.toLowerCase() == 'blocked'
                    ? Colors.red.shade700
                    : Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 20),

            // Refresh button with loading indicator
            _isRefreshing
                ? Column(
              children: [
                const CircularProgressIndicator(color: Color(0xff185794)),
                const SizedBox(height: 8),
                Text(
                  "Checking status...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            )
                : Column(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isRefreshing = true;
                    });
                    _validateUserAndLoadData();
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xff185794),
                    size: 40,
                  ),
                ),
              ],
            ),

            // If active, show a button to view information
            if (_userStatus.toLowerCase() == 'active') ...[
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // This will rebuild the UI with the information content
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff185794),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("View Information",
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInformationContent() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("One Place One Press"),
            const SizedBox(height: 10),
            _buildCard(
              child: const Text(
                "Information about new cancer treatments that are not available in India is often scattered and difficult to find.\n\n"
                    "Our goal with this app is to centralize that information — all in one place — and make it easily accessible to oncologists with just one press, simplifying medical decision-making.\n\n"
                    "The Can-Search app acts as a ready reckoner for oncologists, providing quick access to new cancer medications, available strengths, and prescribing information.\n\n"
                    "Once a treatment is selected, Pharma Five International Pvt. Ltd., through its global network and expertise, ensures the medicine reaches the patient's doorstep.\n\n"
                    "This app is dedicated to all the committed oncologists across the country.",
                style: TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle("Contact Us"),
            const SizedBox(height: 12),
            _buildContactRow("V. Venkataraman", "+919500069255"),
            _buildContactRow("C. Sreekanth", "+919176655641"),
            _buildContactRow("S. Dilli Babu", "+919841829603"),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WebsiteWebViewScreen(
                        url: "https://www.pharmafive.org/",
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.public, color: Colors.white),
                label: const Text(
                  "Visit Website",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff185794),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xff185794))),
      );
    }

    return Scaffold(
      backgroundColor: !isUserActive ? Color(0xffeceef3) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (visible for both active and pending/rejected users)
            isUserActive ? _buildActiveAppBar() : _buildInactiveAppBar(),
            // Content based on user status
            isUserActive
                ? _buildInformationContent()
                : _buildPendingApprovalMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Align(
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xff185794),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildContactRow(String name, String phoneNumber) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
        child: ListTile(
          title: Text(
            name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(phoneNumber),
          trailing: ElevatedButton.icon(
            onPressed: () async {
              final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
              }
            },
            icon: const Icon(Icons.call, color: Colors.white),
            label: const Text("Call", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      _logout();
                    },
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
}