import 'package:sqflite/sqflite.dart';
import '../../../database/app_database.dart';
import '../../../models/infestacao_model.dart';
import '../../../utils/logger.dart';
import 'advanced_infestation_calculator.dart';

/// Serviço para recalcular infestações usando o motor avançado
/// Útil quando o catálogo JSON é atualizado ou quando há dados antigos
class InfestationRecalculationService {
  final AdvancedInfestationCalculator _calculator = AdvancedInfestationCalculator();
  final AppDatabase _database = AppDatabase();

  /// Recalcula uma infestação específica usando dados brutos salvos
  Future<Map<String, dynamic>?> recalcularInfestacao(InfestacaoModel infestacao) async {
    try {
      // Se não tem dados brutos, não pode recalcular
      if (infestacao.quantidadeBruta == null || 
          infestacao.totalPlantasAvaliadas == null) {
        return null;
      }

      // Buscar cultura_id do contexto da infestação
      final db = await _database.database;
      final resultado = await db.query(
        'monitoring_occurrences',
        where: 'id = ?',
        whereArgs: [infestacao.id],
        limit: 1,
      );

      String? culturaId;
      if (resultado.isNotEmpty) {
        culturaId = resultado.first['cultura_id'] as String?;
      }

      if (culturaId == null) {
        return null;
      }

      // Usar motor de cálculo avançado
      final calculoAvancado = await _calculator.calculateInfestation(
        organismoId: infestacao.organismoId,
        quantidadeBruta: infestacao.quantidadeBruta!,
        totalPlantasAvaliadas: infestacao.totalPlantasAvaliadas!,
        culturaId: culturaId,
        tercoPlanta: infestacao.tercoPlanta,
      );

      return calculoAvancado;

    } catch (e) {
      Logger.error('Erro ao recalcular infestação: $e');
      return null;
    }
  }

  /// Recalcula todas as infestações de um monitoramento
  Future<int> recalcularMonitoramento(String sessionId) async {
    try {
      final db = await _database.database;
      
      // Buscar todas as ocorrências da sessão
      final ocorrencias = await db.query(
        'monitoring_occurrences',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );

      int recalculadas = 0;

      for (final ocorrencia in ocorrencias) {
        try {
          final infestacao = InfestacaoModel.fromMap(ocorrencia);
          
          final resultado = await recalcularInfestacao(infestacao);
          
          if (resultado != null) {
            // Atualizar registro com novo cálculo
            await db.update(
              'monitoring_occurrences',
              {
                'percentual': resultado['percentual_real'].round(),
                'nivel': resultado['nivel_severidade'],
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [infestacao.id],
            );

            // Também atualizar no mapa de infestação
            await db.update(
              'infestation_map',
              {
                'percentual': resultado['percentual_real'].round(),
                'nivel': resultado['nivel_severidade'],
                'severity_level': resultado['nivel_severidade'],
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [infestacao.id],
            );

            recalculadas++;
          }
        } catch (e) {
          Logger.error('Erro ao processar ocorrência: $e');
        }
      }

      return recalculadas;

    } catch (e) {
      Logger.error('Erro ao recalcular monitoramento: $e');
      return 0;
    }
  }

  /// Recalcula todas as infestações do banco (manutenção)
  /// Executar quando o catálogo JSON for atualizado
  Future<Map<String, int>> recalcularTodasInfestacoes() async {
    try {
      final db = await _database.database;
      
      // Contar total de ocorrências com dados brutos
      final total = await db.query(
        'monitoring_occurrences',
        where: 'quantidade_bruta IS NOT NULL AND total_plantas_avaliadas IS NOT NULL',
      );

      int processadas = 0;
      int recalculadas = 0;
      int erros = 0;

      for (final ocorrencia in total) {
        processadas++;
        
        try {
          final infestacao = InfestacaoModel.fromMap(ocorrencia);
          final resultado = await recalcularInfestacao(infestacao);
          
          if (resultado != null) {
            // Atualizar ambas as tabelas
            await db.update(
              'monitoring_occurrences',
              {
                'percentual': resultado['percentual_real'].round(),
                'nivel': resultado['nivel_severidade'],
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [infestacao.id],
            );

            await db.update(
              'infestation_map',
              {
                'percentual': resultado['percentual_real'].round(),
                'nivel': resultado['nivel_severidade'],
                'severity_level': resultado['nivel_severidade'],
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [infestacao.id],
            );

            recalculadas++;
          }
        } catch (e) {
          erros++;
        }
      }

      return {
        'total': total.length,
        'processadas': processadas,
        'recalculadas': recalculadas,
        'erros': erros,
      };

    } catch (e) {
      Logger.error('Erro ao recalcular todas as infestações: $e');
      return {
        'total': 0,
        'processadas': 0,
        'recalculadas': 0,
        'erros': 1,
      };
    }
  }
}

