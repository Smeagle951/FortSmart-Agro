import 'package:sqflite/sqflite.dart';

/// Migração para criar a tabela crop_varieties
/// Tabela para armazenar variedades de culturas
Future<void> createCropVarietiesTable(Database db) async {
  try {
    print('🔄 Criando tabela crop_varieties...');
    
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
    
    // Inserir variedades padrão para as 12 culturas
    await _insertDefaultVarieties(db);
    
    print('✅ Tabela crop_varieties criada com sucesso!');
  } catch (e) {
    print('❌ Erro ao criar tabela crop_varieties: $e');
    rethrow;
  }
}

/// Insere variedades padrão para as 12 culturas
Future<void> _insertDefaultVarieties(Database db) async {
  try {
    print('🔄 Inserindo variedades padrão...');
    
    final now = DateTime.now().toIso8601String();
    
    // Verificar se já existem variedades
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM crop_varieties')) ?? 0;
    
    if (count > 0) {
      print('ℹ️ Tabela crop_varieties já contém $count registros, pulando inserção');
      return;
    }
    
    final List<Map<String, dynamic>> variedadesPadrao = [
      // SOJA (ID: 1)
      {'id': 'var_soja_1', 'cropId': '1', 'name': 'Soja RR', 'company': 'TMG', 'cycleDays': 120, 'description': 'Soja Roundup Ready', 'recommendedPopulation': 320000.0, 'weightOf1000Seeds': 199.0},
      {'id': 'var_soja_2', 'cropId': '1', 'name': 'Soja Intacta', 'company': 'TMG', 'cycleDays': 125, 'description': 'Soja com tecnologia Intacta', 'recommendedPopulation': 310000.0, 'weightOf1000Seeds': 205.0},
      {'id': 'var_soja_3', 'cropId': '1', 'name': 'Soja Convencional', 'company': 'TMG', 'cycleDays': 115, 'description': 'Soja convencional', 'recommendedPopulation': 330000.0, 'weightOf1000Seeds': 195.0},
      
      // MILHO (ID: 2)
      {'id': 'var_milho_1', 'cropId': '2', 'name': 'Milho Convencional', 'company': 'Pioneer', 'cycleDays': 130, 'description': 'Milho convencional', 'recommendedPopulation': 55000.0, 'weightOf1000Seeds': 280.0},
      {'id': 'var_milho_2', 'cropId': '2', 'name': 'Milho Transgênico', 'company': 'Pioneer', 'cycleDays': 135, 'description': 'Milho com tecnologia transgênica', 'recommendedPopulation': 52000.0, 'weightOf1000Seeds': 290.0},
      {'id': 'var_milho_3', 'cropId': '2', 'name': 'Milho Pipoca', 'company': 'Pioneer', 'cycleDays': 110, 'description': 'Milho pipoca', 'recommendedPopulation': 60000.0, 'weightOf1000Seeds': 260.0},
      
      // SORGO (ID: 3)
      {'id': 'var_sorgo_1', 'cropId': '3', 'name': 'Sorgo Forrageiro', 'company': 'Agroeste', 'cycleDays': 120, 'description': 'Sorgo para forragem', 'recommendedPopulation': 180000.0, 'weightOf1000Seeds': 35.0},
      {'id': 'var_sorgo_2', 'cropId': '3', 'name': 'Sorgo Granífero', 'company': 'Agroeste', 'cycleDays': 125, 'description': 'Sorgo para grãos', 'recommendedPopulation': 160000.0, 'weightOf1000Seeds': 40.0},
      
      // ALGODÃO (ID: 4)
      {'id': 'var_algodao_1', 'cropId': '4', 'name': 'Algodão RR', 'company': 'Bayer', 'cycleDays': 180, 'description': 'Algodão Roundup Ready', 'recommendedPopulation': 45000.0, 'weightOf1000Seeds': 120.0},
      {'id': 'var_algodao_2', 'cropId': '4', 'name': 'Algodão BT', 'company': 'Bayer', 'cycleDays': 175, 'description': 'Algodão com tecnologia BT', 'recommendedPopulation': 48000.0, 'weightOf1000Seeds': 125.0},
      
      // FEIJÃO (ID: 5)
      {'id': 'var_feijao_1', 'cropId': '5', 'name': 'Feijão Preto', 'company': 'Embrapa', 'cycleDays': 85, 'description': 'Feijão preto', 'recommendedPopulation': 200000.0, 'weightOf1000Seeds': 180.0},
      {'id': 'var_feijao_2', 'cropId': '5', 'name': 'Feijão Carioca', 'company': 'Embrapa', 'cycleDays': 90, 'description': 'Feijão carioca', 'recommendedPopulation': 190000.0, 'weightOf1000Seeds': 175.0},
      
      // GIRASSOL (ID: 6)
      {'id': 'var_girassol_1', 'cropId': '6', 'name': 'Girassol Oleaginoso', 'company': 'Syngenta', 'cycleDays': 120, 'description': 'Girassol para óleo', 'recommendedPopulation': 45000.0, 'weightOf1000Seeds': 65.0},
      
      // AVEIA (ID: 7)
      {'id': 'var_aveia_1', 'cropId': '7', 'name': 'Aveia Forrageira', 'company': 'Embrapa', 'cycleDays': 140, 'description': 'Aveia para forragem', 'recommendedPopulation': 100000.0, 'weightOf1000Seeds': 35.0},
      {'id': 'var_aveia_2', 'cropId': '7', 'name': 'Aveia Branca', 'company': 'Embrapa', 'cycleDays': 135, 'description': 'Aveia branca', 'recommendedPopulation': 110000.0, 'weightOf1000Seeds': 32.0},
      
      // TRIGO (ID: 8)
      {'id': 'var_trigo_1', 'cropId': '8', 'name': 'Trigo de Sequeiro', 'company': 'Embrapa', 'cycleDays': 120, 'description': 'Trigo adaptado ao sequeiro', 'recommendedPopulation': 300000.0, 'weightOf1000Seeds': 45.0},
      {'id': 'var_trigo_2', 'cropId': '8', 'name': 'Trigo Irrigado', 'company': 'Embrapa', 'cycleDays': 110, 'description': 'Trigo para irrigação', 'recommendedPopulation': 320000.0, 'weightOf1000Seeds': 42.0},
      
      // GERGELIM (ID: 9)
      {'id': 'var_gergelim_1', 'cropId': '9', 'name': 'Gergelim Branco', 'company': 'Embrapa', 'cycleDays': 90, 'description': 'Gergelim branco', 'recommendedPopulation': 200000.0, 'weightOf1000Seeds': 3.5},
    ];
    
    final batch = db.batch();
    for (final variedade in variedadesPadrao) {
      batch.insert('crop_varieties', {
        ...variedade,
        'createdAt': now,
        'updatedAt': now,
        'isSynced': 0,
      });
    }
    await batch.commit(noResult: true);
    
    print('✅ ${variedadesPadrao.length} variedades padrão inseridas');
  } catch (e) {
    print('❌ Erro ao inserir variedades padrão: $e');
    rethrow;
  }
}
