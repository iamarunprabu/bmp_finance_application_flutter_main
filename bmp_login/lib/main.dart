import 'package:bmp_login/config/InitialBinding%20.dart';
import 'package:bmp_login/config/app_theme.dart';
import 'package:bmp_login/core/constant/applicationConstant.dart';
import 'package:bmp_login/feature/authentication/screen/role_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: ApplicationConstant.splash,
      getPages: ApplicationConstant.routes,
    );
  }
}
