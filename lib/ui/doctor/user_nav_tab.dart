import 'package:flutter/material.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:pharma_five/ui/doctor/info_screen.dart';
import 'package:pharma_five/ui/doctor/user_dashboard.dart';

class UserNavTab extends StatefulWidget {
  const UserNavTab({Key? key}) : super(key: key);

  @override
  State<UserNavTab> createState() => _UserNavTabState();
}

class _UserNavTabState extends State<UserNavTab> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;
    final isLargeScreen = screenWidth > 1200;

    final titleFontSize = isSmallScreen ? 16.0 : 18.0;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: const [
            UserDashboardScreen(),
            InfoScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xff185794), width: 2),
          borderRadius: const BorderRadius.horizontal(
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
          snakeViewColor: const Color(0xff185794),
          unselectedItemColor: const Color(0xff185794),
          currentIndex: _selectedTab,
          onTap: (index) => setState(() => _selectedTab = index),
          items: [
            // 🟣 0: Product tab
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(left: 3.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: Image.asset(
                    _selectedTab == 0
                        ? "assets/images/product_list.png"
                        : "assets/images/product_list2.png",
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              label: 'Products',
            ),
            // 🔵 1: Info tab
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: SizedBox(
                  height: 25,
                  width: 25,
                  child: Image.asset(
                    _selectedTab == 1
                        ? "assets/images/info_icon_active.png"
                        : "assets/images/info_icon_inactive.png",
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              label: 'Info',
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