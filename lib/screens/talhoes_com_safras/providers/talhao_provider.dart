import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/talhoes/talhao_safra_model.dart';
// Removendo imports duplicados - os modelos já estão disponíveis via talhao_safra_model.dart
import '../../../services/database_service.dart';
// Removendo dependência das tabelas antigas - usando apenas as novas tabelas talhao_safra
import '../../../services/precise_geo_calculator.dart';
import '../../../repositories/talhoes/talhao_safra_repository.dart';
import '../../../services/talhao_unified_service.dart';
import '../../../services/data_cache_service.dart';
import '../../../services/cultura_service.dart';
import '../../../services/talhao_cache_service.dart';
import '../../../modules/offline_maps/services/talhao_integration_service.dart';


/// Provider para gerenciar talhões com safras
class TalhaoProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final TalhaoSafraRepository _talhaoSafraRepository = TalhaoSafraRepository();
  final TalhaoIntegrationService _integrationService = TalhaoIntegrationService();
  
  List<TalhaoSafraModel> _talhoes = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Listeners para mudanças
  final List<Function()> _talhoesChangedListeners = [];
  
  // Getters
  List<TalhaoSafraModel> get talhoes => List.unmodifiable(_talhoes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// Adiciona um listener para mudanças nos talhões
  void addTalhoesChangedListener(Function() listener) {
    _talhoesChangedListeners.add(listener);
  }
  
  /// Remove um listener
  void removeTalhoesChangedListener(Function() listener) {
    _talhoesChangedListeners.remove(listener);
  }
  
  /// Notifica todos os listeners
  void _notifyTalhoesChangedListeners() {
    for (final listener in _talhoesChangedListeners) {
      listener();
    }
  }
  
  /// Executa uma operação com retry para garantir funcionamento offline
  Future<T> _executeWithRetry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int retries = 0;
    while (retries < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 100 * retries));
      }
    }
    throw Exception('Falha após $maxRetries tentativas');
  }
  
  /// Carrega todos os talhões do banco de dados local (OTIMIZADO)
  Future<List<TalhaoSafraModel>> carregarTalhoes({String? idFazenda}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      // OTIMIZAÇÃO: Notificar apenas uma vez no início
      notifyListeners();
      
      // OTIMIZAÇÃO: Limpar caches em background para não bloquear
      Future.microtask(() => _limparCachesConflitantes());
      
      // OTIMIZAÇÃO: Correção de culturas em background (não é crítica)
      Future.microtask(() async {
        try {
          await _talhaoSafraRepository.corrigirCulturasTalhoes();
        } catch (e) {
          // Silencioso em background
        }
      });
      
      // Carregar talhões diretamente do repositório
      final talhoesSafra = await _talhaoSafraRepository.forcarAtualizacaoTalhoes();
      
      // OTIMIZAÇÃO: Validação mais rápida - só verificar se a lista mudou
      if (idFazenda != null) {
        _talhoes = talhoesSafra.where((t) => t.idFazenda == idFazenda).toList();
      } else {
        _talhoes.clear();
        _talhoes.addAll(talhoesSafra);
      }
      
      // OTIMIZAÇÃO: Preservar culturas personalizadas em background
      Future.microtask(() => _preservarCulturasPersonalizadas());
      
      _isLoading = false;
      // OTIMIZAÇÃO: Notificar apenas uma vez no final
      notifyListeners();
      return List<TalhaoSafraModel>.from(_talhoes);
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar talhões: $e';
      notifyListeners();
      return [];
    }
  }
  
  /// Obtém um talhão pelo ID
  TalhaoSafraModel? obterTalhaoPorId(String id) {
    try {
      return _talhoes.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Limpa caches conflitantes para evitar sobrescrita de dados
  Future<void> _limparCachesConflitantes() async {
    try {
      print('🧹 Limpando caches conflitantes...');
      
      // Limpar cache do DataCacheService
      final dataCacheService = DataCacheService();
      dataCacheService.clearPlotCache();
      
      // CORREÇÃO: NÃO chamar forcarAtualizacaoGlobal() após remoção
      // Isso estava recarregando os dados do banco e sobrescrevendo a lista local
      // final talhaoUnifiedService = TalhaoUnifiedService();
      // await talhaoUnifiedService.forcarAtualizacaoGlobal();
      
      // Limpar cache do CulturaService
      final culturaService = CulturaService();
      culturaService.clearCache();
      
      print('✅ Caches conflitantes limpos com sucesso');
    } catch (e) {
      print('⚠️ Erro ao limpar caches: $e');
      // Não falhar o carregamento por erro no cache
    }
  }

  /// Limpa TODOS os caches incluindo SharedPreferences para garantir persistência correta
  Future<void> _limparTodosOsCaches() async {
    try {
      // Limpar cache do DataCacheService
      final dataCacheService = DataCacheService();
      dataCacheService.clearPlotCache();
      
      // Limpar cache do CulturaService
      final culturaService = CulturaService();
      culturaService.clearCache();
      
      // CORREÇÃO CRÍTICA: Limpar cache do SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('talhao_cache_data');
        await prefs.remove('talhao_cache_time');
        // Limpar TODAS as chaves relacionadas a talhões
        final keys = prefs.getKeys();
        for (final key in keys) {
          if (key.contains('talhao') || key.contains('plot')) {
            await prefs.remove(key);
          }
        }
      } catch (e) {
        // Silencioso
      }
      
      // Limpar cache do TalhaoUnifiedService
      try {
        final talhaoUnifiedService = TalhaoUnifiedService();
        talhaoUnifiedService.limparCache(); // Método retorna void, não precisa await
      } catch (e) {
        // Silencioso
      }
      
      // NOVO: Limpar cache do TalhaoCacheService
      try {
        final talhaoCacheService = TalhaoCacheService();
        await talhaoCacheService.clearCache();
      } catch (e) {
        // Silencioso
      }
    } catch (e) {
      print('⚠️ Erro ao limpar todos os caches: $e');
      // Não falhar a operação por erro no cache
    }
  }

  /// Verifica e normaliza culturas personalizadas dos talhões (CORRIGIDO)
  Future<void> _preservarCulturasPersonalizadas() async {
    try {
      print('🔍 DEBUG CULTURA - Verificando culturas personalizadas...');
      
      final culturaService = CulturaService();
      final culturasDisponiveis = await culturaService.loadCulturas();
      
      for (final talhao in _talhoes) {
        for (final safra in talhao.safras) {
          // Verificar se a cultura existe no módulo Culturas da Fazenda
          final culturaEncontrada = await culturaService.loadCulturaById(safra.idCultura);
          
          if (culturaEncontrada == null) {
            print('🔍 DEBUG CULTURA - Cultura não encontrada com ID: "${safra.idCultura}"');
            print('🔍 DEBUG CULTURA - Nome da cultura: "${safra.culturaNome}"');
            
            // CORREÇÃO: Tentar mapear pelo nome para uma cultura existente
            final culturaMapeada = culturasDisponiveis.firstWhere(
              (c) => c.name.toLowerCase() == safra.culturaNome.toLowerCase() ||
                     c.name.toLowerCase().contains(safra.culturaNome.toLowerCase()) ||
                     safra.culturaNome.toLowerCase().contains(c.name.toLowerCase()),
              orElse: () => culturasDisponiveis.firstWhere(
                (c) => c.id == safra.idCultura.replaceFirst('custom_', ''),
                orElse: () => culturasDisponiveis.first,
              ),
            );
            
            if (culturaMapeada != null) {
              print('🔍 DEBUG CULTURA - Mapeando "${safra.culturaNome}" para cultura existente: "${culturaMapeada.name}"');
              
              // Atualizar safra com dados da cultura mapeada
              safra.idCultura = culturaMapeada.id;
              safra.culturaNome = culturaMapeada.name;
              safra.culturaCor = culturaMapeada.color;
              
              // Atualizar no banco
              await _talhaoSafraRepository.atualizarSafraTalhao(safra);
              
              print('✅ DEBUG CULTURA - Cultura normalizada: ${safra.idCultura} - ${safra.culturaNome}');
            } else {
              print('⚠️ DEBUG CULTURA - Não foi possível mapear cultura: ${safra.culturaNome}');
              // Manter como está, não alterar
            }
          } else {
            // Cultura encontrada - garantir que os dados estejam atualizados
            if (safra.culturaNome != culturaEncontrada.name || 
                safra.culturaCor.value != culturaEncontrada.color.value) {
              print('🔍 DEBUG CULTURA - Atualizando dados da cultura: ${culturaEncontrada.name}');
              safra.culturaNome = culturaEncontrada.name;
              safra.culturaCor = culturaEncontrada.color;
              
              // Atualizar no banco
              await _talhaoSafraRepository.atualizarSafraTalhao(safra);
            }
          }
        }
      }
      
      print('✅ DEBUG CULTURA - Verificação e normalização de culturas concluída');
    } catch (e) {
      print('⚠️ Erro ao verificar culturas personalizadas: $e');
    }
  }
  
  /// Salva um novo talhão usando TalhaoSafraRepository (CORRIGIDO)
  Future<bool> salvarTalhao({
    required String nome,
    required String idFazenda,
    required List<LatLng> pontos,
    required String idCultura,
    required String nomeCultura,
    required Color corCultura,
    required String idSafra,
    String? imagemCultura,
    double? areaCalculada, // Área já calculada nas métricas
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Usar área já calculada nas métricas ou calcular se não fornecida
      double area;
      if (areaCalculada != null && areaCalculada > 0) {
        area = areaCalculada;
      } else {
        // Calcular área do polígono usando cálculo preciso apenas se necessário
        area = _calcularAreaAsync(pontos);
      }
      
      // Cria o polígono a partir dos pontos
      final talhaoId = const Uuid().v4();
      final poligono = PoligonoModel(
        id: const Uuid().v4(),
        talhaoId: talhaoId,
        pontos: pontos,
        area: area.toInt(),
        perimetro: _calcularPerimetroAsync(pontos),
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
        area: area, // Definir área explicitamente
      );
      
      // Salva usando TalhaoSafraRepository (CORRIGIDO)
      final idSalvo = await _talhaoSafraRepository.adicionarTalhao(talhao);
      
      if (idSalvo.isNotEmpty) {
        // Adiciona à lista em memória
        _talhoes.add(talhao);
        
        // LIMPAR CACHES APÓS SALVAR para evitar conflitos
        await _limparCachesConflitantes();
        
        _isLoading = false;
        _errorMessage = null;
        // CORREÇÃO: Notificar apenas uma vez no final
        notifyListeners();
        
        // Integrar com mapas offline
        try {
          await _integrationService.createOfflineMapForTalhao(talhao);
        } catch (e) {
          // Não falhar o salvamento do talhão por erro no mapa offline
        }
        
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
      return false;
    }
  }

  /// Converte polígonos para JSON string
  String _converterPoligonosParaJson(List<PoligonoModel> poligonos) {
    final List<Map<String, dynamic>> poligonosJson = [];
    
    for (var poligono in poligonos) {
      poligonosJson.add({
        'id': poligono.id,
        'talhaoId': poligono.talhaoId,
        'pontos': poligono.pontos.map((p) => '${p.latitude},${p.longitude}').join(';'),
        'area': poligono.area,
        'perimetro': poligono.perimetro,
        'dataCriacao': poligono.dataCriacao.toIso8601String(),
        'dataAtualizacao': poligono.dataAtualizacao.toIso8601String(),
        'ativo': poligono.ativo ? 1 : 0,
      });
    }
    
    return jsonEncode(poligonosJson);
  }

  /// Converte safras para JSON string
  String _converterSafrasParaJson(List<SafraTalhaoModel> safras) {
    final List<Map<String, dynamic>> safrasJson = [];
    
    for (var safra in safras) {
      safrasJson.add({
        'id': safra.id,
        'idTalhao': safra.idTalhao,
        'idSafra': safra.idSafra,
        'idCultura': safra.idCultura,
        'culturaNome': safra.culturaNome,
        'culturaCor': safra.culturaCor.value,
        'imagemCultura': safra.imagemCultura,
        'area': safra.area,
        'dataCadastro': safra.dataCadastro.toIso8601String(),
        'dataAtualizacao': safra.dataAtualizacao.toIso8601String(),
        'sincronizado': safra.sincronizado ? 1 : 0,
      });
    }
    
    return jsonEncode(safrasJson);
  }
  
  /// Salva um talhão a partir do DesenhoProvider e CulturaProvider
  Future<bool> salvarTalhaoDoDesenho({
    required String nome,
    required String idFazenda,
    required List<LatLng> pontos,
    required String idCultura,
    required String nomeCultura,
    required Color corCultura,
    required String idSafra,
  }) async {
    // Verifica se há pontos suficientes
    if (pontos.length < 3) {
      _errorMessage = 'O polígono precisa ter pelo menos 3 pontos';
      notifyListeners();
      return false;
    }
    
    // Salva o talhão
    return salvarTalhao(
      nome: nome,
      idFazenda: idFazenda,
      pontos: pontos,
      idCultura: idCultura,
      nomeCultura: nomeCultura,
      corCultura: corCultura,
      idSafra: idSafra,
      imagemCultura: null,
      areaCalculada: null, // Não há área pré-calculada neste método
    );
  }
  
  /// Atualiza um talhão existente
  Future<bool> atualizarTalhao(TalhaoSafraModel talhao) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Validar dados antes de salvar
      if (talhao.name.trim().isEmpty) {
        _errorMessage = 'Nome do talhão é obrigatório';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      if (talhao.poligonos.isEmpty) {
        _errorMessage = 'Talhão deve ter pelo menos um polígono';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Validar polígonos
      for (final poligono in talhao.poligonos) {
        if (poligono.pontos.isEmpty || poligono.pontos.length < 3) {
          _errorMessage = 'Polígono deve ter pelo menos 3 pontos';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      
      // Atualiza a data de atualização
      final talhaoAtualizado = talhao.copyWith(
        dataAtualizacao: DateTime.now(),
        sincronizado: false, // Sempre marcar como não sincronizado após edição
      );
      
      print('🔄 Salvando talhão: ${talhaoAtualizado.name}');
      print('  - ID: ${talhaoAtualizado.id}');
      print('  - Área: ${talhaoAtualizado.area}');
      print('  - Polígonos: ${talhaoAtualizado.poligonos.length}');
      
      // CORREÇÃO: Usar TalhaoSafraRepository para atualizar corretamente
      await _executeWithRetry(() async {
        await _talhaoSafraRepository.atualizarTalhao(talhaoAtualizado);
      });
      
      // CORREÇÃO CRÍTICA: Limpar TODOS os caches para evitar restauração de dados antigos
      await _limparTodosOsCaches();
      
      // Sempre prosseguir com a atualização da lista em memória
      // Atualiza na lista em memória
      final index = _talhoes.indexWhere((t) => t.id == talhao.id);
      if (index >= 0) {
        _talhoes[index] = talhaoAtualizado;
      } else {
        // Se não encontrou na lista, adiciona
        _talhoes.add(talhaoAtualizado);
      }
      
      _isLoading = false;
      // CORREÇÃO: Notificar apenas uma vez no final
      notifyListeners();
      print('✅ Talhão atualizado com sucesso');
      
      // Integrar com mapas offline
      try {
        print('🗺️ Atualizando mapa offline para talhão: ${talhaoAtualizado.name}');
        await _integrationService.updateOfflineMapForTalhao(talhaoAtualizado);
        print('✅ Mapa offline atualizado com sucesso');
      } catch (e) {
        print('⚠️ Erro ao atualizar mapa offline: $e');
        // Não falhar a atualização do talhão por erro no mapa offline
      }
      
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao atualizar talhão: $e';
      notifyListeners();
      print('❌ Erro ao atualizar talhão: $e');
      return false;
    }
  }
  
  /// Exclui um talhão
  Future<bool> excluirTalhao(String id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      // Verificar se o talhão existe
      final talhaoExistente = _talhoes.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Talhão não encontrado'),
      );
      
      // Exclui do banco de dados usando o repositório correto
      await _talhaoSafraRepository.removerTalhao(id);
      final count = 1; // Assumir sucesso se não houve exceção
      
      print('📊 Resultado da exclusão: $count registros afetados');
      
      if (count > 0) {
        // CORREÇÃO CRÍTICA: Limpar TODOS os caches para evitar restauração de dados antigos
        await _limparTodosOsCaches();
        
        // Remove da lista em memória
        _talhoes.removeWhere((t) => t.id == id);
        
        _isLoading = false;
        // CORREÇÃO: Notificar apenas uma vez no final
        notifyListeners();
        
        // Integrar com mapas offline
        try {
          await _integrationService.removeOfflineMapForTalhao(id);
        } catch (e) {
          // Não falhar a exclusão do talhão por erro no mapa offline
        }
        
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Erro ao excluir talhão do banco de dados';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao excluir talhão: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Salva um talhão importado (KML/GeoJSON)
  Future<bool> salvarTalhaoImportado({
    required String nome,
    required String idFazenda,
    required List<List<LatLng>> poligonos,
    required String idCultura,
    required String nomeCultura,
    required Color corCultura,
    required String idSafra,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Cria polígonos para cada lista de pontos
      final List<PoligonoModel> poligonosModel = [];
      double areaTotal = 0.0;
      
      for (final pontos in poligonos) {
        if (pontos.length >= 3) {
          final area = _calcularAreaHectares(pontos);
          final poligono = PoligonoModel(
            id: const Uuid().v4(),
            talhaoId: const Uuid().v4(),
            pontos: pontos,
            area: area.toInt(),
            perimetro: _calcularPerimetro(pontos).toInt(),
            dataCriacao: DateTime.now(),
            dataAtualizacao: DateTime.now(),
            ativo: true,
          );
          poligonosModel.add(poligono);
          areaTotal += area;
        }
      }
      
      if (poligonosModel.isEmpty) {
        _errorMessage = 'Nenhum polígono válido encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Cria o modelo de safra
      final safra = SafraTalhaoModel(
        id: const Uuid().v4(),
        idTalhao: const Uuid().v4(),
        idSafra: idSafra,
        idCultura: idCultura,
        culturaNome: nomeCultura,
        culturaCor: corCultura,
        area: areaTotal,
        dataCadastro: DateTime.now(),
        dataAtualizacao: DateTime.now(),
      );
      
      // Cria o modelo de talhão
      final talhao = TalhaoSafraModel(
        id: const Uuid().v4(),
        name: nome,
        idFazenda: idFazenda,
        poligonos: poligonosModel,
        safras: [safra],
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
      );
      
      // Salva no banco de dados
      final id = await _databaseService.insertData('talhoes', talhao.toMap());
      
      if (id > 0) {
        // Adiciona à lista em memória
        _talhoes.add(talhao);
        _isLoading = false;
        // CORREÇÃO: Notificar apenas uma vez no final
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Erro ao salvar talhão importado no banco de dados';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao salvar talhão importado: $e';
      notifyListeners();
      print(_errorMessage);
      return false;
    }
  }
  
  /// Calcula o perímetro de uma lista de pontos
  double _calcularPerimetro(List<LatLng> pontos) {
    if (pontos.length < 2) return 0.0;
    
    double perimetro = 0.0;
    for (int i = 0; i < pontos.length; i++) {
      final p1 = pontos[i];
      final p2 = pontos[(i + 1) % pontos.length];
      perimetro += _calcularDistancia(p1, p2);
    }
    
    return perimetro;
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
  
  /// Limpa o erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Força o recarregamento dos talhões
  Future<void> recarregarTalhoes({String? idFazenda}) async {
    await carregarTalhoes(idFazenda: idFazenda);
  }

  /// Verifica se um talhão ainda existe no banco de dados
  Future<bool> _verificarTalhaoExisteNoBanco(String talhaoId) async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM talhao_safra WHERE id = ?',
        [talhaoId],
      );
      final count = result.first['count'] as int;
      return count > 0;
    } catch (e) {
      print('❌ DEBUG: Erro ao verificar talhão no banco: $e');
      return false;
    }
  }
  
  /// Calcula área em hectares usando sistema preciso
  double _calcularAreaHectares(List<LatLng> pontos) {
    try {
      if (pontos.length < 3) return 0.0;
      
      // Validar pontos antes do cálculo
      for (final ponto in pontos) {
        if (ponto.latitude.isNaN || ponto.longitude.isNaN || 
            ponto.latitude.isInfinite || ponto.longitude.isInfinite) {
          print('DEBUG: Ponto inválido detectado: ${ponto.latitude}, ${ponto.longitude}');
          return 0.0;
        }
      }
      
      // Usar sistema de cálculo preciso
      final areaHectares = PreciseGeoCalculator.calculatePolygonAreaHectares(pontos);
      
      // Validar resultado
      if (areaHectares.isNaN || areaHectares.isInfinite || areaHectares < 0) {
        print('DEBUG: Área calculada inválida: $areaHectares');
        return 0.0;
      }
      
      print('DEBUG: Área calculada com sucesso (precisa): $areaHectares hectares');
      return areaHectares;
      
    } catch (e) {
      print('DEBUG: Erro ao calcular área: $e');
      return 0.0;
    }
  }

  /// Salva talhões importados usando TalhaoSafraRepository (CORRIGIDO)
  Future<bool> salvarTalhoesImportados({
    required String nome,
    required String idFazenda,
    required List<List<LatLng>> poligonos,
    required String idCultura,
    required String nomeCultura,
    required Color corCultura,
    required String idSafra,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Cria polígonos para cada lista de pontos
      final List<PoligonoModel> poligonosModel = [];
      double areaTotal = 0.0;
      
      for (final pontos in poligonos) {
        if (pontos.length >= 3) {
          final area = _calcularAreaAsync(pontos);
          final poligono = PoligonoModel(
            id: const Uuid().v4(),
            talhaoId: const Uuid().v4(),
            pontos: pontos,
            area: area.toInt(),
            perimetro: _calcularPerimetroAsync(pontos),
            dataCriacao: DateTime.now(),
            dataAtualizacao: DateTime.now(),
            ativo: true,
          );
          poligonosModel.add(poligono);
          areaTotal += area;
        }
      }
      
      if (poligonosModel.isEmpty) {
        _errorMessage = 'Nenhum polígono válido encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Cria o modelo de safra
      final safra = SafraTalhaoModel(
        id: const Uuid().v4(),
        idTalhao: const Uuid().v4(),
        idSafra: idSafra,
        idCultura: idCultura,
        culturaNome: nomeCultura,
        culturaCor: corCultura,
        area: areaTotal,
        dataCadastro: DateTime.now(),
        dataAtualizacao: DateTime.now(),
      );
      
      // Cria o modelo de talhão
      final talhao = TalhaoSafraModel(
        id: const Uuid().v4(),
        name: nome,
        idFazenda: idFazenda,
        poligonos: poligonosModel,
        safras: [safra],
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
      );
      
      // Salva usando TalhaoSafraRepository (CORRIGIDO)
      final idSalvo = await _talhaoSafraRepository.adicionarTalhao(talhao);
      
      if (idSalvo.isNotEmpty) {
        // Adiciona à lista em memória
        _talhoes.add(talhao);
        _isLoading = false;
        // CORREÇÃO: Notificar apenas uma vez no final
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Erro ao salvar talhão importado no banco de dados';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao salvar talhão importado: $e';
      notifyListeners();
      print(_errorMessage);
      return false;
    }
  }

  /// Calcula área usando PreciseGeoCalculator com Shoelace (RESTAURADO)
  double _calcularAreaAsync(List<LatLng> pontos) {
    try {
      if (pontos.length < 3) {
        print('⚠️ Pontos insuficientes para calcular área: ${pontos.length}');
        return 0.0;
      }
      
      // Validar pontos antes do cálculo
      for (final ponto in pontos) {
        if (ponto.latitude.isNaN || ponto.longitude.isNaN) {
          print('⚠️ Ponto com coordenadas NaN encontrado');
          return 0.0;
        }
        if (ponto.latitude.abs() > 90 || ponto.longitude.abs() > 180) {
          print('⚠️ Coordenadas fora dos limites válidos: ${ponto.latitude}, ${ponto.longitude}');
          return 0.0;
        }
      }
      
      print('🔄 Calculando área com PreciseGeoCalculator Shoelace para ${pontos.length} pontos');
      
      // Usar PreciseGeoCalculator com timeout para evitar travamentos
      final area = _calcularAreaComTimeout(pontos);
      
      // Validar resultado
      if (area.isNaN || area.isInfinite || area < 0) {
        print('⚠️ Área calculada inválida: $area, usando cálculo básico');
        return _calcularAreaHectares(pontos);
      }
      
      print('✅ Área calculada com sucesso: ${area.toStringAsFixed(4)} hectares');
      return area;
    } catch (e) {
      print('⚠️ Erro no cálculo preciso, usando cálculo básico: $e');
      try {
        return _calcularAreaHectares(pontos);
      } catch (e2) {
        print('❌ Erro também no cálculo básico: $e2');
        return 0.0;
      }
    }
  }

  /// Calcula área com timeout para evitar travamentos
  double _calcularAreaComTimeout(List<LatLng> pontos) {
    try {
      // Usar PreciseGeoCalculator com validação adicional
      final area = PreciseGeoCalculator.calculatePolygonAreaHectares(pontos);
      return area;
    } catch (e) {
      print('⚠️ Erro no PreciseGeoCalculator: $e');
      // Fallback para cálculo básico
      return _calcularAreaHectares(pontos);
    }
  }

  /// Calcula perímetro usando PreciseGeoCalculator (RESTAURADO)
  int _calcularPerimetroAsync(List<LatLng> pontos) {
    try {
      print('🔄 Calculando perímetro com PreciseGeoCalculator para ${pontos.length} pontos');
      
      // Usar PreciseGeoCalculator para cálculo preciso
      final perimetro = PreciseGeoCalculator.calculatePolygonPerimeter(pontos);
      return perimetro.toInt();
    } catch (e) {
      print('⚠️ Erro no cálculo preciso de perímetro, usando cálculo básico: $e');
      return _calcularPerimetro(pontos).toInt();
    }
  }

  /// Adiciona um talhão à lista
  void addTalhao(TalhaoSafraModel talhao) {
    _talhoes.add(talhao);
    notifyListeners();
    _notifyTalhoesChangedListeners();
  }

  /// Remove um talhão da lista
  void removeTalhao(String id) {
    _talhoes.removeWhere((talhao) => talhao.id == id);
    notifyListeners();
    _notifyTalhoesChangedListeners();
  }

  /// Atualiza um talhão na lista
  void updateTalhao(TalhaoSafraModel talhao) {
    final index = _talhoes.indexWhere((t) => t.id == talhao.id);
    if (index != -1) {
      _talhoes[index] = talhao;
      notifyListeners();
      _notifyTalhoesChangedListeners();
    }
  }

  /// Busca um talhão por ID
  TalhaoSafraModel? getTalhaoById(String id) {
    try {
      return _talhoes.firstWhere((talhao) => talhao.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Limpa a lista de talhões
  void clearTalhoes() {
    _talhoes.clear();
    notifyListeners();
    _notifyTalhoesChangedListeners();
  }

  /// Limpa mensagens de erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }


  /// Remove um talhão pelo ID (OTIMIZADO)
  Future<bool> removerTalhao(String talhaoId) async {
    try {
      print('🔍 DEBUG: Iniciando remoção do talhão: $talhaoId');
      _isLoading = true;
      _errorMessage = null;
      // OTIMIZAÇÃO: Notificar apenas uma vez no início
      notifyListeners();
      
      // CORREÇÃO: Usar TalhaoSafraRepository para remoção correta
      await _executeWithRetry(() async {
        await _talhaoSafraRepository.removerTalhao(talhaoId);
      });
      
      // CORREÇÃO CRÍTICA: Limpar TODOS os caches para evitar restauração de dados antigos
      await _limparTodosOsCaches();
      
      // Remover da lista local
      _talhoes.removeWhere((talhao) => talhao.id == talhaoId);
      
      _isLoading = false;
      
      // OTIMIZAÇÃO: Notificar apenas uma vez no final com todas as mudanças
      _notifyTalhoesChangedListeners();
      notifyListeners();
      
      print('✅ DEBUG: Talhão removido com sucesso: $talhaoId');
      print('✅ DEBUG: Lista local atualizada - ${_talhoes.length} talhões restantes');
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao remover talhão: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ DEBUG: Erro ao remover talhão: $e');
      return false;
    }
  }


  /// Força o reload completo dos talhões do banco de dados (OTIMIZADO)
  Future<void> forcarReload() async {
    try {
      print('🔄 DEBUG: Forçando reload completo dos talhões...');
      
      // Limpar lista local
      _talhoes.clear();
      
      // OTIMIZAÇÃO: Limpar caches em background
      Future.microtask(() => _limparCachesConflitantes());
      
      // Recarregar do banco
      await carregarTalhoes();
      
      print('✅ DEBUG: Reload completo concluído - ${_talhoes.length} talhões carregados');
    } catch (e) {
      print('❌ DEBUG: Erro ao forçar reload: $e');
      rethrow;
    }
  }
}
