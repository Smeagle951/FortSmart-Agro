import 'package:flutter/material.dart';
import '../utils/text_encoding_helper.dart';

/// Widget para exibir texto com tratamento de codificação
class SafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;

  const SafeText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final normalizedText = TextEncodingHelper.normalizeText(text);
    
    return Text(
      normalizedText,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}

/// Widget para exibir título com tratamento de codificação
class SafeTitle extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final Color? color;

  const SafeTitle(
    this.text, {
    Key? key,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final normalizedText = TextEncodingHelper.normalizeText(text);
    
    return Text(
      normalizedText,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

/// Widget para exibir subtítulo com tratamento de codificação
class SafeSubtitle extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final Color? color;

  const SafeSubtitle(
    this.text, {
    Key? key,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final normalizedText = TextEncodingHelper.normalizeText(text);
    
    return Text(
      normalizedText,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: color,
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

/// Widget para exibir corpo de texto com tratamento de codificação
class SafeBodyText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final Color? color;

  const SafeBodyText(
    this.text, {
    Key? key,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final normalizedText = TextEncodingHelper.normalizeText(text);
    
    return Text(
      normalizedText,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: color,
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
