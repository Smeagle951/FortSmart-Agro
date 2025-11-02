import 'package:flutter_test/flutter_test.dart';
import '../models/calibration_result.dart';

/// Teste dos cálculos de calibração usando o exemplo fornecido
void main() {
  group('CalibrationCalculator Tests', () {
    test('Exemplo numérico do usuário - Dados corretos', () {
      // Dados do exemplo fornecido
      final weightsGrams = [1200.0, 1100.0, 1250.0, 1180.0, 1300.0, 1150.0];
      final distanceM = 50.0;
      final widthM = 27.0;
      final desiredKgHa = 150.0;
      
      // Calcular resultado
      final result = CalibrationCalculator.calculateCalibration(
        weightsGrams: weightsGrams,
        distanceM: distanceM,
        widthM: widthM,
        desiredKgHa: desiredKgHa,
      );
      
      // Verificar cálculos esperados
      expect(result.areaHa, closeTo(0.135, 0.001)); // (50 × 27) / 10.000 = 0,135 ha
      expect(result.totalKg, closeTo(7.18, 0.01)); // 7180g = 7,18 kg
      expect(result.rateKgHa, closeTo(53.19, 0.1)); // 7,18 ÷ 0,135 ≈ 53,19 kg/ha
      expect(result.numberOfTrays, equals(6));
      expect(result.areaPerTray, closeTo(0.0225, 0.0001)); // 0,135 ÷ 6 = 0,0225 ha
      
      // Verificar taxas por bandeja
      expect(result.trayRates.length, equals(6));
      expect(result.trayRates[0], closeTo(53.333, 0.1)); // 1,2 ÷ 0,0225 = 53,333 kg/ha
      expect(result.trayRates[1], closeTo(48.889, 0.1)); // 1,1 ÷ 0,0225 = 48,889 kg/ha
      expect(result.trayRates[2], closeTo(55.556, 0.1)); // 1,25 ÷ 0,0225 = 55,556 kg/ha
      expect(result.trayRates[3], closeTo(52.444, 0.1)); // 1,18 ÷ 0,0225 = 52,444 kg/ha
      expect(result.trayRates[4], closeTo(57.778, 0.1)); // 1,3 ÷ 0,0225 = 57,778 kg/ha
      expect(result.trayRates[5], closeTo(51.111, 0.1)); // 1,15 ÷ 0,0225 = 51,111 kg/ha
      
      // Verificar média
      expect(result.mean, closeTo(53.185, 0.1)); // Média das taxas por bandeja
      
      // Verificar CV%
      expect(result.cvPercent, closeTo(5.95, 0.1)); // CV% esperado ≈ 5,95%
      
      // Verificar erro percentual
      expect(result.errorPercent, closeTo(-64.54, 0.1)); // (53,185 - 150) / 150 × 100 = -64,54%
      
      // Verificar fator de ajuste
      expect(result.adjustmentFactor, closeTo(2.82, 0.1)); // 150 / 53,185 ≈ 2,82
      expect(result.adjustPercent, closeTo(182.0, 1.0)); // (2,82 - 1) × 100 ≈ 182%
      
      // Verificar status
      expect(result.qualityStatus, equals('Excelente')); // CV% < 10%
      expect(result.qualityColor, equals('green'));
    });
    
    test('Validação de entrada - Casos de erro', () {
      // Teste com lista vazia
      expect(
        () => CalibrationCalculator.calculateCalibration(
          weightsGrams: [],
          distanceM: 50.0,
          widthM: 27.0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      
      // Teste com distância zero
      expect(
        () => CalibrationCalculator.calculateCalibration(
          weightsGrams: [1000.0, 1100.0, 1200.0, 1100.0, 1250.0, 1180.0],
          distanceM: 0.0,
          widthM: 27.0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      
      // Teste com largura zero
      expect(
        () => CalibrationCalculator.calculateCalibration(
          weightsGrams: [1000.0, 1100.0, 1200.0, 1100.0, 1250.0, 1180.0],
          distanceM: 50.0,
          widthM: 0.0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      
      // Teste com peso zero
      expect(
        CalibrationCalculator.validateInput(
          weights: [1000.0, 0.0, 1200.0, 1100.0, 1250.0, 1180.0], // 6 bandejas com uma zero
          distance: 50.0,
          width: 27.0,
        ),
        equals('Todos os pesos devem ser maiores que zero'),
      );
    });
    
    test('Recomendações baseadas no resultado', () {
      final result = CalibrationCalculator.calculateCalibration(
        weightsGrams: [1200.0, 1100.0, 1250.0, 1180.0, 1300.0, 1150.0],
        distanceM: 50.0,
        widthM: 27.0,
        desiredKgHa: 150.0,
      );
      
      final recommendations = CalibrationCalculator.generateRecommendations(result);
      
      expect(recommendations, isNotEmpty);
      expect(recommendations.any((r) => r.contains('CV% excelente')), isTrue);
      expect(recommendations.any((r) => r.contains('Aumentar dosador')), isTrue);
    });
    
    test('Diferentes números de bandejas', () {
      // Teste com 8 bandejas
      final weights8 = [1200.0, 1100.0, 1250.0, 1180.0, 1300.0, 1150.0, 1200.0, 1100.0];
      final result8 = CalibrationCalculator.calculateCalibration(
        weightsGrams: weights8,
        distanceM: 50.0,
        widthM: 27.0,
      );
      
      expect(result8.numberOfTrays, equals(8));
      expect(result8.areaPerTray, closeTo(0.135 / 8, 0.0001));
      
      // Teste com 4 bandejas (mínimo)
      final weights4 = [1200.0, 1100.0, 1250.0, 1180.0];
      final result4 = CalibrationCalculator.calculateCalibration(
        weightsGrams: weights4,
        distanceM: 50.0,
        widthM: 27.0,
      );
      
      expect(result4.numberOfTrays, equals(4));
      expect(result4.areaPerTray, closeTo(0.135 / 4, 0.0001));
    });
  });
}
