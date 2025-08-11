import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pharma_five/ui/doctor/website_reference_link.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helper/shared_preferences.dart';
import '../../service/api_service.dart';
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
  bool _isDeletingAccount = false;

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

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      final email = await SharedPreferenceHelper.getUserEmail();
      if (email != null && email.isNotEmpty) {
        final result = await ApiService().deleteUser(userEmail: email);

        if (result['success'] == true) {
          await SharedPreferenceHelper.clearSession();

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Account deleted successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception(result['message'] ?? 'Failed to delete account');
        }
      } else {
        throw Exception('User email not found');
      }
    } catch (e) {
      debugPrint('Delete account failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
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
            // Menu button for inactive users
            /*Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _showMenuOptions,
                icon: const Icon(Icons.more_vert, color: Colors.black87),
              ),
            ),*/
            if (_userStatus.toLowerCase() == 'active')
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _showMenuOptions,
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                ),
              ),
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
            // Menu button for active users
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: IconButton(
                  onPressed: _showMenuOptions,
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                ),
              ),
            ),
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
            _buildSectionTitle("PROCESS NOTE ON NAMED PATIENT BASIS IMPORTS"),
            const SizedBox(height: 10),
            Draft1InformationCard(),
            const SizedBox(height: 24),
            _buildSectionTitle("Bringing Essential Medicines to You—Seamlessly and Legally"),
            const SizedBox(height: 10),
            Draft2InformationCard(),
            const SizedBox(height: 24),
            _buildSectionTitle("Contact Us"),
            const SizedBox(height: 10),
            VenkataramanInformationCard(),
            const SizedBox(height: 24),
            DilliBabuInformationCard(),
            const SizedBox(height: 24),
            SreekanthInformationCard(),
            const SizedBox(height: 24),
            RandipInformationCard(),
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

  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Account',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteAccountDialog();
                  },
                ),
                // const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isDeletingAccount, // Prevent dismissing while deleting
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'This action cannot be undone. All your data will be permanently deleted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Are you sure you want to delete your account?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                  if (_isDeletingAccount) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(color: Colors.red),
                    const SizedBox(height: 10),
                    const Text(
                      'Deleting account...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
              actions: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                        onPressed: _isDeletingAccount ? null : () {
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
                        onPressed: _isDeletingAccount ? null : () {
                          Navigator.of(context).pop();
                          _deleteAccount();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        child: _isDeletingAccount
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
class Draft1InformationCard extends StatefulWidget {
  const Draft1InformationCard({super.key});

  @override
  State<Draft1InformationCard> createState() => _Draft1InformationCardState();
}

class _Draft1InformationCardState extends State<Draft1InformationCard> {
  bool _expanded = false;

  static const String _fullText =
      // "PROCESS NOTE ON NAMED PATIENT BASIS IMPORTS\n\n"
      "We provide medicines that are not available in India to patients in India on a Named Patient Basis Imports. "
      "This includes sourcing the medicine from the supplier to safely delivering the medicine to the patient’s doorstep. "
      "This process is 100% legal and through original and verified sources. "
      "We source the medicine directly from the supplier outside India and do not charge anything from the patient for this facilitation service.\n\n"
      "It is to be noted that the lead time provided below is very stringent and cannot be expedited as it involves many participants like the Government offices that provide the license, "
      "the customs office that clears the import, and the shipping process through air cargo. "
      "Also, the suppliers abroad have a standard process which they follow and are bound by the local laws. "
      "We want the patients to understand that the shipment will take at least 14 to 16 Working days (excluding Saturdays and Sundays) from the date of payment to the supplier outside India. "
      "We assure that every effort will be taken at our end to supply the medicine within the stipulated timeline, subject to any extreme situations which may lead to certain delays. "
      "We do want to convey that such occurrences are very rare and most of the shipments we deliver are generally on time. "
      "The detailed process is explained below.\n\n"
      "The following documents are expected to be provided by the patient:\n"
      "• Prescription mentioning medicine name with strength and dosage with treating Doctor’s stamp & registration number of the Doctor in the doctor’s letterhead.\n"
      "• Patient’s Aadhar ID.\n"
      "• Attender’s Aadhar ID (can be anyone like relatives, caretakers etc.).\n"
      "• One Email ID and Mobile Number accessible by the patient or their attender for OTP. (used for filing application for import license).\n"
      "• CDEC certificate signed by a government doctor (can be arranged by us for a fee)\n\n"
      "Once the above documents are received, we will apply for import license from government portal. This process takes 2 to 3 working days.\n"
      "Once we receive approval, we will provide the license to the patient along with the proforma invoice along with bank account details received from the supplier.\n"
      "The patient, along with the above documents mentioned and the documents provided by us, will have to wire transfer the sum mentioned in the proforma invoice and share us the acknowledgement with payment reference number. "
      "Please note that the patient’s name is to be mentioned in the reference column while making the above payment.\n"
      "Once we receive the acknowledgement, the process of import starts. It is from here that the shipment is accepted and the stipulated timeline of 14 – 16 working days starts.\n"
      "The charges for shipment from the source country to the patient will be on actual basis and shall be paid by the patient to us in INR. "
      "We will provide proper bills for the same and any money received in excess of the bills provided by us, will be refunded to the patient’s bank account.\n"
      "We will provide a set of documents on which the patient is required to sign for the customs clearance process.\n"
      "The actual invoice of the medicine along with the customs bill of entry will be provided within 10 days from the time of delivery of medicine to your doorstep.\n\n"
      "We ensure a smooth process and timebound delivery with an unmatched track record for 8 years and counting.\n\n"
      "We source Globally & Deliver Locally at your Doorstep.";

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fullText,
            maxLines: _expanded ? null : 10,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? "Read less" : "Read more", style: TextStyle(color: Color(0xff185794)),),
            ),
          ),
        ],
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
}
class Draft2InformationCard extends StatefulWidget {
  const Draft2InformationCard({super.key});

