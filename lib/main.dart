import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/calculator_screen.dart';
import 'state/calculator_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(CalcoloSmartApp(prefs: prefs));
}

class CalcoloSmartApp extends StatelessWidget {
  const CalcoloSmartApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CalculatorController>(
      create: (_) => CalculatorController(prefs),
      child: Consumer<CalculatorController>(
        builder: (BuildContext context, CalculatorController controller, _) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: controller.isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: controller.isDark
                  ? AppColors.darkBg
                  : AppColors.lightBg,
              systemNavigationBarIconBrightness: controller.isDark
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );
          return MaterialApp(
            title: 'Calcolo Smart',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: controller.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const CalculatorScreen(),
          );
        },
      ),
    );
  }
}
