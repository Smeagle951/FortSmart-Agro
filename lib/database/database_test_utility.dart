import 'package:flutter/material.dart';
import 'app_database.dart';
import 'database_helper.dart';
import 'plot_database_repair.dart';
import 'daos/plot_dao.dart';
import '../models/plot.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Utilitário para testar a integridade do banco de dados e da tabela de talhões
class DatabaseTestUtility {
  final AppDatabase _appDatabase = AppDatabase();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final PlotDatabaseRepair _plotDatabaseRepair = PlotDatabaseRepair();
  final PlotDao _plotDao = PlotDao();
  final _uuid = const Uuid();
  
  /// Executa uma série de testes para verificar a integridade do banco de dados
  Future<Map<String, dynamic>> runDatabaseTests() async {
    final results = {
      'success': false,
      'tests': <Map<String, dynamic>>[],
      'overallStatus': 'Falha',
    };
    
    try {
      debugPrint('🧪 Iniciando testes de banco de dados');
      
      // Teste 1: Verificar conexão com o banco de dados
      final test1 = await _testDatabaseConnection();
      results['tests'] = [...(results['tests'] as List<Map<String, dynamic>>), test1];
      
      // Teste 2: Verificar saúde do banco de dados
      final test2 = await _testDatabaseHealth();
      results['tests'] = [...(results['tests'] as List<Map<String, dynamic>>), test2];
      
      // Teste 3: Verificar tabela de talhões
      final test3 = await _testPlotTable();
      results['tests'] = [...(results['tests'] as List<Map<String, dynamic>>), test3];
      
      // Teste 4: Inserir e recuperar um talhão
      final test4 = await _testPlotInsertAndRetrieve();
      results['tests'] = [...(results['tests'] as List<Map<String, dynamic>>), test4];
      
      // Teste 5: Atualizar um talhão
      final test5 = await _testPlotUpdate();
      results['tests'] = [...(results['tests'] as List<Map<String, dynamic>>), test5];
      
      // Teste 6: Excluir um talhão
      final test6 = await _testPlotDelete();
      results['tests'] = [...(results['tests'] as List<Map<String, dynamic>>), test6];
      
      // Calcula o resultado geral
      final testsList = results['tests'] as List<Map<String, dynamic>>;
      final failedTests = testsList.where((t) => !t['passed']).length;
      results['success'] = failedTests == 0;
      results['overallStatus'] = failedTests == 0 ? 'Sucesso' : 'Falha ($failedTests testes falharam)';
      
      debugPrint('🏁 Testes concluídos: ${results['overallStatus']}');
      return results;
    } catch (e) {
      debugPrint('❌ Erro durante a execução dos testes: $e');
      results['overallStatus'] = 'Erro: $e';
      return results;
    }
  }
  
  /// Teste 1: Verificar conexão com o banco de dados
  Future<Map<String, dynamic>> _testDatabaseConnection() async {
    final result = {
      'name': 'Conexão com o banco de dados',
      'passed': false,
      'message': '',
    };
    
    try {
      final db = await _appDatabase.database;
      final isOpen = db.isOpen;
      result['passed'] = isOpen;
      result['message'] = isOpen 
          ? 'Conexão estabelecida com sucesso' 
          : 'Não foi possível estabelecer conexão';
    } catch (e) {
      result['message'] = 'Erro ao conectar: $e';
    }
    
    return result;
  }
  
  /// Teste 2: Verificar saúde do banco de dados
  Future<Map<String, dynamic>> _testDatabaseHealth() async {
    final result = {
      'name': 'Saúde do banco de dados',
      'passed': false,
      'message': '',
    };
    
    try {
      final isHealthy = await _databaseHelper.checkDatabaseHealth();
      result['passed'] = isHealthy;
      result['message'] = isHealthy 
          ? 'Banco de dados está saudável' 
          : 'Banco de dados apresenta problemas';
    } catch (e) {
      result['message'] = 'Erro ao verificar saúde: $e';
    }
    
    return result;
  }
  
  /// Teste 3: Verificar tabela de talhões
  Future<Map<String, dynamic>> _testPlotTable() async {
    final result = {
      'name': 'Tabela de talhões',
      'passed': false,
      'message': '',
    };
    
    try {
      final health = await _plotDatabaseRepair.checkPlotTableHealth();
      result['passed'] = health['tableExists'] && health['structureCorrect'];
      
      if (!health['tableExists']) {
        result['message'] = 'Tabela de talhões não existe';
      } else if (!health['structureCorrect']) {
        result['message'] = 'Estrutura da tabela de talhões incorreta';
      } else if ((health['issues'] as List).isNotEmpty) {
        result['message'] = 'Tabela existe mas apresenta problemas: ${(health['issues'] as List).join(', ')}';
        result['passed'] = false;
      } else {
        result['message'] = 'Tabela de talhões OK com ${health['recordCount']} registros';
      }
    } catch (e) {
      result['message'] = 'Erro ao verificar tabela: $e';
    }
    
    return result;
  }
  
