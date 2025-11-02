/// 🧠 Service: Classificação Fenológica Automática
/// 
/// Serviço inteligente para classificação automática de estágios
/// fenológicos (BBCH) baseado nos dados coletados em campo.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import '../models/phenological_record_model.dart';
import '../models/phenological_stage_model.dart';

class PhenologicalClassificationService {
  /// Classificar estágio fenológico automaticamente
  static PhenologicalStageModel? classificarEstagio({
    required PhenologicalRecordModel registro,
    required String cultura,
  }) {
    switch (cultura.toLowerCase()) {
      case 'soja':
        return _classificarSoja(registro);
      case 'milho':
        return _classificarMilho(registro);
      case 'feijao':
      case 'feijão':
        return _classificarFeijao(registro);
      case 'algodao':
      case 'algodão':
        return _classificarAlgodao(registro);
      case 'sorgo':
        return _classificarSorgo(registro);
      case 'gergelim':
        return _classificarGergelim(registro);
      case 'cana':
      case 'cana-de-açucar':
      case 'cana-de-acucar':
      case 'cana de açúcar':
      case 'cana de acucar':
        return _classificarCana(registro);
      case 'tomate':
        return _classificarTomate(registro);
      case 'trigo':
        return _classificarTrigo(registro);
      case 'aveia':
        return _classificarAveia(registro);
      case 'girassol':
        return _classificarGirassol(registro);
      case 'arroz':
        return _classificarArroz(registro);
      default:
        return null;
    }
  }

  /// 🌱 Classificação Automática para SOJA
  static PhenologicalStageModel? _classificarSoja(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('soja');
    final dae = r.diasAposEmergencia;
    final altura = r.alturaCm;
    final numFolhas = r.numeroFolhasTrifolioladas;
    final vagens = r.vagensPlanta;
    final comprimentoVagens = r.comprimentoVagensCm;

    // FASE REPRODUTIVA - Prioridade para detectar R9 a R1
    
    // R9: Maturação de Colheita (> 100 DAE, vagens secas)
    if (dae >= 100 && vagens != null && vagens > 0) {
      return estagios.firstWhere((e) => e.codigo == 'R9');
    }
    
    // R8: Maturação Plena (90-120 DAE)
    if (dae >= 90 && dae < 100) {
      return estagios.firstWhere((e) => e.codigo == 'R8');
    }
    
    // R7: Início da Maturação (80-100 DAE)
    if (dae >= 80 && dae < 90) {
      return estagios.firstWhere((e) => e.codigo == 'R7');
    }
    
    // R6: Grão Completamente Cheio (65-90 DAE, vagens completas)
    if (dae >= 65 && dae < 80 && vagens != null && vagens > 0) {
      return estagios.firstWhere((e) => e.codigo == 'R6');
    }
    
    // R5: Início do Enchimento de Grãos (55-80 DAE, vagens > 2cm)
    if (dae >= 55 && dae < 65 && comprimentoVagens != null && comprimentoVagens >= 2.0) {
      return estagios.firstWhere((e) => e.codigo == 'R5');
    }
    
    // R4: Vagem Completamente Desenvolvida (50-70 DAE, vagens 2-4cm)
    if (dae >= 50 && dae < 55 && comprimentoVagens != null && 
        comprimentoVagens >= 2.0 && comprimentoVagens <= 4.0) {
      return estagios.firstWhere((e) => e.codigo == 'R4');
    }
    
    // R3: Início da Formação de Vagens (45-65 DAE, vagens < 1.5cm)
    if (dae >= 45 && dae < 50 && comprimentoVagens != null && comprimentoVagens < 1.5) {
      return estagios.firstWhere((e) => e.codigo == 'R3');
    }
    
    // R2: Florescimento Pleno (40-60 DAE)
    if (dae >= 40 && dae < 45) {
      return estagios.firstWhere((e) => e.codigo == 'R2');
    }
    
    // R1: Início do Florescimento (35-50 DAE)
    if (dae >= 35 && dae < 40) {
      return estagios.firstWhere((e) => e.codigo == 'R1');
    }

    // FASE VEGETATIVA - Baseado em número de folhas trifolioladas
    
    if (numFolhas != null) {
      // V4 ou superior (4+ folhas trifolioladas)
      if (numFolhas >= 4) {
        return estagios.firstWhere(
          (e) => e.codigo == 'V4',
          orElse: () => estagios.firstWhere((e) => e.codigo == 'V3'),
        );
      }
      
      // V3 (3 folhas trifolioladas)
      if (numFolhas == 3) {
        return estagios.firstWhere((e) => e.codigo == 'V3');
      }
      
      // V2 (2 folhas trifolioladas)
      if (numFolhas == 2) {
        return estagios.firstWhere((e) => e.codigo == 'V2');
      }
      
      // V1 (1 folha trifoliolada)
      if (numFolhas == 1) {
        return estagios.firstWhere((e) => e.codigo == 'V1');
      }
    }
    
    // Baseado em DAE e altura se não houver folhas trifolioladas
    if (dae >= 20 && dae < 35) {
      if (altura != null && altura >= 40) {
        return estagios.firstWhere((e) => e.codigo == 'V4');
      } else if (altura != null && altura >= 30) {
        return estagios.firstWhere((e) => e.codigo == 'V3');
      }
    }
    
    // VC: Cotilédone (7-15 DAE)
    if (dae >= 7 && dae < 20) {
      return estagios.firstWhere((e) => e.codigo == 'VC');
    }
    
    // VE: Emergência (5-10 DAE)
    if (dae >= 5 && dae < 7) {
      return estagios.firstWhere((e) => e.codigo == 'VE');
    }

    return null; // Não foi possível classificar
  }

