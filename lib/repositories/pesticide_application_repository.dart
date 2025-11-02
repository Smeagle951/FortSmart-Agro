import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/pesticide_application.dart';
import '../models/inventory_movement.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/inventory_movement_repository.dart';
import '../repositories/plot_repository.dart';
import '../repositories/crop_repository.dart';
import '../repositories/agricultural_product_repository.dart';

/// Repositório para operações com aplicações de defensivos
class PesticideApplicationRepository {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'pesticide_applications';
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final InventoryMovementRepository _movementRepository = InventoryMovementRepository();
  final PlotRepository _plotRepository = PlotRepository();
  final CropRepository _cropRepository = CropRepository();
  final AgriculturalProductRepository _productRepository = AgriculturalProductRepository();

  /// Cria a tabela de aplicações de defensivos no banco de dados
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        plotId TEXT NOT NULL,
        cropId TEXT,
        productId TEXT NOT NULL,
        dose REAL NOT NULL,
        doseUnit TEXT NOT NULL,
        mixtureVolume REAL NOT NULL,
        totalArea REAL NOT NULL,
        applicationDate TEXT NOT NULL,
        responsiblePerson TEXT NOT NULL,
        applicationType INTEGER NOT NULL,
        temperature REAL,
        humidity REAL,
        observations TEXT,
        imageUrls TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (plotId) REFERENCES plots (id) ON DELETE CASCADE,
        FOREIGN KEY (cropId) REFERENCES crops (id) ON DELETE RESTRICT,
        FOREIGN KEY (productId) REFERENCES agricultural_products (id) ON DELETE RESTRICT
      )
    ''');
  }

  /// Insere uma nova aplicação de defensivo no banco de dados
  Future<String> insert(PesticideApplication application) async {
    final db = await _database.database;
    
    // Preparar o mapa para inserção
    final Map<String, dynamic> applicationMap = application.toMap();
    
    // Converter a lista de URLs de imagens para JSON se existir
    if (applicationMap['imageUrls'] != null) {
      applicationMap['imageUrls'] = application.imageUrls != null && application.imageUrls!.isNotEmpty
          ? application.imageUrls!.join('|') // Usar separador para facilitar a recuperação
          : null;
    }
    
    await db.insert(_tableName, applicationMap);
    return application.id ?? '';
  }
  
  /// Insere uma nova aplicação de defensivo no banco de dados (alias para insert)
  Future<String> insertPesticideApplication(PesticideApplication application) async {
    return await insert(application);
  }

  /// Atualiza uma aplicação de defensivo existente
  Future<int> update(PesticideApplication application) async {
    final db = await _database.database;
    
    // Preparar o mapa para atualização
    final Map<String, dynamic> applicationMap = application.toMap();
    
    // Converter a lista de URLs de imagens para JSON se existir
    if (applicationMap['imageUrls'] != null) {
      applicationMap['imageUrls'] = application.imageUrls != null && application.imageUrls!.isNotEmpty
          ? application.imageUrls!.join('|') // Usar separador para facilitar a recuperação
          : null;
    }
    
    return await db.update(
      _tableName,
      applicationMap,
      where: 'id = ?',
      whereArgs: [application.id],
    );
  }
  
  /// Atualiza uma aplicação de defensivo existente (alias para update)
  Future<int> updatePesticideApplication(PesticideApplication application) async {
    return await update(application);
  }

  /// Exclui uma aplicação de defensivo
  Future<int> delete(String id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Exclui uma aplicação de defensivo (alias para delete)
  Future<int> deletePesticideApplication(String id) async {
    return await delete(id);
  }

  /// Método alias para deleteApplication
  Future<int> deleteApplication(String id) async {
    return await delete(id);
  }

  /// Método auxiliar para processar URLs de imagens em mapas do banco de dados
  void _processImageUrls(List<Map<String, dynamic>> maps) {
    for (var map in maps) {
      if (map['imageUrls'] != null && map['imageUrls'] is String) {
        final String imageUrlsStr = map['imageUrls'];
        if (imageUrlsStr.isNotEmpty) {
          map['imageUrls'] = imageUrlsStr.split('|');
        } else {
          map['imageUrls'] = <String>[];
        }
      }
    }
  }
  
  /// Obtém todas as aplicações de defensivos
  Future<List<PesticideApplication>> getAll() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    
    // Processar URLs de imagens
    _processImageUrls(maps);
    
    List<PesticideApplication> applications = [];
    
    for (var map in maps) {
      // Buscar informações adicionais
      final plot = await _plotRepository.getById(map['plotId']);
      final crop = map['cropId'] != null ? await _cropRepository.getById(int.parse(map['cropId'])) : null;
      final product = await _productRepository.getById(map['productId']);
      
      applications.add(PesticideApplication.fromMap(map).copyWith(
        cropName: crop?.name,
        productName: product?.name,
      ));
    }
    
    return applications;
  }
  
  /// Obtém todas as aplicações de defensivos (alias para getAll)
  Future<List<PesticideApplication>> getAllPesticideApplications() async {
    return await getAll();
  }

  /// Obtém todas as aplicações de defensivos
  Future<List<PesticideApplication>> getAllApplications() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName, orderBy: 'applicationDate DESC');
    
    // Processar URLs de imagens
    _processImageUrls(maps);
    
    return List.generate(maps.length, (i) {
      return PesticideApplication.fromMap(maps[i]);
    });
  }

  /// Obtém uma aplicação de defensivo pelo ID
  Future<PesticideApplication?> getById(String id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }
    
    // Processar URLs de imagens
    _processImageUrls(maps);

    final map = maps.first;
    
    // Buscar informações adicionais
    final plot = await _plotRepository.getById(map['plotId']);
    final crop = map['cropId'] != null ? await _cropRepository.getById(int.parse(map['cropId'])) : null;
    final product = await _productRepository.getById(map['productId']);
    
    return PesticideApplication.fromMap(map).copyWith(
      cropName: crop?.name,
      productName: product?.name,
    );
  }
  
  /// Obtém uma aplicação de defensivo pelo ID (alias para getById)
  Future<PesticideApplication?> getPesticideApplicationById(String id) async {
    return await getById(id);
  }

  /// Busca todas as aplicações por ID do talhão
  Future<List<PesticideApplication>> getByPlotId(String plotId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'plotId = ?',
      whereArgs: [plotId],
    );
    
    // Processar URLs de imagens
    _processImageUrls(maps);
    
    return List.generate(maps.length, (i) => PesticideApplication.fromMap(maps[i]));
  }
  
  /// Alias para getByPlotId() - usado nas telas de relatório
  Future<List<PesticideApplication>> getApplicationsByPlotId(String plotId) async {
    return getByPlotId(plotId);
  }

  /// Busca as aplicações mais recentes
  Future<List<PesticideApplication>> getRecentApplications({int limit = 5}) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'date DESC',
      limit: limit,
    );
    
    // Processar URLs de imagens
    _processImageUrls(maps);
    
    return List.generate(maps.length, (i) => PesticideApplication.fromMap(maps[i]));
  }

  /// Busca todas as aplicações por ID da cultura
  Future<List<PesticideApplication>> getByCropId(String cropId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'cropId = ?',
      whereArgs: [int.parse(cropId)],
    );
    
    // Processar URLs de imagens
    _processImageUrls(maps);
    
    return List.generate(maps.length, (i) => PesticideApplication.fromMap(maps[i]));
  }

  /// Busca todas as aplicações por ID do produto
  Future<List<PesticideApplication>> getByProductId(String productId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'productId = ?',
      whereArgs: [productId],
    );
    
    // Processar URLs de imagens
    _processImageUrls(maps);
    
    return List.generate(maps.length, (i) => PesticideApplication.fromMap(maps[i]));
  }

  /// Busca as aplicações pendentes de sincronização
  Future<List<PesticideApplication>> getPendingSync() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    
    // Processar URLs de imagens
    _processImageUrls(maps);
    
    return List.generate(maps.length, (i) => PesticideApplication.fromMap(maps[i]));
  }

  /// Marca uma aplicação de defensivo como sincronizada
  Future<int> markAsSynced(String id) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca a contagem total de aplicações de defensivos
  Future<int> count() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Deduz a quantidade do produto do estoque
  Future<void> _deductProductFromInventory(PesticideApplication application) async {
    try {
      // Verifica se o productId existe
      if (application.productId == null) return;
      
      // Busca informações do produto agrícola
      final product = await _productRepository.getById(application.productId!);
      if (product == null) return;
      
      // Busca o produto no estoque pelo nome
      final inventoryItems = await _inventoryRepository.getItemsByName(product.name, product.formulation ?? '');
      if (inventoryItems.isEmpty) return;
      
      // Usa o primeiro item encontrado
      final inventoryItem = inventoryItems.first;
      
      // Calcula a quantidade total do produto a ser deduzida
      final totalProductAmount = application.calculateTotalProductAmount();
      
      // Busca informações do talhão e cultura para o registro da movimentação
      final plot = await _plotRepository.getById(application.plotId);
      final crop = application.cropId != null ? await _cropRepository.getById(int.parse(application.cropId!)) : null;
      
      String plotName = 'Talhão não identificado';
      String cropName = 'Cultura não identificada';
      
      if (plot != null) plotName = plot.name;
      if (crop != null) cropName = crop.name;
      
      // Cria a finalidade da movimentação
      final purpose = 'Aplicação no Talhão ${plotName} - ${cropName}';
      
      // Registra a saída no estoque
      await _inventoryRepository.updateQuantity(
        inventoryItem.id!.toString(), 
        -totalProductAmount, 
        purpose,
        activityId: application.id,
        notes: 'Responsável: ${application.responsiblePerson}'
      );
      
      // Registra a movimentação detalhada
      final movement = InventoryMovement(
        inventoryItemId: inventoryItem.id!.toString(),
        type: MovementType.exit,
        quantity: totalProductAmount,
        purpose: purpose,
        responsiblePerson: application.responsiblePerson ?? 'Não informado',
        date: application.date,
        relatedDocumentId: application.id,
        relatedDocumentType: 'Aplicação de Defensivo',
      );
      
      await _movementRepository.addMovement(movement);
      
    } catch (e) {
      print('Erro ao deduzir produto do estoque: $e');
      rethrow;
    }
  }
  
  /// Estorna a quantidade do produto ao estoque
  Future<void> _returnProductToInventory(PesticideApplication application) async {
    try {
      // Verifica se o productId existe
      if (application.productId == null) return;
      
      // Busca informações do produto agrícola
      final product = await _productRepository.getById(application.productId!);
      if (product == null) return;
      
      // Busca o produto no estoque pelo nome
      final inventoryItems = await _inventoryRepository.getItemsByName(product.name, product.formulation ?? '');
      if (inventoryItems.isEmpty) return;
      
      // Usa o primeiro item encontrado
      final inventoryItem = inventoryItems.first;
      
      // Calcula a quantidade total do produto a ser estornada
      final totalProductAmount = application.calculateTotalProductAmount();
      
      // Busca informações do talhão e cultura para o registro da movimentação
      final plot = await _plotRepository.getById(application.plotId);
      final crop = application.cropId != null ? await _cropRepository.getById(int.parse(application.cropId!)) : null;
      
      String plotName = 'Talhão não identificado';
      String cropName = 'Cultura não identificada';
      
      if (plot != null) plotName = plot.name;
      if (crop != null) cropName = crop.name;
      
      // Cria a finalidade da movimentação
      final purpose = 'Estorno de Aplicação - Talhão ${plotName} - ${cropName}';
      
      // Registra a entrada no estoque (estorno)
      await _inventoryRepository.updateQuantity(
        inventoryItem.id!.toString(), 
        totalProductAmount, 
        purpose,
        activityId: application.id,
        notes: 'Responsável: ${application.responsiblePerson}'
      );
      
      // Registra a movimentação detalhada
      final movement = InventoryMovement(
        inventoryItemId: inventoryItem.id!.toString(),
        type: MovementType.entry,
        quantity: totalProductAmount,
        purpose: purpose,
        responsiblePerson: application.responsiblePerson ?? 'Não informado',
        date: DateTime.now(),
        relatedDocumentId: application.id,
        relatedDocumentType: 'Estorno de Aplicação',
      );
      
      await _movementRepository.addMovement(movement);
      
    } catch (e) {
      print('Erro ao estornar produto ao estoque: $e');
      rethrow;
    }
  }

  /// Adiciona uma nova aplicação de defensivo com suporte ao novo modelo
  Future<String> addApplication(PesticideApplication application) async {
    final db = await _database.database;
    
    // Criar um mapa com os dados básicos da aplicação
    final Map<String, dynamic> applicationMap = {
      'id': application.id,
      'plotId': application.plotId,
      'applicationDate': application.date.toIso8601String(),
      'responsiblePerson': application.responsiblePerson ?? 'Não informado',
      'observations': application.notes ?? '',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'isSynced': 0,
      // Valores padrão para campos obrigatórios que não estão no novo modelo
      'cropId': application.cropId ?? '1', // ID padrão para cultura
      'productId': '1', // ID padrão para produto
      'dose': 0.0,
      'doseUnit': 'L/ha',
      'mixtureVolume': 0.0,
      'totalArea': 0.0,
      'applicationType': 0,
    };
    
    await db.insert(_tableName, applicationMap);
    return application.id!;
  }
  
  /// Atualiza uma aplicação de defensivo com suporte ao novo modelo
  Future<int> updateApplication(PesticideApplication application) async {
    final db = await _database.database;
    
    // Criar um mapa com os dados básicos da aplicação
    final Map<String, dynamic> applicationMap = {
      'plotId': application.plotId,
      'applicationDate': application.date.toIso8601String(),
      'responsiblePerson': application.responsiblePerson ?? 'Não informado',
      'observations': application.notes ?? '',
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    return await db.update(
      _tableName,
      applicationMap,
      where: 'id = ?',
      whereArgs: [application.id],
    );
  }

  /// Obtém todas as aplicações de defensivos para uma cultura específica
  Future<List<PesticideApplication>> getApplicationsByCrop(String cropName) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cropName = ?',
        whereArgs: [cropName],
      );
      
      final applications = List.generate(maps.length, (i) {
        return PesticideApplication.fromMap(maps[i]);
      });
      
      return applications;
    } catch (e) {
      print('Erro ao obter aplicações por cultura: $e');
      return [];
    }
  }
}
