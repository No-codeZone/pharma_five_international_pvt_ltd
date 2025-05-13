import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  bool _isCheckingConnectivity = false;

  @override
  void initState() {
    super.initState();
    _initConnectivityMonitoring();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initConnectivityMonitoring() async {
    // Initial connectivity check
    await _checkInternetStatus();

    // Set up listener for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((_) {
      _checkInternetStatus();
    });
  }

  Future<bool> _checkInternetStatus() async {
    if (_isCheckingConnectivity) return _isConnected;

    setState(() => _isCheckingConnectivity = true);

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final isNowConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (mounted) {
        setState(() {
          _isConnected = isNowConnected;
          _isCheckingConnectivity = false;
        });

        // Show toast on connectivity change
        if (_isConnected) {
          _showToast("Internet connection restored", isError: false);
          _fetchUsers();
        } else {
          _showToast("No internet connection", isError: true);
        }
      }
      return isNowConnected;
    } on SocketException catch (_) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isCheckingConnectivity = false;
        });
      }
      return false;
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isCheckingConnectivity = false;
        });
      }
      return false;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isCheckingConnectivity = false;
        });
      }
      return false;
    }
  }

  Widget _buildNoInternetWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            "assets/animations/internet.json",
            width: 250,
            height: 250,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          IconButton(
            onPressed: () async {
              final connected = await _checkInternetStatus();
              if (connected) await _fetchUsers();
            },
            icon: Icon(Icons.refresh, color: Color(0xff185794), size: 40),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUsers() async {
    if (!_isConnected) {
      _showToast("No internet connection. Please check your network", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _usersList = [];
    });

    try {
      final response = await _apiService.getUsers(
        page: widget.currentPage,
        size: 10,
        status: selectedStatus,
      ).timeout(const Duration(seconds: 15));

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
        _showToast("Network error. Please check your connection", isError: true);
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showToast("Request timed out. Please try again", isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _usersList = [];
        });
        _showToast("Failed to load users", isError: true);
      }
    }
  }

  Future<void> _retryConnection() async {
    setState(() => _isLoading = true);
    final connected = await _checkInternetStatus();
    if (connected) await _fetchUsers();
    setState(() => _isLoading = false);
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      gravity: ToastGravity.TOP,
    );
  }

  void _showApproveDialog(String email) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            content: const Text('Do you want to approve the request?', textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: _isUpdating ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isUpdating || !_isConnected
                    ? null
                    : () async {
                  setStateDialog(() => _isUpdating = true);
                  try {
                    widget.onStatusUpdate(email, 'Active');
                    widget.onPageChange(0);
                    await Future.delayed(const Duration(milliseconds: 300));
                    await _fetchUsers();
                    Navigator.pop(context);
                    _showToast("Status updated to Approved");
                  } catch (e) {
                    _showToast("Failed to update status", isError: true);
                  } finally {
                    setState(() => _isUpdating = false);
                  }
                },
                child: _isUpdating
                    ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Yes, Approve'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showRejectDialog(String email) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            content: const Text('Do you want to reject the request?', textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: _isUpdating ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isUpdating || !_isConnected
                    ? null
                    : () async {
                  setStateDialog(() => _isUpdating = true);
                  try {
                    widget.onStatusUpdate(email, 'Reject');
                    widget.onPageChange(0);
                    await Future.delayed(const Duration(milliseconds: 300));
                    await _fetchUsers();
                    Navigator.pop(context);
                    _showToast("Status updated to Rejected");
                  } catch (e) {
                    _showToast("Failed to update status", isError: true);
                  } finally {
                    setState(() => _isUpdating = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: _isUpdating
                    ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Yes, Reject'),
              ),
            ],
          );
        });
      },
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
    if (_usersList.isEmpty || !_isConnected) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 10,
        alignment: WrapAlignment.center,
        children: List.generate(totalPages, (index) {
          final bool isSelected = index == widget.currentPage;
          return InkWell(
            onTap: () => widget.onPageChange(index),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xff185794) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xff185794),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading users...', style: TextStyle(color: Colors.grey))
            ],
          )
      );
    }

    if (!_isConnected) {
      return _buildNoInternetWidget();
    }

    if (_usersList.isEmpty && _isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset("assets/animations/no_data_found.json", width: 200),
            const SizedBox(height: 12),
            Text('No ${selectedStatus.toLowerCase()} users found', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            IconButton(
              onPressed: _fetchUsers,
              icon: const Icon(Icons.refresh),
              style: ElevatedButton.styleFrom(
                foregroundColor: Color(0xff185794),
              ),
            ),
          ],
        ),
      );
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
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _usersList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _usersList[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 30, child: Text('${(widget.currentPage * 10) + index + 1}.')),
                      Expanded(child: Text(item['name'] ?? 'User')),
                      Expanded(flex: 2, child: Text(item['organisationName'] ?? 'Organization')),
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
      decoration: BoxDecoration(
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

          // User List
          Expanded(child: _buildUserList()),

          // Pagination
          _buildPagination(),
        ],
      ),
    );
  }
}