  @override
  State<Draft2InformationCard> createState() => _Draft2InformationCardState();
}

class _Draft2InformationCardState extends State<Draft2InformationCard> {
  bool _expanded = false;

  static const String _fullText =
      // "Bringing Essential Medicines to You—Seamlessly and Legally\n\n"
      "Looking for life-saving medicines that aren’t available in India? We’ve got you covered. "
      "With 100% legal process and verified sources, we ensure a hassle-free import process to deliver your medicine straight to your doorstep.\n\n"
      "Here’s how we make it simple for you:\n"
      "✅ Global sourcing, local delivery: We find the medicine you need and deliver it safely.\n"
      "✅ Fully compliant with regulations: We handle all licenses, paperwork, and logistics.\n"
      "✅ Zero facilitation charges: You pay only for the medicine and shipment at actual costs.\n"
      "✅ Transparent process: All payments and documents are accounted for.\n"
      "✅ Timely delivery: Your medicine arrives within 14 to 16 working days (excluding Saturdays and Sundays) from the date of payment.\n"
      "✅ Trusted expertise: 8 years of unmatched service in importing essential medicines and 35+ years of experience in the field of pharmaceuticals.\n\n"
      "✅ Here’s what we want from you:\n"
      "• Prescription mentioning patient’s name, medicine name with strength and dosage with treating Doctor’s stamp & registration number of the Doctor in the doctor’s letterhead.\n"
      "• Patient’s Aadhar ID.\n"
      "• Attender’s Aadhar ID (can be anyone like relatives, caretakers etc.).\n"
      "• One Email ID and Mobile Number accessible by the patient or their attender for OTP. (used for filing application for import license).\n"
      "• CDEC certificate signed by a government doctor (can be arranged by us for a fee)\n\n"
      "✅ Timelines:\n"
      "License Application Process – 2 to 3 working days\n"
      "Shipment process – 14 to 16 working days from the date of wire transfer to the supplier outside India & providing us the acknowledgement of the transfer.\n\n"
      "✅ Points to note:\n"
      "The lead time provided is very stringent and cannot be expedited as it involves many participants like the Government offices that approve the license, the customs offices that clears the import, and the shipping process through air cargo. "
      "Also, the suppliers abroad have a standard process which they follow and are bound by the local laws.\n"
      "We assure that every effort will be taken at our end to supply the medicine within the stipulated timeline, subject to any extreme situations which may lead to certain delays. "
      "We do want to convey that such occurrences are very rare and most of the shipments we deliver are generally on time.\n"
      "The actual invoice of the medicine along with the customs bill of entry will be provided within 10 days from the time of delivery of medicine.\n\n"
      "Navigating legal approvals, customs, and air cargo can be complex, but our proven track record ensures that your health is our priority. "
      "We have a streamlined process handled by experts, so you get the treatment you need, stress-free & on time.\n\n"
      "“We source Globally - deliver locally”\n"
      "“Right Thing the Right Way”";

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fullText,
            maxLines: _expanded ? null : 10,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? "Read less" : "Read more",style: TextStyle(color: Color(0xff185794)),),
            ),
          ),
        ],
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
}
class VenkataramanInformationCard extends StatefulWidget {
  const VenkataramanInformationCard({super.key});

  @override
  State<VenkataramanInformationCard> createState() => _VenkataramanInformationCardState();
}

class _VenkataramanInformationCardState extends State<VenkataramanInformationCard> {
  bool _expanded = false;

