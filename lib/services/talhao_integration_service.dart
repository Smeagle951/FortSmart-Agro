import 'dart:async';
import 'package:flutter/material.dart';

import '../models/talhao_model.dart';
import '../models/safra_model.dart';
import '../repositories/talhoes/talhao_sqlite_repository.dart';
import '../utils/logger.dart';
import 'data_cache_service.dart';

/// Serviço para integração do módulo de talhões com outros módulos do sistema
/// 
/// Este serviço fornece hooks e métodos para integração com os módulos:
/// - Histórico
/// - Plantio
/// - Monitoramento
/// - Relatórios
class TalhaoIntegrationService {
  static final TalhaoIntegrationService _instance = TalhaoIntegrationService._internal();
  factory TalhaoIntegrationService() => _instance;
  TalhaoIntegrationService._internal();

  final TalhaoSQLiteRepository _repository = TalhaoSQLiteRepository();
  final DataCacheService _cacheService = DataCacheService();
  
  // Streams para notificar outros módulos sobre mudanças
  final _talhaoChangedController = StreamController<TalhaoModel>.broadcast();
  final _safraChangedController = StreamController<SafraModel>.broadcast();
  final _alertasController = StreamController<TalhaoAlerta>.broadcast();
  
  /// Stream que notifica quando um talhão é alterado
  Stream<TalhaoModel> get onTalhaoChanged => _talhaoChangedController.stream;
  
  /// Stream que notifica quando uma safra é alterada
  Stream<SafraModel> get onSafraChanged => _safraChangedController.stream;
  
  /// Stream que notifica sobre alertas relacionados a talhões
  Stream<TalhaoAlerta> get onAlertaRecebido => _alertasController.stream;
  
  /// Libera recursos ao encerrar o serviço
  void dispose() {
    _talhaoChangedController.close();
    _safraChangedController.close();
    _alertasController.close();
  }
  
  /// Notifica outros módulos sobre a criação ou alteração de um talhão
  void notificarMudancaTalhao(TalhaoModel talhao) {
    _talhaoChangedController.add(talhao);
    Logger.log('TalhaoIntegrationService: Notificando mudança no talhão ${talhao.id}');
  }
  
  /// Notifica outros módulos sobre a criação ou alteração de uma safra
  void notificarMudancaSafra(SafraModel safra) {
    _safraChangedController.add(safra);
    Logger.log('TalhaoIntegrationService: Notificando mudança na safra ${safra.id} do talhão ${safra.talhaoId}');
  }
  
  /// Registra um evento no histórico do talhão
  Future<void> registrarEventoHistorico({
    required String talhaoId,
    required String tipoEvento,
    required String descricao,
    Map<String, dynamic>? metadados,
  }) async {
    try {
      // Implementação futura: integração com o módulo de histórico
      // Por enquanto, apenas registra o evento no log
      Logger.log('TalhaoIntegrationService: Evento registrado para talhão $talhaoId - $tipoEvento: $descricao');
      
      // Quando o módulo de histórico estiver implementado, chamar o serviço apropriado
      // await HistoricoService().registrarEvento(
      //   entidadeId: talhaoId,
      //   tipoEntidade: 'talhao',
      //   tipoEvento: tipoEvento,
      //   descricao: descricao,
      //   metadados: metadados,
      // );
    } catch (e) {
      Logger.error('Erro ao registrar evento no histórico: $e');
    }
  }
  
