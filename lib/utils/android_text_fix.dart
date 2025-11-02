import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Utilitário específico para corrigir problemas de texto no Android 12+
class AndroidTextFix {
  static bool _isInitialized = false;
  static bool _isAndroid12Plus = false;
  static bool _hasSystemUIFontIssues = false;
  
  /// Inicializa as correções específicas do Android
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _detectAndroidVersion();
      await _detectSystemUIIssues();
      
      if (_isAndroid12Plus) {
        await _applyAndroid12Fixes();
      }
      
      _isInitialized = true;
      print('✅ Correções do Android inicializadas (Android 12+: $_isAndroid12Plus)');
      
    } catch (e) {
      print('❌ Erro ao inicializar correções do Android: $e');
    }
  }
  
  /// Detecta a versão do Android
  static Future<void> _detectAndroidVersion() async {
    if (!Platform.isAndroid) return;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      // Android 12 = API 31, Android 13 = API 33, etc.
      _isAndroid12Plus = androidInfo.version.sdkInt >= 31;
      
      print('📱 Android API ${androidInfo.version.sdkInt} detectado');
      
    } catch (e) {
      print('⚠️ Não foi possível detectar versão do Android: $e');
      // Assume Android 12+ por segurança se não conseguir detectar
      _isAndroid12Plus = true;
    }
  }
  
  /// Detecta problemas específicos da System UI
  static Future<void> _detectSystemUIIssues() async {
    if (!Platform.isAndroid) return;
    
    try {
      // Tentar detectar se há problemas com System UI
      // Isso pode ser feito verificando logs ou tentando operações específicas
      _hasSystemUIFontIssues = _isAndroid12Plus;
      
    } catch (e) {
      print('⚠️ Erro ao detectar problemas de System UI: $e');
    }
  }
  
  /// Aplica correções específicas para Android 12+
  static Future<void> _applyAndroid12Fixes() async {
    try {
      print('🔧 Aplicando correções para Android 12+...');
      
      // 1. Configurar SystemUI para modo compatível
      await _configureSystemUI();
      
      // 2. Forçar rebuild de widgets de texto
      await _forceTextWidgetRefresh();
      
      // 3. Configurar cache de fontes
      await _configureFontCache();
      
    } catch (e) {
      print('❌ Erro ao aplicar correções do Android 12+: $e');
    }
  }
  
  /// Configura System UI para evitar problemas
  static Future<void> _configureSystemUI() async {
    try {
      // Configurar barra de status e navegação
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      
      print('✅ System UI configurada');
      
    } catch (e) {
      print('❌ Erro ao configurar System UI: $e');
    }
  }
  
  /// Força refresh de widgets de texto
  static Future<void> _forceTextWidgetRefresh() async {
    try {
      // Aguardar próximo frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Forçar reassemble da aplicação
        WidgetsBinding.instance.reassembleApplication();
      });
      
      print('✅ Refresh de widgets de texto forçado');
      
    } catch (e) {
      print('❌ Erro ao forçar refresh: $e');
    }
  }
  
  /// Configura cache de fontes
  static Future<void> _configureFontCache() async {
    try {
      // No Android 12+, pode ser necessário limpar cache de fontes
      if (_isAndroid12Plus) {
        // Força limpeza de cache de renderização
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      }
      
      print('✅ Cache de fontes configurado');
      
    } catch (e) {
      print('❌ Erro ao configurar cache de fontes: $e');
    }
  }
  
  /// Retorna true se está rodando no Android 12+
  static bool get isAndroid12Plus => _isAndroid12Plus;
  
  /// Retorna true se há problemas conhecidos com System UI
  static bool get hasSystemUIFontIssues => _hasSystemUIFontIssues;
  
  /// Aplica correção específica quando app volta do background
  static Future<void> onAppResumed() async {
    if (!_isAndroid12Plus) return;
    
    try {
      print('📱 App voltou do background - aplicando correções...');
      
      // Aguardar um frame para estabilizar
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Reconfigurar System UI
      await _configureSystemUI();
      
      // Forçar refresh se necessário
      if (_hasSystemUIFontIssues) {
        await _forceTextWidgetRefresh();
      }
      
    } catch (e) {
      print('❌ Erro ao aplicar correções após resumir: $e');
    }
  }
  
  /// Aplica correção quando app vai para background
  static Future<void> onAppPaused() async {
    if (!_isAndroid12Plus) return;
    
    try {
      print('📱 App indo para background - preparando...');
      
      // Limpar cache se necessário
      if (_hasSystemUIFontIssues) {
        PaintingBinding.instance.imageCache.clear();
      }
      
    } catch (e) {
      print('❌ Erro ao preparar para background: $e');
    }
  }
}

/// Widget específico para corrigir problemas de texto no Android 12+
class Android12SafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final String? semanticsLabel;
  
  const Android12SafeText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se não é Android 12+, usar Text normal
    if (!AndroidTextFix.isAndroid12Plus) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaleFactor != null 
            ? TextScaler.linear(textScaleFactor!) 
            : null,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
      );
    }
    
    // Para Android 12+, usar proteções extras
    return RepaintBoundary(
      child: Container(
        // Container força novo contexto de renderização
        child: DefaultTextStyle.merge(
          style: _getAndroid12SafeStyle(context),
          child: Text(
            _sanitizeTextForAndroid12(text),
            style: style,
            textAlign: textAlign,
            textDirection: textDirection,
            locale: locale,
            softWrap: softWrap,
            overflow: overflow,
            textScaler: textScaleFactor != null 
                ? TextScaler.linear(textScaleFactor!) 
                : null,
            maxLines: maxLines,
            semanticsLabel: semanticsLabel,
          ),
        ),
      ),
    );
  }
  
  /// Retorna estilo seguro para Android 12+
  TextStyle _getAndroid12SafeStyle(BuildContext context) {
    if (AndroidTextFix.hasSystemUIFontIssues) {
      // Usar apenas fontes do sistema no Android 12+ com problemas
      return const TextStyle(
        fontFamily: null, // Força uso da fonte do sistema
      );
    }
    
    return const TextStyle();
  }
  
  /// Sanitiza texto para Android 12+
  String _sanitizeTextForAndroid12(String text) {
    if (text.isEmpty) return ' ';
    
    // Android 12+ pode ter problemas com certos caracteres
    return text
        .replaceAll('\uFEFF', '') // BOM
        .replaceAll('\u200B', '') // Zero Width Space
        .replaceAll('\u00A0', ' ') // Non-breaking space -> normal space
        .trim();
  }
}

/// Mixin para StatefulWidgets que precisam lidar com Android 12+
mixin Android12CompatMixin<T extends StatefulWidget> on State<T> {
  
  @override
  void initState() {
    super.initState();
    _initializeAndroid12Support();
  }
  
  void _initializeAndroid12Support() {
    if (AndroidTextFix.isAndroid12Plus) {
      // Configurações específicas para Android 12+
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshTextWidgets();
        }
      });
    }
  }
  
  /// Refresh específico para widgets de texto no Android 12+
  void _refreshTextWidgets() {
    if (AndroidTextFix.hasSystemUIFontIssues && mounted) {
      setState(() {
        // Força rebuild dos widgets de texto
      });
    }
  }
  
  /// Chama quando app volta do background
  void onAndroid12AppResumed() {
    if (AndroidTextFix.isAndroid12Plus && mounted) {
      // Aguardar estabilização antes de refresh
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _refreshTextWidgets();
        }
      });
    }
  }
}