  /// 🌽 Classificação Automática para MILHO
  static PhenologicalStageModel? _classificarMilho(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('milho');
    final dae = r.diasAposEmergencia;
    final numFolhas = r.numeroFolhas;
    final espigas = r.espigasPlanta;

    // FASE REPRODUTIVA
    
    // R6: Maturação Fisiológica (110-140 DAE)
    if (dae >= 110) {
      return estagios.firstWhere((e) => e.codigo == 'R6');
    }
    
    // R5: Grão Duro (95-115 DAE)
    if (dae >= 95 && dae < 110) {
      return estagios.firstWhere((e) => e.codigo == 'R5');
    }
    
    // R4: Grão Farináceo (85-105 DAE)
    if (dae >= 85 && dae < 95) {
      return estagios.firstWhere((e) => e.codigo == 'R4');
    }
    
    // R3: Grão Pastoso (75-95 DAE)
    if (dae >= 75 && dae < 85) {
      return estagios.firstWhere((e) => e.codigo == 'R3');
    }
    
    // R2: Grão Leitoso (65-85 DAE)
    if (dae >= 65 && dae < 75) {
      return estagios.firstWhere((e) => e.codigo == 'R2');
    }
    
    // R1: Embonecamento (55-75 DAE, espigas visíveis)
    if (dae >= 55 && dae < 65 && espigas != null && espigas > 0) {
      return estagios.firstWhere((e) => e.codigo == 'R1');
    }
    
    // VT: Pendoamento (50-70 DAE)
    if (dae >= 50 && dae < 55) {
      return estagios.firstWhere((e) => e.codigo == 'VT');
    }

    // FASE VEGETATIVA - Baseado em número de folhas
    
    if (numFolhas != null) {
      // V6 ou superior (6+ folhas)
      if (numFolhas >= 6) {
        return estagios.firstWhere(
          (e) => e.codigo == 'V6',
          orElse: () => estagios.firstWhere((e) => e.codigo == 'V4'),
        );
      }
      
      // V4 (4-5 folhas)
      if (numFolhas >= 4 && numFolhas < 6) {
        return estagios.firstWhere((e) => e.codigo == 'V4');
      }
      
      // V2 (2-3 folhas)
      if (numFolhas >= 2 && numFolhas < 4) {
        return estagios.firstWhere((e) => e.codigo == 'V2');
      }
    }
    
    // VE: Emergência (4-10 DAE)
    if (dae >= 4 && dae < 18) {
      return estagios.firstWhere((e) => e.codigo == 'VE');
    }

    return null;
  }

