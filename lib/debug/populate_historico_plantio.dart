import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../database/models/historico_plantio_model.dart';
import '../database/repositories/historico_plantio_repository.dart';
import '../utils/logger.dart';

/// 🔧 SCRIPT: Popular historico_plantio com dados existentes
class PopulateHistoricoPlantio {
  static Future<void> executar(BuildContext context) async {
    try {
      Logger.info('🔧 ========================================');
      Logger.info('🔧 POPULANDO historico_plantio');
      Logger.info('🔧 ========================================');
      
      final db = await AppDatabase().database;
      final repository = HistoricoPlantioRepository();
      
      // Limpar histórico existente (opcional)
      // await db.delete('historico_plantio');
      // Logger.info('🗑️ Histórico limpo');
      
      // 1. Buscar dados de plantio_integrado
      Logger.info('📊 Buscando dados de plantio_integrado...');
      final plantiosIntegrados = await db.query('plantio_integrado');
      Logger.info('   - ${plantiosIntegrados.length} registros encontrados');
      
      int inseridos = 0;
      
      for (var plantio in plantiosIntegrados) {
        final talhaoId = plantio['talhao_id'] as String?;
        final culturaId = plantio['cultura_id'] as String?;
        final talhaoNome = plantio['talhao_nome'] as String?;
        
        if (talhaoId == null || culturaId == null) {
          Logger.info('   ⚠️ Registro sem talhaoId ou culturaId: ${plantio['id']}');
          continue;
        }
        
        // Verificar se já existe
        final existe = await db.query(
          'historico_plantio',
          where: 'talhao_id = ? AND cultura_id = ?',
          whereArgs: [talhaoId, culturaId],
          limit: 1,
        );
        
        if (existe.isNotEmpty) {
          Logger.info('   ⏭️ Já existe: $talhaoNome → $culturaId');
          continue;
        }
        
        // Criar registro de histórico
        final historico = HistoricoPlantioModel(
          calculoId: plantio['id'] as String? ?? '',
          talhaoId: talhaoId,
          talhaoNome: talhaoNome,
          safraId: plantio['safra_id'] as String? ?? '',
          culturaId: culturaId,
          tipo: 'plantio_integrado',
          data: DateTime.parse(plantio['data_plantio'] as String? ?? DateTime.now().toIso8601String()),
          resumo: 'Talhão: ${talhaoNome ?? talhaoId}, Cultura: $culturaId',
        );
        
        await repository.salvar(historico);
        inseridos++;
        
        Logger.info('   ✅ Inserido: $talhaoNome → $culturaId');
      }
      
      // 2. Buscar dados da tabela plantio (se existir)
      try {
        Logger.info('📊 Buscando dados da tabela plantio...');
        final plantios = await db.query('plantio');
        Logger.info('   - ${plantios.length} registros encontrados');
        
        for (var plantio in plantios) {
          final talhaoId = plantio['talhao_id'] as String?;
          final culturaId = plantio['cultura_id'] as String? ?? plantio['cultura'] as String?;
          
          if (talhaoId == null || culturaId == null) {
            continue;
          }
          
          // Verificar se já existe
          final existe = await db.query(
            'historico_plantio',
            where: 'talhao_id = ? AND cultura_id = ?',
            whereArgs: [talhaoId, culturaId],
            limit: 1,
          );
          
          if (existe.isNotEmpty) {
            continue;
          }
          
          // Criar registro de histórico
          final historico = HistoricoPlantioModel(
            calculoId: plantio['id'] as String? ?? '',
            talhaoId: talhaoId,
            talhaoNome: null, // Será buscado depois
            safraId: plantio['safra_id'] as String? ?? '',
            culturaId: culturaId,
            tipo: 'plantio_manual',
            data: DateTime.parse(plantio['data_plantio'] as String? ?? DateTime.now().toIso8601String()),
            resumo: 'Cultura: $culturaId',
          );
          
          await repository.salvar(historico);
          inseridos++;
          
          Logger.info('   ✅ Inserido da tabela plantio: $talhaoId → $culturaId');
        }
      } catch (e) {
        Logger.info('   ⚠️ Tabela plantio não existe ou erro: $e');
      }
      
      // Verificar resultado final
      final totalFinal = await db.rawQuery('SELECT COUNT(*) as total FROM historico_plantio');
      final total = totalFinal.first['total'] as int;
      
      Logger.info('🔧 ========================================');
      Logger.info('✅ POPULAÇÃO CONCLUÍDA');
      Logger.info('   - Registros inseridos: $inseridos');
      Logger.info('   - Total na tabela: $total');
      Logger.info('🔧 ========================================');
      
      // Mostrar resultado
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ População Concluída'),
            content: Text(
              'Registros inseridos: $inseridos\n'
              'Total na tabela: $total\n\n'
              'Agora volte à Dashboard e clique no botão de refresh no card de Plantios.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
    } catch (e, stack) {
      Logger.error('❌ Erro ao popular historico_plantio: $e');
      Logger.error('Stack: $stack');
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Erro'),
            content: Text('Erro ao popular histórico:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

