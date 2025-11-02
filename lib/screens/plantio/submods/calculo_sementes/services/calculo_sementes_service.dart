import '../../../../../models/seed_calc_result.dart';
import '../../../../../utils/seed_calculation_utils.dart';
import '../models/calculo_sementes_state.dart';

/// Serviço para cálculos de sementes
class CalculoSementesService {
  /// Calcula o resultado baseado no estado
  static SeedCalcResult calcular(CalculoSementesState state) {
    if (!state.isValid) {
      throw ArgumentError('Estado inválido para cálculo');
    }

    final params = state.calculoParams;
    
    return calculateSeeds(
      modeSeedsPerBag: params['modeSeedsPerBag'] as bool,
      seedsPerBag: (params['seedsPerBag'] as num?)?.toDouble() ?? 0.0,
      Wbag: (params['Wbag'] as num?)?.toDouble() ?? 0.0,
      nBags: (params['nBags'] as num?)?.toInt() ?? 0,
      PMS_g_per_1000_input: (params['PMS_g_per_1000_input'] as num?)?.toDouble(),
      sMetro: (params['sMetro'] as num?)?.toDouble() ?? 0.0,
      populacaoDesejada: (params['populacaoDesejada'] as num?)?.toDouble() ?? 0.0,
      modoPopulacao: (params['modoPopulacao'] as bool?) ?? false,
      esp: (params['esp'] as num?)?.toDouble() ?? 0.0,
      Nha: (params['Nha'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Valida os campos do estado
  static String? validarEspacamento(double? value) {
    if (value == null || value <= 0) {
      return 'Espaçamento deve ser maior que zero';
    }
    return null;
  }

  static String? validarGerminacao(double? value) {
    if (value == null || value <= 0 || value > 100) {
      return 'Germinação deve estar entre 0 e 100%';
    }
    return null;
  }

  static String? validarVigor(double? value) {
    if (value == null || value <= 0 || value > 100) {
      return 'Vigor deve estar entre 0 e 100%';
    }
    return null;
  }

  static String? validarSementesPorMetro(double? value, ModoCalculo modo) {
    if (modo == ModoCalculo.sementesPorMetro) {
      if (value == null || value <= 0) {
        return 'Sementes por metro deve ser maior que zero';
      }
    }
    return null;
  }

  static String? validarPopulacaoDesejada(double? value, ModoCalculo modo) {
    if (modo == ModoCalculo.populacao) {
      if (value == null || value <= 0) {
        return 'População desejada deve ser maior que zero';
      }
    }
    return null;
  }

  static String? validarPesoBag(double? value) {
    if (value == null || value <= 0) {
      return 'Peso do bag deve ser maior que zero';
    }
    return null;
  }

  static String? validarNumeroBags(int? value) {
    if (value == null || value <= 0) {
      return 'Número de bags deve ser maior que zero';
    }
    return null;
  }

  static String? validarSementesPorBag(double? value, ModoBag modo) {
    // Sementes por bag é sempre necessário para calcular PMS, independente do modo
    if (value == null || value <= 0) {
      return 'Sementes por bag deve ser maior que zero';
    }
    return null;
  }

  static String? validarPMSManual(double? value, bool usarPMS) {
    if (usarPMS && (value == null || value <= 0)) {
      return 'PMS deve ser maior que zero';
    }
    return null;
  }

  static String? validarAreaDesejada(double? value, bool usarArea) {
    if (usarArea && (value == null || value <= 0)) {
      return 'Área desejada deve ser maior que zero';
    }
    return null;
  }

  static String? validarAreaManual(double? value) {
    if (value == null || value <= 0) {
      return 'Área deve ser maior que zero';
    }
    return null;
  }
}
