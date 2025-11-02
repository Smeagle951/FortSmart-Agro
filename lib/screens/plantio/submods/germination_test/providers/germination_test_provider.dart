/// 🌱 Provider para Testes de Germinação
/// 
/// Gerencia o estado dos testes de germinação seguindo
/// metodologias agronômicas (ABNT NBR 9787)

import 'package:flutter/foundation.dart';
import '../models/germination_test_model.dart';
import '../database/daos/germination_test_dao.dart';
import '../database/daos/germination_subtest_dao.dart';
import '../database/daos/germination_daily_record_dao.dart';
import '../services/germination_calculation_service.dart';
import '../database/germination_database.dart';
import '../../../../../database/app_database.dart';

class GerminationTestProvider with ChangeNotifier {
  GerminationTestDao? _testDao;
  GerminationSubtestDao? _subtestDao;
  GerminationDailyRecordDao? _recordDao;
  
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
        _subtestDao = GerminationSubtestDao(db);
        _recordDao = GerminationDailyRecordDao(db);
      } else {
        // Usar banco principal do app
        // O banco será inicializado quando necessário
        _testDao = null;
        _subtestDao = null;
        _recordDao = null;
      }
    } catch (e) {
      _setError('Erro ao inicializar banco de dados: $e');
    }
  }

  // Getters
  List<GerminationTest> get tests => _tests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get statistics => _statistics;
  bool get isReady => _testDao != null && _subtestDao != null && _recordDao != null;

  /// Garante que o provider está inicializado
  Future<void> ensureInitialized() async {
    if (!isReady) {
      // Usar o banco principal do app
      final appDatabase = await AppDatabase.instance.database;
      _testDao = GerminationTestDao(appDatabase);
      _subtestDao = GerminationSubtestDao(appDatabase);
      _recordDao = GerminationDailyRecordDao(appDatabase);
      
      // Criar tabelas se não existirem
      await GerminationDatabase.createTables(appDatabase);
    }
  }

  /// Carrega todos os testes
  Future<void> loadTests() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Garantir que o provider está inicializado
      await ensureInitialized();
      
      _tests = await _testDao?.findAll() ?? [];
      print('✅ GerminationTestProvider: ${_tests.length} testes carregados');
      
      await _calculateStatistics();
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao carregar testes: $e');
      _setError('Erro ao carregar testes: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carrega testes por status
  Future<void> loadTestsByStatus(String status) async {
    _setLoading(true);
    _clearError();
    
    try {
      if (status == 'all') {
        _tests = await _testDao?.findAll() ?? [];
      } else {
        _tests = await _testDao?.findByStatus(status) ?? [];
      }
      await _calculateStatistics();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar testes por status: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carrega testes por cultura
  Future<void> loadTestsByCulture(String culture) async {
    _setLoading(true);
    _clearError();
    
    try {
      _tests = await _testDao?.findByCulture(culture) ?? [];
      await _calculateStatistics();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar testes por cultura: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Busca testes com filtros
  Future<void> searchTests({
    String? culture,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchText,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      _tests = await _testDao?.findWithFilters(
        culture: culture,
        status: status,
        startDate: startDate,
        endDate: endDate,
        searchText: searchText,
      ) ?? [];
      await _calculateStatistics();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao buscar testes: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Cria um novo teste
  Future<GerminationTest?> createTest({
    required String culture,
    required String variety,
    required String seedLot,
    required int totalSeeds,
    required DateTime startDate,
    DateTime? expectedEndDate,
    required int pureSeeds,
    required int brokenSeeds,
    required int stainedSeeds,
    String? observations,
    String? canteiroId,
    String? position,
    List<String>? selectedPositions,
    bool useSubtests = false,
    int subtestSeedCount = 100,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final now = DateTime.now();
      
      // Criar teste principal
      final test = GerminationTest(
        culture: culture,
        variety: variety,
        seedLot: seedLot,
        totalSeeds: totalSeeds,
        startDate: startDate,
        expectedEndDate: expectedEndDate,
        pureSeeds: pureSeeds,
        brokenSeeds: brokenSeeds,
        stainedSeeds: stainedSeeds,
        observations: observations,
        useSubtests: useSubtests,
        subtestSeedCount: useSubtests ? (subtestSeedCount > 0 ? subtestSeedCount : 100) : totalSeeds,
        subtestNames: useSubtests ? selectedPositions?.join(',') : null,
        position: position,
        createdAt: now,
        updatedAt: now,
      );

      final testId = await _testDao?.insert(test) ?? 0;
      final createdTest = test.copyWith(id: testId);
      
      print('✅ Teste criado com ID: $testId');
      print('   - Cultura: ${test.culture}');
      print('   - Variedade: ${test.variety}');
      print('   - Total de Sementes: ${test.totalSeeds}');
      print('   - useSubtests: ${test.useSubtests}');
      print('   - Subtestes: ${selectedPositions?.join(', ') ?? 'Nenhum'}');

      // Criar subtestes se necessário
      if (useSubtests && selectedPositions != null) {
        for (int i = 0; i < selectedPositions.length; i++) {
          final subtest = GerminationSubtest(
            germinationTestId: testId,
            subtestCode: selectedPositions[i],
            subtestName: 'Subteste ${selectedPositions[i]}',
            seedCount: subtestSeedCount > 0 ? subtestSeedCount : 100, // Usar o valor definido pelo usuário ou padrão
            createdAt: now,
            updatedAt: now,
          );
          await _subtestDao?.insert(subtest);
        }
      }

      _tests.insert(0, createdTest);
      await _calculateStatistics();
      notifyListeners();
      return createdTest;
    } catch (e) {
      _setError('Erro ao criar teste: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Adiciona registro diário com ordenação sequencial automática
  Future<GerminationDailyRecord?> addDailyRecord({
    required int testId,
    String? subtestId,
    required int day, // Este parâmetro será ignorado - será calculado automaticamente
    required DateTime recordDate,
    required int normalGerminated,
    required int abnormalGerminated,
    required int diseasedFungi,
    required int diseasedBacteria,
    required int notGerminated,
    required int otherSeeds,
    required int inertMatter,
    String? observations,
    String? photos,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Buscar registros existentes para calcular o próximo número sequencial
      final existingRecords = await _recordDao?.findByTestId(testId) ?? [];
      
      // Criar registro temporário para ordenação
      final tempRecord = GerminationDailyRecord(
        germinationTestId: testId,
        subtestId: subtestId != null ? int.tryParse(subtestId) : null,
        day: 0, // Será recalculado
        recordDate: recordDate,
        normalGerminated: normalGerminated,
        abnormalGerminated: abnormalGerminated,
        diseasedFungi: diseasedFungi,
        diseasedBacteria: diseasedBacteria,
        notGerminated: notGerminated,
        otherSeeds: otherSeeds,
        inertMatter: inertMatter,
        observations: observations,
        photos: photos,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Adicionar à lista e reordenar
      existingRecords.add(tempRecord);
      final sortedRecords = _sortRecordsSequentially(existingRecords);
      
      // Encontrar o novo registro e obter seu número sequencial
      final newRecord = sortedRecords.firstWhere(
        (r) => r.recordDate == recordDate && 
               r.normalGerminated == normalGerminated &&
               r.subtestId?.toString() == subtestId
      );
      
      // Inserir no banco
      final recordId = await _recordDao?.insert(newRecord) ?? 0;
      final createdRecord = newRecord.copyWith(id: recordId);

      // Atualizar resultados do teste
      await _updateTestResults(testId);

      notifyListeners();
      return createdRecord;
    } catch (e) {
      _setError('Erro ao adicionar registro: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza um teste
  Future<GerminationTest?> updateTest({
    required int testId,
    required String culture,
    required String variety,
    required String seedLot,
    required int totalSeeds,
    required DateTime startDate,
    DateTime? expectedEndDate,
    int? pureSeeds,
    int? brokenSeeds,
    int? stainedSeeds,
    String? observations,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final existingTest = await _testDao?.findById(testId);
      if (existingTest == null) {
        _setError('Teste não encontrado');
        return null;
      }

      final updatedTest = existingTest.copyWith(
        culture: culture,
        variety: variety,
        seedLot: seedLot,
        totalSeeds: totalSeeds,
        startDate: startDate,
        expectedEndDate: expectedEndDate,
        pureSeeds: pureSeeds ?? existingTest.pureSeeds,
        brokenSeeds: brokenSeeds ?? existingTest.brokenSeeds,
        stainedSeeds: stainedSeeds ?? existingTest.stainedSeeds,
        observations: observations,
        updatedAt: DateTime.now(),
      );

      await _testDao?.update(updatedTest);

      // Atualizar na lista
      final index = _tests.indexWhere((t) => t.id == testId);
      if (index != -1) {
        _tests[index] = updatedTest;
      }

      await _calculateStatistics();
      notifyListeners();
      return updatedTest;
    } catch (e) {
      _setError('Erro ao atualizar teste: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Finaliza um teste
  Future<GerminationTest?> finalizeTest(int testId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _testDao?.updateStatus(testId, 'completed');
      
      // Atualizar resultados finais
      await _updateTestResults(testId);
      
      // Atualizar na lista
      final index = _tests.indexWhere((t) => t.id == testId);
      if (index != -1) {
        _tests[index] = _tests[index].copyWith(
          status: 'completed',
          updatedAt: DateTime.now(),
        );
      }

      await _calculateStatistics();
      notifyListeners();
      return _tests[index];
    } catch (e) {
      _setError('Erro ao finalizar teste: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancela um teste
  Future<bool> cancelTest(int testId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _testDao?.updateStatus(testId, 'cancelled');
      
      // Atualizar na lista
      final index = _tests.indexWhere((t) => t.id == testId);
      if (index != -1) {
        _tests[index] = _tests[index].copyWith(
          status: 'cancelled',
          updatedAt: DateTime.now(),
        );
      }

      await _calculateStatistics();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao cancelar teste: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Exclui um teste
  Future<bool> deleteTest(int testId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _testDao?.delete(testId);
      
      // Remover da lista
      _tests.removeWhere((t) => t.id == testId);
      
      await _calculateStatistics();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao excluir teste: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Limpa todos os testes (útil para resetar após problemas de banco)
  Future<bool> clearAllTests() async {
    _setLoading(true);
    _clearError();
    
    try {
      print('🧹 Limpando todos os testes...');
      
      // Limpar todas as tabelas relacionadas
      final db = await AppDatabase.instance.database;
      await db.execute('DELETE FROM germination_daily_records');
      await db.execute('DELETE FROM germination_subtest_daily_records');
      await db.execute('DELETE FROM germination_subtests');
      await db.execute('DELETE FROM germination_tests');
      
      // Limpar lista local
      _tests.clear();
      
      // Recalcular estatísticas
      await _calculateStatistics();
      
      print('✅ Todos os testes foram limpos com sucesso');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erro ao limpar testes: $e');
      _setError('Erro ao limpar testes: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Obtém um teste por ID
  Future<GerminationTest?> getTestById(int id) async {
    try {
      print('🔍 Buscando teste com ID: $id');
      
      // Garantir que o provider está inicializado
      await ensureInitialized();
      
      final test = await _testDao?.findById(id);
      if (test == null) {
        print('❌ Teste não encontrado com ID: $id');
        // Verificar se há testes no banco
        final allTests = await _testDao?.findAll() ?? [];
        print('📊 Total de testes no banco: ${allTests.length}');
        for (final t in allTests) {
          print('   - Teste ID: ${t.id}, Cultura: ${t.culture}, Tipo: ${t.useSubtests ? "Com Subtestes" : "Individual"}');
        }
      } else {
        print('✅ Teste encontrado: ${test.culture} - ${test.useSubtests ? "Com Subtestes" : "Individual"}');
      }
      return test;
    } catch (e) {
      print('❌ Erro ao buscar teste: $e');
      _setError('Erro ao obter teste: $e');
      return null;
    }
  }

  /// Obtém registros diários de um teste ordenados sequencialmente
  Future<List<GerminationDailyRecord>> getDailyRecords(int testId) async {
    try {
      // Garantir que o provider está inicializado
      await ensureInitialized();
      
      final records = await _recordDao?.findByTestId(testId) ?? [];
      return _sortRecordsSequentially(records);
    } catch (e) {
      _setError('Erro ao obter registros: $e');
      return [];
    }
  }

  /// Ordena registros por data e atribui números sequenciais (separado por subteste)
  List<GerminationDailyRecord> _sortRecordsSequentially(List<GerminationDailyRecord> records) {
    if (records.isEmpty) return records;
    
    // Separar por subteste
    final Map<String?, List<GerminationDailyRecord>> subtestRecords = {};
    for (final record in records) {
      final subtestKey = record.subtestId?.toString() ?? 'Individual';
      subtestRecords.putIfAbsent(subtestKey, () => []).add(record);
    }
    
    final List<GerminationDailyRecord> sortedRecords = [];
    
    // Ordenar cada subteste separadamente
    for (final entry in subtestRecords.entries) {
      final subtestRecordsList = entry.value;
      
      // Ordenar por data (mais antiga primeiro)
      subtestRecordsList.sort((a, b) => a.recordDate.compareTo(b.recordDate));
      
      // Atribuir números sequenciais baseados na posição ordenada
      for (int i = 0; i < subtestRecordsList.length; i++) {
        subtestRecordsList[i] = subtestRecordsList[i].copyWith(day: i + 1);
      }
      
      sortedRecords.addAll(subtestRecordsList);
    }
    
    // Manter a ordem sequencial dentro de cada subteste, ordenando apenas por subteste e depois por data
    sortedRecords.sort((a, b) {
      final aSubtest = a.subtestId?.toString() ?? 'Individual';
      final bSubtest = b.subtestId?.toString() ?? 'Individual';
      
      // Primeiro ordenar por subteste
      final subtestComparison = aSubtest.compareTo(bSubtest);
      if (subtestComparison != 0) return subtestComparison;
      
      // Depois ordenar por data dentro do mesmo subteste
      return a.recordDate.compareTo(b.recordDate);
    });
    
    return sortedRecords;
  }

  /// Atualiza ordenação de todos os registros de um teste
  Future<void> updateRecordsSequentialOrder(int testId) async {
    try {
      final records = await _recordDao?.findByTestId(testId) ?? [];
      final sortedRecords = _sortRecordsSequentially(records);
      
      // Atualizar cada registro com seu novo número sequencial
      for (final record in sortedRecords) {
        await _recordDao?.update(record);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Erro ao atualizar ordenação: $e');
    }
  }

  /// Atualiza um registro diário existente
  Future<bool> updateDailyRecord(GerminationDailyRecord record) async {
    try {
      await _recordDao?.update(record);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao atualizar registro: $e');
      return false;
    }
  }

  /// Cria um novo registro diário
  Future<bool> createDailyRecord(GerminationDailyRecord record) async {
    try {
      await _recordDao?.insert(record);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao criar registro: $e');
      return false;
    }
  }

  /// Exclui um registro diário
  Future<bool> deleteDailyRecord(int recordId) async {
    try {
      await _recordDao?.delete(recordId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao excluir registro: $e');
      return false;
    }
  }

  /// Calcula resultados de um subteste
  Map<String, dynamic>? calculateSubtestResults(GerminationTest test, List<GerminationDailyRecord> records) {
    if (records.isEmpty) return null;

    // Calcular totais
    int totalNormal = records.fold(0, (sum, record) => sum + record.normalGerminated);
    int totalAbnormal = records.fold(0, (sum, record) => sum + record.abnormalGerminated);
    int totalDiseased = records.fold(0, (sum, record) => sum + record.diseasedFungi + record.diseasedBacteria);
    int totalOther = records.fold(0, (sum, record) => sum + record.otherSeeds);
    int totalInert = records.fold(0, (sum, record) => sum + record.inertMatter);

    // Calcular percentuais
    double germinationPercentage = (totalNormal / test.totalSeeds) * 100;
    double contaminationPercentage = (totalDiseased / test.totalSeeds) * 100;
    double purityPercentage = ((test.totalSeeds - totalOther - totalInert) / test.totalSeeds) * 100;
    double culturalValue = (germinationPercentage * purityPercentage) / 100;

    return {
      'germinationPercentage': germinationPercentage,
      'contaminationPercentage': contaminationPercentage,
      'purityPercentage': purityPercentage,
      'culturalValue': culturalValue,
      'totalNormal': totalNormal,
      'totalAbnormal': totalAbnormal,
      'totalDiseased': totalDiseased,
      'totalOther': totalOther,
      'totalInert': totalInert,
      'isValid': true,
    };
  }

  /// Calcula resultados de um teste
  Future<Map<String, dynamic>?> calculateTestResults(int testId) async {
    try {
      final records = await _recordDao?.findByTestId(testId) ?? [];
      final test = await _testDao?.findById(testId);
      
      if (test == null || records.isEmpty) {
        return null;
      }

      return GerminationCalculationService.getTestSummary(records, test.totalSeeds);
    } catch (e) {
      _setError('Erro ao calcular resultados: $e');
      return null;
    }
  }

  /// Atualiza resultados de um teste
  Future<void> _updateTestResults(int testId) async {
    try {
      final results = await calculateTestResults(testId);
      if (results != null && results['isValid'] == true) {
        await _testDao?.updateResults(
          testId,
          finalGerminationPercentage: results['germinationPercentage'],
          purityPercentage: results['purityPercentage'],
          diseasedPercentage: results['contaminationPercentage'],
          culturalValue: results['culturalValue'],
          averageGerminationTime: results['averageTime'],
          firstCountDay: results['firstCountDay'],
          day50PercentGermination: results['day50PercentGermination'],
        );
      }
    } catch (e) {
      debugPrint('Erro ao atualizar resultados: $e');
    }
  }

  /// Calcula estatísticas gerais
  Future<void> _calculateStatistics() async {
    try {
      final totalTests = _tests.length;
      final activeTests = _tests.where((t) => t.status == 'active').length;
      final completedTests = _tests.where((t) => t.status == 'completed').length;
      final cancelledTests = _tests.where((t) => t.status == 'cancelled').length;

      // Calcular média de germinação das culturas mais testadas
      final cultureCounts = <String, int>{};
      final cultureGerminations = <String, List<double>>{};

      for (final test in _tests) {
        if (test.status == 'completed' && test.finalGerminationPercentage != null) {
          cultureCounts[test.culture] = (cultureCounts[test.culture] ?? 0) + 1;
          cultureGerminations[test.culture] ??= [];
          cultureGerminations[test.culture]!.add(test.finalGerminationPercentage!);
        }
      }

      final topCultures = cultureCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      _statistics = {
        'totalTests': totalTests,
        'activeTests': activeTests,
        'completedTests': completedTests,
        'cancelledTests': cancelledTests,
        'topCultures': topCultures.take(3).map((e) => {
          'culture': e.key,
          'count': e.value,
          'averageGermination': cultureGerminations[e.key]!.reduce((a, b) => a + b) / cultureGerminations[e.key]!.length,
        }).toList(),
      };
    } catch (e) {
      _statistics = {
        'totalTests': 0,
        'activeTests': 0,
        'completedTests': 0,
        'cancelledTests': 0,
        'topCultures': [],
      };
    }
  }

  /// Métodos auxiliares
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Limpa dados
  void clearData() {
    _tests.clear();
    _statistics.clear();
    _clearError();
    notifyListeners();
  }
}
