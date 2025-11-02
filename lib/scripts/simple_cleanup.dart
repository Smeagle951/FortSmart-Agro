#!/usr/bin/env dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Script simples para limpar culturas de teste
void main() async {
  print('🧹 Iniciando limpeza simples de culturas de teste...');
  
  try {
    // Conectar ao banco de dados
    final databasePath = join(await getDatabasesPath(), 'fortsmart_agro.db');
    final db = await openDatabase(databasePath);
    
    print('📊 Conectado ao banco: $databasePath');
    
    // 1. Listar culturas atuais
    print('🌱 Culturas atuais:');
    final currentCrops = await db.rawQuery('SELECT id, name FROM crops ORDER BY id');
    for (final crop in currentCrops) {
      print('   - ${crop['id']}: ${crop['name']}');
    }
    
    // 2. Remover culturas de teste
    print('\n🗑️ Removendo culturas de teste...');
    final testCulturesDeleted = await db.delete(
      'crops', 
      where: "name LIKE '%Teste%' OR name LIKE '%test%' OR id LIKE 'test_%'"
    );
    print('✅ $testCulturesDeleted culturas de teste removidas');
    
    // 3. Remover pragas de teste
    print('🐛 Removendo pragas de teste...');
    final testPestsDeleted = await db.delete(
      'pests',
      where: "name LIKE '%Teste%' OR name LIKE '%test%' OR scientific_name LIKE '%Test%'"
    );
    print('✅ $testPestsDeleted pragas de teste removidas');
    
    // 4. Remover doenças de teste
    print('🦠 Removendo doenças de teste...');
    final testDiseasesDeleted = await db.delete(
      'diseases',
      where: "name LIKE '%Teste%' OR name LIKE '%test%' OR scientific_name LIKE '%Test%'"
    );
    print('✅ $testDiseasesDeleted doenças de teste removidas');
    
    // 5. Verificar dados finais
    print('\n📋 Dados finais:');
    final finalCrops = await db.rawQuery('SELECT id, name FROM crops ORDER BY id');
    print('🌱 Culturas restantes (${finalCrops.length}):');
    for (final crop in finalCrops) {
      print('   - ${crop['id']}: ${crop['name']}');
    }
    
    // 6. Contar registros
    final cropsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM crops')
    ) ?? 0;
    
    final pestsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pests')
    ) ?? 0;
    
    final diseasesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM diseases')
    ) ?? 0;
    
    print('\n📊 Totais finais:');
    print('   - Culturas: $cropsCount');
    print('   - Pragas: $pestsCount');
    print('   - Doenças: $diseasesCount');
    
    await db.close();
    print('\n✅ Limpeza concluída com sucesso!');
    
  } catch (e) {
    print('❌ Erro durante a limpeza: $e');
    exit(1);
  }
}
