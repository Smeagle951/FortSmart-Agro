import '../models/plot.dart';
import '../repositories/plot_repository.dart';

class PlotService {
  final PlotRepository _repository = PlotRepository();

  // Obter todos os talhões
  Future<List<Plot>> getAllPlots() async {
    return await _repository.getAllPlots();
  }

  // Obter talhões por fazenda
  Future<List<Plot>> getPlotsByFarm(String farmId) async {
    return await _repository.getPlotsByFarm(int.parse(farmId));
  }

  // Obter um talhão pelo ID
  Future<Plot?> getPlotById(String id) async {
    return await _repository.getPlotById(id);
  }

  // Adicionar um novo talhão
  Future<String> addPlot(Plot plot) async {
    final result = await _repository.addPlot(plot);
    return result ?? '';
  }

  // Atualizar um talhão existente
  Future<bool> updatePlot(Plot plot) async {
    return await _repository.updatePlot(plot);
  }

  // Excluir um talhão
  Future<bool> deletePlot(String id) async {
    return await _repository.deletePlot(id);
  }

  // Calcular área total de talhões por fazenda
  Future<double> calculateTotalAreaByFarm(String farmId) async {
    final plots = await getPlotsByFarm(farmId);
    double totalArea = 0;
    
    for (var plot in plots) {
      if (plot.area != null) {
        totalArea += plot.area!;
      }
    }
    
    return totalArea;
  }
}