  /// 🫘 Classificação Automática para FEIJÃO
  static PhenologicalStageModel? _classificarFeijao(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('feijao');
    final dae = r.diasAposEmergencia;
    final numFolhas = r.numeroFolhasTrifolioladas;
    final vagens = r.vagensPlanta;
    final comprimentoVagens = r.comprimentoVagensCm;

    // FASE REPRODUTIVA
    
    // R9: Maturação (70-90 DAE, vagens secas)
    if (dae >= 70) {
      return estagios.firstWhere((e) => e.codigo == 'R9');
    }
    
    // R8: Enchimento de Vagens (45-65 DAE, vagens completas)
    if (dae >= 45 && dae < 70 && vagens != null && vagens > 0) {
      return estagios.firstWhere((e) => e.codigo == 'R8');
    }
    
    // R7: Formação de Vagens (35-50 DAE, vagens < 2cm)
    if (dae >= 35 && dae < 45 && comprimentoVagens != null && comprimentoVagens < 2.0) {
      return estagios.firstWhere((e) => e.codigo == 'R7');
    }
    
    // R6: Floração (30-45 DAE)
    if (dae >= 30 && dae < 35) {
      return estagios.firstWhere((e) => e.codigo == 'R6');
    }
    
    // R5: Pré-Floração (25-35 DAE)
    if (dae >= 25 && dae < 30) {
      return estagios.firstWhere((e) => e.codigo == 'R5');
    }

    // FASE VEGETATIVA
    
    if (numFolhas != null) {
      // V3: Primeira Folha Trifoliolada (15-25 DAE)
      if (numFolhas >= 1) {
        return estagios.firstWhere((e) => e.codigo == 'V3');
      }
    }
    
    // V2: Folhas Primárias (10-18 DAE)
    if (dae >= 10 && dae < 15) {
      return estagios.firstWhere((e) => e.codigo == 'V2');
    }
    
    // V1: Emergência (5-12 DAE)
    if (dae >= 5 && dae < 10) {
      return estagios.firstWhere((e) => e.codigo == 'V1');
    }
    
    // V0: Germinação (3-8 DAE)
    if (dae >= 3 && dae < 5) {
      return estagios.firstWhere((e) => e.codigo == 'V0');
    }

    return null;
  }

  /// Obter descrição estendida do estágio
  static String obterDescricaoEstendida(
    PhenologicalStageModel estagio,
    PhenologicalRecordModel registro,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln(estagio.descricao);
    buffer.writeln();
    buffer.writeln('📊 Dados do Registro:');
    buffer.writeln('• Dias após emergência: ${registro.diasAposEmergencia}');
    
    if (registro.alturaCm != null) {
      buffer.writeln('• Altura: ${registro.alturaCm!.toStringAsFixed(1)} cm');
    }
    
    if (registro.numeroFolhas != null) {
      buffer.writeln('• Número de folhas: ${registro.numeroFolhas}');
    }
    
    if (registro.numeroFolhasTrifolioladas != null) {
      buffer.writeln('• Folhas trifolioladas: ${registro.numeroFolhasTrifolioladas}');
    }
    
    if (registro.vagensPlanta != null) {
      buffer.writeln('• Vagens/planta: ${registro.vagensPlanta!.toStringAsFixed(1)}');
    }
    
    if (estagio.recomendacoes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('💡 Recomendações Agronômicas:');
      for (final rec in estagio.recomendacoes) {
        buffer.writeln('• $rec');
      }
    }
    
    return buffer.toString();
  }

