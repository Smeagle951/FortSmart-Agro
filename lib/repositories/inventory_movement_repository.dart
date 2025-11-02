import '../database/daos/inventory_movement_dao.dart';
import '../database/models/inventory_movement.dart' as DbModel;
import '../models/inventory_movement.dart';

class InventoryMovementRepository {
  final InventoryMovementDao _movementDao = InventoryMovementDao();

  // Obter todos os movimentos de estoque
  Future<List<InventoryMovement>> getAllMovements() async {
    final dbMovements = await _movementDao.getAll();
    return dbMovements.map((dbMovement) => InventoryMovement.fromDbModel(dbMovement)).toList();
  }

  // Obter movimentos por item de estoque
  Future<List<InventoryMovement>> getMovementsByItemId(int itemId) async {
    final dbMovements = await _movementDao.getByItemId(itemId);
    return dbMovements.map((dbMovement) => InventoryMovement.fromDbModel(dbMovement)).toList();
  }

  // Obter movimentos por atividade
  Future<List<InventoryMovement>> getMovementsByActivityId(String activityId) async {
    final dbMovements = await _movementDao.getByActivityId(activityId);
    return dbMovements.map((dbMovement) => InventoryMovement.fromDbModel(dbMovement)).toList();
  }

  // Obter movimentos por intervalo de data
  Future<List<InventoryMovement>> getMovementsByDateRange(dynamic startDate, dynamic endDate) async {
    // Converter para string ISO8601 se for DateTime
    final String startDateStr = startDate is DateTime ? startDate.toIso8601String() : startDate;
    final String endDateStr = endDate is DateTime ? endDate.toIso8601String() : endDate;
    
    final dbMovements = await _movementDao.getByDateRange(startDateStr, endDateStr);
    return dbMovements.map((dbMovement) => InventoryMovement.fromDbModel(dbMovement)).toList();
  }

  // Registrar um novo movimento de estoque
  Future<int> addMovement(InventoryMovement movement) async {
    // Converter para o modelo do banco de dados
    final dbMovement = movement.toDbModel();
    
    return await _movementDao.insert(dbMovement);
  }

  // Excluir um movimento de estoque
  Future<bool> deleteMovement(int id) async {
    final result = await _movementDao.delete(id);
    return result > 0;
  }
  
  // Atualizar um movimento de estoque
  Future<bool> updateMovement(InventoryMovement movement) async {
    // Converter para o modelo do banco de dados
    final dbMovement = movement.toDbModel();
    
    // Atualiza o movimento mantendo dados importantes
    final updatedDbMovement = DbModel.InventoryMovement(
      id: dbMovement.id,
      itemId: dbMovement.itemId,
      quantity: dbMovement.quantity,
      previousQuantity: dbMovement.previousQuantity,
      newQuantity: dbMovement.newQuantity,
      reason: dbMovement.reason,
      activityId: dbMovement.activityId,
      notes: dbMovement.notes,
      createdAt: dbMovement.createdAt,
      syncStatus: 0, // Marcar para sincronização
      remoteId: dbMovement.remoteId,
      date: dbMovement.date,
    );
    
    final result = await _movementDao.update(updatedDbMovement);
    return result > 0;
  }

  // Obter movimentos pendentes de sincronização
  Future<List<InventoryMovement>> getPendingSyncMovements() async {
    final dbMovements = await _movementDao.getPendingSync();
    return dbMovements.map((dbMovement) => InventoryMovement.fromDbModel(dbMovement)).toList();
  }

  // Atualizar status de sincronização
  Future<bool> updateSyncStatus(int id, int syncStatus, int? remoteId) async {
    final result = await _movementDao.updateSyncStatus(id, syncStatus, remoteId);
    return result > 0;
  }

  // Gerar relatório de movimentação por categoria
  Future<Map<String, double>> generateMovementReportByReason(DateTime startDate, DateTime endDate) async {
    final movements = await getMovementsByDateRange(startDate, endDate);
    
    final Map<String, double> report = {};
    
    for (final movement in movements) {
      if (report.containsKey(movement.purpose)) {
        report[movement.purpose] = report[movement.purpose]! + movement.quantity;
      } else {
        report[movement.purpose] = movement.quantity;
      }
    }
    
    return report;
  }
}
