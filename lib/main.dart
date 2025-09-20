import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/auth0_login_page.dart';
import 'widgets/data_caching_test_page.dart';
import 'core/dependency_injection.dart';

void main() {
  runApp(const MenuOptimizerApp());
}

class MenuOptimizerApp extends StatelessWidget {
  const MenuOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: DependencyInjection.providers,
      child: MaterialApp(
        title: 'Menu Optimizer Pro - PennApps 2025',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/welcome',
        routes: {
          '/welcome': (context) => WelcomeScreen(),
          '/login': (context) => const Auth0LoginPage(),
          '/home': (context) => const HomeScreen(),
          '/test-caching': (context) => const DataCachingTestPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
