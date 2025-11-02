import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/crop.dart' as app_crop;
import '../models/crop_model.dart' as monitoring_crop;
import '../models/talhao_model.dart';
import '../models/talhoes/talhao_safra_model.dart';
import '../models/poligono_model.dart' as poligono;
import '../repositories/talhoes/talhao_safra_repository.dart';
import '../models/cultura_model.dart';
import 'talhao_unified_service.dart';

/// Serviço para gerenciar talhões (parcelas de terra)
class TalhaoService {
  final AppDatabase _database = AppDatabase();
  final AppDatabase _databaseHelper = AppDatabase();
  final String talhoesTable = 'talhoes';
  final String poligonosTable = 'poligonos_talhao';
  final TalhaoSafraRepository _talhaoSafraRepository = TalhaoSafraRepository();
  // final CulturaRepository _culturaRepository = CulturaRepository();

  /// Garante que as tabelas necessárias existem
  Future<void> _ensureTablesExist() async {
    final db = await _database.database;
    
    // Tabela de talhões
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $talhoesTable (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        area REAL,
        fazendaId TEXT,
        fazendaNome TEXT,
        safraId TEXT,
        culturaId TEXT,
        culturaNome TEXT,
        status TEXT,
        dataCriacao TEXT,
        dataAtualizacao TEXT
      )
    ''');
    
    // Tabela de polígonos (coordenadas)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $poligonosTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        talhaoId TEXT,
        latitude REAL,
        longitude REAL,
        ordem INTEGER,
        FOREIGN KEY (talhaoId) REFERENCES $talhoesTable (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Insere um novo talhão no banco de dados
  Future<void> inserir(TalhaoModel talhao) async {
    await _ensureTablesExist();
    final db = await _database.database;
    
    await db.transaction((txn) async {
      // Insere o talhão
      await txn.insert(
        talhoesTable,
        talhao.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Insere os pontos do polígono
      if (talhao.poligonos.isNotEmpty && talhao.poligonos[0].isNotEmpty) {
        // Limpa pontos existentes
        await txn.delete(
          poligonosTable,
          where: 'talhaoId = ?',
          whereArgs: [talhao.id],
        );
        
        // Insere os novos pontos - usamos o primeiro polígono da lista
        for (int i = 0; i < talhao.poligonos[0].length; i++) {
          final ponto = talhao.poligonos[0][i];
          await txn.insert(poligonosTable, {
            'talhaoId': talhao.id,
            'latitude': ponto.latitude,
            'longitude': ponto.longitude,
            'ordem': i,
          });
        }
      }
    });
  }

  /// Atualiza um talhão existente
  Future<void> atualizar(TalhaoModel talhao) async {
    await inserir(talhao); // Usamos o mesmo método pois ele já lida com substituição
  }

  /// Exclui um talhão pelo ID
  Future<void> excluir(String id) async {
    await _ensureTablesExist();
    final db = await _database.database;
    
    await db.transaction((txn) async {
      // Exclui os pontos do polígono
      await txn.delete(
        poligonosTable,
        where: 'talhaoId = ?',
        whereArgs: [id],
      );
      
      // Exclui o talhão
      await txn.delete(
        talhoesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Obtém um talhão pelo ID
  Future<TalhaoModel?> obterPorId(String id) async {
    await _ensureTablesExist();
    final db = await _database.database;
    
    // Consulta o talhão
    final List<Map<String, dynamic>> talhoesMaps = await db.query(
      talhoesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    // Se não encontrou o talhão, tenta buscar no módulo premium
    if (talhoesMaps.isEmpty) {
      final talhoesPremium = await _carregarTalhoesPremium(id: id);
      return talhoesPremium.isNotEmpty ? talhoesPremium.first : null;
    }
    
    // Busca os pontos do polígono
    final List<Map<String, dynamic>> poligonoMaps = await db.query(
      poligonosTable,
      where: 'talhaoId = ?',
      whereArgs: [id],
      orderBy: 'ordem ASC',
    );
    
    // Converte os pontos para LatLng
    final List<LatLng> pontosLatLng = poligonoMaps.map((ponto) {
      return LatLng(ponto['latitude'] as double, ponto['longitude'] as double);
    }).toList();
    
    // Criar o modelo de polígono
    final poligonoModel = poligono.PoligonoModel(
      pontos: pontosLatLng, 
      talhaoId: id,
      id: const Uuid().v4(),
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      ativo: true,
      area: 0,
      perimetro: 0
    );
    
    // Cria o modelo de talhão com o polígono
    final talhao = TalhaoModel.fromMap(talhoesMaps.first);
    
    // Criar um polígono vazio para o talhão
    final poligonoVazio = poligono.PoligonoModel(
      id: const Uuid().v4(),
      talhaoId: talhao.id,
      pontos: [],
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      ativo: true,
      area: 0.0,
      perimetro: 0.0
    );
    return talhao.copyWith(poligonos: [poligonoVazio]);
  }

  /// Lista todos os talhões
  Future<List<TalhaoModel>> listarTodos() async {
    await _ensureTablesExist();
    final db = await _database.database;
    
    // Consulta os talhões
    final List<Map<String, dynamic>> talhoesMaps = await db.query(talhoesTable);
    
    // Se não houver talhões, retorna uma lista vazia
    if (talhoesMaps.isEmpty) {
      // Tenta carregar talhões do módulo premium
      return await _carregarTalhoesPremium();
    }
    
    // Lista para armazenar os talhões com seus polígonos
    final List<TalhaoModel> talhoes = [];
    
    // Para cada talhão, busca seus pontos e cria o modelo
    for (final talhaoMap in talhoesMaps) {
      final talhaoId = talhaoMap['id'] as String;
      
      // Consulta os pontos do polígono
      final List<Map<String, dynamic>> pontosMaps = await db.query(
        poligonosTable,
        where: 'talhaoId = ?',
        whereArgs: [talhaoId],
        orderBy: 'ordem ASC',
      );
      
      // Converte os mapas em pontos LatLng
      final List<LatLng> pontos = pontosMaps.map((map) {
        return LatLng(
          map['latitude'] as double,
          map['longitude'] as double,
        );
      }).toList();
      
      // Criar o modelo de polígono
      final poligonoModel = poligono.PoligonoModel(
        pontos: pontos, 
        talhaoId: talhaoId,
        id: const Uuid().v4(),
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: true,
        area: 0,
        perimetro: 0
      );
      
      // Cria o modelo de talhão com o polígono
      final talhao = TalhaoModel.fromMap(talhaoMap);
      talhoes.add(talhao.copyWith(poligonos: [poligonoModel]));
    }
    
    // Se não encontrou talhões no formato antigo, tenta carregar do módulo premium
    if (talhoes.isEmpty) {
      return await _carregarTalhoesPremium();
    }
    
    return talhoes;
  }

  /// Lista talhões por fazenda
  Future<List<TalhaoModel>> listarPorFazenda(String fazendaId) async {
    await _ensureTablesExist();
    final db = await _database.database;
    
    // Consulta os talhões da fazenda
    final List<Map<String, dynamic>> talhoesMaps = await db.query(
      talhoesTable,
      where: 'fazendaId = ?',
      whereArgs: [fazendaId],
    );
    
    // Se não houver talhões, tenta carregar do módulo premium
    if (talhoesMaps.isEmpty) {
      return await _carregarTalhoesPremium(idFazenda: fazendaId);
    }
    
    // Lista para armazenar os talhões com seus polígonos
    final List<TalhaoModel> talhoes = [];
    
    // Para cada talhão, busca seus pontos e cria o modelo
    for (final talhaoMap in talhoesMaps) {
      final talhaoId = talhaoMap['id'] as String;
      
      // Consulta os pontos do polígono
      final List<Map<String, dynamic>> pontosMaps = await db.query(
        poligonosTable,
        where: 'talhaoId = ?',
        whereArgs: [talhaoId],
        orderBy: 'ordem ASC',
      );
      
      // Converte os mapas em pontos LatLng
      final List<LatLng> pontos = pontosMaps.map((map) {
        return LatLng(
          map['latitude'] as double,
          map['longitude'] as double,
        );
      }).toList();
      
      // Criar o modelo de polígono
      final poligonoModel = poligono.PoligonoModel(
        pontos: pontos, 
        talhaoId: talhaoId,
        id: const Uuid().v4(),
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: true,
        area: 0,
        perimetro: 0
      );
      
      // Cria o modelo de talhão com o polígono
      final talhao = TalhaoModel.fromMap(talhaoMap);
      talhoes.add(talhao.copyWith(poligonos: [poligonoModel]));
    }
    
    // Se não encontrou talhões no formato antigo, tenta carregar do módulo premium
    if (talhoes.isEmpty) {
      return await _carregarTalhoesPremium(idFazenda: fazendaId);
    }
    
    return talhoes;
  }

  /// Lista talhões por safra
  Future<List<TalhaoModel>> listarPorSafra(String safraId) async {
    await _ensureTablesExist();
    final db = await _database.database;
    
    // Consulta os talhões da safra
    final List<Map<String, dynamic>> talhoesMaps = await db.query(
      talhoesTable,
      where: 'safraId = ?',
      whereArgs: [safraId],
    );
    
    // Se não houver talhões, tenta carregar do módulo premium
    if (talhoesMaps.isEmpty) {
      return await _carregarTalhoesPremium(idSafra: safraId);
    }
    
    // Lista para armazenar os talhões com seus polígonos
    final List<TalhaoModel> talhoes = [];
    
    // Para cada talhão, busca seus pontos e cria o modelo
    for (final talhaoMap in talhoesMaps) {
      final talhaoId = talhaoMap['id'] as String;
      
      // Consulta os pontos do polígono
      final List<Map<String, dynamic>> pontosMaps = await db.query(
        poligonosTable,
        where: 'talhaoId = ?',
        whereArgs: [talhaoId],
        orderBy: 'ordem ASC',
      );
      
      // Converte os mapas em pontos LatLng
      final List<LatLng> pontos = pontosMaps.map((map) {
        return LatLng(
          map['latitude'] as double,
          map['longitude'] as double,
        );
      }).toList();
      
      // Criar o modelo de polígono
      final poligonoModel = poligono.PoligonoModel(
        pontos: pontos, 
        talhaoId: talhaoId,
        id: const Uuid().v4(),
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: true,
        area: 0,
        perimetro: 0
      );
      
      // Cria o modelo de talhão com o polígono
      final talhao = TalhaoModel.fromMap(talhaoMap);
      talhoes.add(talhao.copyWith(poligonos: [poligonoModel]));
    }
    
    // Se não encontrou talhões no formato antigo, tenta carregar do módulo premium
    if (talhoes.isEmpty) {
      return await _carregarTalhoesPremium(idSafra: safraId);
    }
    
    return talhoes;
  }

  /// Lista talhões por cultura
  Future<List<TalhaoModel>> listarPorCultura(String culturaId) async {
    await _ensureTablesExist();
    final db = await _database.database;
    
    // Consulta os talhões da cultura
    final List<Map<String, dynamic>> talhoesMaps = await db.query(
      talhoesTable,
      where: 'culturaId = ?',
      whereArgs: [culturaId],
    );
    
    // Se não houver talhões, tenta carregar do módulo premium
    if (talhoesMaps.isEmpty) {
      return await _carregarTalhoesPremium(idCultura: culturaId);
    }
    
    // Lista para armazenar os talhões com seus polígonos
    final List<TalhaoModel> talhoes = [];
    
    // Para cada talhão, busca seus pontos e cria o modelo
    for (final talhaoMap in talhoesMaps) {
      final talhaoId = talhaoMap['id'] as String;
      
      // Consulta os pontos do polígono
      final List<Map<String, dynamic>> pontosMaps = await db.query(
        poligonosTable,
        where: 'talhaoId = ?',
        whereArgs: [talhaoId],
        orderBy: 'ordem ASC',
      );
      
      // Converte os mapas em pontos LatLng
      final List<LatLng> pontos = pontosMaps.map((map) {
        return LatLng(
          map['latitude'] as double,
          map['longitude'] as double,
        );
      }).toList();
      
      // Criar o modelo de polígono
      final poligonoModel = poligono.PoligonoModel(
        pontos: pontos, 
        talhaoId: talhaoId,
        id: const Uuid().v4(),
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: true,
        area: 0,
        perimetro: 0
      );
      
      // Cria o modelo de talhão com o polígono
      final talhao = TalhaoModel.fromMap(talhaoMap);
      talhoes.add(talhao.copyWith(poligonos: [poligonoModel]));
    }
    
    // Se não encontrou talhões no formato antigo, tenta carregar do módulo premium
    if (talhoes.isEmpty) {
      return await _carregarTalhoesPremium(idCultura: culturaId);
    }
    
    return talhoes;
  }

  /// Calcula a área total de todos os talhões
  Future<double> calcularAreaTotal() async {
    final talhoes = await listarTodos();
    double areaTotal = 0;
    
    for (final talhao in talhoes) {
      // Como o campo area não pode ser nulo, não precisamos da verificação
      areaTotal += talhao.area;
    }
    
    return areaTotal;
  }

  /// Calcula a área total dos talhões de uma fazenda
  Future<double> calcularAreaTotalPorFazenda(String fazendaId) async {
    final talhoes = await listarPorFazenda(fazendaId);
    double areaTotal = 0;
    
    for (final talhao in talhoes) {
      if (talhao.area != null) {
        areaTotal += talhao.area; // Removido operador ! redundante
      }
    }
    
    return areaTotal;
  }

  /// Calcula a área total dos talhões de uma safra
  Future<double> calcularAreaTotalPorSafra(String safraId) async {
    final talhoes = await listarPorSafra(safraId);
    double areaTotal = 0;
    
    for (final talhao in talhoes) {
      if (talhao.area != null) {
        areaTotal += talhao.area; // Removido operador ! redundante
      }
    }
    
    return areaTotal;
  }

  /// Calcula a área total dos talhões de uma cultura
  Future<double> calcularAreaTotalPorCultura(String culturaId) async {
    final talhoes = await listarPorCultura(culturaId);
    return talhoes.fold<double>(0, (total, talhao) => total + (talhao.area ?? 0));
  }
  
  /// Carrega talhões do módulo premium (TalhaoSafraModel) e converte para TalhaoModel
  /// Parâmetros opcionais permitem filtrar por id, idFazenda, idSafra ou idCultura
  Future<List<TalhaoModel>> _carregarTalhoesPremium({String? id, String? idFazenda, String? idSafra, String? idCultura}) async {
    try {
      var talhoesPremium = <TalhaoSafraModel>[];
      
      // Busca talhões de acordo com os filtros
      if (id != null) {
        // Busca por ID específico
        final talhao = await _talhaoSafraRepository.buscarTalhaoPorId(id);
        if (talhao != null) {
          talhoesPremium = [talhao];
        }
      } else if (idFazenda != null) {
        // Busca por fazenda
        talhoesPremium = await _talhaoSafraRepository.buscarTalhoesPorIdFazenda(idFazenda);
      } else if (idSafra != null) {
        // Busca por safra
        talhoesPremium = await _talhaoSafraRepository.buscarTalhoesPorSafra(idSafra);
      } else if (idCultura != null) {
        // Busca por cultura - precisamos buscar todos e filtrar
        // Como não temos acesso direto ao PerfilService, buscamos todos os talhões
        // da primeira fazenda disponível no banco
        final db = await _databaseHelper.database;
        final fazendas = await db.query('fazenda', limit: 1);
        if (fazendas.isNotEmpty) {
          final idFazenda = fazendas.first['id'] as String;
          final todosTalhoes = await _talhaoSafraRepository.buscarTalhoesPorIdFazenda(idFazenda);
          talhoesPremium = todosTalhoes.where((talhao) => 
            talhao.safras.any((safra) => safra.idCultura == idCultura)
          ).toList();
        }
      } else {
        // Busca todos os talhões da fazenda atual
        // Como não temos acesso direto ao PerfilService, buscamos todos os talhões
        // da primeira fazenda disponível no banco
        final db = await _databaseHelper.database;
        final fazendas = await db.query('fazenda', limit: 1);
        if (fazendas.isNotEmpty) {
          final idFazenda = fazendas.first['id'] as String;
          talhoesPremium = await _talhaoSafraRepository.buscarTalhoesPorIdFazenda(idFazenda);
        } else {
          talhoesPremium = [];
        }
      }
      
      // Converte TalhaoSafraModel para TalhaoModel
      List<TalhaoModel> result = [];
      for (var talhao in talhoesPremium) {
        result.add(await _converterParaTalhaoModel(talhao));
      }
      return result;
    } catch (e, stackTrace) {
      print('Erro ao carregar talhões premium: $e');
      print(stackTrace);
      return [];
    }
  }

  /// Converte um TalhaoSafraModel para TalhaoModel
  Future<TalhaoModel> _converterParaTalhaoModel(TalhaoSafraModel talhaoSafra) async {
    // Extrair a primeira safra (se existir) para obter informações de cultura
    final safra = talhaoSafra.safras.isNotEmpty ? talhaoSafra.safras.first : null;
    
    // Criar o polígono no formato esperado pelo TalhaoModel
    final List<poligono.PoligonoModel> poligonos = [];
    if (talhaoSafra.poligonos.isNotEmpty) {
      poligonos.add(poligono.PoligonoModel(
        pontos: talhaoSafra.poligonos.first.pontos, 
        talhaoId: talhaoSafra.id,
        id: const Uuid().v4(),
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: true,
        area: 0,
        perimetro: 0
      ));
    } else {
      poligonos.add(PoligonoModel(
        pontos: [], 
        talhaoId: talhaoSafra.id,
        id: const Uuid().v4(),
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: true,
        area: 0,
        perimetro: 0
      ) as poligono.PoligonoModel);
    }
    
    // Criar um crop simulado se houver informações de cultura
    monitoring_crop.Crop? monitoringCrop;
    if (safra != null && safra.idCultura != null) {
      // Criar o objeto Crop do tipo monitoring_crop.Crop sem depender do repositório
      monitoringCrop = monitoring_crop.Crop(
        id: safra.idCultura!,
        name: 'Cultura ${safra.idCultura}',
        color: const Color(0xFF4CAF50), // Cor padrão verde
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
        isPending: false,
        isSynced: true,
      );
    }
    
    // Criar o TalhaoModel
    return TalhaoModel(
      id: talhaoSafra.id,
      name: talhaoSafra.nome,
      poligonos: poligonos,
      area: talhaoSafra.safras.isNotEmpty ? talhaoSafra.safras.first.area : 0,
      fazendaId: talhaoSafra.idFazenda,
      dataCriacao: talhaoSafra.dataCriacao,
      dataAtualizacao: talhaoSafra.dataAtualizacao,
      sincronizado: talhaoSafra.sincronizado,
      observacoes: null, // Não temos este campo no modelo premium
      metadados: null, // Não temos este campo no modelo premium
      safras: [], // TalhaoModel usa outro formato de safras, não compatível diretamente
      cropId: safra != null && safra.idCultura != null ? int.tryParse(safra.idCultura!) : null,
      culturaId: safra?.idCultura,
      safraId: safra != null && safra.idSafra != null ? int.tryParse(safra.idSafra!) : null,
      crop: monitoringCrop, // Usar o crop do tipo monitoring_crop.Crop

    );
  }
  /// Calcula o perímetro de um polígono a partir de uma lista de pontos
  double _calcularPerimetro(List<LatLng> pontos) {
    if (pontos.isEmpty || pontos.length < 3) {
      return 0;
    }
    
    double perimetro = 0;
    final Distance distance = const Distance();
    
    // Somar as distâncias entre pontos consecutivos
    for (int i = 0; i < pontos.length - 1; i++) {
      perimetro += distance.as(LengthUnit.Meter, pontos[i], pontos[i + 1]);
    }
    
    // Fechar o polígono (distância do último ponto ao primeiro)
    perimetro += distance.as(LengthUnit.Meter, pontos.last, pontos.first);
    
    return perimetro;
  }

  /// Obtém todos os talhões usando o TalhaoUnifiedService
  Future<List<TalhaoModel>> getAllTalhoes() async {
    try {
      print('🔄 [TalhaoService] Carregando talhões via TalhaoUnifiedService...');
      
      // Usar o TalhaoUnifiedService que já está funcionando
      final TalhaoUnifiedService unifiedService = TalhaoUnifiedService();
      final talhoes = await unifiedService.getAllTalhoes();
      
      print('✅ [TalhaoService] ${talhoes.length} talhões carregados via TalhaoUnifiedService');
      return talhoes;
      
    } catch (e) {
      print('❌ [TalhaoService] Erro ao carregar talhões: $e');
      return [];
    }
  }

  /// Obtém estatísticas dos talhões
  Future<Map<String, dynamic>> getTalhoesStats() async {
    try {
      final talhoes = await getAllTalhoes();
      final areaTotal = await calcularAreaTotal();
      
      return {
        'total': talhoes.length,
        'active': talhoes.length, // Todos os talhões são considerados ativos
        'areaTotal': areaTotal,
      };
    } catch (e) {
      print('❌ [TalhaoService] Erro ao obter estatísticas: $e');
      return {
        'total': 0,
        'active': 0,
        'areaTotal': 0.0,
      };
    }
  }

  /// Obtém o polígono de um talhão específico
  Future<List<LatLng>?> getTalhaoPolygon(String talhaoId) async {
    try {
      await _ensureTablesExist();
      final db = await _database.database;
      
      // Busca os pontos do polígono
      final List<Map<String, dynamic>> pontosMaps = await db.query(
        poligonosTable,
        where: 'talhaoId = ?',
        whereArgs: [talhaoId],
        orderBy: 'ordem ASC',
      );
      
      if (pontosMaps.isEmpty) {
        // Tenta carregar do módulo premium
        final talhoesPremium = await _carregarTalhoesPremium();
        final talhaoPremium = talhoesPremium.where((t) => t.id == talhaoId).firstOrNull;
        
        if (talhaoPremium != null && talhaoPremium.poligonos.isNotEmpty) {
          return talhaoPremium.poligonos.first.pontos;
        }
        
        return null;
      }
      
      // Converte os mapas em pontos LatLng
      final List<LatLng> pontos = pontosMaps.map((map) {
        return LatLng(
          map['latitude'] as double,
          map['longitude'] as double,
        );
      }).toList();
      
      return pontos;
    } catch (e) {
      print('❌ Erro ao obter polígono do talhão $talhaoId: $e');
      return null;
    }
  }
}
