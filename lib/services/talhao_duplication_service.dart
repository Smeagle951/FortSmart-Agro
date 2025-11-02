import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhoes/talhao_safra_model.dart';
// import '../models/safra_talhao_model.dart'; // Removido - conflito de importação
// import '../models/poligono_model.dart'; // Removido - conflito de importação

/// Serviço para duplicar talhões com todas as suas propriedades
class TalhaoDuplicationService {
  
  /// Duplica um talhão existente com todas as suas propriedades
  /// Retorna um novo talhão com ID único e nome modificado
  Future<TalhaoSafraModel?> duplicarTalhao(
    dynamic talhaoOriginal, {
    String? novoNome,
    String? novaSafra,
    String? novaCultura,
    Color? novaCorCultura,
    double? offsetLatitude = 0.0001, // Pequeno offset para não sobrepor
    double? offsetLongitude = 0.0001,
  }) async {
    try {
      // Gerar novo ID único
      final novoId = const Uuid().v4();
      
      // Nome do talhão duplicado
      final nomeFinal = novoNome ?? '${talhaoOriginal.name}_copia';
      
      // Duplicar polígonos com pequeno offset
      final poligonosDuplicados = <PoligonoModel>[];
      if (talhaoOriginal.poligonos != null) {
        for (final poligono in talhaoOriginal.poligonos) {
          final poligonoDuplicado = _duplicarPoligono(
            poligono,
            novoId,
            offsetLatitude: offsetLatitude,
            offsetLongitude: offsetLongitude,
          );
          poligonosDuplicados.add(poligonoDuplicado);
        }
      }
      
      // Duplicar safras
      final safrasDuplicadas = <SafraTalhaoModel>[];
      if (talhaoOriginal.safras != null) {
        for (final safra in talhaoOriginal.safras) {
          final safraDuplicada = _duplicarSafra(
            safra,
            novoId,
            novaSafra: novaSafra,
            novaCultura: novaCultura,
            novaCorCultura: novaCorCultura,
          );
          safrasDuplicadas.add(safraDuplicada);
        }
      }
      
      // Criar novo talhão duplicado
      final talhaoDuplicado = TalhaoSafraModel(
        id: novoId,
        name: nomeFinal,
        idFazenda: talhaoOriginal.idFazenda ?? 'fazenda_1',
        poligonos: poligonosDuplicados,
        safras: safrasDuplicadas,
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        sincronizado: false, // Sempre começa como não sincronizado
        area: talhaoOriginal.area,
        metadados: _duplicarMetadados(talhaoOriginal.metadados),
      );
      
      return talhaoDuplicado;
    } catch (e) {
      debugPrint('❌ Erro ao duplicar talhão: $e');
      return null;
    }
  }
  
  /// Duplica um polígono com offset nas coordenadas
  PoligonoModel _duplicarPoligono(
    dynamic poligonoOriginal,
    String novoTalhaoId, {
    double? offsetLatitude = 0.0001,
    double? offsetLongitude = 0.0001,
  }) {
    // Duplicar pontos com offset
    final pontosDuplicados = <LatLng>[];
    if (poligonoOriginal.pontos != null) {
      for (final ponto in poligonoOriginal.pontos) {
        if (ponto != null) {
          double? lat, lng;
          
          if (ponto is LatLng) {
            lat = ponto.latitude;
            lng = ponto.longitude;
          } else if (ponto.latitude != null && ponto.longitude != null) {
            lat = ponto.latitude.toDouble();
            lng = ponto.longitude.toDouble();
          }
          
          if (lat != null && lng != null) {
            pontosDuplicados.add(LatLng(
              lat + (offsetLatitude ?? 0.0001),
              lng + (offsetLongitude ?? 0.0001),
            ));
          }
        }
      }
    }
    
    return PoligonoModel(
      id: const Uuid().v4(),
      talhaoId: novoTalhaoId,
      pontos: pontosDuplicados,
      area: poligonoOriginal.area ?? 0.0,
      perimetro: poligonoOriginal.perimetro ?? 0.0,
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      ativo: true,
    );
  }
  
