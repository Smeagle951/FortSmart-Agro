import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../database/fix_plantios_table.dart';
import '../models/plantio_model.dart';
import '../utils/logger.dart';
import '../utils/device_id_manager.dart';
import '../database/models/crop.dart';
import '../models/crop_variety.dart';
import 'data_cache_service.dart';
import '../services/crop_service.dart';
import '../services/talhao_service.dart';
import '../services/estoque_service.dart';
import '../services/manual_variety_service.dart';
import '../models/agricultural_product.dart';

/// Serviço para gerenciar operações relacionadas ao plantio
class PlantioService {
  final AppDatabase _appDatabase = AppDatabase();
  final String tableName = 'plantios';

  Future<Database> get database async => await _appDatabase.database;
  
  /// Corrige a estrutura da tabela plantios
  Future<void> fixTable() async {
    try {
      await FixPlantiosTable.fixTable();
      Logger.info('✅ Tabela plantios corrigida com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao corrigir tabela plantios: $e');
      rethrow;
    }
  }

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        talhaold TEXT,
        culturald TEXT,
        variedadeld TEXT,
        safrald TEXT,
        usuariold TEXT,
        descricao TEXT,
        dataPlantio TEXT,
        areaPlantada REAL,
        espacamento REAL,
        densidade REAL,
        germinacao REAL,
        pesoMedioSemente REAL,
        sementesMetro REAL,
        sementesHa REAL,
        kgHa REAL,
        sacasHa REAL,
        metodoCalibragrem TEXT,
        fonteEstoqueld TEXT,
        fonteEstoqueQuantidade REAL,
        fotos TEXT,
        dataCriacao TEXT,
        dataAtualizacao TEXT,
        created_at TEXT,
        updated_at TEXT,
        device_id TEXT,
        talhao_id TEXT,
        cultura_id TEXT,
        variedade_id TEXT,
        data_plantio TEXT,
        populacao INTEGER,
        profundidade REAL,
        maquinas_ids TEXT,
        densidade_linear REAL,
        metodo_calibragem TEXT,
        fonte_sementes_id TEXT,
        resultados TEXT,
        observacoes TEXT,
        trator_id TEXT,
        plantadeira_id TEXT,
        calibragem_id TEXT,
        estande_id TEXT,
        peso_mil_sementes REAL,
        gramas_coletadas REAL,
        distancia_percorrida REAL,
        engrenagem_motora INTEGER,
        engrenagem_movida INTEGER,
        sync_status INTEGER NOT NULL DEFAULT 0,
        remote_id TEXT
      )
    ''');
  }

  Future<int> cadastrar(PlantioModel plantio) async {
    try {
      final db = await database;
      final deviceId = await DeviceIdManager.getDeviceId();
      
      // Preparar dados para inserção
      final data = {
        ...plantio.toMap(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'device_id': deviceId,
        'sync_status': 0, // Não sincronizado
      };
      
      Logger.info('🔍 Tentando inserir plantio com dados: ${data.keys.join(', ')}');
      
      return await db.insert(tableName, data);
    } catch (e) {
      Logger.error('❌ Erro ao cadastrar plantio: $e');
      
      // Se o erro for relacionado à estrutura da tabela, tentar corrigir
      if (e.toString().contains('no column named') || 
          e.toString().contains('table plantios has no column') ||
          e.toString().contains('no such column')) {
        Logger.info('🔧 Tentando corrigir estrutura da tabela plantios...');
        try {
          await fixTable();
          
          // Tentar novamente após corrigir a tabela
          final db = await database;
          final deviceId = await DeviceIdManager.getDeviceId();
          
          final data = {
            ...plantio.toMap(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'device_id': deviceId,
            'sync_status': 0,
          };
          
          Logger.info('🔍 Tentando inserir plantio novamente após correção...');
          return await db.insert(tableName, data);
        } catch (fixError) {
          Logger.error('❌ Erro ao corrigir tabela: $fixError');
          
          // Se ainda falhar, tentar inserir apenas com campos básicos
          try {
            Logger.info('🔧 Tentando inserção com campos básicos...');
            final db = await database;
            final deviceId = await DeviceIdManager.getDeviceId();
            
            final basicData = {
              'id': plantio.id,
              'talhao_id': plantio.talhaoId,
              'cultura_id': plantio.culturaId,
              'data_plantio': plantio.dataPlantio?.toIso8601String(),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'device_id': deviceId,
              'sync_status': 0,
            };
            
            return await db.insert(tableName, basicData);
          } catch (basicError) {
            Logger.error('❌ Erro na inserção básica: $basicError');
            rethrow;
          }
        }
      }
      
      rethrow;
    }
  }

  Future<int> atualizar(PlantioModel plantio) async {
    try {
      final db = await database;
      
      final data = {
        ...plantio.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      return await db.update(
        tableName,
        data,
        where: 'id = ?',
        whereArgs: [plantio.id],
      );
    } catch (e) {
      Logger.error('Erro ao atualizar plantio: $e');
      rethrow;
    }
  }

  Future<int> deletar(String id) async {
    try {
      final db = await database;
      return await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      Logger.error('Erro ao deletar plantio: $e');
      rethrow;
    }
  }

  // Métodos de compatibilidade
  Future<List<PlantioModel>> getAllPlantios() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(tableName);
      return List.generate(maps.length, (i) => PlantioModel.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar plantios: $e');
      rethrow;
    }
  }

  Future<PlantioModel?> getPlantioById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) return null;
      return PlantioModel.fromMap(maps.first);
    } catch (e) {
      Logger.error('Erro ao buscar plantio por ID: $e');
      rethrow;
    }
  }

  Future<String> savePlantio(PlantioModel plantio) async {
    try {
      if (plantio.id?.isEmpty ?? true) {
        // Novo plantio
        final id = await cadastrar(plantio);
        return id.toString();
      } else {
        // Atualizar plantio existente
        await atualizar(plantio);
        return plantio.id!;
      }
    } catch (e) {
      Logger.error('Erro ao salvar plantio: $e');
      rethrow;
    }
  }

  Future<void> deletePlantio(String id) async {
    try {
      await deletar(id);
    } catch (e) {
      Logger.error('Erro ao deletar plantio: $e');
      rethrow;
    }
  }

  Future<PlantioModel?> buscarPorId(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return PlantioModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      Logger.error('Erro ao buscar plantio por ID: $e');
      return null;
    }
  }

  Future<List<PlantioModel>> listarTodos() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        orderBy: 'data_plantio DESC',
      );
      
      return List.generate(maps.length, (i) => PlantioModel.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao listar plantios: $e');
      return [];
    }
  }

  Future<List<PlantioModel>> buscarPorTalhao(String talhaoId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'data_plantio DESC',
      );
      
      return List.generate(maps.length, (i) => PlantioModel.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar plantios por talhão: $e');
      return [];
    }
  }

  Future<List<PlantioModel>> buscarPorCultura(String culturaId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'cultura_id = ?',
        whereArgs: [culturaId],
        orderBy: 'data_plantio DESC',
      );
      
      return List.generate(maps.length, (i) => PlantioModel.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar plantios por cultura: $e');
      return [];
    }
  }

  Future<List<PlantioModel>> buscarPorPeriodo(DateTime inicio, DateTime fim) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'data_plantio BETWEEN ? AND ?',
        whereArgs: [inicio.toIso8601String(), fim.toIso8601String()],
        orderBy: 'data_plantio DESC',
      );
      
      return List.generate(maps.length, (i) => PlantioModel.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar plantios por período: $e');
      return [];
    }
  }

  Future<List<PlantioModel>> buscarNaoSincronizados() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'sync_status = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );
      
      return List.generate(maps.length, (i) => PlantioModel.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao buscar plantios não sincronizados: $e');
      return [];
    }
  }

  Future<int> marcarComoSincronizado(String id, String remoteId) async {
    try {
      final db = await database;
      return await db.update(
        tableName,
        {
          'sync_status': 1,
          'remote_id': remoteId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      Logger.error('Erro ao marcar plantio como sincronizado: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obterEstatisticas() async {
    try {
      final db = await database;
      
      // Total de plantios
      final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM $tableName');
      final total = totalResult.first['total'] as int;
      
      // Plantios do mês atual
      final now = DateTime.now();
      final inicioMes = DateTime(now.year, now.month, 1);
      final fimMes = DateTime(now.year, now.month + 1, 0);
      
      final mesResult = await db.rawQuery(
        'SELECT COUNT(*) as total FROM $tableName WHERE data_plantio BETWEEN ? AND ?',
        [inicioMes.toIso8601String(), fimMes.toIso8601String()],
      );
      final plantiosMes = mesResult.first['total'] as int;
      
      // Área total plantada
      final areaResult = await db.rawQuery('''
        SELECT SUM(t.area) as area_total 
        FROM $tableName p 
        JOIN talhoes t ON p.talhao_id = t.id
      ''');
      final areaTotal = (areaResult.first['area_total'] as num?)?.toDouble() ?? 0.0;
      
      return {
        'total_plantios': total,
        'plantios_mes': plantiosMes,
        'area_total': areaTotal,
      };
    } catch (e) {
      Logger.error('Erro ao obter estatísticas de plantio: $e');
      return {
        'total_plantios': 0,
        'plantios_mes': 0,
        'area_total': 0.0,
      };
    }
  }

  /// Obtém o nome do talhão a partir do ID
  Future<String?> getTalhaoNome(String talhaoId) async {
    try {
      final talhoes = await getTalhoesPlantioDiponiveis();
      final talhao = talhoes.firstWhere(
        (t) => t.id == talhaoId,
        orElse: () => throw Exception('Talhão não encontrado'),
      );
      return talhao.name;
    } catch (e) {
      print('Erro ao obter nome do talhão: $e');
      return null;
    }
  }
  
  /// Obtém o nome da cultura a partir do ID
  Future<String?> getCulturaNome(String culturaId) async {
    try {
      final culturas = await getCulturas();
      final cultura = culturas.firstWhere(
        (c) => c.id.toString() == culturaId,
        orElse: () => throw Exception('Cultura não encontrada'),
      );
      return cultura.name;
    } catch (e) {
      print('Erro ao obter nome da cultura: $e');
      return null;
    }
  }
  
  /// Obtém o nome da variedade a partir do ID
  Future<String?> getVariedadeNome(String variedadeId) async {
    try {
      // Verificar se é uma variedade manual (começa com "manual_")
      if (variedadeId.startsWith('manual_')) {
        // Buscar o nome da variedade manual no serviço
        final varietyName = await ManualVarietyService.getManualVarietyName(variedadeId);
        return varietyName ?? 'Variedade Manual';
      }
      
      // Primeiro precisamos obter todas as variedades
      final db = await _appDatabase.database;
      final results = await db.query('crop_varieties');
      
      if (results.isEmpty) {
        // Se não encontrar no banco, tenta buscar de outra fonte
        final culturas = await getCulturas();
        for (final cultura in culturas) {
          final variedades = await getVariedades(cultura.id.toString());
          for (final variedade in variedades) {
            if (variedade.id == variedadeId) {
              return variedade.name;
            }
          }
        }
        return null;
      }
      
      final variedades = results.map((map) => CropVariety.fromMap(map)).toList();
      final variedade = variedades.firstWhere(
        (v) => v.id == variedadeId,
        orElse: () => throw Exception('Variedade não encontrada'),
      );
      return variedade.name;
    } catch (e) {
      print('Erro ao obter nome da variedade: $e');
      return null;
    }
  }
  
  /// Obtém as variedades de uma cultura
  Future<List<CropVariety>> getVariedades(String culturaId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        'crop_varieties',
        where: 'cropId = ?',
        whereArgs: [culturaId],
      );
      
      return results.map((map) => CropVariety.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao obter variedades: $e');
      return [];
    }
  }

  /// Carrega variedades de uma cultura
  Future<List<CropVariety>> getVariedadesByCultura(String culturaId) async {
    try {
      // TODO: Implementar busca de variedades do banco de dados
      // Por enquanto, retornar lista vazia
      return [];
    } catch (e) {
      Logger.error('Erro ao buscar variedades: $e');
      return [];
    }
  }

  /// Carrega talhões disponíveis
  Future<List<AgriculturalProduct>> getCulturas() async {
    try {
      // TODO: Implementar busca de culturas do banco de dados
      // Por enquanto, retornar lista vazia
      return [];
    } catch (e) {
      Logger.error('Erro ao buscar culturas: $e');
      rethrow;
    }
  }
  
  /// Converte um AgriculturalProduct para Crop
  Crop _convertToCrop(AgriculturalProduct product) {
    // Converter o colorValue (que é uma string hexadecimal) para um inteiro
    int colorInt = 0xFF4CAF50; // Verde padrão
    if (product.colorValue != null && product.colorValue!.isNotEmpty) {
      try {
        if (product.colorValue!.startsWith('#')) {
          colorInt = int.parse('0xFF${product.colorValue!.substring(1)}');
        } else if (product.colorValue!.startsWith('0x')) {
          colorInt = int.parse(product.colorValue!);
        } else {
          colorInt = int.parse('0xFF${product.colorValue}');
        }
      } catch (e) {
        print('Erro ao converter cor: $e');
      }
    }
    
    // Verificar se o produto é do tipo semente (seed)
    bool isSeed = product.type == ProductType.seed;
    
    return Crop(
      id: int.tryParse(product.id) ?? 0,
      name: product.name,
      description: product.notes ?? product.name, // Usando notes como descrição se disponível
      syncStatus: product.isSynced ? 1 : 0,
      remoteId: product.parentId,
    );
  }

  /// Calcula sementes por hectare com base na população desejada e germinação
  int calcularSementesHa(int populacaoDesejada, double germinacaoPercentual) {
    final germinacaoRelativa = germinacaoPercentual / 100;
    return (populacaoDesejada / germinacaoRelativa).round();
  }

  /// Calcula kg/ha com base nas sementes/ha e peso de 1000 sementes
  double calcularKgHa(int sementesHa, double pesoMilSementes) {
    return (sementesHa * pesoMilSementes) / (1000 * 1000);
  }

  /// Calcula sacas/ha com base em kg/ha (considerando sacas de 60kg)
  double calcularSacasHa(double kgHa) {
    return kgHa / 60;
  }

  /// Calcula kg/ha com base na calibragem por coleta de gramas
  double calcularKgHaColeta(double gramasColetadas, double espacamentoCm, double distanciaColetadaM) {
    return (gramasColetadas * 10000) / (espacamentoCm * distanciaColetadaM * 1000);
  }

  /// Calcula sementes por metro linear com base na população e espaçamento
  double calcularSementesPorMetroLinear(int sementesHa, double espacamentoCm) {
    // Converte espaçamento de cm para metros
    final espacamentoM = espacamentoCm / 100;
    
    // Calcula sementes por metro linear
    // Fórmula: (sementes/ha) * (espaçamento em m) / 10000
    return (sementesHa * espacamentoM) / 10000;
  }

  /// Verifica se a dose está dentro da meta (±10%)
  bool isDoseDentroMeta(double doseReal, double doseMeta) {
    final diferenca = (doseReal - doseMeta).abs();
    final percentualDiferenca = (diferenca / doseMeta) * 100;
    return percentualDiferenca <= 10;
  }

  /// Carrega talhões disponíveis para plantio
  Future<List<dynamic>> getTalhoesPlantioDiponiveis() async {
    try {
      // TODO: Implementar busca de talhões do banco de dados
      // Por enquanto, retornar lista vazia
      return [];
    } catch (e) {
      Logger.error('Erro ao buscar talhões para plantio: $e');
      return [];
    }
  }
}
