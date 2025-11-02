import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../repositories/talhao_repository.dart';
import '../utils/logger.dart';

/// Serviço para sugestão inteligente de nomes para talhões
class IntelligentNamingService {
  static final IntelligentNamingService _instance = IntelligentNamingService._internal();
  factory IntelligentNamingService() => _instance;
  IntelligentNamingService._internal();

  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  
  // Padrões de nomenclatura
  static const List<String> _direcoes = ['Norte', 'Sul', 'Leste', 'Oeste', 'Nordeste', 'Noroeste', 'Sudeste', 'Sudoeste'];
  static const List<String> _caracteristicas = ['Alto', 'Baixo', 'Plano', 'Inclinado', 'Fértil', 'Seco', 'Úmido'];
  static const List<String> _culturas = ['Soja', 'Milho', 'Algodão', 'Feijão', 'Arroz', 'Trigo'];
  
  /// Gera sugestões inteligentes de nomes para um talhão
  Future<List<String>> generateNameSuggestions({
    required double latitude,
    required double longitude,
    required double area,
    String? cultura,
    String? safra,
    List<LatLng>? pontos,
  }) async {
    try {
      final suggestions = <String>[];
      
      // 1. Sugestão baseada em coordenadas
      suggestions.addAll(_generateCoordinateBasedNames(latitude, longitude));
      
      // 2. Sugestão baseada na área
      suggestions.addAll(_generateAreaBasedNames(area));
      
      // 3. Sugestão baseada na cultura
      if (cultura != null) {
        suggestions.addAll(_generateCropBasedNames(cultura, safra));
      }
      
      // 4. Sugestão baseada na posição relativa
      suggestions.addAll(await _generatePositionBasedNames(latitude, longitude));
      
      // 5. Sugestão baseada em características geográficas
      if (pontos != null) {
        suggestions.addAll(_generateGeographicBasedNames(pontos));
      }
      
      // 6. Sugestão baseada na ordem de criação
      suggestions.addAll(await _generateOrderBasedNames());
      
      // 7. Sugestão baseada em padrões existentes
      suggestions.addAll(await _generatePatternBasedNames());
      
      // Remover duplicatas e limitar a 10 sugestões
      final uniqueSuggestions = suggestions.toSet().toList();
      uniqueSuggestions.sort();
      
      return uniqueSuggestions.take(10).toList();
    } catch (e) {
      Logger.error('Erro ao gerar sugestões de nomes: $e');
      return ['Talhão 01', 'Talhão 02', 'Talhão 03'];
    }
  }
  
  /// Gera nomes baseados em coordenadas
  List<String> _generateCoordinateBasedNames(double lat, double lng) {
    final suggestions = <String>[];
    
    // Usar coordenadas arredondadas
    final latRounded = (lat * 1000).round() / 1000;
    final lngRounded = (lng * 1000).round() / 1000;
    
    suggestions.add('Talhão ${latRounded.toStringAsFixed(3)}');
    suggestions.add('Talhão ${lngRounded.toStringAsFixed(3)}');
    
    // Usar coordenadas como identificador único
    final coordId = '${latRounded.toStringAsFixed(3).replaceAll('.', '')}_${lngRounded.toStringAsFixed(3).replaceAll('.', '')}';
    suggestions.add('Talhão $coordId');
    
    return suggestions;
  }
  
  /// Gera nomes baseados na área
  List<String> _generateAreaBasedNames(double area) {
    final suggestions = <String>[];
    
    if (area < 1) {
      suggestions.add('Talhão Pequeno');
      suggestions.add('Talhão ${(area * 1000).round()}m²');
    } else if (area < 5) {
      suggestions.add('Talhão Médio');
      suggestions.add('Talhão ${area.toStringAsFixed(1)}ha');
    } else {
      suggestions.add('Talhão Grande');
      suggestions.add('Talhão ${area.toStringAsFixed(0)}ha');
    }
    
    // Nome baseado no tamanho relativo
    if (area > 10) {
      suggestions.add('Talhão Extenso');
    } else if (area < 0.5) {
      suggestions.add('Talhão Compacto');
    }
    
    return suggestions;
  }
  
