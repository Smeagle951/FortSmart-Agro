import 'package:flutter/material.dart';

/// Botão com efeito de gradiente
class GradientButton extends StatelessWidget {
  final Gradient gradient;
  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final double width;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double elevation;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientButton({
    Key? key,
    required this.gradient,
    required this.onPressed,
    required this.child,
    this.height = 50.0,
    this.width = double.infinity,
    this.borderRadius = 8.0,
    this.padding,
    this.elevation = 2.0,
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (elevation > 0)
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0.5,
              blurRadius: elevation,
              offset: Offset(0, elevation / 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: Padding(
              padding: padding ?? EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Cria um botão com gradiente padrão da aplicação
  factory GradientButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    double height = 50.0,
    double width = double.infinity,
    double borderRadius = 8.0,
    EdgeInsetsGeometry? padding,
    double elevation = 2.0,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    
    return GradientButton(
      key: key,
      gradient: LinearGradient(
        colors: [
          theme.primaryColor,
          theme.primaryColor.withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onPressed: onPressed,
      child: child,
      height: height,
      width: width,
      borderRadius: borderRadius,
      padding: padding,
      elevation: elevation,
    );
  }

  /// Cria um botão com gradiente secundário da aplicação
  factory GradientButton.secondary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    double height = 50.0,
    double width = double.infinity,
    double borderRadius = 8.0,
    EdgeInsetsGeometry? padding,
    double elevation = 2.0,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    
    return GradientButton(
      key: key,
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.secondary,
          theme.colorScheme.secondary.withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onPressed: onPressed,
      child: child,
      height: height,
      width: width,
      borderRadius: borderRadius,
      padding: padding,
      elevation: elevation,
    );
  }
}