  /// Validar se o estágio está dentro do esperado
  static bool validarEstagio({
    required PhenologicalStageModel estagio,
    required int diasAposEmergencia,
  }) {
    if (estagio.daeMinimo == null || estagio.daeMaximo == null) {
      return true; // Sem validação
    }
    
    return diasAposEmergencia >= estagio.daeMinimo! &&
           diasAposEmergencia <= estagio.daeMaximo!;
  }

  /// Calcular atraso ou adiantamento em dias
  static int calcularDesvioDAE({
    required PhenologicalStageModel estagio,
    required int diasAposEmergencia,
  }) {
    if (estagio.daeMinimo == null || estagio.daeMaximo == null) {
      return 0;
    }
    
    final daeEsperado = ((estagio.daeMinimo! + estagio.daeMaximo!) / 2).round();
    return diasAposEmergencia - daeEsperado;
  }

  /// 🌾 Classificação Automática para ALGODÃO
  static PhenologicalStageModel? _classificarAlgodao(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('algodao');
    final dae = r.diasAposEmergencia;
    final numFolhas = r.numeroFolhas;

    // FASE REPRODUTIVA
    if (dae >= 110) return estagios.firstWhere((e) => e.codigo == 'C2'); // Capulho maduro
    if (dae >= 65) return estagios.firstWhere((e) => e.codigo == 'C1'); // Primeiro capulho
    if (dae >= 45) return estagios.firstWhere((e) => e.codigo == 'F1'); // Primeira flor
    if (dae >= 35) return estagios.firstWhere((e) => e.codigo == 'B1'); // Botão floral
    
    // FASE VEGETATIVA
    if (numFolhas != null && numFolhas >= 4) {
      return estagios.firstWhere((e) => e.codigo == 'V4');
    }
    if (numFolhas != null && numFolhas >= 1) {
      return estagios.firstWhere((e) => e.codigo == 'V1');
    }
    if (dae >= 5) return estagios.firstWhere((e) => e.codigo == 'VE');
    
    return null;
  }

  /// 🌾 Classificação Automática para SORGO
  static PhenologicalStageModel? _classificarSorgo(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('sorgo');
    final dae = r.diasAposEmergencia;
    final numFolhas = r.numeroFolhas;

    // FASE REPRODUTIVA
    if (dae >= 120) return estagios.firstWhere((e) => e.codigo == 'MF');
    if (dae >= 105) return estagios.firstWhere((e) => e.codigo == 'GF');
    if (dae >= 90) return estagios.firstWhere((e) => e.codigo == 'GL');
    if (dae >= 75) return estagios.firstWhere((e) => e.codigo == 'FL');
    if (dae >= 60) return estagios.firstWhere((e) => e.codigo == 'EB');
    if (dae >= 45) return estagios.firstWhere((e) => e.codigo == 'BF');
    
    // FASE VEGETATIVA
    if (numFolhas != null) {
      if (numFolhas >= 6) return estagios.firstWhere((e) => e.codigo == 'V6');
      if (numFolhas >= 3) return estagios.firstWhere((e) => e.codigo == 'V3');
    }
    if (dae >= 5) return estagios.firstWhere((e) => e.codigo == 'VE');
    
    return null;
  }

  /// 🌰 Classificação Automática para GERGELIM
  static PhenologicalStageModel? _classificarGergelim(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('gergelim');
    final dae = r.diasAposEmergencia;
    final numFolhas = r.numeroFolhas;

    // FASE REPRODUTIVA
    if (dae >= 95) return estagios.firstWhere((e) => e.codigo == 'R9'); // Maturação
    if (dae >= 85) return estagios.firstWhere((e) => e.codigo == 'R7'); // Início maturação
    if (dae >= 70) return estagios.firstWhere((e) => e.codigo == 'R5'); // Enchimento cápsulas
    if (dae >= 55) return estagios.firstWhere((e) => e.codigo == 'R3'); // Formação cápsulas
    if (dae >= 45) return estagios.firstWhere((e) => e.codigo == 'R2'); // Floração plena
    if (dae >= 35) return estagios.firstWhere((e) => e.codigo == 'R1'); // Início florescimento
    
    // FASE VEGETATIVA
    if (numFolhas != null && numFolhas >= 4) {
      return estagios.firstWhere((e) => e.codigo == 'V4');
    }
    if (numFolhas != null && numFolhas >= 2) {
      return estagios.firstWhere((e) => e.codigo == 'V2');
    }
    if (dae >= 5) return estagios.firstWhere((e) => e.codigo == 'VE');
    
    return null;
  }

