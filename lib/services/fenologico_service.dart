import 'package:flutter/material.dart';

class FenologicoService {
  static Map<String, dynamic> calcularDadosFenologicos(DateTime dataEmergencia, int cicloDias, String cultura) {
    final dae = DateTime.now().difference(dataEmergencia).inDays;
    final dac = cicloDias - dae;

    String estagio = definirEstagio(dae, cultura);

    return {
      'DAE': dae,
      'DAC': dac < 0 ? 0 : dac,
      'Estagio': estagio,
      'ProntoParaColheita': dac <= 0
    };
  }

  static String definirEstagio(int dae, String cultura) {
    if (cultura.toLowerCase() == 'soja') {
      if (dae <= 5) return 'Emergência (VE)';
      if (dae <= 10) return 'Cotilédone (VC)';
      if (dae <= 20) return 'Primeiro trifólio (V1)';
      if (dae <= 30) return 'Vegetativo (V2-V3)';
      if (dae <= 45) return 'Vegetativo (V4-V6)';
      if (dae <= 60) return 'Florescimento (R1-R2)';
      if (dae <= 80) return 'Desenvolvimento de vagens (R3-R4)';
      if (dae <= 100) return 'Enchimento de grãos (R5-R6)';
      if (dae <= 120) return 'Maturação (R7-R8)';
    } else if (cultura.toLowerCase() == 'milho') {
      if (dae <= 7) return 'Emergência (VE)';
      if (dae <= 14) return 'Vegetativo inicial (V1-V3)';
      if (dae <= 28) return 'Vegetativo (V4-V6)';
      if (dae <= 42) return 'Pré-florescimento (V7-V10)';
      if (dae <= 56) return 'Florescimento (VT-R1)';
      if (dae <= 70) return 'Grão leitoso (R2-R3)';
      if (dae <= 84) return 'Grão pastoso (R4)';
      if (dae <= 98) return 'Grão farináceo (R5)';
      if (dae <= 120) return 'Maturação (R6)';
    } else if (cultura.toLowerCase() == 'algodão') {
      if (dae <= 7) return 'Emergência';
      if (dae <= 35) return 'Vegetativo';
      if (dae <= 60) return 'Florescimento';
      if (dae <= 100) return 'Frutificação';
      if (dae <= 180) return 'Maturação';
    } else if (cultura.toLowerCase() == 'feijão') {
      if (dae <= 5) return 'Emergência (VE)';
      if (dae <= 20) return 'Vegetativo (V1-V4)';
      if (dae <= 40) return 'Florescimento (R5-R6)';
      if (dae <= 60) return 'Formação de vagens (R7-R8)';
      if (dae <= 90) return 'Maturação (R9)';
    }
    return 'Fora do ciclo';
  }

