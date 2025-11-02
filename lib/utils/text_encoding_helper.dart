import 'dart:convert';
import 'package:flutter/material.dart';

/// Classe utilitária para lidar com problemas de codificação de texto na interface
class TextEncodingHelper {
  /// Normaliza a codificação de texto para garantir a exibição correta
  static String normalizeText(String text) {
    if (text.isEmpty) return text;
    
    try {
      // Tenta decodificar e recodificar o texto para corrigir problemas de codificação
      final bytes = utf8.encode(text);
      final decodedText = utf8.decode(bytes, allowMalformed: true);
      
      // Verifica se o texto contém caracteres de controle não imprimíveis
      final cleanedText = _removeControlCharacters(decodedText);
      
      // Normaliza caracteres especiais comuns em português
      final normalizedText = _normalizeSpecialCharacters(cleanedText);
      
      return normalizedText;
    } catch (e) {
      // Se houver erro, tenta abordagens alternativas
      return _fallbackNormalization(text);
    }
  }

  /// Remove caracteres de controle não imprimíveis do texto
  static String _removeControlCharacters(String text) {
    // Remove caracteres de controle, exceto quebras de linha e tabulações
    return text.replaceAll(RegExp(r'[\p{Cc}&&[^\n\t\r]]', unicode: true), '');
  }

  /// Normaliza caracteres especiais comuns em português
  static String _normalizeSpecialCharacters(String text) {
    // Mapeamento de caracteres especiais que podem aparecer incorretamente
    final Map<String, String> specialCharsMap = {
      'Ã£': 'ã', 'Ãµ': 'õ', 'Ã¡': 'á', 'Ãé': 'é', 'Ã­': 'í', 'Ã³': 'ó', 'Ãº': 'ú',
      'Ã¢': 'â', 'Ãª': 'ê', 'Ã´': 'ô', 'Ã§': 'ç', 'Ã‡': 'Ç',
      'Ã€': 'À', 'Ã': 'Á', 'Ã‚': 'Â', 'Ãƒ': 'Ã', 'Ã„': 'Ä',
      'Ã…': 'Å', 'Ã†': 'Æ', 'Ãˆ': 'È', 'Ã‰': 'É', 'ÃŠ': 'Ê',
      'Ã‹': 'Ë', 'ÃŒ': 'Ì', 'Ã': 'Í', 'ÃŽ': 'Î', 'Ã': 'Ï',
      'Ã': 'Ò', 'Ã"': 'Ó', 'Ã"': 'Ô', 'Ã•': 'Õ', 'Ã–': 'Ö',
      'Ã˜': 'Ø', 'Ã™': 'Ù', 'Ãš': 'Ú', 'Ã›': 'Û', 'Ãœ': 'Ü',
      'Ã': 'Ý', 'Ãž': 'Þ', 'ÃŸ': 'ß', 'Ã ': 'à', 'Ã¡': 'á',
      'Ã¢': 'â', 'Ã£': 'ã', 'Ã¤': 'ä', 'Ã¥': 'å', 'Ã¦': 'æ',
      'Ã¨': 'è', 'Ãé': 'é', 'Ãª': 'ê', 'Ã«': 'ë', 'Ã¬': 'ì',
      'Ã­': 'í', 'Ã®': 'î', 'Ã¯': 'ï', 'Ã°': 'ð', 'Ã²': 'ò',
      'Ã³': 'ó', 'Ã´': 'ô', 'Ãµ': 'õ', 'Ã¶': 'ö', 'Ã¸': 'ø',
      'Ã¹': 'ù', 'Ãº': 'ú', 'Ã»': 'û', 'Ã¼': 'ü', 'Ã½': 'ý',
      'Ã¾': 'þ', 'Ã¿': 'ÿ',
    };

    String result = text;
    specialCharsMap.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    return result;
  }

  /// Método alternativo para normalização quando o método principal falha
  static String _fallbackNormalization(String text) {
    try {
      // Tenta decodificar usando Latin-1 (ISO-8859-1) e recodificar para UTF-8
      final bytes = latin1.encode(text);
      final decodedText = utf8.decode(bytes, allowMalformed: true);
      return _normalizeSpecialCharacters(decodedText);
    } catch (e) {
      // Se ainda falhar, faz uma limpeza básica de caracteres
      return _cleanupText(text);
    }
  }

