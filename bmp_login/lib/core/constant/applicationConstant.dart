import 'package:bmp_login/feature/authentication/screen/login_screen.dart';
import 'package:bmp_login/feature/splash/splash_screen.dart';
import 'package:bmp_login/presentation/admin_dashboard.dart';
import 'package:bmp_login/presentation/pages/user_dasboard.dart';
import 'package:bmp_login/presentation/screen/loan_detail_screen.dart';
import 'package:bmp_login/presentation/screen/loan_request_form_screen.dart';
import 'package:bmp_login/presentation/screen/loan_request_list_screen.dart';
import 'package:get/get.dart';

class ApplicationConstant {
  static const splash = "/splash";
  static const login = "/login";
  static const adminDashboard = "/admin-dashboard";
  static const userDashboard = "/user-dashboard";
  static const LoanRequestList = "/loan-request-list";
  static const LoanRequestForm = "/loan-request-form";
  static const LoanDetail = "/loan-detail";

  static const baseUrl = "http://10.0.2.2:8080";
  static const loginApi = "/user/login";
  static const register = "/api/auth/register";
  static const logout = "/user/logout";
  static const nextLoan = "/api/loan/next-loan_number";

  static final routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: adminDashboard, page: () => const AdminDashboard()),
    GetPage(name: userDashboard, page: () => const UserDasboard()),
    GetPage(name: LoanRequestList, page: () => const LoanRequestListScreen()),
    GetPage(name: LoanRequestForm, page: () => const LoanRequestFormScreen()),
    GetPage(name: LoanDetail, page: () => const LoanDetailScreen()),
  ];
}