  /// Duplica uma safra
  SafraTalhaoModel _duplicarSafra(
    dynamic safraOriginal,
    String novoTalhaoId, {
    String? novaSafra,
    String? novaCultura,
    Color? novaCorCultura,
  }) {
    return SafraTalhaoModel(
      id: const Uuid().v4(),
      idTalhao: novoTalhaoId,
      idSafra: novaSafra ?? safraOriginal.idSafra ?? 'safra_2024',
      idCultura: safraOriginal.idCultura ?? 'cultura_padrao',
      culturaNome: novaCultura ?? safraOriginal.culturaNome ?? 'Cultura não definida',
      culturaCor: novaCorCultura ?? safraOriginal.culturaCor ?? Colors.green,
      area: safraOriginal.area ?? 0.0,
      dataCadastro: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      sincronizado: false,
    );
  }
  
  /// Duplica metadados do talhão
  Map<String, dynamic> _duplicarMetadados(Map<String, dynamic>? metadados) {
    if (metadados == null) return {};
    
    final metadadosDuplicados = Map<String, dynamic>.from(metadados);
    metadadosDuplicados['duplicado_em'] = DateTime.now().toIso8601String();
    metadadosDuplicados['versao_original'] = metadadosDuplicados['versao'] ?? '1.0';
    metadadosDuplicados['versao'] = '1.0';
    
    return metadadosDuplicados;
  }
  
  /// Duplica múltiplos talhões
  Future<List<TalhaoSafraModel>> duplicarTalhoes(
    List<dynamic> talhoes, {
    String? prefixoNome,
    double? offsetLatitude = 0.0001,
    double? offsetLongitude = 0.0001,
  }) async {
    final talhoesDuplicados = <TalhaoSafraModel>[];
    
    for (int i = 0; i < talhoes.length; i++) {
      final talhao = talhoes[i];
      final novoNome = prefixoNome != null 
        ? '${prefixoNome}_${talhao.name}_${i + 1}'
        : '${talhao.name}_copia_${i + 1}';
      
      final talhaoDuplicado = await duplicarTalhao(
        talhao,
        novoNome: novoNome,
        offsetLatitude: offsetLatitude,
        offsetLongitude: offsetLongitude,
      );
      
      if (talhaoDuplicado != null) {
        talhoesDuplicados.add(talhaoDuplicado);
      }
    }
    
    return talhoesDuplicados;
  }
  
  /// Verifica se um talhão é uma duplicata
  bool isDuplicata(TalhaoSafraModel talhao) {
    return talhao.name.toLowerCase().contains('copia') ||
           talhao.name.toLowerCase().contains('duplicado') ||
           talhao.name.toLowerCase().contains('_copy');
  }
  
  /// Obtém informações sobre a duplicação
  Map<String, dynamic> getDuplicacaoInfo(TalhaoSafraModel talhao) {
    final metadados = talhao.metadados;
    
    return {
      'duplicado_em': metadados?['duplicado_em'],
      'versao_original': metadados?['versao_original'],
      'versao_atual': metadados?['versao'],
      'is_duplicata': isDuplicata(talhao),
    };
  }
  
  /// Cria um talhão de teste para desenvolvimento
  TalhaoSafraModel criarTalhaoTeste({
    String? nome,
    String? idFazenda,
    List<LatLng>? pontos,
  }) {
    final nomeFinal = nome ?? 'Talhão Teste';
    final idFazendaFinal = idFazenda ?? 'fazenda_teste';
    final pontosFinal = pontos ?? [
      const LatLng(-15.7801, -47.9292),
      const LatLng(-15.7802, -47.9293),
      const LatLng(-15.7803, -47.9292),
      const LatLng(-15.7801, -47.9292),
    ];
    
    final poligono = PoligonoModel(
      id: const Uuid().v4(),
      talhaoId: const Uuid().v4(),
      pontos: pontosFinal,
      area: 1,
      perimetro: 150,
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      ativo: true,
    );
    
    final safra = SafraTalhaoModel(
      id: const Uuid().v4(),
      idTalhao: const Uuid().v4(),
      idSafra: '2024/2025',
      idCultura: 'soja_2024',
      culturaNome: 'Soja',
      culturaCor: Colors.green,
      area: 1.5,
      dataCadastro: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      sincronizado: false,
    );
    
    return TalhaoSafraModel(
      id: const Uuid().v4(),
      name: nomeFinal,
      idFazenda: idFazendaFinal,
      poligonos: [poligono],
      safras: [safra],
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      sincronizado: false,
      area: 1.5,
      metadados: {
        'tipo': 'teste',
        'criado_por': 'sistema',
        'versao': '1.0',
      },
    );
  }
}