  /// Teste 4: Inserir e recuperar um talhão
  Future<Map<String, dynamic>> _testPlotInsertAndRetrieve() async {
    final result = {
      'name': 'Inserir e recuperar talhão',
      'passed': false,
      'message': '',
    };
    
    try {
      // Cria um talhão de teste
      final testId = 'test_${_uuid.v4()}';
      final now = DateTime.now().toIso8601String();
      final testPlot = Plot(
        id: testId,
        name: 'Talhão de Teste',
        area: 10.5,
        propertyId: 1,
        farmId: 1,
        createdAt: now,
        updatedAt: now,
        polygonJson: jsonEncode([
          {'latitude': -15.123, 'longitude': -47.456},
          {'latitude': -15.124, 'longitude': -47.456},
          {'latitude': -15.124, 'longitude': -47.457},
          {'latitude': -15.123, 'longitude': -47.457},
        ]),
      );
      
      // Insere o talhão
      final insertedId = await _plotDao.insert(testPlot);
      if (insertedId == null) {
        result['message'] = 'Falha ao inserir talhão de teste';
        return result;
      }
      
      // Recupera o talhão
      final retrievedPlot = await _plotDao.getById(testId);
      if (retrievedPlot == null) {
        result['message'] = 'Talhão inserido mas não foi possível recuperá-lo';
        return result;
      }
      
      // Verifica se os dados estão corretos
      final dataCorrect = 
          retrievedPlot.id == testId &&
          retrievedPlot.name == 'Talhão de Teste' &&
          retrievedPlot.area == 10.5;
      
      result['passed'] = dataCorrect;
      result['message'] = dataCorrect 
          ? 'Talhão inserido e recuperado com sucesso' 
          : 'Dados do talhão recuperado não correspondem aos inseridos';
      
      // Limpa o talhão de teste
      await _plotDao.delete(testId);
    } catch (e) {
      result['message'] = 'Erro durante o teste: $e';
    }
    
    return result;
  }
  
  /// Teste 5: Atualizar um talhão
  Future<Map<String, dynamic>> _testPlotUpdate() async {
    final result = {
      'name': 'Atualizar talhão',
      'passed': false,
      'message': '',
    };
    
    try {
      // Cria um talhão de teste
      final testId = 'test_${_uuid.v4()}';
      final now = DateTime.now().toIso8601String();
      final testPlot = Plot(
        id: testId,
        name: 'Talhão Original',
        area: 10.5,
        propertyId: 1,
        farmId: 1,
        createdAt: now,
        updatedAt: now,
        polygonJson: jsonEncode([
          {'latitude': -15.123, 'longitude': -47.456},
          {'latitude': -15.124, 'longitude': -47.456},
          {'latitude': -15.124, 'longitude': -47.457},
          {'latitude': -15.123, 'longitude': -47.457},
        ]),
      );
      
      // Insere o talhão
      await _plotDao.insert(testPlot);
      
      // Atualiza o talhão
      final updatedPlot = Plot(
        id: testId,
        name: 'Talhão Atualizado',
        area: 12.5,
        propertyId: 1,
        farmId: 1,
        createdAt: now,
        updatedAt: DateTime.now().toIso8601String(),
        polygonJson: testPlot.polygonJson,
      );
      
      final updateSuccess = await _plotDao.update(updatedPlot);
      if (!updateSuccess) {
        result['message'] = 'Falha ao atualizar talhão';
        await _plotDao.delete(testId);
        return result;
      }
      
      // Recupera o talhão atualizado
      final retrievedPlot = await _plotDao.getById(testId);
      if (retrievedPlot == null) {
        result['message'] = 'Talhão não encontrado após atualização';
        return result;
      }
      
      // Verifica se os dados foram atualizados corretamente
      final dataCorrect = 
          retrievedPlot.name == 'Talhão Atualizado' &&
          retrievedPlot.area == 12.5;
      
      result['passed'] = dataCorrect;
      result['message'] = dataCorrect 
          ? 'Talhão atualizado com sucesso' 
          : 'Dados do talhão não foram atualizados corretamente';
      
      // Limpa o talhão de teste
      await _plotDao.delete(testId);
    } catch (e) {
      result['message'] = 'Erro durante o teste: $e';
    }
    
    return result;
  }
  
  /// Teste 6: Excluir um talhão
  Future<Map<String, dynamic>> _testPlotDelete() async {
    final result = {
      'name': 'Excluir talhão',
      'passed': false,
      'message': '',
    };
    
    try {
      // Cria um talhão de teste
      final testId = 'test_${_uuid.v4()}';
      final now = DateTime.now().toIso8601String();
      final testPlot = Plot(
        id: testId,
        name: 'Talhão para Exclusão',
        area: 10.5,
        propertyId: 1,
        farmId: 1,
        createdAt: now,
        updatedAt: now,
        polygonJson: jsonEncode([
          {'latitude': -15.123, 'longitude': -47.456},
          {'latitude': -15.124, 'longitude': -47.456},
          {'latitude': -15.124, 'longitude': -47.457},
          {'latitude': -15.123, 'longitude': -47.457},
        ]),
      );
      
      // Insere o talhão
      await _plotDao.insert(testPlot);
      
      // Exclui o talhão
      final deleteSuccess = await _plotDao.delete(testId);
      if (!deleteSuccess) {
        result['message'] = 'Falha ao excluir talhão';
        return result;
      }
      
      // Verifica se o talhão foi excluído
      final retrievedPlot = await _plotDao.getById(testId);
      result['passed'] = retrievedPlot == null;
      result['message'] = retrievedPlot == null 
          ? 'Talhão excluído com sucesso' 
          : 'Talhão ainda existe após tentativa de exclusão';
    } catch (e) {
      result['message'] = 'Erro durante o teste: $e';
    }
    
    return result;
  }
}
