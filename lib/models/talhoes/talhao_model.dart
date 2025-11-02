import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'crop_model.dart' as app_crop;
import 'safra_model.dart';
import 'poligono_model.dart';

/// Modelo de Talhão unificado com suporte a múltiplas safras
class TalhaoModel {
  /// Getter para cor principal do talhão (prioriza safra atual, depois crop, depois cor padrão)
  Color get cor {
    // Se houver safra atual com cor definida, use-a
    if (safraAtual?.cor != null) {
      return safraAtual!.cor;
    }
    // Se houver crop com cor definida, use-a
    if (crop != null && crop!.color != null) {
      return crop!.color;
    }
    // Cor padrão
    return Colors.grey;
  }

  // Campos principais
  final String id;
  late final String name;
  final List<PoligonoModel> poligonos;
  final double area;
  final String? fazendaId;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  bool sincronizado; // Removido final para permitir alteração via setter
  final String? observacoes;
  Map<String, dynamic>? metadados; // Removido final para permitir modificação no construtor
  
  // Lista de safras associadas a este talhão
  final List<SafraModel> safras;
  
  // Campos para compatibilidade com código existente
  final int? cropId;
  final String? culturaId; // ID da cultura como string (usado no módulo de Alertas)
  
  /// Getter de compatibilidade para código legado quando culturaId não está definido
  int? get culturaIdInt => culturaId != null ? int.tryParse(culturaId!) : cropId;
  final int? safraId;
  late final app_crop.Crop? crop;

  // Compatibilidade para código legado que usa 'points'
  factory TalhaoModel.points({
    String? id,
    String? name,
    required List<LatLng> points,
    double? area,
    String? fazendaId,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    bool sincronizado = false,
    String? observacoes,
    Map<String, dynamic>? metadados,
    List<SafraModel>? safras,
    int? cropId,
    int? safraId,
    app_crop.Crop? crop,
    String? criadoPor,
    // Parâmetro adicional para compatibilidade com código legado
    String? nome,
  }) {
    final now = DateTime.now();
    final uuid = id ?? const Uuid().v4();
    final actualName = name ?? nome ?? '';
    
    // Criar polígono a partir dos pontos
    final poligono = PoligonoModel.criar(
      pontos: points,
      talhaoId: uuid,
    );
    
    // Calcular área se não fornecida
    final areaCalculada = area ?? poligono.area;
    
    return TalhaoModel(
      id: uuid,
      name: actualName,
      poligonos: [poligono],
      area: areaCalculada,
      fazendaId: fazendaId,
      dataCriacao: dataCriacao ?? now,
      dataAtualizacao: dataAtualizacao ?? now,
      sincronizado: sincronizado,
      observacoes: observacoes,
      metadados: metadados,
      safras: safras ?? [],
      cropId: cropId,
      culturaId: cropId?.toString(), // Adicionando compatibilidade com módulo de Alertas
      safraId: safraId,
      crop: crop,
      criadoPor: criadoPor,
    );
  }

  TalhaoModel({
    required this.id,
    required this.name,
    required this.poligonos,
    required this.area,
    this.fazendaId,
    required this.dataCriacao,
    required this.dataAtualizacao,
    this.sincronizado = false,
    this.observacoes,
    Map<String, dynamic>? metadados,
    required this.safras,
    this.cropId,
    this.culturaId,
    this.safraId,
    this.crop,
    String? criadoPor,
  }) {
    // Inicializar metadados
    this.metadados = metadados ?? {};
    
    // Se criadoPor for fornecido, adicionar aos metadados
    if (criadoPor != null) {
      this.metadados!['criadoPor'] = criadoPor;
    }
  }
    
  // Campos adicionais para compatibilidade com código existente
  String get nome => name;
  String get nomeTalhao => name; // Getter usado em várias partes do código
  List<LatLng> get points => poligonos.isNotEmpty ? poligonos.first.pontos : [];
  // Getter de compatibilidade para 'pontos' (alias para points)
  List<LatLng> get pontos => points;
  DateTime get createdAt => dataCriacao;
  DateTime get updatedAt => dataAtualizacao;
  String? get criadoPor => metadados != null ? metadados!['criadoPor'] : null;
  bool get synced => sincronizado;
  int get syncStatus => sincronizado ? 1 : 0;
  set syncStatus(int value) => sincronizado = value > 0;
  SafraModel? get safra => safras.isNotEmpty ? safras.first : null;
  
  // Getter para colorValue (para compatibilidade com talhao_model_new)
  Object get colorValue {
    // Se tiver safra com cultura, usar a cor da cultura
    if (safras.isNotEmpty) {
      return safras.first.culturaCor;
    }
    // Se tiver crop definido, usar a cor do crop
    else if (crop != null) {
      return crop!.color.value;
    }
    // Cor padrão
    return Colors.green.value;
  }
  

