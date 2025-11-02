import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../database/app_database.dart';
import '../utils/logger.dart';
import 'agronomic_severity_calculator.dart';

/// Serviço DIRETO e SIMPLES para salvar ocorrências
/// SEM complexidade, SEM múltiplos métodos, SEM falhas silenciosas
class DirectOccurrenceService {
  static const String _tag = 'DIRECT_OCC';

  /// Salva uma ocorrência DIRETAMENTE no banco
  /// Retorna true se salvou com sucesso, false caso contrário
  static Future<bool> saveOccurrence({
    required String sessionId,
    required String pointId,
    required String talhaoId,
    required String tipo,
    required String subtipo,
    required String nivel,
    required int percentual,
    required double? latitude,
    required double? longitude,
    String? observacao,
    List<String>? fotoPaths,
    String? tercoPlanta,
    int? quantidade, // ✅ NOVO: Campo quantidade separado
    double? temperature, // ✅ NOVO: Temperatura
    double? humidity, // ✅ NOVO: Umidade
    double? agronomicSeverity, // ✅ NOVO: Aceitar severidade já calculada
  }) async {
    try {
      Logger.info('🔵 [$_tag] ==========================================');
      Logger.info('🔵 [$_tag] INICIANDO SALVAMENTO DE OCORRÊNCIA');
      Logger.info('🔵 [$_tag] Session ID: $sessionId');
      Logger.info('🔵 [$_tag] Point ID: $pointId');
      Logger.info('🔵 [$_tag] Talhão ID: $talhaoId');
      Logger.info('🔵 [$_tag] Tipo: $tipo');
      Logger.info('🔵 [$_tag] Subtipo: $subtipo');
      Logger.info('🔵 [$_tag] Percentual: $percentual%');
      if (temperature != null) Logger.info('🔵 [$_tag] Temperatura: ${temperature}°C');
      if (humidity != null) Logger.info('🔵 [$_tag] Umidade: ${humidity}%');
      if (fotoPaths != null && fotoPaths.isNotEmpty) Logger.info('🔵 [$_tag] Fotos: ${fotoPaths.length} imagem(ns)');
      Logger.info('🔵 [$_tag] ==========================================');

      // 1. Obter o banco
      final db = await AppDatabase.instance.database;
      Logger.info('✅ [$_tag] Banco de dados obtido');

      // 2. Verificar se a tabela existe
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitoring_occurrences'"
      );
      
      if (tableCheck.isEmpty) {
        Logger.error('❌ [$_tag] Tabela monitoring_occurrences NÃO EXISTE!');
        return false;
      }
      Logger.info('✅ [$_tag] Tabela monitoring_occurrences existe');

      // ✅ 2.5: GARANTIR QUE O PONTO EXISTE (CRÍTICO PARA MONITORAMENTO LIVRE)
      final pointExists = await db.rawQuery(
        'SELECT id FROM monitoring_points WHERE id = ?',
        [pointId],
      );
      
      if (pointExists.isEmpty) {
        Logger.warning('⚠️ [$_tag] Ponto $pointId não existe - criando automaticamente...');
        
        // Buscar dados da sessão para obter informações necessárias
        final sessionData = await db.query(
          'monitoring_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
          limit: 1,
        );
        
        if (sessionData.isNotEmpty) {
          final session = sessionData.first;
          
          // Contar quantos pontos já existem para essa sessão (para definir o número)
          final existingPoints = await db.rawQuery(
            'SELECT COUNT(*) as total FROM monitoring_points WHERE session_id = ?',
            [sessionId],
          );
          final numeroPonto = ((existingPoints.first['total'] as num?)?.toInt() ?? 0) + 1;
          
          // Criar o ponto com os dados disponíveis
          await db.insert('monitoring_points', {
            'id': pointId,
            'session_id': sessionId,
            'numero': numeroPonto,
            'latitude': latitude ?? 0.0,
            'longitude': longitude ?? 0.0,
            'timestamp': DateTime.now().toIso8601String(),
            'manual_entry': 1, // ✅ Monitoramento livre é entrada manual
            'sync_state': 'synced',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          Logger.info('✅ [$_tag] Ponto $pointId criado automaticamente (número $numeroPonto)');
        } else {
          Logger.error('❌ [$_tag] Sessão $sessionId não encontrada - não é possível criar ponto');
          return false;
        }
      } else {
        Logger.info('✅ [$_tag] Ponto $pointId já existe');
      }

      // 3. ✅ VERIFICAR SE JÁ EXISTE OCORRÊNCIA DUPLICADA
      final existingOcc = await db.query(
        'monitoring_occurrences',
        where: 'session_id = ? AND point_id = ? AND organism_name = ? AND tipo = ?',
        whereArgs: [sessionId, pointId, subtipo, tipo],
        limit: 1,
      );
      
      if (existingOcc.isNotEmpty) {
        Logger.warning('⚠️ [$_tag] ============================================');
        Logger.warning('⚠️ [$_tag] OCORRÊNCIA DUPLICADA DETECTADA!');
        Logger.warning('⚠️ [$_tag] Session: $sessionId');
        Logger.warning('⚠️ [$_tag] Point: $pointId');
        Logger.warning('⚠️ [$_tag] Organism: $subtipo');
        Logger.warning('⚠️ [$_tag] Tipo: $tipo');
        Logger.warning('⚠️ [$_tag] ID existente: ${existingOcc.first['id']}');
        Logger.warning('⚠️ [$_tag] PULANDO salvamento para evitar duplicação!');
        Logger.warning('⚠️ [$_tag] ============================================');
        return true; // ✅ Retornar sucesso (já existe)
      }
      Logger.info('✅ [$_tag] Nenhuma duplicata encontrada, prosseguindo...');
      
      // 4. Gerar ID único
      final occId = '${DateTime.now().millisecondsSinceEpoch}_${pointId}_${tipo}_${subtipo}';
      Logger.info('✅ [$_tag] ID gerado: $occId');

      // 4. Preparar dados
      final now = DateTime.now().toIso8601String();
      
      // ✅ USAR SEVERIDADE JÁ CALCULADA (vem do NewOccurrenceCard)
      double finalAgronomicSeverity = agronomicSeverity ?? 0.0;
      
      // Se não veio severidade calculada, calcular agora
      if (finalAgronomicSeverity == 0.0 && quantidade != null && quantidade > 0) {
      try {
          finalAgronomicSeverity = await AgronomicSeverityCalculator.calculateSeverity(
            pointCount: quantidade, // ✅ USAR QUANTIDADE, não percentual!
          organismName: subtipo,
          cropName: 'SOJA', // TODO: Obter da sessão
          cropStage: 'V6', // TODO: Obter da sessão
          organismType: tipo,
            temperature: temperature,
            humidity: humidity,
          totalPlantsEvaluated: 10,
        );
          Logger.info('✅ [$_tag] Severidade agronômica calculada: $finalAgronomicSeverity');
      } catch (e) {
        Logger.warning('⚠️ [$_tag] Erro ao calcular severidade agronômica: $e');
          finalAgronomicSeverity = percentual.toDouble(); // Fallback para percentual
        }
      } else if (finalAgronomicSeverity > 0.0) {
        Logger.info('✅ [$_tag] Usando severidade agronômica JÁ CALCULADA: $finalAgronomicSeverity');
      }
      
      // ✅ GARANTIR QUE organism_id E organism_name EXISTAM NA TABELA
      try {
        await db.execute('ALTER TABLE monitoring_occurrences ADD COLUMN organism_id TEXT');
      } catch (_) {
        // Coluna já existe
      }
      try {
        await db.execute('ALTER TABLE monitoring_occurrences ADD COLUMN organism_name TEXT');
      } catch (_) {
        // Coluna já existe
      }
      
      // ✅ FILTRAR STRINGS VAZIAS DAS FOTOS
      final fotoPathsLimpos = fotoPaths
          ?.where((path) => path != null && path.trim().isNotEmpty)
          .map((path) => path.trim())
          .toList() ?? [];
      
      Logger.info('📸 [$_tag] ===== PROCESSAMENTO DE FOTOS =====');
      Logger.info('   📥 fotoPaths recebido: $fotoPaths');
      Logger.info('   🧹 Após limpeza: $fotoPathsLimpos');
      Logger.info('   📊 Total válido: ${fotoPathsLimpos.length} imagem(ns)');
      Logger.info('📸 [$_tag] ==================================');
      
      final data = {
        'id': occId,
        'point_id': pointId,
        'session_id': sessionId,
        'talhao_id': talhaoId,
        'organism_id': subtipo, // ✅ Usar subtipo como organism_id (nome do organismo)
        'organism_name': subtipo, // ✅ Nome do organismo
        'tipo': tipo,
        'subtipo': subtipo,
        'nivel': nivel,
        'percentual': percentual,
        'quantidade': quantidade ?? percentual, // ✅ USAR quantidade real se disponível
        'agronomic_severity': finalAgronomicSeverity, // ✅ USAR SEVERIDADE CORRETA
        'terco_planta': tercoPlanta ?? 'Médio',
        'observacao': observacao, // ✅ SEM 's' - conforme schema da tabela
        'foto_paths': fotoPathsLimpos.isNotEmpty ? jsonEncode(fotoPathsLimpos) : null, // ✅ FILTRAR vazios!
        'latitude': latitude,
        'longitude': longitude,
        'data_hora': now,
        'sincronizado': 0,
        'created_at': now,
        'updated_at': now,
      };

      Logger.info('✅ [$_tag] Dados preparados: ${data.keys.toList()}');
      Logger.info('🔍 [$_tag] ========== VALORES EXATOS SALVOS ==========');
      Logger.info('   📦 quantidade: ${data['quantidade']}');
      Logger.info('   📊 percentual: ${data['percentual']}');
      Logger.info('   🎯 agronomic_severity: ${data['agronomic_severity']}');
      Logger.info('   🦠 organism_name: ${data['organism_name']}');
      Logger.info('   📸 foto_paths: ${data['foto_paths']}');
      Logger.info('   📸 total_imagens_validas: ${fotoPathsLimpos.length}');
      Logger.info('🔍 [$_tag] ============================================');

      // 5. INSERIR NO BANCO (com conflito = replace)
      final rowId = await db.insert(
        'monitoring_occurrences',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      Logger.info('✅ [$_tag] Ocorrência INSERIDA! Row ID: $rowId');

      // 6. VERIFICAR se foi salvo mesmo
      final verification = await db.query(
        'monitoring_occurrences',
        where: 'id = ?',
        whereArgs: [occId],
        limit: 1,
      );

      if (verification.isEmpty) {
        Logger.error('❌ [$_tag] VERIFICAÇÃO FALHOU! Ocorrência NÃO está no banco!');
        return false;
      }

      Logger.info('✅ [$_tag] VERIFICAÇÃO OK! Ocorrência confirmada no banco');
      Logger.info('🔍 [$_tag] ===== DADOS SALVOS NO BANCO =====');
      Logger.info('   ID: ${verification.first['id']}');
      Logger.info('   organism_name: ${verification.first['organism_name']}');
      Logger.info('   quantidade: ${verification.first['quantidade']}');
      Logger.info('   percentual: ${verification.first['percentual']}');
      Logger.info('   agronomic_severity: ${verification.first['agronomic_severity']}');
      Logger.info('   session_id: ${verification.first['session_id']}');
      Logger.info('   talhao_id: ${verification.first['talhao_id']}');
      Logger.info('🔍 [$_tag] =============================');
      
      // 6. SINCRONIZAR PARA INFESTATION_MAP (para o mapa funcionar!)
      try {
        await _syncToInfestationMap(db, data, occId, sessionId, talhaoId);
        Logger.info('✅ [$_tag] Sincronizado para infestation_map!');
      } catch (syncError) {
        Logger.warning('⚠️ [$_tag] Erro ao sincronizar para infestation_map: $syncError');
        // Não falhar o salvamento principal
      }
      
      // 7. ✅ ATUALIZAR TEMPERATURA E UMIDADE NA SESSÃO DE MONITORAMENTO
      if (temperature != null || humidity != null) {
        try {
          await _updateSessionWeatherData(db, sessionId, temperature, humidity);
          Logger.info('✅ [$_tag] Temperatura/Umidade atualizadas na sessão!');
        } catch (weatherError) {
          Logger.warning('⚠️ [$_tag] Erro ao atualizar temperatura/umidade: $weatherError');
          // Não falhar o salvamento principal
        }
      }
      
      Logger.info('🎉 [$_tag] SALVAMENTO CONCLUÍDO COM SUCESSO!');
      Logger.info('🔵 [$_tag] ==========================================\n');

      return true;

    } catch (e, stack) {
      Logger.error('❌ [$_tag] ERRO CRÍTICO NO SALVAMENTO: $e', null, stack);
      Logger.error('❌ [$_tag] Stack trace: $stack');
      return false;
    }
  }

  /// Conta quantas ocorrências existem para uma sessão
  static Future<int> countOccurrencesForSession(String sessionId) async {
    try {
      final db = await AppDatabase.instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM monitoring_occurrences WHERE session_id = ?',
        [sessionId],
      );
      final count = (result.first['count'] as num?)?.toInt() ?? 0;
      Logger.info('📊 [$_tag] Sessão $sessionId tem $count ocorrências');
      return count;
    } catch (e) {
      Logger.error('❌ [$_tag] Erro ao contar ocorrências: $e');
      return 0;
    }
  }

  /// Conta quantas ocorrências existem para um ponto
  static Future<int> countOccurrencesForPoint(String pointId) async {
    try {
      final db = await AppDatabase.instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM monitoring_occurrences WHERE point_id = ?',
        [pointId],
      );
      final count = (result.first['count'] as num?)?.toInt() ?? 0;
      Logger.info('📊 [$_tag] Ponto $pointId tem $count ocorrências');
      return count;
    } catch (e) {
      Logger.error('❌ [$_tag] Erro ao contar ocorrências: $e');
      return 0;
    }
  }

