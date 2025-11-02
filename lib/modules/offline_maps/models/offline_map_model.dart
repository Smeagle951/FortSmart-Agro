import 'package:latlong2/latlong.dart';
import 'offline_map_status.dart';

/// Modelo de dados para mapas offline
class OfflineMapModel {
  final String id;
  final String talhaoId;
  final String talhaoName;
  final String? fazendaId;
  final String? fazendaName;
  final List<LatLng> polygon;
  final double area;
  final OfflineMapStatus status;
  final DateTime? lastDownload;
  final DateTime? lastUpdate;
  final int zoomMin;
  final int zoomMax;
  final String? localPath;
  final int? totalTiles;
  final int? downloadedTiles;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  OfflineMapModel({
    required this.id,
    required this.talhaoId,
    required this.talhaoName,
    this.fazendaId,
    this.fazendaName,
    required this.polygon,
    required this.area,
    required this.status,
    this.lastDownload,
    this.lastUpdate,
    this.zoomMin = 13,
    this.zoomMax = 18,
    this.localPath,
    this.totalTiles,
    this.downloadedTiles,
    this.errorMessage,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : metadata = metadata ?? const {},
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Cria um novo modelo de mapa offline
  factory OfflineMapModel.create({
    required String talhaoId,
    required String talhaoName,
    required List<LatLng> polygon,
    required double area,
    String? fazendaId,
    String? fazendaName,
    int zoomMin = 13,
    int zoomMax = 18,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return OfflineMapModel(
      id: 'offline_map_${talhaoId}_${now.millisecondsSinceEpoch}',
      talhaoId: talhaoId,
      talhaoName: talhaoName,
      fazendaId: fazendaId,
      fazendaName: fazendaName,
      polygon: polygon,
      area: area,
      status: OfflineMapStatus.notDownloaded,
      zoomMin: zoomMin,
      zoomMax: zoomMax,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Cria a partir de um mapa (deserialização)
  factory OfflineMapModel.fromMap(Map<String, dynamic> map) {
    // Converter string de polígono para lista de LatLng
    List<LatLng> polygon = [];
    if (map['polygon'] != null) {
      if (map['polygon'] is String) {
        polygon = _parsePolygonString(map['polygon']);
      } else if (map['polygon'] is List) {
        polygon = (map['polygon'] as List).map((point) {
          if (point is Map) {
            return LatLng(point['lat'] ?? 0.0, point['lng'] ?? 0.0);
          }
          return LatLng(0.0, 0.0);
        }).toList();
      }
    }

    return OfflineMapModel(
      id: map['id'] ?? '',
      talhaoId: map['talhao_id'] ?? '',
      talhaoName: map['talhao_name'] ?? '',
      fazendaId: map['fazenda_id'],
      fazendaName: map['fazenda_name'],
      polygon: polygon,
      area: (map['area'] ?? 0.0).toDouble(),
      status: OfflineMapStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => OfflineMapStatus.notDownloaded,
      ),
      lastDownload: map['last_download'] != null 
          ? DateTime.parse(map['last_download']) 
          : null,
      lastUpdate: map['last_update'] != null 
          ? DateTime.parse(map['last_update']) 
          : null,
      zoomMin: map['zoom_min'] ?? 13,
      zoomMax: map['zoom_max'] ?? 18,
      localPath: map['local_path'],
      totalTiles: map['total_tiles'],
      downloadedTiles: map['downloaded_tiles'],
      errorMessage: map['error_message'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
    );
  }

  /// Converte para mapa (serialização)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'talhao_name': talhaoName,
      'fazenda_id': fazendaId,
      'fazenda_name': fazendaName,
      'polygon': _polygonToString(polygon),
      'area': area,
      'status': status.name,
      'last_download': lastDownload?.toIso8601String(),
      'last_update': lastUpdate?.toIso8601String(),
      'zoom_min': zoomMin,
      'zoom_max': zoomMax,
      'local_path': localPath,
      'total_tiles': totalTiles,
      'downloaded_tiles': downloadedTiles,
      'error_message': errorMessage,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria uma cópia com campos atualizados
  OfflineMapModel copyWith({
    String? id,
    String? talhaoId,
    String? talhaoName,
    String? fazendaId,
    String? fazendaName,
    List<LatLng>? polygon,
    double? area,
    OfflineMapStatus? status,
    DateTime? lastDownload,
    DateTime? lastUpdate,
    int? zoomMin,
    int? zoomMax,
    String? localPath,
    int? totalTiles,
    int? downloadedTiles,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfflineMapModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoName: talhaoName ?? this.talhaoName,
      fazendaId: fazendaId ?? this.fazendaId,
      fazendaName: fazendaName ?? this.fazendaName,
      polygon: polygon ?? this.polygon,
      area: area ?? this.area,
      status: status ?? this.status,
      lastDownload: lastDownload ?? this.lastDownload,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      zoomMin: zoomMin ?? this.zoomMin,
      zoomMax: zoomMax ?? this.zoomMax,
      localPath: localPath ?? this.localPath,
      totalTiles: totalTiles ?? this.totalTiles,
      downloadedTiles: downloadedTiles ?? this.downloadedTiles,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calcula o progresso do download (0.0 a 1.0)
  double get downloadProgress {
    if (totalTiles == null || totalTiles == 0) return 0.0;
    return (downloadedTiles ?? 0) / totalTiles!;
  }

  /// Verifica se o download está completo
  bool get isDownloadComplete {
    return status == OfflineMapStatus.downloaded && 
           totalTiles != null && 
           downloadedTiles != null && 
           downloadedTiles == totalTiles;
  }

  /// Calcula o bounding box do polígono
  Map<String, double> get boundingBox {
    if (polygon.isEmpty) {
      return {
        'minLat': 0.0,
        'maxLat': 0.0,
        'minLng': 0.0,
        'maxLng': 0.0,
      };
    }

    double minLat = polygon.first.latitude;
    double maxLat = polygon.first.latitude;
    double minLng = polygon.first.longitude;
    double maxLng = polygon.first.longitude;

    for (final point in polygon) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  /// Converte polígono para string
  static String _polygonToString(List<LatLng> polygon) {
    return polygon.map((point) => '${point.latitude},${point.longitude}').join(';');
  }

  /// Converte string para polígono
  static List<LatLng> _parsePolygonString(String polygonStr) {
    if (polygonStr.isEmpty) return [];
    
    return polygonStr.split(';').map((pointStr) {
      final coords = pointStr.split(',');
      if (coords.length >= 2) {
        return LatLng(
          double.parse(coords[0]),
          double.parse(coords[1]),
        );
      }
      return LatLng(0.0, 0.0);
    }).toList();
  }

  @override
  String toString() {
    return 'OfflineMapModel(id: $id, talhaoId: $talhaoId, talhaoName: $talhaoName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineMapModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
