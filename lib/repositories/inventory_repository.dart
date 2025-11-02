import '../database/daos/inventory_dao.dart';
import '../database/daos/inventory_movement_dao.dart';
import '../database/models/inventory.dart';
import '../database/models/inventory_movement.dart';
import '../models/inventory_item.dart' as app_model;
import '../database/app_database.dart';

import '../utils/logger.dart';

class InventoryRepository {
  final InventoryDao _inventoryDao = InventoryDao();
  final InventoryMovementDao _movementDao = InventoryMovementDao();


  // Obter todos os itens de estoque
  Future<List<InventoryItem>> getAllItems() async {
    try {
      Logger.info('🔄 Carregando todos os itens de inventário...');
      final items = await _inventoryDao.getAll();
      Logger.info('✅ ${items.length} itens de inventário carregados');
      return items;
    } catch (e) {
      Logger.error('❌ Erro ao carregar itens de inventário: $e');
      return [];
    }
  }

  // Obter itens por categoria
  Future<List<InventoryItem>> getItemsByCategory(String category) async {
    return await _inventoryDao.getByCategory(category);
  }

  // Obter um item pelo ID
  Future<InventoryItem?> getItemById(dynamic id) async {
    // Converter para int se for String
    final int itemId = id is String ? int.tryParse(id) ?? 0 : id;
    return await _inventoryDao.getById(itemId);
  }
  
  // Obter itens pelo nome e formulação
  Future<List<InventoryItem>> getItemsByName(String name, String? formulation) async {
    // Obter todos os itens e filtrar manualmente
    final allItems = await getAllItems();
    
    return allItems.where((item) {
      bool nameMatches = item.name.toLowerCase() == name.toLowerCase();
      
      if (formulation != null && formulation.isNotEmpty) {
        return nameMatches && item.formulation?.toLowerCase() == formulation.toLowerCase();
      }
      
      return nameMatches;
    }).toList();
  }

  // Adicionar um novo item ao estoque
  Future<int> addItem(InventoryItem item) async {
    // Definir timestamps
    final now = DateTime.now().toIso8601String();
    item = item.copyWith(
      createdAt: now,
      updatedAt: now,
      syncStatus: 0,
    );

    // Inserir no banco de dados
    final itemId = await _inventoryDao.insert(item);
    
    // Registrar movimento inicial de estoque
    if (itemId > 0 && item.quantity > 0) {
      await _registerInventoryMovement(
        itemId: itemId,
        quantity: item.quantity,
        previousQuantity: 0,
        newQuantity: item.quantity,
        reason: 'Estoque inicial',
      );
    }
    
    return itemId;
  }

  // Atualizar um item existente
  Future<bool> updateItem(InventoryItem item) async {
    // Obter o item atual para comparar quantidades
    final currentItem = await _inventoryDao.getById(item.id!);
    
    // Atualizar timestamp
    item = item.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
      syncStatus: 0,
    );

    // Atualizar no banco de dados
    final result = await _inventoryDao.update(item);
    
    // Registrar movimento de estoque se a quantidade mudou
    if (result > 0 && currentItem != null && currentItem.quantity != item.quantity) {
      await _registerInventoryMovement(
        itemId: item.id!,
        quantity: item.quantity - currentItem.quantity,
        previousQuantity: currentItem.quantity,
        newQuantity: item.quantity,
        reason: 'Ajuste de estoque',
      );
    }
    
