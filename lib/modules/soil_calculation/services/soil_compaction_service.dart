import 'dart:math';
import 'package:flutter/material.dart';

class SoilCompactionService {
  static const double GRAVIDADE = 9.81; // m/s²

  /// Calcula a resistência à penetração usando o método simples
  /// 
  /// [pesoMartelo] - Peso do martelo em kg
  /// [numGolpes] - Número de golpes
  /// [distanciaTotal] - Distância total de penetração em metros
  /// 
  /// Retorna a resistência em MPa
  static double calcularRPSimples({
    required double pesoMartelo,
    required int numGolpes,
    required double distanciaTotal,
  }) {
    // Fórmula: RP = (Peso × Número de golpes) / Distância
    // Convertendo para MPa (1 kgf/cm² ≈ 0.0980665 MPa)
    double rpKgfCm2 = (pesoMartelo * numGolpes) / distanciaTotal;
    double rpMPa = rpKgfCm2 * 0.0980665;
    return rpMPa;
  }

  /// Calcula o Índice de Resistência à Penetração (IRP) usando o método avançado
  /// 
  /// [numeroGolpes] - Número de golpes
  /// [pesoMartelo] - Peso do martelo em kg
  /// [alturaQueda] - Altura da queda em metros
  /// [distanciaTotal] - Distância total de penetração em metros
  /// [diametroPonteira] - Diâmetro da ponteira em centímetros
  /// [anguloPonteira] - Ângulo da ponteira em graus (opcional)
  /// 
  /// Retorna a resistência em MPa
  static double calcularIRP({
    required int numeroGolpes,
    required double pesoMartelo,
    required double alturaQueda,
    required double distanciaTotal,
    required double diametroPonteira,
    double? anguloPonteira,
  }) {
    // Converter diâmetro cm → m
    double raio = (diametroPonteira / 100) / 2;

    // Calcular área
    double area;
    if (anguloPonteira != null && anguloPonteira > 0) {
      // Área com ângulo: A = π * r² / sin(θ)
      area = (pi * (raio * raio)) / (sin(anguloPonteira * (pi / 180)));
    } else {
      // Área circular padrão: A = π * r²
      area = pi * (raio * raio);
    }

    // Calcular RP: RP = (N * m * g * h) / (A * d)
    double rpPascal = (numeroGolpes * pesoMartelo * GRAVIDADE * alturaQueda) /
        (area * distanciaTotal);

    // Converter para MPa (1 MPa = 1,000,000 Pa)
    double rpMPa = rpPascal / 1000000;
    return rpMPa;
  }

  /// Interpreta o resultado da resistência à penetração
  /// 
  /// [rp] - Resistência à penetração em MPa
  /// 
  /// Retorna um mapa com a interpretação como texto e a cor correspondente
  static Map<String, dynamic> interpretarIRP(double rp) {
    String interpretacao;
    Color cor;
    
    if (rp < 1.5) {
      interpretacao = 'Sem Compactação';
      cor = const Color(0xFF4CAF50); // Verde
    } else if (rp >= 1.5 && rp < 2.0) {
      interpretacao = 'Leve Compactação';
      cor = const Color(0xFFFFEB3B); // Amarelo
    } else if (rp >= 2.0 && rp < 2.5) {
      interpretacao = 'Moderada Compactação';
      cor = const Color(0xFFFF9800); // Laranja
    } else {
      interpretacao = 'Alta Compactação';
      cor = const Color(0xFFF44336); // Vermelho
    }
    
    return {
      'interpretacao': interpretacao,
      'cor': cor,
    };
  }
  
  /// Método legado para compatibilidade
  /// Interpreta o resultado da resistência à penetração
  /// 
  /// [rp] - Resistência à penetração em MPa
  /// 
  /// Retorna a interpretação como texto
  static String interpretarRP(double rp) {
    return interpretarIRP(rp)['interpretacao'];
  }

  /// Retorna a cor correspondente à interpretação da resistência à penetração
  /// 
  /// [interpretacao] - Interpretação da resistência à penetração
  /// 
  /// Retorna a cor como objeto Color
  static Color getCorInterpretacao(String interpretacao) {
    switch (interpretacao) {
      case 'Sem Compactação':
        return const Color(0xFF4CAF50); // Verde
      case 'Leve Compactação':
        return const Color(0xFFFFEB3B); // Amarelo
      case 'Moderada Compactação':
        return const Color(0xFFFF9800); // Laranja
      case 'Alta Compactação':
        return const Color(0xFFF44336); // Vermelho
      default:
        return const Color(0xFF9E9E9E); // Cinza (caso não reconhecido)
    }
  }
}