  /// Gera nomes baseados na cultura
  List<String> _generateCropBasedNames(String cultura, String? safra) {
    final suggestions = <String>[];
    
    suggestions.add('Talhão $cultura');
    suggestions.add('$cultura Principal');
    
    if (safra != null) {
      suggestions.add('$cultura $safra');
      suggestions.add('Talhão $cultura $safra');
    }
    
    // Nome baseado na estação
    final now = DateTime.now();
    final month = now.month;
    
    if (month >= 3 && month <= 5) {
      suggestions.add('$cultura Outono');
    } else if (month >= 6 && month <= 8) {
      suggestions.add('$cultura Inverno');
    } else if (month >= 9 && month <= 11) {
      suggestions.add('$cultura Primavera');
    } else {
      suggestions.add('$cultura Verão');
    }
    
    return suggestions;
  }
  
  /// Gera nomes baseados na posição relativa
  Future<List<String>> _generatePositionBasedNames(double lat, double lng) async {
    final suggestions = <String>[];
    
    try {
      // Obter todos os talhões existentes
      final existingTalhoes = await _talhaoRepository.getTalhoes();
      
      if (existingTalhoes.isNotEmpty) {
        // Encontrar o talhão mais próximo
        TalhaoModel? nearestTalhao;
        double minDistance = double.infinity;
        
        for (final talhao in existingTalhoes) {
          if (talhao.points.isNotEmpty) {
            final talhaoCenter = _calculateCenter(talhao.points);
            final distance = _calculateDistance(lat, lng, talhaoCenter.latitude, talhaoCenter.longitude);
            
            if (distance < minDistance) {
              minDistance = distance;
              nearestTalhao = talhao;
            }
          }
        }
        
        if (nearestTalhao != null) {
          // Determinar direção relativa
          final direction = _getRelativeDirection(lat, lng, nearestTalhao.points.first.latitude, nearestTalhao.points.first.longitude);
          suggestions.add('Talhão $direction');
          suggestions.add('${nearestTalhao.name} $direction');
        }
      }
      
      // Sugestões baseadas em direções cardeais
      final direction = _getCardinalDirection(lat, lng);
      suggestions.add('Talhão $direction');
      suggestions.add('$direction Principal');
      
    } catch (e) {
      Logger.error('Erro ao gerar nomes baseados em posição: $e');
    }
    
    return suggestions;
  }
  
  /// Gera nomes baseados em características geográficas
  List<String> _generateGeographicBasedNames(List<LatLng> pontos) {
    final suggestions = <String>[];
    
    if (pontos.length < 3) return suggestions;
    
    // Calcular características do polígono
    final area = _calculatePolygonArea(pontos);
    final perimeter = _calculatePolygonPerimeter(pontos);
    final compactness = (4 * pi * area) / (perimeter * perimeter);
    
    // Nome baseado na forma
    if (compactness > 0.8) {
      suggestions.add('Talhão Circular');
    } else if (compactness > 0.6) {
      suggestions.add('Talhão Regular');
    } else {
      suggestions.add('Talhão Irregular');
    }
    
    // Nome baseado no número de vértices
    if (pontos.length <= 4) {
      suggestions.add('Talhão Simples');
    } else if (pontos.length <= 8) {
      suggestions.add('Talhão Complexo');
    } else {
      suggestions.add('Talhão Detalhado');
    }
    
    return suggestions;
  }
  
  /// Gera nomes baseados na ordem de criação
  Future<List<String>> _generateOrderBasedNames() async {
    final suggestions = <String>[];
    
    try {
      final existingTalhoes = await _talhaoRepository.getTalhoes();
      final nextNumber = existingTalhoes.length + 1;
      
      suggestions.add('Talhão ${nextNumber.toString().padLeft(2, '0')}');
      suggestions.add('Talhão #$nextNumber');
      
      // Verificar se há padrão numérico
      final numericNames = existingTalhoes
          .where((t) => t.name.contains(RegExp(r'\d+')))
          .map((t) => int.tryParse(t.name.replaceAll(RegExp(r'[^\d]'), '')))
          .where((n) => n != null)
          .cast<int>()
          .toList();
      
      if (numericNames.isNotEmpty) {
        numericNames.sort();
        final maxNumber = numericNames.last;
        suggestions.add('Talhão ${(maxNumber + 1).toString().padLeft(2, '0')}');
      }
      
    } catch (e) {
      Logger.error('Erro ao gerar nomes baseados em ordem: $e');
    }
    
    return suggestions;
  }
  