  /// Converte o modelo para um mapa para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'poligonos': poligonos.map((p) => p.toMap()).toList(),
      'area': area,
      'fazendaId': fazendaId,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
      'sincronizado': sincronizado,
      'observacoes': observacoes,
      'metadados': metadados,
      'safras': safras.map((s) => s.toMap()).toList(),
      'crop_id': cropId,
      'safra_id': safraId,
    };
  }

  /// Cria um modelo a partir de um mapa
  factory TalhaoModel.fromMap(Map<String, dynamic> map) {
    // Processar polígonos
    List<PoligonoModel> poligonos = [];
    if (map['poligonos'] != null && map['poligonos'] is List) {
      poligonos = (map['poligonos'] as List)
          .map((poligonoMap) => PoligonoModel.fromMap(poligonoMap))
          .toList();
    } else if (map['points'] != null) {
      // Compatibilidade com formato antigo
      final pontos = _stringToPoints(map['points']);
      if (pontos.isNotEmpty) {
        poligonos = [
          PoligonoModel.criar(
            pontos: pontos,
            talhaoId: map['id'] ?? const Uuid().v4(),
          )
        ];
      }
    }
    
    // Processar safras
    List<SafraModel> safras = [];
    if (map['safras'] != null && map['safras'] is List) {
      safras = (map['safras'] as List)
          .map((safraMap) => SafraModel.fromMap(safraMap))
          .toList();
    }
    
    return TalhaoModel(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? '',
      poligonos: poligonos,
      area: map['area']?.toDouble() ?? 0.0,
      fazendaId: map['fazendaId'],
      dataCriacao: map['dataCriacao'] != null 
          ? DateTime.parse(map['dataCriacao']) 
          : (map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now()),
      dataAtualizacao: map['dataAtualizacao'] != null 
          ? DateTime.parse(map['dataAtualizacao']) 
          : (map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now()),
      sincronizado: map['sincronizado'] ?? map['synced'] == 1,
      observacoes: map['observacoes'],
      metadados: map['metadados'],
      safras: safras,
      cropId: map['crop_id'],
      safraId: map['safra_id'],
    );
  }

  /// Serializa para JSON
  String toJson() => json.encode(toMap());
  
  /// Cria uma instância a partir de JSON
  factory TalhaoModel.fromJson(String source) =>
      TalhaoModel.fromMap(json.decode(source));

  /// Converte uma string para lista de pontos
  static List<LatLng> _stringToPoints(String? pointsStr) {
    if (pointsStr == null || pointsStr.isEmpty) {
      return [];
    }
    
    List<LatLng> result = [];
    List<String> pointPairs = pointsStr.split(';');
    
    for (String pair in pointPairs) {
      List<String> coords = pair.split(',');
      if (coords.length >= 2) {
        double lat = double.tryParse(coords[0]) ?? 0;
        double lng = double.tryParse(coords[1]) ?? 0;
        result.add(LatLng(lat, lng));
      }
    }
    
    return result;
  }

  /// Calcula a área do talhão em hectares
  double calculateAreaInHectares() {
    if (points.length < 3) {
      return 0.0;
    }
    
    // Implementação do algoritmo de cálculo de área (Fórmula de Gauss)
    double calculatedArea = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      calculatedArea += points[i].longitude * points[j].latitude;
      calculatedArea -= points[j].longitude * points[i].latitude;
    }
    
    calculatedArea = (calculatedArea.abs() / 2.0) * 11100000; // Converter para hectares usando fator de conversão correto
    return calculatedArea;
  }

  /// Retorna a cor do talhão baseada na cultura
  Object getColor() {
    // Verificar se tem safra atual com cultura
    final currentSafra = safraAtual;
    if (currentSafra != null) {
      return currentSafra.culturaCor;
    }
    
    // Verificar se tem cultura definida diretamente
    if (crop != null) {
      return crop!.color;
    }
    
    // Cor padrão se não tiver cultura ou cor definida
    return Colors.blue;
  }
  
  /// Retorna a safra atual (a mais recente)
  SafraModel? get safraAtual {
    if (safras.isEmpty) return null;
    
    // Ordenar por data de criação (mais recente primeiro)
    final safrasOrdenadas = List<SafraModel>.from(safras);
    safrasOrdenadas.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
    
    return safrasOrdenadas.first;
  }
  
  /// Verifica se o talhão possui polígonos válidos
  bool get possuiPoligonosValidos {
    return poligonos.isNotEmpty && poligonos.any((p) => p.isValid);
  }
  
  /// Retorna o centroide do primeiro polígono válido
  LatLng get centroide {
    if (poligonos.isEmpty) return LatLng(0, 0);
    return poligonos.first.centroide;
  }
  
  /// Retorna o período da safra atual
  String? get safraAtualPeriodo => safraAtual?.periodo;
  
  /// Cria uma cópia do modelo com os campos atualizados
  TalhaoModel copyWith({
    String? id,
    String? name,
    List<PoligonoModel>? poligonos,
    double? area,
    String? fazendaId,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    bool? sincronizado,
    String? observacoes,
    Map<String, dynamic>? metadados,
    List<SafraModel>? safras,
    int? cropId,
    int? safraId,
    app_crop.Crop? crop,
  }) {
    return TalhaoModel(
      id: id ?? this.id,
      name: name ?? this.name,
      poligonos: poligonos ?? this.poligonos,
      area: area ?? this.area,
      fazendaId: fazendaId ?? this.fazendaId,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      sincronizado: sincronizado ?? this.sincronizado,
      observacoes: observacoes ?? this.observacoes,
      metadados: metadados ?? this.metadados,
      safras: safras ?? this.safras,
      cropId: cropId ?? this.cropId,
      safraId: safraId ?? this.safraId,
      crop: crop ?? this.crop,
    );
  }
  
  /// Cria um novo talhão
  static TalhaoModel criar({
    required String nome,
    required List<LatLng> pontos,
    double? area,
    String? fazendaId,
    String? observacoes,
    Map<String, dynamic>? metadados,
    List<SafraModel>? safras,
    int? culturaId,
    int? safraId,
    app_crop.Crop? cultura,
    String? criadoPor,
    List<PoligonoModel>? poligonos,
    List<List<LatLng>>? poligonosLegacy,
  }) {
    final now = DateTime.now();
    final id = const Uuid().v4();
    
    // Preparar metadados com criadoPor se fornecido
    final metadadosAtualizados = {...(metadados ?? {})};
    if (criadoPor != null) {
      metadadosAtualizados['criadoPor'] = criadoPor;
    }
    
    // Determinar os polígonos a usar
    List<PoligonoModel> poligonosFinais = [];
    
    // Usar polígonos fornecidos diretamente
    if (poligonos != null && poligonos.isNotEmpty) {
      poligonosFinais = poligonos;
    }
    // Ou criar a partir de listas de pontos (formato legado)
    else if (poligonosLegacy != null && poligonosLegacy.isNotEmpty) {
      poligonosFinais = poligonosLegacy.map((listaPontos) => 
        PoligonoModel.criar(
          pontos: listaPontos,
          talhaoId: id,
        )
      ).toList();
    }
    // Ou criar a partir da lista de pontos principal
    else if (pontos.isNotEmpty) {
      poligonosFinais = [
        PoligonoModel.criar(
          pontos: pontos,
          talhaoId: id,
          area: area,
        )
      ];
    }
    
    // Calcular área total se não fornecida
    final areaTotal = area ?? poligonosFinais.fold<double>(
      0.0, 
      (total, poligono) => total + poligono.area
    );
    
    return TalhaoModel(
      id: id,
      name: nome,
      poligonos: poligonosFinais,
      area: areaTotal,
      fazendaId: fazendaId,
      dataCriacao: now,
      dataAtualizacao: now,
      sincronizado: false,
      observacoes: observacoes,
      metadados: metadadosAtualizados,
      safras: safras ?? [],
      cropId: culturaId,
      safraId: safraId,
      crop: cultura,
      criadoPor: criadoPor,
    );
  }
  
  /// Adiciona uma safra ao talhão
  TalhaoModel adicionarSafra(SafraModel safra) {
    final novasSafras = List<SafraModel>.from(safras);
    novasSafras.add(safra);
    
    return copyWith(
      safras: novasSafras,
      dataAtualizacao: DateTime.now(),
    );
  }
  
  /// Sobrecarga do método adicionarSafra para compatibilidade com código existente
  TalhaoModel adicionarSafraNomeada({
    required String safra,
    required String culturaId,
    required String culturaNome,
    required Color culturaCor,
  }) {
    final novaSafra = SafraModel.criar(
      talhaoId: id,
      safra: safra,
      culturaId: culturaId,
      culturaNome: culturaNome,
      culturaCor: culturaCor.value.toString(),
    );
    
    return adicionarSafra(novaSafra);
  }
  
  /// Método para compatibilidade com código existente que usa parâmetros nomeados
  TalhaoModel adicionarSafraPorNome({
    String? safra,
    String? culturaId,
    String? culturaNome,
    Color? culturaCor,
  }) {
    if (safra == null || culturaId == null || culturaNome == null || culturaCor == null) {
      // Se algum parâmetro for nulo, retornar o talhao sem alterações
      return this;
    }
    
    return adicionarSafraNomeada(
      safra: safra,
      culturaId: culturaId,
      culturaNome: culturaNome,
      culturaCor: culturaCor,
    );
  }
  
  /// Método de fábrica para criar um talhão a partir de parâmetros legados
  factory TalhaoModel.fromLegacy({
    int? id,
    String? name,
    List<LatLng>? points,
    double? area,
    int? syncStatus,
    int? cropId,
    int? safraId,
    app_crop.Crop? crop,
    SafraModel? safra,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? criadoPor,
    List<SafraModel>? safras,
    List<List<LatLng>>? poligonos,
  }) {
    final now = DateTime.now();
    final uuid = id != null ? id.toString() : const Uuid().v4();
    
    // Criar polígonos a partir dos pontos
    List<PoligonoModel> poligonosModels = [];
    
    // Se tiver lista de polígonos, usar
    if (poligonos != null && poligonos.isNotEmpty) {
      poligonosModels = poligonos.map((pontos) => 
        PoligonoModel.criar(
          pontos: pontos,
          talhaoId: uuid,
        )
      ).toList();
    } 
    // Senão, usar a lista de pontos principal
    else if (points != null && points.isNotEmpty) {
      poligonosModels = [
        PoligonoModel.criar(
          pontos: points,
          talhaoId: uuid,
        )
      ];
    }
    
    // Calcular área se não fornecida
    final areaCalculada = area ?? poligonosModels.fold<double>(
      0.0, 
      (total, poligono) => total + poligono.area
    );
    
    // Preparar metadados
    final metadadosMap = <String, dynamic>{};
    if (criadoPor != null) {
      metadadosMap['criadoPor'] = criadoPor;
    }
    
    // Preparar lista de safras
    List<SafraModel> safrasList = safras ?? [];
    if (safra != null && !safrasList.contains(safra)) {
      safrasList.add(safra);
    }
    
    return TalhaoModel(
      id: uuid,
      name: name ?? '',
      poligonos: poligonosModels,
      area: areaCalculada,
      fazendaId: null,
      dataCriacao: createdAt ?? now,
      dataAtualizacao: updatedAt ?? now,
      sincronizado: syncStatus == 1,
      observacoes: null,
      metadados: metadadosMap,
      safras: safrasList,
      cropId: cropId,
      safraId: safraId,
      crop: crop,
    );
  }
  
  /// Método de fábrica para criar um talhão a partir de parâmetros legados com nomes antigos
  factory TalhaoModel.fromLegacyNames({
    int? id,
    String? name,
    List<LatLng>? points,
    double? area,
    int? syncStatus,
    int? crop_id,
    int? safra_id,
    app_crop.Crop? crop,
    SafraModel? safra,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? criadoPor,
    List<SafraModel>? safras,
    List<List<LatLng>>? poligonos,
  }) {
    return TalhaoModel.fromLegacy(
      id: id,
      name: name,
      points: points,
      area: area,
      syncStatus: syncStatus,
      cropId: crop_id,
      safraId: safra_id,
      crop: crop,
      safra: safra,
      createdAt: createdAt,
      updatedAt: updatedAt,
      criadoPor: criadoPor,
      safras: safras,
      poligonos: poligonos,
    );
  }

  get polygon => null;

  get fazendaNome => null;

  get culturaNome => null;
  
  /// Método estático para criar um talhão a partir de parâmetros legados
  static TalhaoModel criarLegado({
    int? id,
    String? name,
    List<LatLng>? points,
    double? area,
    int? syncStatus,
    int? cropId,
    int? safraId,
    app_crop.Crop? crop,
    SafraModel? safra,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? criadoPor,
    List<SafraModel>? safras,
    List<List<LatLng>>? poligonos,
  }) {
    return TalhaoModel.fromLegacy(
      id: id,
      name: name,
      points: points,
      area: area,
      syncStatus: syncStatus,
      cropId: cropId,
      safraId: safraId,
      crop: crop,
      safra: safra,
      createdAt: createdAt,
      updatedAt: updatedAt,
      criadoPor: criadoPor,
      safras: safras,
      poligonos: poligonos,
    );
  }
  
  /// Adiciona um polígono ao talhão
  TalhaoModel adicionarPoligono(PoligonoModel poligono) {
    final novosPoligonos = List<PoligonoModel>.from(poligonos);
    novosPoligonos.add(poligono);
    
    // Recalcular a área total
    final novaArea = novosPoligonos.fold<double>(
      0.0, 
      (total, poligono) => total + poligono.area
    );
    
    return copyWith(
      poligonos: novosPoligonos,
      area: novaArea,
      dataAtualizacao: DateTime.now(),
    );
  }
}
