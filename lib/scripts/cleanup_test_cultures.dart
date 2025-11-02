#!/usr/bin/env dart
import 'dart:io';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Script para limpar culturas de teste e garantir dados corretos
void main() async {
  print('🧹 Iniciando limpeza de culturas de teste...');
  
  try {
    final appDatabase = AppDatabase();
    await appDatabase.initialize();
    final db = await appDatabase.database;
    
    // 1. Remover culturas de teste
    print('🗑️ Removendo culturas de teste...');
    final testCulturesDeleted = await db.delete(
      'crops', 
      where: "name LIKE '%Teste%' OR name LIKE '%test%' OR id LIKE 'test_%'"
    );
    print('✅ $testCulturesDeleted culturas de teste removidas');
    
    // 2. Remover pragas de teste
    print('🐛 Removendo pragas de teste...');
    final testPestsDeleted = await db.delete(
      'pests',
      where: "name LIKE '%Teste%' OR name LIKE '%test%' OR scientific_name LIKE '%Test%'"
    );
    print('✅ $testPestsDeleted pragas de teste removidas');
    
    // 3. Remover doenças de teste
    print('🦠 Removendo doenças de teste...');
    final testDiseasesDeleted = await db.delete(
      'diseases',
      where: "name LIKE '%Teste%' OR name LIKE '%test%' OR scientific_name LIKE '%Test%'"
    );
    print('✅ $testDiseasesDeleted doenças de teste removidas');
    
    // 4. Verificar dados atuais
    print('📊 Verificando dados atuais...');
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
    
    print('📈 Dados atuais:');
    print('   - Culturas: $cropsCount');
    print('   - Pragas: $pestsCount');
    print('   - Doenças: $diseasesCount');
    print('   - Plantas daninhas: $weedsCount');
    
    // 5. Listar culturas atuais
    print('🌱 Culturas atuais:');
    final currentCrops = await db.rawQuery('SELECT id, name FROM crops ORDER BY id');
    for (final crop in currentCrops) {
      print('   - ${crop['id']}: ${crop['name']}');
    }
    
    // 6. Se não há culturas, inserir dados padrão
    if (cropsCount == 0) {
      print('⚠️ Nenhuma cultura encontrada, inserindo dados padrão...');
      await _insertDefaultCrops(db);
      print('✅ Dados padrão inseridos');
    }
    
    print('✅ Limpeza concluída com sucesso!');
    
  } catch (e) {
    print('❌ Erro durante a limpeza: $e');
    exit(1);
  }
}

/// Insere culturas padrão
Future<void> _insertDefaultCrops(dynamic db) async {
  final defaultCrops = [
    {'id': 1, 'name': 'Soja', 'description': 'Glycine max - Cultura principal para produção de óleo e proteína'},
    {'id': 2, 'name': 'Milho', 'description': 'Zea mays - Cultura para grãos e silagem'},
    {'id': 3, 'name': 'Algodão', 'description': 'Gossypium hirsutum - Cultura para produção de fibra'},
    {'id': 4, 'name': 'Feijão', 'description': 'Phaseolus vulgaris - Cultura para grãos'},
    {'id': 5, 'name': 'Girassol', 'description': 'Helianthus annuus - Cultura para produção de óleo'},
    {'id': 6, 'name': 'Arroz', 'description': 'Oryza sativa - Cultura para grãos'},
    {'id': 7, 'name': 'Sorgo', 'description': 'Sorghum bicolor - Cultura para grãos e forragem'},
    {'id': 8, 'name': 'Gergelim', 'description': 'Sesamum indicum - Cultura para produção de óleo'},
    {'id': 9, 'name': 'Cana-de-açúcar', 'description': 'Saccharum officinarum - Cultura energética'},
    {'id': 10, 'name': 'Tomate', 'description': 'Solanum lycopersicum - Cultura hortícola'},
  ];
  
  final batch = db.batch();
  for (final crop in defaultCrops) {
    batch.insert('crops', crop);
  }
  await batch.commit(noResult: true);
}
