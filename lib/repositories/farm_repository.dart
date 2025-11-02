import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/farm.dart';
import '../utils/device_id_manager.dart';

class FarmRepository {
  AppDatabase? _appDatabase;
  final String tableName = 'farms';
  
  /// Obtém a instância do AppDatabase de forma lazy
  AppDatabase get appDatabase {
    _appDatabase ??= AppDatabase();
    return _appDatabase!;
  }
  
  // Flag para controlar qual implementação de banco de dados usar
  final bool _useAppDatabase = true; // Definindo para usar AppDatabase
  
  // Proteção contra loops infinitos
  bool _isInitializingTable = false;
  int _initializationAttempts = 0;
  static const int _maxInitializationAttempts = 3;

  Future<Database> get database async {
    // Usando AppDatabase para evitar problemas de "database closed"
    return await appDatabase.database;
  }

  // Obter todas as fazendas
  Future<List<Farm>> getAllFarms() async {
    try {
      // Inicializar tabela se necessário (com proteção contra loops)
      await _safeInitializeFarmsTable();
      
      final db = await database;
      
      // Primeiro tenta buscar todas as fazendas sem filtrar por device_id
      final List<Map<String, dynamic>> maps = await db.query(tableName);
      
      if (maps.isNotEmpty) {
        print('📊 ${maps.length} fazendas encontradas');
        return List.generate(maps.length, (i) {
          return _mapToFarm(maps[i]);
        });
      }
      
      // Se não encontrar nenhuma fazenda, tenta com o device_id atual
      final deviceId = await DeviceIdManager.getDeviceId();
      final List<Map<String, dynamic>> deviceMaps = await db.query(
        tableName,
        where: 'device_id = ?',
        whereArgs: [deviceId],
      );
      
      if (deviceMaps.isNotEmpty) {
        print('📊 ${deviceMaps.length} fazendas encontradas para device_id: $deviceId');
        return List.generate(deviceMaps.length, (i) {
          return _mapToFarm(deviceMaps[i]);
        });
      }
      
      print('⚠️ Nenhuma fazenda encontrada');
      return [];
    } catch (e) {
      print('❌ Erro ao buscar fazendas: $e');
      return [];
    }
  }

