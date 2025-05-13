import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../helper/shared_preferences.dart';
import '../service/api_service.dart';
import 'login_screen.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  String userStatus = 'pending';
  String? userEmail;
  bool checking = false;
  late String statusMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await SharedPreferenceHelper.init();
    final isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
    final email = await SharedPreferenceHelper.getUserEmail();
    final status = (await SharedPreferenceHelper.getUserStatus())?.toLowerCase() ?? 'pending';

    if (!isLoggedIn || email == null || email.isEmpty) {
      _navigateToLogin();
      return;
    }

    setState(() {
      userEmail = email;
      userStatus = status;
      _loading = false;
    });
  }

  Future<void> _navigateToLogin() async {
    await SharedPreferenceHelper.clearSession();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _showToast(String message, bool isError) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: isError ? Colors.red : const Color(0xff185794),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> checkStatus() async {
    setState(() => checking = true);
    try {
      final response = await ApiService().getUsers(search: userEmail ?? '');
      final users = response['content'] ?? [];

      if (users.isNotEmpty) {
        final status = users[0]['status'].toString().toLowerCase();
        await SharedPreferenceHelper.setUserStatus(status);

        setState(() {
          userStatus = status;
        });

        _showToast("Your status is now: $status", false);
      } else {
        _showToast("User not found.", true);
      }
    } catch (e) {
      debugPrint("Status check failed: $e");
      _showToast("Failed to check status", true);
    } finally {
      setState(() => checking = false);
    }
  }

  Future<void> logout() async {
    try {
      final email = await SharedPreferenceHelper.getUserEmail();
      if (email != null && email.isNotEmpty) {
        await ApiService().logoutUser(userEmail: email);
      }
      await SharedPreferenceHelper.clearSession();
      _showToast("Logout successful.", false);
      _navigateToLogin();
    } catch (e) {
      debugPrint('Logout failed: $e');
      _showToast('Logout failed. Please try again.', true);
    }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Color(0xff262A88)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    statusMessage = userStatus == 'rejected'
        ? "Your account has been rejected. Please contact the administrator."
        : "Your account is in $userStatus state. Please wait for admin approval.";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Approval"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Account Status",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Current Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Chip(
                    label: Text(
                      userStatus.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: userStatus == 'rejected'
                        ? Colors.red
                        : userStatus == 'pending'
                        ? Colors.orange
                        : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: checking ? null : checkStatus,
                child: checking
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text("Check Status"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}