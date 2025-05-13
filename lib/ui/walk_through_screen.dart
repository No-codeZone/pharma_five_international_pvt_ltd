import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pharma_five/ui/registration_screen.dart';

import '../helper/shared_preferences.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_dashboard_screen.dart';
import 'doctor/user_dashboard.dart';
import 'login_screen.dart';

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({Key? key}) : super(key: key);

  @override
  _WalkthroughScreenState createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await SharedPreferenceHelper.init();

    bool isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
    String? userType = await SharedPreferenceHelper.getUserType();

    if (isLoggedIn && userType != null) {
      Widget nextScreen =
           // AdminDashboardScreen();
          userType == 'admin' ? const AdminDashboardScreen() : UserDashboardScreen();
          // userType == 'admin' ? const AdminDashboard() : UserDashboardScreen();

      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo_pf.png',
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.medical_services_outlined,
                        color: Color(0xff185794),
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Join us today for easy',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'medicine management!',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Container(
                width: double.infinity,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      child: Image.asset(
                        'assets/animations/icons_logo_sign.gif', // Update with your GIF path
                        width: 320,
                        height: 320,
                        fit: BoxFit.cover,
                      ),
                    ),
                    /*Lottie.asset("assets/animations/pharma_five_landing_img.json",
                        width: 320, height: 320, fit: BoxFit.cover)*/
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200, // Light gray background
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              // Slight shadow color
                              spreadRadius: 3,
                              blurRadius: 6,
                              offset:
                                  Offset(0, 3), // Positioned slightly downward
                            ),
                          ],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegistrationScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff185794),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            elevation:
                                0, // No built-in elevation since we're using custom shadow
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Image.asset(
                                    'assets/images/_signup_btn_icon_img.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 30),
                              const Text('Sign Up',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xffffffff), // Pure white background
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade50,
                            // Almost white button color
                            foregroundColor: Colors.grey.shade600,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            elevation: 0, // Flat design, no shadow
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  // Keeping icon container white
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Image.asset(
                                    'assets/images/_login_btn_icon_img.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 30),
                              Text(
                                'Login',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
