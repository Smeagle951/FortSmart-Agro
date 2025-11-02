import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/crop_variety.dart';
import '../repositories/crop_variety_repository.dart';
import '../services/crop_validation_service.dart';
import '../utils/logger.dart';

/// Script para testar o salvamento de variedades após correção
/// 
/// Este script:
/// 1. Verifica se as tabelas existem
/// 2. Testa o salvamento de uma variedade
/// 3. Valida a integridade dos dados
/// 
/// Autor: Assistente IA
/// Data: 2024-12-21
/// Versão: 1.0

class TestCropVarietySaving {
  static const String _tag = 'TestCropVarietySaving';
  
  /// Executa o teste completo
  static Future<void> run() async {
    Logger.info('$_tag: 🧪 Iniciando teste de salvamento de variedades...');
    
    try {
      // 1. Verificar estrutura do banco
      await _checkDatabaseStructure();
      
      // 2. Testar salvamento de variedade
      await _testVarietySaving();
      
      // 3. Validar integridade
      await _validateDataIntegrity();
      
      Logger.info('$_tag: ✅ Teste concluído com sucesso!');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro no teste: $e');
      rethrow;
    }
  }
  
  /// Verifica a estrutura do banco de dados
  static Future<void> _checkDatabaseStructure() async {
    Logger.info('$_tag: 🔍 Verificando estrutura do banco...');
    
    final db = await AppDatabase().database;
    
    // Verificar se a tabela crops existe
    final cropsTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='crops'"
    );
    
    if (cropsTable.isEmpty) {
      throw Exception('Tabela crops não existe!');
    }
    
    Logger.info('$_tag: ✅ Tabela crops existe');
    
    // Verificar se a tabela crop_varieties existe
    final varietiesTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='crop_varieties'"
    );
    
    if (varietiesTable.isEmpty) {
      throw Exception('Tabela crop_varieties não existe!');
    }
    
    Logger.info('$_tag: ✅ Tabela crop_varieties existe');
    
    // Verificar se há culturas na tabela crops
    final cropsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM crops')
    ) ?? 0;
    
    Logger.info('$_tag: 📊 Culturas encontradas: $cropsCount');
    
    if (cropsCount == 0) {
      Logger.warning('$_tag: ⚠️ Nenhuma cultura encontrada, criando culturas básicas...');
      final cropValidationService = CropValidationService();
      await cropValidationService.ensureBasicCropsExist();
    }
    
    // Listar culturas disponíveis
    final crops = await db.rawQuery('SELECT id, name FROM crops ORDER BY id');
    Logger.info('$_tag: 📋 Culturas disponíveis:');
    for (final crop in crops) {
      Logger.info('$_tag:   - ID: ${crop['id']}, Nome: ${crop['name']}');
    }
  }
  
  /// Testa o salvamento de uma variedade
  static Future<void> _testVarietySaving() async {
    Logger.info('$_tag: 🧪 Testando salvamento de variedade...');
    
    final repository = CropVarietyRepository();
    
    // Criar uma variedade de teste
    final testVariety = CropVariety(
      cropId: '1', // Soja
      name: 'Variedade Teste',
      company: 'Empresa Teste',
      cycleDays: 120,
      description: 'Variedade criada para teste',
      recommendedPopulation: 300000.0,
      weightOf1000Seeds: 200.0,
      notes: 'Notas de teste',
    );
    
    Logger.info('$_tag: 📝 Criando variedade: ${testVariety.name}');
    
    try {
      final varietyId = await repository.insert(testVariety);
      Logger.info('$_tag: ✅ Variedade salva com ID: $varietyId');
      
      // Verificar se a variedade foi salva corretamente
      final savedVariety = await repository.getById(varietyId);
      if (savedVariety == null) {
        throw Exception('Variedade não foi encontrada após salvamento!');
      }
      
      Logger.info('$_tag: ✅ Variedade recuperada: ${savedVariety.name}');
      Logger.info('$_tag:   - CropId: ${savedVariety.cropId}');
      Logger.info('$_tag:   - Empresa: ${savedVariety.company}');
      Logger.info('$_tag:   - Ciclo: ${savedVariety.cycleDays} dias');
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao salvar variedade: $e');
      rethrow;
    }
  }
  
  /// Valida a integridade dos dados
  static Future<void> _validateDataIntegrity() async {
    Logger.info('$_tag: 🔍 Validando integridade dos dados...');
    
    final db = await AppDatabase().database;
    
    // Verificar se há variedades com cropId inválido
    final invalidVarieties = await db.rawQuery('''
      SELECT cv.id, cv.name, cv.cropId, c.name as crop_name
      FROM crop_varieties cv 
      LEFT JOIN crops c ON cv.cropId = c.id 
      WHERE c.id IS NULL
    ''');
    
    if (invalidVarieties.isNotEmpty) {
      Logger.warning('$_tag: ⚠️ Encontradas ${invalidVarieties.length} variedades com cropId inválido:');
      for (final variety in invalidVarieties) {
        Logger.warning('$_tag:   - ${variety['name']} (cropId: ${variety['cropId']})');
      }
    } else {
      Logger.info('$_tag: ✅ Todas as variedades têm cropId válido');
    }
    
    // Verificar contagem de variedades por cultura
    final varietiesByCrop = await db.rawQuery('''
      SELECT c.name as crop_name, COUNT(cv.id) as variety_count
      FROM crops c
      LEFT JOIN crop_varieties cv ON c.id = cv.cropId
      GROUP BY c.id, c.name
      ORDER BY variety_count DESC
    ''');
    
    Logger.info('$_tag: 📊 Variedades por cultura:');
    for (final row in varietiesByCrop) {
      Logger.info('$_tag:   - ${row['crop_name']}: ${row['variety_count']} variedades');
    }
  }
}

/// Função principal para executar o teste
Future<void> main() async {
  try {
    await TestCropVarietySaving.run();
    print('🎉 Teste de salvamento de variedades concluído com sucesso!');
  } catch (e) {
    print('❌ Erro no teste: $e');
    exit(1);
  }
}
