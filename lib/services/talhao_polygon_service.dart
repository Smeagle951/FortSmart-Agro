import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhoes/talhao_safra_model.dart';
import '../models/poligono_model.dart';
import '../utils/cultura_colors.dart';

/// Serviço para gerenciar a exibição e persistência dos polígonos dos talhões
class TalhaoPolygonService {
  
  /// Constrói polígonos para exibição no mapa
  /// Resolve problemas de conversão de dados e cores
  List<Polygon> buildPolygonsForMap({
    required List<dynamic> talhoes,
    TalhaoSafraModel? selectedTalhao,
    bool showLabels = true,
    double defaultOpacity = 0.4,
    double selectedOpacity = 0.6,
  }) {
    final List<Polygon> polygons = [];
    
    debugPrint('🔍 buildPolygonsForMap: Processando ${talhoes.length} talhões');
    
    for (final talhao in talhoes) {
      try {
        debugPrint('🔍 Processando talhão: ${talhao.name} (ID: ${talhao.id})');
        
        // Verificar se o talhão tem pontos diretamente (formato antigo)
        if (talhao.pontos != null && talhao.pontos.isNotEmpty) {
          debugPrint('🔍 Talhão tem pontos diretos: ${talhao.pontos.length}');
          final pontos = _convertPointsToLatLng(talhao.pontos);
          
          if (pontos.length >= 3) {
            final isSelected = selectedTalhao?.id == talhao.id;
            final opacity = isSelected ? selectedOpacity : defaultOpacity;
            final pontosFechados = _closePolygon(pontos);
            
            debugPrint('✅ Criando polígono direto para ${talhao.name}: ${pontosFechados.length} pontos');
            
            // Obter cor da cultura se disponível
            Color corPoligono = Colors.green;
            Color corBorda = Colors.green.withOpacity(0.8);
            Color corTexto = Colors.white;
            
            // Tentar obter cor da cultura do talhão
            if (talhao.safras != null && talhao.safras.isNotEmpty) {
              final safra = talhao.safras.first;
              if (safra.culturaCor != null) {
                corPoligono = Color(safra.culturaCor);
                corBorda = Color(safra.culturaCor).withOpacity(0.8);
                // Usar cor de texto contrastante
                corTexto = CulturaColorsUtils.getContrastingTextColor(Color(safra.culturaCor));
              } else if (safra.culturaNome != null) {
                corPoligono = CulturaColorsUtils.getColorForName(safra.culturaNome);
                corBorda = CulturaColorsUtils.getColorForName(safra.culturaNome).withOpacity(0.8);
                corTexto = CulturaColorsUtils.getContrastingTextColor(CulturaColorsUtils.getColorForName(safra.culturaNome));
              }
            }
            
            polygons.add(Polygon(
              points: pontosFechados,
              color: corPoligono.withOpacity(opacity),
              borderColor: isSelected ? Colors.yellow : corBorda,
              borderStrokeWidth: isSelected ? 4.0 : 2.5,
              isFilled: true,
              label: showLabels ? talhao.name : null,
              labelStyle: TextStyle(
                color: corTexto,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                backgroundColor: Colors.black54,
              ),
            ));
          }
        }
        
        // Verificar se o talhão tem polígonos (formato novo)
        if (talhao.poligonos != null && talhao.poligonos.isNotEmpty) {
          debugPrint('🔍 Talhão tem polígonos: ${talhao.poligonos.length}');
          
          for (final poligono in talhao.poligonos) {
            if (poligono.pontos != null && poligono.pontos.length >= 3) {
              final isSelected = selectedTalhao?.id == talhao.id;
              final opacity = isSelected ? selectedOpacity : defaultOpacity;
              
              // Converter pontos para LatLng corretamente
              final pontos = _convertPointsToLatLng(poligono.pontos);
              
              debugPrint('🔍 Polígono ${talhao.name}: ${pontos.length} pontos convertidos');
              
              if (pontos.length >= 3) {
                // Garantir que o polígono está fechado
                final pontosFechados = _closePolygon(pontos);
                
                debugPrint('🔍 Polígono ${talhao.name}: ${pontosFechados.length} pontos após fechamento');
                
                // Obter cor da cultura se disponível
                Color corPoligono = Colors.green;
                Color corBorda = Colors.green.withOpacity(0.8);
                Color corTexto = Colors.white;
                
                // Tentar obter cor da cultura do talhão
                if (talhao.safras != null && talhao.safras.isNotEmpty) {
                  final safra = talhao.safras.first;
                  if (safra.culturaCor != null) {
                    corPoligono = Color(safra.culturaCor);
                    corBorda = Color(safra.culturaCor).withOpacity(0.8);
                    // Usar cor de texto contrastante
                    corTexto = CulturaColorsUtils.getContrastingTextColor(Color(safra.culturaCor));
                  } else if (safra.culturaNome != null) {
                    corPoligono = CulturaColorsUtils.getColorForName(safra.culturaNome);
                    corBorda = CulturaColorsUtils.getColorForName(safra.culturaNome).withOpacity(0.8);
                    corTexto = CulturaColorsUtils.getContrastingTextColor(CulturaColorsUtils.getColorForName(safra.culturaNome));
                  }
                }
                
                polygons.add(Polygon(
                  points: pontosFechados,
                  color: corPoligono.withOpacity(opacity),
                  borderColor: isSelected ? Colors.yellow : corBorda,
                  borderStrokeWidth: isSelected ? 4.0 : 2.5,
                  isFilled: true,
                  label: showLabels ? talhao.name : null,
                  labelStyle: TextStyle(
                    color: corTexto,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    backgroundColor: Colors.black54,
                  ),
                ));
              }
            }
          }
        }
        
        // Se não tem nem pontos nem polígonos, tentar usar dados básicos
        if ((talhao.pontos == null || talhao.pontos.isEmpty) && 
            (talhao.poligonos == null || talhao.poligonos.isEmpty)) {
          debugPrint('⚠️ Talhão ${talhao.name} não tem pontos nem polígonos');
        }
        
      } catch (e) {
        debugPrint('❌ Erro ao processar polígono do talhão ${talhao.name}: $e');
        debugPrint('❌ Stack trace: ${StackTrace.current}');
      }
    }
    
    debugPrint('✅ buildPolygonsForMap: Retornando ${polygons.length} polígonos');
    return polygons;
  }
  
