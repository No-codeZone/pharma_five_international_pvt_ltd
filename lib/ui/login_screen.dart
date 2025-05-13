import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:pharma_five/ui/admin/admin_dashboard.dart';
import 'package:pharma_five/ui/forgot_password_screen.dart';
import 'package:pharma_five/ui/registration_screen.dart';
import 'package:pharma_five/ui/walk_through_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../helper/color_manager.dart';
import '../helper/shared_preferences.dart';
import '../service/api_service.dart';
import 'package:flutter/gestures.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin_approval_screen.dart';
import 'doctor/user_dashboard.dart';

// Instead of directly using WebView, we'll create a simpler implementation using a Dialog

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _wasDisconnected = false;
  String? _validationMessage;

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: isError ? Colors.red : const Color(0xff185794),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAndClearSession();
    // Check initial connectivity status but don't show toast for initial connected state
    InternetConnection().hasInternetAccess.then((connected) {
      if (!connected) {
        _wasDisconnected = true;
        _showToast("No internet connection", isError: true);
      }
    });

    // Listen for internet connectivity changes
    InternetConnection().onStatusChange.listen((status) {
      if (status == InternetStatus.disconnected) {
        _wasDisconnected = true;
        _showToast("Internet disconnected", isError: true);
      } else if (_wasDisconnected) {
        // Only show the "connected" toast if previously disconnected
        _wasDisconnected = false;
        _showToast("Internet connected");
      }
    });
  }

  Future<void> _checkAndClearSession() async {
    await SharedPreferenceHelper.init();
    final isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
    final email = await SharedPreferenceHelper.getUserEmail();

    if (isLoggedIn && email != null && email.isNotEmpty) {
      await ApiService().logoutUser(userEmail: email);
      await SharedPreferenceHelper.clearSession();
    }
  }

  void _openTermsAndPrivacyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xff185794),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Pharma Five International Pvt.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TermsAndPrivacyContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _validateForm() async {
    try {
      final isConnected = await InternetConnection().hasInternetAccess;
      if (!isConnected) {
        _showToast("No internet connection. Please check your connection and try again.", isError: true);
        return;
      }

      await SharedPreferenceHelper.init();

      if (_formKey.currentState!.validate()) {
        setState(() => _isLoading = true);

        final email = _emailController.text.trim();
        final password = _passwordController.text;

        final loginResult = await ApiService().userLogin(email: email, password: password);

        final bool success = loginResult?['success'] ?? false;
        final String message = loginResult?['message'] ?? '';
        final Map<String, dynamic>? data = loginResult?['data'];
        final String role = loginResult?['role'] ?? '';
        final String status = loginResult?['status'] ?? '';

        await SharedPreferenceHelper.setLoggedIn(true);
        await SharedPreferenceHelper.setUserEmail(email);
        await SharedPreferenceHelper.setUserType(role);
        await SharedPreferenceHelper.setUserStatus(status);

        if (success && data != null) {

          _showToast("${role[0].toUpperCase()}${role.substring(1)} login successful!");

          if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              // MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          } else if (role == 'user' && status == 'active') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
            );
          }
        } else if (!success &&
            (message.contains("Account is not ACTIVE. Current status: Pending") || message.contains("Account is not ACTIVE. Current status: Reject"))) {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
          );
        } else {
          _showToast(message.isNotEmpty ? message : "Login failed.", isError: true);
        }
      }
    } catch (e) {
      _showToast("Login failed. Please try again.", isError: true);
      debugPrint('Login error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back + Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => WalkthroughScreen()),
                            )
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xff185794),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF9ABEE3), width: 4),
                            ),
                            child: const Center(
                              child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/logo_pf.png',
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.medical_services_outlined,
                                  color: Color(0xff185794), size: 30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Login to Pharma Five International Private Limited',
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Join us today for easy medicine',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const Text(
                      'management!',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),

                    const SizedBox(height: 30),

                    buildTextField("Email or username", _emailController),
                    buildPasswordField(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        // onPressed: () {
                        //   Navigator.pushReplacement(
                        //     context,
                        //     MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        //   );
                        // },
                        onPressed: _isLoading ? null : _validateForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff185794),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xff185794)),
                          ),
                        )
                            : const Text('Log In',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegistrationScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Color(0xff185794)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Sign Up',
                            style: TextStyle(
                                color: Color(0xff185794),
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    // const SizedBox(height: 16),

                    /*Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: RichText(
                          textAlign: TextAlign.start,
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600),
                            children: [
                              const TextSpan(
                                  text: 'By signing in, you agree to the '),
                              TextSpan(
                                text: 'Terms and Privacy Policy',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _openTermsAndPrivacyDialog,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),*/
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        'I forgot my password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.navBorder,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "$label is required";
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: "Password",
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Password is required";
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class TermsAndPrivacyContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1
        const Text(
          'Terms and Privacy Policy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xff185794),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Welcome to Pharma Five International Pvt.. By using our application, you agree to the following terms and conditions.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Section 2
        const Text(
          '1. User Agreement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff185794),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'By accessing or using Pharma Five International Pvt., you agree to be bound by these Terms and Conditions. If you disagree with any part of these terms, you may not access the service.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Section 3
        const Text(
          '2. Privacy Policy',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff185794),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information when you use our app.\n\nWe collect personal information such as name, email, and professional credentials for account management and service delivery.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Section 4
        const Text(
          '3. Cancer Medication Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff185794),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pharma Five International Pvt. provides access to various medications, including specialized oncology treatments:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),

        // Drug Info 1
        _buildDrugInfoCard(
          'Pembrolizumab (Keytruda®)',
          'Immune checkpoint inhibitor',
          'Melanoma, non-small cell lung cancer, head and neck squamous cell carcinoma',
          'Fatigue, rash, diarrhea, nausea, decreased appetite',
          'USD 10,500 - USD 15,000 per treatment cycle',
        ),
        const SizedBox(height: 12),

        // Drug Info 2
        _buildDrugInfoCard(
          'Osimertinib (Tagrisso®)',
          'EGFR tyrosine kinase inhibitor',
          'Non-small cell lung cancer with specific EGFR mutations',
          'Rash, diarrhea, dry skin, nail toxicity, decreased appetite',
          'USD 8,000 - USD 12,000 per month',
        ),
        const SizedBox(height: 12),

        // Drug Info 3
        _buildDrugInfoCard(
          'Lenvatinib (Lenvima®)',
          'Multikinase inhibitor',
          'Thyroid cancer, renal cell carcinoma, hepatocellular carcinoma',
          'Hypertension, fatigue, diarrhea, decreased appetite, weight loss',
          'USD 7,000 - USD 9,500 per month',
        ),
        const SizedBox(height: 20),

        // Section 5
        const Text(
          '4. Use Limitations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff185794),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Information provided in this application is for professional healthcare use only. All medication information should be verified with official prescribing information.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Section 6
        const Text(
          '5. Data Security',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff185794),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We implement best practices to secure all user and medication data. This includes encryption, secure servers, and regular security audits.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Section 7 - Table
        const Text(
          '6. Oncology Product Availability',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff185794),
          ),
        ),
        const SizedBox(height: 12),
        _buildMedicationTable(),
        const SizedBox(height: 20),

        // Section 8
        const Text(
          '7. Contact Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff185794),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'For questions regarding these terms or our privacy practices:\n\nEmail: privacy@pharmafive.com\nPhone: +1-555-PHARMA5',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Section 9
        const Text(
          '8. Terms Updates',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xff185794),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'These Terms and Privacy Policy may be updated occasionally. We will notify users of significant changes.\n\nLast Updated: April 15, 2025',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDrugInfoCard(
      String name, String classification, String indications, String sideEffects, String priceRange) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xff185794),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black),
              children: [
                const TextSpan(
                  text: 'Classification: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: classification),
              ],
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black),
              children: [
                const TextSpan(
                  text: 'Indications: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: indications),
              ],
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black),
              children: [
                const TextSpan(
                  text: 'Common Side Effects: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: sideEffects),
              ],
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black),
              children: [
                const TextSpan(
                  text: 'Price Range: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: priceRange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Medication',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Stock',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Lead Time',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Row 1
          _buildTableRow('Rituximab', 'Available', '3-5 days', false),
          _divider(),

          // Row 2
          _buildTableRow('Trastuzumab', 'Limited', '7-10 days', false),
          _divider(),

          // Row 3
          _buildTableRow('Bevacizumab', 'Available', '2-4 days', false),
          _divider(),

          // Row 4
          _buildTableRow('Enzalutamide', 'Out of stock', '14-21 days', false),
          _divider(),

          // Row 5
          _buildTableRow('Olaparib', 'Available', '3-5 days', true),
        ],
      ),
    );
  }

  Widget _buildTableRow(String medication, String stock, String leadTime, bool isLast) {
    Color stockColor;

    if (stock == 'Available') {
      stockColor = Colors.green;
    } else if (stock == 'Limited') {
      stockColor = Colors.orange;
    } else {
      stockColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: isLast
            ? const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(medication),
          ),
          Expanded(
            child: Text(
              stock,
              style: TextStyle(
                color: stockColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(leadTime),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: Colors.grey.shade300,
    );
  }

}