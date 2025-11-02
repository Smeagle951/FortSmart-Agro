import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../utils/geo_math.dart';

/// Enum para os modos de desenho do talhão
enum ModoDesenho {
  manual,    // Desenho manual no mapa
  gps,       // Caminhada com GPS
  importacao // Importação de arquivo
}

/// Enum para os modos de criação de talhão
enum ModoCriacao {
  manual,    // Desenho manual no mapa
  gps,       // Caminhada com GPS
  importacao // Importação de arquivo
}

/// Provider para gerenciar o estado do desenho do polígono do talhão
class DesenhoProvider extends ChangeNotifier {
  final List<LatLng> _pontos = [];
  bool _desenhoConcluido = false;
  double _areaCalculada = 0.0;
  double _perimetroCalculado = 0.0;
  ModoCriacao _modoCriacao = ModoCriacao.manual;
  int? _pontoSelecionadoIndex;
  bool _modoEdicao = false;

  /// Lista de pontos do polígono
  List<LatLng> get pontos => List.unmodifiable(_pontos);
  
  /// Indica se o desenho está concluído
  bool get desenhoConcluido => _desenhoConcluido;
  
  /// Área calculada do polígono em hectares
  double get areaCalculada => _areaCalculada;
  
  /// Perímetro calculado do polígono em metros
  double get perimetroCalculado => _perimetroCalculado;
  
  /// Perímetro formatado para exibição
  String get perimetroFormatado => '${_perimetroCalculado.toStringAsFixed(1)} m';
  
  /// Área formatada para exibição
  String get areaFormatada => GeoMath.formatarArea(_areaCalculada);
  
  /// Modo de criação atual
  ModoCriacao get modoCriacao => _modoCriacao;
  
  /// Índice do ponto selecionado para edição
  int? get pontoSelecionadoIndex => _pontoSelecionadoIndex;
  
  /// Indica se está em modo de edição
  bool get modoEdicao => _modoEdicao;
  
  /// Define o modo de criação
  void definirModoCriacao(ModoCriacao modo) {
    // Se estiver mudando para o modo GPS, limpa os pontos existentes
    if (modo == ModoCriacao.gps && _modoCriacao != ModoCriacao.gps) {
      limparDesenho();
    }
    
    _modoCriacao = modo;
    notifyListeners();
  }
  
  /// Define o modo de desenho (compatibilidade com ModoDesenho)
  void setModoDesenho(ModoDesenho modo) {
    // Converte ModoDesenho para ModoCriacao
    ModoCriacao modoCriacao;
    switch (modo) {
      case ModoDesenho.manual:
        modoCriacao = ModoCriacao.manual;
        break;
      case ModoDesenho.gps:
        modoCriacao = ModoCriacao.gps;
        break;
      case ModoDesenho.importacao:
        modoCriacao = ModoCriacao.importacao;
        break;
    }
    
    // Usa o método existente
    definirModoCriacao(modoCriacao);
  }
  
  /// Define os pontos do polígono
  void setPontos(List<LatLng> pontos) {
    // Limpa os pontos existentes
    _pontos.clear();
    
    // Adiciona os novos pontos
    if (pontos.isNotEmpty) {
      _pontos.addAll(pontos);
      _calcularArea();
    }
    
    notifyListeners();
  }
  
  /// Integra pontos do GPS ao desenho do polígono
  void integrarPontosGPS(List<LatLng> pontosGPS) {
    if (_modoCriacao != ModoCriacao.gps || pontosGPS.isEmpty) {
      return;
    }
    
    // Adiciona os pontos do GPS ao desenho
    adicionarPontos(pontosGPS);
  }
  