  /// 🌾 Classificação Automática para CANA-DE-AÇÚCAR
  static PhenologicalStageModel? _classificarCana(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('cana');
    final dae = r.diasAposEmergencia;

    // Cana tem ciclo longo
    if (dae >= 300) return estagios.firstWhere((e) => e.codigo == 'MA'); // Maturação
    if (dae >= 100) return estagios.firstWhere((e) => e.codigo == 'CE'); // Crescimento colmos
    if (dae >= 40) return estagios.firstWhere((e) => e.codigo == 'PE'); // Perfilhamento
    if (dae >= 15) return estagios.firstWhere((e) => e.codigo == 'G'); // Germinação
    
    return null;
  }

  /// 🍅 Classificação Automática para TOMATE
  static PhenologicalStageModel? _classificarTomate(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('tomate');
    final dae = r.diasAposEmergencia;
    final numFolhas = r.numeroFolhas;

    // FASE REPRODUTIVA - Baseado em cor dos frutos (se registrado nas observações)
    if (dae >= 85) return estagios.firstWhere((e) => e.codigo == 'R6'); // Maturação plena
    if (dae >= 75) return estagios.firstWhere((e) => e.codigo == 'R5'); // Breaker
    if (dae >= 65) return estagios.firstWhere((e) => e.codigo == 'R4'); // Crescimento frutos
    if (dae >= 55) return estagios.firstWhere((e) => e.codigo == 'R3'); // Frutificação
    if (dae >= 45) return estagios.firstWhere((e) => e.codigo == 'R2'); // Floração penca
    if (dae >= 35) return estagios.firstWhere((e) => e.codigo == 'R1'); // Primeira inflorescência
    
    // FASE VEGETATIVA
    if (numFolhas != null && numFolhas >= 6) {
      return estagios.firstWhere((e) => e.codigo == 'V6');
    }
    if (numFolhas != null && numFolhas >= 2) {
      return estagios.firstWhere((e) => e.codigo == 'V2');
    }
    if (dae >= 6) return estagios.firstWhere((e) => e.codigo == 'VE');
    
    return null;
  }

  /// 🌾 Classificação Automática para TRIGO
  static PhenologicalStageModel? _classificarTrigo(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('trigo');
    final dae = r.diasAposEmergencia;

    // FASE REPRODUTIVA
    if (dae >= 125) return estagios.firstWhere((e) => e.codigo == 'MF'); // Maturação
    if (dae >= 110) return estagios.firstWhere((e) => e.codigo == 'GM'); // Grão massa
    if (dae >= 95) return estagios.firstWhere((e) => e.codigo == 'GL'); // Grão leitoso
    if (dae >= 85) return estagios.firstWhere((e) => e.codigo == 'FL'); // Floração
    if (dae >= 75) return estagios.firstWhere((e) => e.codigo == 'ES'); // Espigamento
    if (dae >= 60) return estagios.firstWhere((e) => e.codigo == 'EB'); // Emborrachamento
    
    // FASE VEGETATIVA
    if (dae >= 40) return estagios.firstWhere((e) => e.codigo == 'EL'); // Elongação
    if (dae >= 20) return estagios.firstWhere((e) => e.codigo == 'AP'); // Afilhamento
    if (dae >= 7) return estagios.firstWhere((e) => e.codigo == 'VE'); // Emergência
    
    return null;
  }