  /// Lista todas as ocorrências de uma sessão
  static Future<List<Map<String, dynamic>>> getOccurrencesForSession(String sessionId) async {
    try {
      final db = await AppDatabase.instance.database;
      final occurrences = await db.query(
        'monitoring_occurrences',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'created_at DESC',
      );
      Logger.info('📊 [$_tag] ${occurrences.length} ocorrências encontradas para sessão $sessionId');
      return occurrences;
    } catch (e) {
      Logger.error('❌ [$_tag] Erro ao buscar ocorrências: $e');
      return [];
    }
  }

  /// Diagnóstico rápido do banco
  static Future<Map<String, int>> quickDiagnostic() async {
    try {
      final db = await AppDatabase.instance.database;
      
      final sessionsResult = await db.rawQuery('SELECT COUNT(*) as total FROM monitoring_sessions');
      final sessionsCount = (sessionsResult.first['total'] as num?)?.toInt() ?? 0;
      
      final pointsResult = await db.rawQuery('SELECT COUNT(*) as total FROM monitoring_points');
      final pointsCount = (pointsResult.first['total'] as num?)?.toInt() ?? 0;
      
      final occurrencesResult = await db.rawQuery('SELECT COUNT(*) as total FROM monitoring_occurrences');
      final occurrencesCount = (occurrencesResult.first['total'] as num?)?.toInt() ?? 0;

      Logger.info('📊 [$_tag] DIAGNÓSTICO RÁPIDO:');
      Logger.info('   - Sessões: $sessionsCount');
      Logger.info('   - Pontos: $pointsCount');
      Logger.info('   - Ocorrências: $occurrencesCount');

      return {
        'sessions': sessionsCount,
        'points': pointsCount,
        'occurrences': occurrencesCount,
      };
    } catch (e) {
      Logger.error('❌ [$_tag] Erro no diagnóstico: $e');
      return {'sessions': 0, 'points': 0, 'occurrences': 0};
    }
  }
  
