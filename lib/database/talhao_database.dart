import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

import '../models/talhao_model.dart';
import '../models/safra_model.dart';
import '../models/poligono_model.dart';
import '../utils/model_converter_utils.dart';
import '../utils/logger.dart';
import 'database_helper.dart';

/// Classe responsável por gerenciar a persistência de talhões no SQLite
class TalhaoDatabase {
  static final TalhaoDatabase _instance = TalhaoDatabase._internal();
  factory TalhaoDatabase() => _instance;
  TalhaoDatabase._internal();

  static const String tableTalhoes = 'talhoes';
  static const String tableSafras = 'safras_talhao';
  static const String tablePoligonos = 'poligonos_talhao';

  /// Inicializa as tabelas de talhões no banco de dados
  Future<void> initTables(Database db) async {
    try {
      Logger.info('Inicializando tabelas do módulo talhões...');
      
      // Configurar PRAGMA para melhor performance
      await db.execute('PRAGMA foreign_keys = ON');
      await db.execute('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA synchronous = NORMAL');
      await db.execute('PRAGMA cache_size = 1000');
      await db.execute('PRAGMA temp_store = MEMORY');
      
      // Tabela de talhões
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableTalhoes (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          area REAL NOT NULL,
          sync_status INTEGER NOT NULL DEFAULT 0,
          crop_id INTEGER,
          safra_id INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          farm_id TEXT,
          observacoes TEXT,
          metadata TEXT,
          deleted_at TEXT,
          version INTEGER DEFAULT 1
        )
      ''');

      // Tabela de safras associadas aos talhões
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableSafras (
          id TEXT PRIMARY KEY,
          talhao_id INTEGER NOT NULL,
          safra TEXT NOT NULL,
          cultura_id TEXT NOT NULL,
          cultura_nome TEXT NOT NULL,
          cultura_cor TEXT NOT NULL,
          data_criacao TEXT NOT NULL,
          data_atualizacao TEXT NOT NULL,
          sincronizado INTEGER DEFAULT 0,
          deleted_at TEXT,
          FOREIGN KEY (talhao_id) REFERENCES $tableTalhoes (id) ON DELETE CASCADE
        )
      ''');

      // Tabela de polígonos dos talhões
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tablePoligonos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          talhao_id INTEGER NOT NULL,
          poligono_index INTEGER NOT NULL,
          points TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (talhao_id) REFERENCES $tableTalhoes (id) ON DELETE CASCADE
        )
      ''');
      
      // Criar índices para melhorar a performance das consultas
      await _createIndexes(db);
      
      Logger.info('Tabelas do módulo talhões inicializadas com sucesso');
    } catch (e) {
      Logger.error('Erro ao inicializar tabelas do módulo talhões: $e');
      rethrow;
    }
  }
  
  /// Cria índices para melhorar a performance das consultas
  Future<void> _createIndexes(Database db) async {
    try {
      // Índices para a tabela de talhões
      await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_farm_id ON $tableTalhoes (farm_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_sync_status ON $tableTalhoes (sync_status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_created_at ON $tableTalhoes (created_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_deleted_at ON $tableTalhoes (deleted_at)');
      
      // Índices para a tabela de safras
      await db.execute('CREATE INDEX IF NOT EXISTS idx_safras_talhao_id ON $tableSafras (talhao_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_safras_sincronizado ON $tableSafras (sincronizado)');
      
      // Índices para a tabela de polígonos
      await db.execute('CREATE INDEX IF NOT EXISTS idx_poligonos_talhao_id ON $tablePoligonos (talhao_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_poligonos_index ON $tablePoligonos (poligono_index)');
      
      Logger.info('Índices criados com sucesso');
    } catch (e) {
      Logger.error('Erro ao criar índices: $e');
    }
  }

  /// Salva um talhão no banco de dados SQLite
  Future<bool> salvarTalhao(TalhaoModel talhao) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      return await db.transaction((txn) async {
        // Verificar se o talhão já existe
        final existingTalhao = await txn.query(
          tableTalhoes,
          where: 'id = ? AND deleted_at IS NULL',
          whereArgs: [int.tryParse(talhao.id) ?? talhao.id],
        );

        final now = DateTime.now().toIso8601String();
        
        Map<String, dynamic> talhaoMap = {
          'id': int.tryParse(talhao.id) ?? talhao.id,
          'name': talhao.name,
          'area': talhao.area,
          'sync_status': talhao.syncStatus,
          'crop_id': talhao.cropId,
          'safra_id': talhao.safraId,
          'created_at': talhao.createdAt?.toIso8601String() ?? now,
          'updated_at': now,
          'farm_id': talhao.fazendaId,
          'observacoes': talhao.observacoes,
          'metadata': talhao.metadados != null ? jsonEncode(talhao.metadados) : null,
          'version': (existingTalhao.isNotEmpty ? (existingTalhao.first['version'] as int? ?? 1) : 1) + 1,
        };

        // Inserir ou atualizar o talhão
        if (existingTalhao.isEmpty) {
          await txn.insert(tableTalhoes, talhaoMap);
          Logger.info('Talhão inserido: ${talhao.name}');
        } else {
          await txn.update(
            tableTalhoes,
            talhaoMap,
            where: 'id = ?',
            whereArgs: [int.tryParse(talhao.id) ?? talhao.id],
          );
          Logger.info('Talhão atualizado: ${talhao.name}');
        }

        // Excluir polígonos existentes para recriar
        await txn.delete(
          tablePoligonos,
          where: 'talhao_id = ?',
          whereArgs: [int.tryParse(talhao.id) ?? talhao.id],
        );

        // Inserir polígonos
        for (int i = 0; i < talhao.poligonos.length; i++) {
          final poligono = talhao.poligonos[i];
          final pointsJson = poligono.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
          
          await txn.insert(tablePoligonos, {
            'talhao_id': int.tryParse(talhao.id) ?? talhao.id,
            'poligono_index': i,
            'points': jsonEncode(pointsJson),
            'created_at': now,
            'updated_at': now,
          });
        }

        // Excluir safras existentes para recriar
        await txn.delete(
          tableSafras,
          where: 'talhao_id = ?',
          whereArgs: [int.tryParse(talhao.id) ?? talhao.id],
        );

        // Inserir safras
        for (final safra in talhao.safras) {
          await txn.insert(tableSafras, {
            'id': safra.id,
            'talhao_id': int.tryParse(talhao.id) ?? talhao.id,
            'safra': safra.safra,
            'cultura_id': safra.culturaId,
            'cultura_nome': safra.culturaNome,
            'cultura_cor': safra.culturaCor,
            'data_criacao': safra.dataCriacao.toIso8601String(),
            'data_atualizacao': safra.dataAtualizacao.toIso8601String(),
            'sincronizado': safra.sincronizado ? 1 : 0,
          });
        }

        return true;
      });
    } catch (e) {
      Logger.error('Erro ao salvar talhão: $e');
      return false;
    }
  }

  /// Carrega todos os talhões do banco de dados SQLite
  Future<List<TalhaoModel>> listarTodos() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Consultar todos os talhões não deletados
      final List<Map<String, dynamic>> talhoesMaps = await db.query(
        tableTalhoes,
        where: 'deleted_at IS NULL',
        orderBy: 'created_at DESC',
      );
      
      if (talhoesMaps.isEmpty) {
        Logger.info('Nenhum talhão encontrado no banco de dados');
        return [];
      }

      List<TalhaoModel> talhoes = [];
      
      for (final talhaoMap in talhoesMaps) {
        try {
          final talhao = await _buildTalhaoModel(talhaoMap, db);
          if (talhao != null) {
            talhoes.add(talhao);
          }
        } catch (e) {
          Logger.error('Erro ao construir talhão ${talhaoMap['id']}: $e');
        }
      }
      
      Logger.info('Carregados ${talhoes.length} talhões do banco de dados');
      return talhoes;
    } catch (e) {
      Logger.error('Erro ao listar talhões: $e');
      return [];
    }
  }
  
  /// Constrói um modelo de talhão a partir dos dados do banco
  Future<TalhaoModel?> _buildTalhaoModel(Map<String, dynamic> talhaoMap, Database db) async {
    try {
      final int talhaoId = talhaoMap['id'];
      
      // Consultar polígonos do talhão
      final List<Map<String, dynamic>> poligonosMaps = await db.query(
        tablePoligonos,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'poligono_index ASC',
      );
      
      // Converter polígonos para o formato esperado
      List<List<LatLng>> pontosPoligonos = [];
      List<PoligonoModel> poligonosModels = [];
      for (final poligonoMap in poligonosMaps) {
        try {
          final String pointsJson = poligonoMap['points'];
          final List<dynamic> pointsList = jsonDecode(pointsJson);
          
          List<LatLng> pontos = pointsList.map<LatLng>((point) {
            return LatLng(
              point['lat'] as double,
              point['lng'] as double,
            );
          }).toList();
          
          pontosPoligonos.add(pontos);
          poligonosModels.add(ModelConverterUtils.latLngListToPoligono(pontos, talhaoId.toString()));
        } catch (e) {
          Logger.error('Erro ao processar polígono do talhão $talhaoId: $e');
        }
      }
      
      // Consultar safras do talhão
      final List<Map<String, dynamic>> safrasMaps = await db.query(
        tableSafras,
        where: 'talhao_id = ? AND deleted_at IS NULL',
        whereArgs: [talhaoId],
      );
      
      // Converter safras para o formato esperado
      List<SafraModel> safras = safrasMaps.map((safraMap) {
        final String corHex = safraMap['cultura_cor'];
        
        return SafraModel(
          id: safraMap['id'],
          talhaoId: safraMap['talhao_id'].toString(),
          safra: safraMap['safra'],
          culturaId: safraMap['cultura_id'],
          culturaNome: safraMap['cultura_nome'],
          culturaCor: corHex,
          dataCriacao: DateTime.parse(safraMap['data_criacao']),
          dataAtualizacao: DateTime.parse(safraMap['data_atualizacao']),
          sincronizado: safraMap['sincronizado'] == 1,
          periodo: safraMap['periodo'] ?? 'Safra ${DateTime.now().year}',
          dataInicio: DateTime.tryParse(safraMap['data_inicio'] ?? safraMap['data_criacao']) ?? DateTime.parse(safraMap['data_criacao']),
          dataFim: DateTime.tryParse(safraMap['data_fim'] ?? safraMap['data_atualizacao']) ?? DateTime.parse(safraMap['data_atualizacao']),
          ativa: safraMap['ativa'] ?? true,
          nome: safraMap['nome'] ?? safraMap['safra'] ?? 'Safra',
        );
      }).toList().cast<SafraModel>();
      
      // Criar o modelo de talhão
      return TalhaoModel(
        id: talhaoMap['id'],
        name: talhaoMap['name'],
        poligonos: poligonosModels,
        area: talhaoMap['area'],
        sincronizado: talhaoMap['sync_status'] == 1 || talhaoMap['sincronizado'] == 1,
        cropId: talhaoMap['crop_id'],
        safraId: talhaoMap['safra_id'],
        dataCriacao: talhaoMap['created_at'] != null ? DateTime.parse(talhaoMap['created_at']) : DateTime.now(),
        dataAtualizacao: talhaoMap['updated_at'] != null ? DateTime.parse(talhaoMap['updated_at']) : DateTime.now(),
        safras: safras,
        fazendaId: talhaoMap['farm_id'],
        observacoes: talhaoMap['observacoes'],
        metadados: talhaoMap['metadata'] != null ? jsonDecode(talhaoMap['metadata']) : null,
      );
    } catch (e) {
      Logger.error('Erro ao construir modelo de talhão: $e');
      return null;
    }
  }

  /// Busca um talhão pelo ID
  Future<TalhaoModel?> buscarPorId(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Consultar o talhão pelo ID
      final List<Map<String, dynamic>> talhoesMaps = await db.query(
        tableTalhoes,
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [id],
      );
      
      if (talhoesMaps.isEmpty) {
        return null;
      }

      return await _buildTalhaoModel(talhoesMaps.first, db);
    } catch (e) {
      Logger.error('Erro ao buscar talhão por ID: $e');
      return null;
    }
  }

  /// Exclui um talhão pelo ID (soft delete)
  Future<bool> excluir(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Soft delete - marcar como deletado em vez de remover fisicamente
      final result = await db.update(
        tableTalhoes,
        {
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result > 0) {
        Logger.info('Talhão marcado como deletado: $id');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Erro ao excluir talhão: $e');
      return false;
    }
  }

  /// Marca um talhão como sincronizado
  Future<bool> marcarComoSincronizado(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final result = await db.update(
        tableTalhoes,
        {
          'sync_status': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result > 0) {
        Logger.info('Talhão marcado como sincronizado: $id');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Erro ao marcar talhão como sincronizado: $e');
      return false;
    }
  }

  /// Retorna todos os talhões não sincronizados
  Future<List<TalhaoModel>> listarNaoSincronizados() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Consultar talhões não sincronizados e não deletados
      final List<Map<String, dynamic>> talhoesMaps = await db.query(
        tableTalhoes,
        where: 'sync_status = ? AND deleted_at IS NULL',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );
      
      if (talhoesMaps.isEmpty) {
        return [];
      }

      List<TalhaoModel> talhoes = [];
      
      for (final talhaoMap in talhoesMaps) {
        try {
          final talhao = await _buildTalhaoModel(talhaoMap, db);
          if (talhao != null) {
            talhoes.add(talhao);
          }
        } catch (e) {
          Logger.error('Erro ao construir talhão não sincronizado ${talhaoMap['id']}: $e');
        }
      }
      
      Logger.info('Encontrados ${talhoes.length} talhões não sincronizados');
      return talhoes;
    } catch (e) {
      Logger.error('Erro ao listar talhões não sincronizados: $e');
      return [];
    }
  }
  
  /// Busca talhões por fazenda
  Future<List<TalhaoModel>> buscarPorFazenda(String farmId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final List<Map<String, dynamic>> talhoesMaps = await db.query(
        tableTalhoes,
        where: 'farm_id = ? AND deleted_at IS NULL',
        whereArgs: [farmId],
        orderBy: 'name ASC',
      );
      
      if (talhoesMaps.isEmpty) {
        return [];
      }

      List<TalhaoModel> talhoes = [];
      
      for (final talhaoMap in talhoesMaps) {
        try {
          final talhao = await _buildTalhaoModel(talhaoMap, db);
          if (talhao != null) {
            talhoes.add(talhao);
          }
        } catch (e) {
          Logger.error('Erro ao construir talhão da fazenda ${talhaoMap['id']}: $e');
        }
      }
      
      return talhoes;
    } catch (e) {
      Logger.error('Erro ao buscar talhões por fazenda: $e');
      return [];
    }
  }
  
  /// Obtém estatísticas do banco de dados
  Future<Map<String, dynamic>> getStats() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final talhoesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableTalhoes WHERE deleted_at IS NULL')
      ) ?? 0;
      
      final naoSincronizadosCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableTalhoes WHERE sync_status = 0 AND deleted_at IS NULL')
      ) ?? 0;
      
      final safrasCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableSafras WHERE deleted_at IS NULL')
      ) ?? 0;
      
      final poligonosCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tablePoligonos')
      ) ?? 0;
      
      return {
        'totalTalhoes': talhoesCount,
        'naoSincronizados': naoSincronizadosCount,
        'totalSafras': safrasCount,
        'totalPoligonos': poligonosCount,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Erro ao obter estatísticas: $e');
      return {};
    }
  }
}
