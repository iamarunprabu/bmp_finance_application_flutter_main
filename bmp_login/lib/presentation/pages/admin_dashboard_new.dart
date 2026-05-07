import 'package:flutter/material.dart';
import 'package:bmp_login/presentation/widgets/curved_body_container.dart';
import 'package:bmp_login/core/constant/applicationConstant.dart';
import 'package:bmp_login/core/utils/jwt_storage.dart';
import 'package:bmp_login/config/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AdminDashboardNew extends StatefulWidget {
  const AdminDashboardNew({super.key});

  @override
  State<AdminDashboardNew> createState() => _AdminDashboardNewState();
}

class _AdminDashboardNewState extends State<AdminDashboardNew> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String selectedPeriod = 'Monthly';
  bool isLoading = true;
  List<dynamic> allLoans = [];
  List<dynamic> filteredLoans = [];

  double totalInvestment = 0.0;
  double totalLoanAmount = 0.0;
  double totalRevenue = 0.0;
  double totalApprovedLoans = 0.0;
  double savingsGoal = 0.0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      fetchInvestmentTotal(),
      fetchAllLoans(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchDashboardStats() async {
    try {
      final token = await JwtStorage.getToken();

      final response = await http.get(
        Uri.parse('${ApplicationConstant.baseUrl}/api/loan/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalLoanAmount =
              (data['totalLoanRequestAmount'] as num?)?.toDouble() ?? 0.0;
          totalApprovedLoans =
              (data['approvedCount'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      print("Dashboard error: $e");
    }
  }

  Future<void> fetchInvestmentTotal() async {
    try {
      final token = await JwtStorage.getToken();
      final now = DateTime.now();

      final uri = Uri.parse('${ApplicationConstant.baseUrl}/api/investment/all')
          .replace(
        queryParameters: {
          'month': now.month.toString(),
          'year': now.year.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        double totalInv = 0.0;
        for (var item in data) {
          totalInv += (item['inversmentAmt'] ?? item['amount'] ?? 0).toDouble();
        }

        setState(() {
          totalInvestment = totalInv;
        });
      }
    } catch (e) {
      print("Investment total error: $e");
    }
  }

  Future<void> fetchAllLoans() async {
    try {
      print('Starting fetchAllLoans...');
      final token = await JwtStorage.getToken();
      print('Token received: ${token?.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('${ApplicationConstant.baseUrl}/api/loan/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('API timeout after 30 seconds');
          throw TimeoutException('API request timeout');
        },
      );

      print('API Response Code: ${response.statusCode}');
      print('API Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Loans fetched successfully: ${data.length} loans');

        if (mounted) {
          setState(() {
            allLoans = data;
            filteredLoans = data;
          });
          print('State updated with loans');
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load loans: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request timeout. Please check your connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Fetch all loans error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading loans: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterLoans(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredLoans = allLoans;
      } else {
        filteredLoans = allLoans.where((loan) {
          final loanNo = loan['loanNo']?.toString().toLowerCase() ?? '';
          final customerName =
              loan['customerName']?.toString().toLowerCase() ?? '';
          final amount = loan['amount']?.toString().toLowerCase() ?? '';
          final status = loan['status']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return loanNo.contains(searchLower) ||
              customerName.contains(searchLower) ||
              amount.contains(searchLower) ||
              status.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingAmount = totalInvestment - totalLoanAmount;
    final calculatedPercentage =
        totalInvestment > 0 ? ((totalLoanAmount / totalInvestment) * 100) : 0.0;
    final percentage = calculatedPercentage > 100
        ? '100'
        : calculatedPercentage.toStringAsFixed(0);
    final isExceeded = totalLoanAmount > totalInvestment;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.primary,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/bmp.png'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'BMP Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Loan Management System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User List'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed('/user-list');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Approved Loans'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(
                  '/loan-request-list',
                  arguments: {
                    'isAdmin': true,
                    'status': 'APPROVED',
                    'title': 'Approved Loans',
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Rejected Loans'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(
                  '/loan-request-list',
                  arguments: {
                    'isAdmin': true,
                    'status': 'NOT_ELIGIBLE',
                    'title': 'Rejected Loans',
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_empty),
              title: const Text('Pending Loans'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(
                  '/loan-request-list',
                  arguments: {
                    'isAdmin': true,
                    'status': 'PENDING',
                    'title': 'Pending Loans',
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.priority_high),
              title: const Text('Priority Sheet'),
              onTap: () {
                Navigator.pop(context);
                _showPrioritySheetPopup(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Investment List'),
              onTap: () {
                Navigator.pop(context);
                _showInvestmentListDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Investment Returns'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to investment returns
                Get.toNamed('/investment-returns');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile
                Get.toNamed('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
                Get.toNamed('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadDashboard,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                        child: Column(
                          children: [
                            _buildFinancialOverview(percentage, isExceeded),
                            const SizedBox(height: 30),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  _buildAdminStats(),
                                  const SizedBox(height: 20),
                                  _buildPeriodSelector(),
                                  const SizedBox(height: 20),
                                  _buildManagementSection(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    const double headerHeight = 150;
    const double cardHeight = 92;

    return Container(
      height: headerHeight,
      color: theme.primaryColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      ),
    );
  }

  Widget _buildFinancialOverview(String percentage, bool isExceeded) {
    final theme = Theme.of(context);
    final remainingAmount = totalInvestment - totalLoanAmount;
    final progressValue = totalInvestment > 0
        ? (totalLoanAmount / totalInvestment).clamp(0.0, 1.0)
        : 0.0;

    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW: Total Investment & Total Loan Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet,
                              color: theme.colorScheme.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Total Investment',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${totalInvestment.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.currency_rupee,
                              color: theme.colorScheme.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Total Loan Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${totalLoanAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // FOOTER ROW: Three values with progress bar above
              Row(
                children: [
                  Text(
                    '₹${totalInvestment.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isExceeded
                                    ? const Color(0xFFEF4444)
                                    : theme.colorScheme.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${remainingAmount.abs().toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              // Sub-label row
              Row(
                children: [
                  Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                  ),
                  Expanded(child: Container()),
                  Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // WARNING/STATUS MESSAGE
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isExceeded
                      ? const Color(0xFFEF4444).withOpacity(0.08)
                      : const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExceeded
                        ? const Color(0xFFEF4444).withOpacity(0.2)
                        : const Color(0xFF10B981).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExceeded ? Icons.warning_rounded : Icons.check_circle,
                      color: isExceeded
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isExceeded
                            ? 'Loan Amount Exceeds Investment by ₹${remainingAmount.abs().toStringAsFixed(0)}'
                            : 'Remaining Amount: ₹${remainingAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isExceeded
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminStats() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.currency_rupee, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Savings On Goals',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${savingsGoal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long,
                        color: Colors.white.withOpacity(0.9), size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Total Revenue',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${totalRevenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.white.withOpacity(0.9), size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Approved Loans',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalApprovedLoans.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodButton('Monthly'),
        const SizedBox(width: 12),
        _buildPeriodButton('Yearly'),
      ],
    );
  }

  Widget _buildPeriodButton(String period) {
    final theme = Theme.of(context);
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => selectedPeriod = period);
          print('Period changed to: $period');
          if (period == 'Yearly') {
            print('Fetching loans for yearly view...');
            await fetchAllLoans();
            print('Loans fetch completed');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManagementSection() {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthCode = now.month.toString().padLeft(2, '0');
    final yearCode = now.year.toString();

    final monthlyLoans = allLoans.where((loan) {
      final requestMonth = loan['requestMonth']?.toString() ?? '';
      return requestMonth.contains(yearCode) &&
          requestMonth.contains(monthCode);
    }).toList();

    final loansToDisplay =
        selectedPeriod == 'Yearly' ? filteredLoans : monthlyLoans;

    final noLoans = loansToDisplay.isEmpty;
    final headerText = selectedPeriod == 'Yearly'
        ? 'All Loan Requests'
        : 'All Loan Requests (Current Month)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headerText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 16),
        if (selectedPeriod == 'Yearly' && allLoans.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterLoans,
              decoration: InputDecoration(
                hintText: 'Search by loan number, name, amount or status...',
                prefixIcon:
                    Icon(Icons.search, color: theme.colorScheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterLoans('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        if (noLoans)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 48,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    allLoans.isEmpty
                        ? 'No loan requests found'
                        : 'No matching results found',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  if (allLoans.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Try adjusting your search criteria',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              Text(
                'Loaded: ${loansToDisplay.length} loans',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: loansToDisplay.length,
                itemBuilder: (context, index) {
                  final loan = loansToDisplay[index];
                  return _buildLoanCard(loan);
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    return _LoanCardAnimated(
      loan: loan,
      onBuildCard: _buildLoanCardContent,
      fetchUserProfileImage: _fetchUserProfileImage,
    );
  }

  Widget _buildLoanCardContent(
      Map<String, dynamic> loan, ThemeData theme, String? profileImageUrl) {
    final status = loan['status'] ?? 'PENDING';
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.schedule;
    if (status == 'APPROVED') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'NOT_ELIGIBLE' || status == 'REJECTED') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Loan # + Name | Status Badge (Vertical)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan #${loan['loanNo'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        loan['customerName'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Compact Status Badge (Vertical)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 0.7,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 10),
                      const SizedBox(height: 1),
                      SizedBox(
                        width: 28,
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withOpacity(0.08),
            ),
            const SizedBox(height: 9),
            // Three columns: Amount, Plan, Request Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItemCompact(
                  theme,
                  Icons.currency_rupee,
                  'Amount',
                  '₹${(loan['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                ),
                _buildDetailItemCompact(
                  theme,
                  Icons.calendar_today,
                  'Plan',
                  loan['plan']?.toString() ?? 'N/A',
                ),
                _buildDetailItemCompact(
                  theme,
                  Icons.date_range,
                  'Request Date',
                  loan['requestMonth']?.toString() ?? 'N/A',
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Sold by
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.onSurface.withOpacity(0.35),
                  size: 11,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    'Sold by: ${loan['soldBy'] ?? 'N/A'}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItemCompact(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: theme.colorScheme.onSurface.withOpacity(0.35),
                size: 10,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<String?> _fetchUserProfileImage(String userId) async {
    try {
      final token = await JwtStorage.getToken();
      final response = await http.get(
        Uri.parse('${ApplicationConstant.baseUrl}/api/user/profile/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['profileImage'];
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
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
          '${ApplicationConstant.baseUrl}/api/loan/import-excel',
          data: formData,
          options: dio.Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (context.mounted) {
          await _showAnimatedSuccessDialog('Excel file imported successfully!',
              'Data has been imported to the system');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Import failed: $e'),
                backgroundColor: Colors.red),
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
        '${ApplicationConstant.baseUrl}/api/loan/export-excel',
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
        await _showAnimatedSuccessDialog('Excel file downloaded successfully!',
            'File saved to device storage');
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
          SnackBar(
              content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
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

  void _showInvestmentListDialog() async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final month = now.month;
    final year = now.year;
    final token = await JwtStorage.getToken();

    print('Calling investment API with month: $month, year: $year');

    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading investments...'),
          ],
        ),
      ),
    );

    try {
      final uri = Uri.parse('${ApplicationConstant.baseUrl}/api/investment/all')
          .replace(
        queryParameters: {
          'month': month.toString(),
          'year': year.toString(),
        },
      );

      print('Final URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Received data: $data'); // Debug log
        _showInvestmentDataDialog(data, month, year, theme);
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        Get.snackbar(
            'Error', 'Failed to load investments: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Investment list error: $e');
      Get.snackbar('Error', 'Failed to load investments: $e');
    }
  }

  void _showInvestmentDataDialog(
      List<dynamic> data, int month, int year, ThemeData theme) {
    final monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet,
                color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Investment List - ${monthNames[month]} $year',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Custom table header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Partner Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Investment Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              // Table body
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: data.isEmpty
                      ? const Center(
                          child: Text(
                            'No investments found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: data.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final item = data[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item['createdBy'] ??
                                          item['partnerName'] ??
                                          item['username'] ??
                                          'N/A',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '₹${(item['inversmentAmt'] ?? item['amount'] ?? 0).toString()}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _downloadInvestmentPDF(month, year),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download as PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
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
  }

  Future<void> _downloadInvestmentPDF(int month, int year) async {
    try {
      final token = await JwtStorage.getToken();

      print('Downloading PDF for month: $month, year: $year');

      // Show loading indicator
      Get.dialog(
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      final url =
          '${ApplicationConstant.baseUrl}/api/investment/report/pdf?month=$month&year=$year';
      print('PDF URL: $url');

      final response = await Dio().get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
          validateStatus: (status) => status! < 600,
        ),
      );

      Get.back(); // Close loading dialog

      print('PDF Response status: ${response.statusCode}');
      print('PDF Response size: ${response.data?.length ?? 0} bytes');

      if (response.statusCode == 200) {
        if (response.data != null && response.data.length > 0) {
          final appDir = await getExternalStorageDirectory();
          final savePath =
              '${appDir!.path}/investment_report_${month}_$year.pdf';

          final file = File(savePath);
          await file.writeAsBytes(response.data);

          print('PDF saved to: $savePath');

          await _showAnimatedSuccessDialog('PDF downloaded successfully!',
              'Investment report saved to device');

          try {
            await OpenFile.open(savePath);
          } catch (e) {
            print('Error opening PDF: $e');
          }
        } else {
          Get.snackbar('Error', 'Empty PDF data received');
        }
      } else {
        print('PDF Download Error: ${response.statusCode} - ${response.data}');
        Get.snackbar('Error', 'Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      print('PDF Download error: $e');
      Get.snackbar('Error', 'Failed to download PDF: $e');
    }
  }

  Future<void> _showAnimatedSuccessDialog(String title, String message) async {
    await Get.dialog(
      _SuccessAnimationDialog(title: title, message: message),
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      transitionCurve: Curves.easeInOut,
    );
  }

  void _logout() async {
    await JwtStorage.clearAll();
    Get.offAllNamed('/role-select'); // Navigate to login
  }
}

/// Animated Success Dialog Widget
class _SuccessAnimationDialog extends StatefulWidget {
  final String title;
  final String message;

  const _SuccessAnimationDialog({required this.title, required this.message});

  @override
  State<_SuccessAnimationDialog> createState() =>
      _SuccessAnimationDialogState();
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

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _checkController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
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
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: ScaleTransition(
                scale: _checkAnimation,
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _textAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(_textAnimation),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Animated Loan Card Widget
class _LoanCardAnimated extends StatefulWidget {
  final Map<String, dynamic> loan;
  final Function(Map<String, dynamic>, ThemeData, String?) onBuildCard;
  final Future<String?> Function(String) fetchUserProfileImage;

  const _LoanCardAnimated({
    required this.loan,
    required this.onBuildCard,
    required this.fetchUserProfileImage,
  });

  @override
  State<_LoanCardAnimated> createState() => _LoanCardAnimatedState();
}

class _LoanCardAnimatedState extends State<_LoanCardAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _slideController.forward();

    // Fetch profile image
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final url = await widget.fetchUserProfileImage(
        widget.loan['soldBy']?.toString() ?? '',
      );
      if (mounted) {
        setState(() {
          profileImageUrl = url;
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child:
            widget.onBuildCard(widget.loan, theme, profileImageUrl) as Widget,
      ),
    );
  }
}
