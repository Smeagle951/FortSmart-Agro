import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../agricultural_product_model.dart';
import '../cultura_model.dart';

/// Modelo de Talhão com suporte a múltiplas safras
class TalhaoSafraModel {
  String id;
  String name;
  String idFazenda;
  List<PoligonoModel> poligonos;
  List<SafraTalhaoModel> safras;
  DateTime dataCriacao;
  DateTime dataAtualizacao;
  bool sincronizado;
  double? area; // Propriedade para armazenar a área calculada
  Map<String, dynamic>? metadados; // Dados adicionais como produtividade, etc.
  String? observacoes;
  String? culturaId;
  String? safraId;
  String? crop;
  String? coordenadas;
  
  // Getter de compatibilidade temporária
  String get nome => name;

  TalhaoSafraModel({
    String? id,
    required this.name,
    String? nome, // Parâmetro de compatibilidade
    required this.idFazenda,
    required this.poligonos,
    List<SafraTalhaoModel>? safras,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    this.sincronizado = false,
    this.area,
    this.metadados,
    this.observacoes,
    this.culturaId,
    this.safraId,
    this.crop,
    this.coordenadas,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.safras = safras ?? [],
    this.dataCriacao = dataCriacao ?? DateTime.now(),
    this.dataAtualizacao = dataAtualizacao ?? DateTime.now();

  /// Converte o modelo para um mapa para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'idFazenda': idFazenda,
      'poligonos': poligonos.map((p) => p.toMap()).toList(),
      'safras': safras.map((s) => s.toMap()).toList(),
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0,
      'area': area,
      'metadados': metadados,
    };
  }

  /// Cria um modelo a partir de um mapa
  factory TalhaoSafraModel.fromMap(Map<String, dynamic> map) {
    try {
      // Converter polígonos
      List<PoligonoModel> poligonos = [];
      if (map['poligonos'] != null) {
        if (map['poligonos'] is String) {
          // Se for string JSON, fazer parse
          final poligonosJson = jsonDecode(map['poligonos'] as String);
          if (poligonosJson is List) {
            poligonos = poligonosJson
                .map((p) => PoligonoModel.fromMap(p))
                .toList();
          }
        } else if (map['poligonos'] is List) {
          // Se for lista, converter diretamente
          poligonos = (map['poligonos'] as List)
              .map((p) => PoligonoModel.fromMap(p))
              .toList();
        }
      }
      
      // Converter safras
      List<SafraTalhaoModel> safras = [];
      if (map['safras'] != null) {
        if (map['safras'] is String) {
          // Se for string JSON, fazer parse
          final safrasJson = jsonDecode(map['safras'] as String);
          if (safrasJson is List) {
            safras = safrasJson
                .map((s) => SafraTalhaoModel.fromMap(s))
                .toList();
          }
        } else if (map['safras'] is List) {
          // Se for lista, converter diretamente
          safras = (map['safras'] as List)
              .map((s) => SafraTalhaoModel.fromMap(s))
              .toList();
        }
      }
      
      return TalhaoSafraModel(
        id: map['id'],
        name: map['name'],
        idFazenda: map['idFazenda'],
        poligonos: poligonos,
        safras: safras,
        dataCriacao: map['dataCriacao'] != null 
            ? DateTime.parse(map['dataCriacao']) 
            : null,
        dataAtualizacao: map['dataAtualizacao'] != null 
            ? DateTime.parse(map['dataAtualizacao']) 
            : null,
        sincronizado: map['sincronizado'] == 1 || map['sincronizado'] == true,
        area: map['area'] != null ? (map['area'] is double ? map['area'] : double.tryParse(map['area'].toString())) : null,
        metadados: map['metadados'],
      );
    } catch (e) {
      print('Erro ao converter TalhaoSafraModel: $e');
      rethrow;
    }
  }

  /// Calcula a área total do talhão em hectares
  double calcularAreaTotal() {
    if (poligonos.isEmpty) return 0.0;
    
    double areaTotal = 0.0;
    for (var poligono in poligonos) {
      areaTotal += poligono.calcularAreaHectares();
    }
    
    return areaTotal;
  }

