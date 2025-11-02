import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../utils/logger.dart';

/// Migração para corrigir a chave estrangeira da tabela crop_varieties
/// Corrige a referência de 'culturas' para 'crops'
Future<void> fixCropVarietiesForeignKey(Database db) async {
  const String _tag = 'FixCropVarietiesForeignKey';
  
  try {
    Logger.info('$_tag: 🔄 Iniciando correção da chave estrangeira...');
    
    // Verificar se a tabela crop_varieties existe
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='crop_varieties'"
    );
    
    if (tables.isEmpty) {
      Logger.info('$_tag: Tabela crop_varieties não existe, criando...');
      await _createCropVarietiesTable(db);
      return;
    }
    
    // Verificar se a tabela crops existe
    final cropsTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='crops'"
    );
    
    if (cropsTables.isEmpty) {
      Logger.error('$_tag: ❌ Tabela crops não existe! Criando tabela crops primeiro...');
      await _createCropsTable(db);
    }
    
    // Verificar se há dados na tabela crop_varieties
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM crop_varieties')
    ) ?? 0;
    
    Logger.info('$_tag: 📊 Tabela crop_varieties contém $count registros');
    
    if (count > 0) {
      // Verificar se há registros com cropId inválido
      final invalidRecords = await db.rawQuery('''
        SELECT cv.id, cv.cropId, c.id as valid_crop_id 
        FROM crop_varieties cv 
        LEFT JOIN crops c ON cv.cropId = c.id 
        WHERE c.id IS NULL
      ''');
      
      if (invalidRecords.isNotEmpty) {
        Logger.warning('$_tag: ⚠️ Encontrados ${invalidRecords.length} registros com cropId inválido');
        
        // Corrigir registros com cropId inválido
        for (final record in invalidRecords) {
          final varietyId = record['id'] as String;
          final invalidCropId = record['cropId'] as String;
          
          Logger.info('$_tag: Corrigindo variedade $varietyId com cropId inválido: $invalidCropId');
          
          // Tentar encontrar uma cultura correspondente pelo nome
          String? correctedCropId;
          
          // Mapear nomes antigos para IDs corretos
          final cropMapping = {
            'custom_soja': '1',
            'custom_milho': '2', 
            'custom_sorgo': '3',
            'custom_algodao': '4',
            'custom_feijao': '5',
            'custom_girassol': '6',
            'custom_aveia': '7',
            'custom_trigo': '8',
            'custom_gergelim': '9',
            'custom_arroz': '10',
            'custom_cana': '11',
            'custom_cafe': '12',
          };
          
          correctedCropId = cropMapping[invalidCropId];
          
          if (correctedCropId != null) {
            // Verificar se a cultura existe
            final cropExists = await db.rawQuery(
              'SELECT id FROM crops WHERE id = ?',
              [correctedCropId]
            );
            
            if (cropExists.isNotEmpty) {
              // Atualizar o registro
              await db.update(
                'crop_varieties',
                {'cropId': correctedCropId},
                where: 'id = ?',
                whereArgs: [varietyId],
              );
              Logger.info('$_tag: ✅ Corrigido: $varietyId -> cropId: $correctedCropId');
            } else {
              Logger.warning('$_tag: ⚠️ Cultura $correctedCropId não existe, criando...');
              await _createMissingCrop(db, correctedCropId);
            }
          } else {
            Logger.warning('$_tag: ⚠️ Não foi possível mapear cropId: $invalidCropId');
          }
        }
      }
    }
    
    // Recriar a tabela com a chave estrangeira correta
    Logger.info('$_tag: 🔄 Recriando tabela com chave estrangeira correta...');
    
    // Fazer backup dos dados existentes
    final existingData = await db.rawQuery('SELECT * FROM crop_varieties');
    
    // Dropar a tabela existente
    await db.execute('DROP TABLE IF EXISTS crop_varieties');
    
    // Criar a tabela com a estrutura correta
    await _createCropVarietiesTable(db);
    
    // Restaurar os dados
    if (existingData.isNotEmpty) {
      Logger.info('$_tag: 🔄 Restaurando ${existingData.length} registros...');
      final batch = db.batch();
      for (final record in existingData) {
        batch.insert('crop_varieties', record);
      }
      await batch.commit(noResult: true);
    }
    
    Logger.info('$_tag: ✅ Correção da chave estrangeira concluída');
    
  } catch (e) {
    Logger.error('$_tag: ❌ Erro ao corrigir chave estrangeira: $e');
    rethrow;
  }
}

