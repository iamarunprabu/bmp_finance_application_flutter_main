import 'package:bmp_login/core/constant/applicationConstant.dart';
import 'package:bmp_login/core/utils/jwt_storage.dart';
import 'package:bmp_login/feature/authentication/model/monthly_report_model.dart';
import 'package:bmp_login/feature/authentication/screen/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserDasboard extends StatefulWidget {
  const UserDasboard({super.key});

  @override
  State<UserDasboard> createState() => _UserDasboardState();
}

class _UserDasboardState extends State<UserDasboard> {
  String selectedMenu = 'Dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = true;
  List<double> weeklySalesData = [];
  Map<String, dynamic> statsData = {};
  Map<String, int> ordersStatusData = {
    'completed': 0,
    'pending': 0,
    'processing': 0,
    'cancelled': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      fetchDashboardStats(),
      fetchMonthlyReport(),
      fetchInvestmentAmount(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchDashboardStats() async {
    try {
      final token = await JwtStorage.getToken();
      final username = await JwtStorage.getUsername();

      print('Fetching dashboard stats for user: $username');
      print(
          'URL: ${ApplicationConstant.baseUrl}/api/loan/dashboard?username=$username');

      final response = await http.get(
        Uri.parse(
            '${ApplicationConstant.baseUrl}/api/loan/dashboard?username=$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('Dashboard Status Code: ${response.statusCode}');
      print('Dashboard Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          statsData['totalRequests'] =
              (data['totalRequests'] as num?)?.toInt() ?? 0;
          statsData['approvedCount'] =
              (data['approvedCount'] as num?)?.toInt() ?? 0;
          statsData['rejectedCount'] =
              (data['rejectedCount'] as num?)?.toInt() ?? 0;
          statsData['totalPendingCount'] =
              (data['totalPendingCount'] as num?)?.toInt() ?? 0;
          statsData['totalLoanRequestAmount'] =
              (data['totalLoanRequestAmount'] as num?)?.toDouble() ?? 0.0;

          ordersStatusData['completed'] = statsData['approvedCount'];
          ordersStatusData['pending'] = statsData['totalPendingCount'];
          ordersStatusData['processing'] = statsData['rejectedCount'];
          ordersStatusData['cancelled'] =
              (data['cancelledCount'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      print("Dashboard error: $e");
    }
  }

  Future<void> fetchMonthlyReport() async {
    try {
      final token = await JwtStorage.getToken();
      final username = await JwtStorage.getUsername();

      print('Fetching monthly report for user: $username');
      print(
          'URL: ${ApplicationConstant.baseUrl}/api/loan/monthly-report?username=$username');

      final response = await http.get(
        Uri.parse(
            '${ApplicationConstant.baseUrl}/api/loan/monthly-report?username=$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Monthly Report Status Code: ${response.statusCode}');
      print('Monthly Report Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final monthlyReport = MonthlyReportResponse.fromJson(jsonData);

        setState(() {
          weeklySalesData =
              monthlyReport.data.map((item) => item.totalLoanAmount).toList();

          int totalApproved = 0;
          int totalRejected = 0;
          int totalPending = 0;
          int totalCancelled = 0;

          for (var month in monthlyReport.data) {
            totalApproved += month.approvedCount;
            totalRejected += month.rejectedCount;
            totalPending += month.pendingCount;
            totalCancelled += month.cancelledCount;
          }

          ordersStatusData['completed'] = totalApproved;
          ordersStatusData['pending'] = totalPending;
          ordersStatusData['processing'] = totalRejected;
          ordersStatusData['cancelled'] = totalCancelled;
        });
        print('Chart data loaded: ${weeklySalesData.length} months');
      }
    } catch (e) {
      print("Monthly report error: $e");
    }
  }

  Future<void> fetchInvestmentAmount() async {
    try {
      final token = await JwtStorage.getToken();
      final username = await JwtStorage.getUsername();

      print('Fetching investment amount for user: $username');
      print(
          'URL: ${ApplicationConstant.baseUrl}/api/investment/userInverstmentAmt?username=$username');

      final response = await http.get(
        Uri.parse(
            '${ApplicationConstant.baseUrl}/api/investment/userInverstmentAmt?username=$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Investment Amount Status Code: ${response.statusCode}');
      print('Investment Amount Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        double totalInvestment = 0.0;

        for (var item in data) {
          totalInvestment += (item['inversmentAmt'] as num?)?.toDouble() ?? 0.0;
        }

        setState(() {
          statsData['investmentAmount'] = totalInvestment;
        });
        print('Total Investment Amount: $totalInvestment');
      }
    } catch (e) {
      print("Investment amount error: $e");
    }
  }

  void _showInvestmentSuccessAnimation(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _InvestmentSuccessDialog(message: message),
    );
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  String formatCurrency(dynamic value) {
    final num safeValue = value is num ? value : 0;
    return '₹${safeValue.toDouble().toStringAsFixed(0)}';
  }

  String formatCount(dynamic value) {
    final num safeValue = value is num ? value : 0;
    return safeValue.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildStatsCards(),
                          // const SizedBox(height: 20),
                          // _buildWeeklySalesChart(),
                          const SizedBox(height: 20),
                          _buildOrdersStatusChart(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showInvestmentDialog() {
    final TextEditingController amountController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet,
                color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Add Investment'),
          ],
        ),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Investment Amount',
            prefixText: '₹ ',
            hintText: 'Enter amount',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = amountController.text.trim();
              if (amount.isEmpty) {
                Get.snackbar('Error', 'Please enter amount');
                return;
              }
              await _saveInvestment(double.parse(amount));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveInvestment(double amount) async {
    try {
      final token = await JwtStorage.getToken();
      final username = await JwtStorage.getUsername();

      final response = await http.post(
        Uri.parse('${ApplicationConstant.baseUrl}/api/investment/save'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'createdBy': username,
          'inversmentAmt': amount,
        }),
      );

      print('Investment Response: ${response.statusCode}');
      print('Investment Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = response.body;
        Navigator.pop(context);
        _showInvestmentSuccessAnimation(message);
        await Future.delayed(const Duration(milliseconds: 2000));
        _loadDashboard();
      } else {
        Get.snackbar('Error', 'Failed to save investment');
      }
    } catch (e) {
      print('Investment error: $e');
      Get.snackbar('Error', 'Failed to save investment');
    }
  }

  Widget _buildDrawer() {
    final AuthController authController = Get.put(AuthController());
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: FutureBuilder<String?>(
                future: JwtStorage.getUsername(),
                builder: (context, snapshot) {
                  final username = snapshot.data ?? 'User';
                  final firstLetter =
                      username.isNotEmpty ? username[0].toUpperCase() : 'U';

                  return Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            firstLetter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _buildMenuItem(Icons.dashboard_outlined, 'Dashboard',
                      selectedMenu == 'Dashboard'),
                  _buildMenuItemWithNavigation(
                    Icons.description,
                    'Loan Request',
                    selectedMenu == 'Loan Request',
                    () {
                      setState(() => selectedMenu = 'Loan Request');
                      Navigator.pop(context);
                      Get.toNamed(ApplicationConstant.LoanRequestList);
                    },
                  ),
                  _buildMenuItemWithNavigation(
                    Icons.account_balance_wallet,
                    'Investment',
                    selectedMenu == 'Investment',
                    () {
                      setState(() => selectedMenu = 'Investment');
                      Navigator.pop(context);
                      _showInvestmentDialog();
                    },
                  ),
                  _buildMenuItemWithNavigation(
                    Icons.check_circle_outline,
                    'Approved Loans',
                    selectedMenu == 'Approved Loans',
                    () async {
                      setState(() => selectedMenu = 'Approved Loans');
                      Navigator.pop(context);
                      final username = await JwtStorage.getUsername();
                      Get.toNamed(
                        '/loan-request-list',
                        arguments: {
                          'isAdmin': false,
                          'status': 'APPROVED',
                          'username': username,
                          'title': 'Approved Loans',
                        },
                      );
                    },
                  ),
                  _buildMenuItemWithNavigation(
                    Icons.cancel_outlined,
                    'Rejected Loans',
                    selectedMenu == 'Rejected Loans',
                    () async {
                      setState(() => selectedMenu = 'Rejected Loans');
                      Navigator.pop(context);
                      final username = await JwtStorage.getUsername();
                      Get.toNamed(
                        '/loan-request-list',
                        arguments: {
                          'isAdmin': false,
                          'status': 'NOT_ELIGIBLE',
                          'username': username,
                          'title': 'Rejected Loans',
                        },
                      );
                    },
                  ),
                  _buildMenuItemWithNavigation(
                    Icons.hourglass_empty,
                    'Pending Loans',
                    selectedMenu == 'Pending Loans',
                    () async {
                      setState(() => selectedMenu = 'Pending Loans');
                      Navigator.pop(context);
                      final username = await JwtStorage.getUsername();
                      Get.toNamed(
                        '/loan-request-list',
                        arguments: {
                          'isAdmin': false,
                          'status': 'PENDING',
                          'username': username,
                          'title': 'Pending Loans',
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'OTHER',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _buildMenuItem(Icons.person_outline, 'Profile',
                      selectedMenu == 'Profile'),
                  _buildMenuItem(Icons.settings_outlined, 'Settings',
                      selectedMenu == 'Settings'),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: const Icon(Icons.logout,
                    size: 20, color: Color(0xFF666666)),
                title: const Text('Logout',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
                onTap: () async {
                  await authController.logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool isSelected) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(icon,
            size: 20,
            color: isSelected ? Colors.white : const Color(0xFF666666)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFF666666),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() => selectedMenu = title);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildMenuItemWithNavigation(
      IconData icon, String title, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(icon,
            size: 20,
            color: isSelected ? Colors.white : const Color(0xFF666666)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFF666666),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        height: 60,
        color: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.menu, size: 24),
              color: Colors.white,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            const SizedBox(width: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Transform.rotate(
                    angle: (1 - value) * 2,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/bmp.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'BMP',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _showInvestmentDialog,
                child: _buildStatCard(
                  title: 'Investment Amount',
                  value: formatCurrency(statsData['investmentAmount'] ?? 0),
                  percentage: '',
                  color: const Color(0xFF10B981),
                  icon: Icons.currency_rupee,
                  isPositive: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Loan Amount',
                value: formatCurrency(statsData['totalLoanRequestAmount']),
                percentage: '',
                color: const Color(0xFF10B981),
                icon: Icons.trending_up,
                isPositive: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final username = await JwtStorage.getUsername();
                  Get.toNamed(
                    '/loan-request-list',
                    arguments: {
                      'isAdmin': false,
                      'status': 'APPROVED',
                      'username': username,
                      'title': 'Approved Loans',
                    },
                  );
                },
                child: _buildStatCard(
                  title: 'Approved Loans',
                  value: formatCount(statsData['approvedCount']),
                  percentage: '',
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.verified_outlined,
                  isPositive: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final username = await JwtStorage.getUsername();
                  Get.toNamed(
                    '/loan-request-list',
                    arguments: {
                      'isAdmin': false,
                      'status': 'PENDING',
                      'username': username,
                      'title': 'Pending Loans',
                    },
                  );
                },
                child: _buildStatCard(
                  title: 'Pending Loans',
                  value: formatCount(statsData['totalPendingCount']),
                  percentage: '',
                  color: const Color(0xFFF97316),
                  icon: Icons.hourglass_bottom,
                  isPositive: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Loan Request',
                value: formatCount(statsData['totalRequests']),
                percentage: '',
                color: theme.colorScheme.primary,
                icon: Icons.summarize,
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String percentage,
    required Color color,
    required IconData icon,
    required bool isPositive,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              if (percentage.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 10,
                      color: isPositive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildWeeklySalesChart() {
    final theme = Theme.of(context);
    final maxValue = weeklySalesData.isEmpty
        ? 4000.0
        : (weeklySalesData.reduce((a, b) => a > b ? a : b) * 1.2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child:
                    const Icon(Icons.show_chart, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Monthly Report',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: weeklySalesData.isEmpty
                ? Center(
                    child: Text('No data available',
                        style: TextStyle(color: Colors.grey[600])))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxValue / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec'
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < weeklySalesData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    value.toInt() < months.length
                                        ? months[value.toInt()]
                                        : '',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                        fontWeight: FontWeight.w500),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            interval: maxValue / 4,
                            getTitlesWidget: (value, meta) {
                              if (value == 0)
                                return Text('0',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6)));
                              return Text(
                                  '₹${(value / 1000).toStringAsFixed(0)}K',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6)));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (weeklySalesData.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxValue,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) =>
                              theme.colorScheme.primary,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              const months = [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                                'Jul',
                                'Aug',
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec'
                              ];
                              return LineTooltipItem(
                                '${months[spot.x.toInt()]}\n₹${spot.y.toStringAsFixed(0)}',
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            weeklySalesData.length,
                            (index) => FlSpot(
                                index.toDouble(), weeklySalesData[index]),
                          ),
                          isCurved: true,
                          color: theme.colorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: theme.colorScheme.primary,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.3),
                                theme.colorScheme.primary.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersStatusChart() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.pie_chart,
                    color: Color(0xFFFBBF24), size: 20),
              ),
              const SizedBox(width: 10),
              Text('Loan Status',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: ordersStatusData['completed']!.toDouble(),
                    color: const Color(0xFF10B981),
                    title: '${ordersStatusData['completed']}',
                    radius: 45,
                    titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: ordersStatusData['pending']!.toDouble(),
                    color: const Color(0xFFFBBF24),
                    title: '${ordersStatusData['pending']}',
                    radius: 45,
                    titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: ordersStatusData['processing']!.toDouble(),
                    color: const Color(0xFFEF4444),
                    title: '${ordersStatusData['processing']}',
                    radius: 45,
                    titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: ordersStatusData['cancelled']!.toDouble(),
                    color: const Color(0xFF3B82F6),
                    title: '${ordersStatusData['cancelled']}',
                    radius: 45,
                    titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildLegendItem(const Color(0xFF10B981), 'Completed',
                  '${ordersStatusData['completed']}'),
              _buildLegendItem(const Color(0xFFFBBF24), 'Pending',
                  '${ordersStatusData['pending']}'),
              _buildLegendItem(const Color(0xFFEF4444), 'Rejected',
                  '${ordersStatusData['processing']}'),
              _buildLegendItem(const Color(0xFF3B82F6), 'Cancelled',
                  '${ordersStatusData['cancelled']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

class _InvestmentSuccessDialog extends StatefulWidget {
  final String message;

  const _InvestmentSuccessDialog({required this.message});

  @override
  State<_InvestmentSuccessDialog> createState() =>
      _InvestmentSuccessDialogState();
}

class _InvestmentSuccessDialogState extends State<_InvestmentSuccessDialog>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _checkController;
  late final AnimationController _textController;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _checkAnimation;
  late final Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );

    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await _scaleController.forward();
    await _checkController.forward();
    await _textController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF252541),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FadeTransition(
                  opacity: _checkAnimation,
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _textAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_textAnimation),
                child: Column(
                  children: [
                    const Text(
                      'Investment Saved!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green.shade400,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
