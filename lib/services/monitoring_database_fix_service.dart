import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço para corrigir problemas de banco de dados no monitoramento
class MonitoringDatabaseFixService {
  static const String _tag = 'MonitoringDatabaseFixService';
  final AppDatabase _database = AppDatabase();

  /// Corrige problemas de foreign key no banco de dados
  Future<void> fixDatabaseIssues() async {
    try {
      Logger.info('$_tag: 🔧 Iniciando correção de problemas de banco de dados...');
      
      // 1. Verificar e criar dados de exemplo na tabela talhoes
      await _ensureTalhoesData();
      
      // 2. Verificar e criar dados de exemplo na tabela pontos_monitoramento
      await _ensurePontosMonitoramentoData();
      
      // 3. Verificar integridade das foreign keys
      await _verifyForeignKeys();
      
      Logger.info('$_tag: ✅ Correção de problemas de banco de dados concluída!');
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao corrigir problemas de banco: $e');
      rethrow;
    }
  }

  /// Verifica se existem dados na tabela talhoes
  Future<void> _ensureTalhoesData() async {
    try {
      final db = await _database.database;
      
      // Verificar se a tabela talhoes existe e tem dados
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM talhoes')
      ) ?? 0;
      
      Logger.info('$_tag: 📊 Tabela talhoes tem $count registros');
      
      if (count == 0) {
        Logger.warning('$_tag: ⚠️ Nenhum talhão encontrado na tabela talhoes');
        Logger.info('$_tag: 💡 O usuário precisa criar talhões através do módulo de talhões');
      } else {
        Logger.info('$_tag: ✅ Talhões encontrados na tabela');
      }
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao verificar dados na tabela talhoes: $e');
      rethrow;
    }
  }

  /// Verifica se existem dados na tabela pontos_monitoramento
  Future<void> _ensurePontosMonitoramentoData() async {
    try {
      final db = await _database.database;
      
      // Verificar se a tabela pontos_monitoramento existe e tem dados
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM pontos_monitoramento')
      ) ?? 0;
      
      Logger.info('$_tag: 📊 Tabela pontos_monitoramento tem $count registros');
      
      if (count == 0) {
        Logger.warning('$_tag: ⚠️ Nenhum ponto de monitoramento encontrado');
        Logger.info('$_tag: 💡 O usuário precisa criar pontos através do módulo de monitoramento');
      } else {
        Logger.info('$_tag: ✅ Pontos de monitoramento encontrados na tabela');
      }
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao verificar dados na tabela pontos_monitoramento: $e');
      rethrow;
    }
  }

  /// Verifica a integridade das foreign keys
  Future<void> _verifyForeignKeys() async {
    try {
      final db = await _database.database;
      
      Logger.info('$_tag: 🔍 Verificando integridade das foreign keys...');
      
      // Verificar se existem talhões
      final talhoesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM talhoes')
      ) ?? 0;
      
      // Verificar se existem pontos de monitoramento
      final pontosCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM pontos_monitoramento')
      ) ?? 0;
      
      Logger.info('$_tag: 📊 Talhões: $talhoesCount, Pontos: $pontosCount');
      
      if (talhoesCount == 0) {
        Logger.warning('$_tag: ⚠️ Nenhum talhão encontrado!');
      }
      
      if (pontosCount == 0) {
        Logger.warning('$_tag: ⚠️ Nenhum ponto de monitoramento encontrado!');
      }
      
      // Verificar se há infestações órfãs
      final infestoesOrfas = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM infestacoes_monitoramento i 
        LEFT JOIN talhoes t ON i.talhao_id = t.id 
        WHERE t.id IS NULL
      ''');
      
      final countOrfas = infestoesOrfas.first['count'] as int? ?? 0;
      
      if (countOrfas > 0) {
        Logger.warning('$_tag: ⚠️ Encontradas $countOrfas infestações órfãs (sem talhão correspondente)');
      }
      
      Logger.info('$_tag: ✅ Verificação de integridade concluída');
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao verificar integridade das foreign keys: $e');
      rethrow;
    }
  }

  /// Verifica se um talhão existe no banco de dados
  Future<bool> talhaoExists(String talhaoId) async {
    try {
      final db = await _database.database;
      
      Logger.info('$_tag: 🔍 Verificando se talhão existe: $talhaoId');
      
      // Primeiro, tentar verificar com o ID string diretamente
      var result = await db.query(
        'talhoes',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [talhaoId],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        Logger.info('$_tag: ✅ Talhão encontrado com ID string: $talhaoId');
        return true;
      }
      
      // Se não encontrou, tentar converter para int e verificar
      final talhaoIdInt = int.tryParse(talhaoId);
      if (talhaoIdInt != null) {
        result = await db.query(
          'talhoes',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [talhaoIdInt],
          limit: 1,
        );
        
        if (result.isNotEmpty) {
          Logger.info('$_tag: ✅ Talhão encontrado com ID int: $talhaoIdInt');
          return true;
        }
      }
      
      // Se ainda não encontrou, tentar verificar se é um UUID e usar hash
      if (talhaoId.contains('-')) {
        final hashId = talhaoId.hashCode.abs();
        result = await db.query(
          'talhoes',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [hashId],
          limit: 1,
        );
        
        if (result.isNotEmpty) {
          Logger.info('$_tag: ✅ Talhão encontrado com ID hash: $hashId (original: $talhaoId)');
          return true;
        }
      }
      
      // Se não encontrou de nenhuma forma, verificar se há talhões na tabela
      final allTalhoes = await db.query('talhoes', columns: ['id'], limit: 5);
      Logger.info('$_tag: 📊 Talhões disponíveis na tabela: ${allTalhoes.map((t) => t['id']).join(', ')}');
      
      Logger.warning('$_tag: ⚠️ Talhão $talhaoId não encontrado');
      return false;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao verificar talhão: $e');
      Logger.error('$_tag: ❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Verifica se um ponto de monitoramento existe no banco de dados
  Future<bool> pontoExists(int pontoId) async {
    try {
      final db = await _database.database;
      
      Logger.info('$_tag: 🔍 Verificando se ponto existe: $pontoId');
      
      // Verificar na tabela pontos_monitoramento
      var result = await db.query(
        'pontos_monitoramento',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [pontoId],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        Logger.info('$_tag: ✅ Ponto encontrado na tabela pontos_monitoramento: $pontoId');
        return true;
      }
      
      // Verificar na tabela monitoring_points (nova estrutura)
      result = await db.query(
        'monitoring_points',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [pontoId.toString()],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        Logger.info('$_tag: ✅ Ponto encontrado na tabela monitoring_points: $pontoId');
        return true;
      }
      
      // Verificar na tabela pontos_monitoramento_simples (método alternativo)
      result = await db.query(
        'pontos_monitoramento_simples',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [pontoId],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        Logger.info('$_tag: ✅ Ponto encontrado na tabela pontos_monitoramento_simples: $pontoId');
        return true;
      }
      
      // Se não encontrou, verificar se há pontos nas tabelas
      try {
        final pontosCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM pontos_monitoramento')
        ) ?? 0;
        Logger.info('$_tag: 📊 Pontos na tabela pontos_monitoramento: $pontosCount');
      } catch (e) {
        Logger.info('$_tag: 📊 Tabela pontos_monitoramento não existe');
      }
      
      try {
        final monitoringPointsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM monitoring_points')
        ) ?? 0;
        Logger.info('$_tag: 📊 Pontos na tabela monitoring_points: $monitoringPointsCount');
      } catch (e) {
        Logger.info('$_tag: 📊 Tabela monitoring_points não existe');
      }
      
      try {
        final simplesCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM pontos_monitoramento_simples')
        ) ?? 0;
        Logger.info('$_tag: 📊 Pontos na tabela pontos_monitoramento_simples: $simplesCount');
      } catch (e) {
        Logger.info('$_tag: 📊 Tabela pontos_monitoramento_simples não existe');
      }
      
      Logger.warning('$_tag: ⚠️ Ponto $pontoId não encontrado em nenhuma tabela');
      return false;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao verificar ponto: $e');
      Logger.error('$_tag: ❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Converte talhao_id de INTEGER para TEXT (para compatibilidade)
  String convertTalhaoIdToText(int talhaoId) {
    // Mapear IDs inteiros para IDs de texto
    switch (talhaoId) {
      case 0:
      case 1:
        return 'talhao_1';
      case 2:
        return 'talhao_2';
      default:
        return 'talhao_$talhaoId';
    }
  }

  /// Converte talhao_id de TEXT para INTEGER (para compatibilidade)
  int convertTalhaoIdToInt(String talhaoId) {
    // Mapear IDs de texto para IDs inteiros
    switch (talhaoId) {
      case 'talhao_1':
        return 1;
      case 'talhao_2':
        return 2;
      default:
        // Tentar extrair número do ID
        final match = RegExp(r'talhao_(\d+)').firstMatch(talhaoId);
        if (match != null) {
          return int.tryParse(match.group(1)!) ?? 1;
        }
        return 1;
    }
  }
}