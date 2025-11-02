import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço para validar e garantir que culturas existam antes de salvar variedades
class CropValidationService {
  static const String _tag = 'CropValidationService';
  final AppDatabase _appDatabase = AppDatabase();

  /// Garante que uma cultura existe na tabela crops
  /// Se não existir, cria automaticamente
  Future<int> ensureCropExists(String cropId, String cropName) async {
    try {
      Logger.info('$_tag: Verificando se cultura existe: $cropId ($cropName)');
      
      final db = await _appDatabase.database;
      
      // Verificar se a cultura já existe pelo nome primeiro
      final existingCrops = await db.query(
        'crops',
        where: 'name = ?',
        whereArgs: [cropName],
        limit: 1,
      );
      
      if (existingCrops.isNotEmpty) {
        final existingId = existingCrops.first['id'] as int;
        Logger.info('$_tag: Cultura já existe com ID: $existingId');
        
        // Verificar se o ID realmente existe na tabela
        final verifyCrop = await db.query(
          'crops',
          where: 'id = ?',
          whereArgs: [existingId],
          limit: 1,
        );
        
        if (verifyCrop.isEmpty) {
          Logger.warning('$_tag: ID $existingId não existe na tabela crops, criando nova cultura...');
          // Continuar para criar nova cultura
        } else {
          return existingId;
        }
      }
      
      // Criar nova cultura
      Logger.info('$_tag: Criando nova cultura: $cropName');
      final newCropId = await db.insert('crops', {
        'name': cropName,
        'scientific_name': _getScientificName(cropName),
        'family': _getFamily(cropName),
        'description': 'Cultura criada automaticamente para variedades',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 0,
      });
      
      if (newCropId == null || newCropId <= 0) {
        throw Exception('Falha ao criar cultura: ID inválido retornado');
      }
      
      Logger.info('$_tag: Cultura criada com ID: $newCropId');
      return newCropId;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao garantir cultura: $e');
      rethrow;
    }
  }

  /// Garante que a tabela crops existe
  Future<void> ensureCropsTableExists() async {
    try {
      final db = await _appDatabase.database;
      
      // Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='crops'"
      );
      
      if (tables.isEmpty) {
        Logger.info('$_tag: Criando tabela crops...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS crops (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            scientific_name TEXT,
            family TEXT,
            description TEXT,
            image_url TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status INTEGER NOT NULL DEFAULT 0,
            remote_id INTEGER
          )
        ''');
        Logger.info('$_tag: Tabela crops criada com sucesso');
      }
    } catch (e) {
      Logger.error('$_tag: Erro ao criar tabela crops: $e');
      rethrow;
    }
  }

  /// Obtém o nome científico baseado no nome da cultura
  String _getScientificName(String cropName) {
    switch (cropName.toLowerCase()) {
      case 'soja':
        return 'Glycine max';
      case 'milho':
        return 'Zea mays';
      case 'algodão':
      case 'algodao':
        return 'Gossypium hirsutum';
      case 'trigo':
        return 'Triticum aestivum';
      case 'arroz':
        return 'Oryza sativa';
      case 'feijão':
      case 'feijao':
        return 'Phaseolus vulgaris';
      case 'café':
      case 'cafe':
        return 'Coffea arabica';
      case 'cana-de-açúcar':
      case 'cana-de-acucar':
        return 'Saccharum officinarum';
      default:
        return 'Cultura agrícola';
    }
  }

  /// Obtém a família botânica baseada no nome da cultura
  String _getFamily(String cropName) {
    switch (cropName.toLowerCase()) {
      case 'soja':
      case 'feijão':
      case 'feijao':
        return 'Fabaceae';
      case 'milho':
        return 'Poaceae';
      case 'trigo':
      case 'arroz':
        return 'Poaceae';
      case 'algodão':
      case 'algodao':
        return 'Malvaceae';
      case 'café':
      case 'cafe':
        return 'Rubiaceae';
      case 'cana-de-açúcar':
      case 'cana-de-acucar':
        return 'Poaceae';
      default:
        return 'Angiospermae';
    }
  }

  /// Valida se um cropId é válido (existe na tabela crops)
  Future<bool> isValidCropId(dynamic cropId) async {
    try {
      final db = await _appDatabase.database;
      
      // Se cropId é string, tentar converter para int
      int? numericId;
      if (cropId is String) {
        numericId = int.tryParse(cropId);
        if (numericId == null) {
          // Se não é numérico, buscar por nome
          final crops = await db.query(
            'crops',
            where: 'name = ?',
            whereArgs: [cropId],
            limit: 1,
          );
          return crops.isNotEmpty;
        }
      } else if (cropId is int) {
        numericId = cropId;
      } else {
        return false;
      }
      
      if (numericId != null) {
        final crops = await db.query(
          'crops',
          where: 'id = ?',
          whereArgs: [numericId],
          limit: 1,
        );
        return crops.isNotEmpty;
      }
      
      return false;
    } catch (e) {
      Logger.error('$_tag: Erro ao validar cropId: $e');
      return false;
    }
  }

  /// Obtém o ID numérico de uma cultura pelo nome
  Future<int?> getCropIdByName(String cropName) async {
    try {
      final db = await _appDatabase.database;
      
      final crops = await db.query(
        'crops',
        where: 'name = ?',
        whereArgs: [cropName],
        limit: 1,
      );
      
      if (crops.isNotEmpty) {
        return crops.first['id'] as int;
      }
      
      return null;
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar ID da cultura: $e');
      return null;
    }
  }

  /// Garante que culturas básicas existem (soja, milho, etc.)
  Future<void> ensureBasicCropsExist() async {
    try {
      final basicCrops = ['soja', 'milho', 'algodao', 'trigo', 'arroz', 'feijao'];
      
      for (final cropName in basicCrops) {
        await ensureCropExists(cropName, cropName);
      }
      
      Logger.info('$_tag: ✅ Culturas básicas verificadas/criadas');
    } catch (e) {
      Logger.error('$_tag: Erro ao garantir culturas básicas: $e');
      rethrow;
    }
  }
}
