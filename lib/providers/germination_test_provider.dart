/// 🌱 Provider Simplificado de Teste de Germinação
/// Versão limpa sem dependências complexas

import 'package:flutter/foundation.dart';
import '../screens/plantio/submods/germination_test/models/germination_test_model.dart';
import '../screens/plantio/submods/germination_test/database/daos/germination_test_dao.dart';
import '../screens/plantio/submods/germination_test/database/daos/germination_daily_record_dao.dart';
import '../screens/plantio/submods/germination_test/database/daos/germination_subtest_dao.dart';

class GerminationTestProvider with ChangeNotifier {
  GerminationTestDao? _testDao;
  GerminationDailyRecordDao? _recordDao;
  GerminationSubtestDao? _subtestDao;
  
  List<GerminationTest> _tests = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _statistics = {};
  
  GerminationTestProvider(dynamic database) {
    _initializeDatabase(database);
  }
  
  Future<void> _initializeDatabase(dynamic database) async {
    try {
      if (database != null) {
        final db = await database.database;
        _testDao = GerminationTestDao(db);
        _recordDao = GerminationDailyRecordDao(db);
        _subtestDao = GerminationSubtestDao(db);
        print('✅ DAOs de Germinação inicializados com sucesso');
      }
      } catch (e) {
      _setError('Erro ao inicializar banco de dados: $e');
      print('❌ Erro ao inicializar DAOs de Germinação: $e');
    }
  }
  
  /// Verifica se o provider está pronto para uso
  bool get isReady => _testDao != null && _recordDao != null && _subtestDao != null;
  
  /// Aguarda a inicialização do provider
  Future<void> ensureInitialized() async {
    if (!isReady) {
      // Aguardar um pouco mais se ainda não estiver pronto
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Getters
  List<GerminationTest> get tests => _tests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  Map<String, dynamic> get statistics => _statistics;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> loadTests() async {
    if (_testDao == null) return;
    
    try {
    _setLoading(true);
      _error = null;
      
      _tests = await _testDao!.findAll();
      await _calculateStatistics();
      
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao carregar testes: $e');
    }
  }
  
  Future<void> _calculateStatistics() async {
    if (_tests.isEmpty) {
      _statistics = {
        'activeTests': 0,
        'completedTests': 0,
        'cancelledTests': 0,
        'averageGermination': 0.0,
      };
      return;
    }
    
    _statistics = {
      'activeTests': _tests.where((t) => t.status == 'active').length,
      'completedTests': _tests.where((t) => t.status == 'completed').length,
      'cancelledTests': _tests.where((t) => t.status == 'cancelled').length,
      'averageGermination': _calculateAverageGermination(),
    };
  }
  
  double _calculateAverageGermination() {
    final testsWithResults = _tests.where((t) => t.finalGerminationPercentage != null).toList();
    if (testsWithResults.isEmpty) return 0.0;
    
    final sum = testsWithResults.fold<double>(
      0.0, 
      (prev, test) => prev + (test.finalGerminationPercentage ?? 0.0)
    );
    return sum / testsWithResults.length;
  }
  
  Future<GerminationTest?> createTest({
    required String culture,
    required String variety,
    required String seedLot,
    required int totalSeeds,
    required DateTime startDate,
    required int pureSeeds,
    required int brokenSeeds,
    required int stainedSeeds,
    required bool hasSubtests,
    required int subtestSeedCount,
    String? observations,
  }) async {
    if (_testDao == null) return null;
    
    try {
      _setLoading(true);
      
      final test = GerminationTest(
          culture: culture,
          variety: variety,
          seedLot: seedLot,
          totalSeeds: totalSeeds,
          startDate: startDate,
        pureSeeds: pureSeeds,
        brokenSeeds: brokenSeeds,
        stainedSeeds: stainedSeeds,
        hasSubtests: hasSubtests,
        subtestSeedCount: subtestSeedCount,
          observations: observations,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      
      final id = await _testDao!.insert(test);
      final createdTest = test.copyWith(id: id);
      
      _tests.insert(0, createdTest);
      await _calculateStatistics();
      
      _setLoading(false);
      return createdTest;
      
    } catch (e) {
      _setError('Erro ao criar teste: $e');
      return null;
    }
  }
  
  Future<GerminationTest?> getTestById(int id) async {
    if (_testDao == null) return null;
    
    try {
      return await _testDao!.findById(id);
    } catch (e) {
      _setError('Erro ao buscar teste: $e');
      return null;
    }
  }
  
  Future<bool> updateTest(GerminationTest test) async {
    if (_testDao == null) return false;
    
    try {
      _setLoading(true);
      
      await _testDao!.update(test);
      
      // Atualizar na lista local
      final index = _tests.indexWhere((t) => t.id == test.id);
      if (index != -1) {
        _tests[index] = test;
      }
      
      await _calculateStatistics();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao atualizar teste: $e');
      return false;
    }
  }
  
  Future<List<GerminationDailyRecord>> getDailyRecords(int testId) async {
    if (_recordDao == null) return [];
    
    try {
      return await _recordDao!.findByTestId(testId);
    } catch (e) {
      _setError('Erro ao carregar registros: $e');
      return [];
    }
  }
  
  Future<bool> deleteTest(int testId) async {
    if (_testDao == null) return false;
    
    try {
      await _testDao!.delete(testId);
      _tests.removeWhere((t) => t.id == testId);
      await _calculateStatistics();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao excluir teste: $e');
      return false;
    }
  }

  Future<bool> deleteDailyRecord(int recordId) async {
    if (_recordDao == null) return false;
    
    try {
      await _recordDao!.delete(recordId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao excluir registro: $e');
      return false;
    }
  }
  
  Future<bool> updateDailyRecord(GerminationDailyRecord record) async {
    if (_recordDao == null) return false;
    
    try {
      await _recordDao!.update(record);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao atualizar registro: $e');
      return false;
    }
  }
  
  Future<bool> createDailyRecord(GerminationDailyRecord record) async {
    if (_recordDao == null) return false;
    
    try {
      await _recordDao!.insert(record);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao criar registro: $e');
      return false;
    }
  }
}

