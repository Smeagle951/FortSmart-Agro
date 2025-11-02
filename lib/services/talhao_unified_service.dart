import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../models/talhao_model.dart';
import '../models/safra_model.dart';
import '../models/poligono_model.dart';
import '../models/talhoes/talhao_safra_model.dart' as talhao_safra;
import '../repositories/talhoes/talhao_safra_repository.dart';
import '../utils/logger.dart';

/// Serviço unificado para carregar talhões em todos os módulos do sistema
/// Garante que os talhões salvos apareçam em: Monitoramento, Plantio, Aplicação, Colheita, Gestão de Custos, etc.
class TalhaoUnifiedService {
  static final TalhaoUnifiedService _instance = TalhaoUnifiedService._internal();
  factory TalhaoUnifiedService() => _instance;
  TalhaoUnifiedService._internal();

  final TalhaoSafraRepository _talhaoRepository = TalhaoSafraRepository();
  
  // Cache de talhões para evitar recarregamentos desnecessários
  List<TalhaoModel>? _cachedTalhoes;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidity = Duration(minutes: 5);
  
  // Stream para notificar mudanças nos talhões
  final _talhoesController = StreamController<List<TalhaoModel>>.broadcast();
  Stream<List<TalhaoModel>> get talhoesStream => _talhoesController.stream;

  /// Carrega talhões para qualquer módulo do sistema
  Future<List<TalhaoModel>> carregarTalhoesParaModulo({
    required String nomeModulo,
    bool forceRefresh = false,
  }) async {
    try {
      Logger.info('🔄 [$nomeModulo] Carregando talhões...');
      
      // Verificar cache se não for refresh forçado
      if (!forceRefresh && _cachedTalhoes != null && _lastCacheUpdate != null) {
        final cacheAge = DateTime.now().difference(_lastCacheUpdate!);
        if (cacheAge < _cacheValidity) {
          Logger.info('📊 [$nomeModulo] Usando cache de talhões (${_cachedTalhoes!.length} talhões)');
          return _cachedTalhoes!;
        }
      }
      
      // Verificar se há talhões salvos
      final hasTalhoes = await _talhaoRepository.hasTalhoesSalvos();
      Logger.info('📊 [$nomeModulo] Há talhões salvos no banco: $hasTalhoes');
      
      if (!hasTalhoes) {
        Logger.info('ℹ️ [$nomeModulo] Nenhum talhão salvo encontrado');
        _cachedTalhoes = [];
        _lastCacheUpdate = DateTime.now();
        _talhoesController.add(_cachedTalhoes!);
        return _cachedTalhoes!;
      }
      
      // Carregar talhões do repositório
      final talhoesSafra = await _talhaoRepository.forcarAtualizacaoTalhoes();
      Logger.info('📊 [$nomeModulo] ${talhoesSafra.length} talhões encontrados no repositório');
      
      if (talhoesSafra.isEmpty) {
        Logger.info('ℹ️ [$nomeModulo] Nenhum talhão válido encontrado');
        _cachedTalhoes = [];
        _lastCacheUpdate = DateTime.now();
        _talhoesController.add(_cachedTalhoes!);
        return _cachedTalhoes!;
      }
      
      // Converter para TalhaoModel
      final talhoesConvertidos = <TalhaoModel>[];
      
      for (final talhaoSafra in talhoesSafra) {
        Logger.info('🔍 [$nomeModulo] Processando talhão: ${talhaoSafra.nome}');
        
        if (talhaoSafra.poligonos.isNotEmpty) {
          final poligono = talhaoSafra.poligonos.first;
          Logger.info('📍 [$nomeModulo] Polígono encontrado com ${poligono.pontos.length} pontos');
          
          if (poligono.pontos.length >= 3) {
            // Validar coordenadas
            final pontosValidos = <LatLng>[];
            for (final ponto in poligono.pontos) {
              if (ponto != null && 
                  ponto.latitude != null && 
                  ponto.longitude != null &&
                  ponto.latitude != 0.0 && 
                  ponto.longitude != 0.0) {
                pontosValidos.add(LatLng(
                  ponto.latitude.toDouble(),
                  ponto.longitude.toDouble(),
                ));
              }
            }
            
            if (pontosValidos.length >= 3) {
              // Garantir que o polígono está fechado
              if (pontosValidos.first != pontosValidos.last) {
                pontosValidos.add(pontosValidos.first);
              }
              
              // Criar modelo de polígono
              final poligonoModel = PoligonoModel(
                id: poligono.id.toString(),
                pontos: pontosValidos,
                dataCriacao: poligono.dataCriacao ?? DateTime.now(),
                dataAtualizacao: poligono.dataAtualizacao ?? DateTime.now(),
                ativo: poligono.ativo ?? true,
                area: poligono.area?.toDouble() ?? 0.0,
                perimetro: poligono.perimetro?.toDouble() ?? 0.0,
                talhaoId: talhaoSafra.id,
              );
              
              // Criar modelo de talhão
              final talhaoModel = TalhaoModel(
                id: talhaoSafra.id.toString(),
                name: talhaoSafra.name,
                area: talhaoSafra.area?.toDouble() ?? 0.0,
                fazendaId: talhaoSafra.idFazenda,
                dataCriacao: talhaoSafra.dataCriacao,
                dataAtualizacao: talhaoSafra.dataAtualizacao,
                observacoes: '',
                sincronizado: talhaoSafra.sincronizado,
                safras: talhaoSafra.safras.map((s) => SafraModel(
                  id: s.id.toString(),
                  talhaoId: s.idTalhao,
                  safra: s.idSafra,
                  culturaId: s.idCultura,
                  culturaNome: s.culturaNome,
                  culturaCor: s.culturaCor.toString(),
                  dataCriacao: s.dataCadastro,
                  dataAtualizacao: s.dataAtualizacao,
                  sincronizado: s.sincronizado,
                  periodo: s.idSafra,
                  dataInicio: s.dataCadastro,
                  dataFim: s.dataAtualizacao,
                  ativa: true,
                  nome: s.culturaNome,
                )).toList(),
                crop: null,
                poligonos: [poligonoModel],
              );
              
              talhoesConvertidos.add(talhaoModel);
              Logger.info('✅ [$nomeModulo] Talhão convertido: ${talhaoModel.name}');
            } else {
              Logger.warning('⚠️ [$nomeModulo] Talhão ${talhaoSafra.nome} com pontos insuficientes: ${pontosValidos.length}');
            }
          } else {
            Logger.warning('⚠️ [$nomeModulo] Talhão ${talhaoSafra.nome} sem polígono válido');
          }
        } else {
          Logger.warning('⚠️ [$nomeModulo] Talhão ${talhaoSafra.nome} sem polígonos');
        }
      }
      
      // Atualizar cache
      _cachedTalhoes = talhoesConvertidos;
      _lastCacheUpdate = DateTime.now();
      _talhoesController.add(_cachedTalhoes!);
      
      Logger.info('✅ [$nomeModulo] ${talhoesConvertidos.length} talhões carregados com sucesso');
      return talhoesConvertidos;
      
    } catch (e) {
      Logger.error('❌ [$nomeModulo] Erro ao carregar talhões: $e');
      // Retornar cache se disponível, senão lista vazia
      return _cachedTalhoes ?? [];
    }
  }

