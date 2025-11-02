import 'package:flutter/foundation.dart';

enum MetodoCalibragrem { engrenagem, gramas }

class PlantioModel {
  final String? id;
  final String? talhaoId;
  final String? culturaId;
  final String? variedadeId;
  final String? safraId;
  final String? usuarioId;
  final String? descricao;
  final DateTime? dataPlantio;
  final double? areaPlantada;
  final double? espacamento;
  final double? densidade;
  final double? germinacao;
  final double? pesoMedioSemente;
  final double? sementesMetro;
  final double? sementesHa;
  final double? kgHa;
  final double? sacasHa;
  final MetodoCalibragrem? metodoCalibragrem;
  final String? fonteEstoqueId;
  final double? fonteEstoqueQuantidade;
  final List<String>? fotos;
  final DateTime? dataCriacao;
  final DateTime? dataAtualizacao;

  PlantioModel({
    this.id,
    this.talhaoId,
    this.culturaId,
    this.variedadeId,
    this.safraId,
    this.usuarioId,
    this.descricao,
    this.dataPlantio,
    this.areaPlantada,
    this.espacamento,
    this.densidade,
    this.germinacao,
    this.pesoMedioSemente,
    this.sementesMetro,
    this.sementesHa,
    this.kgHa,
    this.sacasHa,
    this.metodoCalibragrem,
    this.fonteEstoqueId,
    this.fonteEstoqueQuantidade,
    this.fotos,
    this.dataCriacao,
    this.dataAtualizacao,
  });

  PlantioModel copyWith({
    String? id,
    String? talhaoId,
    String? culturaId,
    String? variedadeId,
    String? safraId,
    String? usuarioId,
    String? descricao,
    DateTime? dataPlantio,
    double? areaPlantada,
    double? espacamento,
    double? densidade,
    double? germinacao,
    double? pesoMedioSemente,
    double? sementesMetro,
    double? sementesHa,
    double? kgHa,
    double? sacasHa,
    MetodoCalibragrem? metodoCalibragrem,
    String? fonteEstoqueId,
    double? fonteEstoqueQuantidade,
    List<String>? fotos,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return PlantioModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      safraId: safraId ?? this.safraId,
      usuarioId: usuarioId ?? this.usuarioId,
      descricao: descricao ?? this.descricao,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      areaPlantada: areaPlantada ?? this.areaPlantada,
      espacamento: espacamento ?? this.espacamento,
      densidade: densidade ?? this.densidade,
      germinacao: germinacao ?? this.germinacao,
      pesoMedioSemente: pesoMedioSemente ?? this.pesoMedioSemente,
      sementesMetro: sementesMetro ?? this.sementesMetro,
      sementesHa: sementesHa ?? this.sementesHa,
      kgHa: kgHa ?? this.kgHa,
      sacasHa: sacasHa ?? this.sacasHa,
      metodoCalibragrem: metodoCalibragrem ?? this.metodoCalibragrem,
      fonteEstoqueId: fonteEstoqueId ?? this.fonteEstoqueId,
      fonteEstoqueQuantidade: fonteEstoqueQuantidade ?? this.fonteEstoqueQuantidade,
      fotos: fotos ?? this.fotos,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'safra_id': safraId,
      'usuario_id': usuarioId,
      'descricao': descricao,
      'data_plantio': dataPlantio?.toIso8601String(),
      'area_plantada': areaPlantada,
      'espacamento': espacamento,
      'densidade': densidade,
      'germinacao': germinacao,
      'peso_medio_semente': pesoMedioSemente,
      'sementes_metro': sementesMetro,
      'sementes_ha': sementesHa,
      'kg_ha': kgHa,
      'sacas_ha': sacasHa,
      'metodo_calibragem': metodoCalibragrem?.toString(),
      'fonte_estoque_id': fonteEstoqueId,
      'fonte_estoque_quantidade': fonteEstoqueQuantidade,
      'fotos': fotos?.join(','), // Converter lista para string separada por vírgula
      'data_criacao': dataCriacao?.toIso8601String(),
      'data_atualizacao': dataAtualizacao?.toIso8601String(),
      // Campos adicionais para compatibilidade
      'talhaold': talhaoId,
      'culturald': culturaId,
      'variedadeld': variedadeId,
      'safrald': safraId,
      'usuariold': usuarioId,
      'dataPlantio': dataPlantio?.millisecondsSinceEpoch,
      'areaPlantada': areaPlantada,
      'pesoMedioSemente': pesoMedioSemente,
      'sementesMetro': sementesMetro,
      'sementesHa': sementesHa,
      'metodoCalibragrem': metodoCalibragrem?.toString(),
      'fonteEstoqueId': fonteEstoqueId,
      'fonteEstoqueQuantidade': fonteEstoqueQuantidade,
      'dataCriacao': dataCriacao?.millisecondsSinceEpoch,
      'dataAtualizacao': dataAtualizacao?.millisecondsSinceEpoch,
    };
  }

