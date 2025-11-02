import '../models/calibragem_adubo_model.dart';
import '../repositories/calibragem_adubo_repository.dart';

class CalibragemAduboService {
  final CalibragemAduboRepository _repository = CalibragemAduboRepository();

  Future<void> saveCalibragemAdubo(CalibragemAduboModel calibragem) async {
    if (calibragem.id != null) {
      await _repository.update(calibragem);
    } else {
      await _repository.insert(calibragem);
    }
  }

  Future<List<CalibragemAduboModel>> getAllCalibragems() async {
    return await _repository.getAll();
  }

  Future<CalibragemAduboModel?> getCalibragemById(int id) async {
    return await _repository.getById(id);
  }

  Future<void> deleteCalibragem(int id) async {
    await _repository.delete(id);
  }

  // Métodos de cálculo delegados ao modelo
  double calcularAreaPercorrida(double distancia, int numeroLinhas, double espacamentoEntreLinhas) {
    return CalibragemAduboModel.calcularAreaPercorrida(distancia, numeroLinhas, espacamentoEntreLinhas);
  }

  double calcularKgPorHa(double gramasColetadas, bool coletaPorLinha, int numeroLinhas, double areaPercorridaHa) {
    return CalibragemAduboModel.calcularKgPorHa(gramasColetadas, coletaPorLinha, numeroLinhas, areaPercorridaHa);
  }

  double calcularSacasPorHa(double kgPorHa, [double pesoDaSaca = 50.0]) {
    return CalibragemAduboModel.calcularSacasPorHa(kgPorHa, pesoDaSaca);
  }

  double calcularErroPorcentagem(double valorAtual, double valorDesejado, bool emSacas) {
    return CalibragemAduboModel.calcularErroPorcentagem(valorAtual, valorDesejado, emSacas);
  }

  // Função para realizar todos os cálculos de uma vez
  Map<String, double> calcularResultados({
    required bool coletaPorLinha,
    required double gramasColetadas,
    required double distanciaPercorrida,
    required int numeroLinhas,
    required double espacamentoEntreLinhas,
    required double valorDesejado,
    required bool usaUnidadeSacas,
  }) {
    // Cálculo da área percorrida em hectares
    double areaPercorridaHa = calcularAreaPercorrida(
      distanciaPercorrida, 
      numeroLinhas, 
      espacamentoEntreLinhas
    );
    
    // Cálculo da aplicação em kg/ha
    double kgPorHa = calcularKgPorHa(
      gramasColetadas, 
      coletaPorLinha, 
      numeroLinhas, 
      areaPercorridaHa
    );
    
    // Conversão para sacas/ha
    double sacasPorHa = calcularSacasPorHa(kgPorHa);
    
    // Se a meta está em sacas, compara com sacas, senão compara com kg/ha
    double valorAtual = usaUnidadeSacas ? sacasPorHa : kgPorHa;
    
    // Cálculo do erro em relação à meta
    double erroPorcentagem = calcularErroPorcentagem(
      valorAtual, 
      valorDesejado, 
      usaUnidadeSacas
    );
    
    return {
      'areaPercorridaHa': areaPercorridaHa,
      'kgPorHa': kgPorHa,
      'sacasPorHa': sacasPorHa,
      'erroPorcentagem': erroPorcentagem,
    };
  }

  // Sugestão de ajuste de engrenagem baseada no erro
  String getSugestaoAjuste(double erroPorcentagem) {
    if (erroPorcentagem.abs() <= 5.0) {
      return 'Calibragem adequada, dentro da tolerância de ±5%.';
    } else if (erroPorcentagem > 5.0) {
      return 'Reduzir a aplicação. Sugestão: aumentar a engrenagem movida ou diminuir a motora.';
    } else {
      return 'Aumentar a aplicação. Sugestão: diminuir a engrenagem movida ou aumentar a motora.';
    }
  }
}
