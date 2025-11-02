import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';
import '../utils/precise_geo_calculator.dart';

import '../models/talhao_model.dart';
import '../utils/model_adapters.dart';
import '../models/safra_model.dart' as safra;
import '../models/poligono_model.dart' as poligono;
import '../utils/mapbox_to_maptiler_adapter.dart' as mapbox;
import 'safra_repository.dart';
import 'talhao_repository_v2.dart';
import '../database/app_database.dart';
// import '../models/talhao_poligono_model.dart'; // Arquivo não existe
import '../models/talhoes/talhao_safra_model.dart' as talhaoSafra;

/// Repositório para gerenciar os talhões no banco de dados local
class TalhaoRepository extends ChangeNotifier {
  static const String _tableName = 'talhoes';
  static const String _tablePoligonos = 'talhao_poligonos';
  static const String _tableSafras = 'talhao_safras';
  static const String _dbName = 'fortsmartagro.db';
  static const int _dbVersion = 2;

  final AppDatabase _appDatabase = AppDatabase();
  final TalhaoRepositoryV2 _repositoryV2 = TalhaoRepositoryV2();

  
  List<TalhaoModel> _talhoes = [];
  bool _isLoading = false;
  SafraRepository? _safraRepository;
  
  /// Obtém a instância do SafraRepository de forma lazy
  SafraRepository get safraRepository {
    _safraRepository ??= SafraRepository();
    return _safraRepository!;
  }
  
  // Repositório V2 para o novo modelo TalhaoModel
  // final TalhaoRepositoryV2 _repositoryV2 = TalhaoRepositoryV2(); // This line is removed as per the new_code
  
  /// Lista de talhões carregados
  List<TalhaoModel> get talhoes => _talhoes;
  
  /// Indica se está carregando dados
  bool get isLoading => _isLoading;
  
