import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../repositories/talhao_repository.dart';
import '../repositories/talhao_repository_v2.dart';
import '../services/talhao_module_service.dart';
import '../services/talhao_unified_service.dart';
import '../services/database_service.dart';
import '../models/talhao_model.dart';
import '../models/poligono_model.dart';

class TalhaoSafraModel {
  final String id;
  final String nome;
  final String culturaId;
  final List<LatLng> pontos;
  final double area;
  final double perimetro;
  final DateTime dataCriacao;
  final Color corCultura;

  TalhaoSafraModel({
    required this.id,
    required this.nome,
    required this.culturaId,
    required this.pontos,
    required this.area,
    required this.perimetro,
    required this.dataCriacao,
    required this.corCultura,
  });

  // Estrutura de polígonos compatível com a tela
  List<PoligonoWrapper> get poligonos {
    if (pontos.isNotEmpty) {
      return [PoligonoWrapper(pontos: pontos)];
    }
    return [];
  }

  get cultura => null;

  get safraAtual => null;
  
  // Getter de compatibilidade
  String get name => nome;

  /// Cria uma cópia do modelo com alterações
  TalhaoSafraModel copyWith({
    String? id,
    String? nome,
    String? culturaId,
    List<LatLng>? pontos,
    double? area,
    double? perimetro,
    DateTime? dataCriacao,
    Color? corCultura,
  }) {
    return TalhaoSafraModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      culturaId: culturaId ?? this.culturaId,
      pontos: pontos ?? this.pontos,
      area: area ?? this.area,
      perimetro: perimetro ?? this.perimetro,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      corCultura: corCultura ?? this.corCultura,
    );
  }
}

// Wrapper para simular a estrutura PoligonoModel
class PoligonoWrapper {
  final List<LatLng> pontos;
  
  PoligonoWrapper({required this.pontos});
}

class TalhaoProvider with ChangeNotifier {
  List<TalhaoSafraModel> _talhoes = [];
  String? _errorMessage;
  TalhaoRepository? _talhaoRepository;
  TalhaoRepositoryV2? _talhaoRepositoryV2;
  TalhaoModuleService? _talhaoModuleService;
  DatabaseService? _databaseService;
  
  /// Obtém a instância do TalhaoRepository de forma lazy
  TalhaoRepository get talhaoRepository {
    _talhaoRepository ??= TalhaoRepository();
    return _talhaoRepository!;
  }
  
  /// Obtém a instância do TalhaoRepositoryV2 de forma lazy
  TalhaoRepositoryV2 get talhaoRepositoryV2 {
    _talhaoRepositoryV2 ??= TalhaoRepositoryV2();
    return _talhaoRepositoryV2!;
  }
  
  /// Obtém a instância do TalhaoModuleService de forma lazy
  TalhaoModuleService get talhaoModuleService {
    _talhaoModuleService ??= TalhaoModuleService();
    return _talhaoModuleService!;
  }
  
  /// Obtém a instância do DatabaseService de forma lazy
  DatabaseService get databaseService {
    _databaseService ??= DatabaseService();
    return _databaseService!;
  }

