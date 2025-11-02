import 'package:flutter/material.dart';
import '../utils/text_encoding_helper.dart';

/// Widget para exibir títulos com tratamento seguro de codificação de texto
/// 
/// Este widget garante que o texto exibido tenha a codificação correta,
/// evitando problemas com caracteres especiais e acentuação.
class SafeTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;
  final double? textScaleFactor;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final Locale? locale;

  /// Construtor para o widget SafeTitle
  /// 
  /// [text] é o texto a ser exibido
  /// [style] é o estilo do texto
  /// [textAlign] é o alinhamento do texto
  /// [overflow] é o comportamento quando o texto não cabe no espaço disponível
  /// [maxLines] é o número máximo de linhas
  /// [softWrap] indica se o texto deve quebrar em espaços
  /// [textScaleFactor] é o fator de escala do texto
  /// [strutStyle] é o estilo de strut do texto
  /// [textDirection] é a direção do texto
  /// [locale] é a localização do texto
  const SafeTitle(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
    this.textScaleFactor,
    this.strutStyle,
    this.textDirection,
    this.locale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Normaliza o texto para garantir a codificação correta
    final normalizedText = TextEncodingHelper.normalizeText(text);
    
    // Estilo padrão para títulos
    final defaultStyle = Theme.of(context).textTheme.titleLarge;
    final mergedStyle = style != null 
        ? defaultStyle?.merge(style) ?? style 
        : defaultStyle;

    return Text(
      normalizedText,
      style: mergedStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
      textScaler: textScaleFactor != null ? TextScaler.linear(textScaleFactor!) : null,
      strutStyle: strutStyle,
      textDirection: textDirection,
      locale: locale,
    );
  }
}