  /// Importa pontos de um arquivo GeoJSON
  Future<bool> importarDeGeoJSON(String conteudoGeoJSON) async {
    if (_modoCriacao != ModoCriacao.importacao) {
      return false;
    }
    
    try {
      // Limpa pontos existentes
      limparDesenho();
      
      // Parseia o GeoJSON
      final Map<String, dynamic> geoJson = json.decode(conteudoGeoJSON);
      
      // Verifica se é um Feature ou FeatureCollection
      if (geoJson['type'] == 'FeatureCollection' && geoJson['features'] is List) {
        // Pega o primeiro polígono encontrado
        final features = geoJson['features'] as List;
        for (final feature in features) {
          if (feature['geometry'] != null && 
              feature['geometry']['type'] == 'Polygon' && 
              feature['geometry']['coordinates'] is List) {
            final coordinates = feature['geometry']['coordinates'][0] as List;
            final List<LatLng> pontos = [];
            
            // Converte as coordenadas para LatLng
            for (final coord in coordinates) {
              if (coord is List && coord.length >= 2) {
                // GeoJSON usa [longitude, latitude]
                pontos.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
              }
            }
            
            if (pontos.isNotEmpty) {
              adicionarPontos(pontos);
              concluirDesenho();
              return true;
            }
          }
        }
      } else if (geoJson['type'] == 'Feature' && 
                geoJson['geometry'] != null && 
                geoJson['geometry']['type'] == 'Polygon') {
        final coordinates = geoJson['geometry']['coordinates'][0] as List;
        final List<LatLng> pontos = [];
        
        // Converte as coordenadas para LatLng
        for (final coord in coordinates) {
          if (coord is List && coord.length >= 2) {
            // GeoJSON usa [longitude, latitude]
            pontos.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
          }
        }
        
        if (pontos.isNotEmpty) {
          adicionarPontos(pontos);
          concluirDesenho();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Erro ao importar GeoJSON: $e');
      return false;
    }
  }
  
  /// Adiciona um ponto ao polígono
  void adicionarPonto(LatLng ponto) {
    // Verifica se o ponto já existe para evitar duplicatas
    if (!_pontoExiste(ponto)) {
      _pontos.add(ponto);
      _calcularArea();
      notifyListeners();
    }
  }
  
  /// Verifica se um ponto já existe no polígono (com uma pequena margem de tolerância)
  bool _pontoExiste(LatLng novoPonto) {
    const double tolerancia = 0.0001; // Aproximadamente 10 metros na equador
    
    for (final ponto in _pontos) {
      if ((ponto.latitude - novoPonto.latitude).abs() < tolerancia &&
          (ponto.longitude - novoPonto.longitude).abs() < tolerancia) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Adiciona múltiplos pontos ao polígono
  void adicionarPontos(List<LatLng> novosPontos) {
    bool pontosAdicionados = false;
    
    for (final ponto in novosPontos) {
      if (!_pontoExiste(ponto)) {
        _pontos.add(ponto);
        pontosAdicionados = true;
      }
    }
    
    if (pontosAdicionados) {
      _calcularArea();
      notifyListeners();
    }
  }
  
  /// Remove o último ponto adicionado
  void removerUltimoPonto() {
    if (_pontos.isNotEmpty) {
      _pontos.removeLast();
      _calcularArea();
      notifyListeners();
    }
  }
  
  /// Remove um ponto específico pelo índice
  void removerPonto(int index) {
    if (index >= 0 && index < _pontos.length) {
      _pontos.removeAt(index);
      _pontoSelecionadoIndex = null;
      _calcularArea();
      notifyListeners();
    }
  }
  
  /// Seleciona um ponto para edição
  void selecionarPonto(int? index) {
    _pontoSelecionadoIndex = index;
    notifyListeners();
  }
  
  /// Atualiza a posição de um ponto existente
  void atualizarPonto(int index, LatLng novaPosicao) {
    if (index >= 0 && index < _pontos.length) {
      _pontos[index] = novaPosicao;
      _calcularArea();
      notifyListeners();
    }
  }
  
  /// Ativa ou desativa o modo de edição
  void alternarModoEdicao() {
    _modoEdicao = !_modoEdicao;
    if (!_modoEdicao) {
      _pontoSelecionadoIndex = null;
    }
    notifyListeners();
  }
  
  /// Limpa todos os pontos do desenho
  void limparDesenho() {
    _pontos.clear();
    _desenhoConcluido = false;
    _areaCalculada = 0.0;
    _pontoSelecionadoIndex = null;
    _modoEdicao = false;
    notifyListeners();
  }
  
  /// Finaliza o desenho do polígono
  void concluirDesenho() {
    if (_pontos.length >= 3) {
      _desenhoConcluido = true;
      _modoEdicao = false;
      _pontoSelecionadoIndex = null;
      notifyListeners();
    }
  }
  
  /// Reabre o desenho para edição
  void reabrirDesenho() {
    _desenhoConcluido = false;
    notifyListeners();
  }
  
  /// Calcula a área do polígono em hectares usando a fórmula de Gauss
  /// com correção para coordenadas geográficas usando a classe GeoMath
  void _calcularArea() {
    if (_pontos.length < 3) {
      _areaCalculada = 0.0;
      return;
    }
    
    // Utiliza a classe GeoMath para cálculo preciso de área
    _areaCalculada = GeoMath.calcularArea(_pontos);
    
    // Também calcula o perímetro para uso futuro
    _perimetroCalculado = GeoMath.calcularPerimetro(_pontos);
  }
  
  /// Exporta o polígono para formato GeoJSON
  String exportarParaGeoJSON({
    String? nome,
    String? idCultura,
    String? nomeCultura,
    String? corHex,
  }) {
    if (_pontos.length < 3) {
      return '{"type":"FeatureCollection","features":[]}'; // GeoJSON vazio
    }
    
    // Fecha o polígono para garantir que o primeiro e último pontos sejam iguais
    final List<LatLng> pontosParaExportar = List.from(_pontos);
    if (pontosParaExportar.first.latitude != pontosParaExportar.last.latitude ||
        pontosParaExportar.first.longitude != pontosParaExportar.last.longitude) {
      pontosParaExportar.add(pontosParaExportar.first);
    }
    
    // Converte os pontos para o formato GeoJSON [longitude, latitude]
    final List<List<double>> coordinates = pontosParaExportar.map((ponto) => 
      [ponto.longitude, ponto.latitude]
    ).toList();
    
    // Cria as propriedades do feature
    final Map<String, dynamic> properties = {
      'area_ha': _areaCalculada,
    };
    
    // Adiciona propriedades opcionais se fornecidas
    if (nome != null) properties['nome'] = nome;
    if (idCultura != null) properties['id_cultura'] = idCultura;
    if (nomeCultura != null) properties['nome_cultura'] = nomeCultura;
    if (corHex != null) properties['cor_hex'] = corHex;
    
    // Cria o objeto GeoJSON
    final Map<String, dynamic> geoJson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': properties,
          'geometry': {
            'type': 'Polygon',
            'coordinates': [coordinates]
          }
        }
      ]
    };
    
    // Converte para string JSON formatada
    return json.encode(geoJson);
  }
  
  /// Calcula o centro geométrico do polígono
  LatLng? calcularCentroPoligono() {
    if (_pontos.length < 3) {
      return null;
    }
    
    double lat = 0.0;
    double lng = 0.0;
    
    for (final ponto in _pontos) {
      lat += ponto.latitude;
      lng += ponto.longitude;
    }
    
    return LatLng(lat / _pontos.length, lng / _pontos.length);
  }
  
  /// Verifica se um ponto está dentro do polígono
  bool pontoEstaDentroDoPoligono(LatLng ponto) {
    if (_pontos.length < 3) return false;
    
    bool dentro = false;
    int j = _pontos.length - 1;
    
    for (int i = 0; i < _pontos.length; i++) {
      if ((_pontos[i].latitude > ponto.latitude) != (_pontos[j].latitude > ponto.latitude) &&
          (ponto.longitude < (_pontos[j].longitude - _pontos[i].longitude) * 
          (ponto.latitude - _pontos[i].latitude) / 
          (_pontos[j].latitude - _pontos[i].latitude) + _pontos[i].longitude)) {
        dentro = !dentro;
      }
      j = i;
    }
    
    return dentro;
  }
  
  /// Simplifica o polígono removendo pontos redundantes
  void simplificarPoligono(double tolerancia) {
    if (_pontos.length <= 3) return;
    
    final List<LatLng> pontosSimplificados = [];
    final double toleranciaQuadrada = tolerancia * tolerancia;
    
    pontosSimplificados.add(_pontos.first);
    
    for (int i = 1; i < _pontos.length - 1; i++) {
      final LatLng p1 = pontosSimplificados.last;
      final LatLng p2 = _pontos[i];
      final LatLng p3 = _pontos[i + 1];
      
      // Calcula a distância do ponto p2 à linha formada por p1 e p3
      final double distancia = _distanciaPontoLinha(p2, p1, p3);
      
      if (distancia > toleranciaQuadrada) {
        pontosSimplificados.add(p2);
      }
    }
    
    pontosSimplificados.add(_pontos.last);
    
    if (pontosSimplificados.length < _pontos.length) {
      _pontos.clear();
      _pontos.addAll(pontosSimplificados);
      _calcularArea();
      notifyListeners();
    }
  }
  
  /// Calcula a distância de um ponto a uma linha
  double _distanciaPontoLinha(LatLng ponto, LatLng linhaPonto1, LatLng linhaPonto2) {
    final double x = ponto.longitude;
    final double y = ponto.latitude;
    final double x1 = linhaPonto1.longitude;
    final double y1 = linhaPonto1.latitude;
    final double x2 = linhaPonto2.longitude;
    final double y2 = linhaPonto2.latitude;
    
    final double A = x - x1;
    final double B = y - y1;
    final double C = x2 - x1;
    final double D = y2 - y1;
    
    final double dot = A * C + B * D;
    final double lenSq = C * C + D * D;
    double param = -1;
    
    if (lenSq != 0) {
      param = dot / lenSq;
    }
    
    double xx, yy;
    
    if (param < 0) {
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      xx = x2;
      yy = y2;
    } else {
      xx = x1 + param * C;
      yy = y1 + param * D;
    }
    
    final double dx = x - xx;
    final double dy = y - yy;
    
    return dx * dx + dy * dy;
  }

  void limparPontos() {}
}
