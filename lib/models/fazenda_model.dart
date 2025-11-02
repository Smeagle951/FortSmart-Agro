import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';

/// Modelo para representar uma fazenda
class FazendaModel {
  final String id;
  final String nome;
  final String? endereco;
  final String? cidade;
  final String? estado;
  final String? pais;
  final double? area;
  final LatLng? localizacao;
  final String? proprietario;
  final String? contato;
  final String? observacoes;
  final String? dataCriacao;
  final String? dataAtualizacao;

  FazendaModel({
    String? id,
    required this.nome,
    this.endereco,
    this.cidade,
    this.estado,
    this.pais,
    this.area,
    this.localizacao,
    this.proprietario,
    this.contato,
    this.observacoes,
    this.dataCriacao,
    this.dataAtualizacao,
  }) : id = id ?? const Uuid().v4();

  /// Converte o modelo para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'endereco': endereco,
      'cidade': cidade,
      'estado': estado,
      'pais': pais,
      'area': area,
      'latitude': localizacao?.latitude,
      'longitude': localizacao?.longitude,
      'proprietario': proprietario,
      'contato': contato,
      'observacoes': observacoes,
      'dataCriacao': dataCriacao ?? DateTime.now().toIso8601String(),
      'dataAtualizacao': dataAtualizacao ?? DateTime.now().toIso8601String(),
    };
  }

  /// Cria um modelo a partir de um mapa
  factory FazendaModel.fromMap(Map<String, dynamic> map) {
    LatLng? localizacao;
    if (map['latitude'] != null && map['longitude'] != null) {
      localizacao = LatLng(map['latitude'], map['longitude']);
    }

    return FazendaModel(
      id: map['id'],
      nome: map['nome'],
      endereco: map['endereco'],
      cidade: map['cidade'],
      estado: map['estado'],
      pais: map['pais'],
      area: map['area'],
      localizacao: localizacao,
      proprietario: map['proprietario'],
      contato: map['contato'],
      observacoes: map['observacoes'],
      dataCriacao: map['dataCriacao'],
      dataAtualizacao: map['dataAtualizacao'],
    );
  }

  /// Cria uma cópia do modelo com alguns campos alterados
  FazendaModel copyWith({
    String? id,
    String? nome,
    String? endereco,
    String? cidade,
    String? estado,
    String? pais,
    double? area,
    LatLng? localizacao,
    String? proprietario,
    String? contato,
    String? observacoes,
    String? dataCriacao,
    String? dataAtualizacao,
  }) {
    return FazendaModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      endereco: endereco ?? this.endereco,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      pais: pais ?? this.pais,
      area: area ?? this.area,
      localizacao: localizacao ?? this.localizacao,
      proprietario: proprietario ?? this.proprietario,
      contato: contato ?? this.contato,
      observacoes: observacoes ?? this.observacoes,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}
