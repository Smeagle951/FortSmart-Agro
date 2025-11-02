import 'package:flutter/material.dart';

/// Utilitários para design responsivo
class ResponsiveUtils {
  /// Verifica se deve usar layout compacto baseado no tamanho da tela
  static bool shouldUseCompactLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600;
  }

  /// Obtém espaçamento adaptativo baseado no tamanho da tela
  static double getAdaptiveSpacing(BuildContext context, {double? small, double? compact}) {
    if (shouldUseCompactLayout(context)) {
      return compact ?? small ?? 8.0;
    }
    return small ?? 12.0;
  }

  /// Obtém tamanho de fonte adaptativo
  static double getAdaptiveFontSize(BuildContext context, {required double small, required double compact}) {
    if (shouldUseCompactLayout(context)) {
      return compact;
    }
    return small;
  }

  /// Obtém padding adaptativo
  static EdgeInsets getAdaptivePadding(BuildContext context, {EdgeInsets? small, EdgeInsets? compact}) {
    if (shouldUseCompactLayout(context)) {
      return compact ?? small ?? const EdgeInsets.all(8.0);
    }
    return small ?? const EdgeInsets.all(12.0);
  }

  /// Obtém border radius adaptativo
  static BorderRadius getAdaptiveBorderRadius(BuildContext context) {
    if (shouldUseCompactLayout(context)) {
      return BorderRadius.circular(8.0);
    }
    return BorderRadius.circular(12.0);
  }
}

/// Widget de texto responsivo
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? TextStyle()).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Widget de botão responsivo
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final double? fontSize;

  const ResponsiveButton(
    this.text, {
    Key? key,
    this.onPressed,
    this.style,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize),
      ),
    );
  }
}

/// Widget de grade adaptativa
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const AdaptiveGrid({
    Key? key,
    required this.children,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveUtils.shouldUseCompactLayout(context);
    
    return GridView.count(
      crossAxisCount: isCompact ? 1 : crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      children: children,
    );
  }
}

/// Widget de card adaptativo
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final double? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AdaptiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2.0,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
      ),
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(8.0),
          child: child,
        ),
      ),
    );
  }
}
