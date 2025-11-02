import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../utils/precise_geo_calculator.dart';

/// Modelo que representa um polígono de um talhão

class PoligonoModel implements Iterable<LatLng> {
  @override
  Iterator<LatLng> get iterator => pontos.iterator;
  
  @override
  bool any(bool Function(LatLng element) test) => pontos.any(test);
  
  @override
  Iterable<R> cast<R>() => pontos.cast<R>();
  
  @override
  bool contains(Object? element) => pontos.contains(element);
  
  @override
  LatLng elementAt(int index) => pontos.elementAt(index);
  
  @override
  bool every(bool Function(LatLng element) test) => pontos.every(test);
  
  @override
  Iterable<T> expand<T>(Iterable<T> Function(LatLng element) toElements) => pontos.expand(toElements);
  
  @override
  LatLng get first => pontos.first;
  
  @override
  LatLng firstWhere(bool Function(LatLng element) test, {LatLng Function()? orElse}) => 
      pontos.firstWhere(test, orElse: orElse);
  
  @override
  T fold<T>(T initialValue, T Function(T previousValue, LatLng element) combine) => 
      pontos.fold(initialValue, combine);
  
  @override
  Iterable<LatLng> followedBy(Iterable<LatLng> other) => pontos.followedBy(other);
  
  @override
  void forEach(void Function(LatLng element) action) => pontos.forEach(action);
  
  @override
  bool get isEmpty => pontos.isEmpty;
  
  @override
  bool get isNotEmpty => pontos.isNotEmpty;
  
  @override
  String join([String separator = ""]) => pontos.join(separator);
  
  @override
  LatLng get last => pontos.last;
  
  @override
  LatLng lastWhere(bool Function(LatLng element) test, {LatLng Function()? orElse}) => 
      pontos.lastWhere(test, orElse: orElse);
  
  @override
  int get length => pontos.length;
  
  @override
  Iterable<T> map<T>(T Function(LatLng e) toElement) => pontos.map(toElement);
  
  @override
  LatLng reduce(LatLng Function(LatLng value, LatLng element) combine) => pontos.reduce(combine);
  
  @override
  LatLng get single => pontos.single;
  
  @override
  LatLng singleWhere(bool Function(LatLng element) test, {LatLng Function()? orElse}) => 
      pontos.singleWhere(test, orElse: orElse);
  
  @override
  Iterable<LatLng> skip(int count) => pontos.skip(count);
  
  @override
  Iterable<LatLng> skipWhile(bool Function(LatLng value) test) => pontos.skipWhile(test);
  
  @override
  Iterable<LatLng> take(int count) => pontos.take(count);
  
  @override
  Iterable<LatLng> takeWhile(bool Function(LatLng value) test) => pontos.takeWhile(test);
  
  @override
  List<LatLng> toList({bool growable = true}) => pontos.toList(growable: growable);
  
  @override
  Set<LatLng> toSet() => pontos.toSet();
  
  @override
  Iterable<LatLng> where(bool Function(LatLng element) test) => pontos.where(test);
  
  @override
  Iterable<T> whereType<T>() => pontos.whereType<T>();
  final String id;
  final List<LatLng> pontos;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final bool ativo;
  final double area; // Área em hectares
  final double perimetro; // Perímetro em metros
  final String talhaoId;

  /// Getter para o centro do polígono
  LatLng get center {
    if (pontos.isEmpty) {
      throw StateError('Polígono não possui pontos');
    }
    
    double latSum = 0;
    double lngSum = 0;
    
    for (final ponto in pontos) {
      latSum += ponto.latitude;
      lngSum += ponto.longitude;
    }
    
    return LatLng(
      latSum / pontos.length,
      lngSum / pontos.length,
    );
  }

  /// Construtor principal
  PoligonoModel({
    required this.id,
    required this.pontos,
    required this.dataCriacao,
    required this.dataAtualizacao,
    required this.ativo,
    required this.area,
    required this.perimetro,
    required this.talhaoId,
  });

