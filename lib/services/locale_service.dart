import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService with ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = const Locale('en', 'US');

  Locale get locale => _locale;

  static const List<LocaleOption> supportedLocales = [
    LocaleOption(
      locale: Locale('en', 'US'),
      name: 'English',
      flag: '🇺🇸',
      nativeName: 'English',
    ),
    LocaleOption(
      locale: Locale('es', 'ES'),
      name: 'Spanish',
      flag: '🇪🇸',
      nativeName: 'Español',
    ),
    LocaleOption(
      locale: Locale('fr', 'FR'),
      name: 'French',
      flag: '🇫🇷',
      nativeName: 'Français',
    ),
    LocaleOption(
      locale: Locale('de', 'DE'),
      name: 'German',
      flag: '🇩🇪',
      nativeName: 'Deutsch',
    ),
    LocaleOption(
      locale: Locale('it', 'IT'),
      name: 'Italian',
      flag: '🇮🇹',
      nativeName: 'Italiano',
    ),
    LocaleOption(
      locale: Locale('pt', 'PT'),
      name: 'Portuguese',
      flag: '🇵🇹',
      nativeName: 'Português',
    ),
    LocaleOption(
      locale: Locale('zh', 'CN'),
      name: 'Chinese',
      flag: '🇨🇳',
      nativeName: '中文',
    ),
    LocaleOption(
      locale: Locale('ja', 'JP'),
      name: 'Japanese',
      flag: '🇯🇵',
      nativeName: '日本語',
    ),
    LocaleOption(
      locale: Locale('ko', 'KR'),
      name: 'Korean',
      flag: '🇰🇷',
      nativeName: '한국어',
    ),
    LocaleOption(
      locale: Locale('ar', 'SA'),
      name: 'Arabic',
      flag: '🇸🇦',
      nativeName: 'العربية',
    ),
  ];

  LocaleService() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = prefs.getString(_localeKey);

      if (localeString != null && localeString.isNotEmpty) {
        final parts = localeString.split('_');
        if (parts.length == 2) {
          final testLocale = Locale(parts[0], parts[1]);

          // Check if the loaded locale is supported
          final isSupported = supportedLocales.any(
            (option) => option.locale == testLocale,
          );

          if (isSupported) {
            _locale = testLocale;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    try {
      _locale = newLocale;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, '${newLocale.languageCode}_${newLocale.countryCode}');

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  LocaleOption get currentLocaleOption {
    return supportedLocales.firstWhere(
      (option) => option.locale == _locale,
      orElse: () => supportedLocales.first,
    );
  }

  String getLocalizedString(String key) {
    // Basic localization - in a real app you'd use a proper i18n solution
    final translations = <String, Map<String, String>>{
      'settings': {
        'en': 'Settings',
        'es': 'Configuración',
        'fr': 'Paramètres',
        'de': 'Einstellungen',
        'it': 'Impostazioni',
        'pt': 'Configurações',
        'zh': '设置',
        'ja': '設定',
        'ko': '설정',
        'ar': 'إعدادات',
      },
      'dark_mode': {
        'en': 'Dark Mode',
        'es': 'Modo Oscuro',
        'fr': 'Mode Sombre',
        'de': 'Dunkler Modus',
        'it': 'Modalità Scura',
        'pt': 'Modo Escuro',
        'zh': '深色模式',
        'ja': 'ダークモード',
        'ko': '다크 모드',
        'ar': 'الوضع المظلم',
      },
      'language': {
        'en': 'Language',
        'es': 'Idioma',
        'fr': 'Langue',
        'de': 'Sprache',
        'it': 'Lingua',
        'pt': 'Idioma',
        'zh': '语言',
        'ja': '言語',
        'ko': '언어',
        'ar': 'اللغة',
      },
      'close': {
        'en': 'Close',
        'es': 'Cerrar',
        'fr': 'Fermer',
        'de': 'Schließen',
        'it': 'Chiudi',
        'pt': 'Fechar',
        'zh': '关闭',
        'ja': '閉じる',
        'ko': '닫기',
        'ar': 'إغلاق',
      },
    };

    final langCode = _locale.languageCode;
    return translations[key]?[langCode] ?? translations[key]?['en'] ?? key;
  }
}

class LocaleOption {
  final Locale locale;
  final String name;
  final String flag;
  final String nativeName;

  const LocaleOption({
    required this.locale,
    required this.name,
    required this.flag,
    required this.nativeName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocaleOption && other.locale == locale;
  }

  @override
  int get hashCode => locale.hashCode;
}