import 'package:flutter/material.dart';
import 'text_rendering_fix.dart';
import 'rebuild_safe_widgets.dart';
import 'android_text_fix.dart';

/// Solução completa para problemas de corrupção de texto no Flutter
/// 
/// Este utilitário resolve os principais problemas de renderização de texto:
/// 1. Problemas com fontes customizadas
/// 2. Corrupção após hot reload/rebuild
/// 3. Problemas específicos do Android 12+
/// 4. Corrupção ao retornar do background
class TextCorruptionFix {
  static bool _isInitialized = false;
  
  /// Inicializa todas as correções de texto
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔤 Inicializando correções de corrupção de texto...');
      
      // 1. Inicializar correções gerais de renderização
      await TextRenderingFix.initialize();
      
      // 2. Inicializar correções específicas do Android
      await AndroidTextFix.initialize();
      
      _isInitialized = true;
      print('✅ Todas as correções de texto inicializadas');
      
    } catch (e) {
      print('❌ Erro ao inicializar correções de texto: $e');
    }
  }
  
  /// Retorna widget de texto seguro baseado na plataforma
  static Widget safeText(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    double? textScaleFactor,
    int? maxLines,
    String? semanticsLabel,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
  }) {
    // Se é Android 12+, usar widget específico
    if (AndroidTextFix.isAndroid12Plus) {
      return Android12SafeText(
        text,
        key: key,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaleFactor: textScaleFactor,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
      );
    }
    
    // Para outras plataformas, usar SafeText geral
    return SafeText(
      text,
      key: key,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
  
  /// Retorna ListTile seguro contra corrupção
  static Widget safeListTile({
    Key? key,
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    Widget? trailing,
    bool isThreeLine = false,
    bool? dense,
    VisualDensity? visualDensity,
    ShapeBorder? shape,
    EdgeInsetsGeometry? contentPadding,
    bool enabled = true,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    bool selected = false,
    Color? focusColor,
    Color? hoverColor,
    Color? splashColor,
    FocusNode? focusNode,
    bool autofocus = false,
    Color? tileColor,
    Color? selectedTileColor,
    bool? enableFeedback,
    double? horizontalTitleGap,
    double? minVerticalPadding,
    double? minLeadingWidth,
  }) {
    return RebuildSafeWidgets.listTile(
      key: key,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      isThreeLine: isThreeLine,
      dense: dense,
      visualDensity: visualDensity,
      shape: shape,
      contentPadding: contentPadding,
      enabled: enabled,
      onTap: onTap,
      onLongPress: onLongPress,
      selected: selected,
      focusColor: focusColor,
      hoverColor: hoverColor,
      splashColor: splashColor,
      focusNode: focusNode,
      autofocus: autofocus,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
      enableFeedback: enableFeedback,
      horizontalTitleGap: horizontalTitleGap,
      minVerticalPadding: minVerticalPadding,
      minLeadingWidth: minLeadingWidth,
    );
  }
  
  /// Aplica correções quando app volta do background
  static Future<void> onAppResumed() async {
    try {
      print('📱 Aplicando correções após retornar do background...');
      
      // Aplicar correções específicas do Android
      await AndroidTextFix.onAppResumed();
      
      // Limpar cache de renderização se necessário
      if (TextRenderingFix.hasFontIssues || AndroidTextFix.hasSystemUIFontIssues) {
        await TextRenderingFix.clearFontCache();
      }
      
    } catch (e) {
      print('❌ Erro ao aplicar correções de background: $e');
    }
  }
  
  /// Aplica correções quando app vai para background
  static Future<void> onAppPaused() async {
    try {
      await AndroidTextFix.onAppPaused();
    } catch (e) {
      print('❌ Erro ao aplicar correções de pause: $e');
    }
  }
  
  /// Força refresh de todos os widgets de texto
  static Future<void> forceTextRefresh() async {
    try {
      print('🔄 Forçando refresh de widgets de texto...');
      
      await TextRenderingFix.clearFontCache();
      
      if (AndroidTextFix.isAndroid12Plus) {
        await AndroidTextFix.onAppResumed();
      }
      
    } catch (e) {
      print('❌ Erro ao forçar refresh: $e');
    }
  }
  
  /// Retorna informações sobre problemas detectados
  static Map<String, dynamic> getDiagnosticInfo() {
    return {
      'initialized': _isInitialized,
      'has_font_issues': TextRenderingFix.hasFontIssues,
      'is_android_12_plus': AndroidTextFix.isAndroid12Plus,
      'has_system_ui_issues': AndroidTextFix.hasSystemUIFontIssues,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Widget principal que aplica todas as correções de texto
class TextCorruptionFixWrapper extends StatefulWidget {
  final Widget child;
  
  const TextCorruptionFixWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<TextCorruptionFixWrapper> createState() => _TextCorruptionFixWrapperState();
}

class _TextCorruptionFixWrapperState extends State<TextCorruptionFixWrapper> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFixes();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  Future<void> _initializeFixes() async {
    await TextCorruptionFix.initialize();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        TextCorruptionFix.onAppResumed();
        break;
      case AppLifecycleState.paused:
        TextCorruptionFix.onAppPaused();
        break;
      default:
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      onResume: () => TextCorruptionFix.onAppResumed(),
      onPause: () => TextCorruptionFix.onAppPaused(),
      child: widget.child,
    );
  }
}

/// Extensões para facilitar o uso
extension TextCorruptionFixExtension on String {
  /// Converte string em widget de texto seguro
  Widget toSafeText({
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    double? textScaleFactor,
    int? maxLines,
    String? semanticsLabel,
  }) {
    return TextCorruptionFix.safeText(
      this,
      key: key,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
    );
  }
}

/// Mixin completo para StatefulWidgets
mixin TextCorruptionFixMixin<T extends StatefulWidget> on State<T> 
    implements TextRenderingFixMixin<T>, Android12CompatMixin<T> {
  
  @override
  void initState() {
    super.initState();
    _initializeAllFixes();
  }
  
  void _initializeAllFixes() {
    // Aplicar todas as inicializações necessárias
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        onAppResumed();
        if (AndroidTextFix.isAndroid12Plus) {
          onAndroid12AppResumed();
        }
      }
    });
  }
  
  /// Método principal para ser chamado quando app volta do background
  void onAppResumed() {
    refreshTextIfNeeded();
  }
  
  /// Força refresh completo de texto
  void forceTextRefresh() {
    if (mounted) {
      setState(() {
        // Força rebuild
      });
    }
  }
}
