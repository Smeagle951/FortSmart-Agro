import 'dart:convert';
import 'dart:io';

/// Script de diagnóstico dos JSONs v2.0
/// Analisa todos os arquivos organismos_*.json e gera relatório completo
void main() async {
  print('📊 DIAGNÓSTICO: JSONs Organismos v2.0\n');
  print('=' * 60);
  
  final assetsDir = Directory('assets/data');
  
  if (!await assetsDir.exists()) {
    print('❌ Diretório assets/data não encontrado!');
    exit(1);
  }
  
  final jsonFiles = assetsDir.listSync()
    .where((f) => 
      f is File && 
      f.path.endsWith('.json') && 
      f.path.contains('organismos_'))
    .toList();
  
  if (jsonFiles.isEmpty) {
    print('⚠️ Nenhum arquivo organismos_*.json encontrado!');
    exit(0);
  }
  
  print('📁 Arquivos encontrados: ${jsonFiles.length}\n');
  
  final relatorio = <String, dynamic>{};
  int totalOrganismos = 0;
  
  for (var file in jsonFiles) {
    try {
      final content = await File(file.path).readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      
      final cultura = data['cultura'] ?? 'Desconhecida';
      final organismos = (data['organismos'] as List? ?? []) as List;
      
      final pragas = organismos.where((o) {
        final categoria = o['categoria']?.toString().toLowerCase() ?? '';
        return categoria == 'praga';
      }).length;
      
      final doencas = organismos.where((o) {
        final categoria = o['categoria']?.toString().toLowerCase() ?? '';
        return categoria == 'doença' || categoria == 'doenca';
      }).length;
      
      final daninhas = organismos.where((o) {
        final categoria = o['categoria']?.toString().toLowerCase() ?? '';
        return categoria.contains('daninha') || categoria.contains('daninha');
      }).length;
      
      relatorio[cultura] = {
        'arquivo': file.path.split('/').last,
        'total_organismos': organismos.length,
        'pragas': pragas,
        'doencas': doencas,
        'daninhas': daninhas,
        'versao': data['versao'] ?? 'N/A',
        'data_atualizacao': data['data_atualizacao'] ?? 'N/A',
        'nome_cientifico_cultura': data['nome_cientifico'] ?? 'N/A',
      };
      
      totalOrganismos += organismos.length;
      
      print('✅ $cultura:');
      print('   📄 Arquivo: ${file.path.split('/').last}');
      print('   📊 Total: ${organismos.length} organismos');
      print('   🐛 Pragas: $pragas');
      print('   🦠 Doenças: $doencas');
      print('   🌿 Daninhas: $daninhas');
      print('   📅 Versão: ${data['versao'] ?? 'N/A'}');
      print('');
      
    } catch (e) {
      print('❌ Erro ao processar ${file.path}: $e');
    }
  }
  
  // Adicionar estatísticas gerais
  relatorio['_estatisticas_gerais'] = {
    'total_culturas': jsonFiles.length,
    'total_organismos': totalOrganismos,
    'arquivos_processados': jsonFiles.length,
    'data_diagnostico': DateTime.now().toIso8601String(),
  };
  
  // Salvar relatório
  final relatorioFile = File('relatorio_diagnostico_v2.json');
  await relatorioFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(relatorio)
  );
  
  print('=' * 60);
  print('\n📈 RESUMO GERAL:');
  print('   Culturas analisadas: ${jsonFiles.length}');
  print('   Total de organismos: $totalOrganismos');
  print('   Média por cultura: ${(totalOrganismos / jsonFiles.length).toStringAsFixed(1)}');
  print('\n✅ Relatório salvo em: relatorio_diagnostico_v2.json');
}

