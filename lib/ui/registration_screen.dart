import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:pharma_five/ui/login_screen.dart';
import 'package:pharma_five/ui/walk_through_screen.dart';
import '../service/api_service.dart';
import 'package:http/http.dart' as http;
import '../service/internet_connectivity_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _validationMessage;
  bool _isLoading = false;

  bool _isNameValid = true;
  bool _isOrganizationValid = true;
  bool _isMobileValid = true;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _wasDisconnected = false;

  @override
  void initState() {
    super.initState();

    hasRealInternetConnection().then((connected) {
      if (!connected) {
        _wasDisconnected = true;
        _showToast("No internet connection", true);
      }
    });

  }


  void _showToast(String message, bool isError) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: isError ? Colors.red : const Color(0xff262A88),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _validateForm() async {
    setState(() {
      _validationMessage = null;
      _isLoading = false;
      _isNameValid = true;
      _isOrganizationValid = true;
      _isMobileValid = true;
      _isEmailValid = true;
      _isPasswordValid = true;
    });

    bool hasError = false;

    if (_nameController.text.trim().isEmpty) {
      _isNameValid = false;
      hasError = true;
    }

    if (_organizationController.text.trim().isEmpty) {
      _isOrganizationValid = false;
      hasError = true;
    }

    if (_mobileController.text.trim().isEmpty || _mobileController.text.length != 10) {
      _isMobileValid = false;
      hasError = true;
      _validationMessage = _mobileController.text.trim().isEmpty
          ? "Please enter mobile number"
          : "Mobile number must be 10 digits";
    }

    /*final emailPattern = r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$";
    final isEmailValidRegex = RegExp(emailPattern).hasMatch(_emailController.text.trim());

    if (_emailController.text.trim().isEmpty || !isEmailValidRegex) {
      _isEmailValid = false;
      hasError = true;
      _validationMessage = _emailController.text.trim().isEmpty
          ? "Please enter email"
          : "Enter a valid email address";
    }*/

    if (_passwordController.text.trim().isEmpty || _passwordController.text.length < 8) {
      _isPasswordValid = false;
      hasError = true;
      _validationMessage = _passwordController.text.trim().isEmpty
          ? "Please enter password"
          : "Password must include at least 8 characters";
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final isConnected = await InternetConnection().hasInternetAccess;
    if (!isConnected) {
      _showToast("No internet connection. Please check your connection and try again.", true);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final response = await ApiService()
          .registerUser(
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        organisationName: _organizationController.text.trim(),
        password: _passwordController.text.trim(),
      )
          .timeout(const Duration(seconds: 60),
          onTimeout: () => throw TimeoutException("Request timed out"));

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response['success']) {
        // Clear fields
        _nameController.clear();
        _organizationController.clear();
        _mobileController.clear();
        _emailController.clear();
        _passwordController.clear();

        setState(() {
          _validationMessage = null;
          _isNameValid = true;
          _isOrganizationValid = true;
          _isMobileValid = true;
          _isEmailValid = true;
          _isPasswordValid = true;
        });

        _showToast(response['message'], false);

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
            );
          }
        });
      } else {
        setState(() => _validationMessage = response['message']);
        _showToast(response['message'], false);

        debugPrint("Registration response is here===\t${response['message'].toString()}");

        _nameController.clear();
        _organizationController.clear();
        _mobileController.clear();
        _emailController.clear();
        _passwordController.clear();

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
            );
          }
        });
      }
    } on TimeoutException {
      setState(() {
        _isLoading = false;
        _validationMessage = "Request timed out! Please try again.";
      });
      _showToast("Request timed out! Please try again.", true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _validationMessage = "An unexpected error occurred.";
      });
      _showToast("An unexpected error occurred.", true);
    }
  }

  Future<bool> hasRealInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;

    try {
      final result = await http.get(Uri.parse('https://www.google.com')).timeout(Duration(seconds: 3));
      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _handleConnectivityChange(ConnectivityResult result) async {
    final connected = await hasRealInternetConnection();
    if (!connected && !_wasDisconnected) {
      _wasDisconnected = true;
      _showToast("Internet disconnected", true);
    } else if (connected && _wasDisconnected) {
      _wasDisconnected = false;
      _showToast("Internet connected", false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const WalkthroughScreen()),
                        ),
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
                        errorBuilder: (_, __, ___) => Icon(Icons.medical_services_outlined,
                            color: Color(0xff185794), size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Signup to Pharma Five International Private Limited',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join us today for easy\nmedicine management!',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  buildTextField("Full Name", _nameController, isValid: _isNameValid),
                  buildTextField("Organization", _organizationController, isValid: _isOrganizationValid),
                  buildMobileNumberField(),
                  buildTextField("Email", _emailController, isEmail: true, isValid: _isEmailValid),
                  buildPasswordField(),

                  if (_validationMessage != null &&
                      (!_isNameValid || !_isOrganizationValid || !_isMobileValid || !_isEmailValid || !_isPasswordValid))
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationMessage!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff185794),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff185794)),
                        ),
                      )
                          : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: const BorderSide(color: Color(0xff185794)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Login',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xff185794))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  /*Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        children: const [
                          TextSpan(text: 'By signing in, you agree to the '),
                          TextSpan(
                            text: 'Terms and Privacy Policy',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),*/
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool isEmail = false, bool isValid = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: isValid ? BorderSide.none : const BorderSide(color: Color(0xff185794), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: isValid ? BorderSide.none : const BorderSide(color: Color(0xff185794), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xff185794), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget buildMobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.number,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: "Mobile Number",
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: _isMobileValid ? BorderSide.none : const BorderSide(color: Color(0xff185794), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: _isMobileValid ? BorderSide.none : const BorderSide(color: Color(0xff185794), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xff185794), width: 2),
            ),
            counterText: "",
          ),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: _isPasswordValid ? BorderSide.none : const BorderSide(color: Color(0xff185794), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: _isPasswordValid ? BorderSide.none : const BorderSide(color: Color(0xff185794), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xff185794), width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}