  /// Constrói polylines para melhor visualização dos talhões
  List<Polyline> buildPolylinesForMap({
    required List<dynamic> talhoes,
    TalhaoSafraModel? selectedTalhao,
    double defaultStrokeWidth = 2.0,
    double selectedStrokeWidth = 4.0,
  }) {
    final List<Polyline> polylines = [];
    
    for (final talhao in talhoes) {
      try {
        if (talhao.poligonos != null && talhao.poligonos.isNotEmpty) {
          for (final poligono in talhao.poligonos) {
            if (poligono.pontos != null && poligono.pontos.length >= 3) {
              final isSelected = selectedTalhao?.id == talhao.id;
              final strokeWidth = isSelected ? selectedStrokeWidth : defaultStrokeWidth;
              
              // Converter pontos para LatLng corretamente
              final pontos = _convertPointsToLatLng(poligono.pontos);
              
              if (pontos.length >= 3) {
                // Garantir que o polígono está fechado
                final pontosFechados = _closePolygon(pontos);
                
                polylines.add(Polyline(
                  points: pontosFechados,
                  color: isSelected ? Colors.yellow : Colors.green,
                  strokeWidth: strokeWidth,
                ));
              }
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Erro ao processar polyline do talhão ${talhao.name}: $e');
      }
    }
    
    return polylines;
  }
  
  /// Constrói marcadores simples para os talhões
  List<Marker> buildMarkersForMap({
    required List<dynamic> talhoes,
    required Function(dynamic) onTalhaoTap,
    double markerSize = 24.0,
  }) {
    final List<Marker> markers = [];
    
    for (final talhao in talhoes) {
      try {
        if (talhao.poligonos != null && talhao.poligonos.isNotEmpty) {
          for (final poligono in talhao.poligonos) {
            if (poligono.pontos != null && poligono.pontos.length >= 3) {
              // Calcular centro do polígono
              final centro = _calculatePolygonCenter(poligono.pontos);
              
              // Buscar nome da cultura para exibir
              String nomeCultura = 'Talhão';
              if (talhao.culturaId != null) {
                // Aqui você pode buscar o nome da cultura pelo ID se necessário
                nomeCultura = 'Cultura';
              }
              
              markers.add(Marker(
                point: centro,
                width: 80,
                height: 30,
                child: GestureDetector(
                  onTap: () {
                    onTalhaoTap(talhao);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      nomeCultura,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ));
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Erro ao processar marcador do talhão ${talhao.name}: $e');
      }
    }
    
    return markers;
  }
  
  /// Converte pontos para LatLng corretamente
  List<LatLng> _convertPointsToLatLng(List<dynamic> pontos) {
    final List<LatLng> pontosConvertidos = [];
    
    debugPrint('🔍 _convertPointsToLatLng: Convertendo ${pontos.length} pontos');
    
    for (int i = 0; i < pontos.length; i++) {
      final ponto = pontos[i];
      if (ponto != null) {
        double? lat, lng;
        
        try {
          // Verificar diferentes formatos de ponto
          if (ponto is LatLng) {
            lat = ponto.latitude;
            lng = ponto.longitude;
            debugPrint('🔍 Ponto $i é LatLng: $lat, $lng');
          } else if (ponto.latitude != null && ponto.longitude != null) {
            lat = ponto.latitude.toDouble();
            lng = ponto.longitude.toDouble();
            debugPrint('🔍 Ponto $i tem latitude/longitude: $lat, $lng');
          } else if (ponto is Map<String, dynamic>) {
            lat = ponto['latitude']?.toDouble();
            lng = ponto['longitude']?.toDouble();
            debugPrint('🔍 Ponto $i é Map: lat=$lat, lng=$lng');
          } else if (ponto is String) {
            // Tentar parse de string (ex: "lat,lng")
            final coords = ponto.split(',');
            if (coords.length == 2) {
              lat = double.tryParse(coords[0].trim());
              lng = double.tryParse(coords[1].trim());
              debugPrint('🔍 Ponto $i é String parseada: $lat, $lng');
            }
          } else {
            debugPrint('⚠️ Ponto $i formato desconhecido: ${ponto.runtimeType}');
            debugPrint('⚠️ Conteúdo do ponto: $ponto');
          }
          
          // Validar coordenadas
          if (lat != null && lng != null && 
              lat != 0.0 && lng != 0.0 &&
              lat.abs() <= 90 && lng.abs() <= 180) {
            pontosConvertidos.add(LatLng(lat, lng));
            debugPrint('✅ Ponto $i convertido com sucesso: $lat, $lng');
          } else {
            debugPrint('⚠️ Ponto $i inválido: lat=$lat, lng=$lng');
          }
        } catch (e) {
          debugPrint('❌ Erro ao converter ponto $i: $e');
          debugPrint('❌ Ponto problemático: $ponto');
        }
      } else {
        debugPrint('⚠️ Ponto $i é null');
      }
    }
    
    debugPrint('🔍 Conversão completa: ${pontosConvertidos.length} pontos válidos de ${pontos.length} originais');
    
    // Se não conseguiu converter nenhum ponto, logar detalhes
    if (pontosConvertidos.isEmpty && pontos.isNotEmpty) {
      debugPrint('❌ NENHUM PONTO CONVERTIDO!');
      debugPrint('❌ Primeiro ponto: ${pontos.first}');
      debugPrint('❌ Tipo do primeiro ponto: ${pontos.first.runtimeType}');
      if (pontos.first is Map) {
        debugPrint('❌ Chaves do primeiro ponto: ${(pontos.first as Map).keys.toList()}');
      }
    }
    
    return pontosConvertidos;
  }
  
  /// Fecha o polígono conectando o último ponto ao primeiro
  List<LatLng> _closePolygon(List<LatLng> pontos) {
    if (pontos.isEmpty) return pontos;
    
    final pontosFechados = List<LatLng>.from(pontos);
    
    // Se o primeiro e último ponto não são iguais, adicionar o primeiro no final
    if (pontosFechados.first != pontosFechados.last) {
      pontosFechados.add(pontosFechados.first);
    }
    
    return pontosFechados;
  }
  
  /// Calcula o centro de um polígono
  LatLng _calculatePolygonCenter(List<dynamic> pontos) {
    if (pontos.isEmpty) {
      return const LatLng(0, 0);
    }
    
    double latSum = 0;
    double lngSum = 0;
    int count = 0;
    
    for (final ponto in pontos) {
      if (ponto != null) {
        double? lat, lng;
        
        if (ponto is LatLng) {
          lat = ponto.latitude;
          lng = ponto.longitude;
        } else if (ponto.latitude != null && ponto.longitude != null) {
          lat = ponto.latitude.toDouble();
          lng = ponto.longitude.toDouble();
        }
        
        if (lat != null && lng != null) {
          latSum += lat;
          lngSum += lng;
          count++;
        }
      }
    }
    
    if (count == 0) return const LatLng(0, 0);
    
    return LatLng(latSum / count, lngSum / count);
  }
  
  // Métodos de cores e ícones de culturas removidos - sistema descontinuado
  
  /// Valida se um polígono é válido
  bool isValidPolygon(List<dynamic> pontos) {
    if (pontos.length < 3) return false;
    
    try {
      final pontosConvertidos = _convertPointsToLatLng(pontos);
      return pontosConvertidos.length >= 3;
    } catch (e) {
      return false;
    }
  }
  
  /// Calcula área total de todos os talhões
  double calculateTotalArea(List<dynamic> talhoes) {
    double areaTotal = 0.0;
    
    for (final talhao in talhoes) {
      if (talhao.area != null) {
        areaTotal += talhao.area!;
      } else {
        for (final poligono in talhao.poligonos) {
          areaTotal += poligono.area;
        }
      }
    }
    
    return areaTotal;
  }
  
  /// Filtra talhões por área mínima
  List<dynamic> filterByMinArea(
    List<dynamic> talhoes,
    double minArea,
  ) {
    return talhoes.where((talhao) {
      if (talhao.area != null) {
        return talhao.area! >= minArea;
      }
      
      double areaTalhao = 0.0;
      for (final poligono in talhao.poligonos) {
        areaTalhao += poligono.area;
      }
      
      return areaTalhao >= minArea;
    }).toList();
  }
  
  // Filtro por cultura removido - sistema descontinuado
  
  /// Obtém estatísticas dos talhões
  Map<String, dynamic> getTalhoesStats(List<dynamic> talhoes) {
    if (talhoes.isEmpty) {
      return {
        'total': 0,
        'areaTotal': 0.0,
        'status': <String, int>{},
      };
    }
    
    final status = <String, int>{};
    double areaTotal = 0.0;
    
    for (final talhao in talhoes) {
      // Contar status
      final statusStr = talhao.sincronizado ? 'Sincronizado' : 'Pendente';
      status[statusStr] = (status[statusStr] ?? 0) + 1;
      
      // Calcular área
      if (talhao.area != null) {
        areaTotal += talhao.area!;
      } else {
        for (final poligono in talhao.poligonos) {
          areaTotal += poligono.area;
        }
      }
    }
    
    return {
      'total': talhoes.length,
      'areaTotal': areaTotal,
      'status': status,
    };
  }
}
