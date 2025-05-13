import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:pharma_five/ui/admin/product_list_tab.dart';
import 'package:pharma_five/ui/admin/report_tab.dart';
import 'package:pharma_five/ui/admin/user_list_tab.dart';

import '../../service/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;
  int _currentPage = 0;
  String selectedStatus = 'Pending';
  final ApiService _apiService = ApiService();


  void _onStatusUpdate(String email, String newStatus) async {
    final url = Uri.parse("${_apiService.baseUrl}${_apiService.userUpdateAPI}");
    final requestBody = {
      "email": email,
      "status": newStatus, // "Active" or "Reject"
    };

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        Fluttertoast.showToast(
          msg: "Status updated for $email",
          backgroundColor: Colors.green,
          textColor: Colors.white,
          gravity: ToastGravity.TOP,
        );

        // Optionally trigger refresh of user list
        setState(() {
          _currentPage = 0;
        });
      } else {
        Fluttertoast.showToast(
          msg: "Failed: ${responseData['message'] ?? 'Unknown error'}",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.TOP,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating status: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get screen size and adjust layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 500;
    final isLargeScreen = screenWidth > 1200;

    // Responsive padding and font sizes
    final horizontalPadding =
    isSmallScreen ? 10.0 : (isLargeScreen ? 40.0 : 20.0);
    final logoSize = isSmallScreen ? 60.0 : 80.0;
    final titleFontSize = isSmallScreen ? 16.0 : 18.0;
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            UserListTab(
              // selectedStatus: selectedStatus,
              currentPage: _currentPage,
              onStatusUpdate: _onStatusUpdate,
              onPageChange: (newPage) {
                setState(() {
                  _currentPage = newPage;
                });
              },
            ),
            const ProductListTab(),
            const ReportTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xff185794), width: 2),
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(30),
            right: Radius.circular(30),
          ),
        ),
        child: SnakeNavigationBar.color(
          padding: EdgeInsets.zero,
          behaviour: SnakeBarBehaviour.floating,
          snakeShape: SnakeShape.circle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: Colors.white,
          snakeViewColor: Color(0xff185794),
          unselectedItemColor: Color(0xff185794),
          currentIndex: _selectedTab,
          onTap: (index) => setState(() => _selectedTab = index),
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(left: 3.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: Image.asset(
                      _selectedTab == 0
                          ? "assets/images/user_lists.png"
                          : "assets/images/user_list2.png",
                      // height: 20,
                      // width: 20,
                      alignment: Alignment.center,
                      fit: BoxFit.contain
                  ),
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(left: 3.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: Image.asset(
                      _selectedTab == 1
                          ? "assets/images/product_list.png"
                          : "assets/images/product_list2.png",
                      // height: 20,
                      // width: 20,
                      alignment: Alignment.center,
                      fit: BoxFit.contain
                  ),
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: Image.asset(
                    _selectedTab == 2
                        ? "assets/images/reports.png"
                        : "assets/images/report2.png",
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
          ],
          selectedLabelStyle: TextStyle(fontSize: titleFontSize - 2),
          unselectedLabelStyle: TextStyle(fontSize: titleFontSize - 2),
          showUnselectedLabels: true,
          showSelectedLabels: true,
        ),
      ),
    );
  }
}