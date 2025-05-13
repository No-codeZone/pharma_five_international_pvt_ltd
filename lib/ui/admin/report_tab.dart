import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../helper/shared_preferences.dart';
import '../../model/login_session_model.dart';
import '../../model/product_search_logs_model.dart';
import '../../service/api_service.dart';
import '../login_screen.dart';

class ReportTab extends StatefulWidget {
  final VoidCallback? onLogout;

  const ReportTab({Key? key, this.onLogout}) : super(key: key);

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  Future<LoginSessionModel>? _futureSessions;
  final ApiService _apiService = ApiService();
  int _touchedIndex = -1;
  List<ProductSearchLogs> _searchLogs = [];

  @override
  void initState() {
    super.initState();
    _futureSessions = _fetchLoginSessions();
    _loadSearchLogs();
    _checkLoginStatus();
    debugPrintResponse();
  }

  Future<void> _loadSearchLogs() async {
    try {
      final logs = await _apiService.fetchSearchLogs();
      print("Fetched ${logs.length} search logs");
      for (final log in logs) {
        print("Log: ${log.search} on ${log.createdDatetime}");
      }
      setState(() {
        _searchLogs = logs;
      });
    } catch (e) {
      print("Error loading search logs: $e");
    }
  }

  Future<LoginSessionModel> _fetchLoginSessions() async {
    try {
      final result = await _apiService.fetchLoginSessions();
      // Debug prints
      print("Sessions count: ${result.sessions?.length ?? 0}");
      print("Total count: ${result.totalCount}");
      return result;
    } catch (e) {
      print("Error fetching sessions: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header Row with Logo and Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Image.asset(
                    "assets/images/logo_pf.png",
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                const Text(
                  "Report",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  tooltip: 'Logout',
                  onPressed: _showLogoutDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content based on FutureBuilder
            Flexible(
              fit: FlexFit.loose,
              child: FutureBuilder<LoginSessionModel>(
                future: _futureSessions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Error: ${snapshot.error}"),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _futureSessions = _fetchLoginSessions();
                                });
                              },
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data?.sessions == null) {
                    return const Center(child: Text("No session data available."));
                  }

                  final sessions = snapshot.data!.sessions!;
                  if (sessions.isEmpty) {
                    return const Center(child: Text("No sessions found."));
                  }

                  final totalSessions = sessions.length;
                  final activeSessions = sessions.where((s) => s.active == true).length;
                  final inactiveSessions = totalSessions - activeSessions;
                  final avgDuration = _calculateAvgDuration(sessions);

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _buildMetricCard("Total Sessions", totalSessions.toString()),
                                _buildMetricCard("Active Sessions", activeSessions.toString()),
                                _buildMetricCard("Inactive Sessions", inactiveSessions.toString()),
                                _buildMetricCard("Avg Duration", avgDuration),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sessions by Day Chart - Accordion
                          ExpansionTile(
                            initiallyExpanded: true,
                            title: const Text("Sessions by Day"),
                            children: [
                              _buildSessionsBarChart(sessions),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Search Logs Chart - Accordion
                          ExpansionTile(
                            initiallyExpanded: true,
                            title: const Text("Search Counts by Product"),
                            children: [
                              _buildSearchLogChartFromData(_searchLogs),
                            ],
                          ),

                          const SizedBox(height: 16),

                          const Text("Recent Sessions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),

                          ListView.builder(
                            itemCount: sessions.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              return Card(
                                color: Colors.white,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xff185794),
                                    child: Text("${index + 1}", style: const TextStyle(color: Colors.white)),
                                  ),
                                  title: Text("${session.name ?? 'Unknown'} (${session.email ?? 'No email'})",
                                      style: const TextStyle(color: Color(0xff185794), fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Session ID: ${session.sessionId ?? 'N/A'}"),
                                      Text("Login: ${session.loginTime ?? 'Unknown'}"),
                                      Text("Logout: ${session.logoutTime ?? 'N/A'}"),
                                      Text(
                                        "Status: ${session.active == true ? 'Active' : 'Inactive'}",
                                        style: TextStyle(
                                          color: session.active == true ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMetricCard(String title, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Color(0xff185794))),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSearchLogChartFromData(List<ProductSearchLogs> logs) {
    final Map<String, int> counts = {};

    for (var log in logs) {
      final name = log.search?.trim();
      if (name != null && name.isNotEmpty && name != "NA") {
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("No valid product search data available."),
      );
    }

    final sortedKeys = counts.keys.toList();
    final maxY = counts.values.reduce((a, b) => a > b ? a : b).toDouble();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: sortedKeys.length * 80, // Adjust width based on bar count
            height: 240,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(sortedKeys.length, (index) {
                  final key = sortedKeys[index];
                  final value = counts[key]!;
                  final isTouched = index == _touchedIndex;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value.toDouble(),
                        width: isTouched ? 24 : 18,
                        color: isTouched ? const Color(0xff185794) : const Color(0xff4a90e2),
                        borderRadius: BorderRadius.circular(8),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY + 1,
                          color: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  );
                }),
                maxY: maxY + 1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final product = sortedKeys[group.x.toInt()];
                      return BarTooltipItem(
                        '$product\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} search(es)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex = response?.spot?.touchedBarGroupIndex ?? -1;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedKeys.length) {
                          final label = sortedKeys[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Transform.rotate(
                              angle: -0.7,
                              child: Text(
                                label.length > 8 ? '${label.substring(0, 8)}...' : label,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _calculateAvgDuration(List<Sessions> sessions) {
    final durations = sessions
        .where((s) => s.loginTime != null && s.logoutTime != null)
        .map((s) {
      try {
        final start = DateTime.parse(s.loginTime!);
        final end = DateTime.parse(s.logoutTime!);
        return end.difference(start).inSeconds;
      } catch (e) {
        print("Error calculating duration: $e");
        return 0;
      }
    }).toList();

    if (durations.isEmpty) return "00:00:00";
    final avgSeconds = durations.reduce((a, b) => a + b) ~/ durations.length;
    final duration = Duration(seconds: avgSeconds);
    return duration.toString().split('.').first;
  }

  Future<void> debugPrintResponse() async {
    try {
      final url = Uri.parse("${_apiService.baseUrl}${_apiService.loginSessionAPI}");
      final response = await http.get(url);

      print("=== DEBUG RESPONSE ===");
      print("Status Code: ${response.statusCode}");
      print("Raw Response: ${response.body}");

      try {
        final json = jsonDecode(response.body);
        print("JSON Keys: ${json is Map ? json.keys.toList() : 'Not a Map'}");
        if (json is Map && json['sessions'] != null) {
          print("Sessions found, count: ${json['sessions'] is List ? json['sessions'].length : 'Not a List'}");
        } else if (json is List) {
          print("Response is a List with ${json.length} items");
          if (json.isNotEmpty && json.first is Map) {
            print("First item keys: ${json.first.keys.toList()}");
          }
        }
      } catch (e) {
        print("Error parsing JSON: $e");
      }
      print("=== END DEBUG ===");
    } catch (e) {
      print("Debug request failed: $e");
    }
  }

  Widget _buildSessionsBarChart(List<Sessions> sessions) {
    final Map<String, int> sessionCountByDate = {};

    for (var session in sessions) {
      if (session.loginTime != null) {
        final date = DateTime.parse(session.loginTime!).toLocal();
        final label = "May ${date.day}";
        sessionCountByDate[label] = (sessionCountByDate[label] ?? 0) + 1;
      }
    }

    final sortedKeys = sessionCountByDate.keys.toList()
      ..sort((a, b) => int.parse(a.split(" ")[1]).compareTo(int.parse(b.split(" ")[1])));

    final maxY = (sessionCountByDate.values.isNotEmpty
        ? sessionCountByDate.values.reduce((a, b) => a > b ? a : b)
        : 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sessions by Day",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      // tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      tooltipBorder: BorderSide(color: Colors.white, width: 1),
                      // tooltipBgColor: Colors.blueAccent.shade100, // Use only if supported in your version
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${sortedKeys[group.x.toInt()]}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${rod.toY.toInt()} session(s)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        if (response != null &&
                            response.spot != null &&
                            event.isInterestedForInteractions) {
                          _touchedIndex = response.spot!.touchedBarGroupIndex;
                        } else {
                          _touchedIndex = -1;
                        }
                      });
                    },
                  ),
                  maxY: maxY + 1,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, _) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedKeys.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                sortedKeys[index],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(sortedKeys.length, (index) {
                    final key = sortedKeys[index];
                    final value = sessionCountByDate[key] ?? 0;
                    final isTouched = index == _touchedIndex;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value.toDouble(),
                          width: isTouched ? 24 : 18,
                          color: isTouched ? const Color(0xff185794) : const Color(0xff4a90e2),
                          borderRadius: BorderRadius.circular(8),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY + 1,
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ],
                    );
                  }),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                ),
                swapAnimationDuration: const Duration(milliseconds: 500),
                swapAnimationCurve: Curves.easeOutQuart,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
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
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      final email = await SharedPreferenceHelper.getUserEmail();
      if (email != null && email.isNotEmpty) {
        await _apiService.logoutUser(userEmail: email);
      }

      await SharedPreferenceHelper.clearSession();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      debugPrint('Logout failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }
  Future<void> _checkLoginStatus() async {
    try {
      bool isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
      String? userType = await SharedPreferenceHelper.getUserType();

      if (!isLoggedIn || userType != 'admin') {
        await SharedPreferenceHelper.clearSession(); // Auto clear broken state
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error checking login status: $e');
      // Fallback to login screen in case of any error
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}