/// Cria a tabela crops se não existir
Future<void> _createCropsTable(Database db) async {
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
  
  // Inserir culturas básicas
  final basicCrops = [
    {'name': 'Soja', 'scientific_name': 'Glycine max', 'family': 'Fabaceae', 'description': 'Cultura principal do Brasil'},
    {'name': 'Milho', 'scientific_name': 'Zea mays', 'family': 'Poaceae', 'description': 'Cereal mais cultivado'},
    {'name': 'Sorgo', 'scientific_name': 'Sorghum bicolor', 'family': 'Poaceae', 'description': 'Cereal resistente à seca'},
    {'name': 'Algodão', 'scientific_name': 'Gossypium hirsutum', 'family': 'Malvaceae', 'description': 'Fibra natural'},
    {'name': 'Feijão', 'scientific_name': 'Phaseolus vulgaris', 'family': 'Fabaceae', 'description': 'Proteína vegetal'},
    {'name': 'Girassol', 'scientific_name': 'Helianthus annuus', 'family': 'Asteraceae', 'description': 'Oleaginosa'},
    {'name': 'Aveia', 'scientific_name': 'Avena sativa', 'family': 'Poaceae', 'description': 'Cereal de inverno'},
    {'name': 'Trigo', 'scientific_name': 'Triticum aestivum', 'family': 'Poaceae', 'description': 'Cereal de inverno'},
    {'name': 'Gergelim', 'scientific_name': 'Sesamum indicum', 'family': 'Pedaliaceae', 'description': 'Cultura oleaginosa'},
  ];
  
  final now = DateTime.now().toIso8601String();
  final batch = db.batch();
  for (final crop in basicCrops) {
    batch.insert('crops', {
      ...crop,
      'created_at': now,
      'updated_at': now,
      'sync_status': 0,
    });
  }
  await batch.commit(noResult: true);
}

/// Cria a tabela crop_varieties com a estrutura correta
Future<void> _createCropVarietiesTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS crop_varieties (
      id TEXT PRIMARY KEY,
      cropId TEXT NOT NULL,
      name TEXT NOT NULL,
      company TEXT,
      cycleDays INTEGER DEFAULT 0,
      description TEXT,
      recommendedPopulation REAL,
      weightOf1000Seeds REAL,
      notes TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      isSynced INTEGER DEFAULT 0,
      FOREIGN KEY (cropId) REFERENCES crops (id) ON DELETE CASCADE
    )
  ''');
  
  // Criar índices para performance
  await db.execute('CREATE INDEX IF NOT EXISTS idx_crop_varieties_crop_id ON crop_varieties (cropId)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_crop_varieties_name ON crop_varieties (name)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_crop_varieties_sync_status ON crop_varieties (isSynced)');
}

/// Cria uma cultura que está faltando
Future<void> _createMissingCrop(Database db, String cropId) async {
  final cropNames = {
    '1': 'Soja',
    '2': 'Milho', 
    '3': 'Sorgo',
    '4': 'Algodão',
    '5': 'Feijão',
    '6': 'Girassol',
    '7': 'Aveia',
    '8': 'Trigo',
    '9': 'Gergelim',
    '10': 'Arroz',
    '11': 'Cana-de-açúcar',
    '12': 'Café',
  };
  
  final cropName = cropNames[cropId];
  if (cropName != null) {
    final now = DateTime.now().toIso8601String();
    await db.insert('crops', {
      'id': int.parse(cropId),
      'name': cropName,
      'scientific_name': _getScientificName(cropName),
      'family': _getFamily(cropName),
      'description': 'Cultura criada automaticamente',
      'created_at': now,
      'updated_at': now,
      'sync_status': 0,
    });
  }
}

String _getScientificName(String cropName) {
  switch (cropName.toLowerCase()) {
    case 'soja':
      return 'Glycine max';
    case 'milho':
      return 'Zea mays';
    case 'sorgo':
      return 'Sorghum bicolor';
    case 'algodão':
    case 'algodao':
      return 'Gossypium hirsutum';
    case 'feijão':
    case 'feijao':
      return 'Phaseolus vulgaris';
    case 'girassol':
      return 'Helianthus annuus';
    case 'aveia':
      return 'Avena sativa';
    case 'trigo':
      return 'Triticum aestivum';
    case 'gergelim':
      return 'Sesamum indicum';
    case 'arroz':
      return 'Oryza sativa';
    case 'cana-de-açúcar':
    case 'cana-de-acucar':
      return 'Saccharum officinarum';
    case 'café':
    case 'cafe':
      return 'Coffea arabica';
    default:
      return 'Cultura agrícola';
  }
}

String _getFamily(String cropName) {
  switch (cropName.toLowerCase()) {
    case 'soja':
    case 'feijão':
    case 'feijao':
      return 'Fabaceae';
    case 'milho':
    case 'sorgo':
    case 'aveia':
    case 'trigo':
    case 'arroz':
    case 'cana-de-açúcar':
    case 'cana-de-acucar':
      return 'Poaceae';
    case 'algodão':
    case 'algodao':
      return 'Malvaceae';
    case 'girassol':
      return 'Asteraceae';
    case 'gergelim':
      return 'Pedaliaceae';
    case 'café':
    case 'cafe':
      return 'Rubiaceae';
    default:
      return 'Angiospermae';
  }
}