    return result > 0;
  }

  // Excluir um item
  Future<bool> deleteItem(int id) async {
    final result = await _inventoryDao.delete(id);
    return result > 0;
  }

  // Atualizar a quantidade de um item (adicionar ou remover)
  Future<bool> updateQuantity(String id, double quantityChange, String reason, {String? activityId, String? notes}) async {
    try {
      // Obter o item atual
      final item = await _inventoryDao.getById(int.parse(id));
      if (item == null) {
        return false;
      }

      // Calcular nova quantidade
      final newQuantity = item.quantity + quantityChange;
      if (newQuantity < 0) {
        return false; // Não permitir quantidade negativa
      }

      // Atualizar o item
      final updatedItem = item.copyWith(
        quantity: newQuantity,
        updatedAt: DateTime.now().toIso8601String(),
        syncStatus: 0,
      );

      // Salvar no banco de dados
      final result = await _inventoryDao.update(updatedItem);

      // Registrar a movimentação de estoque
      if (result > 0) {
        await _registerInventoryMovement(
          itemId: item.id!,
          quantity: quantityChange,
          previousQuantity: item.quantity,
          newQuantity: newQuantity,
          reason: reason,
          activityId: activityId,
          notes: notes,
        );
      }

      return result > 0;
    } catch (e) {
      print('Erro ao atualizar quantidade: $e');
      return false;
    }
  }

  // Registrar movimentação de estoque
  Future<int> _registerInventoryMovement({
    required int itemId,
    required double quantity,
    required double previousQuantity,
    required double newQuantity,
    required String reason,
    String? activityId,
    String? notes,
  }) async {
    try {
      final movement = InventoryMovement(
        itemId: itemId,
        quantity: quantity,
        previousQuantity: previousQuantity,
        newQuantity: newQuantity,
        reason: reason,
        activityId: activityId,
        notes: notes,
        createdAt: DateTime.now().toIso8601String(),
      );
      
      return await _movementDao.insert(movement);
    } catch (e) {
      print('Erro ao registrar movimentação de estoque: $e');
      return -1;
    }
  }

  // Obter histórico de movimentações de um item
  Future<List<InventoryMovement>> getItemMovementHistory(int itemId) async {
    return await _movementDao.getByItemId(itemId);
  }
  
  // Obter itens com estoque crítico
  Future<List<app_model.InventoryItem>> getCriticalStockItems() async {
    final allDbItems = await getAllItems();
    final criticalItems = allDbItems.where((item) => item.quantity <= (item.minimumLevel ?? 0)).toList();
    
    // Converter de modelo de banco de dados para modelo de aplicação
    return criticalItems.map((dbItem) => app_model.InventoryItem(
      id: dbItem.id?.toString(),
      name: dbItem.name,
      type: dbItem.type ?? 'Não especificado',
      formulation: dbItem.formulation ?? 'Não especificado',
      unit: dbItem.unit,
      quantity: dbItem.quantity,
      location: dbItem.location ?? 'Não especificado',
      expirationDate: dbItem.expirationDate != null ? DateTime.tryParse(dbItem.expirationDate!) : null,
      manufacturer: dbItem.manufacturer,
      minimumLevel: dbItem.minimumLevel,
      registrationNumber: dbItem.registrationNumber,
      pdfPath: dbItem.pdfPath,
      syncStatus: dbItem.syncStatus,
      category: dbItem.category,
      createdAt: DateTime.tryParse(dbItem.createdAt),
      updatedAt: DateTime.tryParse(dbItem.updatedAt),
    )).toList();
  }

  // Verificar itens com estoque baixo
  Future<List<InventoryItem>> getLowStockItems(double threshold) async {
    return await _inventoryDao.getLowStock(threshold);
  }

  // Obter valor total do estoque
  Future<double> getTotalStockValue() async {
    final items = await _inventoryDao.getAll();
    double total = 0;
    for (final item in items) {
      total += item.quantity * (item.unitPrice ?? 0);
    }
    return total;
  }
  
  /// Atualiza o status do inventário com dados recebidos da API
  Future<bool> updateInventoryStatus(List<dynamic> inventoryData) async {
    try {
      // Usar métodos DAO existentes para atualizar os dados
      for (final itemData in inventoryData) {
        final itemId = itemData['id'];
        final int intItemId = itemId is String ? int.tryParse(itemId) ?? 0 : itemId;
        
        if (intItemId <= 0) continue; // Pular se ID inválido
        
        // Verificar se o item existe
        final existingItem = await _inventoryDao.getById(intItemId);
        
        if (existingItem != null) {
          // Atualizar item existente
          final double newQuantity = (itemData['quantity'] ?? existingItem.quantity).toDouble();
          final double? minimumLevel = (itemData['minimum_level'] ?? existingItem.minimumLevel)?.toDouble();
          final String? location = itemData['location'] ?? existingItem.location;
          final String? expirationDate = itemData['expiration_date'] ?? existingItem.expirationDate;
          
          // Registrar movimentação se a quantidade mudou
          if (newQuantity != existingItem.quantity) {
            await _registerInventoryMovement(
              itemId: intItemId,
              quantity: newQuantity - existingItem.quantity,
              previousQuantity: existingItem.quantity,
              newQuantity: newQuantity,
              reason: 'Atualização via sincronização',
              notes: 'Quantidade atualizada durante sincronização com o servidor',
            );
          }
          
          // Atualizar o item usando o DAO
          final updatedItem = existingItem.copyWith(
            quantity: newQuantity,
            minimumLevel: minimumLevel,
            location: location,
            expirationDate: expirationDate,
            updatedAt: DateTime.now().toIso8601String(),
            syncStatus: 1,
          );
          
          await _inventoryDao.update(updatedItem);
        } else {
          // Item não existe, criar novo
          final newItem = InventoryItem(
            id: intItemId,
            name: itemData['name'] ?? 'Item desconhecido',
            unit: itemData['unit'] ?? 'unid',
            quantity: (itemData['quantity'] ?? 0).toDouble(),
            type: itemData['type'] ?? 'Não especificado',
            category: itemData['category'] ?? 'Geral',
            formulation: itemData['formulation'],
            manufacturer: itemData['manufacturer'],
            minimumLevel: (itemData['minimum_level'])?.toDouble(),
            location: itemData['location'],
            expirationDate: itemData['expiration_date'],
            registrationNumber: itemData['registration_number'],
            unitPrice: (itemData['unit_price'])?.toDouble(),
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            syncStatus: 1,
          );
          
          final newItemId = await _inventoryDao.insert(newItem);
          
          // Registrar movimentação inicial
          if (newItemId > 0) {
            await _registerInventoryMovement(
              itemId: intItemId,
              quantity: newItem.quantity,
              previousQuantity: 0,
              newQuantity: newItem.quantity,
              reason: 'Criação via sincronização',
              notes: 'Item criado durante sincronização com o servidor',
            );
          }
        }
      }
      
      print('Status do inventário atualizado com sucesso');
      return true;
    } catch (e) {
      print('Erro ao atualizar status do inventário: $e');
      return false;
    }
  }
}
