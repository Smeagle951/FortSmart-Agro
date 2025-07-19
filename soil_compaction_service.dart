import 'dart:math';
import 'package:flutter/material.dart';
import 'soil_compaction_model.dart';

class SoilCompactionService {
  // Constante para conversão de kgf para N (Newton)
  static const double _kgfToNewton = 9.80665;
  
  // Constante para conversão de mm² para m²
  static const double _mm2ToM2 = 0.000001;
  
  // Constante para conversão de N/m² para MPa
  static const double _paToMpa = 0.000001;

  /// Calcula a Resistência à Penetração (RP) em MPa
  /// 
  /// Fórmula: RP = F / A
  /// Onde:
  /// - RP = Resistência à Penetração (MPa)
  /// - F = Força aplicada (kgf convertido para N)
  /// - A = Área do cone (mm² convertido para m²)
  double calcularRP({
    required double forcaAplicada, // em kgf
    required double diametroCone, // em mm
  }) {
    // Converter força de kgf para N
    final forcaNewton = forcaAplicada * _kgfToNewton;
    
    // Calcular área do cone em mm²
    final areaCone = pi * pow(diametroCone / 2, 2);
    
    // Converter área de mm² para m²
    final areaConeM2 = areaCone * _mm2ToM2;
    
    // Calcular RP em Pa (N/m²)
    final rpPa = forcaNewton / areaConeM2;
    
    // Converter Pa para MPa
    final rpMpa = rpPa * _paToMpa;
    
    return rpMpa;
  }

  /// Interpreta o valor de RP e retorna uma string com a classificação
  String interpretarRP(double rp) {
    if (rp < 1.0) {
      return 'Baixa';
    } else if (rp < 2.0) {
      return 'Média';
    } else if (rp < 3.0) {
      return 'Alta';
    } else {
      return 'Muito Alta';
    }
  }

  /// Retorna a cor correspondente à interpretação do RP
  Color getCorInterpretacao(String interpretacao) {
    switch (interpretacao) {
      case 'Baixa':
        return Colors.green;
      case 'Média':
        return Colors.yellow;
      case 'Alta':
        return Colors.orange;
      case 'Muito Alta':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Calcula o RP, interpreta e retorna um modelo atualizado
  SoilCompactionModel calcularEInterpretarRP(SoilCompactionModel modelo) {
    if (modelo.forcaAplicada == null || modelo.diametroCone == null) {
      return modelo;
    }

    final rp = calcularRP(
      forcaAplicada: modelo.forcaAplicada!,
      diametroCone: modelo.diametroCone!,
    );

    final interpretacao = interpretarRP(rp);
    final cor = getCorInterpretacao(interpretacao);

    return modelo.copyWith(
      resistenciaPenetracao: rp,
      interpretacao: interpretacao,
      cor: cor,
    );
  }
}
