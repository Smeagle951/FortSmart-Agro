import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/experiment.dart';
import '../utils/logger.dart';

class ExperimentRepository {
  final TaggedLogger _logger = TaggedLogger('ExperimentRepository');
  final AppDatabase _database = AppDatabase();
  final Uuid _uuid = Uuid();
  
  Future<List<Experiment>> getAllExperiments() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query('experiments');
      
      return List.generate(maps.length, (i) {
        return Experiment.fromMap(maps[i]);
      });
    } catch (e) {
      _logger.error('Erro ao buscar experimentos: $e');
      return [];
    }
  }
  
  Future<List<Experiment>> getExperimentsByPlot(String plotId) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'experiments',
        where: 'plot_id = ?',
        whereArgs: [plotId],
      );
      
      return List.generate(maps.length, (i) {
        return Experiment.fromMap(maps[i]);
      });
    } catch (e) {
      _logger.error('Erro ao buscar experimentos por talhão: $e');
      return [];
    }
  }
  
  Future<List<Experiment>> getExperimentsByCropType(String cropType) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'experiments',
        where: 'crop_type = ?',
        whereArgs: [cropType],
      );
      
      return List.generate(maps.length, (i) {
        return Experiment.fromMap(maps[i]);
      });
    } catch (e) {
      _logger.error('Erro ao buscar experimentos por cultura: $e');
      return [];
    }
  }
  
  Future<Experiment?> getExperimentById(String id) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'experiments',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return Experiment.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      _logger.error('Erro ao buscar experimento por ID: $e');
      return null;
    }
  }
  
  Future<bool> saveExperiment(Experiment experiment) async {
    try {
      final db = await _database.database;
      
      // Verifica se é um novo experimento ou atualização
      final experimentToSave = experiment.id == null ? 
        experiment.copyWith(
          id: _uuid.v4(),
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ) : 
        experiment.copyWith(
          updatedAt: DateTime.now().toIso8601String(),
        );
      
      if (experiment.id == null) {
        // Inserir novo
        await db.insert(
          'experiments',
          experimentToSave.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        // Atualizar existente
        await db.update(
          'experiments',
          experimentToSave.toMap(),
          where: 'id = ?',
          whereArgs: [experimentToSave.id],
        );
      }
      
      return true;
    } catch (e) {
      _logger.error('Erro ao salvar experimento: $e');
      return false;
    }
  }
  
  Future<bool> deleteExperiment(String id) async {
    try {
      final db = await _database.database;
      
      await db.delete(
        'experiments',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return true;
    } catch (e) {
      _logger.error('Erro ao excluir experimento: $e');
      return false;
    }
  }
  
  // Métodos específicos para dashboard
  
  Future<List<Experiment>> getActiveExperiments() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'experiments',
        where: 'status = ?',
        whereArgs: ['active'],
      );
      
      return List.generate(maps.length, (i) {
        return Experiment.fromMap(maps[i]);
      });
    } catch (e) {
      _logger.error('Erro ao buscar experimentos ativos: $e');
      return [];
    }
  }
  
  Future<Map<String, int>> getExperimentCountByCrop() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT crop_type, COUNT(*) as count
        FROM experiments
        GROUP BY crop_type
      ''');
      
      final Map<String, int> counts = {};
      for (var row in result) {
        counts[row['crop_type'] as String] = row['count'] as int;
      }
      
      return counts;
    } catch (e) {
      _logger.error('Erro ao obter contagem de experimentos por cultura: $e');
      return {};
    }
  }
  
  Future<Map<String, int>> getExperimentCountByStatus() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT status, COUNT(*) as count
        FROM experiments
        GROUP BY status
      ''');
      
      final Map<String, int> counts = {};
      for (var row in result) {
        counts[row['status'] as String] = row['count'] as int;
      }
      
      return counts;
    } catch (e) {
      _logger.error('Erro ao obter contagem de experimentos por status: $e');
      return {};
    }
  }
}
