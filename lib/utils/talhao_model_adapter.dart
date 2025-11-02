import 'package:fortsmart_agro/models/talhao_model.dart' as standard;
import 'package:fortsmart_agro/models/talhao_model.dart' as mapbox;

/// Classe adaptadora para converter entre diferentes implementações de TalhaoModel
class TalhaoModelAdapter {
  /// Converte um TalhaoModel padrão para um TalhaoModel do Mapbox
  static mapbox.TalhaoModel toMapboxModel(standard.TalhaoModel model) {
    return mapbox.TalhaoModel(
      id: model.id,
      name: model.name,
      crop: model.crop,
      area: model.area,
      poligonos: model.poligonos,
      observacoes: model.observacoes,
      dataCriacao: model.dataCriacao,
      dataAtualizacao: model.dataAtualizacao,
      criadoPor: model.criadoPor,
      sincronizado: model.sincronizado,
      safras: [],
      points: model.poligonos.isNotEmpty ? model.poligonos.first.pontos : [],
      syncStatus: model.sincronizado ? 1 : 0,
    );
  }

  /// Converte um TalhaoModel do Mapbox para um TalhaoModel padrão
  static standard.TalhaoModel toStandardModel(mapbox.TalhaoModel model) {
    return standard.TalhaoModel(
      id: model.id,
      name: model.name,
      crop: model.crop,
      area: model.area,
      poligonos: model.poligonos,
      observacoes: model.observacoes,
      dataCriacao: model.dataCriacao,
      dataAtualizacao: model.dataAtualizacao,
      criadoPor: model.criadoPor,
      sincronizado: model.sincronizado,
      safras: [],
      points: model.poligonos.isNotEmpty ? model.poligonos.first.pontos : [],
      syncStatus: model.sincronizado ? 1 : 0,
    );
  }

  /// Converte uma lista de TalhaoModel padrão para uma lista de TalhaoModel do Mapbox
  static List<mapbox.TalhaoModel> toMapboxModelList(List<standard.TalhaoModel> models) {
    return models.map((model) => toMapboxModel(model)).toList();
  }

  /// Converte uma lista de TalhaoModel do Mapbox para uma lista de TalhaoModel padrão
  static List<standard.TalhaoModel> toStandardModelList(List<mapbox.TalhaoModel> models) {
    return models.map((model) => toStandardModel(model)).toList();
  }
}
