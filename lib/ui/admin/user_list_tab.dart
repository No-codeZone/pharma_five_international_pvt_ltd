import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:pharma_five/service/api_service.dart';

class UserListTab extends StatefulWidget {
  final int currentPage;
  final Function(String email, String newStatus) onStatusUpdate;
  final Function(int newPage) onPageChange;

  const UserListTab({
    Key? key,
    required this.currentPage,
    required this.onStatusUpdate,
    required this.onPageChange,
  }) : super(key: key);

  @override
  State<UserListTab> createState() => _UserListTabState();
}

class _UserListTabState extends State<UserListTab> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isConnected = true;
  bool _isUpdating = false;
  int totalPages = 1;
  List<dynamic> _usersList = [];
  String selectedStatus = 'Pending';

  // Connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivityMonitoring();
    _fetchUsers();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initConnectivityMonitoring() async {
    await _checkConnectivity();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      for (var result in results) {
        _handleConnectivityChange(result);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();

      for (var result in results) {
        _handleConnectivityChange(result); // ✅ now passing one at a time
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnected = false);
      }
    }
  }

  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    final bool wasConnected = _isConnected;
    final bool isNowConnected = result != ConnectivityResult.none;

    // Only proceed if there's an actual change in connectivity status
    if (wasConnected != isNowConnected) {
      // If connectivity was restored
      if (isNowConnected && !wasConnected) {
        // Update UI first to indicate restored connectivity
        if (mounted) {
          setState(() => _isConnected = true);
          _showToast("Internet connection restored", isError: false);
        }

        // Then fetch data with a short delay to allow network to stabilize
        await Future.delayed(const Duration(milliseconds: 500));
        await _fetchUsers();
      }
      // If connectivity was lost
      else if (!isNowConnected && wasConnected) {
        if (mounted) {
          setState(() => _isConnected = false);
          _showToast("No internet connection", isError: true);
        }
      }
    }
  }

  Widget _buildNoInternetWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            "assets/animations/internet.json",
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          // const SizedBox(height: 8),
          // const Text(
          //   'Reconnecting automatically...',
          //   style: TextStyle(
          //     fontSize: 14,
          //     color: Colors.grey,
          //   ),
          // ),
        ],
      ),
    );
  }

  Future<void> _fetchUsers() async {
    if (!_isConnected) {
      return; // Don't attempt to fetch if offline
    }

    setState(() {
      _isLoading = true;
      // Don't clear usersList here to avoid flickering when refreshing
    });

    try {
      final response = await _apiService.getUsers(
        page: widget.currentPage,
        size: 10,
        status: selectedStatus,
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _usersList = response['content'] ?? [];
          totalPages = response['totalPages'] ?? 1;
          _isLoading = false;
        });
      }
    } on SocketException catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isConnected = false;
        });
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showToast("Request timed out", isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showToast("Failed to load users", isError: true);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isError ? Colors.red : Color(0xff185794),
      textColor: Colors.white,
      gravity: ToastGravity.TOP,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xff185794)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedStatus,
        underline: Container(),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff185794)),
        onChanged: !_isConnected
            ? null  // Disable when offline
            : (String? newValue) {
          if (newValue != null) {
            setState(() => selectedStatus = newValue);
            widget.onPageChange(0);
            _fetchUsers();
          }
        },
        items: ['Pending', 'Approved', 'Rejected'].map((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusLabel(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _editIcon(VoidCallback onTap) {
    return InkWell(
      onTap: _isConnected ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: _isConnected ? Colors.grey.shade300 : Colors.grey.shade200,
            shape: BoxShape.circle
        ),
        child: Icon(
            Icons.edit,
            color: _isConnected ? Colors.black87 : Colors.grey,
            size: 14
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: _isConnected ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: _isConnected ? color : Colors.grey,
            shape: BoxShape.circle
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusControls(dynamic status, String email) {
    String statusStr = (status ?? '').toString().toLowerCase();

    switch (statusStr) {
      case 'pending':
        return Row(
          children: [
            _circleIcon(Icons.close, Colors.red, () => _showRejectDialog(email)),
            const SizedBox(width: 8),
            _circleIcon(Icons.check, Colors.green, () => _showApproveDialog(email)),
          ],
        );
      case 'approved':
      case 'active':
        return Row(
          children: [
            _statusLabel('Approved', Colors.green),
            const SizedBox(width: 8),
            _editIcon(() => _showRejectDialog(email)),
          ],
        );
      case 'rejected':
      case 'reject':
        return Row(
          children: [
            _statusLabel('Rejected', Colors.red),
            const SizedBox(width: 8),
            _editIcon(() => _showApproveDialog(email)),
          ],
        );
      default:
        return _statusLabel('Pending', Colors.orange);
    }
  }

  Widget _buildPagination() {
    if (totalPages <= 1) return const SizedBox.shrink();

    const int maxPagesToShow = 7; // ✅ Show up to 7 page buttons
    final double buttonSize = 30; // ✅ Smaller button
    final double fontSize = 14;   // ✅ Smaller font

    int startPage = max(0, min(widget.currentPage - (maxPagesToShow ~/ 2), totalPages - maxPagesToShow));
    int endPage = min(startPage + maxPagesToShow - 1, totalPages - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ← Previous button
          if (widget.currentPage > 0)
            _buildArrowButton(
              isNext: false,
              enabled: _isConnected,
              onTap: () => widget.onPageChange(widget.currentPage - 1),
              buttonSize: buttonSize,
              fontSize: fontSize,
            ),

          // Page number buttons
          ...List.generate(endPage - startPage + 1, (index) {
            final int pageNumber = startPage + index;
            final bool isSelected = pageNumber == widget.currentPage;

            return InkWell(
              onTap: _isConnected && !isSelected ? () => widget.onPageChange(pageNumber) : null,
              borderRadius: BorderRadius.circular(6),
              splashColor: Colors.grey.shade300,
              child: Container(
                width: buttonSize,
                height: buttonSize,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: isSelected
                    ? BoxDecoration(
                  color: const Color(0xff185794).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                )
                    : null,
                child: Text(
                  '${pageNumber + 1}',
                  style: TextStyle(
                    color: _isConnected ? const Color(0xff185794) : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: fontSize,
                  ),
                ),
              ),
            );
          }),

          // → Next button
          if (widget.currentPage < totalPages - 1)
            _buildArrowButton(
              isNext: true,
              enabled: _isConnected,
              onTap: () => widget.onPageChange(widget.currentPage + 1),
              buttonSize: buttonSize,
              fontSize: fontSize,
            ),
        ],
      ),
    );
  }

  Widget _buildArrowButton({
    required bool isNext,
    required bool enabled,
    required VoidCallback onTap,
    required double buttonSize,
    required double fontSize,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      splashColor: Colors.grey.shade300,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        alignment: Alignment.center,
        child: Icon(
          isNext ? Icons.chevron_right : Icons.chevron_left,
          color: enabled ? const Color(0xff185794) : Colors.grey,
          size: fontSize + 4,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset("assets/animations/no_data_found.json", width: 180),
          const SizedBox(height: 12),
          Text('No ${selectedStatus.toLowerCase()} users found',
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xff185794)),
            SizedBox(height: 16),
            Text('Loading users...', style: TextStyle(color: Colors.grey))
          ],
        )
    );
  }

  Widget _buildUserList() {
    if (!_isConnected) {
      return _buildNoInternetWidget();
    }

    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_usersList.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('$selectedStatus Lists',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchUsers,
            color: const Color(0xff185794),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _usersList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _usersList[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Serial number
                      Container(
                        width: 30,
                        child: Text(
                          '${(widget.currentPage * 10) + index + 1}.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                      // User and organization information
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User name
                            Text(
                              item['name'] ?? 'User',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Organization name
                            Text(
                              item['organisationName'] ?? 'Organization',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Status controls
                      _buildStatusControls(item['status'], item['email']),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth < 500 ? 60.0 : 80.0;

    return Container(
      decoration: const BoxDecoration(
          color: Colors.white
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/images/logo_pf.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.language, size: logoSize * 0.6, color: Colors.blue),
                ),

                const Spacer(),

                // Center Title
                const Text(
                  "Users",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const Spacer(),

                // Status Dropdown
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildStatusDropdown(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // User List with connectivity status indicator
          if (!_isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.orange.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Waiting for connection...',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(child: _buildUserList()),

          // Pagination
          _buildPagination(),
        ],
      ),
    );
  }

  void _showApproveDialog(String email) {
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
            'Do you want to approve the request?',
            textAlign: TextAlign.center,
          ),
          actions: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      side: const BorderSide(color: Color(0xff262A88)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text('Cancel'),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const Expanded(
                    child: SizedBox(width: 80)),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff185794),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text('Yes, Approve'),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateStatusByEmail(email, 'Active');
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(String email) {
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
            'Do you want to reject the request?',
            textAlign: TextAlign.center,
          ),
          actions: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      side: const BorderSide(color: Color(0xff262A88)),
                    ),
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const Expanded(
                    child: SizedBox(width: 80)),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff185794),
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)))),
                    child: const Text('Yes, Reject'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateStatusByEmail(email, 'Reject');
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatusByEmail(String email, String newStatus) async {
    if (!_isConnected) {
      _showToast("No internet connection", isError: true);
      return;
    }

    // Show loading indicator
    setState(() {
      _isUpdating = true;
    });

    final url = Uri.parse("${_apiService.baseUrl}/update-status");
    final requestBody = {
      "email": email,
      "status": newStatus, // "Active" or "Reject"
    };

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          _showToast("Status updated successfully", isError: false);

          // Call the parent widget's callback only once
          widget.onStatusUpdate(email, newStatus);

          // Determine if we need to switch tabs based on the new status
          if (newStatus == 'Active' && selectedStatus != 'Approved') {
            // User was approved, switch to Approved tab
            setState(() {
              selectedStatus = 'Approved';
              widget.onPageChange(0); // Reset to first page of new tab
            });
            // The fetch will happen via didUpdateWidget when the page changes
          } else if (newStatus == 'Reject' && selectedStatus != 'Rejected') {
            // User was rejected, switch to Rejected tab
            setState(() {
              selectedStatus = 'Rejected';
              widget.onPageChange(0); // Reset to first page of new tab
            });
            // The fetch will happen via didUpdateWidget when the page changes
          } else {
            // If staying on same tab, we need to refresh the data
            await _fetchUsers();
          }
        } else {
          _showToast("Status update failed", isError: true);
        }
      } else {
        _showToast("Status update failed (${response.statusCode})", isError: true);
      }
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        setState(() => _isConnected = false);
        _showToast("No internet connection", isError: true);
      } else {
        _showToast("Error updating status", isError: true);
      }
    } finally {
      // Hide loading indicator
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  void didUpdateWidget(UserListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the page has changed, fetch new users
    if (oldWidget.currentPage != widget.currentPage) {
      _fetchUsers();
    }
  }
}