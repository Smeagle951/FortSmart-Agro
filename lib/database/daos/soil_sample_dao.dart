import 'package:sqflite/sqflite.dart';
import '../../models/soil_sample.dart';
import '../app_database.dart';
import '../../utils/logger.dart';

/// DAO para operações de banco de dados relacionadas a amostras de solo
class SoilSampleDao {
  static final SoilSampleDao _instance = SoilSampleDao._internal();
  final AppDatabase _database = AppDatabase();
  final TaggedLogger _logger = TaggedLogger('SoilSampleDao');

  factory SoilSampleDao() {
    return _instance;
  }

  SoilSampleDao._internal();

  /// Obtém uma instância do banco de dados
  Future<Database> get database async => await _database.database;

  /// Obtém todas as amostras de solo
  Future<List<SoilSample>> getAllSamples() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('soil_samples');
      return List.generate(maps.length, (i) {
        return SoilSample.fromMap(maps[i]);
      });
    } catch (e) {
      _logger.severe('Erro ao obter todas as amostras: $e');
      return [];
    }
  }

  /// Obtém uma amostra de solo pelo ID
  Future<SoilSample?> getSampleById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'soil_samples',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return SoilSample.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      _logger.severe('Erro ao obter amostra por ID: $e');
      return null;
    }
  }

  /// Obtém amostras de solo pendentes de sincronização
  Future<List<SoilSample>> getPendingSamples() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'soil_samples',
        where: 'syncStatus = ?',
        whereArgs: [0], // 0 = pendente
      );
      return List.generate(maps.length, (i) {
        return SoilSample.fromMap(maps[i]);
      });
    } catch (e) {
      _logger.severe('Erro ao obter amostras pendentes: $e');
      return [];
    }
  }

  /// Insere uma nova amostra de solo
  Future<int> insertSample(SoilSample sample) async {
    try {
      final db = await database;
      return await db.insert('soil_samples', sample.toMap());
    } catch (e) {
      _logger.severe('Erro ao inserir amostra: $e');
      return -1;
    }
  }

  /// Atualiza uma amostra de solo
  Future<int> updateSample(SoilSample sample) async {
    try {
      final db = await database;
      return await db.update(
        'soil_samples',
        sample.toMap(),
        where: 'id = ?',
        whereArgs: [sample.id],
      );
    } catch (e) {
      _logger.severe('Erro ao atualizar amostra: $e');
      return 0;
    }
  }

  /// Exclui uma amostra de solo
  Future<int> deleteSample(String id) async {
    try {
      final db = await database;
      return await db.delete(
        'soil_samples',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      _logger.severe('Erro ao excluir amostra: $e');
      return 0;
    }
  }

  /// Marca uma amostra como sincronizada
  Future<int> markAsSynchronized(String id) async {
    try {
      final db = await database;
      return await db.update(
        'soil_samples',
        {
          'syncStatus': 1, // 1 = sincronizado
          'syncDate': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      _logger.severe('Erro ao marcar amostra como sincronizada: $e');
      return 0;
    }
  }

  /// Marca uma amostra com erro de sincronização
  Future<int> markWithSyncError(String id, String errorMessage) async {
    try {
      final db = await database;
      return await db.update(
        'soil_samples',
        {
          'syncStatus': 2, // 2 = erro
          'syncErrorMessage': errorMessage,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      _logger.severe('Erro ao marcar amostra com erro de sincronização: $e');
      return 0;
    }
  }
}
