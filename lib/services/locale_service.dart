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
      // Settings
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

      // Navigation
      'home': {
        'en': 'Home',
        'es': 'Inicio',
        'fr': 'Accueil',
        'de': 'Startseite',
        'it': 'Home',
        'pt': 'Início',
        'zh': '首页',
        'ja': 'ホーム',
        'ko': '홈',
        'ar': 'الرئيسية',
      },
      'upload': {
        'en': 'Upload',
        'es': 'Subir',
        'fr': 'Télécharger',
        'de': 'Hochladen',
        'it': 'Carica',
        'pt': 'Carregar',
        'zh': '上传',
        'ja': 'アップロード',
        'ko': '업로드',
        'ar': 'رفع',
      },
      'optimize': {
        'en': 'Optimize',
        'es': 'Optimizar',
        'fr': 'Optimiser',
        'de': 'Optimieren',
        'it': 'Ottimizza',
        'pt': 'Otimizar',
        'zh': '优化',
        'ja': '最適化',
        'ko': '최적화',
        'ar': 'تحسين',
      },
      'results': {
        'en': 'Results',
        'es': 'Resultados',
        'fr': 'Résultats',
        'de': 'Ergebnisse',
        'it': 'Risultati',
        'pt': 'Resultados',
        'zh': '结果',
        'ja': '結果',
        'ko': '결과',
        'ar': 'النتائج',
      },

      // Upload Section
      'upload_menu_files': {
        'en': 'Upload Menu Files',
        'es': 'Subir Archivos de Menú',
        'fr': 'Télécharger les Fichiers de Menu',
        'de': 'Menü-Dateien Hochladen',
        'it': 'Carica File del Menu',
        'pt': 'Carregar Arquivos de Menu',
        'zh': '上传菜单文件',
        'ja': 'メニューファイルをアップロード',
        'ko': '메뉴 파일 업로드',
        'ar': 'رفع ملفات القائمة',
      },
      'upload_methods': {
        'en': 'Upload Methods',
        'es': 'Métodos de Subida',
        'fr': 'Méthodes de Téléchargement',
        'de': 'Upload-Methoden',
        'it': 'Metodi di Caricamento',
        'pt': 'Métodos de Carregamento',
        'zh': '上传方式',
        'ja': 'アップロード方法',
        'ko': '업로드 방법',
        'ar': 'طرق الرفع',
      },
      'camera': {
        'en': 'Camera',
        'es': 'Cámara',
        'fr': 'Caméra',
        'de': 'Kamera',
        'it': 'Fotocamera',
        'pt': 'Câmera',
        'zh': '相机',
        'ja': 'カメラ',
        'ko': '카메라',
        'ar': 'الكاميرا',
      },
      'take_photo': {
        'en': 'Take Photo',
        'es': 'Tomar Foto',
        'fr': 'Prendre une Photo',
        'de': 'Foto Aufnehmen',
        'it': 'Scatta Foto',
        'pt': 'Tirar Foto',
        'zh': '拍照',
        'ja': '写真を撮る',
        'ko': '사진 촬영',
        'ar': 'التقاط صورة',
      },
      'gallery': {
        'en': 'Gallery',
        'es': 'Galería',
        'fr': 'Galerie',
        'de': 'Galerie',
        'it': 'Galleria',
        'pt': 'Galeria',
        'zh': '图库',
        'ja': 'ギャラリー',
        'ko': '갤러리',
        'ar': 'المعرض',
      },
      'photos': {
        'en': 'Photos',
        'es': 'Fotos',
        'fr': 'Photos',
        'de': 'Fotos',
        'it': 'Foto',
        'pt': 'Fotos',
        'zh': '照片',
        'ja': '写真',
        'ko': '사진',
        'ar': 'الصور',
      },
      'files': {
        'en': 'Files',
        'es': 'Archivos',
        'fr': 'Fichiers',
        'de': 'Dateien',
        'it': 'File',
        'pt': 'Arquivos',
        'zh': '文件',
        'ja': 'ファイル',
        'ko': '파일',
        'ar': 'الملفات',
      },
      'pdf_image': {
        'en': 'PDF/Image',
        'es': 'PDF/Imagen',
        'fr': 'PDF/Image',
        'de': 'PDF/Bild',
        'it': 'PDF/Immagine',
        'pt': 'PDF/Imagem',
        'zh': 'PDF/图片',
        'ja': 'PDF/画像',
        'ko': 'PDF/이미지',
        'ar': 'PDF/صورة',
      },
      'menu_url': {
        'en': 'Menu URL',
        'es': 'URL del Menú',
        'fr': 'URL du Menu',
        'de': 'Menü-URL',
        'it': 'URL del Menu',
        'pt': 'URL do Menu',
        'zh': '菜单链接',
        'ja': 'メニューURL',
        'ko': '메뉴 URL',
        'ar': 'رابط القائمة',
      },
      'enter_menu_website_url': {
        'en': 'Enter menu website URL',
        'es': 'Ingresa la URL del sitio web del menú',
        'fr': 'Entrez l\'URL du site web du menu',
        'de': 'Menü-Website-URL eingeben',
        'it': 'Inserisci l\'URL del sito web del menu',
        'pt': 'Digite a URL do site do menu',
        'zh': '输入菜单网站链接',
        'ja': 'メニューのウェブサイトURLを入力',
        'ko': '메뉴 웹사이트 URL 입력',
        'ar': 'أدخل رابط موقع القائمة',
      },

      // Optimization Section
      'optimization_goals': {
        'en': 'Optimization Goals',
        'es': 'Objetivos de Optimización',
        'fr': 'Objectifs d\'Optimisation',
        'de': 'Optimierungsziele',
        'it': 'Obiettivi di Ottimizzazione',
        'pt': 'Objetivos de Otimização',
        'zh': '优化目标',
        'ja': '最適化目標',
        'ko': '최적화 목표',
        'ar': 'أهداف التحسين',
      },
      'optimization_goal': {
        'en': 'Optimization Goal',
        'es': 'Objetivo de Optimización',
        'fr': 'Objectif d\'Optimisation',
        'de': 'Optimierungsziel',
        'it': 'Obiettivo di Ottimizzazione',
        'pt': 'Objetivo de Otimização',
        'zh': '优化目标',
        'ja': '最適化目標',
        'ko': '최적화 목표',
        'ar': 'هدف التحسين',
      },
      'dietary_constraints': {
        'en': 'Dietary Constraints',
        'es': 'Restricciones Dietéticas',
        'fr': 'Contraintes Alimentaires',
        'de': 'Ernährungseinschränkungen',
        'it': 'Vincoli Dietetici',
        'pt': 'Restrições Alimentares',
        'zh': '饮食限制',
        'ja': '食事制限',
        'ko': '식이 제약',
        'ar': 'القيود الغذائية',
      },
      'budget': {
        'en': 'Budget',
        'es': 'Presupuesto',
        'fr': 'Budget',
        'de': 'Budget',
        'it': 'Budget',
        'pt': 'Orçamento',
        'zh': '预算',
        'ja': '予算',
        'ko': '예산',
        'ar': 'الميزانية',
      },
      'restaurant_information': {
        'en': 'Restaurant Information',
        'es': 'Información del Restaurante',
        'fr': 'Informations sur le Restaurant',
        'de': 'Restaurant-Informationen',
        'it': 'Informazioni sul Ristorante',
        'pt': 'Informações do Restaurante',
        'zh': '餐厅信息',
        'ja': 'レストラン情報',
        'ko': '레스토랑 정보',
        'ar': 'معلومات المطعم',
      },
      'set_optimization_criteria': {
        'en': 'Set Optimization Criteria',
        'es': 'Establecer Criterios de Optimización',
        'fr': 'Définir les Critères d\'Optimisation',
        'de': 'Optimierungskriterien Festlegen',
        'it': 'Imposta Criteri di Ottimizzazione',
        'pt': 'Definir Critérios de Otimização',
        'zh': '设置优化标准',
        'ja': '最適化基準を設定',
        'ko': '최적화 기준 설정',
        'ar': 'تحديد معايير التحسين',
      },

      // Results Section
      'rankings': {
        'en': 'Rankings',
        'es': 'Clasificaciones',
        'fr': 'Classements',
        'de': 'Ranglisten',
        'it': 'Classifiche',
        'pt': 'Classificações',
        'zh': '排名',
        'ja': 'ランキング',
        'ko': '순위',
        'ar': 'التصنيفات',
      },
      'analysis': {
        'en': 'Analysis',
        'es': 'Análisis',
        'fr': 'Analyse',
        'de': 'Analyse',
        'it': 'Analisi',
        'pt': 'Análise',
        'zh': '分析',
        'ja': '分析',
        'ko': '분석',
        'ar': 'التحليل',
      },
      'items_analyzed': {
        'en': 'Items Analyzed',
        'es': 'Elementos Analizados',
        'fr': 'Éléments Analysés',
        'de': 'Analysierte Elemente',
        'it': 'Elementi Analizzati',
        'pt': 'Itens Analisados',
        'zh': '分析项目',
        'ja': '分析されたアイテム',
        'ko': '분석된 항목',
        'ar': 'العناصر المحللة',
      },
      'average_score': {
        'en': 'Average Score',
        'es': 'Puntuación Promedio',
        'fr': 'Score Moyen',
        'de': 'Durchschnittliche Bewertung',
        'it': 'Punteggio Medio',
        'pt': 'Pontuação Média',
        'zh': '平均分数',
        'ja': '平均スコア',
        'ko': '평균 점수',
        'ar': 'النتيجة المتوسطة',
      },
      'average_price': {
        'en': 'Average Price',
        'es': 'Precio Promedio',
        'fr': 'Prix Moyen',
        'de': 'Durchschnittspreis',
        'it': 'Prezzo Medio',
        'pt': 'Preço Médio',
        'zh': '平均价格',
        'ja': '平均価格',
        'ko': '평균 가격',
        'ar': 'متوسط السعر',
      },
      'median_price': {
        'en': 'Median Price',
        'es': 'Precio Mediano',
        'fr': 'Prix Médian',
        'de': 'Median-Preis',
        'it': 'Prezzo Mediano',
        'pt': 'Preço Mediano',
        'zh': '中位价格',
        'ja': '中央値価格',
        'ko': '중간 가격',
        'ar': 'السعر المتوسط',
      },

      // Common Actions
      'optional': {
        'en': 'Optional',
        'es': 'Opcional',
        'fr': 'Optionnel',
        'de': 'Optional',
        'it': 'Opzionale',
        'pt': 'Opcional',
        'zh': '可选',
        'ja': 'オプション',
        'ko': '선택사항',
        'ar': 'اختياري',
      },
      'clear_all': {
        'en': 'Clear All',
        'es': 'Borrar Todo',
        'fr': 'Effacer Tout',
        'de': 'Alle Löschen',
        'it': 'Cancella Tutto',
        'pt': 'Limpar Tudo',
        'zh': '清除全部',
        'ja': 'すべてクリア',
        'ko': '모두 지우기',
        'ar': 'مسح الكل',
      },
      'selected_files': {
        'en': 'Selected Files',
        'es': 'Archivos Seleccionados',
        'fr': 'Fichiers Sélectionnés',
        'de': 'Ausgewählte Dateien',
        'it': 'File Selezionati',
        'pt': 'Arquivos Selecionados',
        'zh': '已选文件',
        'ja': '選択されたファイル',
        'ko': '선택된 파일',
        'ar': 'الملفات المحددة',
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