  /// Obtém todos os talhões (alias para compatibilidade)
  Future<List<TalhaoModel>> getAllTalhoes() async {
    return carregarTalhoesParaModulo(nomeModulo: 'GERAL');
  }

  /// Força atualização dos talhões em todos os módulos
  Future<List<TalhaoModel>> forcarAtualizacaoGlobal() async {
    Logger.info('🔄 Forçando atualização global dos talhões...');
    
    // Limpar cache
    _cachedTalhoes = null;
    _lastCacheUpdate = null;
    
    // Recarregar para todos os módulos
    final talhoes = await carregarTalhoesParaModulo(
      nomeModulo: 'SISTEMA',
      forceRefresh: true,
    );
    
    Logger.info('✅ Atualização global concluída: ${talhoes.length} talhões');
    return talhoes;
  }

  /// Obtém talhões do cache se disponível
  List<TalhaoModel>? getTalhoesCache() {
    return _cachedTalhoes;
  }

  /// Verifica se há talhões salvos
  Future<bool> hasTalhoesSalvos() async {
    try {
      return await _talhaoRepository.hasTalhoesSalvos();
    } catch (e) {
      Logger.error('❌ Erro ao verificar talhões salvos: $e');
      return false;
    }
  }

  /// Limpa o cache de talhões
  void clearCache() {
    _cachedTalhoes = null;
    _lastCacheUpdate = null;
    Logger.info('🗑️ Cache de talhões limpo');
  }

  /// Obtém estatísticas dos talhões
  Future<Map<String, dynamic>> getEstatisticasTalhoes() async {
    try {
      final talhoes = await carregarTalhoesParaModulo(nomeModulo: 'ESTATISTICAS');
      
      double areaTotal = 0.0;
      int totalPoligonos = 0;
      int totalSafras = 0;
      
      for (final talhao in talhoes) {
        areaTotal += talhao.area;
        totalPoligonos += talhao.poligonos.length;
        totalSafras += talhao.safras.length;
      }
      
      return {
        'total_talhoes': talhoes.length,
        'area_total': areaTotal,
        'total_poligonos': totalPoligonos,
        'total_safras': totalSafras,
        'ultima_atualizacao': _lastCacheUpdate?.toIso8601String(),
        'cache_valido': _cachedTalhoes != null && _lastCacheUpdate != null,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Adiciona um novo talhão
  Future<String> adicionarTalhao(TalhaoModel talhao) async {
    try {
      Logger.info('➕ Adicionando novo talhão: ${talhao.nome}');
      
      // Converter TalhaoModel para TalhaoSafraModel
      final talhaoSafra = talhao_safra.TalhaoSafraModel(
        name: talhao.nome,
        idFazenda: talhao.fazendaId ?? '1',
        poligonos: talhao.pontos.map((p) => talhao_safra.PoligonoModel(
          id: const Uuid().v4(),
          talhaoId: talhao.id,
          pontos: [p],
          area: 0,
          perimetro: 0,
          ativo: true,
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
        )).toList(),
        area: talhao.area,
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
      );
      
      final id = await _talhaoRepository.adicionarTalhao(talhaoSafra);
      
      // Limpar cache para forçar recarregamento
      limparCache();
      
      // Notificar mudanças
      _talhoesController.add(await carregarTalhoesParaModulo(nomeModulo: 'GERAL'));
      
      Logger.info('✅ Talhão adicionado com sucesso: $id');
      return id;
      
    } catch (e) {
      Logger.error('❌ Erro ao adicionar talhão: $e');
      rethrow;
    }
  }

  /// Limpa o cache
  void limparCache() {
    _cachedTalhoes = null;
    _lastCacheUpdate = null;
    Logger.info('🗑️ Cache de talhões limpo');
  }

  /// Dispose do serviço
  void dispose() {
    _talhoesController.close();
  }
}