  /// Getter para área total (compatibilidade)
  double get areaTotal {
    // Verificar se é um talhão importado
    bool isImportedTalhao = name.toLowerCase().contains('importado') || 
                           name.toLowerCase().contains('import') ||
                           name.toLowerCase().contains('pivô') ||
                           name.toLowerCase().contains('pivo');
    
    if (isImportedTalhao) {
      // Para talhões importados, priorizar área original
      if (area != null && area! > 0) {
        return area!;
      }
      
      // Se não tem área no talhão, tentar área da safra
      if (safras.isNotEmpty) {
        final safra = safras.first;
        if (safra.area != null && safra.area! > 0) {
          return safra.area!.toDouble();
        }
      }
      
      // Se não tem área na safra, tentar área dos polígonos (mas sem recalcular)
      double areaTotal = 0.0;
      for (final poligono in poligonos) {
        if (poligono.area > 0) {
          areaTotal += poligono.area;
        }
      }
      
      if (areaTotal > 0) {
        return areaTotal;
      }
    }
    
    // Para talhões criados manualmente, usar área do talhão ou calcular
    return area ?? calcularAreaTotal();
  }

  /// Retorna a safra atual (a mais recente)
  SafraTalhaoModel? get safraAtual {
    if (safras.isEmpty) return null;
    
    // Ordenar por data de criação (mais recente primeiro)
    final safrasOrdenadas = List<SafraTalhaoModel>.from(safras);
    safrasOrdenadas.sort((a, b) => b.dataCadastro.compareTo(a.dataCadastro));
    
    return safrasOrdenadas.first;
  }

  /// Retorna a cor do talhão baseada na cultura da safra atual
  Color get cor {
    final atual = safraAtual;
    if (atual != null) {
      return atual.culturaCor;
    }
    
    // Cor padrão se não tiver cultura ou cor definida
    return Colors.blue;
  }

  get pontos => poligonos.isNotEmpty ? poligonos.first.pontos : <LatLng>[];

  get corCultura => safraAtual?.culturaCor ?? Colors.blue;


  /// Getter para nome da cultura (compatibilidade)
  String get culturaNome => safraAtual?.culturaNome ?? '';

  
  /// Converte o talhão para o formato GeoJSON
  Map<String, dynamic> toGeoJson() {
    if (poligonos.isEmpty) {
      throw Exception('Talhão sem polígonos não pode ser convertido para GeoJSON');
    }
    
    // Pega o primeiro polígono para exportação
    final poligono = poligonos.first;
    
    // Cria as coordenadas no formato GeoJSON (longitude, latitude)
    final List<List<List<double>>> coordinates = [
      poligono.pontos.map((ponto) => [ponto.longitude, ponto.latitude]).toList()
    ];
    
    // Fecha o polígono adicionando o primeiro ponto no final, se necessário
    if (poligono.pontos.isNotEmpty && 
        (poligono.pontos.first.latitude != poligono.pontos.last.latitude || 
         poligono.pontos.first.longitude != poligono.pontos.last.longitude)) {
      coordinates[0].add([poligono.pontos.first.longitude, poligono.pontos.first.latitude]);
    }
    
    // Propriedades do feature
    final Map<String, dynamic> properties = {
      'id': id,
      'nome': name,
      'area': calcularAreaTotal(),
      'dataCriacao': dataCriacao.toIso8601String(),
    };
    
    // Adiciona informações da safra atual, se houver
    if (safraAtual != null) {
      properties['safra'] = safraAtual!.idSafra;
      properties['cultura'] = safraAtual!.culturaNome;
      properties['culturaCor'] = safraAtual!.culturaCor.value.toRadixString(16);
    }
    
    // Retorna o feature completo
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': coordinates,
      },
      'properties': properties,
    };
  }

  /// Cria uma cópia do modelo com os campos atualizados
  TalhaoSafraModel copyWith({
    String? id,
    String? nome,
    String? idFazenda,
    List<PoligonoModel>? poligonos,
    List<SafraTalhaoModel>? safras,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    bool? sincronizado,
    double? area,
    Map<String, dynamic>? metadados,
  }) {
    return TalhaoSafraModel(
      id: id ?? this.id,
      name: nome ?? this.name,
      idFazenda: idFazenda ?? this.idFazenda,
      poligonos: poligonos ?? this.poligonos,
      safras: safras ?? this.safras,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      sincronizado: sincronizado ?? this.sincronizado,
      area: area ?? this.area,
      metadados: metadados ?? this.metadados,
    );
  }
}

/// Modelo para representar um polígono de um talhão
class PoligonoModel {
  final String id;
  final String talhaoId;
  final List<LatLng> pontos;
  final int area;
  final int perimetro;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final bool ativo;

  PoligonoModel({
    required this.id,
    required this.talhaoId,
    required this.pontos,
    required this.area,
    required this.perimetro,
    required this.dataCriacao,
    required this.dataAtualizacao,
    required this.ativo,
  });

  /// Converte o modelo para um mapa
  Map<String, dynamic> toMap() {
    return {
      'pontos': pontos.map((p) => '${p.latitude},${p.longitude}').join(';'),
    };
  }