  /// Gera nomes baseados em padrões existentes
  Future<List<String>> _generatePatternBasedNames() async {
    final suggestions = <String>[];
    
    try {
      final existingTalhoes = await _talhaoRepository.getTalhoes();
      
      if (existingTalhoes.isNotEmpty) {
        // Analisar padrões de nomenclatura existentes
        final names = existingTalhoes.map((t) => t.name).toList();
        
        // Verificar se há prefixos comuns
        final prefixes = <String, int>{};
        for (final name in names) {
          final words = name.split(' ');
          if (words.isNotEmpty) {
            final prefix = words.first;
            prefixes[prefix] = (prefixes[prefix] ?? 0) + 1;
          }
        }
        
        // Sugerir baseado no prefixo mais comum
        if (prefixes.isNotEmpty) {
          final mostCommonPrefix = prefixes.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          
          if (mostCommonPrefix != 'Talhão') {
            suggestions.add('$mostCommonPrefix ${DateTime.now().year}');
          }
        }
        
        // Verificar se há sufixos comuns
        final suffixes = <String, int>{};
        for (final name in names) {
          final words = name.split(' ');
          if (words.length > 1) {
            final suffix = words.last;
            suffixes[suffix] = (suffixes[suffix] ?? 0) + 1;
          }
        }
        
        // Sugerir baseado no sufixo mais comum
        if (suffixes.isNotEmpty) {
          final mostCommonSuffix = suffixes.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          
          if (mostCommonSuffix != '01' && mostCommonSuffix != '02') {
            suggestions.add('Talhão $mostCommonSuffix');
          }
        }
      }
      
    } catch (e) {
      Logger.error('Erro ao gerar nomes baseados em padrões: $e');
    }
    
    return suggestions;
  }
  
  /// Calcula o centro de um conjunto de pontos
  LatLng _calculateCenter(List<LatLng> pontos) {
    double lat = 0, lng = 0;
    for (final ponto in pontos) {
      lat += ponto.latitude;
      lng += ponto.longitude;
    }
    return LatLng(lat / pontos.length, lng / pontos.length);
  }
  
  /// Calcula distância entre dois pontos
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // metros
    
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Obtém direção relativa entre dois pontos
  String _getRelativeDirection(double lat1, double lng1, double lat2, double lng2) {
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    
    if (dLat.abs() > dLng.abs()) {
      return dLat > 0 ? 'Sul' : 'Norte';
    } else {
      return dLng > 0 ? 'Oeste' : 'Leste';
    }
  }
  
  /// Obtém direção cardeal baseada em coordenadas
  String _getCardinalDirection(double lat, double lng) {
    // Simplificado: usar latitude para determinar norte/sul
    if (lat > 0) {
      return lng > 0 ? 'Nordeste' : 'Noroeste';
    } else {
      return lng > 0 ? 'Sudeste' : 'Sudoeste';
    }
  }
  
  /// Calcula área de um polígono
  double _calculatePolygonArea(List<LatLng> pontos) {
    if (pontos.length < 3) return 0;
    
    double area = 0;
    for (int i = 0; i < pontos.length; i++) {
      int j = (i + 1) % pontos.length;
      area += pontos[i].latitude * pontos[j].longitude;
      area -= pontos[j].latitude * pontos[i].longitude;
    }
    return area.abs() / 2;
  }
  
  /// Calcula perímetro de um polígono
  double _calculatePolygonPerimeter(List<LatLng> pontos) {
    if (pontos.length < 2) return 0;
    
    double perimeter = 0;
    for (int i = 0; i < pontos.length; i++) {
      int j = (i + 1) % pontos.length;
      perimeter += _calculateDistance(
        pontos[i].latitude, pontos[i].longitude,
        pontos[j].latitude, pontos[j].longitude,
      );
    }
    return perimeter;
  }
  
  /// Valida se um nome é apropriado
  bool validateName(String name) {
    if (name.isEmpty || name.length > 50) return false;
    
    // Verificar caracteres especiais indesejados
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(name)) return false;
    
    // Verificar se não é muito genérico
    final genericNames = ['Talhão', 'Plot', 'Área', 'Campo'];
    if (genericNames.contains(name)) return false;
    
    return true;
  }
  
  /// Sugere melhorias para um nome
  List<String> suggestNameImprovements(String currentName) {
    final suggestions = <String>[];
    
    if (currentName.isEmpty) {
      suggestions.add('Adicione um nome descritivo');
      return suggestions;
    }
    
    if (currentName.length < 3) {
      suggestions.add('Nome muito curto - adicione mais detalhes');
    }
    
    if (currentName.length > 30) {
      suggestions.add('Nome muito longo - considere abreviar');
    }
    
    if (currentName.contains(' ')) {
      suggestions.add('Considere usar hífen em vez de espaços');
    }
    
    if (!currentName.contains(RegExp(r'\d'))) {
      suggestions.add('Considere adicionar um número para identificação');
    }
    
    return suggestions;
  }
} 