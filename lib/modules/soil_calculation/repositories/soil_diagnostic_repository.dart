import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../models/soil_diagnostic_model.dart';
import '../../../services/database_service.dart';

/// Repositório para gerenciar diagnósticos agronômicos do solo
class SoilDiagnosticRepository extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  /// Inicializa a tabela de diagnósticos
  Future<void> initTable() async {
    final db = await _databaseService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS solo_diagnosticos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        point_id INTEGER NOT NULL,
        tipo_diagnostico TEXT NOT NULL,
        severidade TEXT NOT NULL,
        especie_identificada TEXT,
        profundidade_afetada REAL,
        cultura_impactada TEXT,
        data_identificacao TEXT NOT NULL,
        metodologia_avaliacao TEXT,
        dados_laboratoriais TEXT,
        observacoes TEXT,
        fotos_path TEXT,
        recomendacoes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (point_id) REFERENCES compactacao_pontos(id) ON DELETE CASCADE
      )
    ''');
    
    // Criar índices
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_diagnostico_ponto ON solo_diagnosticos(point_id)'
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_diagnostico_tipo ON solo_diagnosticos(tipo_diagnostico)'
    );
  }

  /// Insere um novo diagnóstico
  Future<int> insert(SoilDiagnosticModel diagnostico) async {
    try {
      await initTable();
      final db = await _databaseService.database;
      final id = await db.insert(
        'solo_diagnosticos',
        diagnostico.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      notifyListeners();
      if (kDebugMode) {
        print('✅ Diagnóstico inserido com ID: $id');
      }
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inserir diagnóstico: $e');
      }
      return -1;
    }
  }

  /// Atualiza um diagnóstico existente
  Future<int> update(SoilDiagnosticModel diagnostico) async {
    try {
      final db = await _databaseService.database;
      final result = await db.update(
        'solo_diagnosticos',
        diagnostico.toMap(),
        where: 'id = ?',
        whereArgs: [diagnostico.id],
      );
      notifyListeners();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao atualizar diagnóstico: $e');
      }
      return -1;
    }
  }

  /// Exclui um diagnóstico
  Future<int> delete(int id) async {
    try {
      final db = await _databaseService.database;
      final result = await db.delete(
        'solo_diagnosticos',
        where: 'id = ?',
        whereArgs: [id],
      );
      notifyListeners();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao excluir diagnóstico: $e');
      }
      return -1;
    }
  }

  /// Busca todos os diagnósticos
  Future<List<SoilDiagnosticModel>> getAll() async {
    try {
      await initTable();
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'solo_diagnosticos',
        orderBy: 'data_identificacao DESC',
      );
      return List.generate(maps.length, (i) {
        return SoilDiagnosticModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar diagnósticos: $e');
      }
      return [];
    }
  }

  /// Busca diagnósticos por ponto de coleta
  Future<List<SoilDiagnosticModel>> getByPoint(int pointId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'solo_diagnosticos',
        where: 'point_id = ?',
        whereArgs: [pointId],
        orderBy: 'data_identificacao DESC',
      );
      return List.generate(maps.length, (i) {
        return SoilDiagnosticModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar diagnósticos por ponto: $e');
      }
      return [];
    }
  }

  /// Busca diagnósticos por tipo
  Future<List<SoilDiagnosticModel>> getByTipo(String tipo) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'solo_diagnosticos',
        where: 'tipo_diagnostico = ?',
        whereArgs: [tipo],
        orderBy: 'data_identificacao DESC',
      );
      return List.generate(maps.length, (i) {
        return SoilDiagnosticModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar diagnósticos por tipo: $e');
      }
      return [];
    }
  }

  /// Busca diagnósticos críticos (alta severidade)
  Future<List<SoilDiagnosticModel>> getCriticos() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'solo_diagnosticos',
        where: 'severidade IN (?, ?)',
        whereArgs: ['Alta', 'Crítica'],
        orderBy: 'data_identificacao DESC',
      );
      return List.generate(maps.length, (i) {
        return SoilDiagnosticModel.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar diagnósticos críticos: $e');
      }
      return [];
    }
  }

  /// Conta diagnósticos por tipo
  Future<Map<String, int>> contarPorTipo() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('''
        SELECT tipo_diagnostico, COUNT(*) as total 
        FROM solo_diagnosticos 
        GROUP BY tipo_diagnostico
      ''');
      
      Map<String, int> contagem = {};
      for (var row in result) {
        contagem[row['tipo_diagnostico'] as String] = row['total'] as int;
      }
      return contagem;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao contar diagnósticos: $e');
      }
      return {};
    }
  }
}

