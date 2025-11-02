import 'package:flutter_test/flutter_test.dart';
import '../utils/utils.dart';

void main() {
  group('InfestationTestRunner - Testes Básicos', () {
    late InfestationTestRunner testRunner;

    setUp(() {
      testRunner = InfestationTestRunner();
    });

    test('deve ser singleton', () {
      final instance1 = InfestationTestRunner();
      final instance2 = InfestationTestRunner();
      expect(identical(instance1, instance2), isTrue);
    });

    test('deve ter método runAllTests', () {
      expect(testRunner.runAllTests, isNotNull);
    });

    test('deve ter método generateTestReport', () {
      expect(testRunner.generateTestReport, isNotNull);
    });

    test('deve gerar relatório com resultados', () {
      final mockResults = {
        'test1': true,
        'test2': false,
        'test3': true,
      };
      
      final report = testRunner.generateTestReport(mockResults);
      
      expect(report, contains('RELATÓRIO DE TESTES'));
      expect(report, contains('2/3 (66.7%)'));
      expect(report, contains('test1: ✅ PASSOU'));
      expect(report, contains('test2: ❌ FALHOU'));
      expect(report, contains('test3: ✅ PASSOU'));
    });

    test('deve mostrar mensagem de sucesso quando todos passam', () {
      final mockResults = {
        'test1': true,
        'test2': true,
      };
      
      final report = testRunner.generateTestReport(mockResults);
      expect(report, contains('🎉 Todos os testes passaram!'));
    });

    test('deve mostrar aviso quando alguns falham', () {
      final mockResults = {
        'test1': true,
        'test2': false,
      };
      
      final report = testRunner.generateTestReport(mockResults);
      expect(report, contains('⚠️ Alguns testes falharam'));
    });
  });
}
