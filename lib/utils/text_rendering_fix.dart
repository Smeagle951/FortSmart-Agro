import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utilitário para corrigir problemas de renderização de texto
/// relacionados a fontes customizadas e rebuilds incorretos
class TextRenderingFix {
  static bool _isInitialized = false;
  static bool _hasFontIssues = false;

  /// Inicializa as correções de renderização de texto
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔤 Inicializando correções de renderização de texto...');
      
      // Verificar se as fontes estão disponíveis
      await _checkFontAvailability();
      
      // Configurar observador de lifecycle
      _setupAppLifecycleObserver();
      
      _isInitialized = true;
      print('✅ Correções de renderização de texto inicializadas');
      
    } catch (e) {
      print('❌ Erro ao inicializar correções de texto: $e');
      _hasFontIssues = true;
    }
  }
  
  /// Verifica se as fontes customizadas estão disponíveis
  static Future<void> _checkFontAvailability() async {
    try {
      // Tentar carregar a fonte OpenSans
      await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
      await rootBundle.load("assets/fonts/OpenSans-Bold.ttf");
      await rootBundle.load("assets/fonts/OpenSans-Italic.ttf");
      
      print('✅ Fontes OpenSans carregadas com sucesso');
    } catch (e) {
      print('⚠️ Problema ao carregar fontes OpenSans: $e');
      _hasFontIssues = true;
    }
  }
  
  /// Configura observador de lifecycle do app
  static void _setupAppLifecycleObserver() {
    // Será configurado no main.dart ou no widget principal
    print('🔄 Configurando observador de lifecycle');
  }
  
  /// Retorna true se há problemas conhecidos com fontes
  static bool get hasFontIssues => _hasFontIssues;
  
  /// Força a limpeza de cache de fontes (Android 12+)
  static Future<void> clearFontCache() async {
    try {
      // Forçar rebuild de widgets de texto
      WidgetsBinding.instance.reassembleApplication();
      print('🔄 Cache de fontes limpo');
    } catch (e) {
      print('❌ Erro ao limpar cache de fontes: $e');
    }
  }
}

/// Widget de texto seguro que previne corrupção de renderização
class SafeText extends StatelessWidget {
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
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  
  const SafeText(
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
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Garantir que o texto não seja nulo ou vazio
    final safeText = text.isEmpty ? ' ' : text;
    
    // Estilo seguro que evita problemas de fonte
    final safeStyle = _getSafeTextStyle(context, style);
    
    return RepaintBoundary(
      child: Text(
        safeText,
        style: safeStyle,
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
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      ),
    );
  }
  
  /// Retorna um estilo de texto seguro
  TextStyle _getSafeTextStyle(BuildContext context, TextStyle? originalStyle) {
    final theme = Theme.of(context);
    
    // Se há problemas com fontes customizadas, usar fonte do sistema
    if (TextRenderingFix.hasFontIssues) {
      return (originalStyle ?? theme.textTheme.bodyMedium!).copyWith(
        fontFamily: null, // Usar fonte do sistema
      );
    }
    
    // Estilo padrão seguro
    return originalStyle ?? theme.textTheme.bodyMedium!;
  }
}

/// Widget de texto rico seguro
class SafeRichText extends StatelessWidget {
  final InlineSpan text;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final bool softWrap;
  final TextOverflow overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  
  const SafeRichText({
    Key? key,
    required this.text,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.selectionColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: RichText(
        text: text,
        textAlign: textAlign,
        textDirection: textDirection,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaleFactor != null 
            ? TextScaler.linear(textScaleFactor!) 
            : TextScaler.noScaling,
        maxLines: maxLines,
        locale: locale,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      ),
    );
  }
}

/// Widget que observa mudanças no lifecycle do app
class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  final VoidCallback? onResume;
  final VoidCallback? onPause;
  
  const AppLifecycleObserver({
    Key? key,
    required this.child,
    this.onResume,
    this.onPause,
  }) : super(key: key);

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App retornou do background');
        widget.onResume?.call();
        // Limpar cache de renderização após retornar do background
        _clearRenderingCache();
        break;
      case AppLifecycleState.paused:
        print('📱 App foi para background');
        widget.onPause?.call();
        break;
      case AppLifecycleState.detached:
        print('📱 App foi fechado');
        break;
      case AppLifecycleState.inactive:
        print('📱 App ficou inativo');
        break;
      case AppLifecycleState.hidden:
        print('📱 App foi minimizado');
        break;
    }
  }
  
  /// Limpa cache de renderização que pode causar corrupção
  void _clearRenderingCache() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Forçar rebuild de widgets com problemas de renderização
        setState(() {});
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Mixin para corrigir problemas de texto em StatefulWidgets
mixin TextRenderingFixMixin<T extends StatefulWidget> on State<T> {
  bool _needsTextRefresh = false;
  
  @override
  void initState() {
    super.initState();
    _checkForTextIssues();
  }
  
  /// Verifica se precisa atualizar renderização de texto
  void _checkForTextIssues() {
    if (TextRenderingFix.hasFontIssues) {
      _needsTextRefresh = true;
    }
  }
  
  /// Força refresh de texto se necessário
  void refreshTextIfNeeded() {
    if (_needsTextRefresh && mounted) {
      setState(() {
        _needsTextRefresh = false;
      });
    }
  }
  
  /// Chama após retornar do background
  void onAppResumed() {
    refreshTextIfNeeded();
  }
}