  /// Define o estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Obtém a instância do banco de dados centralizada
  Future<Database> _getDatabase() async {
    try {
      return await _appDatabase.database.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout ao acessar banco de dados'),
      );
    } catch (e) {
      Logger.error('❌ Erro ao acessar banco de dados: $e');
      rethrow;
    }
  }
  
  /// Verifica se as tabelas existem (já criadas pelo AppDatabase)
  Future<void> _ensureTablesExist(Database db) async {
    try {
      Logger.info('🔍 Verificando tabelas de talhões...');
      
      // As tabelas já são criadas pelo AppDatabase, apenas verificamos se existem
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$_tableName'")
          .timeout(const Duration(seconds: 5));
      
      if (tables.isEmpty) {
        Logger.warning('⚠️ Tabela $_tableName não encontrada - será criada pelo AppDatabase');
      } else {
        Logger.info('✅ Tabela $_tableName encontrada');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar tabelas de talhões: $e');
      // Não rethrow para não quebrar o fluxo
    }
  }
  
  /// Carrega a lista de talhões do banco de dados
  Future<List<TalhaoModel>> loadTalhoes() async {
    _setLoading(true);
    
    try {
      // Adicionar timeout para evitar travamento
      final db = await _getDatabase().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          Logger.warning('⚠️ Timeout ao obter banco de dados');
          throw TimeoutException('Timeout ao obter banco de dados', const Duration(seconds: 3));
        },
      );
      
      await _ensureTablesExist(db);
      
      final List<Map<String, dynamic>> maps = await db.query(_tableName).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          Logger.warning('⚠️ Timeout ao consultar talhões');
          throw TimeoutException('Timeout ao consultar talhões', const Duration(seconds: 2));
        },
      );
      
      _talhoes = _loadTalhoesFormatted(maps);
      notifyListeners();
      
      Logger.info('✅ ${_talhoes.length} talhões carregados com sucesso');
      return _talhoes;
    } catch (e) {
      Logger.error('❌ Erro ao carregar talhões: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// Obtém todos os talhões (alias para loadTalhoes para compatibilidade)
  Future<List<TalhaoModel>> getTalhoes() async {
    try {
      Logger.info('🔄 Carregando talhões do banco de dados SQLite...');
      
      // Carregar diretamente do banco de dados SQLite com timeout
      final talhoes = await loadTalhoes().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          Logger.warning('⚠️ Timeout ao carregar talhões, retornando lista vazia');
          return <TalhaoModel>[];
        },
      );
      Logger.info('📊 ${talhoes.length} talhões encontrados no banco SQLite');
      
      if (talhoes.isNotEmpty) {
        _talhoes = talhoes;
        return _talhoes;
      }
      
      // Se não houver dados no SQLite, tentar do repositório V2 como fallback
      Logger.info('🔄 Tentando carregar do repositório V2 como fallback...');
      final talhoesV2 = await _repositoryV2.listarTodos();
      if (talhoesV2.isNotEmpty) {
        Logger.info('📊 ${talhoesV2.length} talhões encontrados no V2');
        // Se o V2 retornar modelos legados, converta para TalhaoModel unificado
        final talhoesConvertidos = talhoesV2.map((t) => 
          ModelAdapters.convertLegacyToUnified(t.toMap())
        ).toList();
        _talhoes = talhoesConvertidos;
        return _talhoes;
      }
      
      Logger.warning('⚠️ Nenhum talhão encontrado em nenhuma fonte');
      return [];
    } catch (e) {
      Logger.error('❌ Erro ao obter talhões: $e');
      return await loadTalhoes();
    }
  }
  
  /// Decodifica os polígonos do formato JSON para uma lista de PoligonoModel
  List<poligono.PoligonoModel> _decodePoligonos(String poligonosJson) {
    try {
      final List<dynamic> poligonosData = jsonDecode(poligonosJson);
      List<poligono.PoligonoModel> poligonos = [];
      
      // Verifica se o formato é o novo (lista de polígonos com pontos) ou o antigo (lista direta de pontos)
      if (poligonosData.isNotEmpty && poligonosData.first is List) {
        // Novo formato: lista de polígonos, cada um com uma lista de pontos
        int index = 0;
        for (var pontosData in poligonosData) {
          List<LatLng> pontos = [];
          for (var ponto in pontosData) {
            pontos.add(LatLng(
              ponto['latitude'] ?? ponto['lat'] ?? 0.0,
              ponto['longitude'] ?? ponto['lng'] ?? 0.0,
            ));
          }
          
          if (pontos.isNotEmpty) {
            // Para polígonos importados, não recalcular área automaticamente
            // A área será preservada do arquivo original ou calculada no nível do talhão
            double area = 0.0; // Será definida no nível do talhão
            double perimetro = 0.0;
            
            try {
              if (pontos.length >= 3) {
                // Calcular apenas o perímetro, a área será preservada do arquivo original
                perimetro = PreciseGeoCalculator.calculatePolygonPerimeter(pontos);
              }
            } catch (e) {
              debugPrint('Erro ao calcular perímetro do polígono: $e');
              perimetro = 0.0;
            }
            
            poligonos.add(poligono.PoligonoModel(
              id: const Uuid().v4(),
              pontos: pontos,
              dataCriacao: DateTime.now(),
              dataAtualizacao: DateTime.now(),
              ativo: true,
              area: area, // Área será definida no nível do talhão
              perimetro: perimetro,
              talhaoId: '',
            ));
          }
          index++;
        }
      } else {
        // Formato antigo: lista direta de pontos (um único polígono)
        List<LatLng> pontos = poligonosData.map<LatLng>((p) {
          return LatLng(
            p['latitude'] ?? p['lat'] ?? 0.0,
            p['longitude'] ?? p['lng'] ?? 0.0,
          );
        }).toList();
        
        if (pontos.isNotEmpty) {
          // Para polígonos importados, não recalcular área automaticamente
          // A área será preservada do arquivo original ou calculada no nível do talhão
          double area = 0.0; // Será definida no nível do talhão
          double perimetro = 0.0;
          
          try {
            if (pontos.length >= 3) {
              // Calcular apenas o perímetro, a área será preservada do arquivo original
              perimetro = PreciseGeoCalculator.calculatePolygonPerimeter(pontos);
            }
          } catch (e) {
            debugPrint('Erro ao calcular perímetro do polígono: $e');
            perimetro = 0.0;
          }
          
          poligonos.add(poligono.PoligonoModel(
            id: const Uuid().v4(),
            pontos: pontos,
            dataCriacao: DateTime.now(),
            dataAtualizacao: DateTime.now(),
            ativo: true,
            area: area, // Área será definida no nível do talhão
            perimetro: perimetro,
            talhaoId: '',
          ));
        }
      }
      
      return poligonos;
    } catch (e) {
      debugPrint('Erro ao decodificar polígonos: $e');
      return [];
    }
  }
  
  /// Carrega e formata os talhões a partir dos dados do banco
  List<TalhaoModel> _loadTalhoesFormatted(List<Map<String, dynamic>> maps) {
    List<TalhaoModel> talhoes = [];
    for (var map in maps) {
      Logger.info('🔄 Processando talhão: ${map['name']} (ID: ${map['id']})');
      
      // Decodificar os polígonos do formato JSON
      List<poligono.PoligonoModel> poligonos = [];
      try {
        if (map['poligonos'] != null) {
          Logger.info('📊 Polígonos JSON: ${map['poligonos']}');
          final poligonosData = jsonDecode(map['poligonos']);
          Logger.info('📊 Polígonos decodificados: $poligonosData');
          
          if (poligonosData is List) {
            for (var poligonoData in poligonosData) {
              if (poligonoData is Map) {
                // Verificar se tem pontos no formato correto
                if (poligonoData['pontos'] != null) {
                  final pontosString = poligonoData['pontos'] as String;
                  final pontosList = pontosString.split(';').where((p) => p.isNotEmpty).map((p) {
                    final coords = p.split(',');
                    if (coords.length == 2) {
                      return LatLng(
                        double.parse(coords[0]),
                        double.parse(coords[1]),
                      );
                    }
                    return null;
                  }).where((p) => p != null).cast<LatLng>().toList();
                  
                  if (pontosList.length >= 3) {
                    poligonos.add(poligono.PoligonoModel.criar(
                      pontos: pontosList,
                      talhaoId: map['id'],
                    ));
                    Logger.info('✅ Polígono criado com ${pontosList.length} pontos');
                  } else {
                    Logger.warning('⚠️ Polígono com menos de 3 pontos válidos: ${pontosList.length}');
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        Logger.error('❌ Erro ao decodificar polígonos: $e');
      }
      
      // Decodificar safras do formato JSON
      List<safra.SafraModel> safras = [];
      try {
        if (map['safras'] != null) {
          Logger.info('📊 Safras JSON: ${map['safras']}');
          final safrasData = jsonDecode(map['safras']);
          Logger.info('📊 Safras decodificadas: $safrasData');
          
          if (safrasData is List) {
            for (var s in safrasData) {
              if (s is Map) {
                // Converter cor de int para string hex
                String culturaCor = '#000000';
                if (s['culturaCor'] != null) {
                  if (s['culturaCor'] is int) {
                    culturaCor = '#${s['culturaCor'].toRadixString(16).substring(2)}';
                  } else if (s['culturaCor'] is String) {
                    culturaCor = s['culturaCor'];
                  }
                }
                
                safras.add(safra.SafraModel(
                  id: s['id'] ?? const Uuid().v4(),
                  talhaoId: map['id']?.toString() ?? const Uuid().v4(),
                  safra: s['idSafra'] ?? '2024/2025',
                  culturaId: s['idCultura'] ?? '',
                  culturaNome: s['culturaNome'] ?? '',
                  culturaCor: culturaCor,
                  dataCriacao: s['dataCadastro'] != null ? DateTime.parse(s['dataCadastro']) : DateTime.now(),
                  dataAtualizacao: s['dataAtualizacao'] != null ? DateTime.parse(s['dataAtualizacao']) : DateTime.now(),
                  sincronizado: s['sincronizado'] == 1,
                  periodo: s['idSafra'] ?? '2024/2025',
                  dataInicio: s['dataCadastro'] != null ? DateTime.parse(s['dataCadastro']) : DateTime.now(),
                  dataFim: s['dataAtualizacao'] != null ? DateTime.parse(s['dataAtualizacao']) : DateTime.now().add(const Duration(days: 365)),
                  ativa: true,
                  nome: s['culturaNome'] ?? 'Safra',
                ));
                Logger.info('✅ Safra criada: ${s['culturaNome']}');
              }
            }
          }
        }
      } catch (e) {
        Logger.error('❌ Erro ao decodificar safras: $e');
      }
      
      // Preservar área original dos talhões importados ou calcular apenas para talhões criados manualmente
      double area = 0.0;
      
      // Verificar se é um talhão importado (baseado no nome ou outras características)
      bool isImportedTalhao = (map['name']?.toString().toLowerCase().contains('importado') == true) ||
                             (map['name']?.toString().toLowerCase().contains('import') == true) ||
                             (map['observacoes']?.toString().toLowerCase().contains('importado') == true);
      
      if (isImportedTalhao) {
        // Para talhões importados, tentar preservar a área original
        Logger.info('📊 Talhão importado detectado: ${map['name']} - preservando área original');
        
        // Primeiro, tentar usar área da safra se disponível
        if (safras.isNotEmpty) {
          // area = safras.first.area!.toDouble(); // Comentado temporariamente
          Logger.info('  📊 Usando área da safra: ${area.toStringAsFixed(4)} ha');
        }
        // Se não tem área na safra, tentar usar área armazenada no banco (se existir)
        else if (map['area'] != null && map['area'] > 0) {
          area = map['area'].toDouble();
          Logger.info('  📊 Usando área armazenada no banco: ${area.toStringAsFixed(4)} ha');
        }
        // Se não tem área armazenada, calcular apenas como último recurso
        else {
          try {
            if (poligonos.isNotEmpty && poligonos.first.pontos.length >= 3) {
              area = PreciseGeoCalculator.calculatePolygonArea(poligonos.first.pontos);
              Logger.info('  📊 Calculando área como último recurso: ${area.toStringAsFixed(4)} ha');
            }
          } catch (e) {
            debugPrint('Erro ao calcular área de talhão importado: $e');
            area = 0.0;
          }
        }
      } else {
        // Para talhões criados manualmente, calcular área normalmente
        Logger.info('📊 Talhão criado manualmente: ${map['name']} - calculando área');
        try {
          if (poligonos.isNotEmpty && poligonos.first.pontos.length >= 3) {
            area = PreciseGeoCalculator.calculatePolygonArea(poligonos.first.pontos);
            Logger.info('  📊 Área calculada: ${area.toStringAsFixed(4)} ha');
          }
        } catch (e) {
          debugPrint('Erro ao calcular área: $e');
          area = 0.0;
        }
      }
      
      final talhao = TalhaoModel(
        id: map['id']?.toString() ?? const Uuid().v4(),
        name: map['name'] ?? 'Sem nome',
        poligonos: poligonos,
        area: area,
        fazendaId: map['idFazenda'],
        dataCriacao: map['dataCriacao'] != null ? DateTime.parse(map['dataCriacao']) : DateTime.now(),
        dataAtualizacao: map['dataAtualizacao'] != null ? DateTime.parse(map['dataAtualizacao']) : DateTime.now(),
        sincronizado: map['sincronizado'] == 1,
        observacoes: null,
        cropId: null,
        safraId: null,
        crop: null,
        safras: safras,
        // Adicionar metadados com informações precisas (calculadas de forma segura)
        metadados: {
          'areaCalculada': area,
          'perimetroCalculado': poligonos.isNotEmpty ? 
            PreciseGeoCalculator.calculatePolygonPerimeter(poligonos.first.pontos) : 0.0,
          'centroCalculado': poligonos.isNotEmpty ? 
            PreciseGeoCalculator.calculatePolygonCenter(poligonos.first.pontos) : null,
          'boundsCalculado': poligonos.isNotEmpty ? 
            PreciseGeoCalculator.calculatePolygonBounds(poligonos.first.pontos) : null,
          'valido': poligonos.isNotEmpty ? 
            PreciseGeoCalculator.isValidPolygon(poligonos.first.pontos) : false,
        },
      );
      talhoes.add(talhao);
    }
    return talhoes;
  }
  
  /// Calcula a área total dos polígonos
  double _calculateAreaFromPolygons(List<poligono.PoligonoModel> poligonos) {
    double totalArea = 0.0;
    for (final poligono in poligonos) {
      totalArea += PreciseGeoCalculator.calculatePolygonArea(poligono.pontos);
    }
    return totalArea;
  }
  
  /// Calcula o perímetro total dos polígonos
  double _calculatePerimeterFromPolygons(List<poligono.PoligonoModel> poligonos) {
    double totalPerimeter = 0.0;
    for (final poligono in poligonos) {
      totalPerimeter += PreciseGeoCalculator.calculatePolygonPerimeter(poligono.pontos);
    }
    return totalPerimeter;
  }
  
  /// Carrega a lista de talhões (já no modelo unificado) usando o repositório V2
  Future<List<TalhaoModel>> loadTalhoesNew() async {
    try {
      final talhoesV2 = await _repositoryV2.listarTodos();
      return talhoesV2.map((t) => ModelAdapters.convertLegacyToUnified(t.toMap())).toList();
    } catch (e) {
      debugPrint('Erro ao carregar talhões no novo formato: $e');
      return [];
    }
  }
  
  /// Converte um talhão do formato V2 para o formato legado
  TalhaoModel convertTalhaoV2ToLegacy(dynamic talhaoV2) {
    try {
      // Extrair pontos do primeiro polígono (formato legado só suporta um polígono principal)
      final List<LatLng> points = [];
      if (talhaoV2.poligonos != null && talhaoV2.poligonos.isNotEmpty) {
        points.addAll(talhaoV2.poligonos[0]);
      } else if (talhaoV2.points != null && talhaoV2.points.isNotEmpty) {
        points.addAll(talhaoV2.points);
      }
      
      int? culturaId;
      int? safraId;
      safra.SafraModel? safraAtual;
      
      if (talhaoV2.safraAtual != null) {
        culturaId = int.tryParse(talhaoV2.safraAtual!.culturaId?.toString() ?? '');
        safraId = int.tryParse(talhaoV2.safraAtual!.id?.toString() ?? '');
        safraAtual = talhaoV2.safraAtual;
      } else if (talhaoV2.cropId != null) {
        culturaId = talhaoV2.cropId;
      }
      
      // Preparar lista de safras para o modelo legado
      final List<safra.SafraModel> safras = talhaoV2.safras != null 
          ? List<safra.SafraModel>.from(talhaoV2.safras) 
          : <safra.SafraModel>[];
      
      // Converter o ID para int (garantindo que não seja nulo)
      final int? talhaoId = talhaoV2.id != null ? int.tryParse(talhaoV2.id.toString()) : null;
      
      // Criar lista de PoligonoModel para o modelo legado
      final List<poligono.PoligonoModel> poligonosLegacy = [];
      
      // Converter cada polígono do modelo V2 para PoligonoModel
      if (talhaoV2.poligonos != null) {
        for (final poligono in talhaoV2.poligonos) {
          final poligonoModel = poligono.PoligonoModel.criar(
            pontos: poligono,
            talhaoId: talhaoId?.toString() ?? const Uuid().v4(),
          );
          poligonosLegacy.add(poligonoModel);
        }
      }
      
      // Se não houver polígonos, criar um com os pontos principais
      if (poligonosLegacy.isEmpty && points.isNotEmpty) {
        final poligonoModel = poligono.PoligonoModel.criar(
          pontos: points,
          talhaoId: talhaoId?.toString() ?? const Uuid().v4(),
        );
        poligonosLegacy.add(poligonoModel);
      }
      
      // Usar os campos de data do modelo V2 ou criar novos se não existirem
      final DateTime dataCriacao = talhaoV2.createdAt ?? DateTime.now();
      final DateTime dataAtualizacao = talhaoV2.updatedAt ?? DateTime.now();
      
      // Criar o talhão no formato legado com os parâmetros corretos
      return TalhaoModel(
        id: talhaoId?.toString() ?? '',
        name: talhaoV2.name ?? talhaoV2.nome ?? 'Sem nome',
        poligonos: talhaoV2.poligonos ?? [],
        area: talhaoV2.area ?? 0.0,
        fazendaId: talhaoV2.fazendaId,
        dataCriacao: dataCriacao,
        dataAtualizacao: dataAtualizacao,
        sincronizado: talhaoV2.syncStatus == 1,
        cropId: culturaId,
        safraId: safraId,
        crop: talhaoV2.crop,
        safras: safras,
        observacoes: talhaoV2.observacoes,
      );
    } catch (e) {
      debugPrint('Erro ao converter talhão V2 para legado: $e');
      
      // Retornar um talhão vazio em caso de erro
      final now = DateTime.now();
      
      return TalhaoModel(
        id: const Uuid().v4(),
        name: 'Erro de conversão',
        poligonos: [],
        area: 0.0,
        fazendaId: null,
        dataCriacao: now,
        dataAtualizacao: now,
        sincronizado: false,
        observacoes: null,
        cropId: null,
        safraId: null,
        crop: null,
        safras: [],
      );
    }
  }
  
  /// Adiciona um novo talhão ao banco de dados
  Future<TalhaoModel> addTalhao(TalhaoModel talhao) async {
    try {
      Logger.info('🔄 Adicionando talhão: ${talhao.name}');
      
      final db = await _getDatabase().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout ao acessar banco de dados'),
      );
      
      await _ensureTablesExist(db);
      
      // Gerar um ID único para o talhão se não tiver
      final id = talhao.id.toString();
      
      // Serializar polígonos para o formato JSON esperado pelo banco
      final poligonosJson = jsonEncode(talhao.poligonos.map((poligono) => 
        poligono.pontos.map((ponto) => {
          'latitude': ponto.latitude,
          'longitude': ponto.longitude,
        }).toList()
      ).toList());
      
      // Preparar os dados para inserção - compatível com a estrutura do AppDatabase
      final Map<String, dynamic> data = {
        'id': id,
        'name': talhao.name ?? 'Sem nome',
        'idFazenda': talhao.fazendaId ?? '',
        'poligonos': poligonosJson,
        'safras': jsonEncode(talhao.safras.map((safra) => {
          'id': safra.id,
          'culturaId': safra.culturaId,
          'culturaNome': safra.culturaNome,
          'culturaCor': safra.culturaCor,
          'dataCriacao': safra.dataCriacao.toIso8601String(),
          'dataAtualizacao': safra.dataAtualizacao.toIso8601String(),
          'sincronizado': safra.sincronizado,
        }).toList()),
        'dataCriacao': talhao.dataCriacao.toIso8601String(),
        'dataAtualizacao': talhao.dataAtualizacao.toIso8601String(),
        'sincronizado': talhao.sincronizado ? 1 : 0,
      };
      
      Logger.info('💾 Inserindo talhão no banco de dados...');
      
      // Inserir no banco com timeout e tratamento de erro específico
      try {
        await db.insert(_tableName, data, conflictAlgorithm: ConflictAlgorithm.replace)
            .timeout(const Duration(seconds: 15));
        Logger.info('✅ Talhão inserido com sucesso no banco');
      } catch (dbError) {
        Logger.error('❌ Erro ao inserir no banco: $dbError');
        
        // Tentar inserir sem campos opcionais
        final simplifiedData = {
          'id': id,
          'name': talhao.name ?? 'Sem nome',
          'idFazenda': talhao.fazendaId ?? '',
          'poligonos': poligonosJson,
          'safras': '[]',
          'dataCriacao': talhao.dataCriacao.toIso8601String(),
          'dataAtualizacao': talhao.dataAtualizacao.toIso8601String(),
          'sincronizado': 0,
        };
        
        await db.insert(_tableName, simplifiedData, conflictAlgorithm: ConflictAlgorithm.replace)
            .timeout(const Duration(seconds: 15));
        Logger.info('✅ Talhão inserido com dados simplificados');
      }
      
      // Atualizar o talhão com o ID gerado (sem recálculos desnecessários)
      final newTalhao = TalhaoModel(
        id: id,
        name: talhao.name ?? 'Sem nome',
        poligonos: talhao.poligonos,
        area: talhao.area, // Usar área já calculada
        fazendaId: talhao.fazendaId,
        dataCriacao: talhao.dataCriacao,
        dataAtualizacao: talhao.dataAtualizacao,
        sincronizado: talhao.sincronizado,
        cropId: talhao.cropId,
        safraId: talhao.safraId,
        crop: talhao.crop,
        safras: talhao.safras,
        observacoes: talhao.observacoes,
        metadados: talhao.metadados, // Usar metadados já calculados
      );
      
      // Atualizar a lista em memória
      _talhoes.add(newTalhao);
      notifyListeners();
      
      Logger.info('✅ Talhão adicionado com sucesso: ${newTalhao.name}');
      return newTalhao;
    } catch (e) {
      Logger.error('❌ Erro ao adicionar talhão: $e');
      rethrow;
    }
  }
  
  /// Atualiza um talhão existente no banco de dados
  Future<TalhaoModel> updateTalhao(TalhaoModel talhao) async {
    try {
      final db = await _getDatabase();
      await _ensureTablesExist(db);
      
      // Serializar polígonos para o formato JSON esperado pelo banco
      final poligonosJson = jsonEncode(talhao.poligonos.map((poligono) => 
        poligono.pontos.map((ponto) => {
          'latitude': ponto.latitude,
          'longitude': ponto.longitude,
        }).toList()
      ).toList());
      
      // Preparar os dados para atualização - compatível com a estrutura do AppDatabase
      final Map<String, dynamic> data = {
        'name': talhao.name ?? 'Sem nome',
        'idFazenda': talhao.fazendaId ?? '',
        'poligonos': poligonosJson,
        'safras': jsonEncode(talhao.safras.map((safra) => {
          'id': safra.id,
          'culturaId': safra.culturaId,
          'culturaNome': safra.culturaNome,
          'culturaCor': safra.culturaCor,
          'dataCriacao': safra.dataCriacao.toIso8601String(),
          'dataAtualizacao': safra.dataAtualizacao.toIso8601String(),
          'sincronizado': safra.sincronizado,
        }).toList()),
        'dataAtualizacao': talhao.dataAtualizacao.toIso8601String(),
        'sincronizado': 0, // Marca como não sincronizado após atualização
      };
      
      // Atualizar no banco
      final result = await db.update(
        _tableName,
        data,
        where: 'id = ?',
        whereArgs: [talhao.id.toString()],
      );
      
      if (result == 0) {
        throw Exception('Talhão não encontrado para atualização');
      }
      
      // Atualizar o talhão com a data de atualização e status de sincronização
      final updatedTalhao = talhao.copyWith(
        dataAtualizacao: DateTime.now(),
        sincronizado: false, // Marca como não sincronizado após atualização
      );
      
      // Atualizar a lista em memória
      final index = _talhoes.indexWhere((t) => t.id == talhao.id);
      if (index != -1) {
        _talhoes[index] = updatedTalhao;
      }
      notifyListeners();
      
      return updatedTalhao;
    } catch (e) {
      debugPrint('Erro ao atualizar talhão: $e');
      rethrow;
    }
  }
  
  /// Exclui um talhão pelo ID
  Future<bool> deleteTalhao(int id) async {
    _setLoading(true);
    
    try {
      final db = await _getDatabase();
      await _ensureTablesExist(db);
      
      final result = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id.toString()],
      );
      
      // Remover da lista em memória
      _talhoes.removeWhere((talhao) => talhao.id == id);
      notifyListeners();
      
      return result > 0;
    } catch (e) {
      debugPrint('Erro ao excluir talhão: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Duplica um talhão existente
  Future<TalhaoModel> duplicateTalhao(int id) async {
    final talhao = await getTalhaoById(id);
    if (talhao == null) {
      throw Exception('Talhão não encontrado');
    }
    
    // Criar uma cópia do talhão com um novo ID
    final newTalhao = TalhaoModel(
      id: const Uuid().v4(),
      name: '${talhao.name} (Cópia)',
      poligonos: talhao.poligonos.map((p) => p.copyWith(
        id: const Uuid().v4(),
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        talhaoId: '',
      )).toList(),
      area: talhao.area,
      fazendaId: talhao.fazendaId,
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      sincronizado: false,
      observacoes: talhao.observacoes,
      cropId: talhao.cropId,
      safraId: talhao.safraId,
      crop: talhao.crop,
      safras: talhao.safras,
    );
    
    return await addTalhao(newTalhao);
  }
  
  /// Busca um talhão pelo ID
  Future<TalhaoModel?> getTalhaoById(int id) async {
    try {
      final db = await _getDatabase();
      await _ensureTablesExist(db);
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id.toString()],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      // Decodificar os polígonos do formato JSON
      final poligonos = _decodePoligonos(maps[0]['poligonos'] ?? '[]');
      
      // Criar o talhão com o modelo unificado
      return TalhaoModel(
        id: maps[0]['id'],
        name: maps[0]['nome'],
        poligonos: poligonos,
        area: maps[0]['area'],
        fazendaId: maps[0]['farm_id'],
        dataCriacao: DateTime.parse(maps[0]['criado_em']),
        dataAtualizacao: DateTime.parse(maps[0]['atualizado_em']),
        sincronizado: maps[0]['sincronizado'] == 1,
        observacoes: maps[0]['observacoes'],
        cropId: maps[0]['cultura_id'] != null ? int.tryParse(maps[0]['cultura_id'].toString()) : null,
        safraId: maps[0]['safra_id'] != null ? int.tryParse(maps[0]['safra_id'].toString()) : null,
        crop: maps[0]['cultura'],
        safras: [],
      );
    } catch (e) {
      debugPrint('Erro ao buscar talhão: $e');
      return null;
    }
  }
  
  /// Marca um talhão como sincronizado
  Future<void> markTalhaoAsSynced(int id) async {
    try {
      final db = await _getDatabase();
      await _ensureTablesExist(db);
      
      await db.update(
        _tableName,
        {'sincronizado': 1},
        where: 'id = ?',
        whereArgs: [id.toString()],
      );
      
      // Atualizar a lista em memória
      final index = _talhoes.indexWhere((t) => t.id == id);
      if (index != -1) {
        // Como não temos copyWith no modelo unificado, criamos um novo objeto
        final talhao = _talhoes[index];
        _talhoes[index] = talhao.copyWith(
          sincronizado: true,
          dataAtualizacao: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao marcar talhão como sincronizado: $e');
    }
  }
  
  /// Importa talhões de um arquivo JSON
  Future<int> importTalhoes(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado');
      }
      
      final String jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      int importedCount = 0;
      
      for (var json in jsonList) {
        try {
          // Converter os pontos do formato JSON para PoligonoModel
          List<poligono.PoligonoModel> poligonos;
          
          if (json.containsKey('points')) {
            poligonos = _decodePoligonos(jsonEncode(json['points']));
          } else if (json.containsKey('poligonos')) {
            poligonos = _decodePoligonos(jsonEncode(json['poligonos']));
          } else {
            throw Exception('Formato de talhão inválido: sem pontos ou polígonos');
          }
          
          final talhao = TalhaoModel(
            id: json['id'] ?? const Uuid().v4(),
            name: json['nome'] ?? json['name'] ?? 'Talhão Importado',
            poligonos: poligonos,
            area: json['area'] ?? 0.0,
            fazendaId: json['farm_id'] ?? json['fazendaId'],
            dataCriacao: json['criado_em'] != null ? DateTime.parse(json['criado_em']) : DateTime.now(),
            dataAtualizacao: json['atualizado_em'] != null ? DateTime.parse(json['atualizado_em']) : DateTime.now(),
            sincronizado: json['sincronizado'] == 1 || json['sincronizado'] == true,
            safras: [],
            observacoes: json['observacoes'],
          );
          
          await addTalhao(talhao);
          importedCount++;
        } catch (e) {
          debugPrint('Erro ao importar talhão individual: $e');
          // Continuar com o próximo talhão
        }
      }
      
      return importedCount;
    } catch (e) {
      debugPrint('Erro ao importar talhões: $e');
      throw Exception('Falha ao importar talhões: $e');
    }
  }
  
  /// Exporta todos os talhões para um arquivo JSON
  Future<String> exportTalhoes() async {
    try {
      final talhoes = await loadTalhoes();
      final List<Map<String, dynamic>> talhoesMap = talhoes.map((t) => t.toMap()).toList();
      
      final String jsonString = jsonEncode(talhoesMap);
      
      // Salvar o arquivo no diretório de documentos
      final directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/talhoes_export_${DateTime.now().millisecondsSinceEpoch}.json';
      
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return filePath;
    } catch (e) {
      debugPrint('Erro ao exportar talhões: $e');
      throw Exception('Falha ao exportar talhões: $e');
    }
  }
  
  /// Importa talhões de um arquivo KML
  Future<List<TalhaoModel>> importFromKml(String filePath, String culturaNome) async {
    _setLoading(true);
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado: $filePath');
      }
      
      final content = await file.readAsString();
      
      // Processamento simples de KML (em produção, usar uma biblioteca XML adequada)
      final RegExp coordsPattern = RegExp(r'<coordinates>(.*?)</coordinates>', multiLine: true, dotAll: true);
      final RegExp namePattern = RegExp(r'<name>(.*?)</name>', multiLine: true);
      
      final matches = coordsPattern.allMatches(content);
      final nameMatches = namePattern.allMatches(content);
      
      final List<TalhaoModel> talhoesImportados = [];
      int nameIndex = 0;
      
      for (final match in matches) {
        if (match.groupCount > 0) {
          final String coordsString = match.group(1)!.trim();
          final List<String> coordsArray = coordsString.split(' ');
          
          final List<LatLng> pontos = [];
          
          for (final coordPair in coordsArray) {
            if (coordPair.trim().isEmpty) continue;
            
            final List<String> parts = coordPair.trim().split(',');
            if (parts.length >= 2) {
              final double lng = double.tryParse(parts[0]) ?? 0;
              final double lat = double.tryParse(parts[1]) ?? 0;
              pontos.add(LatLng(lat, lng));
            }
          }
          
          if (pontos.length >= 3) {
            String nome = 'Talhão Importado';
            if (nameIndex < nameMatches.length && nameMatches.elementAt(nameIndex).groupCount > 0) {
              nome = nameMatches.elementAt(nameIndex).group(1) ?? nome;
              nameIndex++;
            }
            
            // Para talhões importados de KML, calcular área apenas uma vez
            final areaCalculada = PreciseGeoCalculator.calculatePolygonArea(pontos);
            final perimetroCalculado = PreciseGeoCalculator.calculatePolygonPerimeter(pontos);
            
            final talhao = TalhaoModel(
              id: const Uuid().v4(),
              name: nome,
              poligonos: [poligono.PoligonoModel(
                id: const Uuid().v4(),
                pontos: pontos,
                dataCriacao: DateTime.now(),
                dataAtualizacao: DateTime.now(),
                ativo: true,
                area: areaCalculada,
                perimetro: perimetroCalculado,
                talhaoId: '',
              )],
              area: areaCalculada, // Usar a mesma área calculada
              fazendaId: null,
              dataCriacao: DateTime.now(),
              dataAtualizacao: DateTime.now(),
              sincronizado: false,
              observacoes: 'Importado de KML',
              cropId: null,
              safraId: null,
              crop: null, // Não temos um objeto Crop completo, apenas o nome da cultura
              safras: [],
            );
            
            await addTalhao(talhao);
            talhoesImportados.add(talhao);
          }
        }
      }
      
      return talhoesImportados;
    } catch (e) {
      debugPrint('Erro ao importar KML: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// Calcula a área de um polígono em hectares com alta precisão
  double _calculatePolygonArea(List<LatLng> pontos) {
    return PreciseGeoCalculator.calculatePolygonArea(pontos);
  }
  
  /// Calcula o perímetro de um polígono em metros
  double _calculatePolygonPerimeter(List<LatLng> pontos) {
    return PreciseGeoCalculator.calculatePolygonPerimeter(pontos);
  }
  
  /// Valida e melhora a precisão dos cálculos de um talhão
  Map<String, dynamic> _validateAndImproveCalculations(TalhaoModel talhao) {
    final results = <String, dynamic>{};
    
    if (talhao.poligonos.isNotEmpty) {
      final poligono = talhao.poligonos.first;
      
      // Usar o novo método de estatísticas detalhadas
      final stats = PreciseGeoCalculator.calculatePolygonStats(poligono.pontos);
      
      results.addAll(stats);
      
      // Comparar com área existente se houver
      if (talhao.area > 0) {
        final diferenca = ((stats['area'] - talhao.area) / talhao.area * 100).abs();
        results['diferencaPercentual'] = diferenca;
        results['melhorou'] = diferenca > 1.0; // Considera melhoria se diferença > 1%
        
        // Log detalhado da melhoria
        if (diferenca > 1.0) {
          Logger.info('📊 Talhão ${talhao.name}: Melhoria de ${talhao.area.toStringAsFixed(2)} ha para ${stats['areaFormatted']} (${diferenca.toStringAsFixed(1)}% de diferença)');
          Logger.info('📏 Perímetro: ${stats['perimeterFormatted']} | Pontos: ${stats['pointCount']} → ${stats['simplifiedPointCount']} (${(stats['simplificationRatio'] * 100).toStringAsFixed(1)}%)');
        }
      }
    }
    
    return results;
  }
  
  /// Busca talhões por ID da fazenda
  Future<List<TalhaoModel>> getTalhoesByFarmId(String farmId) async {
    try {
      final db = await _getDatabase();
      await _ensureTablesExist(db);
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'farm_id = ?',
        whereArgs: [farmId],
      );
      
      return _loadTalhoesFormatted(maps);
    } catch (e) {
      debugPrint('Erro ao buscar talhões por fazenda: $e');
      return [];
    }
  }

  /// Obtém as safras de um talhão pelo ID
  Future<List<safra.SafraModel>> getSafrasByTalhaoId(String id) async {
    try {
      return await _repositoryV2.obterHistoricoSafras(id);
    } catch (e) {
      debugPrint('Erro ao obter safras por talhão: $e');
      return [];
    }
  }

  buscarTalhoesPorFazenda(String s) {}
  
  /// Obtém informações precisas de cálculo para um talhão
  Map<String, dynamic> getPreciseCalculations(String talhaoId) {
    try {
      final talhao = _talhoes.firstWhere((t) => t.id == talhaoId);
      return _validateAndImproveCalculations(talhao);
    } catch (e) {
      Logger.error('❌ Erro ao obter cálculos precisos para talhão $talhaoId: $e');
      return {};
    }
  }
  
  /// Atualiza todos os talhões com cálculos precisos
  Future<void> updateAllTalhoesWithPreciseCalculations() async {
    try {
      Logger.info('🔄 Atualizando cálculos precisos para todos os talhões...');
      
      for (int i = 0; i < _talhoes.length; i++) {
        final talhao = _talhoes[i];
        final calculos = _validateAndImproveCalculations(talhao);
        
        if (calculos['melhorou'] == true) {
          Logger.info('✅ Talhão ${talhao.name}: Área melhorada de ${talhao.area.toStringAsFixed(2)} ha para ${calculos['areaFormatada']}');
          
          // Atualizar o talhão com os novos cálculos
          final talhaoAtualizado = TalhaoModel(
            id: talhao.id,
            name: talhao.name,
            poligonos: talhao.poligonos,
            area: calculos['area'],
            fazendaId: talhao.fazendaId,
            dataCriacao: talhao.dataCriacao,
            dataAtualizacao: DateTime.now(),
            sincronizado: false, // Marcar como não sincronizado para atualizar no banco
            cropId: talhao.cropId,
            safraId: talhao.safraId,
            crop: talhao.crop,
            safras: talhao.safras,
            observacoes: talhao.observacoes,
            metadados: {
              ...talhao.metadados ?? {},
              'areaPrecisa': calculos['area'],
              'perimetroPreciso': calculos['perimeter'],
              'centro': calculos['center'],
              'bounds': calculos['bounds'],
              'isValid': calculos['isValid'],
              'pointCount': calculos['pointCount'],
              'simplifiedPointCount': calculos['simplifiedPointCount'],
              'simplificationRatio': calculos['simplificationRatio'],
              'pointDensity': calculos['pointDensity'],
              'ultimaAtualizacaoCalculos': DateTime.now().toIso8601String(),
              'areaFormatted': calculos['areaFormatted'],
              'perimeterFormatted': calculos['perimeterFormatted'],
            },
          );
          
          _talhoes[i] = talhaoAtualizado;
          
          // Salvar no banco de dados
          await updateTalhao(talhaoAtualizado);
        }
      }
      
      notifyListeners();
      Logger.info('✅ Atualização de cálculos precisos concluída');
    } catch (e) {
      Logger.error('❌ Erro ao atualizar cálculos precisos: $e');
    }
  }
}