import 'package:sqflite/sqflite.dart';
import 'database/app_database.dart';
import 'utils/logger.dart';

/// 🔍 DIAGNÓSTICO COMPLETO DO CÁLCULO DE INFESTAÇÃO
/// 
/// Este arquivo ajuda a diagnosticar por que as quantidades e severidades
/// não estão sendo calculadas corretamente no motor de cálculo.
class InfestationCalculationDebugger {
  
  /// Executa diagnóstico completo
  static Future<Map<String, dynamic>> runFullDiagnosis() async {
    Logger.info('🔍 ==========================================');
    Logger.info('🔍 INICIANDO DIAGNÓSTICO COMPLETO DE INFESTAÇÃO');
    Logger.info('🔍 ==========================================');
    
    final results = <String, dynamic>{};
    
    try {
      final db = await AppDatabase.instance.database;
      
      // 1. Verificar estrutura da tabela
      results['table_structure'] = await _checkTableStructure(db);
      
      // 2. Verificar dados brutos
      results['raw_data'] = await _checkRawData(db);
      
      // 3. Verificar dados agrupados
      results['grouped_data'] = await _checkGroupedData(db);
      
      // 4. Verificar dados de monitoramento
      results['monitoring_data'] = await _checkMonitoringData(db);
      
      // 5. Verificar dados de sessões
      results['session_data'] = await _checkSessionData(db);
      
      Logger.info('✅ Diagnóstico completo finalizado');
      return results;
      
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico: $e');
      results['error'] = e.toString();
      return results;
    }
  }
  