  /// Factory constructor para criar um novo polígono
  factory PoligonoModel.criar({
    required List<LatLng> pontos,
    required String talhaoId,
    double? area,
    double? perimetro,
  }) {
    final now = DateTime.now();
    final id = const Uuid().v4();
    
    // Calcular área e perímetro se não fornecidos
    final calculatedArea = area ?? _calcularArea(pontos);
    final calculatedPerimetro = perimetro ?? _calcularPerimetro(pontos);
    
    return PoligonoModel(
      id: id,
      pontos: pontos,
      dataCriacao: now,
      dataAtualizacao: now,
      ativo: true,
      area: calculatedArea,
      perimetro: calculatedPerimetro,
      talhaoId: talhaoId,
    );
  }

  /// Converte o modelo para um mapa para persistência
  Map<String, dynamic> toMap() {
    // Converter pontos para string JSON para evitar problemas no SQLite
    final pontosJson = pontos.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
    final pontosString = jsonEncode(pontosJson);
    
    return {
      'id': id,
      'pontos': pontosString,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
      'ativo': ativo,
      'area': area,
      'perimetro': perimetro,
      'talhaoId': talhaoId,
    };
  }

  /// Cria uma instância a partir de um mapa
  factory PoligonoModel.fromMap(Map<String, dynamic> map) {
    try {
      List<LatLng> pontos = [];
      
      // Tentar diferentes formatos de pontos
      if (map['pontos'] != null) {
        if (map['pontos'] is String) {
          // Se for string JSON, tentar fazer parse
          try {
            final pontosJson = jsonDecode(map['pontos'] as String);
            if (pontosJson is List) {
              for (final ponto in pontosJson) {
                if (ponto is Map<String, dynamic>) {
                  final lat = (ponto['lat'] as num?)?.toDouble();
                  final lng = (ponto['lng'] as num?)?.toDouble();
                  
                  if (lat != null && lng != null) {
                    pontos.add(LatLng(lat, lng));
                  }
                }
              }
            }
          } catch (e) {
            // Se não for JSON, tentar formato "lat,lng;lat,lng;..."
            final pontosStr = map['pontos'] as String;
            if (pontosStr.isNotEmpty) {
              final pointPairs = pontosStr.split(';');
              for (int i = 0; i < pointPairs.length; i++) {
                final pair = pointPairs[i];
                final coords = pair.split(',');
                if (coords.length >= 2) {
                  final lat = double.tryParse(coords[0]);
                  final lng = double.tryParse(coords[1]);
                  if (lat != null && lng != null) {
                    pontos.add(LatLng(lat, lng));
                  }
                }
              }
            }
          }
        } else if (map['pontos'] is List) {
          final pontosList = map['pontos'] as List;
          
          for (int i = 0; i < pontosList.length; i++) {
            final ponto = pontosList[i];
            
            if (ponto is Map<String, dynamic>) {
              // Tentar diferentes formatos de coordenadas
              double? lat, lng;
              
              // Formato 1: lat/lng
              lat = (ponto['lat'] as num?)?.toDouble();
              lng = (ponto['lng'] as num?)?.toDouble();
              
              // Formato 2: latitude/longitude
              if (lat == null || lng == null) {
                lat = (ponto['latitude'] as num?)?.toDouble();
                lng = (ponto['longitude'] as num?)?.toDouble();
              }
              
              if (lat != null && lng != null) {
                pontos.add(LatLng(lat, lng));
              }
            } else if (ponto is List && ponto.length >= 2) {
              // Formato alternativo: lista [lat, lng]
              final lat = (ponto[0] as num?)?.toDouble();
              final lng = (ponto[1] as num?)?.toDouble();
              
              if (lat != null && lng != null) {
                pontos.add(LatLng(lat, lng));
              }
            }
          }
        }
      }
      
      return PoligonoModel(
        id: map['id'] ?? const Uuid().v4(),
        pontos: pontos,
        dataCriacao: map['dataCriacao'] != null ? DateTime.parse(map['dataCriacao']) : DateTime.now(),
        dataAtualizacao: map['dataAtualizacao'] != null ? DateTime.parse(map['dataAtualizacao']) : DateTime.now(),
        ativo: map['ativo'] ?? true,
        area: (map['area'] as num?)?.toDouble() ?? 0.0,
        perimetro: (map['perimetro'] as num?)?.toDouble() ?? 0.0,
        talhaoId: map['talhaoId'],
      );
    } catch (e) {
      print('Erro ao converter PoligonoModel: $e');
      rethrow;
    }
  }

