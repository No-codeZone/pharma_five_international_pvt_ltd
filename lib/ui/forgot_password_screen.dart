import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:pharma_five/service/api_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isSubmitting = false;
  bool _isOtpSent = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isOtpValid = false;
  bool _canResend = false;

  int _remainingSeconds = 60;
  Timer? _timer;

  final String verifyOTPAPI = '/reset-password';
  late StreamSubscription<InternetStatus> _connectionSubscription;
  bool _wasDisconnected = false;

  @override
  void initState() {
    super.initState();

    // Initial internet check
    InternetConnection().hasInternetAccess.then((connected) {
      if (!connected) {
        _wasDisconnected = true;
        _showToast("No internet connection", isError: true);
      }
    });

    // Listen to changes
    _connectionSubscription = InternetConnection().onStatusChange.listen((status) {
      if (status == InternetStatus.disconnected) {
        _wasDisconnected = true;
        _showToast("Internet disconnected", isError: true);
      } else if (_wasDisconnected) {
        _wasDisconnected = false;
        _showToast("Internet connected");
      }
    });
  }



  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isError ? Colors.red : const Color(0xff185794),
      textColor: Colors.white,
      gravity: ToastGravity.TOP,
    );
  }

  void _startResendTimer() {
    _remainingSeconds = 60;
    _canResend = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  Future<Map<String, dynamic>?> _sendOTPApi({required String email}) async {
    final url = Uri.parse('${ApiService().baseUrl}${ApiService().sendOTPAPI}');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? "OTP send failed.",
      };
    } catch (_) {
      return {'success': false, 'message': "An error occurred. Please try again."};
    }
  }

  Future<void> _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      final email = _emailController.text.trim();
      final result = await _sendOTPApi(email: email);
      setState(() => _isSubmitting = false);

      if (result?['success'] == true) {
        _showToast(result!['message']);
        _otpController.clear();
        _startResendTimer();

        setState(() {
          _isOtpSent = true;
          _isOtpValid = false;
        });
      } else {
        _showToast(result?['message'] ?? "Failed to send OTP", isError: true);
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_formKey.currentState!.validate() && _otpController.text.length == 6) {
      setState(() => _isSubmitting = true);
      final result = await _verifyOTPApi(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      setState(() => _isSubmitting = false);

      if (result?['success'] == true) {
        _showToast(result!['message']);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        _showToast(result?['message'] ?? "Verification failed", isError: true);
      }
    } else {
      _showToast("Enter a valid 6-digit OTP", isError: true);
    }
  }

  Future<Map<String, dynamic>?> _verifyOTPApi({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse('${ApiService().baseUrl}$verifyOTPAPI');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "newPassword": newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? "Password reset failed.",
      };
    } catch (_) {
      return {'success': false, 'message': "An error occurred. Please try again."};
    }
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    _timer?.cancel();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isFieldDisabled = _isOtpSent;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildTitle(),
                const SizedBox(height: 20),
                _buildTextField("Email", _emailController, TextInputType.emailAddress,
                      (value) {
                    if (value == null || value.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Enter a valid email';
                    return null;
                  },
                  enabled: !isFieldDisabled,
                ),
                _buildPasswordField("New Password", _newPasswordController, _obscureNewPassword, () {
                  setState(() => _obscureNewPassword = !_obscureNewPassword);
                }, (val) => val == null || val.length < 8 ? 'Minimum 8 characters' : null, enabled: !isFieldDisabled),
                _buildPasswordField("Confirm Password", _confirmPasswordController, _obscureConfirmPassword, () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                }, (val) => val != _newPasswordController.text ? "Passwords don't match" : null, enabled: !isFieldDisabled),

                if (_isOtpSent)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      enabled: true,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: "Enter OTP",
                        hintText: "000000",
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _isOtpValid = value.trim().length == 6);
                      },
                    ),
                  ),

                if (_isOtpSent && !_canResend)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Resend in: $_remainingSeconds sec',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      ),
                    ),
                  ),

                if (_isOtpSent && _canResend)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _sendOTP,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: Color(0xff185794),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : _isOtpSent
                        ? (_isOtpValid ? _verifyOTP : null)
                        : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff185794),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : Text(_isOtpSent ? "Verify OTP" : "Reset Password"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text('Reset Your Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        Text('A 6-digit OTP will be sent to your email', style: TextStyle(fontSize: 14, color: Colors.black54)),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xff185794),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF9ABEE3), width: 2),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
        Image.asset(
          'assets/images/pharmafive_512x512.png',
          width: 80,
          height: 80,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.medical_services_outlined, color: Colors.blue, size: 30),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType inputType,
      FormFieldValidator<String> validator,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        validator: validator,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      String label,
      TextEditingController controller,
      bool obscureText,
      VoidCallback toggleVisibility,
      FormFieldValidator<String> validator, {
        bool enabled = true,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }
}
