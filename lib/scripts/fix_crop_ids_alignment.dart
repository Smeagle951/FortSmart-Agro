import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/pest_dao.dart';
import '../database/daos/disease_dao.dart';
import '../database/daos/weed_dao.dart';
import '../utils/logger.dart';

/// Script para corrigir o alinhamento dos IDs das culturas
/// 
/// PROBLEMA: Os IDs das culturas no CropDao estavam desalinhados com os IDs
/// esperados pelo PestDao e DiseaseDao, causando a não exibição de pragas e doenças.
/// 
/// SOLUÇÃO: 
/// 1. Limpar todas as culturas, pragas, doenças e plantas daninhas
/// 2. Recriar as culturas com IDs corretos (alinhados com PestDao/DiseaseDao)
/// 3. Recriar pragas, doenças e plantas daninhas
class FixCropIdsAlignment {
  final AppDatabase _appDatabase = AppDatabase();
  final CropDao _cropDao = CropDao();
  final PestDao _pestDao = PestDao();
  final DiseaseDao _diseaseDao = DiseaseDao();
  final WeedDao _weedDao = WeedDao();

  /// Executa a correção completa
  Future<void> execute() async {
    try {
      Logger.info('🔧 ========================================');
      Logger.info('🔧 INICIANDO CORREÇÃO DE IDS DAS CULTURAS');
      Logger.info('🔧 ========================================');
      
      final db = await _appDatabase.database;
      
      // 1. Backup dos dados existentes (opcional - por segurança)
      await _backupCurrentData(db);
      
      // 2. Limpar dados existentes
      await _clearAllData(db);
      
      // 3. Recriar culturas com IDs corretos
      await _recreateCropsWithCorrectIds();
      
      // 4. Recriar pragas, doenças e plantas daninhas
      await _recreatePestsDiseasesWeeds();
      
      // 5. Verificar se tudo foi criado corretamente
      await _verifyDataIntegrity(db);
      
      Logger.info('✅ ========================================');
      Logger.info('✅ CORREÇÃO CONCLUÍDA COM SUCESSO!');
      Logger.info('✅ ========================================');
    } catch (e, stackTrace) {
      Logger.error('❌ Erro ao executar correção de IDs: $e');
      Logger.error('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Faz backup dos dados atuais
  Future<void> _backupCurrentData(Database db) async {
    try {
      Logger.info('📦 Fazendo backup dos dados atuais...');
      
      final crops = await db.query('crops');
      final pests = await db.query('pests');
      final diseases = await db.query('diseases');
      final weeds = await db.query('weeds');
      
      Logger.info('📊 Backup: ${crops.length} culturas, ${pests.length} pragas, ${diseases.length} doenças, ${weeds.length} plantas daninhas');
    } catch (e) {
      Logger.warning('⚠️ Erro ao fazer backup: $e (continuando...)');
    }
  }

  /// Limpa todos os dados das tabelas
  Future<void> _clearAllData(Database db) async {
    try {
      Logger.info('🗑️ Limpando dados existentes...');
      
      // Desabilitar foreign keys temporariamente para evitar erros
      await db.execute('PRAGMA foreign_keys = OFF');
      
      // Limpar tabelas na ordem correta (devido a foreign keys)
      await db.delete('weeds');
      await db.delete('diseases');
      await db.delete('pests');
      await db.delete('crop_varieties');
      await db.delete('crops');
      
      // Reabilitar foreign keys
      await db.execute('PRAGMA foreign_keys = ON');
      
      Logger.info('✅ Dados limpos com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao limpar dados: $e');
      rethrow;
    }
  }

  /// Recria as culturas com IDs corretos
  Future<void> _recreateCropsWithCorrectIds() async {
    try {
      Logger.info('🌾 Recriando culturas com IDs corretos...');
      
      await _cropDao.insertDefaultCrops();
      
      Logger.info('✅ Culturas recriadas com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao recriar culturas: $e');
      rethrow;
    }
  }

  /// Recria pragas, doenças e plantas daninhas
  Future<void> _recreatePestsDiseasesWeeds() async {
    try {
      Logger.info('🐛 Recriando pragas, doenças e plantas daninhas...');
      
      await _pestDao.insertDefaultPests();
      await _diseaseDao.insertDefaultDiseases();
      await _weedDao.insertDefaultWeeds();
      
      Logger.info('✅ Pragas, doenças e plantas daninhas recriadas com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao recriar pragas, doenças e plantas daninhas: $e');
      rethrow;
    }
  }

  /// Verifica a integridade dos dados após a correção
  Future<void> _verifyDataIntegrity(Database db) async {
    try {
      Logger.info('🔍 Verificando integridade dos dados...');
      
      // Verificar culturas
      final crops = await db.query('crops', orderBy: 'id ASC');
      Logger.info('📊 Culturas criadas: ${crops.length}');
      for (var crop in crops) {
        Logger.info('  - ID ${crop['id']}: ${crop['name']}');
      }
      
      // Verificar pragas por cultura
      Logger.info('📊 Verificando pragas por cultura:');
      for (var crop in crops) {
        final cropId = crop['id'] as int;
        final pests = await db.query('pests', where: 'crop_id = ?', whereArgs: [cropId]);
        Logger.info('  - Cultura ${crop['name']} (ID $cropId): ${pests.length} pragas');
      }
      
      // Verificar doenças por cultura
      Logger.info('📊 Verificando doenças por cultura:');
      for (var crop in crops) {
        final cropId = crop['id'] as int;
        final diseases = await db.query('diseases', where: 'crop_id = ?', whereArgs: [cropId]);
        Logger.info('  - Cultura ${crop['name']} (ID $cropId): ${diseases.length} doenças');
      }
      
      // Verificar plantas daninhas por cultura
      Logger.info('📊 Verificando plantas daninhas por cultura:');
      for (var crop in crops) {
        final cropId = crop['id'] as int;
        final weeds = await db.query('weeds', where: 'crop_id = ?', whereArgs: [cropId]);
        Logger.info('  - Cultura ${crop['name']} (ID $cropId): ${weeds.length} plantas daninhas');
      }
      
      Logger.info('✅ Integridade verificada com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao verificar integridade: $e');
      rethrow;
    }
  }
}

/// Função principal para executar o script
Future<void> main() async {
  final fixer = FixCropIdsAlignment();
  await fixer.execute();
}

