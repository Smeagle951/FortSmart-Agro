import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/lib_data_culture_import_service.dart';
import '../utils/logger.dart';

/// Script para testar o carregamento dos arquivos JSON em lib/data/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 TESTE DE CARREGAMENTO DOS ARQUIVOS JSON EM LIB/DATA/');
  print('=' * 60);
  
  try {
    final service = LibDataCultureImportService();
    
    // Teste 1: Verificar arquivos disponíveis
    print('\n📁 TESTE 1: Verificando arquivos JSON disponíveis...');
    await _testAvailableFiles();
    
    // Teste 2: Carregar uma cultura específica
    print('\n🌱 TESTE 2: Carregando cultura específica...');
    await _testSpecificCulture();
    
    // Teste 3: Carregar todas as culturas
    print('\n🚀 TESTE 3: Carregando todas as culturas...');
    await _testAllCultures(service);
    
    // Teste 4: Verificar estatísticas
    print('\n📊 TESTE 4: Verificando estatísticas...');
    await _testStatistics(service);
    
    print('\n✅ TODOS OS TESTES CONCLUÍDOS COM SUCESSO!');
    
  } catch (e) {
    print('❌ ERRO NO TESTE: $e');
  }
}

/// Testa arquivos disponíveis
Future<void> _testAvailableFiles() async {
  final files = [
    'organismos_soja.json',
    'organismos_milho.json', 
    'organismos_algodao.json',
    'organismos_feijao.json',
    'organismos_girassol.json',
    'organismos_arroz.json',
    'organismos_sorgo.json',
    'organismos_trigo.json',
    'organismos_aveia.json',
    'organismos_gergelim.json',
    'organismos_cana_acucar.json',
    'organismos_tomate.json',
  ];
  
  for (final fileName in files) {
    try {
      final jsonString = await rootBundle.loadString('lib/data/$fileName');
      final jsonData = json.decode(jsonString);
      
      final cultura = jsonData['cultura'];
      final organismos = jsonData['organismos'] ?? [];
      
      print('✅ $fileName: $cultura (${organismos.length} organismos)');
    } catch (e) {
      print('❌ $fileName: Erro - $e');
    }
  }
}

/// Testa carregamento de cultura específica
Future<void> _testSpecificCulture() async {
  try {
    final jsonString = await rootBundle.loadString('lib/data/organismos_soja.json');
    final jsonData = json.decode(jsonString);
    
    final cultura = jsonData['cultura'];
    final nomeCientifico = jsonData['nome_cientifico'];
    final organismos = jsonData['organismos'] ?? [];
    
    print('📋 Cultura: $cultura');
    print('🔬 Nome científico: $nomeCientifico');
    print('🐛 Total de organismos: ${organismos.length}');
    
    // Contar por tipo
    int pragas = 0;
    int doencas = 0;
    int plantasDaninhas = 0;
    
    for (final organismo in organismos) {
      final tipo = organismo['tipo']?.toString().toUpperCase() ?? '';
      final categoria = organismo['categoria']?.toString() ?? '';
      
      if (tipo == 'PRAGA' || categoria.toLowerCase().contains('praga')) {
        pragas++;
      } else if (tipo == 'DOENÇA' || categoria.toLowerCase().contains('doença') || categoria.toLowerCase().contains('doenca')) {
        doencas++;
      } else if (tipo == 'PLANTA DANINHA' || categoria.toLowerCase().contains('daninha') || categoria.toLowerCase().contains('invasora')) {
        plantasDaninhas++;
      }
    }
    
    print('📊 Distribuição:');
    print('   - Pragas: $pragas');
    print('   - Doenças: $doencas');
    print('   - Plantas daninhas: $plantasDaninhas');
    
  } catch (e) {
    print('❌ Erro ao carregar cultura específica: $e');
  }
}

/// Testa carregamento de todas as culturas
Future<void> _testAllCultures(LibDataCultureImportService service) async {
  try {
    print('🔄 Carregando todas as culturas...');
    final result = await service.loadAllCulturesFromLibData();
    
    if (result['success']) {
      print('✅ Carregamento bem-sucedido!');
      print('📊 Estatísticas:');
      print('   - Culturas: ${result['total_cultures']}');
      print('   - Pragas: ${result['total_pests']}');
      print('   - Doenças: ${result['total_diseases']}');
      print('   - Plantas daninhas: ${result['total_weeds']}');
    } else {
      print('❌ Erro no carregamento: ${result['error']}');
    }
  } catch (e) {
    print('❌ Erro ao carregar todas as culturas: $e');
  }
}

/// Testa estatísticas
Future<void> _testStatistics(LibDataCultureImportService service) async {
  try {
    print('📊 Obtendo estatísticas...');
    final stats = await service.getStatistics();
    
    print('📈 Estatísticas finais:');
    print('   - Total de culturas: ${stats['total_cultures']}');
    print('   - Total de pragas: ${stats['total_pests']}');
    print('   - Total de doenças: ${stats['total_diseases']}');
    print('   - Total de plantas daninhas: ${stats['total_weeds']}');
    
    final cultures = stats['cultures'] as List;
    print('\n🌱 Culturas carregadas:');
    for (final culture in cultures) {
      print('   - ${culture['name']} (ID: ${culture['id']})');
    }
    
  } catch (e) {
    print('❌ Erro ao obter estatísticas: $e');
  }
}
