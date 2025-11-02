import 'dart:ui';
import 'package:flutter/material.dart';

/// Widget que cria um contêiner com efeito de glass morphism (vidro fosco)
class GlassMorphismContainer extends StatelessWidget {
  final Widget child;
  final dynamic borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final Color? backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double height;
  final double? width;
  final Alignment? alignment;
  final BoxShadow? boxShadow;
  final double opacity;
  final double borderOpacity;

  const GlassMorphismContainer({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.blur = 10.0,
    this.backgroundColor,
    this.borderColor = Colors.white30,
    this.borderWidth = 1.0,
    this.height = 0,
    this.width,
    this.alignment,
    this.opacity = 0.2,
    this.borderOpacity = 0.3,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Converter o borderRadius para o tipo correto
    BorderRadius finalBorderRadius;
    if (borderRadius is BorderRadius) {
      finalBorderRadius = borderRadius as BorderRadius;
    } else if (borderRadius is double) {
      finalBorderRadius = BorderRadius.circular(borderRadius as double);
    } else {
      finalBorderRadius = BorderRadius.circular(16.0);
    }
    
    return Container(
      height: height > 0 ? height : null,
      width: width,
      // alignment: alignment, // alignment não é suportado em Marker no flutter_map 5.0.0
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: finalBorderRadius,
        boxShadow: boxShadow != null ? [boxShadow!] : null,
      ),
      child: ClipRRect(
        borderRadius: finalBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor?.withOpacity(opacity) ?? Colors.white.withOpacity(opacity),
              borderRadius: finalBorderRadius,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Tema de cores premium para o aplicativo
class PremiumTheme {
  // Cores primárias
  static const Color darkNavy = Color(0xFF001F3F);       // Azul petróleo
  static const Color darkGreen = Color(0xFF014F43);      // Verde escuro tecnológico
  static const Color neonGreen = Color(0xFF00FF7F);      // Verde neon premium
  static const Color solarOrange = Color(0xFFFF851B);    // Laranja solar
  static const Color techLime = Color(0xFF2ECC40);       // Verde limão tecnológico
  static const Color modernRed = Color(0xFFFF4136);      // Vermelho moderno
  static const Color energeticYellow = Color(0xFFFFDC00); // Amarelo energético
  static const Color elegantDark = Color(0xFF111111);    // Cinza escuro elegante

  // Cores de texto
  static const Color textPrimary = Colors.white;         // Branco puro
  static const Color textSecondary = Color(0xFFD9D9D9);  // Cinza claro

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [darkNavy, darkGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [techLime, neonGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [solarOrange, energeticYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [solarOrange, modernRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
