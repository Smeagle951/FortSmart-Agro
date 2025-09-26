import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../models/talhoes/talhao_safra_model.dart';
import '../../../services/database_service.dart';
import '../../../database/migrations/talhoes_table_migration.dart';

/// Provider otimizado para gerenciar talhões com safras
class TalhaoProviderOptimized extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<TalhaoSafraModel> _talhoes = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<TalhaoSafraModel> get talhoes => List.unmodifiable(_talhoes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// Carrega todos os talhões do banco de dados local com timeout
  Future<List<TalhaoSafraModel>> carregarTalhoes({String? idFazenda}) async {
    try {
      print('🔍 DEBUG: Iniciando carregamento de talhões');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Garantir que a tabela existe
      final db = await _databaseService.database;
      await TalhoesTableMigration.migrate(db);
      
      // Consulta no banco de dados com timeout
      final List<Map<String, dynamic>> maps = await _queryTalhoesWithTimeout(idFazenda);
      print('🔍 DEBUG: Consulta concluída, ${maps.length} talhões encontrados');
      
      // Limpa a lista atual
      _talhoes.clear();
      
      // Converte os resultados para modelos
      for (final map in maps) {
        try {
          final talhao = _converterMapParaTalhao(map);
          if (talhao != null) {
            _talhoes.add(talhao);
          }
        } catch (e) {
          print('🔍 DEBUG: Erro ao converter talhão: $e');
        }
      }
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      
      return _talhoes;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar talhões: $e';
      notifyListeners();
      print('🔍 DEBUG: Erro ao carregar talhões: $e');
      return [];
    }
  }
  
  /// Consulta talhões com timeout
  Future<List<Map<String, dynamic>>> _queryTalhoesWithTimeout(String? idFazenda) async {
    return await _databaseService.queryData(
      'talhoes',
      where: idFazenda != null ? 'idFazenda = ?' : null,
      whereArgs: idFazenda != null ? [idFazenda] : null,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('🔍 DEBUG: Timeout na consulta de talhões');
        return <Map<String, dynamic>>[];
      },
    );
  }
  
  /// Salva um novo talhão no banco de dados local (otimizado)
  Future<bool> salvarTalhao({
    required String nome,
    required String idFazenda,
    required List<LatLng> pontos,
    required String idCultura,
    required String nomeCultura,
    required Color corCultura,
    required String idSafra,
    String? imagemCultura,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Calcular área do polígono de forma assíncrona
      final area = await _calcularAreaAsync(pontos);
      print('🔍 DEBUG: Área calculada: $area hectares');
      
      // Cria o polígono a partir dos pontos
      final talhaoId = const Uuid().v4();
      final poligono = PoligonoModel(
        id: const Uuid().v4(),
        talhaoId: talhaoId,
        pontos: pontos,
        area: area.toInt(),
        perimetro: await _calcularPerimetroAsync(pontos),
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        ativo: true,
      );
      
      // Cria o modelo de safra associada ao talhão
      final safra = SafraTalhaoModel(
        id: const Uuid().v4(),
        idTalhao: talhaoId,
        idSafra: idSafra,
        idCultura: idCultura,
        culturaNome: nomeCultura,
        culturaCor: corCultura,
        area: area,
        dataCadastro: DateTime.now(),
        dataAtualizacao: DateTime.now(),
      );
      
      // Cria o modelo de talhão
      final talhao = TalhaoSafraModel(
        id: talhaoId,
        name: nome,
        idFazenda: idFazenda,
        poligonos: [poligono],
        safras: [safra],
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
      );
      
      // Preparar dados para inserção na tabela talhoes
      final dadosParaInserir = {
        'id': talhao.id,
        'name': talhao.name,
        'idFazenda': talhao.idFazenda,
        'poligonos': _converterPoligonosParaJson(talhao.poligonos),
        'safras': _converterSafrasParaJson(talhao.safras),
        'dataCriacao': talhao.dataCriacao.toIso8601String(),
        'dataAtualizacao': talhao.dataAtualizacao.toIso8601String(),
        'sincronizado': 0,
      };
      
      // Salva no banco de dados com timeout
      final id = await _databaseService.insertData('talhoes', dadosParaInserir).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('🔍 DEBUG: Timeout ao inserir talhão');
          return -1;
        },
      );
      
      if (id > 0) {
        // Adiciona à lista em memória
        _talhoes.add(talhao);
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Erro ao salvar talhão no banco de dados';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao salvar talhão: $e';
      notifyListeners();
      print('🔍 DEBUG: Erro ao salvar talhão: $e');
      return false;
    }
  }
  
  /// Calcula área de forma assíncrona
  Future<double> _calcularAreaAsync(List<LatLng> pontos) async {
    if (pontos.length < 3) return 0.0;
    
    try {
      // Cálculo simplificado para evitar travamentos
      double area = 0.0;
      final n = pontos.length;
      
      for (int i = 0; i < n; i++) {
        final j = (i + 1) % n;
        area += pontos[i].longitude * pontos[j].latitude;
        area -= pontos[j].longitude * pontos[i].latitude;
      }
      
      area = area.abs() / 2.0;
      // Converter para hectares usando fator de conversão correto
      // 1 grau² ≈ 111 km² na latitude média do Brasil
      const double grauParaHectares = 11100000; // 111 km² = 11.100.000 hectares
      return area * grauParaHectares;
    } catch (e) {
      print('🔍 DEBUG: Erro no cálculo de área: $e');
      return 0.0;
    }
  }
  
  /// Calcula perímetro de forma assíncrona
  Future<int> _calcularPerimetroAsync(List<LatLng> pontos) async {
    if (pontos.length < 2) return 0;
    
    try {
      double perimetro = 0.0;
      for (int i = 0; i < pontos.length; i++) {
        final p1 = pontos[i];
        final p2 = pontos[(i + 1) % pontos.length];
        perimetro += _calcularDistancia(p1, p2);
      }
      
      return perimetro.toInt();
    } catch (e) {
      print('🔍 DEBUG: Erro no cálculo de perímetro: $e');
      return 0;
    }
  }
  
  /// Calcula a distância entre dois pontos
  double _calcularDistancia(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    final lat1 = p1.latitude * pi / 180;
    final lat2 = p2.latitude * pi / 180;
    final deltaLat = (p2.latitude - p1.latitude) * pi / 180;
    final deltaLng = (p2.longitude - p1.longitude) * pi / 180;
    
    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Converte mapa para modelo de talhão
  TalhaoSafraModel? _converterMapParaTalhao(Map<String, dynamic> map) {
    try {
      final poligonos = _converterJsonParaPoligonos(map['poligonos'] ?? '[]');
      final safras = _converterJsonParaSafras(map['safras'] ?? '[]');
      
      return TalhaoSafraModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        idFazenda: map['idFazenda'] ?? '',
        poligonos: poligonos,
        safras: safras,
        dataCriacao: DateTime.tryParse(map['dataCriacao'] ?? '') ?? DateTime.now(),
        dataAtualizacao: DateTime.tryParse(map['dataAtualizacao'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      print('🔍 DEBUG: Erro ao converter mapa para talhão: $e');
      return null;
    }
  }
  
  /// Converte polígonos para JSON
  String _converterPoligonosParaJson(List<PoligonoModel> poligonos) {
    try {
      final List<Map<String, dynamic>> poligonosJson = poligonos.map((poligono) {
        return {
          'id': poligono.id,
          'talhaoId': poligono.talhaoId,
          'pontos': poligono.pontos.map((ponto) => {
            'latitude': ponto.latitude,
            'longitude': ponto.longitude,
          }).toList(),
          'area': poligono.area,
          'perimetro': poligono.perimetro,
          'dataCriacao': poligono.dataCriacao.toIso8601String(),
          'dataAtualizacao': poligono.dataAtualizacao.toIso8601String(),
          'ativo': poligono.ativo ? 1 : 0,
        };
      }).toList();
      
      return jsonEncode(poligonosJson);
    } catch (e) {
      print('🔍 DEBUG: Erro ao converter polígonos para JSON: $e');
      return '[]';
    }
  }
  
  /// Converte safras para JSON
  String _converterSafrasParaJson(List<SafraTalhaoModel> safras) {
    try {
      final List<Map<String, dynamic>> safrasJson = safras.map((safra) {
        return {
          'id': safra.id,
          'idTalhao': safra.idTalhao,
          'idSafra': safra.idSafra,
          'idCultura': safra.idCultura,
          'culturaNome': safra.culturaNome,
          'culturaCor': safra.culturaCor.value,
          'area': safra.area,
          'dataCadastro': safra.dataCadastro.toIso8601String(),
          'dataAtualizacao': safra.dataAtualizacao.toIso8601String(),
        };
      }).toList();
      
      return jsonEncode(safrasJson);
    } catch (e) {
      print('🔍 DEBUG: Erro ao converter safras para JSON: $e');
      return '[]';
    }
  }
  
  /// Converte JSON para polígonos
  List<PoligonoModel> _converterJsonParaPoligonos(String jsonString) {
    try {
      final List<dynamic> poligonosJson = jsonDecode(jsonString);
      return poligonosJson.map((json) {
        final pontos = (json['pontos'] as List).map((ponto) {
          return LatLng(ponto['latitude'], ponto['longitude']);
        }).toList();
        
        return PoligonoModel(
          id: json['id'] ?? '',
          talhaoId: json['talhaoId'] ?? '',
          pontos: pontos,
          area: json['area'] ?? 0,
          perimetro: json['perimetro'] ?? 0,
          dataCriacao: DateTime.tryParse(json['dataCriacao'] ?? '') ?? DateTime.now(),
          dataAtualizacao: DateTime.tryParse(json['dataAtualizacao'] ?? '') ?? DateTime.now(),
          ativo: json['ativo'] == 1,
        );
      }).toList();
    } catch (e) {
      print('🔍 DEBUG: Erro ao converter JSON para polígonos: $e');
      return [];
    }
  }
  
  /// Converte JSON para safras
  List<SafraTalhaoModel> _converterJsonParaSafras(String jsonString) {
    try {
      final List<dynamic> safrasJson = jsonDecode(jsonString);
      return safrasJson.map((json) {
        return SafraTalhaoModel(
          id: json['id'] ?? '',
          idTalhao: json['idTalhao'] ?? '',
          idSafra: json['idSafra'] ?? '',
          idCultura: json['idCultura'] ?? '',
          culturaNome: json['culturaNome'] ?? '',
          culturaCor: Color(json['culturaCor'] ?? 0xFF4CAF50),
          area: (json['area'] ?? 0.0).toDouble(),
          dataCadastro: DateTime.tryParse(json['dataCadastro'] ?? '') ?? DateTime.now(),
          dataAtualizacao: DateTime.tryParse(json['dataAtualizacao'] ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('🔍 DEBUG: Erro ao converter JSON para safras: $e');
      return [];
    }
  }
  
  /// Limpa o erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Força o recarregamento dos talhões
  Future<void> recarregarTalhoes({String? idFazenda}) async {
    await carregarTalhoes(idFazenda: idFazenda);
  }
}
