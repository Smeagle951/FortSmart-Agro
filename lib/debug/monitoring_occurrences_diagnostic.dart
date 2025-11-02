import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// 🔍 Diagnóstico específico para investigar problema de ocorrências
class MonitoringOccurrencesDiagnostic {
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    final results = <String, dynamic>{};
    
    try {
      final db = await AppDatabase.instance.database;
      results['database_path'] = db.path;
      
      Logger.info('🔍 [DIAGNOSTIC] Iniciando diagnóstico de ocorrências...');
      
      // 1. Verificar se a tabela monitoring_occurrences existe
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitoring_occurrences'"
      );
      results['table_exists'] = tableExists.isNotEmpty;
      
      if (!results['table_exists']) {
        results['error'] = 'Tabela monitoring_occurrences NÃO EXISTE!';
        return results;
      }
      
      // 2. Contar total de ocorrências
      results['total_occurrences'] = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_occurrences')
      );
      
      // 3. Mostrar estrutura da tabela
      final tableInfo = await db.rawQuery('PRAGMA table_info(monitoring_occurrences)');
      results['table_columns'] = tableInfo.map((col) => col['name']).toList();
      
      // 4. Buscar últimas 10 ocorrências
      final latestOccurrences = await db.query(
        'monitoring_occurrences',
        orderBy: 'created_at DESC',
        limit: 10,
      );
      results['latest_occurrences'] = latestOccurrences.map((occ) => {
        'id': occ['id'],
        'point_id': occ['point_id'],
        'session_id': occ['session_id'],
        'tipo': occ['tipo'],
        'subtipo': occ['subtipo'],
        'percentual': occ['percentual'],
        'created_at': occ['created_at'],
      }).toList();
      
      // 5. Verificar IDs de pontos na tabela monitoring_points
      final points = await db.query(
        'monitoring_points',
        orderBy: 'created_at DESC',
        limit: 10,
      );
      results['latest_points'] = points.map((pt) => {
        'id': pt['id'],
        'session_id': pt['session_id'],
        'numero': pt['numero'],
        'latitude': pt['latitude'],
        'longitude': pt['longitude'],
      }).toList();
      
      // 6. Verificar se há ocorrências órfãs (point_id que não existe em monitoring_points)
      final orphanOccurrences = await db.rawQuery('''
        SELECT mo.id, mo.point_id, mo.session_id, mo.tipo, mo.subtipo
        FROM monitoring_occurrences mo
        LEFT JOIN monitoring_points mp ON mo.point_id = mp.id
        WHERE mp.id IS NULL
        LIMIT 10
      ''');
      results['orphan_occurrences'] = orphanOccurrences.length;
      results['orphan_occurrences_list'] = orphanOccurrences;
      
      // 7. Verificar relação point_id entre monitoring_occurrences e monitoring_points
      final pointIdComparison = await db.rawQuery('''
        SELECT 
          (SELECT COUNT(*) FROM monitoring_points) as total_points,
          (SELECT COUNT(*) FROM monitoring_occurrences) as total_occurrences,
          (SELECT COUNT(DISTINCT point_id) FROM monitoring_occurrences) as distinct_point_ids_in_occ,
          (SELECT COUNT(DISTINCT id) FROM monitoring_points) as distinct_point_ids_in_points
      ''');
      results['point_id_comparison'] = pointIdComparison.first;
      
    } catch (e, stack) {
      results['error'] = 'Erro inesperado: $e';
      results['stack_trace'] = stack.toString();
      Logger.error('❌ [DIAGNOSTIC] Erro: $e', null, stack);
    }
    
    return results;
  }
  
  static String formatResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('=== 🔍 DIAGNÓSTICO DE OCORRÊNCIAS ===\n');
    
    buffer.writeln('📁 Banco: ${results['database_path']}\n');
    
    if (results.containsKey('error') && results['error'].contains('NÃO EXISTE')) {
      buffer.writeln('❌ ERRO CRÍTICO: ${results['error']}\n');
      return buffer.toString();
    }
    
    buffer.writeln('1️⃣ TABELA monitoring_occurrences:');
    buffer.writeln('   - Existe: ${results['table_exists'] ? '✅ SIM' : '❌ NÃO'}');
    buffer.writeln('   - Total de registros: ${results['total_occurrences'] ?? 0}');
    buffer.writeln('   - Colunas: ${(results['table_columns'] as List?)?.join(', ') ?? 'N/A'}\n');
    
    buffer.writeln('2️⃣ ÚLTIMAS OCORRÊNCIAS SALVAS:');
    final latestOcc = results['latest_occurrences'] as List?;
    if (latestOcc != null && latestOcc.isNotEmpty) {
      for (var occ in latestOcc.take(5)) {
        buffer.writeln('   - ID: ${occ['id']}');
        buffer.writeln('     Point ID: ${occ['point_id']}');
        buffer.writeln('     Session ID: ${occ['session_id']}');
        buffer.writeln('     Organismo: ${occ['subtipo']} (${occ['tipo']})');
        buffer.writeln('     Percentual: ${occ['percentual']}%');
        buffer.writeln('     ---');
      }
    } else {
      buffer.writeln('   ⚠️ NENHUMA OCORRÊNCIA ENCONTRADA!\n');
    }
    
    buffer.writeln('\n3️⃣ ÚLTIMOS PONTOS SALVOS:');
    final latestPts = results['latest_points'] as List?;
    if (latestPts != null && latestPts.isNotEmpty) {
      for (var pt in latestPts.take(5)) {
        buffer.writeln('   - ID: ${pt['id']}');
        buffer.writeln('     Session ID: ${pt['session_id']}');
        buffer.writeln('     Número: ${pt['numero']}');
        buffer.writeln('     GPS: ${pt['latitude']}, ${pt['longitude']}');
        buffer.writeln('     ---');
      }
    } else {
      buffer.writeln('   ⚠️ NENHUM PONTO ENCONTRADO!\n');
    }
    
    buffer.writeln('\n4️⃣ ANÁLISE DE CONEXÃO:');
    final comparison = results['point_id_comparison'] as Map?;
    if (comparison != null) {
      buffer.writeln('   - Total de pontos: ${comparison['total_points']}');
      buffer.writeln('   - Total de ocorrências: ${comparison['total_occurrences']}');
      buffer.writeln('   - IDs únicos em occurrences: ${comparison['distinct_point_ids_in_occ']}');
      buffer.writeln('   - IDs únicos em points: ${comparison['distinct_point_ids_in_points']}');
    }
    
    buffer.writeln('\n5️⃣ OCORRÊNCIAS ÓRFÃS:');
    final orphanCount = results['orphan_occurrences'] as int? ?? 0;
    buffer.writeln('   - Total órfãs: $orphanCount');
    if (orphanCount > 0) {
      final orphanList = results['orphan_occurrences_list'] as List?;
      if (orphanList != null) {
        for (var orphan in orphanList.take(3)) {
          buffer.writeln('   - ID: ${orphan['id']}, Point ID: ${orphan['point_id']}');
        }
      }
    }
    
    if (results.containsKey('error') && !results['error'].contains('NÃO EXISTE')) {
      buffer.writeln('\n❌ ERRO: ${results['error']}');
    }
    
    return buffer.toString();
  }
}

