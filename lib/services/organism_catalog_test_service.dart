import 'dart:convert';
import 'package:flutter/services.dart';
import 'organism_catalog_loader_service.dart';
import '../utils/logger.dart';

/// Serviço para testar a funcionalidade do catálogo de organismos
class OrganismCatalogTestService {
  final OrganismCatalogLoaderService _loaderService = OrganismCatalogLoaderService();

  /// Testa o carregamento de todos os organismos
  Future<Map<String, dynamic>> testLoadAllOrganisms() async {
    try {
      Logger.info('🧪 Iniciando teste de carregamento de todos os organismos...');
      
      final startTime = DateTime.now();
      final organisms = await _loaderService.loadAllOrganisms();
      final endTime = DateTime.now();
      
      final duration = endTime.difference(startTime);
      
      // Agrupa por cultura
      final Map<String, int> organismsByCrop = {};
      final Map<String, int> organismsByType = {};
      
      for (var organism in organisms) {
        organismsByCrop[organism.cropName] = (organismsByCrop[organism.cropName] ?? 0) + 1;
        final typeKey = organism.type.toString().split('.').last;
        organismsByType[typeKey] = (organismsByType[typeKey] ?? 0) + 1;
      }
      
      final result = {
        'success': true,
        'total_organisms': organisms.length,
        'cultures_count': organismsByCrop.length,
        'organisms_by_crop': organismsByCrop,
        'organisms_by_type': organismsByType,
        'load_time_ms': duration.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      Logger.info('✅ Teste concluído: ${organisms.length} organismos carregados em ${duration.inMilliseconds}ms');
      return result;
      
    } catch (e) {
      Logger.error('❌ Erro no teste: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Testa o carregamento de uma cultura específica
  Future<Map<String, dynamic>> testLoadCulture(String cultureName) async {
    try {
      Logger.info('🧪 Testando carregamento da cultura: $cultureName');
      
      final startTime = DateTime.now();
      final organisms = await _loaderService.loadCultureOrganisms(cultureName);
      final endTime = DateTime.now();
      
      final duration = endTime.difference(startTime);
      
      // Agrupa por tipo
      final Map<String, int> organismsByType = {};
      for (var organism in organisms) {
        final typeKey = organism.type.toString().split('.').last;
        organismsByType[typeKey] = (organismsByType[typeKey] ?? 0) + 1;
      }
      
      final result = {
        'success': true,
        'culture': cultureName,
        'total_organisms': organisms.length,
        'organisms_by_type': organismsByType,
        'load_time_ms': duration.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      Logger.info('✅ Teste da cultura $cultureName: ${organisms.length} organismos em ${duration.inMilliseconds}ms');
      return result;
      
    } catch (e) {
      Logger.error('❌ Erro no teste da cultura $cultureName: $e');
      return {
        'success': false,
        'culture': cultureName,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Testa a funcionalidade de busca
  Future<Map<String, dynamic>> testSearchFunctionality() async {
    try {
      Logger.info('🧪 Testando funcionalidade de busca...');
      
      final testQueries = [
        'lagarta',
        'soja',
        'fungo',
        'bicudo',
        'percevejo',
      ];
      
      final Map<String, dynamic> results = {
        'success': true,
        'search_tests': {},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      for (String query in testQueries) {
        final startTime = DateTime.now();
        final searchResults = await _loaderService.searchOrganisms(query: query);
        final endTime = DateTime.now();
        
        results['search_tests'][query] = {
          'results_count': searchResults.length,
          'search_time_ms': endTime.difference(startTime).inMilliseconds,
        };
        
        Logger.info('🔍 Busca por "$query": ${searchResults.length} resultados');
      }
      
      Logger.info('✅ Teste de busca concluído');
      return results;
      
    } catch (e) {
      Logger.error('❌ Erro no teste de busca: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Testa as estatísticas do catálogo
  Future<Map<String, dynamic>> testCatalogStatistics() async {
    try {
      Logger.info('🧪 Testando estatísticas do catálogo...');
      
      final startTime = DateTime.now();
      final stats = await _loaderService.getCatalogStatistics();
      final endTime = DateTime.now();
      
      final result = {
        'success': true,
        'statistics': stats,
        'load_time_ms': endTime.difference(startTime).inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      Logger.info('✅ Estatísticas: ${stats['total_organisms']} organismos, ${stats['cultures_count']} culturas');
      return result;
      
    } catch (e) {
      Logger.error('❌ Erro no teste de estatísticas: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Executa todos os testes
  Future<Map<String, dynamic>> runAllTests() async {
    try {
      Logger.info('🧪 Iniciando bateria completa de testes...');
      
      final results = {
        'success': true,
        'tests': {},
        'summary': {},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Teste 1: Carregamento de todos os organismos
      results['tests']['load_all'] = await testLoadAllOrganisms();
      
      // Teste 2: Carregamento por cultura
      final cultures = ['soja', 'milho', 'algodao', 'trigo', 'feijao'];
      results['tests']['load_cultures'] = {};
      for (String culture in cultures) {
        results['tests']['load_cultures'][culture] = await testLoadCulture(culture);
      }
      
      // Teste 3: Funcionalidade de busca
      results['tests']['search'] = await testSearchFunctionality();
      
      // Teste 4: Estatísticas
      results['tests']['statistics'] = await testCatalogStatistics();
      
      // Resumo
      int totalTests = 0;
      int passedTests = 0;
      
      void countTests(Map<String, dynamic> testResults) {
        if (testResults is Map<String, dynamic>) {
          if (testResults.containsKey('success')) {
            totalTests++;
            if (testResults['success'] == true) {
              passedTests++;
            }
          } else {
            testResults.forEach((key, value) {
              countTests(value);
            });
          }
        }
      }
      
      countTests(results['tests']);
      
      results['summary'] = {
        'total_tests': totalTests,
        'passed_tests': passedTests,
        'failed_tests': totalTests - passedTests,
        'success_rate': totalTests > 0 ? (passedTests / totalTests * 100).toStringAsFixed(1) + '%' : '0%',
      };
      
      Logger.info('✅ Bateria de testes concluída: $passedTests/$totalTests testes passaram');
      return results;
      
    } catch (e) {
      Logger.error('❌ Erro na bateria de testes: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
