import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/talhao_model_new.dart';
import '../models/poligono_model.dart';
import '../models/plot.dart';
import '../models/crop_model.dart' as app_crop;
import 'talhao_repository.dart';
import 'plot_repository.dart';
import '../utils/google_maps_compatibility.dart' as google;
import 'package:latlong2/latlong.dart';

/// Adaptador para integrar o TalhaoRepository (Mapbox) com o PlotRepository
/// Isso permite que os talhões criados com Mapbox apareçam nos seletores existentes
class TalhaoPlotAdapter {
  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  final PlotRepository _plotRepository = PlotRepository();

  /// Singleton para o adaptador
  static final TalhaoPlotAdapter _instance = TalhaoPlotAdapter._internal();
  
  factory TalhaoPlotAdapter() {
    return _instance;
  }
  
  TalhaoPlotAdapter._internal();

  /// Converte um TalhaoModel para um Plot
  Plot _convertTalhaoToPlot(TalhaoModel talhao) {
    // Converter os pontos do formato LatLng para o formato Google Maps
    List<google.GoogleLatLng> googlePoints = [];
    
    // Percorrer todos os polígonos e seus pontos
    for (var poligono in talhao.poligonos) {
      for (var ponto in poligono.pontos) {
        googlePoints.add(google.GoogleLatLng(ponto.latitude, ponto.longitude));
      }
    }
    
    // Converter para o formato de string JSON esperado pelo Plot
    String polygonsJson = [googlePoints.map((point) => {
      'latitude': point.latitude,
      'longitude': point.longitude
    }).toList()].toString();
    
    // Criar o Plot com os dados do TalhaoModel
    return Plot(
      id: talhao.id.toString(),
      name: talhao.name,
      cropName: talhao.crop?.name ?? '',
      cropType: talhao.crop?.name ?? '',
      area: talhao.area,
      polygonJson: polygonsJson,
      notes: talhao.observacoes ?? '', 
      createdAt: talhao.dataCriacao.toIso8601String(),
      updatedAt: talhao.dataAtualizacao.toIso8601String(),
      farmId: talhao.fazendaId != null ? int.tryParse(talhao.fazendaId.toString()) ?? 1 : 1,
      propertyId: 1, // Usar o ID da propriedade principal por padrão
      isSynced: talhao.sincronizado,
      syncStatus: talhao.sincronizado ? 1 : 0,
    );
  }

  /// Converte um Plot para um TalhaoModel
  Future<TalhaoModel> _convertPlotToTalhao(Plot plot) async {
    // Converter as coordenadas do formato JSON para LatLng
    List<LatLng> pontos = [];
    
    try {
      final polygonJson = plot.polygonJson?.replaceAll("'", '"') ?? '[]';
      final List<dynamic> polygons = json.decode(polygonJson);
      
      // Assumindo que temos apenas um polígono na lista
      if (polygons.isNotEmpty) {
        final polygon = polygons[0];
        
        for (var point in polygon) {
          final latLng = LatLng(
            point['latitude'],
            point['longitude'],
          );
          pontos.add(latLng);
        }
      }
    } catch (e) {
      debugPrint('Erro ao converter polígono: $e');
      // Fornecer uma lista vazia se houver erro na conversão
      pontos = [];
    }
    
    // Criar um PoligonoModel com os pontos extraídos
    final poligono = PoligonoModel.criar(
      pontos: pontos,
      talhaoId: plot.id ?? '',
      area: plot.area ?? 0.0,
      perimetro: 0.0,
    );
    
    // Criar o TalhaoModel com os dados do Plot
    return TalhaoModel(
      id: plot.id ?? '',
      name: plot.name, // name é obrigatório no modelo Plot
      poligonos: [poligono],
      area: plot.area ?? 0.0,
      fazendaId: plot.farmId?.toString(),
      dataCriacao: DateTime.tryParse(plot.createdAt ?? '') ?? DateTime.now(),
      dataAtualizacao: DateTime.tryParse(plot.updatedAt ?? '') ?? DateTime.now(),
      sincronizado: plot.isSynced ?? false,
      observacoes: plot.notes,
      cropId: null,
      safraId: null,
      crop: plot.cropName != null && plot.cropName!.isNotEmpty ? app_crop.Crop(
        id: 'temp_${plot.id}',
        name: plot.cropName!,
        description: '',
        color: Colors.green,
        imageUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ) : null,
      safras: [],

    );
  }