  /// Sincroniza ocorrência para infestation_map
  static Future<void> _syncToInfestationMap(
    Database db,
    Map<String, dynamic> occData,
    String occId,
    String sessionId,
    String talhaoId,
  ) async {
    Logger.info('🔄 [$_tag] Sincronizando para infestation_map...');
    
    // Buscar dados da sessão para pegar cultura_nome e talhao_nome
    final sessionData = await db.query(
      'monitoring_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    
    if (sessionData.isEmpty) {
      Logger.warning('⚠️ [$_tag] Sessão não encontrada para sincronização');
      return;
    }
    
    final session = sessionData.first;
    
    await db.insert(
      'infestation_map',
      {
        'id': occId,
        'ponto_id': occData['point_id'],
        'talhao_id': talhaoId,
        'latitude': occData['latitude'],
        'longitude': occData['longitude'],
        'tipo': occData['tipo'],
        'subtipo': occData['subtipo'],
        'nivel': occData['nivel'],
        'percentual': occData['percentual'],
        'observacao': occData['observacao'],
        'foto_paths': occData['foto_paths'],
        'data_hora': occData['data_hora'],
        'sincronizado': 0,
        'cultura_id': session['cultura_id'],
        'cultura_nome': session['cultura_nome'],
        'talhao_nome': session['talhao_nome'],
        'severity_level': occData['nivel']?.toString().toLowerCase() ?? 'low',
        'status': 'active',
        'source': 'monitoring_module',
        'created_at': occData['created_at'],
        'updated_at': occData['updated_at'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    Logger.info('✅ [$_tag] Sincronizado para infestation_map!');
  }
  
  /// Atualiza temperatura e umidade na sessão de monitoramento
  static Future<void> _updateSessionWeatherData(
    Database db,
    String sessionId,
    double? temperature,
    double? humidity,
  ) async {
    Logger.info('🌤️ [$_tag] Atualizando temperatura/umidade na sessão $sessionId...');
    
    // Garantir que as colunas existem
    try {
      await db.execute('ALTER TABLE monitoring_sessions ADD COLUMN temperatura REAL');
    } catch (_) {
      // Coluna já existe
    }
    try {
      await db.execute('ALTER TABLE monitoring_sessions ADD COLUMN umidade REAL');
    } catch (_) {
      // Coluna já existe
    }
    
    // Buscar valores atuais (se existirem)
    final currentData = await db.query(
      'monitoring_sessions',
      columns: ['temperatura', 'umidade'],
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    
    // Preparar valores para atualização (manter valores antigos se novos forem null)
    final Map<String, dynamic> updateData = {};
    
    if (currentData.isNotEmpty) {
      final currentTemp = (currentData.first['temperatura'] as num?)?.toDouble();
      final currentHumid = (currentData.first['umidade'] as num?)?.toDouble();
      
      // Usar novo valor se fornecido, senão manter o antigo
      updateData['temperatura'] = temperature ?? currentTemp;
      updateData['umidade'] = humidity ?? currentHumid;
    } else {
      // Se não houver dados atuais, usar os novos valores
      if (temperature != null) updateData['temperatura'] = temperature;
      if (humidity != null) updateData['umidade'] = humidity;
    }
    
    if (updateData.isNotEmpty) {
      await db.update(
        'monitoring_sessions',
        updateData,
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      
      Logger.info('✅ [$_tag] Temperatura/Umidade atualizadas: Temp=${updateData['temperatura']}°C, Umid=${updateData['umidade']}%');
    }
  }
}