  /// 🌾 Classificação Automática para AVEIA
  static PhenologicalStageModel? _classificarAveia(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('aveia');
    final dae = r.diasAposEmergencia;

    // FASE REPRODUTIVA
    if (dae >= 130) return estagios.firstWhere((e) => e.codigo == 'MF'); // Maturação
    if (dae >= 115) return estagios.firstWhere((e) => e.codigo == 'GF'); // Grão farináceo
    if (dae >= 100) return estagios.firstWhere((e) => e.codigo == 'GL'); // Grão leitoso
    if (dae >= 85) return estagios.firstWhere((e) => e.codigo == 'FL'); // Floração
    if (dae >= 75) return estagios.firstWhere((e) => e.codigo == 'EP'); // Espigamento
    if (dae >= 60) return estagios.firstWhere((e) => e.codigo == 'EB'); // Emborrachamento
    
    // FASE VEGETATIVA
    if (dae >= 40) return estagios.firstWhere((e) => e.codigo == 'EL'); // Elongação
    if (dae >= 20) return estagios.firstWhere((e) => e.codigo == 'AF'); // Afilhamento
    if (dae >= 15 && r.numeroFolhas != null && r.numeroFolhas! >= 3) {
      return estagios.firstWhere((e) => e.codigo == 'V3');
    }
    if (dae >= 7) return estagios.firstWhere((e) => e.codigo == 'VE');
    
    return null;
  }

  /// 🌻 Classificação Automática para GIRASSOL
  static PhenologicalStageModel? _classificarGirassol(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('girassol');
    final dae = r.diasAposEmergencia;
    final numFolhas = r.numeroFolhas;

    // FASE REPRODUTIVA
    if (dae >= 110) return estagios.firstWhere((e) => e.codigo == 'R9'); // Maturação
    if (dae >= 85) return estagios.firstWhere((e) => e.codigo == 'R6'); // Fim floração
    if (dae >= 75) return estagios.firstWhere((e) => e.codigo == 'R5'); // Floração plena
    if (dae >= 65) return estagios.firstWhere((e) => e.codigo == 'R4'); // Abertura capítulo
    if (dae >= 50) return estagios.firstWhere((e) => e.codigo == 'R1'); // Botão floral
    
    // FASE VEGETATIVA - Baseado em pares de folhas
    if (numFolhas != null) {
      if (numFolhas >= 8) return estagios.firstWhere((e) => e.codigo == 'V8'); // 8 pares = 16 folhas
      if (numFolhas >= 4) return estagios.firstWhere((e) => e.codigo == 'V4'); // 4 pares = 8 folhas
    }
    if (dae >= 7) return estagios.firstWhere((e) => e.codigo == 'VE');
    
    return null;
  }

  /// 🍚 Classificação Automática para ARROZ
  static PhenologicalStageModel? _classificarArroz(PhenologicalRecordModel r) {
    final estagios = PhenologicalStageDatabase.getEstagiosPorCultura('arroz');
    final dae = r.diasAposEmergencia;
    final numFolhas = r.numeroFolhas;

    // FASE REPRODUTIVA
    if (dae >= 125) return estagios.firstWhere((e) => e.codigo == 'MF'); // Maturação
    if (dae >= 110) return estagios.firstWhere((e) => e.codigo == 'GF'); // Grão farináceo
    if (dae >= 95) return estagios.firstWhere((e) => e.codigo == 'GL'); // Grão leitoso
    if (dae >= 80) return estagios.firstWhere((e) => e.codigo == 'FL'); // Floração
    if (dae >= 65) return estagios.firstWhere((e) => e.codigo == 'EP'); // Emborrachamento
    if (dae >= 45) return estagios.firstWhere((e) => e.codigo == 'IP'); // Iniciação panícula
    
    // FASE VEGETATIVA
    if (dae >= 25) return estagios.firstWhere((e) => e.codigo == 'PE'); // Perfilhamento
    if (dae >= 15 && numFolhas != null && numFolhas >= 3) {
      return estagios.firstWhere((e) => e.codigo == 'V3');
    }
    if (dae >= 5) return estagios.firstWhere((e) => e.codigo == 'VE');
    
    return null;
  }
}

