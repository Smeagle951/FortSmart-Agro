import 'dart:io';
import 'dart:convert';

/// Script para verificar quais arquivos JSON precisam de enriquecimento v5.0
void main() async {
  print('🔍 VERIFICANDO STATUS DE ENRIQUECIMENTO v5.0\n');
  print('=' * 80);
  
  final List<String> culturas = [
    'algodao', 'arroz', 'aveia', 'batata', 'cana_acucar',
    'feijao', 'gergelim', 'girassol', 'milho', 'soja',
    'sorgo', 'tomate', 'trigo'
  ];
  
  int totalArquivos = 0;
  int arquivosCompletos = 0;
  int arquivosIncompletos = 0;
  int totalOrganismos = 0;
  int organismosCompletos = 0;
  int organismosIncompletos = 0;
  
  final Map<String, Map<String, dynamic>> statusPorCultura = {};
  
  for (final cultura in culturas) {
    final arquivo = 'assets/data/organismos_$cultura.json';
    final file = File(arquivo);
    
    if (!file.existsSync()) {
      print('⚠️  $cultura: Arquivo não existe');
      continue;
    }
    
    totalArquivos++;
    
    try {
      final content = await file.readAsString();
      final List<dynamic> organismos = json.decode(content);
      
      int completosNestaCultura = 0;
      int incompletosNestaCultura = 0;
      final List<String> organismosIncompleto = [];
      
      for (final org in organismos) {
        totalOrganismos++;
        
        // Verificar campos v5.0 (adicionados pelo script expandir_dados_2024_2025.dart)
        final bool temV50 = org.containsKey('ciclo_vida_detalhado_2024') &&
                           org.containsKey('monitoramento_profissional_2024') &&
                           org.containsKey('economia_2024_2025') &&
                           org.containsKey('resistencia_atualizada_2024') &&
                           org.containsKey('clima_regional_2024_2025') &&
                           org.containsKey('controle_biologico_expandido_2024') &&
                           org.containsKey('mip_integrado_2024') &&
                           org.containsKey('tendencias_2024_2025');
        
        if (temV50) {
          completosNestaCultura++;
          organismosCompletos++;
        } else {
          incompletosNestaCultura++;
          organismosIncompletos++;
          organismosIncompleto.add(org['nome_cientifico'] ?? org['name'] ?? 'Desconhecido');
        }
      }
      
      final bool culturaCompleta = incompletosNestaCultura == 0;
      
      if (culturaCompleta) {
        arquivosCompletos++;
        print('✅ ${cultura.toUpperCase().padRight(15)} - ${organismos.length} organismos - COMPLETO v5.0');
      } else {
        arquivosIncompletos++;
        print('❌ ${cultura.toUpperCase().padRight(15)} - ${organismos.length} organismos - ${incompletosNestaCultura} INCOMPLETOS');
      }
      
      statusPorCultura[cultura] = {
        'total': organismos.length,
        'completos': completosNestaCultura,
        'incompletos': incompletosNestaCultura,
        'culturaCompleta': culturaCompleta,
        'organismosIncompletos': organismosIncompleto,
      };
      
    } catch (e) {
      print('❌ $cultura: Erro ao processar - $e');
    }
  }
  
  // Verificar plantas daninhas
  print('\n' + '=' * 80);
  print('🌱 PLANTAS DANINHAS:\n');
  
  int totalPdArquivos = 0;
  int pdArquivosCompletos = 0;
  int pdArquivosIncompletos = 0;
  int totalPd = 0;
  int pdCompletos = 0;
  int pdIncompletos = 0;
  
  for (final cultura in culturas) {
    final arquivo = 'assets/data/plantas_daninhas_$cultura.json';
    final file = File(arquivo);
    
    if (!file.existsSync()) {
      continue;
    }
    
    totalPdArquivos++;
    
    try {
      final content = await file.readAsString();
      final List<dynamic> plantas = json.decode(content);
      
      int completosNestaCultura = 0;
      int incompletosNestaCultura = 0;
      
      for (final planta in plantas) {
        totalPd++;
        
        final bool temV50 = planta.containsKey('ciclo_vida_detalhado_2024') &&
                           planta.containsKey('monitoramento_profissional_2024') &&
                           planta.containsKey('economia_2024_2025');
        
        if (temV50) {
          completosNestaCultura++;
          pdCompletos++;
        } else {
          incompletosNestaCultura++;
          pdIncompletos++;
        }
      }
      
      final bool culturaCompleta = incompletosNestaCultura == 0;
      
      if (culturaCompleta) {
        pdArquivosCompletos++;
        print('✅ ${cultura.toUpperCase().padRight(15)} - ${plantas.length} plantas - COMPLETO v5.0');
      } else {
        pdArquivosIncompletos++;
        print('❌ ${cultura.toUpperCase().padRight(15)} - ${plantas.length} plantas - ${incompletosNestaCultura} INCOMPLETOS');
      }
      
    } catch (e) {
      print('❌ $cultura: Erro ao processar plantas daninhas - $e');
    }
  }
  
  // Relatório final
  print('\n' + '=' * 80);
  print('📊 RESUMO GERAL:\n');
  
  print('ORGANISMOS (Pragas/Doenças):');
  print('  Total de arquivos: $totalArquivos');
  print('  Arquivos completos v5.0: $arquivosCompletos (${_percent(arquivosCompletos, totalArquivos)}%)');
  print('  Arquivos incompletos: $arquivosIncompletos (${_percent(arquivosIncompletos, totalArquivos)}%)');
  print('');
  print('  Total de organismos: $totalOrganismos');
  print('  Organismos completos v5.0: $organismosCompletos (${_percent(organismosCompletos, totalOrganismos)}%)');
  print('  Organismos incompletos: $organismosIncompletos (${_percent(organismosIncompletos, totalOrganismos)}%)');
  
  print('\nPLANTAS DANINHAS:');
  print('  Total de arquivos: $totalPdArquivos');
  print('  Arquivos completos v5.0: $pdArquivosCompletos (${_percent(pdArquivosCompletos, totalPdArquivos)}%)');
  print('  Arquivos incompletos: $pdArquivosIncompletos (${_percent(pdArquivosIncompletos, totalPdArquivos)}%)');
  print('');
  print('  Total de plantas: $totalPd');
  print('  Plantas completas v5.0: $pdCompletos (${_percent(pdCompletos, totalPd)}%)');
  print('  Plantas incompletas: $pdIncompletos (${_percent(pdIncompletos, totalPd)}%)');
  
  print('\n' + '=' * 80);
  
  if (arquivosIncompletos > 0 || pdArquivosIncompletos > 0) {
    print('\n🔧 AÇÃO NECESSÁRIA:');
    print('Execute: dart scripts/enriquecer_todas_culturas_v5.dart');
    print('Para complementar automaticamente todos os arquivos!\n');
    
    // Mostrar detalhes das culturas incompletas
    print('\n📋 DETALHES DAS CULTURAS INCOMPLETAS:\n');
    statusPorCultura.forEach((cultura, status) {
      if (!status['culturaCompleta']) {
        print('❌ ${cultura.toUpperCase()}:');
        print('   ${status['incompletos']} de ${status['total']} organismos precisam de atualização');
        if (status['organismosIncompletos'].length <= 5) {
          print('   Organismos: ${status['organismosIncompletos'].join(', ')}');
        } else {
          print('   Organismos: ${status['organismosIncompletos'].take(5).join(', ')} e mais ${status['organismosIncompletos'].length - 5}...');
        }
        print('');
      }
    });
  } else {
    print('\n✅ TODOS OS ARQUIVOS ESTÃO COMPLETOS v5.0!\n');
  }
  
  print('=' * 80);
}

String _percent(int parte, int total) {
  if (total == 0) return '0.0';
  return ((parte / total) * 100).toStringAsFixed(1);
}