  // Obter uma fazenda pelo ID
  Future<Farm?> getFarmById(dynamic id) async {
    try {
      final db = await database;
      
      // Converter o ID para string se for um número
      final String idStr = id is int ? id.toString() : id;
      
      // Buscar a fazenda apenas pelo ID, sem filtrar por device_id
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [idStr],
      );
      
      if (maps.isNotEmpty) {
        print('Fazenda encontrada com ID: $idStr');
        return _mapToFarm(maps.first);
      }
      
      print('Fazenda não encontrada com ID: $idStr');
      return null;
    } catch (e) {
      print('Erro ao buscar fazenda por ID: $e');
      return null;
    }
  }

  // Adicionar uma nova fazenda
  Future<String> addFarm(Farm farm) async {
    try {
      // Inicializar tabela se necessário (com proteção contra loops)
      await _safeInitializeFarmsTable();
      
      final db = await database;
      final deviceId = await DeviceIdManager.getDeviceId();
      
      final farmMap = _farmToMap(farm);
      farmMap['device_id'] = deviceId;
      
      print('💾 Salvando fazenda: ${farm.name}');
      
      final id = await db.insert(tableName, farmMap);
      print('✅ Fazenda salva com ID: $id');
      return id.toString();
    } catch (e) {
      print('❌ Erro ao adicionar fazenda: $e');
      rethrow;
    }
  }

  // Atualizar uma fazenda existente
  Future<bool> updateFarm(Farm farm) async {
    try {
      print('🔄 Iniciando atualização da fazenda: ${farm.name}');
      print('📊 ID da fazenda: ${farm.id}');
      
      final db = await database;
      print('✅ Banco de dados conectado');
      
      // Verificar se a fazenda existe antes de atualizar
      final existingFarm = await getFarmById(farm.id);
      if (existingFarm == null) {
        print('❌ Fazenda não encontrada para atualização: ${farm.id}');
        return false;
      }
      print('✅ Fazenda encontrada para atualização');
      
      final farmMap = _farmToMap(farm);
      print('📊 Dados convertidos para mapa: ${farmMap.keys.toList()}');
      
      print('🔄 Executando update no banco...');
      final count = await db.update(
        tableName,
        farmMap,
        where: 'id = ?',
        whereArgs: [farm.id],
      );
      
      print('✅ Fazenda atualizada com sucesso. Registros afetados: $count');
      
      if (count > 0) {
        print('✅ Atualização bem-sucedida');
        return true;
      } else {
        print('⚠️ Nenhum registro foi atualizado');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao atualizar fazenda: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Excluir uma fazenda
  Future<bool> deleteFarm(String id) async {
    try {
      final db = await database;
      
      print('🗑️ Excluindo fazenda com ID: $id');
      
      final count = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('✅ Fazenda excluída. Registros afetados: $count');
      return count > 0;
    } catch (e) {
      print('❌ Erro ao excluir fazenda: $e');
      return false;
    }
  }

  // Alias para deleteFarm para compatibilidade
  Future<bool> removeFarm(String id) async {
    return await deleteFarm(id);
  }

  // Verificar se uma fazenda existe
  Future<bool> farmExists(String id) async {
    final farm = await getFarmById(id);
    return farm != null;
  }

  // Verificar se a tabela farms existe e tem dados
  Future<bool> checkFarmsTable() async {
    try {
      final db = await database;
      
      // Verificar se a tabela existe
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', tableName],
      );
      
      if (tables.isEmpty) {
        print('❌ Tabela farms não existe');
        return false;
      }
      
      // Verificar se há dados na tabela
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      final farmCount = count.first['count'] as int;
      
      print('📊 Tabela farms existe com $farmCount registros');
      return farmCount > 0;
    } catch (e) {
      print('❌ Erro ao verificar tabela farms: $e');
      return false;
    }
  }

  // Inicializar tabela farms se necessário (COM PROTEÇÃO CONTRA LOOPS)
  Future<void> _safeInitializeFarmsTable() async {
    // Proteção contra loops infinitos
    if (_isInitializingTable) {
      print('⚠️ Inicialização da tabela farms já em andamento. Aguardando...');
      return;
    }
    
    if (_initializationAttempts >= _maxInitializationAttempts) {
      print('❌ MÁXIMO DE TENTATIVAS DE INICIALIZAÇÃO DA TABELA FARMS ATINGIDO');
      return;
    }
    
    try {
      _isInitializingTable = true;
      _initializationAttempts++;
      
      print('🏗️ Inicializando tabela farms... (tentativa $_initializationAttempts)');
      
      final db = await database;
      print('✅ Banco de dados conectado');
      
      // Verificar se a tabela existe
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', tableName],
      );
      
      if (tables.isEmpty) {
        print('📋 Tabela farms não existe. Criando...');
        
        // Criar tabela se não existir
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableName (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            logo_url TEXT,
            responsible_person TEXT,
            document_number TEXT,
            phone TEXT,
            email TEXT,
            address TEXT NOT NULL,
            total_area REAL NOT NULL,
            plots_count INTEGER NOT NULL,
            crops TEXT NOT NULL,
            cultivation_system TEXT,
            has_irrigation INTEGER NOT NULL,
            irrigation_type TEXT,
            mechanization_level TEXT,
            technical_responsible_name TEXT,
            technical_responsible_id TEXT,
            documents TEXT,
            is_verified INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1,
            latitude REAL,
            longitude REAL,
            property_id INTEGER DEFAULT 1,
            owner_name TEXT,
            municipality TEXT,
            state TEXT,
            website TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            device_id TEXT
          )
        ''');
        
        print('✅ Tabela farms criada com sucesso');
      } else {
        print('✅ Tabela farms já existe');
      }
      
      // Verificar se há dados na tabela
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      final farmCount = count.first['count'] as int;
      
      print('📊 Tabela farms verificada com $farmCount registros');
      
    } catch (e) {
      print('❌ Erro ao inicializar tabela farms: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    } finally {
      _isInitializingTable = false;
    }
  }

  // Método público para inicializar tabela (mantém compatibilidade)
  Future<void> initializeFarmsTable() async {
    await _safeInitializeFarmsTable();
  }
  
  // Alias para getAllFarms para compatibilidade com código existente
  Future<List<Farm>> getFarms() async {
    return await getAllFarms();
  }

  // Converter um mapa para um objeto Farm
  Farm _mapToFarm(Map<String, dynamic> map) {
    try {
      return Farm(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        logoUrl: map['logo_url'],
        responsiblePerson: map['responsible_person'],
        documentNumber: map['document_number'],
        phone: map['phone'],
        email: map['email'],
        address: map['address'] ?? '',
        totalArea: (map['total_area'] ?? 0.0).toDouble(),
        plotsCount: map['plots_count'] ?? 0,
        crops: _parseCrops(map['crops']),
        cultivationSystem: map['cultivation_system'],
        hasIrrigation: map['has_irrigation'] == 1,
        irrigationType: map['irrigation_type'],
        mechanizationLevel: map['mechanization_level'],
        technicalResponsibleName: map['technical_responsible_name'],
        technicalResponsibleId: map['technical_responsible_id'],
        documents: _parseDocuments(map['documents']),
        plots: [], // Será carregado separadamente se necessário
        isVerified: map['is_verified'] == 1,
        isActive: map['is_active'] == 1,
        latitude: map['latitude']?.toDouble(),
        longitude: map['longitude']?.toDouble(),
        propertyId: map['property_id'] ?? 1,
        ownerName: map['owner_name'] ?? map['responsible_person'],
        municipality: map['municipality'],
        state: map['state'],
        website: map['website'],
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      print('❌ Erro ao converter mapa para Farm: $e');
      print('📊 Dados do mapa: $map');
      rethrow;
    }
  }

  // Parse seguro de culturas
  List<String> _parseCrops(dynamic crops) {
    if (crops == null) return ['Soja', 'Milho'];
    
    try {
      if (crops is String) {
        final List<dynamic> parsed = jsonDecode(crops);
        return parsed.map<String>((e) => e.toString()).toList();
      } else if (crops is List) {
        return crops.map<String>((e) => e.toString()).toList();
      }
    } catch (e) {
      print('❌ Erro ao fazer parse de culturas: $e');
    }
    
    return ['Soja', 'Milho'];
  }

  // Parse seguro de documentos
  List<FarmDocument> _parseDocuments(dynamic documents) {
    if (documents == null) return [];
    
    try {
      if (documents is String) {
        final List<dynamic> parsed = jsonDecode(documents);
        return parsed.map<FarmDocument>((x) => FarmDocument.fromMap(x)).toList();
      } else if (documents is List) {
        return documents.map<FarmDocument>((x) => FarmDocument.fromMap(x)).toList();
      }
    } catch (e) {
      print('❌ Erro ao fazer parse de documentos: $e');
    }
    
    return [];
  }

  // Converter um objeto Farm para um mapa
  Map<String, dynamic> _farmToMap(Farm farm) {
    try {
      print('🔄 Convertendo Farm para mapa...');
      
      // Validar dados obrigatórios
      if (farm.name.isEmpty) {
        throw Exception('Nome da fazenda é obrigatório');
      }
      
      if (farm.address.isEmpty) {
        throw Exception('Endereço da fazenda é obrigatório');
      }
      
      // Permitir área zero para fazendas recém-criadas
      // if (farm.totalArea <= 0) {
      //   throw Exception('Área total deve ser maior que zero');
      // }
      
      if (farm.plotsCount < 0) {
        throw Exception('Número de talhões não pode ser negativo');
      }
      
      final farmMap = {
        'id': farm.id,
        'name': farm.name.trim(),
        'logo_url': farm.logoUrl,
        'responsible_person': farm.responsiblePerson?.trim(),
        'document_number': farm.documentNumber?.trim(),
        'phone': farm.phone?.trim(),
        'email': farm.email?.trim(),
        'address': farm.address.trim(),
        'total_area': farm.totalArea,
        'plots_count': farm.plotsCount,
        'crops': jsonEncode(farm.crops.isNotEmpty ? farm.crops : ['Soja']),
        'cultivation_system': farm.cultivationSystem?.trim(),
        'has_irrigation': farm.hasIrrigation ? 1 : 0,
        'irrigation_type': farm.irrigationType?.trim(),
        'mechanization_level': farm.mechanizationLevel?.trim(),
        'technical_responsible_name': farm.technicalResponsibleName?.trim(),
        'technical_responsible_id': farm.technicalResponsibleId?.trim(),
        'documents': jsonEncode(farm.documents.map((x) => x.toMap()).toList()),
        'is_verified': farm.isVerified ? 1 : 0,
        'is_active': farm.isActive ? 1 : 0,
        'latitude': farm.latitude,
        'longitude': farm.longitude,
        'property_id': farm.propertyId,
        'owner_name': farm.ownerName?.trim(),
        'municipality': farm.municipality?.trim(),
        'state': farm.state?.trim(),
        'website': farm.website?.trim(),
        'created_at': farm.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(), // Sempre atualizar
      };
      
      print('✅ Farm convertido para mapa com sucesso');
      return farmMap;
    } catch (e) {
      print('❌ Erro ao converter Farm para mapa: $e');
      print('📊 Dados da fazenda:');
      print('  - ID: ${farm.id}');
      print('  - Nome: ${farm.name}');
      print('  - Endereço: ${farm.address}');
      print('  - Área: ${farm.totalArea}');
      print('  - Talhões: ${farm.plotsCount}');
      rethrow;
    }
  }

  listarTodos() {}
}