  /// Sincroniza os talhões do Mapbox com o repositório de Plots
  Future<void> syncTalhoesToPlots() async {
    try {
      // Obter todos os talhões do Mapbox
      final talhoes = await _talhaoRepository.getTalhoes();
      
      // Para cada talhão, verificar se já existe um plot correspondente
      for (var talhao in talhoes) {
        // Garantir que estamos usando o modelo correto
        if (talhao.runtimeType.toString() != 'TalhaoModel') {
          debugPrint('Tipo incompatível: ${talhao.runtimeType}. Pulando...');
          continue;
        }
        
        final existingPlot = await _plotRepository.getById(talhao.id.toString());
        
        if (existingPlot == null) {
          // Se não existir, criar um novo plot
          final newPlot = _convertTalhaoToPlot(talhao);
          await _plotRepository.save(newPlot);
          debugPrint('Talhão ${talhao.name} sincronizado como Plot');
        } else {
          // Se existir, atualizar o plot
          final updatedPlot = _convertTalhaoToPlot(talhao);
          await _plotRepository.update(updatedPlot);
          debugPrint('Talhão ${talhao.name} atualizado como Plot');
        }
      }
      
      // Também sincronizar no sentido inverso (Plots para Talhões)
      final plots = await _plotRepository.getAll();
      
      for (var plot in plots) {
        final id = plot.id;
        final existingTalhao = id != null ? await _talhaoRepository.getTalhaoById(int.tryParse(id) ?? 0) : null;
        
        if (existingTalhao == null && id != null) {
          // Se não existir, criar um novo talhão
          final talhao = await _convertPlotToTalhao(plot);
          await _talhaoRepository.addTalhao(talhao);
          debugPrint('Plot ${plot.name} sincronizado como Talhão');
        }
      }
      
      debugPrint('Sincronização entre Talhões e Plots concluída com sucesso');
    } catch (e) {
      debugPrint('Erro ao sincronizar Talhões com Plots: $e');
      rethrow;
    }
  }

  /// Obtém todos os talhões como Plots
  Future<List<Plot>> getAllTalhoesAsPlots() async {
    try {
      // Primeiro sincronizar para garantir que todos os talhões estejam disponíveis como plots
      await syncTalhoesToPlots();
      
      // Então retornar todos os plots
      return await _plotRepository.getAll();
    } catch (e) {
      debugPrint('Erro ao obter talhões como plots: $e');
      return [];
    }
  }

  /// Obtém um talhão específico como Plot
  Future<Plot?> getTalhaoAsPlot(int id) async {
    try {
      // Primeiro sincronizar para garantir que o talhão esteja disponível como plot
      await syncTalhoesToPlots();
      
      // Então retornar o plot específico
      return await _plotRepository.getById(id.toString());
    } catch (e) {
      debugPrint('Erro ao obter talhão como plot: $e');
      return null;
    }
  }

  /// Adiciona um novo talhao (Plot) ao banco de dados
  Future<String> addTalhao(TalhaoModel talhao) async {
    try {
      // Converter TalhaoModel para Plot
      final newPlot = _convertTalhaoToPlot(talhao);
      
      // Adicionar Plot ao banco de dados
      final plotId = await _plotRepository.addPlot(newPlot);
      
      // Retornar o ID do novo Plot
      return plotId ?? '';
    } catch (e) {
      debugPrint('Erro ao adicionar talhao: $e');
      throw e;
    }
  }

  /// Obtém todos os plots como Talhões
  Future<List<TalhaoModel>> getAllPlotsAsTalhoes() async {
    try {
      // Primeiro sincronizar para garantir que todos os plots estejam disponíveis como talhões
      await syncTalhoesToPlots();
      
      // Obter todos os plots
      final plots = await _plotRepository.getAllPlots();
      
      // Convertê-los para TalhaoModel (usando Future.wait para aguardar todas as conversões)
      final List<TalhaoModel> talhoes = await Future.wait(
        plots.map((plot) => _convertPlotToTalhao(plot)).toList()
      );
      
      return talhoes;
    } catch (e) {
      debugPrint('Erro ao obter talhoes: $e');
      return [];
    }
  }
}
