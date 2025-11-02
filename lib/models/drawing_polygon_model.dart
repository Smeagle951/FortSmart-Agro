import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'drawing_vertex_model.dart';
import '../utils/geodetic_utils.dart';
import '../utils/type_utils.dart';

class DrawingPolygon {
  final String id;
  final String name;
  final List<DrawingVertex> vertices;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isClosed;
  final double? area; // em m²
  final double? perimeter; // em metros

  DrawingPolygon({
    required this.id,
    required this.name,
    required this.vertices,
    required this.createdAt,
    this.updatedAt,
    this.isClosed = false,
    this.area,
    this.perimeter,
  });

  List<LatLng> get latLngVertices {
    return vertices.map((vertex) => vertex.toLatLng()).toList();
  }

  bool get canClose {
    return vertices.length >= 3;
  }

  DrawingPolygon copyWith({
    String? id,
    String? name,
    List<DrawingVertex>? vertices,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isClosed,
    double? area,
    double? perimeter,
  }) {
    return DrawingPolygon(
      id: id ?? this.id,
      name: name ?? this.name,
      vertices: vertices ?? this.vertices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isClosed: isClosed ?? this.isClosed,
      area: area ?? this.area,
      perimeter: perimeter ?? this.perimeter,
    );
  }

  // Adicionar vértice
  DrawingPolygon addVertex(DrawingVertex vertex) {
    final newVertices = List<DrawingVertex>.from(vertices)..add(vertex);
    return copyWith(
      vertices: newVertices,
      updatedAt: DateTime.now(),
    );
  }

  // Atualizar vértice
  DrawingPolygon updateVertex(String vertexId, DrawingVertex newVertex) {
    final newVertices = vertices.map((vertex) {
      return vertex.id == vertexId ? newVertex : vertex;
    }).toList();
    
    return copyWith(
      vertices: newVertices,
      updatedAt: DateTime.now(),
    );
  }

  // Remover vértice
  DrawingPolygon removeVertex(String vertexId) {
    final newVertices = vertices.where((vertex) => vertex.id != vertexId).toList();
    return copyWith(
      vertices: newVertices,
      updatedAt: DateTime.now(),
    );
  }

  // Fechar polígono
  DrawingPolygon closePolygon() {
    if (!canClose) return this;
    
    return copyWith(
      isClosed: true,
      updatedAt: DateTime.now(),
    );
  }

  // Calcular área usando novo modelo de cálculo geodésico (muito mais preciso)
  Future<double> calculateArea() async {
    if (vertices.length < 3) return 0.0;

    try {
      // Usar o novo sistema de cálculo geodésico
      return await GeodeticUtils.calculatePolygonArea(latLngVertices);
    } catch (e) {
      // Fallback para método simples se houver erro
      return _calculateAreaSimple();
    }
  }

  // Calcular perímetro usando novo modelo de cálculo geodésico
  Future<double> calculatePerimeter() async {
    if (vertices.length < 2) return 0.0;

    try {
      // Usar o novo sistema de cálculo geodésico
      return await GeodeticUtils.calculatePolygonPerimeter(latLngVertices);
    } catch (e) {
      // Fallback para método simples se houver erro
      return _calculatePerimeterSimple();
    }
  }

  // Método simples de cálculo de área (fallback)
  double _calculateAreaSimple() {
    if (vertices.length < 3) return 0.0;

    double area = 0.0;
    for (int i = 0; i < vertices.length; i++) {
      int j = (i + 1) % vertices.length;
      area += vertices[i].longitude * vertices[j].latitude;
      area -= vertices[j].longitude * vertices[i].latitude;
    }
    area = (area.abs() / 2) * 111000 * 111000; // Aproximação para metros quadrados
    return area;
  }

  // Método simples de cálculo de perímetro (fallback)
  double _calculatePerimeterSimple() {
    if (vertices.length < 2) return 0.0;

    double perimeter = 0.0;
    for (int i = 0; i < vertices.length; i++) {
      int j = (i + 1) % vertices.length;
      perimeter += _calculateDistance(vertices[i], vertices[j]);
    }
    return perimeter;
  }

  // Calcular distância entre dois pontos (método simples)
  double _calculateDistance(DrawingVertex p1, DrawingVertex p2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    final double lat1Rad = p1.latitude * (pi / 180);
    final double lat2Rad = p2.latitude * (pi / 180);
    final double deltaLatRad = (p2.latitude - p1.latitude) * (pi / 180);
    final double deltaLngRad = (p2.longitude - p1.longitude) * (pi / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Calcular centroide
  LatLng get centroid {
    if (vertices.isEmpty) return const LatLng(0, 0);
    
    double latSum = 0;
    double lngSum = 0;
    for (final vertex in vertices) {
      latSum += vertex.latitude;
      lngSum += vertex.longitude;
    }
    
    return LatLng(latSum / vertices.length, lngSum / vertices.length);
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vertices': vertices.map((v) => v.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isClosed': isClosed,
      'area': area,
      'perimeter': perimeter,
    };
  }

  // Criar a partir de JSON
  factory DrawingPolygon.fromJson(Map<String, dynamic> json) {
    return DrawingPolygon(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      vertices: (json['vertices'] as List<dynamic>?)
          ?.map((v) => DrawingVertex.fromJson(v))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isClosed: json['isClosed'] ?? false,
      area: json['area']?.toDouble(),
      perimeter: json['perimeter']?.toDouble(),
    );
  }

  // Criar a partir de Map do banco
  factory DrawingPolygon.fromMap(Map<String, dynamic> map) {
    final geometry = map['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;
    
    List<DrawingVertex> vertices = [];
    if (coordinates != null && coordinates.isNotEmpty) {
      final coords = coordinates[0] as List<dynamic>;
      vertices = coords.map((coord) {
        final lat = (coord[1] as num).toDouble();
        final lng = (coord[0] as num).toDouble();
        return DrawingVertex(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          latitude: lat,
          longitude: lng,
          accuracy: 0.0,
          timestamp: DateTime.now(),
        );
      }).toList();
    }

    return DrawingPolygon(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      vertices: vertices,
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'].toString()) : null,
      isClosed: map['is_closed'] == 1 || map['is_closed'] == true,
      area: TypeUtils.toDouble(map['area']),
      perimeter: TypeUtils.toDouble(map['perimeter']),
    );
  }

  // Converter para Map para o banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'geometry': {
        'type': 'Polygon',
        'coordinates': [vertices.map((v) => [v.longitude, v.latitude]).toList()]
      },
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_closed': isClosed ? 1 : 0,
      'area': area,
      'perimeter': perimeter,
    };
  }
}
