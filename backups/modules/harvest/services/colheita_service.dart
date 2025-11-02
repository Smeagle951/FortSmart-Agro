import '../models/colheita_model.dart';
import '../repositories/colheita_repository.dart';

class ColheitaService {
  final ColheitaRepository _repository = ColheitaRepository();

  Future<List<ColheitaModel>> getAllColheitas() async {
    return await _repository.getAll();
  }

  Future<List<ColheitaModel>> getColheitasByFilters({
    int? talhaoId,
    int? culturaId,
    String? dataInicio,
    String? dataFim,
  }) async {
    return await _repository.getByFilters(
      talhaoId: talhaoId,
      culturaId: culturaId,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );
  }

  Future<ColheitaModel?> getColheitaById(int id) async {
    return await _repository.getById(id);
  }

  Future<void> saveColheita(ColheitaModel colheita) async {
    if (colheita.id != null) {
      await _repository.update(colheita);
    } else {
      await _repository.insert(colheita);
    }
  }

  Future<void> deleteColheita(int id) async {
    await _repository.delete(id);
  }

  // Calcular total colhido em sacas
  double calcularTotalColhido(double areaColhida, double produtividade) {
    return areaColhida * produtividade;
  }
}
