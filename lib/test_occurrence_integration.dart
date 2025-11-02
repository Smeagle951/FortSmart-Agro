import 'package:flutter/material.dart';
import 'services/cultura_talhao_service.dart';
import 'utils/logger.dart';

/// Teste de integração para verificar se o carregamento de organismos está funcionando
class TestOccurrenceIntegration {
  static final CulturaTalhaoService _culturaService = CulturaTalhaoService();

  /// Testa o carregamento de organismos para uma cultura específica
  static Future<void> testOrganismLoading() async {
    try {
      Logger.info('🧪 Iniciando teste de integração de organismos...');
      
      // 1. Testar listagem de culturas
      Logger.info('📋 Testando listagem de culturas...');
      final culturas = await _culturaService.listarCulturas();
      Logger.info('✅ ${culturas.length} culturas encontradas');
      
      for (var cultura in culturas) {
        Logger.info('  - ${cultura['nome']} (ID: ${cultura['id']})');
      }
      
      if (culturas.isEmpty) {
        Logger.warning('⚠️ Nenhuma cultura encontrada - teste interrompido');
        return;
      }
      
      // 2. Testar carregamento de organismos para a primeira cultura
      final primeiraCultura = culturas.first;
      final culturaId = primeiraCultura['id'].toString();
      final culturaNome = primeiraCultura['nome'];
      
      Logger.info('🔍 Testando carregamento de organismos para: $culturaNome (ID: $culturaId)');
      
      final organisms = await _culturaService.getOrganismsByCrop(culturaId);
      Logger.info('✅ ${organisms.length} organismos encontrados para $culturaNome');
      
      // 3. Agrupar organismos por tipo
      final pragas = organisms.where((org) => org['tipo'] == 'praga').toList();
      final doencas = organisms.where((org) => org['tipo'] == 'doenca').toList();
      final daninhas = organisms.where((org) => org['tipo'] == 'daninha').toList();
      
      Logger.info('📊 Organismos por tipo:');
      Logger.info('  - Pragas: ${pragas.length}');
      Logger.info('  - Doenças: ${doencas.length}');
      Logger.info('  - Plantas daninhas: ${daninhas.length}');
      
      // 4. Mostrar detalhes dos organismos
      if (pragas.isNotEmpty) {
        Logger.info('🐛 Pragas encontradas:');
        for (var praga in pragas) {
          Logger.info('  - ${praga['nome']} (${praga['nome_cientifico']})');
        }
      }
      
      if (doencas.isNotEmpty) {
        Logger.info('🦠 Doenças encontradas:');
        for (var doenca in doencas) {
          Logger.info('  - ${doenca['nome']} (${doenca['nome_cientifico']})');
        }
      }
      
      if (daninhas.isNotEmpty) {
        Logger.info('🌿 Plantas daninhas encontradas:');
        for (var daninha in daninhas) {
          Logger.info('  - ${daninha['nome']} (${daninha['nome_cientifico']})');
        }
      }
      
      // 5. Testar filtro por tipo
      Logger.info('🔍 Testando filtro por tipo...');
      
      final pragasFiltradas = organisms.where((org) => 
        org['tipo']?.toString().toLowerCase() == 'praga').toList();
      final doencasFiltradas = organisms.where((org) => 
        org['tipo']?.toString().toLowerCase() == 'doenca').toList();
      final daninhasFiltradas = organisms.where((org) => 
        org['tipo']?.toString().toLowerCase() == 'daninha').toList();
      
      Logger.info('✅ Filtros funcionando:');
      Logger.info('  - Pragas filtradas: ${pragasFiltradas.length}');
      Logger.info('  - Doenças filtradas: ${doencasFiltradas.length}');
      Logger.info('  - Daninhas filtradas: ${daninhasFiltradas.length}');
      
      // 6. Testar busca por nome
      Logger.info('🔍 Testando busca por nome...');
      final query = 'soja';
      final resultadosBusca = organisms.where((org) {
        final nome = (org['nome'] ?? '').toLowerCase();
        final nomeCientifico = (org['nome_cientifico'] ?? '').toLowerCase();
        return nome.contains(query) || nomeCientifico.contains(query);
      }).toList();
      
      Logger.info('✅ Busca por "$query": ${resultadosBusca.length} resultados');
      for (var resultado in resultadosBusca) {
        Logger.info('  - ${resultado['nome']} (${resultado['tipo']})');
      }
      
      Logger.info('🎉 Teste de integração concluído com sucesso!');
      
    } catch (e) {
      Logger.error('❌ Erro no teste de integração: $e');
    }
  }

  /// Testa o carregamento de organismos para múltiplas culturas
  static Future<void> testMultipleCrops() async {
    try {
      Logger.info('🧪 Testando múltiplas culturas...');
      
      final culturas = await _culturaService.listarCulturas();
      
      for (var cultura in culturas.take(3)) { // Testar apenas as primeiras 3
        final culturaId = cultura['id'].toString();
        final culturaNome = cultura['nome'];
        
        Logger.info('🔍 Testando cultura: $culturaNome');
        
        final organisms = await _culturaService.getOrganismsByCrop(culturaId);
        
        final pragas = organisms.where((org) => org['tipo'] == 'praga').length;
        final doencas = organisms.where((org) => org['tipo'] == 'doenca').length;
        final daninhas = organisms.where((org) => org['tipo'] == 'daninha').length;
        
        Logger.info('  - Total: ${organisms.length} | Pragas: $pragas | Doenças: $doencas | Daninhas: $daninhas');
      }
      
      Logger.info('✅ Teste de múltiplas culturas concluído!');
      
    } catch (e) {
      Logger.error('❌ Erro no teste de múltiplas culturas: $e');
    }
  }

  /// Executa todos os testes
  static Future<void> runAllTests() async {
    Logger.info('🚀 Iniciando todos os testes de integração...');
    
    await testOrganismLoading();
    await Future.delayed(Duration(seconds: 1));
    await testMultipleCrops();
    
    Logger.info('🏁 Todos os testes concluídos!');
  }
}
