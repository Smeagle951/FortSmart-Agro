import 'dart:convert';
import 'dart:io';

/// Script de validação de campos nos JSONs v2.0
/// Identifica quais campos estão presentes e quais estão faltando
void main() async {
  print('🔍 VALIDAÇÃO: Campos nos JSONs v2.0\n');
  print('=' * 60);
  
  final camposRequeridos = [
    'id', 'nome', 'nome_cientifico', 'categoria',
    'sintomas', 'dano_economico', 'partes_afetadas',
    'fenologia', 'nivel_acao', 'manejo_quimico',
    'manejo_biologico', 'manejo_cultural'
  ];
  
  final camposNovosV3 = [
    'caracteristicas_visuais',
    'condicoes_climaticas',
    'ciclo_vida',
    'rotacao_resistencia',
    'distribuicao_geografica',
    'economia_agronomica',
    'controle_biologico_detalhado',
    'diagnostico_diferencial',
    'tendencias_sazonais',
    'features_ia'
  ];
  
  final camposOpcionais = [
    'doses_defensivos',
    'fases',
    'severidade',
    'niveis_infestacao',
    'condicoes_favoraveis',
    'limiares_especificos',
    'observacoes',
    'icone',
    'ativo',
  ];
  
  final assetsDir = Directory('assets/data');
  final jsonFiles = assetsDir.listSync()
    .where((f) => 
      f is File && 
      f.path.endsWith('.json') && 
      f.path.contains('organismos_'))
    .toList();
  
  final relatorio = <String, dynamic>{};
  
  // Estatísticas globais
  final statsGlobal = {
    'campos_presentes_global': <String, int>{},
    'campos_faltantes_global': <String, int>{},
    'campos_novos_faltantes_global': <String, int>{},
  };
  
  for (var file in jsonFiles) {
    try {
      final content = await File(file.path).readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      final cultura = data['cultura'] ?? 'Desconhecida';
      final organismos = (data['organismos'] as List? ?? []) as List;
      
      final camposPresentes = <String, int>{};
      final camposFaltantes = <String, int>{};
      final camposNovosFaltantes = <String, int>{};
      final camposOpcionaisPresentes = <String, int>{};
      
      final stats = {
        'campos_presentes': camposPresentes,
        'campos_faltantes': camposFaltantes,
        'campos_novos_faltantes': camposNovosFaltantes,
        'campos_opcionais_presentes': camposOpcionaisPresentes,
        'total_organismos': organismos.length,
      };
      
      for (var org in organismos) {
        final orgMap = org as Map<String, dynamic>;
        
        // Verificar campos requeridos
        for (var campo in camposRequeridos) {
          if (orgMap.containsKey(campo)) {
            camposPresentes[campo] = (camposPresentes[campo] ?? 0) + 1;
            
            final globalPresentes = statsGlobal['campos_presentes_global'] as Map<String, int>;
            globalPresentes[campo] = (globalPresentes[campo] ?? 0) + 1;
          } else {
            camposFaltantes[campo] = (camposFaltantes[campo] ?? 0) + 1;
            
            final globalFaltantes = statsGlobal['campos_faltantes_global'] as Map<String, int>;
            globalFaltantes[campo] = (globalFaltantes[campo] ?? 0) + 1;
          }
        }
        
        // Verificar campos novos v3.0
        for (var campo in camposNovosV3) {
          if (!orgMap.containsKey(campo)) {
            camposNovosFaltantes[campo] = (camposNovosFaltantes[campo] ?? 0) + 1;
            
            final globalNovosFaltantes = statsGlobal['campos_novos_faltantes_global'] as Map<String, int>;
            globalNovosFaltantes[campo] = (globalNovosFaltantes[campo] ?? 0) + 1;
          }
        }
        
        // Verificar campos opcionais
        for (var campo in camposOpcionais) {
          if (orgMap.containsKey(campo)) {
            camposOpcionaisPresentes[campo] = (camposOpcionaisPresentes[campo] ?? 0) + 1;
          }
        }
      }
      
      relatorio[cultura] = stats;
      
      // Exibir resultados para esta cultura
      print('📊 $cultura (${organismos.length} organismos):');
      
      // Campos faltantes
      if (camposFaltantes.isNotEmpty) {
        print('   ⚠️  Campos requeridos faltantes:');
        camposFaltantes.forEach((campo, qtd) {
          final percent = ((qtd / organismos.length) * 100).toStringAsFixed(1);
          print('      - $campo: $qtd/${organismos.length} ($percent%)');
        });
      } else {
        print('   ✅ Todos os campos requeridos presentes');
      }
      
      // Campos novos faltantes
      if (camposNovosFaltantes.isNotEmpty) {
        print('   🔶 Campos novos v3.0 faltantes:');
        camposNovosFaltantes.forEach((campo, qtd) {
          final percent = ((qtd / organismos.length) * 100).toStringAsFixed(1);
          print('      - $campo: $qtd/${organismos.length} ($percent%)');
        });
      }
      
      // Campos opcionais presentes
      if (camposOpcionaisPresentes.isNotEmpty) {
        print('   💎 Campos opcionais presentes:');
        camposOpcionaisPresentes.forEach((campo, qtd) {
          final percent = ((qtd / organismos.length) * 100).toStringAsFixed(1);
          print('      - $campo: $qtd/${organismos.length} ($percent%)');
        });
      }
      
      print('');
      
    } catch (e) {
      print('❌ Erro ao processar ${file.path}: $e');
    }
  }
  
  // Adicionar estatísticas globais
  relatorio['_estatisticas_globais'] = statsGlobal;
  
  // Salvar relatório
  final relatorioFile = File('relatorio_validacao_campos.json');
  await relatorioFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(relatorio)
  );
  
  print('=' * 60);
  print('\n✅ Relatório de validação salvo em: relatorio_validacao_campos.json');
  
  // Calcular total de organismos
  int totalOrgs = 0;
  for (var file in jsonFiles) {
    try {
      final content = await File(file.path).readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      totalOrgs += ((data['organismos'] as List? ?? []).length);
    } catch (e) {
      // Ignorar erro
    }
  }
  
  // Exibir resumo global
  print('\n📈 RESUMO GLOBAL DE CAMPOS:');
  final globalNovosFaltantes = statsGlobal['campos_novos_faltantes_global'] as Map<String, int>;
  if (globalNovosFaltantes.isNotEmpty && totalOrgs > 0) {
    globalNovosFaltantes.forEach((campo, qtd) {
      final percent = ((qtd / totalOrgs) * 100).toStringAsFixed(1);
      print('   🔶 $campo: $qtd/$totalOrgs ($percent%) faltando');
    });
  }
}

