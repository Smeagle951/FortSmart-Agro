import 'package:flutter/material.dart';

/// Utilitário centralizado para cores de culturas
/// Garante consistência visual e contraste adequado em todo o aplicativo
class CulturaColorsUtils {
  /// Mapeamento de culturas para cores com bom contraste
  static const Map<String, Color> _coresCulturas = {
    'soja': Color(0xFF2E7D32), // Verde escuro
    'milho': Color(0xFFF57F17), // Amarelo escuro
    'algodão': Color(0xFF1976D2), // Azul escuro (substitui branco para melhor contraste)
    'algodao': Color(0xFF1976D2), // Azul escuro (variação sem acento)
    'girassol': Color(0xFFE65100), // Laranja escuro
    'sorgo': Color(0xFF5D4037), // Marrom escuro
    'trigo': Color(0xFF5D4037), // Marrom escuro
    'feijão': Color(0xFF4E342E), // Marrom muito escuro
    'feijao': Color(0xFF4E342E), // Marrom muito escuro (variação sem acento)
    'arroz': Color(0xFFF9A825), // Amarelo escuro
    'café': Color(0xFF3E2723), // Marrom muito escuro
    'cafe': Color(0xFF3E2723), // Marrom muito escuro (variação sem acento)
    'cana': Color(0xFF33691E), // Verde escuro
    'eucalipto': Color(0xFF1B5E20), // Verde muito escuro
    'floresta': Color(0xFF1B5E20), // Verde muito escuro
    'batata': Color(0xFFD84315), // Laranja avermelhado escuro
    'tomate': Color(0xFFB71C1C), // Vermelho escuro
    'gergelim': Color(0xFF4A148C), // Roxo escuro
  };

  /// Cor padrão para culturas não mapeadas
  static const Color _corPadrao = Color(0xFF1B5E20); // Verde escuro padrão

  /// Retorna a cor específica para uma cultura
  /// Garante contraste adequado para visibilidade
  static Color getColorForName(String nomeCultura) {
    if (nomeCultura.isEmpty) {
      return _corPadrao;
    }

    final nomeLower = nomeCultura.toLowerCase().trim();
    
    // Buscar correspondência exata primeiro
    if (_coresCulturas.containsKey(nomeLower)) {
      return _coresCulturas[nomeLower]!;
    }
    
    // Buscar correspondência parcial
    for (final entry in _coresCulturas.entries) {
      if (nomeLower.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Se não encontrou correspondência, retornar cor padrão
    return _corPadrao;
  }

  /// Retorna uma cor de texto contrastante (branco ou preto) baseada na cor de fundo
  static Color getContrastingTextColor(Color backgroundColor) {
    // Fórmula YIQ para determinar brilho
    final yiq = ((backgroundColor.red * 299) + 
                 (backgroundColor.green * 587) + 
                 (backgroundColor.blue * 114)) / 1000;
    
    // Retorna branco para cores escuras e preto para cores claras
    return yiq >= 128 ? Colors.black : Colors.white;
  }

  /// Retorna uma versão mais clara da cor para uso em fundos
  static Color getLightBackgroundColor(Color baseColor) {
    return baseColor.withOpacity(0.1);
  }

  /// Retorna uma versão mais escura da cor para uso em bordas
  static Color getDarkBorderColor(Color baseColor) {
    return baseColor.withOpacity(0.7);
  }

  /// Lista todas as cores disponíveis para culturas
  static List<Color> getAllCultureColors() {
    return _coresCulturas.values.toSet().toList();
  }

  /// Lista todos os nomes de culturas mapeadas
  static List<String> getAllCultureNames() {
    return _coresCulturas.keys.toList();
  }

  /// Verifica se uma cultura tem cor específica mapeada
  static bool hasSpecificColor(String nomeCultura) {
    final nomeLower = nomeCultura.toLowerCase().trim();
    
    if (_coresCulturas.containsKey(nomeLower)) {
      return true;
    }
    
    for (final key in _coresCulturas.keys) {
      if (nomeLower.contains(key)) {
        return true;
      }
    }
    
    return false;
  }
}
