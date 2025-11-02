import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/daos/plot_dao.dart';
import '../models/plot.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class PlotRepository {
  final PlotDao _plotDao = PlotDao();
  final _uuid = const Uuid();

  /// Obtém todos os talhões
  Future<List<Plot>> getAll() async {
    try {
      debugPrint('PlotRepository: Obtendo todos os talhões');
      return await _plotDao.getAll();
    } catch (e) {
      debugPrint('PlotRepository: Erro ao obter todos os talhões: $e');
      return [];
    }
  }

  /// Alias para getAll() - usado em outras partes do código
  Future<List<Plot>> getAllPlots() async {
    return getAll();
  }
  
  /// Método getPlots para compatibilidade com DataCacheService
  Future<List<Plot>> getPlots() async {
    return getAll();
  }

  /// Obtém um talhão pelo ID
  Future<Plot?> getById(dynamic id) async {
    try {
      debugPrint('PlotRepository: Obtendo talhão por ID: $id');
      
      // Converte o ID para String se necessário
      final String plotId = id is int ? id.toString() : id.toString();
      
      return await _plotDao.getById(plotId);
    } catch (e) {
      debugPrint('PlotRepository: Erro ao obter talhão por ID: $e');
      return null;
    }
  }

  /// Alias para getById() - usado em outras partes do código
  Future<Plot?> getPlotById(dynamic id) async {
    return getById(id);
  }

  /// Obtém todos os talhões de uma propriedade
  Future<List<Plot>> getPlotsByFarmId(dynamic propertyId) async {
    try {
      debugPrint('PlotRepository: Obtendo talhões por propriedade: $propertyId');
      
      // Converte o ID para int se necessário
      final int farmId = propertyId is String ? int.parse(propertyId) : propertyId as int;
      
      return await _plotDao.getByPropertyId(farmId);
    } catch (e) {
      debugPrint('PlotRepository: Erro ao obter talhões por propriedade: $e');
      return [];
    }
  }

  /// Obtém talhões por fazenda
  Future<List<Plot>> getByFarmId(dynamic farmId) async {
    try {
      debugPrint('PlotRepository: Obtendo talhões por fazenda: $farmId');
      
      // Converte o ID para int se necessário
      final int fId = farmId is String ? int.tryParse(farmId) ?? 0 : farmId as int;
      
      return await _plotDao.getByFarmId(fId);
    } catch (e) {
      debugPrint('PlotRepository: Erro ao obter talhões por fazenda: $e');
      return [];
    }
  }

  /// Alias para getByFarmId() - usado em outras partes do código
  Future<List<Plot>> getPlotsByFarm(dynamic farmId) async {
    return getByFarmId(farmId);
  }

  /// Salva um novo talhão
  Future<String?> save(Plot plot) async {
    try {
      debugPrint('PlotRepository: Salvando talhão: ${plot.name}');
      
      // Valida os dados do talhão
      if (plot.name.isEmpty) {
        debugPrint('PlotRepository: Nome do talhão não pode ser vazio');
        return null;
      }
      
      // Gera um ID se não existir
      final plotToSave = plot.id == null ? 
        plot.copyWith(
          id: _uuid.v4(),
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ) : 
        plot.copyWith(
          updatedAt: DateTime.now().toIso8601String(),
        );
      
      // Converte coordenadas para JSON em formato GeoJSON válido
      String? polygonJson = plotToSave.polygonJson;
      if (polygonJson == null && plotToSave.coordinates != null && plotToSave.coordinates!.isNotEmpty) {
        // Formata as coordenadas para GeoJSON (longitude, latitude)
        final List<List<double>> formattedCoords = plotToSave.coordinates!.map((coord) => [
          coord['longitude'] ?? 0.0,
          coord['latitude'] ?? 0.0
        ]).toList();
        
        // Adiciona o primeiro ponto novamente ao final para fechar o polígono
        if (formattedCoords.isNotEmpty) {
          formattedCoords.add(formattedCoords.first);
        }
        
        // Criar estrutura GeoJSON válida
        polygonJson = jsonEncode({
          'type': 'Polygon',
          'coordinates': [formattedCoords]
        });
        
        debugPrint('PlotRepository: Polygon JSON gerado: $polygonJson');
      }
      
      final finalPlot = plotToSave.copyWith(polygonJson: polygonJson);
      
      // Salva no banco de dados
      final result = await _plotDao.insert(finalPlot);
      debugPrint('PlotRepository: Resultado do salvamento: $result');
      return result;
    } catch (e) {
      debugPrint('PlotRepository: Erro ao salvar talhão: $e');
      rethrow; // Relançar exceção para mostrar o erro real na UI
    }
  }

  /// Alias para save() - usado em outras partes do código
  Future<String?> savePlot(Plot plot) async {
    return save(plot);
  }

  /// Alias para save() - usado em outras partes do código
  Future<String?> addPlot(Plot plot) async {
    return save(plot);
  }

  /// Insere um novo talhão (alias para save)
  Future<String?> insertPlot(Plot plot) async {
    return save(plot);
  }

  /// Atualiza um talhão existente
  Future<bool> update(Plot plot) async {
    try {
      debugPrint('PlotRepository: Atualizando talhão: ${plot.id}');
      
      // Valida os dados do talhão
      if (plot.id == null || plot.name.isEmpty) {
        debugPrint('PlotRepository: ID ou nome do talhão inválido');
        return false;
      }
      
      // Atualiza a data de modificação
      final plotToUpdate = plot.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      // Converte coordenadas para JSON se necessário
      String? polygonJson = plotToUpdate.polygonJson;
      if (polygonJson == null && plotToUpdate.coordinates != null) {
        polygonJson = jsonEncode(plotToUpdate.coordinates);
      }
      
      final finalPlot = plotToUpdate.copyWith(polygonJson: polygonJson);
      
      // Atualiza no banco de dados
      return await _plotDao.update(finalPlot);
    } catch (e) {
      debugPrint('PlotRepository: Erro ao atualizar talhão: $e');
      return false;
    }
  }

  /// Alias para update() - usado em outras partes do código
  Future<bool> updatePlot(Plot plot) async {
    return update(plot);
  }

  /// Exclui um talhão pelo ID
  Future<bool> delete(dynamic id) async {
    try {
      debugPrint('PlotRepository: Excluindo talhão: $id');
      
      // Converte o ID para String se necessário
      final String plotId = id is int ? id.toString() : id.toString();
      
      return await _plotDao.delete(plotId);
    } catch (e) {
      debugPrint('PlotRepository: Erro ao excluir talhão: $e');
      return false;
    }
  }

  /// Alias para delete() - usado em outras partes do código
  Future<bool> deletePlot(dynamic id) async {
    return delete(id);
  }

  /// Cria as tabelas necessárias para o funcionamento do repositório
  Future<void> createTables(Database db) async {
    try {
      debugPrint('PlotRepository: Criando tabelas');
      
      // Criar tabela de talhões
      await db.execute('''
        CREATE TABLE IF NOT EXISTS plots (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          farmId INTEGER NOT NULL,
          area REAL,
          description TEXT,
          boundaryPoints TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          syncStatus INTEGER DEFAULT 0,
          serverId TEXT,
          status TEXT DEFAULT 'normal'
        )
      ''');
      
      // Criar índices
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plots_farm_id ON plots (farmId)');
      
      debugPrint('PlotRepository: Tabelas criadas com sucesso');
    } catch (e) {
      debugPrint('PlotRepository: Erro ao criar tabelas: $e');
      rethrow;
    }
  }
  
  /// Atualiza os status dos talhões a partir dos dados da API
  Future<bool> updatePlotStatuses(List<dynamic> plotStatusesData) async {
    try {
      debugPrint('PlotRepository: Atualizando status de ${plotStatusesData.length} talhões');
      
      final db = await _plotDao.getDatabase();
      await db.transaction((txn) async {
        // Primeiro, resetamos os status de todos os talhões para o padrão
        await txn.update(
          'plots',
          {'status': 'normal', 'updatedAt': DateTime.now().toIso8601String()},
        );
        
        // Depois atualizamos com os novos status recebidos da API
        for (final statusData in plotStatusesData) {
          final String plotId = statusData['plot_id'];
          final String status = statusData['status'] ?? 'normal';
          
          await txn.update(
            'plots',
            {
              'status': status,
              'updatedAt': DateTime.now().toIso8601String(),
              'syncStatus': 1,
            },
            where: 'id = ? OR serverId = ?',
            whereArgs: [plotId, plotId],
          );
        }
      });
      
      return true;
    } catch (e) {
      debugPrint('PlotRepository: Erro ao atualizar status dos talhões: $e');
      return false;
    }
  }
}
