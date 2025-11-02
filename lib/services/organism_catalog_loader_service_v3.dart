import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/organism_catalog_v3.dart';
import '../utils/logger.dart';

/// Serviço para carregar dados do catálogo de organismos v3.0
/// Suporta backward compatibility com v2.0
class OrganismCatalogLoaderServiceV3 {
  static const String _basePath = 'assets/data';
  
  /// Carrega todos os organismos de todas as culturas (v3.0)
  Future<List<OrganismCatalogV3>> loadAllOrganismsV3() async {
    try {
      List<OrganismCatalogV3> allOrganisms = [];
      
      final cultures = [
        'soja', 'milho', 'algodao', 'arroz', 'aveia',
        'cana_acucar', 'feijao', 'gergelim', 'girassol',
        'sorgo', 'tomate', 'trigo', 'batata'
      ];
      
      for (final culture in cultures) {
        try {
          final organisms = await _loadCultureOrganismsV3(culture);
          allOrganisms.addAll(organisms);
          Logger.info('✅ Carregados ${organisms.length} organismos da cultura $culture (v3.0)');
        } catch (e) {
          Logger.warning('⚠️ Erro ao carregar cultura $culture: $e');
        }
      }
      
      Logger.info('✅ Total carregado: ${allOrganisms.length} organismos v3.0');
      return allOrganisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar organismos v3.0: $e');
      return [];
    }
  }
  
  /// Carrega organismos de uma cultura específica (v3.0)
  Future<List<OrganismCatalogV3>> loadCultureOrganismsV3(String cultureName) async {
    try {
      return await _loadCultureOrganismsV3(cultureName);
    } catch (e) {
      Logger.error('❌ Erro ao carregar cultura $cultureName: $e');
      return [];
    }
  }
  
  /// Método interno para carregar cultura
  Future<List<OrganismCatalogV3>> _loadCultureOrganismsV3(String cultureName) async {
    try {
      final filePath = '$_basePath/organismos_$cultureName.json';
      final jsonString = await rootBundle.loadString(filePath);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      final culturaNome = data['cultura']?.toString() ?? cultureName;
      final organismos = (data['organismos'] as List? ?? []) as List;
      
      final organismosV3 = organismos.map((org) {
        return OrganismCatalogV3.fromJson(
          org as Map<String, dynamic>,
          cropId: cultureName,
          cropName: culturaNome,
        );
      }).toList();
      
      return organismosV3;
      
    } catch (e) {
      Logger.error('❌ Erro ao processar cultura $cultureName: $e');
      return [];
    }
  }
  
  /// Busca organismo por ID (v3.0)
  Future<OrganismCatalogV3?> findOrganismById(String organismId) async {
    try {
      final allOrganisms = await loadAllOrganismsV3();
      return allOrganisms.firstWhere(
        (org) => org.id == organismId,
        orElse: () => throw Exception('Organismo não encontrado'),
      );
    } catch (e) {
      Logger.warning('⚠️ Organismo não encontrado: $organismId');
      return null;
    }
  }
  
  /// Busca organismos por cultura e categoria (v3.0)
  Future<List<OrganismCatalogV3>> findOrganismsByCategory({
    required String culture,
    required String category, // 'Praga', 'Doença', 'Planta Daninha'
  }) async {
    try {
      final allOrganisms = await loadAllOrganismsV3();
      return allOrganisms.where((org) {
        final categoriaMatch = category == 'Praga' && org.type.toString().contains('pest') ||
                              category == 'Doença' && org.type.toString().contains('disease') ||
                              category == 'Planta Daninha' && org.type.toString().contains('weed');
        
        final culturaMatch = org.affectedCrops.any((c) => 
          c.toLowerCase() == culture.toLowerCase()
        );
        
        return categoriaMatch && culturaMatch;
      }).toList();
      
    } catch (e) {
      Logger.error('❌ Erro ao buscar organismos por categoria: $e');
      return [];
    }
  }
}

