import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/auth0_login_page.dart';
import 'core/dependency_injection.dart';
import 'services/theme_service.dart';
import 'services/locale_service.dart';

void main() {
  runApp(const MenuOptimizerApp());
}

class MenuOptimizerApp extends StatelessWidget {
  const MenuOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: DependencyInjection.providers,
      child: Consumer2<ThemeService, LocaleService>(
        builder: (context, themeService, localeService, child) {
          return MaterialApp(
            title: 'Menu Max - PennApps 2025',
            theme: ThemeService.lightTheme,
            darkTheme: ThemeService.darkTheme,
            themeMode: themeService.themeMode,
            locale: localeService.locale,
            supportedLocales: LocaleService.supportedLocales.map((e) => e.locale).toList(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            initialRoute: '/login',
            routes: {
              '/login': (context) => const Auth0LoginPage(),
              '/welcome': (context) => const WelcomeScreen(),
              '/home': (context) => const HomeScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
