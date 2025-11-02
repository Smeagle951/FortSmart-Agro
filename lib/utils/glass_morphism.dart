import 'dart:ui';
import 'package:flutter/material.dart';

/// Widget que aplica efeito de glass morphism (vidro fosco)
class GlassMorphism extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;

  const GlassMorphism({
    Key? key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.2,
    this.radius = 10,
    this.padding,
    this.borderColor,
    this.borderWidth = 1.5,
    this.margin,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: borderWidth,
              )
            : null,
        gradient: gradient,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
