import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../database/app_database.dart';
import '../models/inventory_transaction_model.dart';
import '../models/inventory_product_model.dart';
import '../repositories/inventory_transaction_repository.dart';
import '../repositories/inventory_product_repository.dart';
import './inventory_cache_service.dart';
import '../../../utils/logger.dart';

/// Serviço para operações de transações no estoque
class InventoryServiceTransactions {
  final InventoryTransactionRepository _transactionRepository = InventoryTransactionRepository();
  final InventoryProductRepository _productRepository = InventoryProductRepository();
  final InventoryCacheService _cacheService = InventoryCacheService();

  /// Obtém todas as transações
  Future<List<InventoryTransactionModel>> getAllTransactions() async {
    try {
      return await _transactionRepository.getAll();
    } catch (e) {
      Logger.error('Erro ao obter todas as transações: $e');
      return [];
    }
  }

  /// Obtém transações paginadas
  Future<List<InventoryTransactionModel>> getTransactionsPaginated({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      return await _transactionRepository.getPaginated(
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
      );
    } catch (e) {
      Logger.error('Erro ao obter transações paginadas: $e');
      return [];
    }
  }

  /// Obtém transações por tipo
  Future<List<InventoryTransactionModel>> getTransactionsByType(String type) async {
    try {
      return await _transactionRepository.getByType(type);
    } catch (e) {
      Logger.error('Erro ao obter transações por tipo: $e');
      return [];
    }
  }

  /// Obtém transações de um produto específico
  Future<List<InventoryTransactionModel>> getTransactionsByProduct(String productId) async {
    try {
      return await _transactionRepository.getByProductId(productId);
    } catch (e) {
      Logger.error('Erro ao obter transações por produto: $e');
      return [];
    }
  }

  /// Obtém transações filtradas
  Future<List<InventoryTransactionModel>> getFilteredTransactions({
    String? productId,
    String? transactionType,
    String? batchNumber,
    String? applicationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _transactionRepository.getFiltered(
        productId: productId,
        transactionType: transactionType,
        batchNumber: batchNumber,
        applicationId: applicationId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      Logger.error('Erro ao obter transações filtradas: $e');
      return [];
    }
  }

  /// Obtém a contagem total de transações
  Future<int> getTransactionsCount() async {
    try {
      final transactions = await _transactionRepository.getAll();
      return transactions.length;
    } catch (e) {
      Logger.error('Erro ao obter contagem de transações: $e');
      return 0;
    }
  }

  /// Obtém a contagem de transações com filtros
  Future<int> getFilteredTransactionsCount({
    String? productId,
    String? transactionType,
    String? batchNumber,
    String? applicationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await _transactionRepository.getFiltered(
        productId: productId,
        transactionType: transactionType,
        batchNumber: batchNumber,
        applicationId: applicationId,
        startDate: startDate,
        endDate: endDate,
      );
      return transactions.length;
    } catch (e) {
      Logger.error('Erro ao obter contagem filtrada de transações: $e');
      return 0;
    }
  }

  /// Obtém o total de entradas de um produto
  Future<double> getTotalEntries(String productId) async {
    try {
      final transactions = await _transactionRepository.getByProductId(productId);
      double total = 0.0;
      for (var transaction in transactions) {
        if (transaction.type == TransactionType.entry) {
          total += transaction.quantity;
        }
      }
      return total;
    } catch (e) {
      Logger.error('Erro ao obter total de entradas: $e');
      return 0.0;
    }
  }

  /// Obtém o total de saídas de um produto
  Future<double> getTotalExits(String productId) async {
    try {
      final transactions = await _transactionRepository.getByProductId(productId);
      double total = 0.0;
      for (var transaction in transactions) {
        if (transaction.type == TransactionType.manual) {
          total += transaction.quantity;
        }
      }
      return total;
    } catch (e) {
      Logger.error('Erro ao obter total de saídas: $e');
      return 0.0;
    }
  }

  /// Obtém o total de saídas por aplicação de um produto
  Future<double> getTotalApplicationExits(String productId) async {
    try {
      final transactions = await _transactionRepository.getByProductId(productId);
      double total = 0.0;
      for (var transaction in transactions) {
        if (transaction.type == TransactionType.application) {
          total += transaction.quantity;
        }
      }
      return total;
    } catch (e) {
      Logger.error('Erro ao obter total de saídas por aplicação: $e');
      return 0.0;
    }
  }

  /// Registra uma entrada no estoque
  Future<bool> registerEntry(InventoryTransactionModel transaction) async {
    try {
      // Obter produto atual
      final product = await _productRepository.getById(transaction.productId);
      if (product == null) {
        Logger.error('Produto não encontrado: ${transaction.productId}');
        return false;
      }

      // Calcular novo estoque
      final newStock = product.quantity + transaction.quantity;

      // Atualizar produto
      final updatedProduct = product.copyWith(quantity: newStock);
      await _productRepository.update(updatedProduct);

      // Registrar transação
      await _transactionRepository.insert(transaction);

      Logger.info('Entrada registrada com sucesso');
      return true;
    } catch (e) {
      Logger.error('Erro ao registrar entrada: $e');
      return false;
    }
  }

  /// Registra uma saída no estoque
  Future<bool> registerExit(InventoryTransactionModel transaction) async {
    try {
      // Obter produto atual
      final product = await _productRepository.getById(transaction.productId);
      if (product == null) {
        Logger.error('Produto não encontrado: ${transaction.productId}');
        return false;
      }

      // Verificar se há estoque suficiente
      if (product.quantity < transaction.quantity) {
        Logger.error('Estoque insuficiente: ${product.quantity} < ${transaction.quantity}');
        return false;
      }

      // Calcular novo estoque
      final newStock = product.quantity - transaction.quantity;

      // Atualizar produto
      final updatedProduct = product.copyWith(quantity: newStock);
      await _productRepository.update(updatedProduct);

      // Registrar transação
      await _transactionRepository.insert(transaction);

      Logger.info('Saída registrada com sucesso');
      return true;
    } catch (e) {
      Logger.error('Erro ao registrar saída: $e');
      return false;
    }
  }
}
