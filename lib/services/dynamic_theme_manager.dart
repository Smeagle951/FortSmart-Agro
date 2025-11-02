import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_preferences.dart';
import '../utils/responsive_screen_utils.dart';

/// Gerenciador de temas dinâmicos responsivos
class DynamicThemeManager extends ChangeNotifier {
  static const String _preferencesKey = 'user_preferences';
  
  UserPreferences _preferences = const UserPreferences();
  SharedPreferences? _prefs;
  
  UserPreferences get preferences => _preferences;
  
  /// Inicializa o gerenciador
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPreferences();
  }
  
  /// Carrega preferências salvas
  Future<void> _loadPreferences() async {
    if (_prefs == null) return;
    
    final String? preferencesJson = _prefs!.getString(_preferencesKey);
    if (preferencesJson != null) {
      try {
        final Map<String, dynamic> preferencesMap = jsonDecode(preferencesJson);
        _preferences = UserPreferences.fromMap(preferencesMap);
        notifyListeners();
      } catch (e) {
        // Se houver erro, usa preferências padrão
        _preferences = const UserPreferences();
      }
    }
  }
  
  /// Salva preferências
  Future<void> _savePreferences() async {
    if (_prefs == null) return;
    
    final String preferencesJson = jsonEncode(_preferences.toMap());
    await _prefs!.setString(_preferencesKey, preferencesJson);
  }
  
  /// Atualiza preferências
  Future<void> updatePreferences(UserPreferences newPreferences) async {
    _preferences = newPreferences;
    await _savePreferences();
    notifyListeners();
  }
  
  /// Atualiza tema
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    _preferences = _preferences.copyWith(themeMode: themeMode);
    await _savePreferences();
    notifyListeners();
  }
  
  /// Atualiza esquema de cores
  Future<void> updateColorScheme(ColorSchemeType colorScheme) async {
    _preferences = _preferences.copyWith(colorScheme: colorScheme);
    await _savePreferences();
    notifyListeners();
  }
  
  /// Atualiza alto contraste
  Future<void> updateHighContrast(bool highContrast) async {
    _preferences = _preferences.copyWith(highContrast: highContrast);
    await _savePreferences();
    notifyListeners();
  }
  
  /// Atualiza tamanho da fonte
  Future<void> updateFontSize(FontSizeLevel fontSizeLevel) async {
    _preferences = _preferences.copyWith(fontSizeLevel: fontSizeLevel);
    await _savePreferences();
    notifyListeners();
  }
  
  /// Atualiza contexto do usuário
  Future<void> updateUserContext(UserContext userContext) async {
    _preferences = _preferences.copyWith(userContext: userContext);
    await _savePreferences();
    notifyListeners();
  }
  
  /// Atualiza otimização para campo
  Future<void> updateFieldOptimized(bool fieldOptimized) async {
    _preferences = _preferences.copyWith(fieldOptimized: fieldOptimized);
    await _savePreferences();
    notifyListeners();
  }
  
  /// Aplica configurações de acessibilidade
  Future<void> applyAccessibilitySettings() async {
    _preferences = UserPreferences.accessibilityOptimized();
    await _savePreferences();
    notifyListeners();
  }
  
  /// Aplica configurações para campo
  Future<void> applyFieldSettings() async {
    _preferences = UserPreferences.fieldOptimized();
    await _savePreferences();
    notifyListeners();
  }
  
  /// Aplica configurações para escritório
  Future<void> applyOfficeSettings() async {
    _preferences = UserPreferences.officeOptimized();
    await _savePreferences();
    notifyListeners();
  }
  
  /// Obtém tema baseado nas preferências
  ThemeData getTheme(BuildContext context) {
    final bool isDark = _preferences.themeMode == ThemeMode.dark ||
        (_preferences.themeMode == ThemeMode.system && 
         MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    final ColorScheme colorScheme = _getColorScheme(context, isDark);
    final TextTheme textTheme = _getTextTheme(context);
    
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: _getAppBarTheme(colorScheme),
      cardTheme: _getCardTheme(colorScheme),
      elevatedButtonTheme: _getElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _getOutlinedButtonTheme(colorScheme),
      textButtonTheme: _getTextButtonTheme(colorScheme),
      inputDecorationTheme: _getInputDecorationTheme(colorScheme),
      dividerTheme: _getDividerTheme(colorScheme),
      iconTheme: _getIconTheme(colorScheme),
      primaryTextTheme: textTheme,
    );
  }
  
  /// Obtém esquema de cores baseado nas preferências
  ColorScheme _getColorScheme(BuildContext context, bool isDark) {
    final ColorSchemeType schemeType = _preferences.colorScheme;
    
    switch (schemeType) {
      case ColorSchemeType.adaptive:
        return _getAdaptiveColorScheme(context, isDark);
      case ColorSchemeType.highContrast:
        return _getHighContrastColorScheme(isDark);
      case ColorSchemeType.nature:
        return _getNatureColorScheme(isDark);
      case ColorSchemeType.professional:
        return _getProfessionalColorScheme(isDark);
      case ColorSchemeType.custom:
        return _getCustomColorScheme(isDark);
    }
  }
  
  /// Esquema de cores adaptativo
  ColorScheme _getAdaptiveColorScheme(BuildContext context, bool isDark) {
    final UserContext userContext = _preferences.userContext;
    
    switch (userContext) {
      case UserContext.field:
        return isDark 
            ? _getFieldDarkColorScheme()
            : _getFieldLightColorScheme();
      case UserContext.office:
        return isDark 
            ? _getOfficeDarkColorScheme()
            : _getOfficeLightColorScheme();
      case UserContext.laboratory:
        return isDark 
            ? _getLabDarkColorScheme()
            : _getLabLightColorScheme();
      case UserContext.warehouse:
        return isDark 
            ? _getWarehouseDarkColorScheme()
            : _getWarehouseLightColorScheme();
      default:
        return isDark 
            ? _getDefaultDarkColorScheme()
            : _getDefaultLightColorScheme();
    }
  }
  
  /// Esquema de cores de alto contraste
  ColorScheme _getHighContrastColorScheme(bool isDark) {
    if (isDark) {
      return const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.yellow,
        onSecondary: Colors.black,
        error: Colors.red,
        onError: Colors.white,
        surface: Colors.black,
        onSurface: Colors.white,
        background: Colors.black,
        onBackground: Colors.white,
      );
    } else {
      return const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.blue,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        background: Colors.white,
        onBackground: Colors.black,
      );
    }
  }
  
  /// Esquema de cores naturais
  ColorScheme _getNatureColorScheme(bool isDark) {
    if (isDark) {
      return const ColorScheme.dark(
        primary: Color(0xFF4CAF50), // Verde
        onPrimary: Colors.white,
        secondary: Color(0xFF8BC34A), // Verde claro
        onSecondary: Colors.black,
        surface: Color(0xFF1B5E20), // Verde escuro
        onSurface: Colors.white,
      );
    } else {
      return const ColorScheme.light(
        primary: Color(0xFF2E7D32), // Verde escuro
        onPrimary: Colors.white,
        secondary: Color(0xFF4CAF50), // Verde
        onSecondary: Colors.white,
        surface: Color(0xFFE8F5E8), // Verde muito claro
        onSurface: Color(0xFF1B5E20), // Verde escuro
      );
    }
  }
  
  /// Esquema de cores profissionais
  ColorScheme _getProfessionalColorScheme(bool isDark) {
    if (isDark) {
      return const ColorScheme.dark(
        primary: Color(0xFF1976D2), // Azul
        onPrimary: Colors.white,
        secondary: Color(0xFF42A5F5), // Azul claro
        onSecondary: Colors.black,
        surface: Color(0xFF0D47A1), // Azul escuro
        onSurface: Colors.white,
      );
    } else {
      return const ColorScheme.light(
        primary: Color(0xFF1565C0), // Azul escuro
        onPrimary: Colors.white,
        secondary: Color(0xFF1976D2), // Azul
        onSecondary: Colors.white,
        surface: Color(0xFFE3F2FD), // Azul muito claro
        onSurface: Color(0xFF0D47A1), // Azul escuro
      );
    }
  }
  
  /// Esquema de cores personalizado
  ColorScheme _getCustomColorScheme(bool isDark) {
    // Implementar cores personalizadas baseadas nas preferências
    return isDark ? _getDefaultDarkColorScheme() : _getDefaultLightColorScheme();
  }
  
  /// Esquemas de cores específicos por contexto
  
  ColorScheme _getFieldLightColorScheme() {
    return const ColorScheme.light(
      primary: Color(0xFF2E7D32), // Verde escuro
      onPrimary: Colors.white,
      secondary: Color(0xFFFF9800), // Laranja
      onSecondary: Colors.white,
      surface: Color(0xFFF1F8E9), // Verde muito claro
      onSurface: Color(0xFF1B5E20), // Verde escuro
      background: Color(0xFFF9FBE7), // Verde muito claro
      onBackground: Color(0xFF1B5E20), // Verde escuro
    );
  }
  
  ColorScheme _getFieldDarkColorScheme() {
    return const ColorScheme.dark(
      primary: Color(0xFF4CAF50), // Verde
      onPrimary: Colors.black,
      secondary: Color(0xFFFFB74D), // Laranja claro
      onSecondary: Colors.black,
      surface: Color(0xFF1B5E20), // Verde escuro
      onSurface: Colors.white,
      background: Color(0xFF0D4F1C), // Verde muito escuro
      onBackground: Colors.white,
    );
  }
  
  ColorScheme _getOfficeLightColorScheme() {
    return const ColorScheme.light(
      primary: Color(0xFF1565C0), // Azul escuro
      onPrimary: Colors.white,
      secondary: Color(0xFF1976D2), // Azul
      onSecondary: Colors.white,
      surface: Color(0xFFE3F2FD), // Azul muito claro
      onSurface: Color(0xFF0D47A1), // Azul escuro
    );
  }
  
  ColorScheme _getOfficeDarkColorScheme() {
    return const ColorScheme.dark(
      primary: Color(0xFF42A5F5), // Azul claro
      onPrimary: Colors.black,
      secondary: Color(0xFF64B5F6), // Azul mais claro
      onSecondary: Colors.black,
      surface: Color(0xFF0D47A1), // Azul escuro
      onSurface: Colors.white,
    );
  }
  
  ColorScheme _getLabLightColorScheme() {
    return const ColorScheme.light(
      primary: Color(0xFF7B1FA2), // Roxo
      onPrimary: Colors.white,
      secondary: Color(0xFF9C27B0), // Roxo claro
      onSecondary: Colors.white,
      surface: Color(0xFFF3E5F5), // Roxo muito claro
      onSurface: Color(0xFF4A148C), // Roxo escuro
    );
  }
  
  ColorScheme _getLabDarkColorScheme() {
    return const ColorScheme.dark(
      primary: Color(0xFFBA68C8), // Roxo claro
      onPrimary: Colors.black,
      secondary: Color(0xFFCE93D8), // Roxo mais claro
      onSecondary: Colors.black,
      surface: Color(0xFF4A148C), // Roxo escuro
      onSurface: Colors.white,
    );
  }
  
  ColorScheme _getWarehouseLightColorScheme() {
    return const ColorScheme.light(
      primary: Color(0xFF5D4037), // Marrom
      onPrimary: Colors.white,
      secondary: Color(0xFF8D6E63), // Marrom claro
      onSecondary: Colors.white,
      surface: Color(0xFFEFEBE9), // Marrom muito claro
      onSurface: Color(0xFF3E2723), // Marrom escuro
    );
  }
  
  ColorScheme _getWarehouseDarkColorScheme() {
    return const ColorScheme.dark(
      primary: Color(0xFFA1887F), // Marrom claro
      onPrimary: Colors.black,
      secondary: Color(0xFFBCAAA4), // Marrom mais claro
      onSecondary: Colors.black,
      surface: Color(0xFF3E2723), // Marrom escuro
      onSurface: Colors.white,
    );
  }
  
  ColorScheme _getDefaultLightColorScheme() {
    return const ColorScheme.light();
  }
  
  ColorScheme _getDefaultDarkColorScheme() {
    return const ColorScheme.dark();
  }
  
  /// Obtém tema de texto baseado nas preferências
  TextTheme _getTextTheme(BuildContext context) {
    final double baseFontSize = 16.0;
    final double fontSizeMultiplier = _getFontSizeMultiplier();
    final FontWeight fontWeight = _preferences.boldText ? FontWeight.bold : FontWeight.normal;
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 3.0 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      displayMedium: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 2.5 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      displaySmall: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 2.0 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      headlineLarge: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 1.75 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      headlineMedium: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 1.5 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      headlineSmall: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 1.25 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      titleLarge: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 1.125 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      titleMedium: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      titleSmall: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 0.875 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      bodyLarge: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      bodyMedium: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 0.875 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      bodySmall: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 0.75 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      labelLarge: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 0.875 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      labelMedium: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 0.75 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
      labelSmall: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(context, baseFontSize * 0.625 * fontSizeMultiplier),
        fontWeight: fontWeight,
      ),
    );
  }
  
  /// Obtém multiplicador de tamanho da fonte
  double _getFontSizeMultiplier() {
    switch (_preferences.fontSizeLevel) {
      case FontSizeLevel.extraSmall:
        return 0.8;
      case FontSizeLevel.small:
        return 0.9;
      case FontSizeLevel.medium:
        return 1.0;
      case FontSizeLevel.large:
        return 1.2;
      case FontSizeLevel.extraLarge:
        return 1.4;
      case FontSizeLevel.huge:
        return 1.6;
    }
  }
  
  /// Obtém tema da AppBar
  AppBarTheme _getAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: _preferences.highContrast ? 4.0 : 2.0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(null, 20.0),
        fontWeight: _preferences.boldText ? FontWeight.bold : FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }
  
  /// Obtém tema do Card
  CardTheme _getCardTheme(ColorScheme colorScheme) {
    return CardTheme(
      color: colorScheme.surface,
      elevation: _preferences.highContrast ? 4.0 : 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(null, 12.0)),
        side: _preferences.highContrast 
            ? BorderSide(color: colorScheme.outline, width: 1.0)
            : BorderSide.none,
      ),
    );
  }
  
  /// Obtém tema do ElevatedButton
  ElevatedButtonThemeData _getElevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: _preferences.highContrast ? 4.0 : 2.0,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveScreenUtils.scale(null, 16.0),
          vertical: ResponsiveScreenUtils.scale(null, 12.0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(null, 8.0)),
        ),
        textStyle: TextStyle(
          fontSize: ResponsiveScreenUtils.scale(null, 16.0),
          fontWeight: _preferences.boldText ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }
  
  /// Obtém tema do OutlinedButton
  OutlinedButtonThemeData _getOutlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(
          color: colorScheme.primary,
          width: _preferences.highContrast ? 2.0 : 1.0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveScreenUtils.scale(null, 16.0),
          vertical: ResponsiveScreenUtils.scale(null, 12.0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(null, 8.0)),
        ),
        textStyle: TextStyle(
          fontSize: ResponsiveScreenUtils.scale(null, 16.0),
          fontWeight: _preferences.boldText ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }
  
  /// Obtém tema do TextButton
  TextButtonThemeData _getTextButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveScreenUtils.scale(null, 16.0),
          vertical: ResponsiveScreenUtils.scale(null, 12.0),
        ),
        textStyle: TextStyle(
          fontSize: ResponsiveScreenUtils.scale(null, 16.0),
          fontWeight: _preferences.boldText ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }
  
  /// Obtém tema do InputDecoration
  InputDecorationTheme _getInputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(null, 8.0)),
        borderSide: BorderSide(
          color: colorScheme.outline,
          width: _preferences.highContrast ? 2.0 : 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(null, 8.0)),
        borderSide: BorderSide(
          color: colorScheme.outline,
          width: _preferences.highContrast ? 2.0 : 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ResponsiveScreenUtils.scale(null, 8.0)),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: _preferences.highContrast ? 3.0 : 2.0,
        ),
      ),
      labelStyle: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(null, 16.0),
        fontWeight: _preferences.boldText ? FontWeight.bold : FontWeight.normal,
        color: colorScheme.onSurface,
      ),
      hintStyle: TextStyle(
        fontSize: ResponsiveScreenUtils.scale(null, 16.0),
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }
  
  /// Obtém tema do Divider
  DividerThemeData _getDividerTheme(ColorScheme colorScheme) {
    return DividerThemeData(
      color: colorScheme.outline,
      thickness: _preferences.highContrast ? 2.0 : 1.0,
      space: ResponsiveScreenUtils.scale(null, 16.0),
    );
  }
  
  /// Obtém tema do Icon
  IconThemeData _getIconTheme(ColorScheme colorScheme) {
    return IconThemeData(
      color: colorScheme.onSurface,
      size: ResponsiveScreenUtils.scale(null, 24.0),
    );
  }
}