  /// Carrega talhões do banco de dados usando o serviço unificado
  Future<List<TalhaoSafraModel>> carregarTalhoes() async {
    try {
      print('🔄 TalhaoProvider: Iniciando carregamento de talhões via TalhaoUnifiedService...');
      _errorMessage = null;
      notifyListeners();
      
      List<TalhaoSafraModel> talhoesCarregados = [];
      
      // Usar o TalhaoUnifiedService para carregar talhões
      try {
        final TalhaoUnifiedService _talhaoUnifiedService = TalhaoUnifiedService();
        final talhoesUnificados = await _talhaoUnifiedService.carregarTalhoesParaModulo(
          nomeModulo: 'TALHAO_PROVIDER',
        );
        
        print('📊 TalhaoProvider: ${talhoesUnificados.length} talhões encontrados via TalhaoUnifiedService');
        
        if (talhoesUnificados.isNotEmpty) {
          for (final talhao in talhoesUnificados) {
            try {
              List<LatLng> pontos = [];
              
              if (talhao.poligonos.isNotEmpty) {
                final poligono = talhao.poligonos.first;
                if (poligono.pontos.isNotEmpty) {
                  pontos = poligono.pontos.map((p) => LatLng(p.latitude, p.longitude)).toList();
                  print('📊 TalhaoProvider: Talhão ${talhao.name} tem ${pontos.length} pontos');
                }
              }
              
              final talhaoSafra = TalhaoSafraModel(
                id: talhao.id,
                nome: talhao.name,
                culturaId: talhao.culturaId ?? '',
                pontos: pontos,
                area: talhao.area,
                perimetro: 0.0, // Calcular se necessário
                dataCriacao: talhao.dataCriacao,
                corCultura: talhao.cor,
              );
              talhoesCarregados.add(talhaoSafra);
            } catch (e) {
              print('❌ Erro ao converter talhão: $e');
            }
          }
        }
      } catch (e) {
        print('❌ Erro ao carregar via TalhaoUnifiedService: $e');
        
        // Fallback para o método anterior se o serviço unificado falhar
        try {
          final talhoesV2 = await talhaoRepositoryV2.listarTodos();
          print('📊 TalhaoProvider: Fallback - ${talhoesV2.length} talhões encontrados no V2');
          
          if (talhoesV2.isNotEmpty) {
            for (var talhao in talhoesV2) {
              try {
                List<LatLng> pontos = [];
                
                if (talhao.poligonos.isNotEmpty) {
                  final poligono = talhao.poligonos.first;
                  if (poligono.pontos.isNotEmpty) {
                    pontos = poligono.pontos.map((p) => LatLng(p.latitude, p.longitude)).toList();
                  }
                }
                
                final talhaoSafra = TalhaoSafraModel(
                  id: talhao.id,
                  nome: talhao.name,
                  culturaId: talhao.culturaId ?? '',
                  pontos: pontos,
                  area: talhao.area,
                  perimetro: 0.0,
                  dataCriacao: talhao.dataCriacao,
                  corCultura: talhao.cor,
                );
                talhoesCarregados.add(talhaoSafra);
              } catch (e) {
                print('❌ Erro ao converter talhão V2 (fallback): $e');
              }
            }
          }
        } catch (e) {
          print('❌ Erro no fallback V2: $e');
        }
      }
      
      // Atualizar a lista de talhões
      _talhoes = talhoesCarregados;
      
      print('✅ TalhaoProvider: ${_talhoes.length} talhões carregados com sucesso via TalhaoUnifiedService');
      for (var talhao in _talhoes) {
        print('  - ${talhao.nome} (ID: ${talhao.id})');
      }
      
      notifyListeners();
      return _talhoes;
    } catch (e) {
      _errorMessage = 'Erro ao carregar talhões: $e';
      print('❌ $_errorMessage');
      notifyListeners();
      return [];
    }
  }

  /// Recarrega talhões do banco de dados
  Future<void> recarregarTalhoes() async {
    await carregarTalhoes();
  }

  /// Obtém a lista de talhões
  List<TalhaoSafraModel> get talhoes => _talhoes;

  /// Obtém a mensagem de erro
  String? get errorMessage => _errorMessage;

  /// Limpa a mensagem de erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtém um talhão por ID
  TalhaoSafraModel? getTalhaoPorId(String id) {
    try {
      return _talhoes.firstWhere((talhao) => talhao.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Filtra talhões por nome
  List<TalhaoSafraModel> filtrarTalhoesPorNome(String nome) {
    if (nome.isEmpty) return _talhoes;
    
    return _talhoes.where((talhao) => 
      talhao.nome.toLowerCase().contains(nome.toLowerCase())
    ).toList();
  }

  /// Filtra talhões por cultura
  List<TalhaoSafraModel> filtrarTalhoesPorCultura(String culturaId) {
    if (culturaId.isEmpty) return _talhoes;
    
    return _talhoes.where((talhao) => 
      talhao.culturaId == culturaId
    ).toList();
  }

  /// Obtém estatísticas dos talhões
  Map<String, dynamic> getEstatisticasTalhoes() {
    if (_talhoes.isEmpty) {
      return {
        'total': 0,
        'areaTotal': 0.0,
        'culturas': <String, int>{},
      };
    }
    
    final culturas = <String, int>{};
    double areaTotal = 0.0;
    
    for (final talhao in _talhoes) {
      // Contar culturas
      culturas[talhao.culturaId] = (culturas[talhao.culturaId] ?? 0) + 1;
      
      // Calcular área
      areaTotal += talhao.area;
    }
    
    return {
      'total': _talhoes.length,
      'areaTotal': areaTotal,
      'culturas': culturas,
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}
