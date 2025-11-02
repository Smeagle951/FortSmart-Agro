import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Verificação RÁPIDA do banco de dados
class QuickDBCheck {
  static Future<void> run() async {
    try {
      Logger.info('═══════════════════════════════════════════');
      Logger.info('🔍 VERIFICAÇÃO RÁPIDA DO BANCO DE DADOS');
      Logger.info('═══════════════════════════════════════════');
      
      final db = await AppDatabase.instance.database;
      
      // 1. Sessões
      final sessionsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_sessions')
      ) ?? 0;
      Logger.info('📊 SESSÕES: $sessionsCount');
      
      // 2. Pontos
      final pointsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_points')
      ) ?? 0;
      Logger.info('📍 PONTOS: $pointsCount');
      
      // 3. Ocorrências
      final occCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM monitoring_occurrences')
      ) ?? 0;
      Logger.info('🐛 OCORRÊNCIAS: $occCount');
      
      if (occCount == 0 && sessionsCount > 0) {
        Logger.error('❌ PROBLEMA: $sessionsCount sessões MAS 0 ocorrências!');
        Logger.error('   → As ocorrências NÃO estão sendo salvas no banco!');
      } else if (occCount > 0) {
        Logger.info('✅ TUDO OK: $occCount ocorrências salvas!');
        
        // Mostrar última ocorrência
        final lastOcc = await db.rawQuery('''
          SELECT subtipo, tipo, percentual, created_at 
          FROM monitoring_occurrences 
          ORDER BY created_at DESC 
          LIMIT 1
        ''');
        
        if (lastOcc.isNotEmpty) {
          Logger.info('   📍 Última: ${lastOcc.first['tipo']}/${lastOcc.first['subtipo']} (${lastOcc.first['percentual']}%)');
        }
      }
      
      Logger.info('═══════════════════════════════════════════\n');
      
    } catch (e) {
      Logger.error('❌ Erro na verificação rápida: $e');
    }
  }
}