  /// Registra um plantio associado a um talhão
  Future<bool> registrarPlantio({
    required String talhaoId,
    required String culturaId,
    required String safra,
    required DateTime dataPlantio,
    Map<String, dynamic>? detalhesPlantio,
  }) async {
    try {
      // Buscar o talhão
      final talhao = await _repository.buscarPorId(int.parse(talhaoId));
      if (talhao == null) {
        Logger.error('Talhão não encontrado: $talhaoId');
        return false;
      }
      
      // Verificar se o talhão já tem a safra
      bool safraExistente = talhao.safras.any((s) => s.safra == safra);
      
      // Se a safra não existir, adicionar

      int? _parseColorValue(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) {
          try {
            if (value.startsWith('0x')) {
              return int.parse(value);
            } else if (value.startsWith('#')) {
              return int.parse('0xFF${value.substring(1)}');
            } else {
              return int.parse('0xFF$value');
            }
          } catch (_) {
            return null;
          }
        }
        return null;
      }

      if (!safraExistente) {
        // Buscar informações da cultura
        final culturas = await _cacheService.getCulturas();
        final cultura = culturas.firstWhere(
          (c) => c.id == culturaId,
          orElse: () => throw Exception('Cultura não encontrada: $culturaId'),
        );
        
        // Adicionar safra ao talhão
        await _repository.adicionarSafra(
          talhaoId: int.parse(talhaoId),
          safra: safra,
          culturaId: culturaId,
          culturaNome: cultura.name,
          culturaCor: Color(_parseColorValue(cultura.colorValue) ?? Colors.green.value),
        );
        
        Logger.log('Safra $safra adicionada ao talhão ${talhao.id}');
      }
      
      // Registrar evento no histórico
      await registrarEventoHistorico(
        talhaoId: talhaoId,
        tipoEvento: 'plantio',
        descricao: 'Plantio de ${detalhesPlantio?['culturaNome'] ?? culturaId} na safra $safra',
        metadados: {
          'dataPlantio': dataPlantio.toIso8601String(),
          'culturaId': culturaId,
          'safra': safra,
          ...?detalhesPlantio,
        },
      );
      
      return true;
    } catch (e) {
      Logger.error('Erro ao registrar plantio: $e');
      return false;
    }
  }
  
  /// Registra um alerta do módulo de monitoramento para um talhão
  Future<void> registrarAlerta({
    required String talhaoId,
    required String tipoAlerta,
    required String mensagem,
    required int nivelSeveridade,
    DateTime? dataAlerta,
    Map<String, dynamic>? detalhesAlerta,
  }) async {
    try {
      final talhao = await _repository.buscarPorId(int.parse(talhaoId));
      if (talhao == null) {
        Logger.error('Talhão não encontrado para alerta: $talhaoId');
        return;
      }
      
      final alerta = TalhaoAlerta(
        talhaoId: talhaoId,
        talhaoNome: talhao.name,
        tipoAlerta: tipoAlerta,
        mensagem: mensagem,
        nivelSeveridade: nivelSeveridade,
        dataAlerta: dataAlerta ?? DateTime.now(),
        detalhes: detalhesAlerta,
      );
      
      // Notificar sobre o novo alerta
      _alertasController.add(alerta);
      
      // Registrar no histórico
      await registrarEventoHistorico(
        talhaoId: talhaoId,
        tipoEvento: 'alerta',
        descricao: mensagem,
        metadados: {
          'tipoAlerta': tipoAlerta,
          'nivelSeveridade': nivelSeveridade,
          'dataAlerta': alerta.dataAlerta.toIso8601String(),
          ...?detalhesAlerta,
        },
      );
      
      Logger.log('Alerta registrado para talhão $talhaoId: $mensagem');
    } catch (e) {
      Logger.error('Erro ao registrar alerta: $e');
    }
  }
  
  /// Obtém talhões disponíveis para o módulo de plantio
  Future<List<TalhaoModel>> getTalhoesParaPlantio() async {
    try {
      final talhoes = await _repository.listarTodos();
      return talhoes;
    } catch (e) {
      Logger.error('Erro ao obter talhões para plantio: $e');
      return [];
    }
  }
  
  /// Obtém talhões com uma cultura específica
  Future<List<TalhaoModel>> getTalhoesPorCultura(String culturaId) async {
    try {
      final talhoes = await _repository.listarTodos();
      return talhoes.where((talhao) => 
        talhao.safras.any((safra) => safra.culturaId == culturaId)
      ).toList();
    } catch (e) {
      Logger.error('Erro ao obter talhões por cultura: $e');
      return [];
    }
  }
  
  /// Obtém talhões de uma safra específica
  Future<List<TalhaoModel>> getTalhoesPorSafra(String safra) async {
    try {
      return await _repository.listarPorSafra(safra);
    } catch (e) {
      Logger.error('Erro ao obter talhões por safra: $e');
      return [];
    }
  }
  
  /// Obtém talhões com filtros de safra e cultura
  Future<List<TalhaoModel>> getTalhoes({
    String? safraFiltro,
    String? culturaFiltro,
  }) async {
    try {
      // Obter talhões com filtro de safra
      List<TalhaoModel> talhoes;
      if (safraFiltro != null && safraFiltro.isNotEmpty) {
        talhoes = await _repository.listarPorSafra(safraFiltro);
      } else {
        talhoes = await _repository.listarTodos();
      }
      
      // Aplicar filtro de cultura
      if (culturaFiltro != null && culturaFiltro.isNotEmpty) {
        talhoes = talhoes.where((talhao) => 
          talhao.safras.any((safra) => 
            safra.culturaId == culturaFiltro || 
            safra.culturaNome.toLowerCase().contains(culturaFiltro.toLowerCase())
          )
        ).toList();
      }
      
      return talhoes;
    } catch (e) {
      Logger.error('Erro ao obter talhões com filtros: $e');
      return [];
    }
  }
  
  /// Obtém dados consolidados para o módulo de relatórios
  Future<Map<String, dynamic>> getDadosConsolidados({
    String? safraFiltro,
    String? culturaFiltro,
  }) async {
    try {
      // Obter talhões com filtros
      List<TalhaoModel> talhoes;
      if (safraFiltro != null && safraFiltro.isNotEmpty) {
        talhoes = await _repository.listarPorSafra(safraFiltro);
      } else {
        talhoes = await _repository.listarTodos();
      }
      
      // Aplicar filtro de cultura
      if (culturaFiltro != null && culturaFiltro.isNotEmpty) {
        talhoes = talhoes.where((talhao) => 
          talhao.safras.any((safra) => 
            safra.culturaId == culturaFiltro || 
            safra.culturaNome.toLowerCase().contains(culturaFiltro.toLowerCase())
          )
        ).toList();
      }
      
      // Calcular área total
      final areaTotal = talhoes.fold<double>(0.0, (total, talhao) => total + talhao.area);
      
      // Calcular área por cultura
      final areaPorCultura = await _repository.calcularAreaPorCultura(
        safraFiltro: safraFiltro,
      );
      
      // Contar talhões por safra
      final Map<String, int> talhoesPorSafra = {};
      for (final talhao in talhoes) {
        for (final safra in talhao.safras) {
          talhoesPorSafra[safra.safra] = (talhoesPorSafra[safra.safra] ?? 0) + 1;
        }
      }
      
      return {
        'totalTalhoes': talhoes.length,
        'areaTotal': areaTotal,
        'areaPorCultura': areaPorCultura,
        'talhoesPorSafra': talhoesPorSafra,
        'safras': talhoesPorSafra.keys.toList(),
      };
    } catch (e) {
      Logger.error('Erro ao obter dados consolidados: $e');
      return {};
    }
  }
}

/// Classe para representar um alerta relacionado a um talhão
class TalhaoAlerta {
  final String talhaoId;
  final String talhaoNome;
  final String tipoAlerta;
  final String mensagem;
  final int nivelSeveridade; // 1-5, sendo 5 o mais severo
  final DateTime dataAlerta;
  final Map<String, dynamic>? detalhes;
  
  TalhaoAlerta({
    required this.talhaoId,
    required this.talhaoNome,
    required this.tipoAlerta,
    required this.mensagem,
    required this.nivelSeveridade,
    required this.dataAlerta,
    this.detalhes,
  });
}
