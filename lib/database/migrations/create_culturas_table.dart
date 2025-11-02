import 'package:sqflite/sqflite.dart';

/// Migração para criar a tabela de culturas
Future<void> createCulturasTable(Database db) async {
  print('🔄 Criando tabela de culturas...');

  // Desabilitar FOREIGN KEY constraints para esta tabela
  await db.execute('PRAGMA foreign_keys = OFF');

  // Tabela culturas (para compatibilidade com submódulos de plantio)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS culturas (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      scientific_name TEXT,
      family TEXT,
      description TEXT,
      color_value TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      sync_status INTEGER DEFAULT 0
    )
  ''');

  // Índices para culturas
  await db.execute('CREATE INDEX IF NOT EXISTS idx_culturas_name ON culturas (name)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_culturas_sync_status ON culturas (sync_status)');

  // Inserir culturas padrão se a tabela estiver vazia
  final count = await db.rawQuery('SELECT COUNT(*) as count FROM culturas');
  final culturaCount = count.first['count'] as int? ?? 0;
  
  if (culturaCount == 0) {
    print('🔄 Inserindo culturas padrão...');
    final now = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> culturasPadrao = [
      {'id': 'custom_soja', 'name': 'Soja', 'scientific_name': 'Glycine max', 'family': 'Fabaceae', 'description': 'Cultura principal do Brasil', 'color_value': '4CAF50'},
      {'id': 'custom_milho', 'name': 'Milho', 'scientific_name': 'Zea mays', 'family': 'Poaceae', 'description': 'Cereal mais cultivado', 'color_value': 'FFC107'},
      {'id': 'custom_sorgo', 'name': 'Sorgo', 'scientific_name': 'Sorghum bicolor', 'family': 'Poaceae', 'description': 'Cereal resistente à seca', 'color_value': 'FF9800'},
      {'id': 'custom_algodao', 'name': 'Algodão', 'scientific_name': 'Gossypium hirsutum', 'family': 'Malvaceae', 'description': 'Fibra natural', 'color_value': 'E1F5FE'},
      {'id': 'custom_feijao', 'name': 'Feijão', 'scientific_name': 'Phaseolus vulgaris', 'family': 'Fabaceae', 'description': 'Proteína vegetal', 'color_value': '8D6E63'},
      {'id': 'custom_girassol', 'name': 'Girassol', 'scientific_name': 'Helianthus annuus', 'family': 'Asteraceae', 'description': 'Oleaginosa', 'color_value': 'FFEB3B'},
      {'id': 'custom_aveia', 'name': 'Aveia', 'scientific_name': 'Avena sativa', 'family': 'Poaceae', 'description': 'Cereal de inverno', 'color_value': 'D7CCC8'},
      {'id': 'custom_trigo', 'name': 'Trigo', 'scientific_name': 'Triticum aestivum', 'family': 'Poaceae', 'description': 'Cereal de inverno', 'color_value': 'BCAAA4'},
      {'id': 'custom_gergelim', 'name': 'Gergelim', 'scientific_name': 'Sesamum indicum', 'family': 'Pedaliaceae', 'description': 'Cultura oleaginosa', 'color_value': 'F5F5DC'},
      {'id': 'custom_arroz', 'name': 'Arroz', 'scientific_name': 'Oryza sativa', 'family': 'Poaceae', 'description': 'Cereal de várzea', 'color_value': 'E0E0E0'},
      {'id': 'custom_cana', 'name': 'Cana-de-açúcar', 'scientific_name': 'Saccharum officinarum', 'family': 'Poaceae', 'description': 'Cultura industrial', 'color_value': '8BC34A'},
      {'id': 'custom_cafe', 'name': 'Café', 'scientific_name': 'Coffea arabica', 'family': 'Rubiaceae', 'description': 'Cultura perene', 'color_value': '795548'},
    ];
    
    final batch = db.batch();
    for (final cultura in culturasPadrao) {
      batch.insert('culturas', {
        ...cultura,
        'created_at': now,
        'updated_at': now,
        'sync_status': 0,
      });
    }
    await batch.commit(noResult: true);
    print('✅ ${culturasPadrao.length} culturas padrão inseridas');
  } else {
    print('ℹ️ Tabela culturas já contém $culturaCount registros, pulando inserção');
  }

  // Reabilitar FOREIGN KEY constraints
  await db.execute('PRAGMA foreign_keys = ON');

  print('✅ Tabela de culturas criada com sucesso!');
}
