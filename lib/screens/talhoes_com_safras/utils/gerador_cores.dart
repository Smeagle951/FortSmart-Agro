import 'package:flutter/material.dart';

/// Classe para geração e gerenciamento de cores para culturas agrícolas
/// Garante consistência visual em todo o aplicativo
class GeradorCores {
  /// Paleta de cores agrícolas otimizada para visualização em mapas
  static const List<Color> paletaAgricola = [
    Color(0xFF4CAF50), // Verde
    Color(0xFF2196F3), // Azul
    Color(0xFFFF9800), // Laranja
    Color(0xFF9C27B0), // Roxo
    Color(0xFF795548), // Marrom
    Color(0xFF607D8B), // Azul acinzentado
    Color(0xFFFFC107), // Âmbar
    Color(0xFF009688), // Verde azulado
    Color(0xFFE91E63), // Rosa
    Color(0xFF3F51B5), // Índigo
    Color(0xFFFF5722), // Laranja profundo
    Color(0xFF8BC34A), // Verde claro
  ];
  
  /// Gera uma cor consistente baseada no nome da cultura
  /// A mesma cultura sempre terá a mesma cor
  static Color gerarCorPorCultura(String nomeCultura) {
    if (nomeCultura.isEmpty) {
      return paletaAgricola[0]; // Cor padrão
    }
    
    final hash = nomeCultura.toLowerCase().hashCode;
    final indice = hash.abs() % paletaAgricola.length;
    return paletaAgricola[indice];
  }
  
  /// Gera uma cor com opacidade específica
  static Color gerarCorComOpacidade(String nomeCultura, double opacity) {
    return gerarCorPorCultura(nomeCultura).withOpacity(opacity);
  }
  
  /// Converte uma cor para formato hexadecimal
  static String corParaHex(Color cor) {
    return '#${cor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  /// Converte um código hexadecimal para Color
  static Color hexParaCor(String hex) {
    // Remover # se presente
    final hexSemHash = hex.startsWith('#') ? hex.substring(1) : hex;
    
    // Garantir que temos 6 caracteres
    if (hexSemHash.length == 6) {
      return Color(int.parse('FF$hexSemHash', radix: 16));
    } else if (hexSemHash.length == 8) {
      return Color(int.parse(hexSemHash, radix: 16));
    }
    
    // Fallback para cor padrão
    return paletaAgricola[0];
  }
  
  /// Retorna uma cor de texto apropriada (branco ou preto) baseada na cor de fundo
  /// Garante contraste adequado para leitura
  static Color corTextoContrastante(Color corFundo) {
    // Fórmula YIQ para determinar brilho
    final yiq = ((corFundo.red * 299) + (corFundo.green * 587) + (corFundo.blue * 114)) / 1000;
    
    // Retorna branco para cores escuras e preto para cores claras
    return yiq >= 128 ? Colors.black : Colors.white;
  }
  
  /// Gera uma paleta de cores derivadas para uma cultura
  /// Útil para criar esquemas de cores consistentes
  static Map<String, Color> gerarPaletaCultura(String nomeCultura) {
    final corBase = gerarCorPorCultura(nomeCultura);
    
    return {
      'primaria': corBase,
      'clara': _clarearCor(corBase, 0.3),
      'escura': _escurecerCor(corBase, 0.3),
      'acento': _gerarCorAcento(corBase),
      'fundo': corBase.withOpacity(0.1),
      'borda': corBase.withOpacity(0.7),
    };
  }
  
  /// Clareia uma cor por um fator específico
  static Color _clarearCor(Color cor, double fator) {
    return Color.fromARGB(
      cor.alpha,
      (cor.red + (255 - cor.red) * fator).round().clamp(0, 255),
      (cor.green + (255 - cor.green) * fator).round().clamp(0, 255),
      (cor.blue + (255 - cor.blue) * fator).round().clamp(0, 255),
    );
  }
  
  /// Escurece uma cor por um fator específico
  static Color _escurecerCor(Color cor, double fator) {
    return Color.fromARGB(
      cor.alpha,
      (cor.red * (1 - fator)).round().clamp(0, 255),
      (cor.green * (1 - fator)).round().clamp(0, 255),
      (cor.blue * (1 - fator)).round().clamp(0, 255),
    );
  }
  
  /// Gera uma cor de acento complementar
  static Color _gerarCorAcento(Color corBase) {
    // Rotacionar 180 graus no círculo cromático para cor complementar
    final hsl = HSLColor.fromColor(corBase);
    return HSLColor.fromAHSL(
      hsl.alpha,
      (hsl.hue + 180) % 360,
      hsl.saturation,
      hsl.lightness,
    ).toColor();
  }
  
  /// Retorna um ícone apropriado para a cultura baseado no nome
  static IconData getIconePorCultura(String nomeCultura) {
    final nomeLower = nomeCultura.toLowerCase();
    
    if (nomeLower.contains('soja')) return Icons.grass;
    if (nomeLower.contains('milho')) return Icons.grain;
    if (nomeLower.contains('trigo')) return Icons.agriculture;
    if (nomeLower.contains('algodão')) return Icons.texture;
    if (nomeLower.contains('café')) return Icons.coffee;
    if (nomeLower.contains('cana')) return Icons.grass_outlined;
    if (nomeLower.contains('feijão')) return Icons.spa;
    if (nomeLower.contains('arroz')) return Icons.grain_outlined;
    
    // Ícone padrão para outras culturas
    return Icons.eco;
  }
}
