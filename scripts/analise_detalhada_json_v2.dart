import 'dart:convert';
import 'dart:io';

/// Script de análise detalhada dos JSONs v2.0
/// Analisa estrutura interna, tipos de dados, e qualidade
void main() async {
  print('🔬 ANÁLISE DETALHADA: JSONs Organismos v2.0\n');
  print('=' * 60);
  
  final assetsDir = Directory('assets/data');
  final jsonFiles = assetsDir.listSync()
    .where((f) => 
      f is File && 
      f.path.endsWith('.json') && 
      f.path.contains('organismos_'))
    .toList();
  
  final analiseCompleta = <String, dynamic>{};
  
  for (var file in jsonFiles) {
    try {
      final content = await File(file.path).readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      final cultura = data['cultura'] ?? 'Desconhecida';
      final organismos = (data['organismos'] as List? ?? []) as List;
      
      print('📊 Analisando $cultura (${organismos.length} organismos)...');
      
      final stats = {
        'total_organismos': organismos.length,
        'tamanho_arquivo_bytes': await File(file.path).length(),
        'estrutura_detalhada': <String, dynamic>{},
        'qualidade_dados': <String, dynamic>{},
      };
      
      // Analisar estrutura de cada organismo
      int orgsComFases = 0;
      int orgsComSeveridade = 0;
      int orgsComDoses = 0;
      int orgsComCondicoes = 0;
      int orgsComFenologia = 0;
      
      final camposCompletos = <int>[];
      final camposIncompletos = <int>[];
      
      for (int i = 0; i < organismos.length; i++) {
        final org = organismos[i] as Map<String, dynamic>;
        int completude = 0;
        
        // Verificar campos ricos
        if (org.containsKey('fases') && (org['fases'] as List).isNotEmpty) {
          orgsComFases++;
          completude += 2;
        }
        
        if (org.containsKey('severidade')) {
          orgsComSeveridade++;
          completude += 2;
        }
        
        if (org.containsKey('doses_defensivos')) {
          orgsComDoses++;
          completude += 2;
        }
        
        if (org.containsKey('condicoes_favoraveis')) {
          orgsComCondicoes++;
          completude += 1;
        }
        
        if (org.containsKey('fenologia') && (org['fenologia'] as List).isNotEmpty) {
          orgsComFenologia++;
          completude += 1;
        }
        
        // Campos básicos (1 ponto cada)
        if (org.containsKey('id') && org['id'].toString().isNotEmpty) completude += 1;
        if (org.containsKey('nome') && org['nome'].toString().isNotEmpty) completude += 1;
        if (org.containsKey('nome_cientifico') && org['nome_cientifico'].toString().isNotEmpty) completude += 1;
        if (org.containsKey('sintomas') && (org['sintomas'] as List).isNotEmpty) completude += 1;
        if (org.containsKey('dano_economico') && org['dano_economico'].toString().isNotEmpty) completude += 1;
        
        // Máximo de 10 pontos
        final score = (completude / 10 * 100).round();
        
        if (score >= 80) {
          camposCompletos.add(i);
        } else {
          camposIncompletos.add(i);
        }
      }
      
      stats['estrutura_detalhada'] = {
        'organismos_com_fases': orgsComFases,
        'organismos_com_severidade': orgsComSeveridade,
        'organismos_com_doses': orgsComDoses,
        'organismos_com_condicoes': orgsComCondicoes,
        'organismos_com_fenologia': orgsComFenologia,
        'percentual_fases': ((orgsComFases / organismos.length) * 100).toStringAsFixed(1),
        'percentual_severidade': ((orgsComSeveridade / organismos.length) * 100).toStringAsFixed(1),
        'percentual_doses': ((orgsComDoses / organismos.length) * 100).toStringAsFixed(1),
      };
      
      stats['qualidade_dados'] = {
        'organismos_completos': camposCompletos.length,
        'organismos_incompletos': camposIncompletos.length,
        'score_medio_completude': camposCompletos.isEmpty 
          ? 0 
          : (camposCompletos.length / organismos.length * 100).toStringAsFixed(1),
      };
      
      analiseCompleta[cultura] = stats;
      
      // Exibir resultados
      print('   ✅ Organismos com fases: $orgsComFases (${((orgsComFases / organismos.length) * 100).toStringAsFixed(1)}%)');
      print('   ✅ Organismos com severidade: $orgsComSeveridade (${((orgsComSeveridade / organismos.length) * 100).toStringAsFixed(1)}%)');
      print('   ✅ Organismos com doses: $orgsComDoses (${((orgsComDoses / organismos.length) * 100).toStringAsFixed(1)}%)');
      print('   ✅ Organismos completos: ${camposCompletos.length} (${((camposCompletos.length / organismos.length) * 100).toStringAsFixed(1)}%)');
      print('');
      
    } catch (e) {
      print('❌ Erro ao processar ${file.path}: $e');
    }
  }
  
  // Salvar análise
  final analiseFile = File('analise_detalhada_v2.json');
  await analiseFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(analiseCompleta)
  );
  
  print('=' * 60);
  print('\n✅ Análise detalhada salva em: analise_detalhada_v2.json');
}

