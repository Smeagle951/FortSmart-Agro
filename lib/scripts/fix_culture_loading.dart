#!/usr/bin/env dart
import 'dart:io';
import '../database/app_database.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/pest_dao.dart';
import '../database/daos/disease_dao.dart';
import '../database/daos/weed_dao.dart';
import '../utils/logger.dart';

/// Script para corrigir o carregamento de culturas e remover dados de teste
void main() async {
  print('🔧 Iniciando correção do carregamento de culturas...');
  
  try {
    // 1. Inicializar banco de dados
    print('📊 Inicializando banco de dados...');
    final appDatabase = AppDatabase();
    await appDatabase.initialize();
    final db = await appDatabase.database;
    
    // 2. Limpar dados de teste
    print('🧹 Limpando dados de teste...');
    await _cleanupTestData(db);
    
    // 3. Verificar e inserir dados padrão se necessário
    print('🌱 Verificando dados padrão...');
    await _ensureDefaultData();
    
    // 4. Verificar integridade dos dados
    print('🔍 Verificando integridade dos dados...');
    await _verifyDataIntegrity(db);
    
    // 5. Listar dados finais
    print('📋 Dados finais:');
    await _listFinalData(db);
    
    print('✅ Correção concluída com sucesso!');
    print('');
    print('🎯 Próximos passos:');
    print('   1. Reinicie o aplicativo');
    print('   2. Acesse o módulo "Culturas da Fazenda"');
    print('   3. Verifique se as culturas corretas estão sendo exibidas');
    
  } catch (e) {
    print('❌ Erro durante a correção: $e');
    exit(1);
  }
}

/// Limpa dados de teste do banco
Future<void> _cleanupTestData(dynamic db) async {
  // Remover culturas de teste
  final testCulturesDeleted = await db.delete(
    'crops', 
    where: "name LIKE '%Teste%' OR name LIKE '%test%' OR id LIKE 'test_%'"
  );
  print('   ✅ $testCulturesDeleted culturas de teste removidas');
  
  // Remover pragas de teste
  final testPestsDeleted = await db.delete(
    'pests',
    where: "name LIKE '%Teste%' OR name LIKE '%test%' OR scientific_name LIKE '%Test%'"
  );
  print('   ✅ $testPestsDeleted pragas de teste removidas');
  
  // Remover doenças de teste
  final testDiseasesDeleted = await db.delete(
    'diseases',
    where: "name LIKE '%Teste%' OR name LIKE '%test%' OR scientific_name LIKE '%Test%'"
  );
  print('   ✅ $testDiseasesDeleted doenças de teste removidas');
  
  // Remover plantas daninhas de teste
  final testWeedsDeleted = await db.delete(
    'weeds',
    where: "name LIKE '%Teste%' OR name LIKE '%test%' OR scientific_name LIKE '%Test%'"
  );
  print('   ✅ $testWeedsDeleted plantas daninhas de teste removidas');
}