  // Retorna os estágios fenológicos para uma cultura específica
  // para uso em gráficos e visualizações
  static List<Map<String, dynamic>> getEstagiosFenologicos(String cultura, int cicloDias) {
    List<Map<String, dynamic>> estagios = [];
    
    if (cultura.toLowerCase() == 'soja') {
      estagios = [
        {'nome': 'Emergência (VE)', 'inicio': 0, 'fim': 5, 'cor': Colors.lightGreen},
        {'nome': 'Cotilédone (VC)', 'inicio': 6, 'fim': 10, 'cor': Colors.green.shade300},
        {'nome': 'Primeiro trifólio (V1)', 'inicio': 11, 'fim': 20, 'cor': Colors.green.shade400},
        {'nome': 'Vegetativo (V2-V3)', 'inicio': 21, 'fim': 30, 'cor': Colors.green.shade500},
        {'nome': 'Vegetativo (V4-V6)', 'inicio': 31, 'fim': 45, 'cor': Colors.green.shade600},
        {'nome': 'Florescimento (R1-R2)', 'inicio': 46, 'fim': 60, 'cor': Colors.purple.shade300},
        {'nome': 'Desenvolvimento de vagens (R3-R4)', 'inicio': 61, 'fim': 80, 'cor': Colors.orange.shade300},
        {'nome': 'Enchimento de grãos (R5-R6)', 'inicio': 81, 'fim': 100, 'cor': Colors.amber.shade600},
        {'nome': 'Maturação (R7-R8)', 'inicio': 101, 'fim': cicloDias, 'cor': Colors.brown.shade400},
      ];
    } else if (cultura.toLowerCase() == 'milho') {
      estagios = [
        {'nome': 'Emergência (VE)', 'inicio': 0, 'fim': 7, 'cor': Colors.lightGreen},
        {'nome': 'Vegetativo inicial (V1-V3)', 'inicio': 8, 'fim': 14, 'cor': Colors.green.shade300},
        {'nome': 'Vegetativo (V4-V6)', 'inicio': 15, 'fim': 28, 'cor': Colors.green.shade500},
        {'nome': 'Pré-florescimento (V7-V10)', 'inicio': 29, 'fim': 42, 'cor': Colors.green.shade700},
        {'nome': 'Florescimento (VT-R1)', 'inicio': 43, 'fim': 56, 'cor': Colors.yellow.shade300},
        {'nome': 'Grão leitoso (R2-R3)', 'inicio': 57, 'fim': 70, 'cor': Colors.yellow.shade600},
        {'nome': 'Grão pastoso (R4)', 'inicio': 71, 'fim': 84, 'cor': Colors.orange.shade300},
        {'nome': 'Grão farináceo (R5)', 'inicio': 85, 'fim': 98, 'cor': Colors.amber.shade600},
        {'nome': 'Maturação (R6)', 'inicio': 99, 'fim': cicloDias, 'cor': Colors.brown.shade400},
      ];
    } else if (cultura.toLowerCase() == 'algodão') {
      estagios = [
        {'nome': 'Emergência', 'inicio': 0, 'fim': 7, 'cor': Colors.lightGreen},
        {'nome': 'Vegetativo', 'inicio': 8, 'fim': 35, 'cor': Colors.green.shade500},
        {'nome': 'Florescimento', 'inicio': 36, 'fim': 60, 'cor': Colors.yellow.shade300},
        {'nome': 'Frutificação', 'inicio': 61, 'fim': 100, 'cor': Colors.orange.shade400},
        {'nome': 'Maturação', 'inicio': 101, 'fim': cicloDias, 'cor': Colors.brown.shade400},
      ];
    } else if (cultura.toLowerCase() == 'feijão') {
      estagios = [
        {'nome': 'Emergência (VE)', 'inicio': 0, 'fim': 5, 'cor': Colors.lightGreen},
        {'nome': 'Vegetativo (V1-V4)', 'inicio': 6, 'fim': 20, 'cor': Colors.green.shade500},
        {'nome': 'Florescimento (R5-R6)', 'inicio': 21, 'fim': 40, 'cor': Colors.purple.shade300},
        {'nome': 'Formação de vagens (R7-R8)', 'inicio': 41, 'fim': 60, 'cor': Colors.orange.shade300},
        {'nome': 'Maturação (R9)', 'inicio': 61, 'fim': cicloDias, 'cor': Colors.brown.shade400},
      ];
    } else {
      // Cultura não específica
      estagios = [
        {'nome': 'Emergência', 'inicio': 0, 'fim': cicloDias * 0.05, 'cor': Colors.lightGreen},
        {'nome': 'Vegetativo', 'inicio': cicloDias * 0.05 + 1, 'fim': cicloDias * 0.4, 'cor': Colors.green.shade500},
        {'nome': 'Reprodutivo', 'inicio': cicloDias * 0.4 + 1, 'fim': cicloDias * 0.7, 'cor': Colors.yellow.shade600},
        {'nome': 'Maturação', 'inicio': cicloDias * 0.7 + 1, 'fim': cicloDias, 'cor': Colors.brown.shade400},
      ];
    }
    
    return estagios;
  }
  
  // Retorna a cor associada ao estágio atual
  static Color getEstagioColor(int dae, String cultura, int cicloDias) {
    final estagios = getEstagiosFenologicos(cultura, cicloDias);
    for (var estagio in estagios) {
      if (dae >= estagio['inicio'] && dae <= estagio['fim']) {
        return estagio['cor'];
      }
    }
    return Colors.grey;
  }
}
