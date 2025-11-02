import '../models/perda_colheita_model.dart';
import '../repositories/perda_colheita_repository.dart';

class PerdaColheitaService {
  final PerdaColheitaRepository _repository = PerdaColheitaRepository();

  Future<List<PerdaColheitaModel>> getAllPerdasColheita() async {
    return await _repository.getAll();
  }

  Future<List<PerdaColheitaModel>> getPerdasColheitaByFilters({
    int? talhaoId,
    int? culturaId,
    String? dataInicio,
    String? dataFim,
    String? metodo,
  }) async {
    return await _repository.getByFilters(
      talhaoId: talhaoId,
      culturaId: culturaId,
      dataInicio: dataInicio,
      dataFim: dataFim,
      metodo: metodo,
    );
  }

  Future<PerdaColheitaModel?> getPerdaColheitaById(int id) async {
    return await _repository.getById(id);
  }

  Future<void> savePerdaColheita(PerdaColheitaModel perdaColheita) async {
    if (perdaColheita.id != null) {
      await _repository.update(perdaColheita);
    } else {
      await _repository.insert(perdaColheita);
    }
  }

  Future<void> deletePerdaColheita(int id) async {
    await _repository.delete(id);
  }
  
  // Calcular perda usando método do peso de mil grãos
  double calcularPerdaMilGraos(int espigas, int graosPerdidos, double pesoMilGraos, double areaAmostrada) {
    return PerdaColheitaModel.calcularPerdaMilGraos(espigas, graosPerdidos, pesoMilGraos, areaAmostrada);
  }
  
  // Calcular perda usando método do peso total
  double calcularPerdaPesoTotal(double pesoColetado, double areaAmostrada) {
    return PerdaColheitaModel.calcularPerdaPesoTotal(pesoColetado, areaAmostrada);
  }
  
  // Converter kg/ha para sacas/ha
  double converterKgParaSacas(double kgHa) {
    return PerdaColheitaModel.kgParaSacas(kgHa);
  }
}