  /// Serializa para JSON
  String toJson() => json.encode(toMap());

  /// Cria uma instância a partir de JSON
  factory PoligonoModel.fromJson(String source) =>
      PoligonoModel.fromMap(json.decode(source));

  /// Cria uma cópia com alterações específicas
  PoligonoModel copyWith({
    String? id,
    List<LatLng>? pontos,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    bool? ativo,
    double? area,
    double? perimetro,
    String? talhaoId,
  }) {
    return PoligonoModel(
      id: id ?? this.id,
      pontos: pontos ?? this.pontos,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      ativo: ativo ?? this.ativo,
      area: area ?? this.area,
      perimetro: perimetro ?? this.perimetro,
      talhaoId: talhaoId ?? this.talhaoId,
    );
  }

  /// Calcula a área do polígono em hectares usando o algoritmo preciso unificado
  static double _calcularArea(List<LatLng> pontos) {
    // Usa a mesma implementação de alta precisão empregada em todo o app
    return PreciseGeoCalculator.calculatePolygonArea(pontos);
  }

  /// Calcula o perímetro do polígono
  static double _calcularPerimetro(List<LatLng> pontos) {
    if (pontos.length < 2) return 0.0;
    
    double perimetro = 0.0;
    final Distance distance = const Distance();
    
    for (int i = 0; i < pontos.length; i++) {
      final LatLng p1 = pontos[i];
      final LatLng p2 = pontos[(i + 1) % pontos.length];
      perimetro += distance.as(LengthUnit.Meter, p1, p2);
    }
    
    return perimetro;
  }

  /// Verifica se o polígono é válido (pelo menos 3 pontos)
  bool get isValid => pontos.length >= 3;

  /// Calcula o centroide do polígono
  LatLng get centroide {
    if (pontos.isEmpty) return LatLng(0, 0);
    
    double lat = 0.0;
    double lng = 0.0;
    
    for (final ponto in pontos) {
      lat += ponto.latitude;
      lng += ponto.longitude;
    }
    
    return LatLng(lat / pontos.length, lng / pontos.length);
  }
  
  /// Converte o polígono para uma lista de LatLng (para compatibilidade com código existente)
  List<LatLng> get asLatLngList => pontos;

  num get latitude => pontos.first.latitude;

  num get longitude => pontos.first.longitude;
  
  /// Acessa um ponto específico do polígono pelo índice
  LatLng operator [](int index) => pontos[index];
  
  /// Converte para uma lista de pontos no formato esperado por outros componentes
  List<Map<String, double>> toPointsList() {
    return pontos.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
  }
  
  /// Converte para uma lista de LatLng no formato esperado por flutter_map
  List<LatLng> toLatLngList() {
    return pontos;
  }
  
  /// Método para converter pontos usando uma função personalizada
  List<T> mapPoints<T>(T Function(LatLng) converter) {
    return pontos.map(converter).toList();
  }
  
  /// Converte os pontos para uma lista de Offset para desenho
  List<Offset> toOffsets(Offset Function(LatLng) latLngToOffset) {
    return pontos.map((point) => latLngToOffset(point)).toList();
  }
  
  /// Converte os pontos para uma string no formato 'lat,lng;lat,lng;...'
  String toPointsString() {
    return pontos.map((p) => '${p.latitude},${p.longitude}').join(';');
  }
  
  /// Cria um polígono a partir de uma string de pontos
  static PoligonoModel fromPointsString(String pointsStr, String talhaoId) {
    final pontos = _stringToLatLngList(pointsStr);
    return PoligonoModel.criar(pontos: pontos, talhaoId: talhaoId);
  }
  
  /// Converte uma string de pontos para lista de LatLng
  static List<LatLng> _stringToLatLngList(String pointsStr) {
    if (pointsStr.isEmpty) return [];
    
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
}
