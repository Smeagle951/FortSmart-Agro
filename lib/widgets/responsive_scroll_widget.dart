import 'package:flutter/material.dart';

/// Widget responsivo que elimina problemas de overflow
class ResponsiveScrollWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showScrollIndicator;
  final ScrollController? controller;

  const ResponsiveScrollWidget({
    Key? key,
    required this.child,
    this.padding,
    this.showScrollIndicator = true,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: controller,
          padding: padding ?? const EdgeInsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (padding?.vertical ?? 32),
            ),
            child: IntrinsicHeight(
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Widget para cards responsivos que se adaptam ao tamanho da tela
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withOpacity(0.1),
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: elevation != null
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: elevation!,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
    );
  }
}

/// Widget para texto responsivo que evita overflow
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow ?? TextOverflow.visible,
          softWrap: true,
        );
      },
    );
  }
}

/// Widget para listas responsivas
class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double? spacing;

  const ResponsiveList({
    Key? key,
    required this.children,
    this.padding,
    this.spacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children
              .expand((child) => [
                    child,
                    if (spacing != null) SizedBox(height: spacing!),
                  ])
              .toList()
            ..removeLast(), // Remove o último espaçamento
        );
      },
    );
  }
}

/// Mixin para adicionar funcionalidades responsivas a qualquer widget
mixin ResponsiveMixin {
  bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  double getResponsivePadding(BuildContext context) {
    if (isSmallScreen(context)) return 8.0;
    if (isMediumScreen(context)) return 16.0;
    return 24.0;
  }

  double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isSmallScreen(context)) return baseSize * 0.9;
    if (isMediumScreen(context)) return baseSize;
    return baseSize * 1.1;
  }
}
