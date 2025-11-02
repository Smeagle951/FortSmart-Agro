import '../database/daos/plantio_dao.dart';
import '../database/models/plantio_model.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço para carregar plantios salvos
class PlantioLoaderService {
  final PlantioDao _plantioDao = PlantioDao();
  
  /// Busca plantios por talhão e cultura
  Future<List<Plantio>> buscarPlantiosPorTalhaoECultura({
    required String talhaoId,
    String? culturaId,
  }) async {
    try {
      print('🔍 Buscando plantios para talhão: $talhaoId, cultura: $culturaId');
      
      final plantios = await _plantioDao.listarPlantiosComFiltros(
        talhaoId: talhaoId,
        cultura: culturaId,
      );
      
      print('✅ ${plantios.length} plantios encontrados');
      
      return plantios;
    } catch (e) {
      print('❌ Erro ao buscar plantios: $e');
      return [];
    }
  }
  
  /// Busca o plantio mais recente de um talhão e cultura
  Future<Plantio?> buscarUltimoPlantio({
    required String talhaoId,
    String? culturaId,
  }) async {
    try {
      // ✅ BUSCAR PRIMEIRO DE historico_plantio (dados mais completos)
      final dadosHistorico = await buscarDadosHistoricoPlantio(
        talhaoId: talhaoId,
        culturaId: culturaId,
      );
      
      if (dadosHistorico != null) {
        Logger.info('✅ Dados encontrados em historico_plantio');
        // Converter para modelo Plantio
        return Plantio(
          id: dadosHistorico['id']?.toString() ?? '',
          talhaoId: dadosHistorico['talhao_id']?.toString() ?? talhaoId,
          cultura: dadosHistorico['cultura_id']?.toString() ?? culturaId ?? '',
          variedade: dadosHistorico['variedade']?.toString() ?? '',
          dataPlantio: dadosHistorico['data_plantio'] != null 
              ? DateTime.parse(dadosHistorico['data_plantio'].toString())
              : DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      // Fallback: buscar da tabela antiga
      final plantios = await buscarPlantiosPorTalhaoECultura(
        talhaoId: talhaoId,
        culturaId: culturaId,
      );
      
      if (plantios.isEmpty) return null;
      
      // Retornar o mais recente
      return plantios.first;
    } catch (e) {
      print('❌ Erro ao buscar último plantio: $e');
      return null;
    }
  }
  
  /// Busca dados de plantio do historico_plantio
  Future<Map<String, dynamic>?> buscarDadosHistoricoPlantio({
    required String talhaoId,
    String? culturaId,
  }) async {
    try {
      Logger.info('🔍 Buscando dados de historico_plantio para talhão: $talhaoId');
      
      final db = await AppDatabase().database;
      
      String whereClause = 'talhao_id = ?';
      List<dynamic> whereArgs = [talhaoId];
      
      if (culturaId != null && culturaId.isNotEmpty) {
        whereClause += ' AND cultura_id = ?';
        whereArgs.add(culturaId);
      }
      
      final result = await db.query(
        'historico_plantio',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'data DESC',
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        Logger.info('✅ Dados encontrados: variedade=${result.first['variedade']}, safra=${result.first['safra']}');
        return result.first;
      }
      
      Logger.warning('⚠️ Nenhum dado encontrado em historico_plantio');
      return null;
      
    } catch (e) {
      Logger.error('❌ Erro ao buscar historico_plantio: $e');
      return null;
    }
  }
}