  /// Cria um modelo a partir de um mapa
  factory PoligonoModel.fromMap(Map<String, dynamic> map) {
    List<LatLng> pontos = [];
    
    if (map['pontos'] != null) {
      final pontosStr = map['pontos'] as String;
      final pontosArray = pontosStr.split(';');
      
      for (var ponto in pontosArray) {
        final coords = ponto.split(',');
        if (coords.length >= 2) {
          final lat = double.tryParse(coords[0]) ?? 0.0;
          final lng = double.tryParse(coords[1]) ?? 0.0;
          pontos.add(LatLng(lat, lng));
        }
      }
    }
    
    return PoligonoModel(
      pontos: pontos, 
      id: map['id'] ?? '',
      talhaoId: map['talhaoId'] ?? '',
      area: map['area'] != null ? (map['area'] is int ? map['area'] : int.tryParse(map['area'].toString()) ?? 0) : 0,
      perimetro: map['perimetro'] != null ? (map['perimetro'] is int ? map['perimetro'] : int.tryParse(map['perimetro'].toString()) ?? 0) : 0,
      dataCriacao: map['dataCriacao'] != null ? DateTime.parse(map['dataCriacao']) : DateTime.now(),
      dataAtualizacao: map['dataAtualizacao'] != null ? DateTime.parse(map['dataAtualizacao']) : DateTime.now(),
      ativo: map['ativo'] != null ? map['ativo'] == 1 || map['ativo'] == true : true
    );
  }

  /// Calcula a área do polígono em hectares usando a fórmula de Gauss
  double calcularAreaHectares() {
    if (pontos.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < pontos.length; i++) {
      int j = (i + 1) % pontos.length;
      area += pontos[i].longitude * pontos[j].latitude;
      area -= pontos[j].longitude * pontos[i].latitude;
    }
    
    // Converter para hectares usando fator de conversão correto
          area = (area.abs() / 2.0) * 11100; // 111 km² = 11.100 hectares
    return area;
  }
}

/// Modelo para representar uma safra associada a um talhão
class SafraTalhaoModel {
  String id;
  String idTalhao;
  String idSafra;
  String idCultura;
  String culturaNome;
  Color culturaCor;
  String? imagemCultura;
  double area;
  DateTime dataCadastro;
  DateTime dataAtualizacao;
  bool sincronizado;

  SafraTalhaoModel({
    String? id,
    required this.idTalhao,
    required this.idSafra,
    required this.idCultura,
    required this.culturaNome,
    required this.culturaCor,
    this.imagemCultura,
    required this.area,
    DateTime? dataCadastro,
    DateTime? dataAtualizacao,
    this.sincronizado = false,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.dataCadastro = dataCadastro ?? DateTime.now(),
    this.dataAtualizacao = dataAtualizacao ?? DateTime.now();

  /// Converte o modelo para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idTalhao': idTalhao,
      'idSafra': idSafra,
      'idCultura': idCultura,
      'culturaNome': culturaNome,
      'culturaCor': culturaCor.value,
      'imagemCultura': imagemCultura,
      'area': area,
      'dataCadastro': dataCadastro.toIso8601String(),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0,
    };
  }

  /// Cria um modelo a partir de um mapa
  factory SafraTalhaoModel.fromMap(Map<String, dynamic> map) {
    // CORREÇÃO: Converter cor de forma mais robusta
    Color culturaCor;
    try {
      final corValue = map['culturaCor'];
      if (corValue is int) {
        culturaCor = Color(corValue);
      } else if (corValue is String) {
        // Se for string hex, converter para int
        if (corValue.startsWith('#')) {
          culturaCor = Color(int.parse(corValue.substring(1), radix: 16) + 0xFF000000);
        } else {
          culturaCor = Color(int.parse(corValue));
        }
      } else {
        // Fallback para cor padrão
        culturaCor = Colors.green;
      }
    } catch (e) {
      print('⚠️ Erro ao converter cor da cultura: $e, usando cor padrão');
      culturaCor = Colors.green;
    }

    return SafraTalhaoModel(
      id: map['id'],
      idTalhao: map['idTalhao'],
      idSafra: map['idSafra'],
      idCultura: map['idCultura'],
      culturaNome: map['culturaNome'],
      culturaCor: culturaCor,
      imagemCultura: map['imagemCultura'],
      area: map['area'] is double ? map['area'] : double.parse(map['area'].toString()),
      dataCadastro: map['dataCadastro'] != null 
          ? DateTime.parse(map['dataCadastro']) 
          : null,
      dataAtualizacao: map['dataAtualizacao'] != null 
          ? DateTime.parse(map['dataAtualizacao']) 
          : null,
      sincronizado: map['sincronizado'] == 1 || map['sincronizado'] == true,
    );
  }

