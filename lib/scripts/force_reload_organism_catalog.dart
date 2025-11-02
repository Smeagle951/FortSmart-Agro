import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../repositories/organism_catalog_repository.dart';
import '../services/organism_catalog_loader_service.dart';
import '../utils/logger.dart';

/// Script para forçar a recriação completa do catálogo de organismos
class ForceReloadOrganismCatalog {
  final AppDatabase _database = AppDatabase();
  final OrganismCatalogRepository _repository = OrganismCatalogRepository();
  final OrganismCatalogLoaderService _loaderService = OrganismCatalogLoaderService();

  /// Executa a recriação completa do catálogo
  Future<void> forceReload() async {
    print('🔄 Iniciando recriação forçada do catálogo de organismos...');
    
    try {
      // 1. Limpar completamente a tabela organism_catalog
      await _clearOrganismCatalogTable();
      
      // 2. Garantir que a tabela crops existe com os dados corretos
      await _ensureCropsTable();
      
      // 3. Carregar organismos dos arquivos JSON
      final organisms = await _loaderService.loadAllOrganisms();
      print('📚 Organismos carregados dos JSONs: ${organisms.length}');
      
      // 4. Inserir organismos no banco de dados
      int insertedCount = 0;
      for (var organism in organisms) {
        try {
          await _repository.create(organism);
          insertedCount++;
          if (insertedCount % 10 == 0) {
            print('📈 Inseridos $insertedCount/${organisms.length} organismos...');
          }
        } catch (e) {
          print('❌ Erro ao inserir organismo ${organism.name}: $e');
        }
      }
      
      // 5. Verificar se os dados foram inseridos corretamente
      final allOrganisms = await _repository.getAll();
      print('✅ Verificação final: ${allOrganisms.length} organismos no banco');
      
      // 6. Mostrar estatísticas
      _showStatistics(allOrganisms);
      
      print('🎉 Recriação do catálogo concluída com sucesso!');
      
    } catch (e) {
      print('❌ Erro durante a recriação: $e');
      rethrow;
    }
  }

  /// Limpa completamente a tabela organism_catalog
  Future<void> _clearOrganismCatalogTable() async {
    final db = await _database.database;
    
    print('🗑️ Limpando tabela organism_catalog...');
    
    try {
      await db.execute('DROP TABLE IF EXISTS organism_catalog');
      print('✅ Tabela organism_catalog removida');
    } catch (e) {
      print('⚠️ Erro ao remover tabela: $e');
    }
    
    // Recriar a tabela
    await db.execute('''
      CREATE TABLE organism_catalog (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        scientific_name TEXT,
        type TEXT NOT NULL,
        crop_id TEXT NOT NULL,
        crop_name TEXT NOT NULL,
        unit TEXT NOT NULL,
        low_limit INTEGER NOT NULL,
        medium_limit INTEGER NOT NULL,
        high_limit INTEGER NOT NULL,
        description TEXT,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    print('✅ Tabela organism_catalog recriada');
  }

  /// Garante que a tabela crops existe com os dados corretos
  Future<void> _ensureCropsTable() async {
    final db = await _database.database;
    
    print('📋 Verificando tabela crops...');
    
    // Criar tabela crops se não existir
    await db.execute('''
      CREATE TABLE IF NOT EXISTS crops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        sync_status INTEGER NOT NULL DEFAULT 0,
        remote_id INTEGER
      )
    ''');
    
    // Lista de culturas necessárias
    final requiredCrops = [
      {'id': '1', 'name': 'Soja', 'description': 'Cultura da soja'},
      {'id': '2', 'name': 'Milho', 'description': 'Cultura do milho'},
      {'id': '3', 'name': 'Trigo', 'description': 'Cultura do trigo'},
      {'id': '4', 'name': 'Feijão', 'description': 'Cultura do feijão'},
      {'id': '5', 'name': 'Algodão', 'description': 'Cultura do algodão'},
      {'id': '6', 'name': 'Sorgo', 'description': 'Cultura do sorgo'},
      {'id': '7', 'name': 'Girassol', 'description': 'Cultura do girassol'},
      {'id': '8', 'name': 'Aveia', 'description': 'Cultura da aveia'},
      {'id': '9', 'name': 'Gergelim', 'description': 'Cultura do gergelim'},
    ];
    
    // Inserir culturas se não existirem
    for (final crop in requiredCrops) {
      try {
        await db.insert(
          'crops',
          {
            'id': crop['id'],
            'name': crop['name'],
            'description': crop['description'],
            'sync_status': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        print('✅ Cultura ${crop['name']} verificada/inserida');
      } catch (e) {
        print('⚠️ Erro ao inserir cultura ${crop['name']}: $e');
      }
    }
  }

  /// Mostra estatísticas dos organismos carregados
  void _showStatistics(List<dynamic> organisms) {
    print('\n📊 ESTATÍSTICAS DO CATÁLOGO:');
    print('Total de organismos: ${organisms.length}');
    
    // Contar por tipo
    final pests = organisms.where((o) => o.type.toString().contains('pest')).length;
    final diseases = organisms.where((o) => o.type.toString().contains('disease')).length;
    final weeds = organisms.where((o) => o.type.toString().contains('weed')).length;
    
    print('Pragas: $pests');
    print('Doenças: $diseases');
    print('Plantas daninhas: $weeds');
    
    // Contar por cultura
    final crops = <String, int>{};
    for (var organism in organisms) {
      crops[organism.cropName] = (crops[organism.cropName] ?? 0) + 1;
    }
    
    print('\nPor cultura:');
    crops.forEach((crop, count) {
      print('  $crop: $count organismos');
    });
    
    // Mostrar alguns exemplos
    print('\n📝 EXEMPLOS DE ORGANISMOS:');
    final examples = organisms.take(5).toList();
    for (var org in examples) {
      print('  • ${org.name} (${org.cropName}) - ${org.lowLimit}-${org.mediumLimit}-${org.highLimit} ${org.unit}');
    }
  }
}

/// Função para executar a recriação forçada
Future<void> forceReloadOrganismCatalog() async {
  final reloader = ForceReloadOrganismCatalog();
  
  try {
    await reloader.forceReload();
    print('🎉 Recriação forçada concluída com sucesso!');
  } catch (e) {
    print('❌ Falha na recriação forçada: $e');
  }
}
