import 'package:flutter_test/flutter_test.dart';
import 'infestation_repository.dart';
import '../models/models.dart';

/// Testes básicos para o InfestationRepository
/// Este arquivo pode ser executado com: flutter test lib/modules/infestation_map/repositories/
void main() {
  group('InfestationRepository', () {
    late InfestationRepository repository;

    setUp(() {
      repository = InfestationRepository();
    });

    test('deve inicializar corretamente', () async {
      // Este teste verifica se o repositório pode ser criado
      expect(repository, isNotNull);
      expect(repository, isA<InfestationRepository>());
    });

    test('deve ter métodos necessários', () {
      // Verificar se os métodos principais existem
      expect(repository.getInfestationSummariesByTalhao, isNotNull);
      expect(repository.getActiveInfestationAlerts, isNotNull);
      expect(repository.saveInfestationSummary, isNotNull);
      expect(repository.saveInfestationAlert, isNotNull);
      expect(repository.getTalhaoInfestationStats, isNotNull);
    });

    test('deve retornar lista vazia quando não há dados', () async {
      // Teste com talhão inexistente
      final summaries = await repository.getInfestationSummariesByTalhao('999');
      expect(summaries, isEmpty);
      
      final alerts = await repository.getActiveInfestationAlerts();
      expect(alerts, isEmpty);
    });

    test('deve retornar estatísticas padrão quando não há dados', () async {
      final stats = await repository.getTalhaoInfestationStats('999');
      
      expect(stats, isNotEmpty);
      expect(stats['total_organisms'], equals(0));
      expect(stats['critical_levels'], equals(0));
      expect(stats['high_levels'], equals(0));
      expect(stats['moderate_levels'], equals(0));
      expect(stats['low_levels'], equals(0));
      expect(stats['last_update'], isNotNull);
    });
  });
}
