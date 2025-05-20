import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import '../../helper/communication_handler.dart';
import '../../helper/file_downloader_helper.dart';
import '../../service/api_service.dart';


enum EnquiryStatus { newEnquiry, viewed }
class EnquiryItem {
  final int id;
  final String productName;
  final String userName;
  final EnquiryStatus status;

  EnquiryItem({
    required this.id,
    required this.productName,
    required this.userName,
    required this.status,
  });
}
/// A tab that displays a single page of Enquiries
/// and lets the parent manage currentPage / onPageChange.
class EnquiryTab extends StatefulWidget {
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChange;

  const EnquiryTab({
    Key? key,
    required this.currentPage,
    required this.onPageChange,
    this.pageSize = 10,
  }) : super(key: key);

  @override
  _EnquiryTabState createState() => _EnquiryTabState();
}
class _EnquiryTabState extends State<EnquiryTab> {
  bool _isLoading = false;
  int _totalPages = 1;
  List<EnquiryItem> _items = [];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectionSubscription;
  bool _isConnected = true;
  bool _lastConnectionStatus = true;

  @override
  void initState() {
    super.initState();
    _monitorInternetConnectivity();
    // _loadPage(widget.currentPage);
  }

  void _monitorInternetConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    final initialConnected = results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);

    _isConnected = initialConnected;
    _lastConnectionStatus = initialConnected;

    if (initialConnected) {
      _loadPage(widget.currentPage);
    }

    _connectionSubscription =
        _connectivity.onConnectivityChanged.listen((results) async {
      final connected = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);

      if (_lastConnectionStatus != connected) {
        setState(() {
          _isConnected = connected;
          _lastConnectionStatus = connected;
        });

        if (connected) {
          // Fluttertoast.showToast(
          //   msg: "Internet connection restored",
          //   backgroundColor: const Color(0xff185794),
          // );
          await Future.delayed(
              const Duration(milliseconds: 500)); // allow stabilization
          _loadPage(widget.currentPage);
        } else {
          // Fluttertoast.showToast(
          //   msg: "Internet connection lost",
          //   backgroundColor: Colors.red,
          // );
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant EnquiryTab old) {
    super.didUpdateWidget(old);
    // If parent changed the page, reload:
    if (old.currentPage != widget.currentPage) {
      _loadPage(widget.currentPage);
    }
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      _isLoading = true;
      _items = []; // 👈 clears list immediately to show blank white background
    });

    try {
      final resp = await ApiService().fetchAllEnquiries(
        index: page, // or page * pageSize if backend uses offset
        limit: widget.pageSize,
        // sortOrder: 'desc', // Add sort parameter to get latest enquiries first
      );

      final fetched = resp.data
              ?.map((d) => EnquiryItem(
                    id: d.id ?? 0,
                    productName: d.medicineName ?? '—',
                    userName: d.empName ?? '—',
                    status: d.status == 1
                        ? EnquiryStatus.newEnquiry
                        : EnquiryStatus.viewed,
                  ))
              .toList() ??
          [];

      final totalCount = resp.totalCount ?? fetched.length;
      setState(() {
        _items = fetched;
        _totalPages = (totalCount + widget.pageSize - 1) ~/ widget.pageSize;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading enquiries: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() => _loadPage(widget.currentPage);
  // Handle tap on phone number - direct without using url_launcher
  void _handlePhoneNumberTap(String? phoneNumber) {
    CommunicationHandler.makePhoneCall(context, phoneNumber);
  }
  // Handle tap on email - direct without using url_launcher
  void _handleEmailTap(String? email) {
    CommunicationHandler.sendEmail(context, email);
  }

  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return "N/A";

    try {
      final parsed = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy hh:mm a').format(parsed);
    } catch (e) {
      return "Invalid Date";
    }
  }

  Future<void> _downloadEnquiryExcelFile() async {
    const downloadUrl = "http://13.49.224.44:8080/api/enquiry/download";

    // ✅ Step 1: Check Internet
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi ||
          connectivityResult == ConnectivityResult.ethernet;

      if (!isConnected) {
        Fluttertoast.showToast(
          msg: "No internet connection",
          backgroundColor: Colors.red,
          gravity: ToastGravity.TOP
        );
        return;
      }

      // ✅ Step 2: Check Storage Permission
      final hasPermission = await FileDownloadHelper.requestStoragePermission(context);
      if (!hasPermission) return;

      // ✅ Step 3: Get Download Directory
      final directory = await FileDownloadHelper.getDownloadDirectory();
      if (directory == null) {
        Fluttertoast.showToast(
          msg: "Unable to access storage",
          backgroundColor: Colors.red,
        );
        return;
      }

      // ✅ Step 4: Download File
      final filename = "enquiry_list_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final downloadPath = "${directory.path}/$filename";
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        final file = File(downloadPath);
        await file.writeAsBytes(response.bodyBytes);
        await FileDownloadHelper.showFileDownloadSnackBar(context, downloadPath, Platform.isIOS);
      } else {
        Fluttertoast.showToast(
          msg: "Failed to download file: Status ${response.statusCode}",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      debugPrint("Enquiry download error: $e");
      Fluttertoast.showToast(
        msg: "Download failed: $e",
        backgroundColor: Colors.red,
      );
    }
  }


  Widget _buildInteractiveItem({
    required String label,
    required String? value,
    required IconData icon,
    bool isInteractive = true,
    VoidCallback? onTap,
  }) {
    final displayValue = (value == null || value.trim().isEmpty || value == "-") ? "N/A" : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: isInteractive ? onTap : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Color(0xff185794)),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110, // fixed label width for alignment
                    child: Text(
                      "$label:",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xff185794),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      displayValue!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isInteractive ? Colors.blue : Colors.black87,
                        decoration: isInteractive
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Styled viewEnquiry function based on logout dialog styling
  Future<void> _viewEnquiry(int id, String userName, String productName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xff185794))),
    );

    try {
      final resp = await ApiService().fetchEnquiryById(id);
      Navigator.pop(context); // remove loader

      final d = resp.data!;
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          backgroundColor: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Enquiry Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff185794),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      width: 40,
                      color: const Color(0xff185794).withOpacity(0.5),
                    ),
                    const SizedBox(height: 24), // Increased spacing

                    // Regular items
                    _buildInteractiveItem(
                      label: "Medicine Name",
                      value: productName,
                      icon: Icons.medication,
                      isInteractive: false,
                    ),
                    _buildInteractiveItem(
                      label: "Generic Name",
                      value: d.genericName,
                      icon: Icons.medication_outlined,
                      isInteractive: false,
                    ),
                    _buildInteractiveItem(
                      label: "User Name",
                      value: userName,
                      icon: Icons.person,
                      isInteractive: false,
                    ),

                    // Interactive items with actions
                    _buildInteractiveItem(
                      label: "Mobile",
                      value: d.mobileNumber,
                      icon: Icons.phone,
                      onTap: () => _handlePhoneNumberTap(d.mobileNumber ?? ""),
                    ),
                    _buildInteractiveItem(
                      label: "Email",
                      value: d.email,
                      icon: Icons.email,
                      onTap: () => _handleEmailTap(d.email ?? ""),
                    ),
                    _buildInteractiveItem(
                      label: "Organisation",
                      value: d.organisationName,
                      icon: Icons.business,
                      isInteractive: false,
                    ),
                    _buildInteractiveItem(
                      label: "Enquired",
                      // Changed from "Created" to "Enquired"
                      value: formatDateTime(d.createdDatetime),
                      icon: Icons.calendar_today,
                      isInteractive: false,
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _refresh();
                      },
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Close",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        // Increased vertical padding
                        backgroundColor: const Color(0xff185794),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Icon at Top
              Positioned(
                top: -28,
                left: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.info_outline,
                      size: 30, color: Color(0xff185794)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Error", style: TextStyle(color: Colors.red)),
          content: Text("Unable to load enquiry details: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPagination() {
    if (_items.length < widget.pageSize && widget.currentPage == 0) {
      return const SizedBox.shrink(); // Hide if no need to paginate
    }

    const int maxPagesToShow = 5;
    final double buttonSize = 30;
    final double fontSize = 14;

    int startPage = max(0, min(widget.currentPage - (maxPagesToShow ~/ 2), _totalPages - maxPagesToShow));
    int endPage = min(startPage + maxPagesToShow - 1, _totalPages - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ← Previous
          if (widget.currentPage > 0)
            _buildArrowButton(false, () => widget.onPageChange(widget.currentPage - 1), buttonSize, fontSize),

          // Page buttons
          ...List.generate(endPage - startPage + 1, (index) {
            final int pageNumber = startPage + index;
            final bool isSelected = pageNumber == widget.currentPage;
            return InkWell(
              onTap: isSelected ? null : () => widget.onPageChange(pageNumber),
              child: Container(
                width: buttonSize,
                height: buttonSize,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: isSelected
                    ? BoxDecoration(
                  color: const Color(0xff185794).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                )
                    : null,
                child: Text(
                  '${pageNumber + 1}',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: const Color(0xff185794),
                  ),
                ),
              ),
            );
          }),

          // → Next
          if (widget.currentPage < _totalPages - 1)
            _buildArrowButton(true, () => widget.onPageChange(widget.currentPage + 1), buttonSize, fontSize),
        ],
      ),
    );
  }

  Widget _buildArrowButton(bool isNext, VoidCallback onTap, double size, double fontSize) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Icon(
          isNext ? Icons.chevron_right : Icons.chevron_left,
          size: fontSize + 4,
          color: const Color(0xff185794),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Image.asset(
                          "assets/images/logo_pf.png",
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Enquiry",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child:
                        IconButton(
                          icon: Image.asset(
                            'assets/images/excel_icon.png',
                            height: 24,
                          ),
                          tooltip: 'Download Enquiry Excel',
                          onPressed: _downloadEnquiryExcelFile,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            buildTableHeader(),
            // List view + loader
            Expanded(
              child: Column(
                children: [
                  if (!_isConnected)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.orange.shade100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Waiting for connection...',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                    ),
                  Expanded(
                    child: !_isConnected
                        ? _buildNoInternetWidget()
                        : _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xff185794),
                                  strokeWidth: 3,
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _refresh,
                                color: const Color(0xff185794),
                                child: _items.isEmpty
                                    ? Center(
                                      child: ListView(
                                        children: [
                                          SizedBox(
                                            height: 180,
                                            width: 180,
                                            child: Lottie.asset(
                                                "assets/animations/no_data_found.json",
                                                width: 60),
                                          ),
                                          const SizedBox(height: 12),
                                          Center(
                                              child: Text(
                                                  "No enquiries found.")),
                                        ],
                                      ),
                                    )
                                    : ListView.builder(
                                        itemCount: _items.length,
                                        itemBuilder: (context, index) =>
                                            _buildEnquiryCard(
                                                _items[index], index),
                                      ),
                              ),
                  ),
                ],
              ),
            ),
            // Pagination
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildPagination(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryCard(EnquiryItem item, int index) {
    final isNew = item.status == EnquiryStatus.newEnquiry;
    final sideColor = isNew ? const Color(0xff185794) : Colors.grey;
    final bgColor = isNew ? Color(0xffeff4f8) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.0),
        // Increased vertical margin for better separation
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        // Increased vertical padding for better touch target
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isNew
              ? Border(
                  left: BorderSide(color: sideColor, width: 4),
                  top: BorderSide(color: sideColor, width: 1),
                  right: BorderSide(color: sideColor, width: 1),
                  bottom: BorderSide(color: sideColor, width: 1),
                )
              : Border(
                  left: BorderSide(color: sideColor, width: 4),
                ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Center(child: Text('${index + 1}')),
            ),
            Expanded(
              flex: 4,
              child: isNew
                  ? Text(
                      item.productName,
                      style: TextStyle(
                          fontWeight:
                              isNew ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                          color: Color(0xff185794)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      item.productName,
                      style: TextStyle(
                        fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            isNew
                ? Expanded(
                    flex: 3,
                    child: Text(
                      item.userName,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xff185794)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Expanded(
                    flex: 3,
                    child: Text(
                      item.userName,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            Expanded(
              flex: 2,
              child: IconButton(
                icon: Icon(
                  isNew ? Icons.visibility_off : Icons.visibility,
                  color: isNew ? const Color(0xff185794) : Colors.grey,
                  size: 24, // Increased size for better touch target
                ),
                padding: EdgeInsets.all(8.0),
                // Added padding for better touch target
                onPressed: () =>
                    _viewEnquiry(item.id, item.userName, item.productName),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, bottom: 5.0, right: 20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xff185794),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: const [
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'No.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: Text(
                    'Product name',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    'User name',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoInternetWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset("assets/animations/internet.json",
              width: 200, height: 200),
          const SizedBox(height: 16),
          const Text(
            'No Internet Connection',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }
}