  factory PlantioModel.fromMap(Map<String, dynamic> map) {
    try {
      // Função auxiliar para converter data
      DateTime? parseDate(dynamic value) {
        if (value == null) return null;
        if (value is int) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        } else if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            return null;
          }
        }
        return null;
      }

      // Função auxiliar para converter lista de fotos
      List<String>? parseFotos(dynamic value) {
        if (value == null) return null;
        if (value is List) {
          return List<String>.from(value);
        } else if (value is String && value.isNotEmpty) {
          return value.split(',');
        }
        return null;
      }

      return PlantioModel(
        id: map['id']?.toString() ?? '',
        talhaoId: map['talhao_id']?.toString() ?? map['talhaoId']?.toString() ?? map['talhaold']?.toString() ?? '',
        culturaId: map['cultura_id']?.toString() ?? map['culturaId']?.toString() ?? map['culturald']?.toString() ?? '',
        variedadeId: map['variedade_id']?.toString() ?? map['variedadeId']?.toString() ?? map['variedadeld']?.toString(),
        safraId: map['safra_id']?.toString() ?? map['safraId']?.toString() ?? map['safrald']?.toString(),
        usuarioId: map['usuario_id']?.toString() ?? map['usuarioId']?.toString() ?? map['usuariold']?.toString() ?? '',
        descricao: map['descricao']?.toString() ?? '',
        dataPlantio: parseDate(map['data_plantio'] ?? map['dataPlantio']) ?? DateTime.now(),
        areaPlantada: (map['area_plantada'] ?? map['areaPlantada'] as num?)?.toDouble(),
        espacamento: (map['espacamento'] as num?)?.toDouble(),
        densidade: (map['densidade'] as num?)?.toDouble(),
        germinacao: (map['germinacao'] as num?)?.toDouble(),
        pesoMedioSemente: (map['peso_medio_semente'] ?? map['pesoMedioSemente'] as num?)?.toDouble(),
        sementesMetro: (map['sementes_metro'] ?? map['sementesMetro'] as num?)?.toDouble(),
        sementesHa: (map['sementes_ha'] ?? map['sementesHa'] as num?)?.toDouble(),
        kgHa: (map['kg_ha'] ?? map['kgHa'] as num?)?.toDouble(),
        sacasHa: (map['sacas_ha'] ?? map['sacasHa'] as num?)?.toDouble(),
        metodoCalibragrem: (map['metodo_calibragem'] ?? map['metodoCalibragrem']) != null 
            ? MetodoCalibragrem.values.firstWhere(
                (e) => e.toString() == (map['metodo_calibragem'] ?? map['metodoCalibragrem']),
                orElse: () => MetodoCalibragrem.engrenagem)
            : null,
        fonteEstoqueId: map['fonte_estoque_id']?.toString() ?? map['fonteEstoqueId']?.toString(),
        fonteEstoqueQuantidade: (map['fonte_estoque_quantidade'] ?? map['fonteEstoqueQuantidade'] as num?)?.toDouble(),
        fotos: parseFotos(map['fotos']),
        dataCriacao: parseDate(map['data_criacao'] ?? map['dataCriacao']) ?? DateTime.now(),
        dataAtualizacao: parseDate(map['data_atualizacao'] ?? map['dataAtualizacao']) ?? DateTime.now(),
      );
    } catch (e) {
      print('❌ Erro ao criar PlantioModel.fromMap: $e');
      print('❌ Dados recebidos: $map');
      // Retornar um modelo padrão em caso de erro
      return PlantioModel(
        id: '',
        talhaoId: '',
        culturaId: '',
        descricao: 'Erro ao carregar dados',
        dataPlantio: DateTime.now(),
      );
    }
  }

  @override
  String toString() {
    return 'PlantioModel(id: $id, descricao: $descricao, dataPlantio: $dataPlantio)';
  }
}
