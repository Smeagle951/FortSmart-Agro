import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  print('🔧 Corrigindo tabela crop_varieties...');
  
  try {
    // Obter diretório do banco
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'fortsmart_agro.db');
    
    print('📁 Caminho do banco: $path');
    
    // Abrir banco
    Database db = await openDatabase(path);
    
    print('🔍 Verificando estrutura atual...');
    
    // Verificar se a tabela crop_varieties existe
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='crop_varieties'"
    );
    
    if (tables.isEmpty) {
      print('❌ Tabela crop_varieties não existe!');
      return;
    }
    
    print('✅ Tabela crop_varieties existe');
    
    // Verificar se a tabela crops existe
    final cropsTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='crops'"
    );
    
    if (cropsTables.isEmpty) {
      print('❌ Tabela crops não existe!');
      return;
    }
    
    print('✅ Tabela crops existe');
    
    // Verificar culturas disponíveis
    final crops = await db.rawQuery('SELECT id, name FROM crops ORDER BY id');
    print('📋 Culturas disponíveis:');
    for (final crop in crops) {
      print('   - ID: ${crop['id']}, Nome: ${crop['name']}');
    }
    
    // Verificar variedades existentes
    final varieties = await db.rawQuery('SELECT id, name, cropId FROM crop_varieties LIMIT 5');
    print('📋 Primeiras 5 variedades:');
    for (final variety in varieties) {
      print('   - ID: ${variety['id']}, Nome: ${variety['name']}, CropId: ${variety['cropId']}');
    }
    
    // Verificar variedades com cropId inválido
    final invalidVarieties = await db.rawQuery('''
      SELECT cv.id, cv.name, cv.cropId, c.name as crop_name
      FROM crop_varieties cv 
      LEFT JOIN crops c ON cv.cropId = c.id 
      WHERE c.id IS NULL
    ''');
    
    if (invalidVarieties.isNotEmpty) {
      print('⚠️ Encontradas ${invalidVarieties.length} variedades com cropId inválido:');
      for (final variety in invalidVarieties) {
        print('   - ${variety['name']} (cropId: ${variety['cropId']})');
      }
    } else {
      print('✅ Todas as variedades têm cropId válido');
    }
    
    // Fazer backup dos dados existentes
    print('💾 Fazendo backup dos dados...');
    final existingData = await db.rawQuery('SELECT * FROM crop_varieties');
    print('📊 ${existingData.length} registros encontrados');
    
    // Dropar a tabela existente
    print('🔄 Recriando tabela crop_varieties...');
    await db.execute('DROP TABLE IF EXISTS crop_varieties');
    
    // Criar a tabela com a estrutura correta
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
    
    // Criar índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_crop_varieties_crop_id ON crop_varieties (cropId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_crop_varieties_name ON crop_varieties (name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_crop_varieties_sync_status ON crop_varieties (isSynced)');
    
    print('✅ Tabela recriada com estrutura correta');
    
    // Restaurar os dados
    if (existingData.isNotEmpty) {
      print('📥 Restaurando ${existingData.length} registros...');
      final batch = db.batch();
      for (final record in existingData) {
        batch.insert('crop_varieties', record);
      }
      await batch.commit(noResult: true);
      print('✅ Dados restaurados');
    }
    
    // Verificar se a correção funcionou
    final testVarieties = await db.rawQuery('''
      SELECT cv.id, cv.name, cv.cropId, c.name as crop_name
      FROM crop_varieties cv 
      LEFT JOIN crops c ON cv.cropId = c.id 
      WHERE c.id IS NULL
    ''');
    
    if (testVarieties.isEmpty) {
      print('🎉 Correção concluída com sucesso!');
      print('✅ Todas as variedades agora têm cropId válido');
    } else {
      print('❌ Ainda há variedades com cropId inválido');
    }
    
    await db.close();
    
  } catch (e) {
    print('❌ Erro: $e');
    exit(1);
  }
}
