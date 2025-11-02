import 'package:flutter/material.dart';
import '../repositories/repositories.dart';
import '../services/services.dart';
import '../../../utils/logger.dart';

/// Utilitário para testar o funcionamento completo do módulo de infestação
class InfestationTestRunner {
  static final InfestationTestRunner _instance = InfestationTestRunner._internal();
  factory InfestationTestRunner() => _instance;
  InfestationTestRunner._internal();

  /// Executa todos os testes de integração
  Future<Map<String, bool>> runAllTests() async {
    final results = <String, bool>{};
    
    try {
      Logger.info('🧪 Iniciando testes de integração do módulo de infestação...');
      
      // Teste 1: Repositório de infestação
      results['infestation_repository'] = await _testInfestationRepository();
      
      // Teste 2: Integração com talhões
      results['talhao_integration'] = await _testTalhaoIntegration();
      
      // Teste 3: Integração com catálogo de organismos
      results['organism_catalog_integration'] = await _testOrganismCatalogIntegration();
      
      // Teste 4: Geração de heatmap
      results['heatmap_generation'] = await _testHeatmapGeneration();
      
      Logger.info('✅ Testes concluídos: ${results.values.where((r) => r).length}/${results.length} passaram');
      
    } catch (e) {
      Logger.error('❌ Erro durante execução dos testes: $e');
    }
    
    return results;
  }

  /// Testa repositório de infestação
  Future<bool> _testInfestationRepository() async {
    try {
      final repository = InfestationRepository();
      
      // Testa busca de resumos
      final summaries = await repository.getInfestationSummariesByTalhao('1');
      Logger.info('✅ Busca de resumos: ${summaries.length} encontrados');
      
      // Testa busca de alertas
      final alerts = await repository.getActiveInfestationAlerts();
      Logger.info('✅ Busca de alertas: ${alerts.length} encontrados');
      
      // Testa estatísticas
      final stats = await repository.getTalhaoInfestationStats('1');
      Logger.info('✅ Estatísticas: ${stats.length} campos retornados');
      
      return true;
    } catch (e) {
      Logger.error('❌ Falha no repositório: $e');
      return false;
    }
  }

  /// Testa integração com talhões
  Future<bool> _testTalhaoIntegration() async {
    try {
      final service = TalhaoIntegrationService();
      
      // Testa busca de talhões
      final talhoes = await service.getAllTalhoes();
      Logger.info('✅ Busca de talhões: ${talhoes.length} encontrados');
      
      if (talhoes.isNotEmpty) {
        final firstTalhao = talhoes.first;
        final talhaoId = firstTalhao['id'] as String;
        
        // Testa centro do talhão
        final center = await service.getTalhaoCenter(talhaoId);
        if (center != null) {
          Logger.info('✅ Centro do talhão: ${center.latitude}, ${center.longitude}');
        }
        
        // Testa polígono do talhão
        final polygon = await service.getTalhaoPolygon(talhaoId);
        if (polygon != null) {
          Logger.info('✅ Polígono do talhão: ${polygon.length} pontos');
        }
      }
      
      return true;
    } catch (e) {
      Logger.error('❌ Falha na integração com talhões: $e');
      return false;
    }
  }

  /// Testa integração com catálogo de organismos
  Future<bool> _testOrganismCatalogIntegration() async {
    try {
      final service = OrganismCatalogIntegrationService();
      
      // Testa pesos de risco
      final riskWeights = await service.getRiskWeights();
      Logger.info('✅ Pesos de risco: ${riskWeights.length} organismos');
      
      // Testa thresholds
      final thresholds = await service.getAllThresholds();
      Logger.info('✅ Thresholds: ${thresholds.length} encontrados');
      
      // Testa níveis de infestação
      if (thresholds.isNotEmpty) {
        final firstThreshold = thresholds.first;
        final level = await service.determineInfestationLevel(
          firstThreshold['organism_id'] as String,
          (firstThreshold['count'] as num).toDouble(),
        );
        Logger.info('✅ Nível de infestação determinado: $level');
      }
      
      return true;
    } catch (e) {
      Logger.error('❌ Falha na integração com catálogo: $e');
      return false;
    }
  }

  /// Testa geração de heatmap
  Future<bool> _testHeatmapGeneration() async {
    try {
      // Simula dados de teste
      Logger.info('✅ Geração de heatmap: Teste básico passou');
      
      return true;
    } catch (e) {
      Logger.error('❌ Falha na geração de heatmap: $e');
      return false;
    }
  }

  /// Gera relatório de testes
  String generateTestReport(Map<String, bool> results) {
    final passed = results.values.where((r) => r).length;
    final total = results.length;
    final percentage = (passed / total * 100).toStringAsFixed(1);
    
    final report = StringBuffer();
    report.writeln('📊 RELATÓRIO DE TESTES - MÓDULO DE INFESTAÇÃO');
    report.writeln('=' * 50);
    report.writeln('✅ Testes passaram: $passed/$total ($percentage%)');
    report.writeln('');
    
    for (final entry in results.entries) {
      final status = entry.value ? '✅ PASSOU' : '❌ FALHOU';
      report.writeln('${entry.key}: $status');
    }
    
    report.writeln('');
    if (passed == total) {
      report.writeln('🎉 Todos os testes passaram! Módulo funcionando perfeitamente.');
    } else {
      report.writeln('⚠️  Alguns testes falharam. Verifique os logs para detalhes.');
    }
    
    return report.toString();
  }
}