/// Garante que os dados padrão estejam inseridos
Future<void> _ensureDefaultData() async {
  try {
    final cropDao = CropDao();
    await cropDao.initialize();
    
    final crops = await cropDao.getAll();
    if (crops.isEmpty) {
      print('   ⚠️ Nenhuma cultura encontrada, inserindo dados padrão...');
      await cropDao.insertDefaultCrops();
      print('   ✅ Culturas padrão inseridas');
    } else {
      print('   ✅ ${crops.length} culturas já existem');
    }
    
    final pestDao = PestDao();
    await pestDao.initialize();
    
    final pests = await pestDao.getAll();
    if (pests.isEmpty) {
      print('   ⚠️ Nenhuma praga encontrada, inserindo dados padrão...');
      await pestDao.insertDefaultPests();
      print('   ✅ Pragas padrão inseridas');
    } else {
      print('   ✅ ${pests.length} pragas já existem');
    }
    
    final diseaseDao = DiseaseDao();
    await diseaseDao.initialize();
    
    final diseases = await diseaseDao.getAll();
    if (diseases.isEmpty) {
      print('   ⚠️ Nenhuma doença encontrada, inserindo dados padrão...');
      await diseaseDao.insertDefaultDiseases();
      print('   ✅ Doenças padrão inseridas');
    } else {
      print('   ✅ ${diseases.length} doenças já existem');
    }
    
    final weedDao = WeedDao();
    await weedDao.initialize();
    
    final weeds = await weedDao.getAll();
    if (weeds.isEmpty) {
      print('   ⚠️ Nenhuma planta daninha encontrada, inserindo dados padrão...');
      await weedDao.insertDefaultWeeds();
      print('   ✅ Plantas daninhas padrão inseridas');
    } else {
      print('   ✅ ${weeds.length} plantas daninhas já existem');
    }
    
  } catch (e) {
    print('   ❌ Erro ao garantir dados padrão: $e');
  }
}

/// Verifica integridade dos dados
Future<void> _verifyDataIntegrity(dynamic db) async {
  try {
    // Verificar pragas órfãs
    final orphanPests = await db.rawQuery('''
      SELECT COUNT(*) as count FROM pests p 
      LEFT JOIN crops c ON p.crop_id = c.id 
      WHERE c.id IS NULL
    ''');
    
    final orphanPestsCount = Sqflite.firstIntValue(orphanPests) ?? 0;
    if (orphanPestsCount > 0) {
      print('   ⚠️ $orphanPestsCount pragas órfãs encontradas');
    } else {
      print('   ✅ Nenhuma praga órfã encontrada');
    }
    
    // Verificar doenças órfãs
    final orphanDiseases = await db.rawQuery('''
      SELECT COUNT(*) as count FROM diseases d 
      LEFT JOIN crops c ON d.crop_id = c.id 
      WHERE c.id IS NULL
    ''');
    
    final orphanDiseasesCount = Sqflite.firstIntValue(orphanDiseases) ?? 0;
    if (orphanDiseasesCount > 0) {
      print('   ⚠️ $orphanDiseasesCount doenças órfãs encontradas');
    } else {
      print('   ✅ Nenhuma doença órfã encontrada');
    }
    
    // Verificar plantas daninhas órfãs
    final orphanWeeds = await db.rawQuery('''
      SELECT COUNT(*) as count FROM weeds w 
      LEFT JOIN crops c ON w.crop_id = c.id 
      WHERE c.id IS NULL
    ''');
    
    final orphanWeedsCount = Sqflite.firstIntValue(orphanWeeds) ?? 0;
    if (orphanWeedsCount > 0) {
      print('   ⚠️ $orphanWeedsCount plantas daninhas órfãs encontradas');
    } else {
      print('   ✅ Nenhuma planta daninha órfã encontrada');
    }
    
  } catch (e) {
    print('   ❌ Erro ao verificar integridade: $e');
  }
}

/// Lista os dados finais
Future<void> _listFinalData(dynamic db) async {
  try {
    // Contar registros
    final cropsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM crops')
    ) ?? 0;
    
    final pestsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pests')
    ) ?? 0;
    
    final diseasesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM diseases')
    ) ?? 0;
    
    final weedsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM weeds')
    ) ?? 0;
    
    print('   📊 Totais:');
    print('      - Culturas: $cropsCount');
    print('      - Pragas: $pestsCount');
    print('      - Doenças: $diseasesCount');
    print('      - Plantas daninhas: $weedsCount');
    
    // Listar culturas
    print('   🌱 Culturas disponíveis:');
    final crops = await db.rawQuery('SELECT id, name FROM crops ORDER BY id');
    for (final crop in crops) {
      print('      - ${crop['id']}: ${crop['name']}');
    }
    
  } catch (e) {
    print('   ❌ Erro ao listar dados finais: $e');
  }
}
