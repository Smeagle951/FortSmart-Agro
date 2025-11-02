import 'dart:io';
import 'package:flutter/services.dart';
import '../services/corrected_culture_import_service.dart';
import '../utils/logger.dart';

/// Script para migrar para o sistema corrigido de culturas
/// Carrega culturas dos arquivos JSON em lib/data/ - SEM LIMITAÇÕES
void main() async {
  print('🚀 Iniciando migração para sistema corrigido de culturas...');
  print('📁 Carregando culturas dos arquivos JSON em lib/data/');
  
  try {
    // Inicializar o serviço corrigido
    final importService = CorrectedCultureImportService();
    
    // Carregar TODAS as culturas dos JSONs em lib/data/
    print('📄 Carregando culturas dos arquivos:');
    print('   - organismos_soja.json');
    print('   - organismos_milho.json');
    print('   - organismos_algodao.json');
    print('   - organismos_feijao.json');
    print('   - organismos_girassol.json');
    print('   - organismos_arroz.json');
    print('   - organismos_sorgo.json');
    print('   - organismos_trigo.json');
    print('   - organismos_aveia.json');
    print('   - organismos_gergelim.json');
    print('   - organismos_cana_acucar.json');
    print('   - organismos_tomate.json');
    
    final result = await importService.loadAllCulturesFromLibData();
    
    if (result['success']) {
      print('✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO!');
      print('📊 Estatísticas finais:');
      print('   - Culturas: ${result['total_cultures']}');
      print('   - Pragas: ${result['total_pests']}');
      print('   - Doenças: ${result['total_diseases']}');
      print('   - Plantas daninhas: ${result['total_weeds']}');
      print('');
      print('🎉 Sistema corrigido ativo!');
      print('💡 Agora você pode adicionar quantas culturas quiser!');
    } else {
      print('❌ ERRO NA MIGRAÇÃO:');
      print('   ${result['error']}');
    }
    
  } catch (e) {
    print('❌ ERRO CRÍTICO NA MIGRAÇÃO:');
    print('   $e');
  }
}

/// Função para testar o carregamento de uma cultura específica
Future<void> testSingleCulture(String fileName) async {
  print('🧪 Testando carregamento de: $fileName');
  
  try {
    final importService = CorrectedCultureImportService();
    
    // Carregar arquivo JSON
    final jsonString = await rootBundle.loadString('lib/data/$fileName');
    final jsonData = json.decode(jsonString);
    
    print('📄 Dados carregados:');
    print('   - Cultura: ${jsonData['cultura']}');
    print('   - Nome científico: ${jsonData['nome_cientifico']}');
    print('   - Organismos: ${jsonData['organismos']?.length ?? 0}');
    
    // Contar tipos de organismos
    int pragas = 0;
    int doencas = 0;
    int daninhas = 0;
    
    for (final organismo in jsonData['organismos'] ?? []) {
      final tipo = organismo['tipo']?.toString().toUpperCase() ?? '';
      final categoria = organismo['categoria']?.toString() ?? '';
      
      if (tipo == 'PRAGA' || categoria.toLowerCase().contains('praga')) {
        pragas++;
      } else if (tipo == 'DOENÇA' || categoria.toLowerCase().contains('doença') || categoria.toLowerCase().contains('doenca')) {
        doencas++;
      } else if (tipo == 'PLANTA DANINHA' || categoria.toLowerCase().contains('daninha') || categoria.toLowerCase().contains('invasora')) {
        daninhas++;
      }
    }
    
    print('📊 Organismos encontrados:');
    print('   - Pragas: $pragas');
    print('   - Doenças: $doencas');
    print('   - Plantas daninhas: $daninhas');
    
  } catch (e) {
    print('❌ Erro ao testar $fileName: $e');
  }
}

/// Função para listar todas as culturas disponíveis
Future<void> listAvailableCultures() async {
  print('📋 Culturas disponíveis nos arquivos JSON:');
  
  final cultureFiles = [
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
  
  for (final fileName in cultureFiles) {
    try {
      final jsonString = await rootBundle.loadString('lib/data/$fileName');
      final jsonData = json.decode(jsonString);
      
      final cultura = jsonData['cultura'];
      final nomeCientifico = jsonData['nome_cientifico'];
      final organismos = jsonData['organismos'] ?? [];
      
      print('   - $cultura ($nomeCientifico) - ${organismos.length} organismos');
    } catch (e) {
      print('   - $fileName: ERRO - $e');
    }
  }
}
