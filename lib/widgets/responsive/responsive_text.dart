import 'package:flutter/material.dart';
import '../../utils/responsive_screen_utils.dart';

/// Texto responsivo que se adapta ao tamanho da tela
class ResponsiveText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  final double? letterSpacing;
  final double? lineHeight;
  final TextDecoration? decoration;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
    this.letterSpacing,
    this.lineHeight,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsiveFontSize = fontSize != null 
        ? ResponsiveScreenUtils.getResponsiveFontSize(context, fontSize!)
        : null;
    
    final responsiveLetterSpacing = letterSpacing != null
        ? ResponsiveScreenUtils.scale(context, letterSpacing!)
        : null;
    
    final responsiveLineHeight = lineHeight != null
        ? ResponsiveScreenUtils.scale(context, lineHeight!)
        : null;

    return Text(
      text,
      style: style?.copyWith(
        fontSize: responsiveFontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: responsiveLetterSpacing,
        height: responsiveLineHeight,
        decoration: decoration,
      ) ?? TextStyle(
        fontSize: responsiveFontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: responsiveLetterSpacing,
        height: responsiveLineHeight,
        decoration: decoration,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Título responsivo
class ResponsiveTitle extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;

  const ResponsiveTitle(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      fontSize: fontSize ?? 24.0,
      fontWeight: FontWeight.bold,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Subtítulo responsivo
class ResponsiveSubtitle extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;

  const ResponsiveSubtitle(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      fontSize: fontSize ?? 18.0,
      fontWeight: FontWeight.w600,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Texto do corpo responsivo
class ResponsiveBodyText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;

  const ResponsiveBodyText(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      fontSize: fontSize ?? 16.0,
      fontWeight: FontWeight.normal,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Texto pequeno responsivo
class ResponsiveSmallText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;

  const ResponsiveSmallText(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      fontSize: fontSize ?? 12.0,
      fontWeight: FontWeight.normal,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Texto de captura responsivo
class ResponsiveCaption extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;

  const ResponsiveCaption(
    this.text, {
    Key? key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveText(
      text,
      fontSize: fontSize ?? 10.0,
      fontWeight: FontWeight.normal,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
