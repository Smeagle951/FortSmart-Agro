import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

import '../utils/color_converter.dart';

import '../models/talhao_model.dart';
import '../models/safra_model.dart';
import '../models/poligono_model.dart';
import '../utils/model_converter_utils.dart';
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
        metadata TEXT
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
        FOREIGN KEY (talhao_id) REFERENCES $tableTalhoes (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Salva um talhão no banco de dados SQLite
  Future<bool> salvarTalhao(TalhaoModel talhao) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      return await db.transaction((txn) async {
        // Verificar se o talhão já existe
        final existingTalhao = await txn.query(
          tableTalhoes,
          where: 'id = ?',
          whereArgs: [talhao.id],
        );

        Map<String, dynamic> talhaoMap = {
          'id': talhao.id,
          'name': talhao.name,
          'area': talhao.area,
          'sync_status': talhao.syncStatus,
          'crop_id': talhao.cropId,
          'safra_id': talhao.safraId,
          'created_at': talhao.createdAt?.toIso8601String(),
          'updated_at': talhao.updatedAt?.toIso8601String(),
          'farm_id': talhao.fazendaId,
          'observacoes': talhao.observacoes,
          'metadata': talhao.metadados != null ? jsonEncode(talhao.metadados) : null,
        };

        // Inserir ou atualizar o talhão
        if (existingTalhao.isEmpty) {
          await txn.insert(tableTalhoes, talhaoMap);
        } else {
          await txn.update(
            tableTalhoes,
            talhaoMap,
            where: 'id = ?',
            whereArgs: [talhao.id],
          );
        }

        // Excluir polígonos existentes para recriar
        await txn.delete(
          tablePoligonos,
          where: 'talhao_id = ?',
          whereArgs: [talhao.id],
        );

        // Inserir polígonos
        for (int i = 0; i < talhao.poligonos.length; i++) {
          final poligono = talhao.poligonos[i];
          final pointsJson = poligono.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
          
          await txn.insert(tablePoligonos, {
            'talhao_id': talhao.id,
            'poligono_index': i,
            'points': jsonEncode(pointsJson),
          });
        }

        // Excluir safras existentes para recriar
        await txn.delete(
          tableSafras,
          where: 'talhao_id = ?',
          whereArgs: [talhao.id],
        );

        // Inserir safras
        for (final safra in talhao.safras) {
          await txn.insert(tableSafras, {
            'id': safra.id,
            'talhao_id': talhao.id,
            'safra': safra.safra,
            'cultura_id': safra.culturaId,
            'cultura_nome': safra.culturaNome,
            'cultura_cor': safra.culturaCor, // Já é uma string hexadecimal
            'data_criacao': safra.dataCriacao.toIso8601String(),
            'data_atualizacao': safra.dataAtualizacao.toIso8601String(),
          });
        }

        return true;
      });
    } catch (e) {
      debugPrint('Erro ao salvar talhão: $e');
      return false;
    }
  }

  /// Carrega todos os talhões do banco de dados SQLite
  Future<List<TalhaoModel>> listarTodos() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Consultar todos os talhões
      final List<Map<String, dynamic>> talhoesMaps = await db.query(tableTalhoes);
      
      if (talhoesMaps.isEmpty) {
        return [];
      }

      List<TalhaoModel> talhoes = [];
      
      for (final talhaoMap in talhoesMaps) {
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
          final String pointsJson = poligonoMap['points'];
          final List<dynamic> pointsList = jsonDecode(pointsJson);
          
          List<LatLng> pontos = pointsList.map<LatLng>((point) {
            return LatLng(
              point['lat'] as double,
              point['lng'] as double,
            );
          }).toList();
          
          pontosPoligonos.add(pontos);
          // Criar PoligonoModel para cada lista de pontos
          poligonosModels.add(ModelConverterUtils.latLngListToPoligono(pontos, talhaoId.toString()));
        }
        
        // Consultar safras do talhão
        final List<Map<String, dynamic>> safrasMaps = await db.query(
          tableSafras,
          where: 'talhao_id = ?',
          whereArgs: [talhaoId],
        );
        
        // Converter safras para o formato esperado
        List<SafraModel> safras = safrasMaps.map((safraMap) {
          final String corHex = safraMap['cultura_cor'];
          // Não precisamos converter para Color, pois o modelo espera uma String
          
                  return SafraModel(
          id: safraMap['id'],
          talhaoId: safraMap['talhao_id'].toString(),
          safra: safraMap['safra'],
          culturaId: safraMap['cultura_id'],
          culturaNome: safraMap['cultura_nome'],
          culturaCor: corHex, // Usar a string hexadecimal diretamente
          dataCriacao: DateTime.parse(safraMap['data_criacao']),
          dataAtualizacao: DateTime.parse(safraMap['data_atualizacao']),
          sincronizado: false,
          periodo: safraMap['periodo'] ?? safraMap['safra'],
          dataInicio: safraMap['data_inicio'] != null ? DateTime.parse(safraMap['data_inicio']) : DateTime.now(),
          dataFim: safraMap['data_fim'] != null ? DateTime.parse(safraMap['data_fim']) : DateTime.now().add(const Duration(days: 365)),
          ativa: safraMap['ativa'] ?? true,
          nome: safraMap['nome'] ?? safraMap['cultura_nome'],
        );
        }).toList();
        
        // Criar o modelo de talhão
        final talhao = TalhaoModel(
          id: talhaoMap['id'].toString(),
          name: talhaoMap['name'],
          poligonos: poligonosModels,
          area: talhaoMap['area'] ?? 0.0,
          fazendaId: talhaoMap['farm_id'],
          dataCriacao: talhaoMap['created_at'] != null ? DateTime.parse(talhaoMap['created_at']) : DateTime.now(),
          dataAtualizacao: talhaoMap['updated_at'] != null ? DateTime.parse(talhaoMap['updated_at']) : DateTime.now(),
          sincronizado: talhaoMap['sync_status'] == 1,
          observacoes: talhaoMap['observacoes'],
          metadados: talhaoMap['metadata'] != null ? jsonDecode(talhaoMap['metadata']) : null,
          safras: safras,
          cropId: talhaoMap['crop_id'],
          safraId: talhaoMap['safra_id'],
        );
        
        talhoes.add(talhao);
      }
      
      return talhoes;
    } catch (e) {
      debugPrint('Erro ao listar talhões: $e');
      return [];
    }
  }

  /// Busca um talhão pelo ID
  Future<TalhaoModel?> buscarPorId(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Consultar o talhão pelo ID
      final List<Map<String, dynamic>> talhoesMaps = await db.query(
        tableTalhoes,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (talhoesMaps.isEmpty) {
        return null;
      }

      final talhaoMap = talhoesMaps.first;
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
        final String pointsJson = poligonoMap['points'];
        final List<dynamic> pointsList = jsonDecode(pointsJson);
        
        List<LatLng> pontos = pointsList.map<LatLng>((point) {
          return LatLng(
            point['lat'] as double,
            point['lng'] as double,
          );
        }).toList();
        
        pontosPoligonos.add(pontos);
        // Criar PoligonoModel para cada lista de pontos
        poligonosModels.add(ModelConverterUtils.latLngListToPoligono(pontos, talhaoId.toString()));
      }
      
      // Consultar safras do talhão
      final List<Map<String, dynamic>> safrasMaps = await db.query(
        tableSafras,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
      );
      
      // Converter safras para o formato esperado
      List<SafraModel> safras = safrasMaps.map((safraMap) {
        final String corHex = safraMap['cultura_cor'];
        // Não precisamos converter para Color, pois o modelo espera uma String
        
        return SafraModel(
          id: safraMap['id'],
          talhaoId: safraMap['talhao_id'].toString(),
          safra: safraMap['safra'],
          culturaId: safraMap['cultura_id'],
          culturaNome: safraMap['cultura_nome'],
          culturaCor: corHex, // Usar a string hexadecimal diretamente
          dataCriacao: DateTime.parse(safraMap['data_criacao']),
          dataAtualizacao: DateTime.parse(safraMap['data_atualizacao']),
          sincronizado: false,
          periodo: safraMap['periodo'] ?? safraMap['safra'],
          dataInicio: safraMap['data_inicio'] != null ? DateTime.parse(safraMap['data_inicio']) : DateTime.now(),
          dataFim: safraMap['data_fim'] != null ? DateTime.parse(safraMap['data_fim']) : DateTime.now().add(const Duration(days: 365)),
          ativa: safraMap['ativa'] ?? true,
          nome: safraMap['nome'] ?? safraMap['cultura_nome'],
        );
      }).toList();
      
      // Criar o modelo de talhão
      return TalhaoModel(
        id: talhaoMap['id'].toString(),
        name: talhaoMap['name'],
        poligonos: poligonosModels,
        area: talhaoMap['area'] ?? 0.0,
        fazendaId: talhaoMap['farm_id'],
        dataCriacao: talhaoMap['created_at'] != null ? DateTime.parse(talhaoMap['created_at']) : DateTime.now(),
        dataAtualizacao: talhaoMap['updated_at'] != null ? DateTime.parse(talhaoMap['updated_at']) : DateTime.now(),
        sincronizado: talhaoMap['sync_status'] == 1,
        observacoes: talhaoMap['observacoes'],
        metadados: talhaoMap['metadata'] != null ? jsonDecode(talhaoMap['metadata']) : null,
        safras: safras,
        cropId: talhaoMap['crop_id'],
        safraId: talhaoMap['safra_id'],
      );
    } catch (e) {
      debugPrint('Erro ao buscar talhão por ID: $e');
      return null;
    }
  }

  /// Exclui um talhão pelo ID
  Future<bool> excluir(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Excluir o talhão (as safras e polígonos serão excluídos em cascata)
      await db.delete(
        tableTalhoes,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return true;
    } catch (e) {
      debugPrint('Erro ao excluir talhão: $e');
      return false;
    }
  }

  /// Marca um talhão como sincronizado
  Future<bool> marcarComoSincronizado(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      await db.update(
        tableTalhoes,
        {'sync_status': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return true;
    } catch (e) {
      debugPrint('Erro ao marcar talhão como sincronizado: $e');
      return false;
    }
  }

  /// Retorna todos os talhões não sincronizados
  Future<List<TalhaoModel>> listarNaoSincronizados() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Consultar talhões não sincronizados
      final List<Map<String, dynamic>> talhoesMaps = await db.query(
        tableTalhoes,
        where: 'sync_status = ?',
        whereArgs: [0],
      );
      
      if (talhoesMaps.isEmpty) {
        return [];
      }

      List<TalhaoModel> talhoes = [];
      
      for (final talhaoMap in talhoesMaps) {
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
          final String pointsJson = poligonoMap['points'];
          final List<dynamic> pointsList = jsonDecode(pointsJson);
          
          List<LatLng> pontos = pointsList.map<LatLng>((point) {
            return LatLng(
              point['lat'] as double,
              point['lng'] as double,
            );
          }).toList();
          
          pontosPoligonos.add(pontos);
          // Criar PoligonoModel para cada lista de pontos
          poligonosModels.add(ModelConverterUtils.latLngListToPoligono(pontos, talhaoId.toString()));
        }
        
        // Consultar safras do talhão
        final List<Map<String, dynamic>> safrasMaps = await db.query(
          tableSafras,
          where: 'talhao_id = ?',
          whereArgs: [talhaoId],
        );
        
        // Converter safras para o formato esperado
        List<SafraModel> safras = safrasMaps.map((safraMap) {
          final String corHex = safraMap['cultura_cor'];
          // Não precisamos converter para Color, pois o modelo espera uma String
          
          return SafraModel(
            id: safraMap['id'],
            talhaoId: safraMap['talhao_id'].toString(),
            safra: safraMap['safra'],
            culturaId: safraMap['cultura_id'],
            culturaNome: safraMap['cultura_nome'],
            culturaCor: corHex, // Usar a string hexadecimal diretamente
            dataCriacao: DateTime.parse(safraMap['data_criacao']),
            dataAtualizacao: DateTime.parse(safraMap['data_atualizacao']), sincronizado: false,
          );
        }).toList();
        
        // Criar o modelo de talhão
        final talhao = TalhaoModel(
          id: talhaoMap['id'],
          name: talhaoMap['name'],
          points: pontosPoligonos.isNotEmpty ? pontosPoligonos.first : [],
          area: talhaoMap['area'],
          syncStatus: talhaoMap['sync_status'],
          cropId: talhaoMap['crop_id'],
          safraId: talhaoMap['safra_id'],
          createdAt: talhaoMap['created_at'] != null ? DateTime.parse(talhaoMap['created_at']) : null,
          updatedAt: talhaoMap['updated_at'] != null ? DateTime.parse(talhaoMap['updated_at']) : null,
          poligonos: poligonosModels,
          safras: safras,
          fazendaId: talhaoMap['farm_id'],
          observacoes: talhaoMap['observacoes'],
          metadados: talhaoMap['metadata'] != null ? jsonDecode(talhaoMap['metadata']) : null, dataCriacao: DateTime.now(), dataAtualizacao: DateTime.now(), sincronizado: false,
        );
        
        talhoes.add(talhao);
      }
      
      return talhoes;
    } catch (e) {
      debugPrint('Erro ao listar talhões não sincronizados: $e');
      return [];
    }
  }
}
