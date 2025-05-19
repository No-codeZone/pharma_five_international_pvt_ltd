import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../helper/shared_preferences.dart';
import '../../model/login_session_model.dart';
import '../../model/producr_search_logs_model.dart';
import '../../model/product_search_logs_model.dart';
import '../../service/api_service.dart';
import '../login_screen.dart';

class ReportTab extends StatefulWidget {
  final VoidCallback? onLogout;

  const ReportTab({Key? key, this.onLogout}) : super(key: key);

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> with SingleTickerProviderStateMixin {
  Future<LoginSessionModel>? _futureSessions;
  final ApiService _apiService = ApiService();
  int _touchedIndex = -1;
  // List<ProductSearchLogs> _searchLogs = [];
  List<ProductSearchLogsModel> _searchLogs = [];
  String? _filteredDayLabel;
  List<Sessions> _filteredSessions = [];
  late TabController _tabController;
  bool _isLoading = true;

  // Scroll controllers for horizontal scrolling
  final ScrollController _sessionsScrollController = ScrollController();
  final ScrollController _searchesScrollController = ScrollController();

  // Theme colors
  final Color _primaryColor = const Color(0xff185794);
  final Color _accentColor = const Color(0xff4a90e2);
  final Color _backgroundColor = const Color(0xfff5f7fa);
  final Color _cardColor = Colors.white;
  final Color _textPrimaryColor = const Color(0xff2d3748);
  final Color _textSecondaryColor = const Color(0xff718096);

  int _selectedDayFilter = 7;
  final Map<String, int> _dayFilters = {
    "Last 7 days": 7,
    "Last 30 days": 30,
    "Last 60 days": 60,
    "Last 90 days": 90,
    "All": 9999,
  };

  /*@override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _checkLoginStatus();
  }*/

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _checkLoginStatus();

    // Add listener to load search logs when tab changes
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // Load search logs when search tab is selected
        _loadSearchLogs();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sessionsScrollController.dispose();
    _searchesScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Now only load sessions initially
      final sessionsFuture = _apiService.fetchAllLoginSessions();

      setState(() {
        _futureSessions = sessionsFuture;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _futureSessions = Future.error(e);
      });
      print("Error loading data: $e");
    }
  }

  Future<void> _loadSearchLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logsModels = await _apiService.fetchSearchLogsByDay(days: _selectedDayFilter);

      // Properly use count and search
      final logs = logsModels.map((model) {
        return ProductSearchLogsModel(
          count: model.count,     // ✅ FIXED: use actual count
          search: model.search,
        );
      }).toList();

      setState(() {
        _searchLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading search logs: $e");
      setState(() {
        _searchLogs = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to load search logs. Please try again.'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        "Loading report data...",
                        style: TextStyle(
                            color: _textSecondaryColor,
                            fontWeight: FontWeight.w500
                        ),
                      )
                    ],
                  ),
                ),
              )
            else
              Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // App Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Image.asset(
                "assets/images/logo_pf.png",
                height: 60,
                fit: BoxFit.contain,
              ),
            ),

            // Expanded widget to center the "Analytics" text
            Expanded(
              child: Center(
                child: const Text(
                  "Analytics",
                  style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: _primaryColor),
              tooltip: 'Logout',
              onPressed: _showLogoutDialog,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }


  Widget _buildContent() {
    return FutureBuilder<LoginSessionModel>(
      future: _futureSessions,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Unable to load report data",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Error: ${snapshot.error}",
                    style: TextStyle(color: _textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() {
                        _futureSessions = _apiService.fetchAllLoginSessions();
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data?.sessions == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 48, color: _accentColor),
                const SizedBox(height: 16),
                Text(
                  "No session data available",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        final sessions = snapshot.data!.sessions!;
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 48, color: _accentColor),
                const SizedBox(height: 16),
                Text(
                  "No sessions found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        final allSessions = snapshot.data!.sessions ?? [];
        final totalSessions = snapshot.data!.totalCount ?? allSessions.length;
        final displayedSessions = _filteredDayLabel != null ? _filteredSessions : allSessions;
        final activeSessions = displayedSessions.where((s) => s.active == true).length;
        final inactiveSessions = displayedSessions.length - activeSessions;
        final avgDuration = _calculateAvgDuration(displayedSessions);

        return Column(
          children: [
            _buildFilterBar(allSessions),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    _buildMetricsGrid(displayedSessions, activeSessions, inactiveSessions, avgDuration, totalSessions),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: _primaryColor,
                        unselectedLabelColor: _textSecondaryColor,
                        indicatorColor: _primaryColor,
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: const [
                          Tab(text: "Sessions by Day"),
                          Tab(text: "Product Searches"),
                        ],
                      ),
                    ),
                    // Charts section
                    SizedBox(
                      height: 400, // Or adjust based on need
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSessionsTab(sessions),
                          _buildSearchesTab(_searchLogs),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(List<Sessions> allSessions) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_filteredDayLabel != null) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list, size: 16, color: _primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Filtered: $_filteredDayLabel",
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _filteredDayLabel = null;
                          _filteredSessions = [];
                        });
                      },
                      child: Icon(Icons.clear, size: 16, color: _primaryColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else
            Expanded(
              child: Text(
                "All Sessions",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _textPrimaryColor,
                ),
              ),
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text("Filter by Date"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2024, 1),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: _primaryColor,
                        onPrimary: Colors.white,
                        surface: _cardColor,
                        onSurface: _textPrimaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (selectedDate != null) {
                final filteredLabel = "May ${selectedDate.day}";
                setState(() {
                  _filteredDayLabel = filteredLabel;
                  _filteredSessions = allSessions.where((s) {
                    final loginDate = DateTime.parse(s.loginTime!).toLocal();
                    return loginDate.year == selectedDate.year &&
                        loginDate.month == selectedDate.month &&
                        loginDate.day == selectedDate.day;
                  }).toList();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(List<Sessions> displayedSessions, int activeSessions, int inactiveSessions, String avgDuration, int totalSessions) {
    final metrics = [
      {
        "icon": Icons.people_alt_outlined,
        "title": _filteredDayLabel != null ? "Sessions" : "Total Sessions",
        "value": _filteredDayLabel != null ? "${displayedSessions.length} of $totalSessions" : "$totalSessions",
        "color": _primaryColor,
      },
      {
        "icon": Icons.check_circle_outline,
        "title": "Active",
        "value": "$activeSessions",
        "color": Colors.green,
      },
      {
        "icon": Icons.cancel_outlined,
        "title": "Inactive",
        "value": "$inactiveSessions",
        "color": Colors.red[400]!,
      },
      {
        "icon": Icons.timer_outlined,
        "title": "Avg Duration",
        "value": avgDuration,
        "color": _accentColor,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        shrinkWrap: true,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
        children: metrics.map((metric) {
          return Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(metric["icon"] as IconData, color: metric["color"] as Color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          metric["title"] as String,
                          style: TextStyle(
                            color: _textSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    metric["value"] as String,
                    style: TextStyle(
                      color: _textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsGrid(List<Sessions> displayedSessions, int activeSessions,
      int inactiveSessions, String avgDuration, int totalSessions) {
    final List<Widget> metricCards = [
      _buildMetricCardGrid(
        icon: Icons.people_alt_outlined,
        title: _filteredDayLabel != null ? "Sessions" : "Total Sessions",
        value: _filteredDayLabel != null
            ? "${displayedSessions.length} of $totalSessions"
            : "$totalSessions",
        color: _primaryColor,
      ),
      _buildMetricCardGrid(
        icon: Icons.check_circle_outline,
        title: "Active",
        value: "$activeSessions",
        color: Colors.green,
      ),
      _buildMetricCardGrid(
        icon: Icons.cancel_outlined,
        title: "Inactive",
        value: "$inactiveSessions",
        color: Colors.red.shade400,
      ),
      _buildMetricCardGrid(
        icon: Icons.timer_outlined,
        title: "Avg Duration",
        value: avgDuration,
        color: _accentColor,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: metricCards.map((card) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width / 2) - 24,
            child: card,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricCardGrid({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white, // Light background for visibility
      // color: const Color(0xffF7F1FB), // Light background for visibility
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsTab(List<Sessions> sessions) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sessions by Day",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive chart container
                    return _buildSessionsBarChart(sessions, constraints);
                  }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchesTab(List<ProductSearchLogsModel> logs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Product Search Analytics",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimaryColor,
                    ),
                  ),
                ),
                PopupMenuButton<int>(
                  tooltip: 'Filter by Day',
                  onSelected: (value) {
                    setState(() {
                      _selectedDayFilter = value;
                      _isLoading = true;
                    });
                    _loadSearchLogs();
                  },
                  itemBuilder: (context) => _dayFilters.entries.map((entry) {
                    return PopupMenuItem<int>(
                      value: entry.value,
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: _primaryColor, size: 20),
                        title: Text(
                          entry.key,
                          style: TextStyle(fontSize: 14, color: _textPrimaryColor),
                        ),
                      ),
                    );
                  }).toList(),
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: _primaryColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: _primaryColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _dayFilters.entries
                              .firstWhere((e) => e.value == _selectedDayFilter)
                              .key,
                          style: TextStyle(
                            fontSize: 13,
                            color: _primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                ),
              )
            else
              Expanded(
                child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildSearchLogChartFromData(logs);
                    }
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsBarChart(List<Sessions> sessions, BoxConstraints constraints) {
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

    if (sortedKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No session data to display",
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final maxY = (sessionCountByDate.values.isNotEmpty ? sessionCountByDate.values.reduce((a, b) => a > b ? a : b) : 1).toDouble();

    // Calculate appropriate chart dimensions
    double chartHeight = constraints.maxHeight - 20; // Leave some margin

    // Calculate bar width based on available width
    final availableWidth = constraints.maxWidth;
    final minBarWidth = 36.0; // Minimum width per bar
    final spacing = 24.0; // Space between bars

    // Calculate if we need scrolling
    final neededWidth = (sortedKeys.length * (minBarWidth + spacing));
    final needsScrolling = neededWidth > availableWidth;

    // Adjust bar width if we have few bars and don't need scrolling
    double barWidth = needsScrolling
        ? minBarWidth
        : (availableWidth - (sortedKeys.length * spacing)) / sortedKeys.length;

    // Make sure bar width is reasonable
    barWidth = barWidth.clamp(24.0, 60.0);

    final chartWidth = needsScrolling
        ? sortedKeys.length * (barWidth + spacing)
        : availableWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (needsScrolling)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Swipe horizontally to view all data",
              style: TextStyle(
                fontSize: 12,
                color: _textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Expanded(
          child: Scrollbar(
            controller: _sessionsScrollController,
            thumbVisibility: needsScrolling,
            thickness: 6,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              controller: _sessionsScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(), // Add smooth scroll physics
              child: SizedBox(
                width: chartWidth,
                height: chartHeight,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        tooltipBorder: BorderSide(color: Colors.white, width: 0.5),
                        fitInsideHorizontally: true, // Keep tooltip within horizontal bounds
                        fitInsideVertically: true, // Keep tooltip within vertical bounds
                        maxContentWidth: 120, // Limit tooltip width
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
                        if (event.isInterestedForInteractions && response?.spot != null) {
                          final index = response!.spot!.touchedBarGroupIndex;
                          if (index >= 0 && index < sortedKeys.length) {
                            final selectedLabel = sortedKeys[index];
                            setState(() {
                              _touchedIndex = index;
                              _filteredDayLabel = selectedLabel;
                              _filteredSessions = sessions.where((s) {
                                if (s.loginTime == null) return false;
                                final loginDate = DateTime.parse(s.loginTime!).toLocal();
                                return selectedLabel == "May ${loginDate.day}";
                              }).toList();
                            });
                          }
                        }
                      },
                    ),
                    maxY: maxY + 1,
                    minY: 0,
                    barGroups: List.generate(sortedKeys.length, (index) {
                      final key = sortedKeys[index];
                      final value = sessionCountByDate[key] ?? 0;
                      final isTouched = index == _touchedIndex;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: value.toDouble(),
                            width: isTouched ? barWidth * 1.15 : barWidth,
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor,
                                _accentColor,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY + 1,
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ],
                      );
                    }),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            if (value % 1 != 0) return const SizedBox.shrink(); // Only show integers

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: _textSecondaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
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
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 30,
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                      drawVerticalLine: false,
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 500),
                  swapAnimationCurve: Curves.easeOutQuart,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

// Search Log Chart - Improved
  Widget _buildSearchLogChartFromData(List<ProductSearchLogsModel> logs) {
    final List<String> labels = [];
    final List<int> counts = [];

    for (var log in logs) {
      final name = log.search?.trim();
      if (name != null && name.isNotEmpty && name != "NA") {
        labels.add(name);
        counts.add(log.count ?? 0);
      }
    }

    if (labels.isEmpty || counts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No product search data available",
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final double maxY = counts.reduce((a, b) => a > b ? a : b).toDouble();
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = max(labels.length * 80.0, screenWidth - 64);
    final needsScrolling = contentWidth > screenWidth - 64;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (needsScrolling)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Text(
              "Swipe horizontally to view all searches",
              style: TextStyle(
                fontSize: 12,
                color: _textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Expanded(
          child: Scrollbar(
            controller: _searchesScrollController,
            thumbVisibility: needsScrolling,
            thickness: 6,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              controller: _searchesScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: contentWidth,
                height: 280,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: BarChart(
                    BarChartData(
                      barGroups: List.generate(labels.length, (index) {
                        final value = counts[index];
                        final isTouched = index == _touchedIndex;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value.toDouble(),
                              width: isTouched ? 24 : 18,
                              gradient: LinearGradient(
                                colors: [_accentColor, const Color(0xff7AB0FF)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
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
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          tooltipBorder: const BorderSide(color: Colors.white, width: 0.5),
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          maxContentWidth: 120,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final product = labels[group.x.toInt()];
                            final displayName = product.length > 15
                                ? '${product.substring(0, 15)}...'
                                : product;
                            return BarTooltipItem(
                              '$displayName\n',
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
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: _textSecondaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < labels.length) {
                                final label = labels[index];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Transform.rotate(
                                    angle: -0.7,
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 80),
                                      child: Text(
                                        label.length > 12 ? '${label.substring(0, 12)}...' : label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _textSecondaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
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
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
        return 0;
      }
    }).toList();

    if (durations.isEmpty) return "00:00:00";
    final avg = durations.reduce((a, b) => a + b) ~/ durations.length;
    return Duration(seconds: avg).toString().split('.').first;
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
                    onPressed: () {
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
                    /*onPressed: () async {
                      try {
                        await SharedPreferenceHelper.clearSession();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      } catch (e) {
                        print('Logout failed: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Logout failed. Please try again.')),
                        );
                      }
                    },*/
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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Logout failed. Please try again.'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
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