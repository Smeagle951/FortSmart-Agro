import 'dart:convert';

/// Modelo para leituras do penetrômetro Bluetooth
class PenetrometroReading {
  final int? id;
  final double profundidadeCm; // ex: 0..40
  final double resistenciaMpa; // ex: 2.5
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String deviceId; // MAC ou id do device
  final String? pointCode; // Código do ponto de coleta
  final int? talhaoId; // ID do talhão
  final bool synced; // Flag para sincronização
  final String? observacoes; // Observações adicionais
  final String? fotoPath; // Caminho da foto (opcional)

  PenetrometroReading({
    this.id,
    required this.profundidadeCm,
    required this.resistenciaMpa,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.deviceId,
    this.pointCode,
    this.talhaoId,
    this.synced = false,
    this.observacoes,
    this.fotoPath,
  });

  /// Cria leitura a partir de dados do Bluetooth
  factory PenetrometroReading.fromBluetooth({
    required double profundidadeCm,
    required double resistenciaMpa,
    required String deviceId,
    required double latitude,
    required double longitude,
    String? pointCode,
    int? talhaoId,
    String? observacoes,
    String? fotoPath,
  }) {
    return PenetrometroReading(
      profundidadeCm: profundidadeCm,
      resistenciaMpa: resistenciaMpa,
      timestamp: DateTime.now(),
      deviceId: deviceId,
      latitude: latitude,
      longitude: longitude,
      pointCode: pointCode,
      talhaoId: talhaoId,
      observacoes: observacoes,
      fotoPath: fotoPath,
    );
  }

  /// Converte para Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profundidade': profundidadeCm,
      'resistencia': resistenciaMpa,
      'timestamp': timestamp.toIso8601String(),
      'lat': latitude,
      'lon': longitude,
      'deviceId': deviceId,
      'point_code': pointCode,
      'talhao_id': talhaoId,
      'synced': synced ? 1 : 0,
      'observacoes': observacoes,
      'foto_path': fotoPath,
    };
  }

  /// Cria a partir de Map (SQLite)
  factory PenetrometroReading.fromMap(Map<String, dynamic> map) {
    return PenetrometroReading(
      id: map['id'],
      profundidadeCm: map['profundidade']?.toDouble() ?? 0.0,
      resistenciaMpa: map['resistencia']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      latitude: map['lat']?.toDouble() ?? 0.0,
      longitude: map['lon']?.toDouble() ?? 0.0,
      deviceId: map['deviceId'] ?? '',
      pointCode: map['point_code'],
      talhaoId: map['talhao_id'],
      synced: (map['synced'] ?? 0) == 1,
      observacoes: map['observacoes'],
      fotoPath: map['foto_path'],
    );
  }

  /// Converte para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria a partir de JSON
  factory PenetrometroReading.fromJson(String source) =>
      PenetrometroReading.fromMap(jsonDecode(source));

  /// Cria cópia com alterações
  PenetrometroReading copyWith({
    int? id,
    double? profundidadeCm,
    double? resistenciaMpa,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? deviceId,
    String? pointCode,
    int? talhaoId,
    bool? synced,
    String? observacoes,
    String? fotoPath,
  }) {
    return PenetrometroReading(
      id: id ?? this.id,
      profundidadeCm: profundidadeCm ?? this.profundidadeCm,
      resistenciaMpa: resistenciaMpa ?? this.resistenciaMpa,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deviceId: deviceId ?? this.deviceId,
      pointCode: pointCode ?? this.pointCode,
      talhaoId: talhaoId ?? this.talhaoId,
      synced: synced ?? this.synced,
      observacoes: observacoes ?? this.observacoes,
      fotoPath: fotoPath ?? this.fotoPath,
    );
  }

  /// Calcula nível de compactação baseado na resistência
  String calcularNivelCompactacao() {
    if (resistenciaMpa < 1.5) return 'Solo Solto';
    if (resistenciaMpa < 2.0) return 'Moderado';
    if (resistenciaMpa < 2.5) return 'Alto';
    return 'Crítico';
  }

  /// Retorna cor baseada no nível de compactação
  String getCorNivel() {
    switch (calcularNivelCompactacao()) {
      case 'Solo Solto':
        return '#4CAF50'; // Verde
      case 'Moderado':
        return '#FFC107'; // Amarelo
      case 'Alto':
        return '#FF9800'; // Laranja
      case 'Crítico':
        return '#F44336'; // Vermelho
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  /// Valida se a leitura é válida
  bool get isValid {
    return profundidadeCm > 0 && 
           profundidadeCm <= 50 && 
           resistenciaMpa >= 0 && 
           resistenciaMpa <= 10 &&
           deviceId.isNotEmpty;
  }

  /// Formata dados para exibição
  String get resumoFormatado {
    return 'Prof: ${profundidadeCm.toStringAsFixed(1)}cm | '
           'Resist: ${resistenciaMpa.toStringAsFixed(2)}MPa | '
           'Nível: ${calcularNivelCompactacao()}';
  }

  @override
  String toString() {
    return 'PenetrometroReading(id: $id, profundidade: ${profundidadeCm}cm, '
           'resistencia: ${resistenciaMpa}MPa, device: $deviceId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PenetrometroReading &&
        other.id == id &&
        other.profundidadeCm == profundidadeCm &&
        other.resistenciaMpa == resistenciaMpa &&
        other.timestamp == timestamp &&
        other.deviceId == deviceId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        profundidadeCm.hashCode ^
        resistenciaMpa.hashCode ^
        timestamp.hashCode ^
        deviceId.hashCode;
  }
}
