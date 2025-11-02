import 'package:flutter/material.dart';

/// Serviço para gerenciar ícones das culturas
class CulturaIconService {
  static const Map<String, String> _culturaImagePaths = {
    'soja': 'assets/icons/culturas/Soja.png.png',
    'milho': 'assets/icons/culturas/Milho.png.png',
    'feijao': 'assets/icons/culturas/Feijao.png.png',
    'arroz': 'assets/icons/culturas/Arroz.png.png',
    'trigo': 'assets/icons/culturas/Trigo.png.png',
    'algodao': 'assets/icons/culturas/Algodao.png.png',
    'girassol': 'assets/icons/culturas/Girassol.png.png',
    'cana-de-acucar': 'assets/icons/culturas/Cana-de-Açucar.png.png',
    'sorgo': 'assets/icons/culturas/Sorgo.png.png',
    'aveia': 'assets/icons/culturas/Aveia.png.png',
    'gergilim': 'assets/icons/culturas/Gergilim.png.png',
  };

  /// Obtém o caminho da imagem para uma cultura
  static String? getImagePathForCultura(String culturaNome) {
    final normalizedName = _normalizeCulturaName(culturaNome);
    return _culturaImagePaths[normalizedName];
  }

  /// Normaliza o nome da cultura para busca
  static String _normalizeCulturaName(String nome) {
    return nome.toLowerCase()
        .replaceAll('ã', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(' ', '-')
        .replaceAll('á', 'a');
  }

  /// Cria um widget de ícone para a cultura (imagem ou ícone padrão)
  static Widget getCulturaIcon({
    required String culturaNome,
    double size = 24.0,
    Color? backgroundColor,
    Color? iconColor,
    BoxShape shape = BoxShape.circle,
  }) {
    final imagePath = getImagePathForCultura(culturaNome);
    
    if (imagePath != null) {
      // Usar imagem da cultura
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: shape,
          border: Border.all(
            color: iconColor ?? Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            imagePath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon(culturaNome, size, backgroundColor, iconColor);
            },
          ),
        ),
      );
    } else {
      // Usar ícone padrão
      return _buildFallbackIcon(culturaNome, size, backgroundColor, iconColor);
    }
  }

  /// Cria ícone de fallback quando não há imagem
  static Widget _buildFallbackIcon(
    String culturaNome,
    double size,
    Color? backgroundColor,
    Color? iconColor,
  ) {
    final iconData = _getDefaultIconForCultura(culturaNome);
    final color = backgroundColor ?? _getDefaultColorForCultura(culturaNome);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor ?? Colors.white,
          width: 1,
        ),
      ),
      child: Icon(
        iconData,
        color: iconColor ?? Colors.white,
        size: size * 0.6,
      ),
    );
  }

  /// Obtém ícone padrão para cultura
  static IconData _getDefaultIconForCultura(String culturaNome) {
    final nomeLower = culturaNome.toLowerCase();
    
    if (nomeLower.contains('soja')) return Icons.eco;
    if (nomeLower.contains('milho')) return Icons.grain;
    if (nomeLower.contains('feijao') || nomeLower.contains('feijão')) return Icons.circle;
    if (nomeLower.contains('arroz')) return Icons.grain;
    if (nomeLower.contains('trigo')) return Icons.grain;
    if (nomeLower.contains('algodao') || nomeLower.contains('algodão')) return Icons.texture;
    if (nomeLower.contains('girassol')) return Icons.wb_sunny;
    if (nomeLower.contains('cana')) return Icons.grass;
    if (nomeLower.contains('sorgo')) return Icons.grain;
    if (nomeLower.contains('aveia')) return Icons.grain;
    if (nomeLower.contains('gergilim') || nomeLower.contains('gergelim')) return Icons.circle;
    
    return Icons.eco;
  }

  /// Obtém cor padrão para cultura
  static Color _getDefaultColorForCultura(String culturaNome) {
    final nomeLower = culturaNome.toLowerCase();
    
    if (nomeLower.contains('soja')) return Colors.green;
    if (nomeLower.contains('milho')) return Colors.yellow.shade700;
    if (nomeLower.contains('feijao') || nomeLower.contains('feijão')) return Colors.brown;
    if (nomeLower.contains('arroz')) return Colors.green.shade600;
    if (nomeLower.contains('trigo')) return Colors.amber;
    if (nomeLower.contains('algodao') || nomeLower.contains('algodão')) return Colors.blue;
    if (nomeLower.contains('girassol')) return Colors.orange;
    if (nomeLower.contains('cana')) return Colors.green.shade800;
    if (nomeLower.contains('sorgo')) return Colors.orange.shade700;
    if (nomeLower.contains('aveia')) return Colors.grey.shade600;
    if (nomeLower.contains('gergilim') || nomeLower.contains('gergelim')) return Colors.brown.shade600;
    
    return Colors.grey;
  }

  /// Lista todas as culturas que têm imagens disponíveis
  static List<String> getCulturasComImagens() {
    return _culturaImagePaths.keys.toList();
  }

  /// Verifica se uma cultura tem imagem disponível
  static bool hasImageForCultura(String culturaNome) {
    final normalizedName = _normalizeCulturaName(culturaNome);
    return _culturaImagePaths.containsKey(normalizedName);
  }
}