  /// Getter para culturaId (compatibilidade)
  String get culturaId => idCultura;

  /// Cria uma cópia do modelo com os campos atualizados
  SafraTalhaoModel copyWith({
    String? id,
    String? idTalhao,
    String? idSafra,
    String? idCultura,
    String? culturaNome,
    Color? culturaCor,
    String? imagemCultura,
    double? area,
    DateTime? dataCadastro,
    DateTime? dataAtualizacao,
    bool? sincronizado,
  }) {
    return SafraTalhaoModel(
      id: id ?? this.id,
      idTalhao: idTalhao ?? this.idTalhao,
      idSafra: idSafra ?? this.idSafra,
      idCultura: idCultura ?? this.idCultura,
      culturaNome: culturaNome ?? this.culturaNome,
      culturaCor: culturaCor ?? this.culturaCor,
      imagemCultura: imagemCultura ?? this.imagemCultura,
      area: area ?? this.area,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }
}

/// Modelo para representar uma cultura da fazenda
class CulturaFazendaModel {
  String id;
  String idFazenda;
  String name;
  String corHex;
  String? imagem;
  bool ativa;
  DateTime dataCriacao;
  DateTime dataAtualizacao;
  // Getter de compatibilidade temporária
  String get nome => name;

  CulturaFazendaModel({
    String? id,
    required this.idFazenda,
    required this.name,
    required this.corHex,
    this.imagem,
    this.ativa = true,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.dataCriacao = dataCriacao ?? DateTime.now(),
    this.dataAtualizacao = dataAtualizacao ?? DateTime.now();

  /// Converte o modelo para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idFazenda': idFazenda,
      'name': name,
      'corHex': corHex,
      'imagem': imagem,
      'ativa': ativa ? 1 : 0,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
    };
  }

  /// Cria um modelo a partir de um mapa
  factory CulturaFazendaModel.fromMap(Map<String, dynamic> map) {
    return CulturaFazendaModel(
      id: map['id'],
      idFazenda: map['idFazenda'],
      name: map['name'],
      corHex: map['corHex'],
      imagem: map['imagem'],
      ativa: map['ativa'] == 1 || map['ativa'] == true,
      dataCriacao: map['dataCriacao'] != null 
          ? DateTime.parse(map['dataCriacao']) 
          : null,
      dataAtualizacao: map['dataAtualizacao'] != null 
          ? DateTime.parse(map['dataAtualizacao']) 
          : null,
    );
  }

  /// Converte para o modelo AgriculturalProduct
  AgriculturalProduct toAgriculturalProduct() {
    // Converter a cor de hexadecimal para Color
    final colorValue = int.parse(corHex.replaceFirst('#', '0xFF'));
    
    return AgriculturalProduct(
      id: id,
      name: nome,
      description: 'Cultura da fazenda: $idFazenda',
      imageUrl: imagem,
      color: Color(colorValue),
      type: 'culture',
      createdAt: dataCriacao,
      updatedAt: dataAtualizacao,
    );
  }

  /// Cria a partir de um AgriculturalProduct
  factory CulturaFazendaModel.fromAgriculturalProduct(AgriculturalProduct product, String idFazenda) {
    // Converter a cor para formato hexadecimal
    final colorHex = '#${product.color.value.toRadixString(16).substring(2)}';
    
    return CulturaFazendaModel(
      id: product.id,
      idFazenda: idFazenda,
      name: product.name,
      corHex: colorHex,
      imagem: product.imageUrl,
      ativa: !product.isDeleted,
      dataCriacao: product.createdAt,
      dataAtualizacao: product.updatedAt,
    );
  }

  /// Converte para o modelo CulturaModel
  CulturaModel toCulturaModel() {
    // Converter a cor de hexadecimal para Color
    final colorValue = int.parse(corHex.replaceFirst('#', '0xFF'));
    
    return CulturaModel(
      id: id,
      name: nome,
      description: 'Cultura da fazenda: $idFazenda',
      color: Color(colorValue),
    );
  }

  /// Cria a partir de um CulturaModel
  factory CulturaFazendaModel.fromCulturaModel(CulturaModel cultura, String idFazenda) {
    // Converter a cor para formato hexadecimal
    final colorHex = '#${cultura.color.value.toRadixString(16).substring(2)}';
    
    return CulturaFazendaModel(
      id: cultura.id,
      idFazenda: idFazenda,
      name: cultura.name,
      corHex: colorHex,
      ativa: true,
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
    );
  }

  /// Retorna a cor como objeto Color
  Color get cor {
    return Color(int.parse(corHex.replaceFirst('#', '0xFF')));
  }
}
