import '../models/calibragem_sementes_model.dart';
import '../repositories/calibragem_sementes_repository.dart';

class CalibragemSementesService {
  final CalibragemSementesRepository _repository = CalibragemSementesRepository();

  Future<void> saveCalibragemSementes(CalibragemSementesModel calibragem) async {
    if (calibragem.id != null) {
      await _repository.update(calibragem);
    } else {
      await _repository.insert(calibragem);
    }
  }

  Future<List<CalibragemSementesModel>> getAllCalibragems() async {
    return await _repository.getAll();
  }

  Future<CalibragemSementesModel?> getCalibragemById(int id) async {
    return await _repository.getById(id);
  }

  Future<void> deleteCalibragem(int id) async {
    await _repository.delete(id);
  }

  // Métodos de cálculo delegados ao modelo
  double calcularSementesPorMetro(double sementesColetadas, int linhasColetadas) {
    return CalibragemSementesModel.calcularSementesPorMetro(sementesColetadas, linhasColetadas);
  }

  double calcularSementesPorMetroVacuo(int numeroFuros, int engrenagemMotora, int engrenagemMovida) {
    return CalibragemSementesModel.calcularSementesPorMetroVacuo(numeroFuros, engrenagemMotora, engrenagemMovida);
  }

  double calcularPlantasPorHectare(double sementesPorMetro, double espacamentoEntreLinhas) {
    return CalibragemSementesModel.calcularPlantasPorHectare(sementesPorMetro, espacamentoEntreLinhas);
  }

  double calcularErroPorcentagem(double plantasPorHectare, double populacaoDesejada) {
    return CalibragemSementesModel.calcularErroPorcentagem(plantasPorHectare, populacaoDesejada);
  }

  // Função para realizar todos os cálculos de uma vez
  Map<String, double> calcularResultados({
    required double sementesColetadas,
    required int linhasColetadas,
    required double espacamentoEntreLinhas,
    double? populacaoDesejada,
  }) {
    double sementesPorMetro = calcularSementesPorMetro(sementesColetadas, linhasColetadas);
    double plantasPorHectare = calcularPlantasPorHectare(sementesPorMetro, espacamentoEntreLinhas);
    double plantasPorMetro = sementesPorMetro; // Assumimos que cada semente = 1 planta (pode variar conforme necessidade)
    double plantasPorMetroQuadrado = plantasPorHectare / 10000; // 1 ha = 10.000 m²
    
    double? erroPorcentagem;
    if (populacaoDesejada != null && populacaoDesejada > 0) {
      erroPorcentagem = calcularErroPorcentagem(plantasPorHectare, populacaoDesejada);
    }
    
    return {
      'sementesPorMetro': sementesPorMetro,
      'plantasPorMetro': plantasPorMetro,
      'plantasPorHectare': plantasPorHectare,
      'plantasPorMetroQuadrado': plantasPorMetroQuadrado,
      'erroPorcentagem': erroPorcentagem ?? 0.0,
    };
  }
  
  // Função para cálculos do disco com engrenagens
  Map<String, double> calcularResultadosVacuo({
    required int numeroFuros,
    required int engrenagemMotora,
    required int engrenagemMovida,
    required double espacamentoEntreLinhas,
    double? populacaoDesejada,
  }) {
    double sementesPorMetro = calcularSementesPorMetroVacuo(
      numeroFuros, engrenagemMotora, engrenagemMovida);
    double plantasPorHectare = calcularPlantasPorHectare(sementesPorMetro, espacamentoEntreLinhas);
    double plantasPorMetro = sementesPorMetro; // Assumimos que cada semente = 1 planta
    double plantasPorMetroQuadrado = plantasPorHectare / 10000;
    
    double? erroPorcentagem;
    if (populacaoDesejada != null && populacaoDesejada > 0) {
      erroPorcentagem = calcularErroPorcentagem(plantasPorHectare, populacaoDesejada);
    }
    
    return {
      'sementesPorMetro': sementesPorMetro,
      'plantasPorMetro': plantasPorMetro,
      'plantasPorHectare': plantasPorHectare,
      'plantasPorMetroQuadrado': plantasPorMetroQuadrado,
      'erroPorcentagem': erroPorcentagem ?? 0.0,
    };
  }
}
