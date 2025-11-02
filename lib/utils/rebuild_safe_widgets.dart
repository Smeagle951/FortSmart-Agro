import 'package:flutter/material.dart';

/// Widgets seguros que previnem problemas de rebuild e corrupção de texto
class RebuildSafeWidgets {
  
  /// Text widget que previne corrupção durante rebuilds
  static Widget text(
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
    return RepaintBoundary(
      key: key,
      child: Builder(
        builder: (context) {
          // Garantir que o texto seja válido
          final safeText = _sanitizeText(text);
          
          return Text(
            safeText,
            style: _getSafeStyle(context, style),
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
          );
        },
      ),
    );
  }
  
  /// ListTile seguro contra problemas de rebuild
  static Widget listTile({
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
    return RepaintBoundary(
      key: key,
      child: ListTile(
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
      ),
    );
  }
  
  /// Card seguro com texto
  static Widget card({
    Key? key,
    Color? color,
    double? elevation,
    ShapeBorder? shape,
    bool borderOnForeground = true,
    EdgeInsetsGeometry? margin,
    Clip? clipBehavior,
    Widget? child,
    bool semanticContainer = true,
  }) {
    return RepaintBoundary(
      key: key,
      child: Card(
        color: color,
        elevation: elevation,
        shape: shape,
        borderOnForeground: borderOnForeground,
        margin: margin,
        clipBehavior: clipBehavior,
        semanticContainer: semanticContainer,
        child: child,
      ),
    );
  }
  
  /// Container seguro para textos
  static Widget textContainer({
    Key? key,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    Decoration? foregroundDecoration,
    double? width,
    double? height,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    Widget? child,
    Clip clipBehavior = Clip.none,
  }) {
    return RepaintBoundary(
      key: key,
      child: Container(
        alignment: alignment,
        padding: padding,
        color: color,
        decoration: decoration,
        foregroundDecoration: foregroundDecoration,
        width: width,
        height: height,
        constraints: constraints,
        margin: margin,
        transform: transform,
        transformAlignment: transformAlignment,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }
  
  /// Sanitiza texto para prevenir problemas de renderização
  static String _sanitizeText(String text) {
    if (text.isEmpty) return ' '; // Evitar texto completamente vazio
    
    // Remover caracteres que podem causar problemas
    return text
        .replaceAll('\uFEFF', '') // BOM (Byte Order Mark)
        .replaceAll('\u200B', '') // Zero Width Space
        .replaceAll('\u200C', '') // Zero Width Non-Joiner
        .replaceAll('\u200D', '') // Zero Width Joiner
        .replaceAll('\uFFFD', '?') // Replacement Character
        .trim();
  }
  
  /// Retorna estilo de texto seguro
  static TextStyle _getSafeStyle(BuildContext context, TextStyle? style) {
    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.bodyMedium!;
    
    // Se há problemas conhecidos com fontes, usar fonte do sistema
    return baseStyle.copyWith(
      // Garantir que a cor seja válida
      color: baseStyle.color ?? theme.textTheme.bodyMedium!.color,
      // Garantir tamanho mínimo de fonte
      fontSize: (baseStyle.fontSize ?? 14.0).clamp(8.0, 72.0),
    );
  }
}

/// Widget que protege contra problemas de rebuild
class RebuildSafeWidget extends StatefulWidget {
  final Widget child;
  final Duration rebuildDelay;
  
  const RebuildSafeWidget({
    Key? key,
    required this.child,
    this.rebuildDelay = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<RebuildSafeWidget> createState() => _RebuildSafeWidgetState();
}

class _RebuildSafeWidgetState extends State<RebuildSafeWidget> {
  Widget? _cachedChild;
  bool _isRebuilding = false;
  
  @override
  void initState() {
    super.initState();
    _cachedChild = widget.child;
  }
  
  @override
  void didUpdateWidget(RebuildSafeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.child != oldWidget.child && !_isRebuilding) {
      _scheduleRebuild();
    }
  }
  
  void _scheduleRebuild() {
    _isRebuilding = true;
    
    Future.delayed(widget.rebuildDelay, () {
      if (mounted) {
        setState(() {
          _cachedChild = widget.child;
          _isRebuilding = false;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _cachedChild ?? widget.child,
    );
  }
}

/// Extensão para facilitar o uso de widgets seguros
extension SafeWidgetExtension on Widget {
  /// Envolve o widget em um RepaintBoundary para performance
  Widget withRepaintBoundary() {
    return RepaintBoundary(child: this);
  }
  
  /// Envolve o widget em proteção contra rebuild
  Widget withRebuildProtection({Duration delay = const Duration(milliseconds: 100)}) {
    return RebuildSafeWidget(
      rebuildDelay: delay,
      child: this,
    );
  }
}

/// Mixin para StatefulWidgets que precisam de proteção contra rebuild
mixin RebuildSafeMixin<T extends StatefulWidget> on State<T> {
  bool _isRebuilding = false;
  DateTime? _lastRebuildTime;
  
  /// Executa setState de forma segura
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    
    final now = DateTime.now();
    
    // Evitar rebuilds muito frequentes
    if (_lastRebuildTime != null && 
        now.difference(_lastRebuildTime!).inMilliseconds < 50) {
      return;
    }
    
    if (!_isRebuilding) {
      _isRebuilding = true;
      _lastRebuildTime = now;
      
      setState(() {
        fn();
        _isRebuilding = false;
      });
    }
  }
  
  /// Executa setState com delay para evitar problemas
  void delayedSetState(VoidCallback fn, {Duration delay = const Duration(milliseconds: 50)}) {
    if (!mounted) return;
    
    Future.delayed(delay, () {
      if (mounted) {
        safeSetState(fn);
      }
    });
  }
}
