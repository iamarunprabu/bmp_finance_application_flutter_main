import 'package:bmp_login/core/constant/applicationConstant.dart';
import 'package:bmp_login/core/utils/jwt_storage.dart';
import 'package:bmp_login/core/utils/riverpod_provider.dart';
import 'package:bmp_login/feature/authentication/model/monthly_report_model.dart';
import 'package:bmp_login/feature/authentication/screen/controller/auth_controller.dart';
//import 'package:bmp_login/feature/authentication/screen/controller/loan_request_pagination_controller.dart';
import 'package:bmp_login/presentation/controller/loan_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

// Wrap with ProviderScope in main.dart if not already
// Responsive and animated Drawer
class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _loanListScrollController = ScrollController();
  // Data variables
  bool isLoading = true;
  List<double> weeklySalesData = [342, 0, 1918, 0, 3680, 0, 0]; // Default data
  Map<String, dynamic> statsData = {
    'salesTotal': 30117.0,
    'avgOrder': 66654.0,
    'totalOrders': 46,
    'visitors': 39,
    'salesPercentage': '+25%',
    'avgOrderPercentage': '-15%',
    'ordersPercentage': '+44%',
    'visitorsPercentage': '+2%',
  };
  Map<String, int> ordersStatusData = {
    'completed': 26,
    'pending': 10,
    'processing': 5,
    'cancelled': 5,
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
    
    await fetchDashboardStats();
    await fetchMonthlyReport();
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchDashboardStats() async {
    try {
      final token = await JwtStorage.getToken();
      final username = await JwtStorage.getUsername();

      final response = await http.get(
        Uri.parse('${ApplicationConstant.baseUrl}/api/loan/dashboard?username=$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response Body ${response.body}');
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

          // Update pie chart data dynamically
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

      final response = await http.get(
        Uri.parse('${ApplicationConstant.baseUrl}/api/loan/monthly-report?username=$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Monthly Report: $jsonData');

        final monthlyReport = MonthlyReportResponse.fromJson(jsonData);

        setState(() {
          // Update bar chart with total loan amounts
          weeklySalesData =
              monthlyReport.data.map((item) => item.totalLoanAmount).toList();

          // Calculate totals for pie chart
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

          // Update pie chart data
          ordersStatusData['completed'] = totalApproved;
          ordersStatusData['pending'] = totalPending;
          ordersStatusData['processing'] = totalRejected;
          ordersStatusData['cancelled'] = totalCancelled;
        });
      }
    } catch (e) {
      print("Monthly report error: $e");
    }
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
                          const SizedBox(height: 20),
                          _buildWeeklySalesChart(),
                          const SizedBox(height: 20),
                          _buildOrdersStatusChart(),
                          const SizedBox(height: 32),
                          // _buildPaginatedLoanRequestList(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Widget _buildPaginatedLoanRequestList() {
  //   return Consumer(
  //     builder: (context, ref, _) {
  //       final loanRequestsAsync =
  //           ref.watch(loanRequestPaginationControllerProvider);
  //       final controller =
  //           ref.read(loanRequestPaginationControllerProvider.notifier);
  //       return Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             'Loan Requests (Paginated)',
  //             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 12),
  //           SizedBox(
  //             height: 400,
  //             child: NotificationListener<ScrollNotification>(
  //               onNotification: (scrollInfo) {
  //                 if (scrollInfo is ScrollEndNotification &&
  //                     scrollInfo.metrics.pixels >=
  //                         scrollInfo.metrics.maxScrollExtent) {
  //                   controller.loadNextPage();
  //                 }
  //                 return false;
  //               },
  //               child: loanRequestsAsync.when(
  //                 data: (loanRequests) {
  //                   if (loanRequests.isEmpty) {
  //                     return const Center(
  //                         child: Text('No loan requests found.'));
  //                   }
  //                   return ListView.builder(
  //                     controller: _loanListScrollController,
  //                     itemCount: loanRequests.length,
  //                     itemBuilder: (context, index) {
  //                       final loan = loanRequests[index];
  //                       return Card(
  //                         margin: const EdgeInsets.symmetric(vertical: 6),
  //                         child: ListTile(
  //                           title: Text(
  //                               'Loan #${loan.loanNo} - ${loan.customerName}'),
  //                           subtitle: Text(
  //                               'Amount: ₹${loan.amount} | Status: ${loan.status}'),
  //                         ),
  //                       );
  //                     },
  //                   );
  //                 },
  //                 loading: () =>
  //                     const Center(child: CircularProgressIndicator()),
  //                 error: (e, st) => Center(child: Text('Error: $e')),
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget _buildDrawer() {
    final AuthController authController = Get.put(AuthController());
    final selectedMenu = ref.watch(drawerMenuProvider);
    return ScreenTypeLayout.builder(
      mobile: (context) =>
          _buildAnimatedDrawer(context, selectedMenu, authController),
      tablet: (context) => _buildAnimatedDrawer(
          context, selectedMenu, authController,
          isTablet: true),
      desktop: (context) => _buildAnimatedDrawer(
          context, selectedMenu, authController,
          isDesktop: true),
    );
  }

  Widget _buildAnimatedDrawer(
      BuildContext context, String selectedMenu, AuthController authController,
      {bool isTablet = false, bool isDesktop = false}) {
    final theme = Theme.of(context);
    double drawerWidth = isDesktop
        ? 320
        : isTablet
            ? 260
            : 220;
    return Drawer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: drawerWidth,
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Row(
                children: [
                  FutureBuilder<String?>(
                    future: JwtStorage.getUsername(),
                    builder: (context, snapshot) {
                      final username = snapshot.data ?? 'Admin';
                      final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : 'A';

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
                ],
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
                  _buildMenuItem(
                    Icons.dashboard_outlined,
                    'Dashboard',
                    selectedMenu == 'Dashboard',
                  ),
                  _buildMenuItem(
                    Icons.check_circle_outline,
                    'Approved Loans',
                    selectedMenu == 'Approved Loans',
                  ),
                  _buildMenuItem(
                    Icons.cancel_outlined,
                    'Rejected Loans',
                    selectedMenu == 'Rejected Loans',
                  ),
                  _buildMenuItem(
                    Icons.hourglass_empty,
                    'Pending Loans',
                    selectedMenu == 'Pending Loans',
                  ),
                  _buildMenuItem(
                    Icons.priority_high,
                    'Priority Sheet',
                    selectedMenu == 'Priority Sheet',
                  ),
                  _buildMenuItem(
                    Icons.account_balance_wallet,
                    'Investment List',
                    selectedMenu == 'Investment List',
                  ),
                  _buildMenuItem(
                    Icons.trending_up,
                    'Investment Returns',
                    selectedMenu == 'Investment Returns',
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
                  _buildMenuItem(
                    Icons.person_outline,
                    'Profile',
                    selectedMenu == 'Profile',
                  ),
                  _buildMenuItem(
                    Icons.settings_outlined,
                    'Settings',
                    selectedMenu == 'Settings',
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: const Icon(
                  Icons.logout,
                  size: 20,
                  color: Color(0xFF666666),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
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
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : const Color(0xFF666666),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFF666666),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        onTap: () {
          print('Menu item clicked: $title');
          ref.read(drawerMenuProvider.notifier).state = title;
          Navigator.pop(context);

          if (title == 'Investment List') {
            _showInvestmentListDialog();
          } else if (title == 'Pending Loans') {
            print('Navigating to Pending Loans');
            Get.toNamed(
              '/loan-request-list',
              arguments: {
                'isAdmin': true,
                'status': 'PENDING',
                'title': 'Pending Loans',
              },
              preventDuplicates: false,
            );
          } else if (title == 'Approved Loans') {
            print('Navigating to Approved Loans');
            Get.toNamed(
              '/loan-request-list',
              arguments: {
                'isAdmin': true,
                'status': 'APPROVED',
                'title': 'Approved Loans',
              },
              preventDuplicates: false,
            );
          } else if (title == 'Rejected Loans') {
            print('Navigating to Rejected Loans');
            Get.toNamed(
              '/loan-request-list',
              arguments: {
                'isAdmin': true,
                'status': 'NOT_ELIGIBLE',
                'title': 'Rejected Loans',
              },
              preventDuplicates: false,
            );
          } else if (title == 'Priority Sheet') {
            print('Opening Priority Sheet popup');
            _showPrioritySheetPopup(context);
          }
        },
      ),
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    return Container(
      height: 60,
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, size: 24),
            color: Colors.white,
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'B',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'BMP',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
        ],
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
              child: _buildStatCard(
                title: 'Inverstment Amount',
                value: '₹${statsData['salesTotal'].toStringAsFixed(0)}',
                percentage: statsData['salesPercentage'],
                color: const Color(0xFF10B981),
                icon: Icons.currency_rupee,
                isPositive: statsData['salesPercentage'].toString().startsWith(
                      '+',
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Loan Amount',
                value: formatCurrency(statsData['totalLoanRequestAmount']),

                percentage: statsData['avgOrderPercentage'],
                color: const Color(0xFF10B981), // green → money inflow
                icon: Icons.trending_up,
                isPositive:
                    statsData['avgOrderPercentage'].toString().startsWith('+'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Approved Loans',
                value: formatCount(statsData['approvedCount']),
                percentage: statsData['ordersPercentage'],
                color: const Color(0xFF8B5CF6), // purple → authority / approval
                icon: Icons.verified_outlined,
                isPositive: statsData['ordersPercentage'].toString().startsWith(
                      '+',
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Get.toNamed(
                    '/loan-request-list',
                    arguments: {
                      'isAdmin': true,
                      'status': 'PENDING',
                      'title': 'Pending Loans',
                    },
                    preventDuplicates: false,
                  );
                },
                child: _buildStatCard(
                  title: 'Pending Loans',
                  value: formatCount(statsData['totalPendingCount']),
                  percentage: statsData['visitorsPercentage'],
                  color: const Color(
                    0xFFF97316,
                  ), // orange → pending / attention
                  icon: Icons.hourglass_bottom,
                  isPositive: statsData['visitorsPercentage']
                      .toString()
                      .startsWith('+'),
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
            offset: const Offset(0, 2),
          ),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySalesChart() {
    final theme = Theme.of(context);
    // Calculate max value dynamically
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
            offset: const Offset(0, 2),
          ),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Monthly Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: weeklySalesData.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValue,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => theme.colorScheme.primary,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '₹${rod.toY.toStringAsFixed(0)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
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
                                'Dec',
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
                                      fontWeight: FontWeight.w500,
                                    ),
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
                              if (value == 0) {
                                return Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                );
                              }
                              return Text(
                                '₹${(value / 1000).toStringAsFixed(0)}K',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxValue / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        weeklySalesData.length,
                        (index) =>
                            _buildBarGroup(index, weeklySalesData[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double value) {
    final theme = Theme.of(context);
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: theme.colorScheme.primary,
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
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
            offset: const Offset(0, 2),
          ),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: Color(0xFFFBBF24),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Loan Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
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
                    color: theme.colorScheme.primary,
                    title: '${ordersStatusData['completed']}',
                    radius: 45,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: ordersStatusData['pending']!.toDouble(),
                    color: const Color(0xFF10B981),
                    title: '${ordersStatusData['pending']}',
                    radius: 45,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: ordersStatusData['processing']!.toDouble(),
                    color: const Color(0xFFF97316),
                    title: '${ordersStatusData['processing']}',
                    radius: 45,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: ordersStatusData['cancelled']!.toDouble(),
                    color: const Color(0xFF8B5CF6),
                    title: '${ordersStatusData['cancelled']}',
                    radius: 45,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
              _buildLegendItem(
                theme.colorScheme.primary,
                'Completed',
                '${ordersStatusData['completed']}',
              ),
              _buildLegendItem(
                const Color(0xFF10B981),
                'Pending',
                '${ordersStatusData['pending']}',
              ),
              _buildLegendItem(
                const Color(0xFFF97316),
                'rejected',
                '${ordersStatusData['processing']}',
              ),
              _buildLegendItem(
                const Color(0xFF8B5CF6),
                'Cancelled',
                '${ordersStatusData['cancelled']}',
              ),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Future<void> _importExcelDirect(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      String fileName = result.files.single.name;
      
      dio.FormData formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(filePath, filename: fileName),
      });

      try {
        final token = await JwtStorage.getToken();
        final response = await dio.Dio().post(
          'http://10.0.2.2:8080/api/loan/import-excel',
          data: formData,
          options: dio.Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (context.mounted) {
          await _showAnimatedSuccessDialog('Excel file imported successfully!', 'Data has been imported to the system');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _exportExcelDirect(BuildContext context) async {
    try {
      final token = await JwtStorage.getToken();
      print('Starting download...');
      
      final response = await Dio().get(
        'http://10.0.2.2:8080/api/loan/export-excel',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );

      print('Download response status: ${response.statusCode}');
      
      // Use app's external directory - always accessible
      final appDir = await getExternalStorageDirectory();
      final savePath = '${appDir!.path}/loan_requests.xlsx';
      print('Saving to: $savePath');
      
      final file = File(savePath);
      await file.writeAsBytes(response.data);
      
      final fileExists = await file.exists();
      final fileSize = await file.length();
      print('File created: $fileExists, Size: $fileSize bytes');
      
      if (context.mounted) {
        await _showAnimatedSuccessDialog('Excel file downloaded successfully!', 'File saved to device storage');
      }
      
      // Try to open with any available app
      try {
        await OpenFile.open(savePath);
      } catch (e) {
        print('Could not open file: $e');
      }
    } catch (e) {
      print('Export error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showInvestmentListDialog() async {
    final theme = Theme.of(context);
    final token = await JwtStorage.getToken();

    try {
      final response = await http.get(
        Uri.parse('${ApplicationConstant.baseUrl}/api/investment/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Investment List'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Username')),
                    DataColumn(label: Text('Amount')),
                  ],
                  rows: data.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item['username'] ?? '')),
                      DataCell(Text('₹${item['amount']}')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar('Error', 'Failed to load investments');
      }
    } catch (e) {
      print('Investment list error: $e');
      Get.snackbar('Error', 'Failed to load investments');
    }
  }

  void _showPrioritySheetPopup(BuildContext context) async {
    final theme = Theme.of(context);
    await Get.bottomSheet(
      _buildPrioritySheetBottomSheet(context),
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  Widget _buildPrioritySheetBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.priority_high,
                    color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Priority Sheet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                Get.back(); // Close popup first
                try {
                  await _importExcelDirect(context);
                } catch (e) {
                  print('Import error: $e');
                }
              },
              icon: Icon(Icons.upload_file, color: theme.colorScheme.onPrimary),
              label: Text(
                'Import from Excel',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                Get.back(); // Close popup first
                try {
                  await _exportExcelDirect(context);
                } catch (e) {
                  print('Export error: $e');
                }
              },
              icon: Icon(Icons.download, color: theme.colorScheme.onPrimary),
              label: Text(
                'Export to Excel',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAnimatedSuccessDialog(String title, String message) async {
    await Get.dialog(
      _SuccessAnimationDialog(title: title, message: message),
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      transitionCurve: Curves.easeInOut,
    );
  }
}

/// Animated Success Dialog Widget
class _SuccessAnimationDialog extends StatefulWidget {
  final String title;
  final String message;
  
  const _SuccessAnimationDialog({required this.title, required this.message});

  @override
  State<_SuccessAnimationDialog> createState() => _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<_SuccessAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _textController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _textAnimation;

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

    _scaleController.forward().then((_) {
      _checkController.forward().then((_) {
        _textController.forward();
      });
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && Get.isDialogOpen == true) {
        Get.back();
      }
    });
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
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
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
                  color: theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FadeTransition(
                  opacity: _checkAnimation,
                  child: Icon(
                    Icons.check_rounded,
                    color: theme.colorScheme.onPrimary,
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
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
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

/* {
  "stats": {
    "salesTotal": 30117.28,
    "avgOrder": 654.72,
    "totalOrders": 46,
    "visitors": 39,
    "salesPercentage": "+25%",
    "avgOrderPercentage": "-15%",
    "ordersPercentage": "+44%",
    "visitorsPercentage": "+2%"
  },
  "weeklySales": [
    {"day": "Mon", "sales": 342},
    {"day": "Tue", "sales": 0},
    {"day": "Wed", "sales": 1918},
    {"day": "Thu", "sales": 0},
    {"day": "Fri", "sales": 3680},
    {"day": "Sat", "sales": 0},
    {"day": "Sun", "sales": 0}
  ],
  "ordersStatus": {
    "completed": 26,
    "pending": 10,
    "processing": 5,
    "cancelled": 5
  }
}
*/