  /// Corrige problemas de codificação em um texto
  static String fixEncodingIssues(String text) {
    if (text.isEmpty) return text;
    
    try {
      // Primeiro tenta a normalização padrão
      final normalizedText = normalizeText(text);
      
      // Se a normalização não alterou o texto, verifica se há problemas específicos
      if (normalizedText == text) {
        // Verifica problemas de codificação dupla
        if (text.contains('Ã£') || text.contains('Ãµ') || text.contains('Ã§')) {
          // Tenta corrigir problemas de codificação dupla
          return _normalizeSpecialCharacters(text);
        }
      }
      
      return normalizedText;
    } catch (e) {
      // Em caso de erro, retorna o texto original
      return text;
    }
  }

  /// Realiza uma limpeza básica no texto quando todos os outros métodos falham
  static String _cleanupText(String text) {
    // Remove caracteres que não são ASCII ou caracteres especiais comuns
    final cleanedText = text.replaceAll(RegExp(r'[^\x20-\x7E\u00A0-\u00FF]'), '');
    return _normalizeSpecialCharacters(cleanedText);
  }

  /// Verifica se o texto contém problemas de codificação
  static bool hasEncodingIssues(String text) {
    if (text.isEmpty) return false;
    
    // Verifica se o texto contém sequências de caracteres que indicam problemas de codificação
    final problematicPatterns = [
      'Ã£', 'Ãµ', 'Ã¡', 'Ãé', 'Ã­', 'Ã³', 'Ãº', 'Ã¢', 'Ãª', 'Ã´', 'Ã§',
      // Caracteres de controle não imprimíveis (exceto quebras de linha e tabs)
      RegExp(r'[\p{Cc}&&[^\n\t\r]]', unicode: true),
    ];
    
    for (final pattern in problematicPatterns) {
      if (pattern is RegExp) {
        if (pattern.hasMatch(text)) return true;
      } else if (text.contains(pattern)) {
        return true;
      }
    }
    
    // Verifica se a normalização altera o texto
    final normalizedText = normalizeText(text);
    return normalizedText != text;
  }

  /// Detecta o encoding provável do texto
  static String detectEncoding(String text) {
    if (text.isEmpty) return 'UTF-8';
    
    // Tenta identificar o encoding baseado em padrões comuns
    if (text.contains('Ã£') || text.contains('Ãé') || text.contains('Ã§')) {
      return 'ISO-8859-1 (Latin-1) interpretado como UTF-8';
    }
    
    // Verifica se o texto contém caracteres não-ASCII
    if (text.codeUnits.any((unit) => unit > 127)) {
      // Tenta determinar se é UTF-8 válido
      try {
        utf8.decode(utf8.encode(text));
        return 'UTF-8';
      } catch (_) {
        return 'Encoding desconhecido';
      }
    }
    
    return 'ASCII';
  }

  /// Widget que envolve um Text para garantir a codificação correta
  static Widget safeText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    bool? softWrap,
    double? textScaleFactor,
  }) {
    return Text(
      normalizeText(text),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textScaleFactor: textScaleFactor,
    );
  }

  /// Método para corrigir problemas de codificação em listas de strings
  static List<String> normalizeStringList(List<String> strings) {
    return strings.map((s) => normalizeText(s)).toList();
  }

  /// Método para corrigir problemas de codificação em mapas com valores string
  static Map<String, String> normalizeStringMap(Map<String, String> map) {
    final normalizedMap = <String, String>{};
    map.forEach((key, value) {
      normalizedMap[normalizeText(key)] = normalizeText(value);
    });
    return normalizedMap;
  }
  
  /// Normaliza todos os valores string em um Map genérico (recursivamente)
  static Map<String, dynamic> normalizeMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    
    map.forEach((key, value) {
      final normalizedKey = normalizeText(key);
      
      if (value is String) {
        result[normalizedKey] = normalizeText(value);
      } else if (value is Map<String, dynamic>) {
        result[normalizedKey] = normalizeMap(value);
      } else if (value is List) {
        result[normalizedKey] = normalizeList(value);
      } else {
        result[normalizedKey] = value;
      }
    });
    
    return result;
  }
  
  /// Normaliza todos os valores string em uma List genérica (recursivamente)
  static List<dynamic> normalizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return normalizeText(item);
      } else if (item is Map<String, dynamic>) {
        return normalizeMap(item);
      } else if (item is List) {
        return normalizeList(item);
      } else {
        return item;
      }
    }).toList();
  }
  
  /// Corrige problemas de codificação em um objeto JSON
  static dynamic normalizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return normalizeMap(json);
    } else if (json is List) {
      return normalizeList(json);
    } else if (json is String) {
      return normalizeText(json);
    } else {
      return json;
    }
  }
}