  /// Verifica estrutura da tabela monitoring_occurrences
  static Future<Map<String, dynamic>> _checkTableStructure(Database db) async {
    Logger.info('🔍 1. Verificando estrutura da tabela monitoring_occurrences...');
    
    try {
      final columns = await db.rawQuery('PRAGMA table_info(monitoring_occurrences)');
      
      Logger.info('📋 Colunas da tabela monitoring_occurrences:');
      for (final col in columns) {
        Logger.info('   - ${col['name']}: ${col['type']} (nullable: ${col['notnull'] == 0})');
      }
      
      return {
        'columns': columns,
        'column_count': columns.length,
        'has_quantidade': columns.any((c) => c['name'] == 'quantidade'),
        'has_agronomic_severity': columns.any((c) => c['name'] == 'agronomic_severity'),
        'has_percentual': columns.any((c) => c['name'] == 'percentual'),
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar estrutura: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Verifica dados brutos da tabela
  static Future<Map<String, dynamic>> _checkRawData(Database db) async {
    Logger.info('🔍 2. Verificando dados brutos de monitoring_occurrences...');
    
    try {
      final rawData = await db.rawQuery('''
        SELECT 
          id,
          subtipo,
          tipo,
          percentual,
          quantidade,
          agronomic_severity,
          data_hora,
          point_id,
          session_id
        FROM monitoring_occurrences
        ORDER BY data_hora DESC
        LIMIT 20
      ''');
      
      Logger.info('📊 Dados brutos encontrados: ${rawData.length} registros');
      
      for (final row in rawData.take(5)) {
        Logger.info('   ID: ${row['id']}');
        Logger.info('   Organismo: ${row['subtipo']}');
        Logger.info('   Tipo: ${row['tipo']}');
        Logger.info('   Percentual: ${row['percentual']}');
        Logger.info('   Quantidade: ${row['quantidade']}');
        Logger.info('   Severidade: ${row['agronomic_severity']}');
        Logger.info('   Data: ${row['data_hora']}');
        Logger.info('   ---');
      }
      
      return {
        'total_records': rawData.length,
        'sample_data': rawData.take(5).toList(),
        'has_quantidade_data': rawData.any((r) {
          final v = r['quantidade'];
          final numVal = (v is num) ? v : num.tryParse(v?.toString() ?? '0') ?? 0;
          return numVal > 0;
        }),
        'has_severity_data': rawData.any((r) {
          final v = r['agronomic_severity'];
          final numVal = (v is num) ? v : num.tryParse(v?.toString() ?? '0') ?? 0;
          return numVal > 0;
        }),
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar dados brutos: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Verifica dados agrupados (como usado no cálculo)
  static Future<Map<String, dynamic>> _checkGroupedData(Database db) async {
    Logger.info('🔍 3. Verificando dados agrupados (como usado no cálculo)...');
    
    try {
      final groupedData = await db.rawQuery('''
        SELECT 
          mo.subtipo as organismo_nome,
          mo.tipo,
          AVG(mo.percentual) as percentual_medio,
          mo.nivel,
          SUM(mo.quantidade) as quantidade_total,
          AVG(mo.agronomic_severity) as severidade_media,
          COUNT(DISTINCT mo.point_id) as pontos_com_infestacao,
          COUNT(*) as total_ocorrencias,
          MAX(mo.data_hora) as ultima_ocorrencia
        FROM monitoring_occurrences mo
        WHERE mo.data_hora >= datetime('now', '-30 days')
        GROUP BY mo.subtipo, mo.tipo
        ORDER BY ultima_ocorrencia DESC
        LIMIT 10
      ''');
      
      Logger.info('📊 Dados agrupados encontrados: ${groupedData.length} organismos');
      
      for (final row in groupedData) {
        Logger.info('   Organismo: ${row['organismo_nome']}');
        Logger.info('   Tipo: ${row['tipo']}');
        Logger.info('   Percentual médio: ${row['percentual_medio']}');
        Logger.info('   Quantidade total: ${row['quantidade_total']}');
        Logger.info('   Severidade média: ${row['severidade_media']}');
        Logger.info('   Pontos com infestação: ${row['pontos_com_infestacao']}');
        Logger.info('   Total ocorrências: ${row['total_ocorrencias']}');
        Logger.info('   ---');
      }
      
      return {
        'total_organisms': groupedData.length,
        'grouped_data': groupedData,
        'has_quantidade_total': groupedData.any((r) {
          final v = r['quantidade_total'];
          final numVal = (v is num) ? v : num.tryParse(v?.toString() ?? '0') ?? 0;
          return numVal > 0;
        }),
        'has_severity_media': groupedData.any((r) {
          final v = r['severidade_media'];
          final numVal = (v is num) ? v : num.tryParse(v?.toString() ?? '0') ?? 0;
          return numVal > 0;
        }),
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar dados agrupados: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Verifica dados de monitoramento
  static Future<Map<String, dynamic>> _checkMonitoringData(Database db) async {
    Logger.info('🔍 4. Verificando dados de monitoramento...');
    
    try {
      final monitoringData = await db.rawQuery('''
        SELECT 
          id,
          plot_id,
          plotName,
          cropName,
          date,
          isCompleted,
          severity
        FROM monitorings
        ORDER BY date DESC
        LIMIT 10
      ''');
      
      Logger.info('📊 Monitoramentos encontrados: ${monitoringData.length}');
      
      for (final row in monitoringData) {
        Logger.info('   ID: ${row['id']}');
        Logger.info('   Talhão: ${row['plotName']} (ID: ${row['plot_id']})');
        Logger.info('   Cultura: ${row['cropName']}');
        Logger.info('   Data: ${row['date']}');
        Logger.info('   Concluído: ${row['isCompleted']}');
        Logger.info('   Severidade: ${row['severity']}');
        Logger.info('   ---');
      }
      
      return {
        'total_monitorings': monitoringData.length,
        'monitoring_data': monitoringData,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar dados de monitoramento: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Verifica dados de sessões
  static Future<Map<String, dynamic>> _checkSessionData(Database db) async {
    Logger.info('🔍 5. Verificando dados de sessões...');
    
    try {
      final sessionData = await db.rawQuery('''
        SELECT 
          id,
          talhao_id,
          talhao_nome,
          cultura_nome,
          started_at,
          ended_at,
          status
        FROM monitoring_sessions
        ORDER BY started_at DESC
        LIMIT 10
      ''');
      
      Logger.info('📊 Sessões encontradas: ${sessionData.length}');
      
      for (final row in sessionData) {
        Logger.info('   ID: ${row['id']}');
        Logger.info('   Talhão: ${row['talhao_nome']} (ID: ${row['talhao_id']})');
        Logger.info('   Cultura: ${row['cultura_nome']}');
        Logger.info('   Início: ${row['started_at']}');
        Logger.info('   Fim: ${row['ended_at']}');
        Logger.info('   Status: ${row['status']}');
        Logger.info('   ---');
      }
      
      return {
        'total_sessions': sessionData.length,
        'session_data': sessionData,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar dados de sessões: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Gera relatório de diagnóstico
  static String generateDiagnosisReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('🔍 ==========================================');
    buffer.writeln('🔍 RELATÓRIO DE DIAGNÓSTICO DE INFESTAÇÃO');
    buffer.writeln('🔍 ==========================================');
    buffer.writeln();
    
    // Estrutura da tabela
    if (results['table_structure'] != null) {
      final structure = results['table_structure'] as Map<String, dynamic>;
      buffer.writeln('📋 ESTRUTURA DA TABELA:');
      buffer.writeln('   • Total de colunas: ${structure['column_count']}');
      buffer.writeln('   • Tem coluna quantidade: ${structure['has_quantidade']}');
      buffer.writeln('   • Tem coluna agronomic_severity: ${structure['has_agronomic_severity']}');
      buffer.writeln('   • Tem coluna percentual: ${structure['has_percentual']}');
      buffer.writeln();
    }
    
    // Dados brutos
    if (results['raw_data'] != null) {
      final rawData = results['raw_data'] as Map<String, dynamic>;
      buffer.writeln('📊 DADOS BRUTOS:');
      buffer.writeln('   • Total de registros: ${rawData['total_records']}');
      buffer.writeln('   • Tem dados de quantidade: ${rawData['has_quantidade_data']}');
      buffer.writeln('   • Tem dados de severidade: ${rawData['has_severity_data']}');
      buffer.writeln();
    }
    
    // Dados agrupados
    if (results['grouped_data'] != null) {
      final groupedData = results['grouped_data'] as Map<String, dynamic>;
      buffer.writeln('📊 DADOS AGRUPADOS:');
      buffer.writeln('   • Total de organismos: ${groupedData['total_organisms']}');
      buffer.writeln('   • Tem quantidade total: ${groupedData['has_quantidade_total']}');
      buffer.writeln('   • Tem severidade média: ${groupedData['has_severity_media']}');
      buffer.writeln();
    }
    
    // Monitoramentos
    if (results['monitoring_data'] != null) {
      final monitoringData = results['monitoring_data'] as Map<String, dynamic>;
      buffer.writeln('📊 MONITORAMENTOS:');
      buffer.writeln('   • Total de monitoramentos: ${monitoringData['total_monitorings']}');
      buffer.writeln();
    }
    
    // Sessões
    if (results['session_data'] != null) {
      final sessionData = results['session_data'] as Map<String, dynamic>;
      buffer.writeln('📊 SESSÕES:');
      buffer.writeln('   • Total de sessões: ${sessionData['total_sessions']}');
      buffer.writeln();
    }
    
    // Conclusões
    buffer.writeln('🎯 CONCLUSÕES:');
    
    if (results['raw_data']?['total_records'] == 0) {
      buffer.writeln('   ❌ PROBLEMA: Nenhum dado encontrado na tabela monitoring_occurrences');
      buffer.writeln('   💡 SOLUÇÃO: Verificar se o card de nova ocorrência está salvando dados');
    } else if (results['raw_data']?['has_quantidade_data'] == false) {
      buffer.writeln('   ❌ PROBLEMA: Dados de quantidade não estão sendo salvos');
      buffer.writeln('   💡 SOLUÇÃO: Verificar mapeamento do campo quantidade no DirectOccurrenceService');
    } else if (results['grouped_data']?['total_organisms'] == 0) {
      buffer.writeln('   ❌ PROBLEMA: Dados não estão sendo agrupados corretamente');
      buffer.writeln('   💡 SOLUÇÃO: Verificar consulta SQL de agrupamento');
    } else {
      buffer.writeln('   ✅ Dados encontrados - verificar processamento no motor de cálculo');
    }
    
    return buffer.toString();
  }
}
