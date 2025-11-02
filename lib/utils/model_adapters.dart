// Arquivo para adaptação/conversão entre modelos antigos e novos.
// Agora com suporte ao TalhaoModel unificado.


import 'package:flutter/material.dart';
import '../models/talhao_model.dart';
import '../models/poligono_model.dart';
import 'package:uuid/uuid.dart';

import '../models/safra_model.dart';
import 'package:latlong2/latlong.dart';
import '../models/crop.dart' as app_crop;
import '../models/agricultural_product.dart';
import '../utils/color_converter.dart';

class ModelAdapters {
  /// Converte um AgriculturalProduct para o modelo Crop da aplicação
  static app_crop.Crop agriculturalProductToAppCrop(AgriculturalProduct product) {
    int? color;
    if (product.colorValue != null) {
      color = int.tryParse(product.colorValue!.replaceFirst('#', ''), radix: 16);
      if (color != null) {
        color = 0xFF000000 | color; // Adiciona canal alfa
      }
    }
    return app_crop.Crop(
      id: int.tryParse(product.id) ?? 0,
      name: product.name,
      description: product.notes ?? '',
      colorValue: color,
    );
  }

  /// Converte um Crop da aplicação para AgriculturalProduct
  static AgriculturalProduct appCropToAgriculturalProduct(app_crop.Crop crop) {
    String? colorString;
    if (crop.colorValue != null) {
      // Remove o canal alfa e converte para string hexadecimal
      colorString = '#${(crop.colorValue! & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';
    }
    return AgriculturalProduct(
      id: crop.id?.toString() ?? '',
      name: crop.name,
      notes: crop.description,
      colorValue: colorString,
      type: ProductType.seed,
    );
  }

  /// Converte um modelo legado para o TalhaoModel unificado
  static TalhaoModel convertLegacyToUnified(Map<String, dynamic> legacyData) {
    // Extrair dados do modelo legado
    final String id = legacyData['id']?.toString() ?? const Uuid().v4();
    final String name = legacyData['nome'] as String? ?? legacyData['name'] as String? ?? '';
    final double area = (legacyData['area'] as num?)?.toDouble() ?? 0.0;
    final bool sincronizado = legacyData['sincronizado'] as bool? ?? false;
    final DateTime dataCriacao = legacyData['criadoEm'] != null 
        ? DateTime.tryParse(legacyData['criadoEm'].toString()) ?? DateTime.now()
        : DateTime.now();
    final DateTime dataAtualizacao = legacyData['atualizadoEm'] != null 
        ? DateTime.tryParse(legacyData['atualizadoEm'].toString()) ?? DateTime.now()
        : DateTime.now();
    
    // Extrair pontos do polígono
    List<LatLng> points = [];
    if (legacyData['poligonos'] != null) {
      final poligonos = legacyData['poligonos'] as List<dynamic>;
      if (poligonos.isNotEmpty) {
        final pontos = poligonos[0] as List<dynamic>;
        points = pontos.map((p) => LatLng(
          (p['latitude'] as num).toDouble(),
          (p['longitude'] as num).toDouble(),
        )).toList();
      }
    }
    // Criar polígono
    final poligono = PoligonoModel.criar(
      pontos: points,
      talhaoId: id,
      area: area,
    );
    
    // Extrair informações de cultura
    final int? cropId = legacyData['culturaId'] as int?;
    final String? culturaNome = legacyData['cultura'] as String?;
    
    // Criar safra se houver informações de cultura
    List<SafraModel> safras = [];
    if (culturaNome != null && culturaNome.isNotEmpty) {
      final safra = SafraModel.criar(
        talhaoId: id,
        safra: '2024/2025',
        culturaId: cropId?.toString() ?? '0',
        culturaNome: culturaNome,
        culturaCor: ColorConverter.colorToHex(const Color(0xFF4CAF50)), // Cor padrão para cultura (verde)
      );
      safras = [safra];
    }
    // Criar o TalhaoModel unificado
    return TalhaoModel(
      id: id,
      name: name,
      poligonos: [poligono],
      area: area,
      dataCriacao: dataCriacao,
      dataAtualizacao: dataAtualizacao,
      sincronizado: sincronizado,
      safras: safras,
      cropId: cropId,

    );
  }
  
  /// Converte um TalhaoModel unificado para um formato de mapa legado
  static Map<String, dynamic> convertToLegacyMap(TalhaoModel model) {
    // Converter todos os polígonos para o formato legado
    final List<List<Map<String, double>>> poligonos = model.poligonos.map((poligono) =>
      poligono.pontos.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
      }).toList()
    ).toList();
    
    // Obter informações de cultura da safra atual
    final safraAtual = model.safraAtual;
    final String? culturaNome = safraAtual?.culturaNome;
    
    // Criar mapa no formato legado
    return {
      'id': model.id,
      'nome': model.name,
      'area': model.area,
      'poligonos': poligonos,
      'criadoEm': model.createdAt?.toIso8601String(),
      'atualizadoEm': model.updatedAt?.toIso8601String(),
      'sincronizado': model.sincronizado,
      'cultura': culturaNome,
      'culturaId': model.cropId,
    };
  }
  
  /// Converte uma lista de mapas legados para uma lista de TalhaoModel unificado
  static List<TalhaoModel> convertLegacyListToUnified(List<Map<String, dynamic>> legacyList) {
    return legacyList.map((data) => convertLegacyToUnified(data)).toList();
  }
  
  /// Converte uma lista de TalhaoModel unificado para uma lista de mapas legados
  static List<Map<String, dynamic>> convertToLegacyMapList(List<TalhaoModel> models) {
    return models.map((model) => convertToLegacyMap(model)).toList();
  }
  
  /// Converte uma lista de objetos dinâmicos para uma lista de TalhaoModel
  static List<TalhaoModel> convertToNewTalhaoModelList(List<dynamic> talhoes) {
    try {
      return talhoes.map((talhao) {
        if (talhao is TalhaoModel) {
          return talhao;
        } else if (talhao is Map<String, dynamic>) {
          return convertLegacyToUnified(talhao);
        } else {
          // Tenta converter para Map<String, dynamic> se possível
          try {
            final Map<String, dynamic> talhaoMap = Map<String, dynamic>.from(talhao as Map);
            return convertLegacyToUnified(talhaoMap);
          } catch (e) {
            debugPrint('Erro ao converter talhão: $e');
            // Retorna um modelo vazio em caso de erro
            return TalhaoModel(
              id: const Uuid().v4(),
              name: 'Erro de conversão',
              poligonos: [],
              area: 0.0,
              dataCriacao: DateTime.now(),
              dataAtualizacao: DateTime.now(),
              sincronizado: false,
              safras: [],

              fazendaId: '0', // ID de fazenda padrão
            );
          }
        }
      }).cast<TalhaoModel>().toList();
    } catch (e) {
      debugPrint('Erro ao converter lista de talhões: $e');
      return [];
    }
  }
  
  /// Cria um TalhaoModel a partir de dados básicos, usando o construtor padrão.
  static TalhaoModel createTalhaoModel({
    required String name,
    required List<PoligonoModel> poligonos,
    double? area,
    int? cropId,
    List<SafraModel> safras = const [],
    String? fazendaId,
  }) {
    return TalhaoModel.criar(
      nome: name,
      pontos: [], // Lista vazia para compatibilidade, já que estamos usando poligonos
      poligonos: poligonos,
      area: area,
      culturaId: cropId,
      safras: safras,
      fazendaId: fazendaId ?? '0', // Adicionando ID de fazenda padrão
    );
  }
}