  static const String _fullText =
      "An Alumni of IIM Lucknow and a certified member of Independent Director's Databank IICA, under the Aegis of Ministry of Corporate Affairs, Government of India. "
      "Over 35 years of experience in handling specialty range of products in pharmaceutical industry, he has worked in mid-level management in Pharmaceutical companies. "
      "A dynamic professional, V. Venkataraman, has worked in Leather Industry – Coromendel Leathers, Shipping Industry – Greenways Shipping and Pharma Industry – Unichem Labs, Fulford, MSD. "
      "With a track record for delivering exceptional customer service, he has significant experience in handling patients. "
      "Ensuring ethics, moral values and business integrity at all levels, he is exceptionally well organized, self-motivated, creative and intuitive.";

  static const String _phoneNumber = "+919500069255";

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/venkataraman_pharma_five.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "V. Venkataraman",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Director",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final Uri phoneUri = Uri(scheme: 'tel', path: _phoneNumber);
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        }
                      },
                      child: Text(
                        _phoneNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            _fullText,
            maxLines: _expanded ? null : 5,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? "Read less" : "Read more",style: TextStyle(color: Color(0xff185794))),
            ),
          ),
        ],
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
}
class DilliBabuInformationCard extends StatefulWidget {
  const DilliBabuInformationCard({super.key});

  @override
  State<DilliBabuInformationCard> createState() => _DilliBabuInformationCardState();
}

class _DilliBabuInformationCardState extends State<DilliBabuInformationCard> {
  bool _expanded = false;

  static const String _fullText =
      "A science graduate with a diploma in Pharmacy, with over 25 years of experience in Patient service. "
      "A go-getter and committed professional, he has worked in leading pharmaceutical companies. "
      "Macleods, Intas, Ranbaxy, Merck & Eisai. "
      "He’s a dynamic professional with unmatched zeal and passion for patient care & customer service. "
      "Exceptionally well organised and committed.";

  static const String _phoneNumber = "+919841829603";

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/dilli_babu_pharma_five.png', // Update the path to your actual image asset
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "S. Dilli Babu",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Director", // Adjust title if necessary
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final Uri phoneUri = Uri(scheme: 'tel', path: _phoneNumber);
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        }
                      },
                      child: Text(
                        _phoneNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _fullText,
            maxLines: _expanded ? null : 5,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? "Read less" : "Read more",
                style: const TextStyle(color: Color(0xff185794)),
              ),
            ),
          ),
        ],
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
}
class SreekanthInformationCard extends StatefulWidget {
  const SreekanthInformationCard({super.key});

  @override
  State<SreekanthInformationCard> createState() => _SreekanthInformationCardState();
}

class _SreekanthInformationCardState extends State<SreekanthInformationCard> {
  bool _expanded = false;

  static const String _fullText =
      "A dynamic leader with more than 35 years of experience in pharmaceutical business, specializing exclusively in the Oncology segment in top management roles for more than two decades. "
      "Been instrumental in launching many blockbuster molecules in the field of Oncology with reputed multinational companies, such as Merck, Roche, as a national head and spearheaded the launch of an Oncology company based out of Japan in India. "
      "Passionate in providing an end-to-end solution to cancer patients and believes in quality healthcare for all.";

  static const String _phoneNumber = "+919176655641";

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/sreekanth_pharma_five.png',
                width: 100,
                height: 120,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 42),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "C.Sreekanth",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Director", // Adjust title if necessary
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final Uri phoneUri = Uri(scheme: 'tel', path: _phoneNumber);
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        }
                      },
                      child: Text(
                        _phoneNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _fullText,
            maxLines: _expanded ? null : 5,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? "Read less" : "Read more",
                style: const TextStyle(color: Color(0xff185794)),
              ),
            ),
          ),
        ],
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
}

class RandipInformationCard extends StatefulWidget {
  const RandipInformationCard({super.key});

  @override
  State<RandipInformationCard> createState() => _RandipInformationCardState();
}

class _RandipInformationCardState extends State<RandipInformationCard> {
  bool _expanded = false;

  static const String _fullText =
      "Veteran Speciality Pharma sales and marketing executive with 3 decades in the industry worked with many renowned pharmaceutical giants."
      "currently helping patients to obtain overseas medicines with proper documentations for prescription drugs thorough Name patient Import.patient friendly and has an exceptional track record of customer service.";

  static const String _phoneNumber = "+919836456611";

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/randip_sanyal.jpeg',
                width: 100,
                height: 120,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 42),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Randip sanyal",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Director \n(For East Zone only)", // Adjust title if necessary
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final Uri phoneUri = Uri(scheme: 'tel', path: _phoneNumber);
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        }
                      },
                      child: Text(
                        _phoneNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _fullText,
            maxLines: _expanded ? null : 5,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? "Read less" : "Read more",
                style: const TextStyle(color: Color(0xff185794)),
              ),
            ),
          ),
        ],
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
}