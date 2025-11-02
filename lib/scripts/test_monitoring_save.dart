import 'dart:io';
import '../services/monitoring_database_fix_service.dart';
import '../services/monitoring_validation_service.dart';
import '../repositories/monitoring_repository.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';
import 'package:uuid/uuid.dart';

/// Script para testar o salvamento do monitoramento
class MonitoringSaveTest {
  final MonitoringDatabaseFixService _databaseFixService = MonitoringDatabaseFixService();
  final MonitoringValidationService _validationService = MonitoringValidationService();
  final MonitoringRepository _monitoringRepository = MonitoringRepository();

  /// Executa todos os testes
  Future<void> runAllTests() async {
    print('🧪 Iniciando testes de salvamento do monitoramento...\n');
    
    try {
      // 1. Testar correção do banco de dados
      await _testDatabaseFix();
      
      // 2. Testar validação de dados
      await _testDataValidation();
      
      // 3. Testar salvamento
      await _testSaveMonitoring();
      
      // 4. Testar recuperação
      await _testRetrieveMonitoring();
      
      print('\n✅ Todos os testes concluídos com sucesso!');
      
    } catch (e) {
      print('\n❌ Erro durante os testes: $e');
    }
  }

  /// Testa a correção do banco de dados
  Future<void> _testDatabaseFix() async {
    print('🔧 Testando correção do banco de dados...');
    
    final success = await _databaseFixService.fixMonitoringDatabase();
    if (success) {
      print('✅ Banco de dados corrigido com sucesso');
    } else {
      throw Exception('Falha ao corrigir banco de dados');
    }
    
    final dbWorking = await _databaseFixService.testDatabaseConnection();
    if (dbWorking) {
      print('✅ Conexão com banco de dados funcionando');
    } else {
      throw Exception('Conexão com banco de dados falhou');
    }
  }

  /// Testa a validação de dados
  Future<void> _testDataValidation() async {
    print('🔍 Testando validação de dados...');
    
    // Criar monitoramento de teste
    final testMonitoring = _createTestMonitoring();
    
    // Validar monitoramento
    final validationResult = await _validationService.validateMonitoring(testMonitoring);
    
    if (validationResult['isValid']) {
      print('✅ Monitoramento de teste é válido');
    } else {
      final errors = validationResult['errors'] as List<String>;
      print('❌ Monitoramento de teste é inválido:');
      for (final error in errors) {
        print('   - $error');
      }
    }
    
    final warnings = validationResult['warnings'] as List<String>;
    if (warnings.isNotEmpty) {
      print('⚠️ Avisos encontrados:');
      for (final warning in warnings) {
        print('   - $warning');
      }
    }
  }

  /// Testa o salvamento do monitoramento
  Future<void> _testSaveMonitoring() async {
    print('💾 Testando salvamento do monitoramento...');
    
    // Criar monitoramento de teste
    final testMonitoring = _createTestMonitoring();
    
    // Aplicar correções se necessário
    final correctedMonitoring = await _validationService.fixMonitoring(testMonitoring);
    
    // Salvar monitoramento
    final saveResult = await _monitoringRepository.saveMonitoring(correctedMonitoring);
    
    if (saveResult) {
      print('✅ Monitoramento salvo com sucesso');
    } else {
      throw Exception('Falha ao salvar monitoramento');
    }
  }

  /// Testa a recuperação do monitoramento
  Future<void> _testRetrieveMonitoring() async {
    print('📖 Testando recuperação do monitoramento...');
    
    // Buscar monitoramento salvo
    final savedMonitoring = await _monitoringRepository.getMonitoringById('test-monitoring-001');
    
    if (savedMonitoring != null) {
      print('✅ Monitoramento recuperado com sucesso');
      print('📋 Dados do monitoramento:');
      print('  - ID: ${savedMonitoring.id}');
      print('  - Plot ID: ${savedMonitoring.plotId}');
      print('  - Plot Name: ${savedMonitoring.plotName}');
      print('  - Points: ${savedMonitoring.points.length}');
      
      for (int i = 0; i < savedMonitoring.points.length; i++) {
        final point = savedMonitoring.points[i];
        print('  📍 Ponto ${i + 1}:');
        print('    - ID: ${point.id}');
        print('    - Latitude: ${point.latitude}');
        print('    - Longitude: ${point.longitude}');
        print('    - Ocorrências: ${point.occurrences.length}');
      }
    } else {
      throw Exception('Monitoramento não foi encontrado após salvar');
    }
  }

  /// Cria um monitoramento de teste
  Monitoring _createTestMonitoring() {
    final testPoint1 = MonitoringPoint(
      id: 'test-point-001',
      plotId: 1,
      plotName: 'Talhão Teste',
      cropId: 1,
      cropName: 'Soja',
      latitude: -23.5505,
      longitude: -46.6333,
      occurrences: [
        Occurrence(
          id: 'test-occurrence-001',
          type: OccurrenceType.pest,
          name: 'Lagarta da Soja',
          infestationIndex: 25.0,
          affectedSections: [PlantSection.leaves],
          notes: 'Ocorrência de teste',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Occurrence(
          id: 'test-occurrence-002',
          type: OccurrenceType.disease,
          name: 'Ferrugem Asiática',
          infestationIndex: 15.0,
          affectedSections: [PlantSection.leaves],
          notes: 'Ocorrência de teste',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
      imagePaths: [],
      audioPath: null,
      observations: 'Observações de teste',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final testPoint2 = MonitoringPoint(
      id: 'test-point-002',
      plotId: 1,
      plotName: 'Talhão Teste',
      cropId: 1,
      cropName: 'Soja',
      latitude: -23.5506,
      longitude: -46.6334,
      occurrences: [
        Occurrence(
          id: 'test-occurrence-003',
          type: OccurrenceType.weed,
          name: 'Buva',
          infestationIndex: 30.0,
          affectedSections: [PlantSection.roots],
          notes: 'Ocorrência de teste',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
      imagePaths: [],
      audioPath: null,
      observations: 'Observações de teste',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Monitoring(
      id: 'test-monitoring-001',
      date: DateTime.now(),
      plotId: 1,
      plotName: 'Talhão Teste',
      cropId: 1,
      cropName: 'Soja',
      route: [
        {'latitude': -23.5505, 'longitude': -46.6333},
        {'latitude': -23.5506, 'longitude': -46.6334},
      ],
      points: [testPoint1, testPoint2],
      isCompleted: true,
    );
  }

  /// Limpa dados de teste
  Future<void> cleanupTestData() async {
    print('🧹 Limpando dados de teste...');
    
    try {
      await _databaseFixService.cleanTestData();
      print('✅ Dados de teste removidos');
    } catch (e) {
      print('⚠️ Erro ao limpar dados de teste: $e');
    }
  }
}

/// Função principal para executar os testes
Future<void> main() async {
  final test = MonitoringSaveTest();
  
  try {
    await test.runAllTests();
    
    // Perguntar se deve limpar dados de teste
    print('\n🧹 Deseja limpar os dados de teste? (s/n): ');
    final input = stdin.readLineSync()?.toLowerCase();
    
    if (input == 's' || input == 'sim') {
      await test.cleanupTestData();
    }
    
  } catch (e) {
    print('❌ Erro durante execução dos testes: $e');
  }
}
