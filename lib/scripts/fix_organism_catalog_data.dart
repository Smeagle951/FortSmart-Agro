import '../database/app_database.dart';
import '../utils/enums.dart';

/// Script para corrigir dados corrompidos no catálogo de organismos
/// Resolve problemas com valores inválidos nos dropdowns
class OrganismCatalogDataFixer {
  final AppDatabase _database = AppDatabase();
  
  /// Executa a correção dos dados
  Future<void> fixCorruptedData() async {
    try {
      print('🔧 Iniciando correção de dados do catálogo de organismos...');
      
      final db = await _database.database;
      
      // 1. Corrigir tipos de ocorrência inválidos
      await _fixInvalidOccurrenceTypes(db);
      
      // 2. Corrigir cropIds inválidos
      await _fixInvalidCropIds(db);
      
      // 3. Verificar e corrigir outros campos
      await _fixOtherFields(db);
      
      print('✅ Correção de dados concluída com sucesso!');
    } catch (e) {
      print('❌ Erro ao corrigir dados: $e');
    }
  }
  
  /// Corrige tipos de ocorrência inválidos
  Future<void> _fixInvalidOccurrenceTypes(dynamic db) async {
    print('🔧 Corrigindo tipos de ocorrência...');
    
    // Mapeamento de valores inválidos para válidos
    final typeMapping = {
      '0': 'pest',
      '1': 'disease', 
      '2': 'weed',
      '3': 'pest', // Valor problemático encontrado no erro
      '4': 'other',
      'pest': 'pest',
      'disease': 'disease',
      'weed': 'weed',
      'deficiency': 'deficiency',
      'other': 'other',
    };
    
    // Buscar todos os organismos
    final organisms = await db.query('organism_catalog');
    
    for (final organism in organisms) {
      final currentType = organism['type']?.toString() ?? '';
      final validType = typeMapping[currentType] ?? 'pest';
      
      if (currentType != validType) {
        print('🔄 Corrigindo tipo: $currentType -> $validType (ID: ${organism['id']})');
        
        await db.update(
          'organism_catalog',
          {'type': validType},
          where: 'id = ?',
          whereArgs: [organism['id']],
        );
      }
    }
  }
  
  /// Corrige cropIds inválidos
  Future<void> _fixInvalidCropIds(dynamic db) async {
    print('🔧 Corrigindo cropIds...');
    
    // Mapeamento de valores inválidos para válidos
    final cropMapping = {
      'soja': 'soja',
      'milho': 'milho',
      'algodao': 'algodao',
      'feijao': 'feijao',
      'Soja': 'soja',
      'Milho': 'milho',
      'Algodão': 'algodao',
      'Algodao': 'algodao',
      'Feijão': 'feijao',
      'Feijao': 'feijao',
    };
    
    // Buscar todos os organismos
    final organisms = await db.query('organism_catalog');
    
    for (final organism in organisms) {
      final currentCropId = organism['crop_id']?.toString() ?? '';
      final validCropId = cropMapping[currentCropId] ?? 'soja';
      
      if (currentCropId != validCropId) {
        print('🔄 Corrigindo cropId: $currentCropId -> $validCropId (ID: ${organism['id']})');
        
        await db.update(
          'organism_catalog',
          {'crop_id': validCropId},
          where: 'id = ?',
          whereArgs: [organism['id']],
        );
      }
    }
  }
  
  /// Corrige outros campos que podem estar causando problemas
  Future<void> _fixOtherFields(dynamic db) async {
    print('🔧 Verificando outros campos...');
    
    // Buscar organismos com valores nulos ou inválidos
    final organisms = await db.query('organism_catalog');
    
    for (final organism in organisms) {
      final updates = <String, dynamic>{};
      
      // Corrigir nome se estiver vazio
      if (organism['name'] == null || organism['name'].toString().isEmpty) {
        updates['name'] = 'Organismo sem nome';
        print('🔄 Corrigindo nome vazio (ID: ${organism['id']})');
      }
      
      // Corrigir nome científico se estiver vazio
      if (organism['scientific_name'] == null || organism['scientific_name'].toString().isEmpty) {
        updates['scientific_name'] = 'N/A';
        print('🔄 Corrigindo nome científico vazio (ID: ${organism['id']})');
      }
      
      // Corrigir unidade se estiver vazia
      if (organism['unit'] == null || organism['unit'].toString().isEmpty) {
        updates['unit'] = 'indivíduos/ponto';
        print('🔄 Corrigindo unidade vazia (ID: ${organism['id']})');
      }
      
      // Corrigir limites se estiverem inválidos
      if (organism['low_limit'] == null || organism['low_limit'] < 0) {
        updates['low_limit'] = 0;
        print('🔄 Corrigindo limite baixo inválido (ID: ${organism['id']})');
      }
      
      if (organism['medium_limit'] == null || organism['medium_limit'] < 0) {
        updates['medium_limit'] = 5;
        print('🔄 Corrigindo limite médio inválido (ID: ${organism['id']})');
      }
      
      if (organism['high_limit'] == null || organism['high_limit'] < 0) {
        updates['high_limit'] = 10;
        print('🔄 Corrigindo limite alto inválido (ID: ${organism['id']})');
      }
      
      // Aplicar correções se houver
      if (updates.isNotEmpty) {
        await db.update(
          'organism_catalog',
          updates,
          where: 'id = ?',
          whereArgs: [organism['id']],
        );
      }
    }
  }
  
  /// Verifica se há dados corrompidos
  Future<bool> hasCorruptedData() async {
    try {
      final db = await _database.database;
      
      // Verificar tipos inválidos
      final invalidTypes = await db.rawQuery('''
        SELECT COUNT(*) as count FROM organism_catalog 
        WHERE type NOT IN ('pest', 'disease', 'weed', 'deficiency', 'other')
      ''');
      
      // Verificar cropIds inválidos
      final invalidCropIds = await db.rawQuery('''
        SELECT COUNT(*) as count FROM organism_catalog 
        WHERE crop_id NOT IN ('soja', 'milho', 'algodao', 'feijao')
      ''');
      
      final hasInvalidTypes = invalidTypes.first['count'] as int > 0;
      final hasInvalidCropIds = invalidCropIds.first['count'] as int > 0;
      
      return hasInvalidTypes || hasInvalidCropIds;
    } catch (e) {
      print('❌ Erro ao verificar dados corrompidos: $e');
      return false;
    }
  }
  
  /// Executa verificação e correção se necessário
  Future<void> checkAndFix() async {
    print('🔍 Verificando dados do catálogo de organismos...');
    
    final hasCorrupted = await hasCorruptedData();
    
    if (hasCorrupted) {
      print('⚠️ Dados corrompidos encontrados. Iniciando correção...');
      await fixCorruptedData();
    } else {
      print('✅ Nenhum dado corrompido encontrado.');
    }
  }
}
