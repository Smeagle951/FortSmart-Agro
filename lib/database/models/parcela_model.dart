import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';

/// Modelo para parcelas experimentais
class ParcelaModel {
  final String id;
  final String experimentoId;
  final String tratamentoId;
  final String subareaId; // Referência à subárea no mapa
  final String codigo; // P1, P2, P3, etc.
  final int numeroRepeticao; // 1, 2, 3, etc.
  final int numeroTratamento; // 1, 2, 3, etc.
  final double area; // hectares
  final List<LatLng> pontos; // Coordenadas da parcela
  final String status; // 'planejada', 'plantada', 'em_avaliacao', 'colhida'
  final DateTime? dataPlantio;
  final DateTime? dataColheita;
  final String observacoes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParcelaModel({
    required this.id,
    required this.experimentoId,
    required this.tratamentoId,
    required this.subareaId,
    required this.codigo,
    required this.numeroRepeticao,
    required this.numeroTratamento,
    required this.area,
    required this.pontos,
    required this.status,
    this.dataPlantio,
    this.dataColheita,
    required this.observacoes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma nova parcela
  factory ParcelaModel.create({
    required String experimentoId,
    required String tratamentoId,
    required String subareaId,
    required String codigo,
    required int numeroRepeticao,
    required int numeroTratamento,
    required double area,
    required List<LatLng> pontos,
    String? status,
    String? observacoes,
  }) {
    final uuid = Uuid();
    final now = DateTime.now();
    
    return ParcelaModel(
      id: uuid.v4(),
      experimentoId: experimentoId,
      tratamentoId: tratamentoId,
      subareaId: subareaId,
      codigo: codigo,
      numeroRepeticao: numeroRepeticao,
      numeroTratamento: numeroTratamento,
      area: area,
      pontos: pontos,
      status: status ?? 'planejada',
      observacoes: observacoes ?? '',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Cria uma cópia da parcela com campos alterados
  ParcelaModel copyWith({
    String? id,
    String? experimentoId,
    String? tratamentoId,
    String? subareaId,
    String? codigo,
    int? numeroRepeticao,
    int? numeroTratamento,
    double? area,
    List<LatLng>? pontos,
    String? status,
    DateTime? dataPlantio,
    DateTime? dataColheita,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParcelaModel(
      id: id ?? this.id,
      experimentoId: experimentoId ?? this.experimentoId,
      tratamentoId: tratamentoId ?? this.tratamentoId,
      subareaId: subareaId ?? this.subareaId,
      codigo: codigo ?? this.codigo,
      numeroRepeticao: numeroRepeticao ?? this.numeroRepeticao,
      numeroTratamento: numeroTratamento ?? this.numeroTratamento,
      area: area ?? this.area,
      pontos: pontos ?? this.pontos,
      status: status ?? this.status,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      dataColheita: dataColheita ?? this.dataColheita,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte para Map para salvar no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'experimento_id': experimentoId,
      'tratamento_id': tratamentoId,
      'subarea_id': subareaId,
      'codigo': codigo,
      'numero_repeticao': numeroRepeticao,
      'numero_tratamento': numeroTratamento,
      'area': area,
      'pontos': _pontosToString(pontos),
      'status': status,
      'data_plantio': dataPlantio?.millisecondsSinceEpoch,
      'data_colheita': dataColheita?.millisecondsSinceEpoch,
      'observacoes': observacoes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Cria a partir de Map do banco
  factory ParcelaModel.fromMap(Map<String, dynamic> map) {
    return ParcelaModel(
      id: map['id'],
      experimentoId: map['experimento_id'],
      tratamentoId: map['tratamento_id'],
      subareaId: map['subarea_id'],
      codigo: map['codigo'],
      numeroRepeticao: map['numero_repeticao'],
      numeroTratamento: map['numero_tratamento'],
      area: map['area'],
      pontos: _stringToPontos(map['pontos']),
      status: map['status'],
      dataPlantio: map['data_plantio'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['data_plantio'])
          : null,
      dataColheita: map['data_colheita'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['data_colheita'])
          : null,
      observacoes: map['observacoes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  /// Converte pontos para string
  static String _pontosToString(List<LatLng> pontos) {
    return pontos.map((p) => '${p.latitude},${p.longitude}').join('|');
  }

  /// Converte string para pontos
  static List<LatLng> _stringToPontos(String? str) {
    if (str == null || str.isEmpty) return [];
    return str.split('|').map((p) {
      final coords = p.split(',');
      if (coords.length == 2) {
        return LatLng(double.parse(coords[0]), double.parse(coords[1]));
      }
      return LatLng(0, 0);
    }).toList();
  }

  /// Calcula o centro da parcela
  LatLng get centro {
    if (pontos.isEmpty) return LatLng(0, 0);
    
    double lat = 0, lng = 0;
    for (final ponto in pontos) {
      lat += ponto.latitude;
      lng += ponto.longitude;
    }
    return LatLng(lat / pontos.length, lng / pontos.length);
  }

  /// Verifica se está plantada
  bool get isPlantada => status == 'plantada' && dataPlantio != null;

  /// Verifica se está colhida
  bool get isColhida => status == 'colhida' && dataColheita != null;

  /// Calcula dias desde plantio
  int get diasDesdePlantio {
    if (dataPlantio == null) return 0;
    return DateTime.now().difference(dataPlantio!).inDays;
  }

  @override
  String toString() {
    return 'ParcelaModel(id: $id, codigo: $codigo, area: $area, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParcelaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
