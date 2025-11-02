import 'package:intl/intl.dart';

class ProdutividadeModel {
  int? id;
  int talhaoId;
  int safraId;
  int culturaId;
  String dataColheita;
  double produtividade;
  String unidade;
  double? areaColhida;
  String? observacoes;
  String? createdAt;
  String? updatedAt;
  int syncStatus;

  ProdutividadeModel({
    this.id,
    required this.talhaoId,
    required this.safraId,
    required this.culturaId,
    required this.dataColheita,
    required this.produtividade,
    required this.unidade,
    this.areaColhida,
    this.observacoes,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 0,
  });

  // Converter de Map para objeto
  factory ProdutividadeModel.fromMap(Map<String, dynamic> map) {
    return ProdutividadeModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      safraId: map['safra_id'],
      culturaId: map['cultura_id'],
      dataColheita: map['data_colheita'],
      produtividade: map['produtividade'].toDouble(),
      unidade: map['unidade'],
      areaColhida: map['area_colhida'] != null ? map['area_colhida'].toDouble() : null,
      observacoes: map['observacoes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      syncStatus: map['sync_status'] ?? 0,
    );
  }

  // Converter de objeto para Map
  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    return {
      'id': id,
      'talhao_id': talhaoId,
      'safra_id': safraId,
      'cultura_id': culturaId,
      'data_colheita': dataColheita,
      'produtividade': produtividade,
      'unidade': unidade,
      'area_colhida': areaColhida,
      'observacoes': observacoes,
      'created_at': createdAt ?? timestamp,
      'updated_at': timestamp,
      'sync_status': syncStatus,
    };
  }

  // Copiar objeto com alterações
  ProdutividadeModel copyWith({
    int? id,
    int? talhaoId,
    int? safraId,
    int? culturaId,
    String? dataColheita,
    double? produtividade,
    String? unidade,
    double? areaColhida,
    String? observacoes,
    String? createdAt,
    String? updatedAt,
    int? syncStatus,
  }) {
    return ProdutividadeModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      safraId: safraId ?? this.safraId,
      culturaId: culturaId ?? this.culturaId,
      dataColheita: dataColheita ?? this.dataColheita,
      produtividade: produtividade ?? this.produtividade,
      unidade: unidade ?? this.unidade,
      areaColhida: areaColhida ?? this.areaColhida,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Representação em string
  @override
  String toString() {
    return 'ProdutividadeModel(id: $id, produtividade: $produtividade $unidade, dataColheita: $dataColheita)';
  }
}
