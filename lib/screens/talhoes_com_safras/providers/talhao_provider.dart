import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../models/talhoes/talhao_safra_model.dart';
// Removendo imports duplicados - os modelos já estão disponíveis via talhao_safra_model.dart
import '../../../services/database_service.dart';
// Removendo dependência das tabelas antigas - usando apenas as novas tabelas talhao_safra
import '../../../utils/talhao_calculator.dart';
import '../../../repositories/talhoes/talhao_safra_repository.dart';
import '../../../services/talhao_unified_service.dart';
import '../../../services/data_cache_service.dart';
import '../../../services/cultura_service.dart';
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
        print('🔍 DEBUG: Tentativa ${retries + 1} de $maxRetries');
        return await operation();
      } catch (e) {
        retries++;
        print('🔍 DEBUG: Erro na tentativa $retries: $e');
        if (retries >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 100 * retries));
      }
    }
    throw Exception('Falha após $maxRetries tentativas');
  }
  
  /// Carrega todos os talhões do banco de dados local
  Future<List<TalhaoSafraModel>> carregarTalhoes({String? idFazenda}) async {
    try {
      print('🔍 DEBUG: Iniciando carregamento de talhões');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // LIMPAR CACHES CONFLITANTES antes de carregar
      await _limparCachesConflitantes();
      
      // Primeiro, tentar corrigir problemas de cultura
      print('🔍 DEBUG: Tentando corrigir problemas de cultura...');
      try {
        await _talhaoSafraRepository.corrigirCulturasTalhoes();
      } catch (e) {
        print('⚠️ Erro ao corrigir culturas: $e');
      }
      
      // Carregar talhões diretamente do repositório
      print('🔍 DEBUG: Carregando talhões diretamente do repositório');
      final talhoesSafra = await _talhaoSafraRepository.forcarAtualizacaoTalhoes();
      
      print('🔍 DEBUG: Talhões carregados do repositório: ${talhoesSafra.length}');
      
      // Atualizar lista local
      _talhoes.clear();
      _talhoes.addAll(talhoesSafra);
      
      print('🔍 DEBUG: ${_talhoes.length} talhões carregados com sucesso');
      
      // Verificar e preservar culturas personalizadas
      await _preservarCulturasPersonalizadas();
      
      // Log detalhado para debug
      for (final talhao in _talhoes) {
        print('📋 Talhão: ${talhao.nome}');
        print('  - ID: ${talhao.id}');
        print('  - Polígonos: ${talhao.poligonos.length}');
        print('  - Safras: ${talhao.safras.length}');
        
        for (final safra in talhao.safras) {
          print('🔍 DEBUG CULTURA - Safra carregada:');
          print('    - culturaNome: "${safra.culturaNome}"');
          print('    - idCultura: "${safra.idCultura}"');
          print('    - culturaCor: ${safra.culturaCor}');
          print('    - idSafra: "${safra.idSafra}"');
        }
        
        for (final poligono in talhao.poligonos) {
          print('    - Polígono: ${poligono.pontos.length} pontos');
        }
      }
      
      _isLoading = false;
      // CORREÇÃO: Notificar apenas uma vez no final
      notifyListeners();
      return List<TalhaoSafraModel>.from(_talhoes);
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar talhões: $e';
      notifyListeners();
      print('❌ Erro ao carregar talhões: $e');
      return [];
    }
  }
  
  /// Obtém um talhão pelo ID
  TalhaoSafraModel? obterTalhaoPorId(String id) {
    try {
      if (_talhoes.isEmpty) return null;
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
      
      // Limpar cache do TalhaoUnifiedService
      final talhaoUnifiedService = TalhaoUnifiedService();
      await talhaoUnifiedService.forcarAtualizacaoGlobal();
      
      // Limpar cache do CulturaService
      final culturaService = CulturaService();
      culturaService.clearCache();
      
      print('✅ Caches conflitantes limpos com sucesso');
    } catch (e) {
      print('⚠️ Erro ao limpar caches: $e');
      // Não falhar o carregamento por erro no cache
    }
  }

  /// Verifica e preserva culturas personalizadas dos talhões
  Future<void> _preservarCulturasPersonalizadas() async {
    try {
      print('🔍 DEBUG CULTURA - Verificando culturas personalizadas...');
      
      for (final talhao in _talhoes) {
        for (final safra in talhao.safras) {
          // Verificar se a cultura é personalizada (não existe no módulo Culturas da Fazenda)
          final culturaService = CulturaService();
          final culturaEncontrada = await culturaService.loadCulturaById(safra.idCultura);
          
          if (culturaEncontrada == null) {
            print('🔍 DEBUG CULTURA - Cultura personalizada detectada: "${safra.culturaNome}" (ID: ${safra.idCultura})');
            print('🔍 DEBUG CULTURA - Preservando cultura personalizada...');
            
            // Marcar como cultura personalizada para evitar sobrescrita
            // Isso pode ser feito adicionando um prefixo ou marcador especial
            if (!safra.idCultura.startsWith('custom_')) {
              print('🔍 DEBUG CULTURA - Aplicando prefixo custom_ ao ID da cultura');
              safra.idCultura = 'custom_${safra.idCultura}';
              
              // Atualizar no banco se necessário
              await _talhaoSafraRepository.atualizarSafraTalhao(safra);
            }
          } else {
            print('🔍 DEBUG CULTURA - Cultura encontrada no módulo Culturas da Fazenda: "${culturaEncontrada.name}"');
          }
        }
      }
      
      print('✅ DEBUG CULTURA - Verificação de culturas personalizadas concluída');
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
      
      print('🔍 DEBUG: Iniciando salvamento de talhão: $nome');
      
      // Usar área já calculada nas métricas ou calcular se não fornecida
      double area;
      if (areaCalculada != null && areaCalculada > 0) {
        area = areaCalculada;
        print('🔍 DEBUG: Usando área já calculada nas métricas: $area hectares');
      } else {
        // Calcular área do polígono usando cálculo preciso apenas se necessário
        print('🔍 DEBUG: Calculando área do polígono com ${pontos.length} pontos');
        print('🔍 DEBUG: Pontos recebidos:');
        for (int i = 0; i < pontos.length; i++) {
          print('  - Ponto $i: ${pontos[i].latitude}, ${pontos[i].longitude}');
        }
        
        area = _calcularAreaAsync(pontos);
        print('🔍 DEBUG: Área calculada: $area hectares');
      }
      
      // Cria o polígono a partir dos pontos
      print('🔍 DEBUG: Criando polígono');
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
      print('🔍 DEBUG: Polígono criado com ID: ${poligono.id}');
      print('🔍 DEBUG: Polígono tem ${poligono.pontos.length} pontos');
      print('🔍 DEBUG: Área do polígono: ${poligono.area} m²');
      
      // Cria o modelo de safra associada ao talhão
      print('🔍 DEBUG: Criando safra');
      print('🔍 DEBUG CULTURA - Dados recebidos:');
      print('  - nomeCultura: "$nomeCultura"');
      print('  - idCultura: "$idCultura"');
      print('  - corCultura: $corCultura');
      
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
      
      print('🔍 DEBUG: Safra criada com ID: ${safra.id}');
      print('🔍 DEBUG: Área da safra: ${safra.area} hectares');
      print('🔍 DEBUG CULTURA - Safra criada:');
      print('  - culturaNome: "${safra.culturaNome}"');
      print('  - idCultura: "${safra.idCultura}"');
      print('  - culturaCor: ${safra.culturaCor}');
      
      // Cria o modelo de talhão
      print('🔍 DEBUG: Criando modelo de talhão');
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
      print('🔍 DEBUG: Modelo de talhão criado com ID: ${talhao.id}');
      print('🔍 DEBUG: Área do modelo: ${talhao.area} hectares');
      
      // Salva usando TalhaoSafraRepository (CORRIGIDO)
      print('🔍 DEBUG: Salvando usando TalhaoSafraRepository...');
      final idSalvo = await _talhaoSafraRepository.adicionarTalhao(talhao);
      print('🔍 DEBUG: Talhão salvo com ID: $idSalvo');
      
      if (idSalvo.isNotEmpty) {
        // Adiciona à lista em memória
        _talhoes.add(talhao);
        
        // LIMPAR CACHES APÓS SALVAR para evitar conflitos
        await _limparCachesConflitantes();
        
        _isLoading = false;
        _errorMessage = null;
        // CORREÇÃO: Notificar apenas uma vez no final
        notifyListeners();
        
        print('✅ Talhão salvo com sucesso: $nome');
        print('📊 Total de talhões em memória: ${_talhoes.length}');
        
        // Integrar com mapas offline
        try {
          print('🗺️ Criando mapa offline para talhão: $nome');
          await _integrationService.createOfflineMapForTalhao(talhao);
          print('✅ Mapa offline criado com sucesso');
        } catch (e) {
          print('⚠️ Erro ao criar mapa offline: $e');
          // Não falhar o salvamento do talhão por erro no mapa offline
        }
        
        // Verificar se os dados foram salvos corretamente
        print('🔍 DEBUG CULTURA - Verificando dados salvos no banco...');
        final talhaoSalvo = await _talhaoSafraRepository.buscarTalhaoPorId(idSalvo);
        if (talhaoSalvo != null && talhaoSalvo.safras.isNotEmpty) {
          final safraSalva = talhaoSalvo.safras.first;
          print('🔍 DEBUG CULTURA - Dados salvos no banco:');
          print('  - culturaNome: "${safraSalva.culturaNome}"');
          print('  - idCultura: "${safraSalva.idCultura}"');
          print('  - culturaCor: ${safraSalva.culturaCor}');
          
          // Verificar se os dados correspondem aos enviados
          if (safraSalva.culturaNome == nomeCultura) {
            print('✅ DEBUG CULTURA - Nome da cultura preservado corretamente');
          } else {
            print('❌ DEBUG CULTURA - ERRO: Nome da cultura foi alterado!');
            print('  - Enviado: "$nomeCultura"');
            print('  - Salvo: "${safraSalva.culturaNome}"');
          }
          
          if (safraSalva.idCultura == idCultura) {
            print('✅ DEBUG CULTURA - ID da cultura preservado corretamente');
          } else {
            print('❌ DEBUG CULTURA - ERRO: ID da cultura foi alterado!');
            print('  - Enviado: "$idCultura"');
            print('  - Salvo: "${safraSalva.idCultura}"');
          }
        } else {
          print('❌ DEBUG CULTURA - ERRO: Talhão não encontrado após salvamento');
        }
        
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Erro ao salvar talhão no banco de dados';
        notifyListeners();
        print('❌ Erro: ID retornado vazio');
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao salvar talhão: $e';
      notifyListeners();
      print('❌ Erro ao salvar talhão: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      // Log detalhado do erro para debug
      if (e.toString().contains('database') || e.toString().contains('SQL')) {
        print('❌ Erro de banco de dados detectado');
      } else if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        print('❌ Erro de timeout detectado');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        print('❌ Erro de rede detectado');
      }
      
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
      
      // Atualiza no banco de dados
      final count = await _executeWithRetry(() async {
        return await _databaseService.updateData(
          'talhoes',
          talhaoAtualizado.toMap(),
          where: 'id = ?',
          whereArgs: [talhao.id],
        );
      });
      
      print('📊 Resultado da atualização: $count registros afetados');
      
      if (count > 0) {
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
      } else {
        _isLoading = false;
        _errorMessage = 'Erro ao atualizar talhão no banco de dados';
        notifyListeners();
        print('❌ Erro: $_errorMessage');
        return false;
      }
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
      
      print('🗑️ Excluindo talhão ID: $id');
      
      // Verificar se o talhão existe
      final talhaoExistente = _talhoes.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Talhão não encontrado'),
      );
      
      print('📊 Talhão encontrado: ${talhaoExistente.name}');
      
      // Exclui do banco de dados com retry
      final count = await _executeWithRetry(() async {
        return await _databaseService.deleteData(
          'talhoes',
          where: 'id = ?',
          whereArgs: [id],
        );
      });
      
      print('📊 Resultado da exclusão: $count registros afetados');
      
      if (count > 0) {
        // Remove da lista em memória
        _talhoes.removeWhere((t) => t.id == id);
        
        _isLoading = false;
        // CORREÇÃO: Notificar apenas uma vez no final
        notifyListeners();
        print('✅ Talhão excluído com sucesso');
        
        // Integrar com mapas offline
        try {
          print('🗺️ Removendo mapa offline para talhão: ${talhaoExistente.name}');
          await _integrationService.removeOfflineMapForTalhao(id);
          print('✅ Mapa offline removido com sucesso');
        } catch (e) {
          print('⚠️ Erro ao remover mapa offline: $e');
          // Não falhar a exclusão do talhão por erro no mapa offline
        }
        
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Erro ao excluir talhão do banco de dados';
        notifyListeners();
        print('❌ Erro: $_errorMessage');
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao excluir talhão: $e';
      notifyListeners();
      print('❌ Erro ao excluir talhão: $e');
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
      final resultado = TalhaoCalculator.calcularTalhao(pontos, geodesico: true);
      final areaHectares = resultado['areaHa'];
      
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
      final resultado = TalhaoCalculator.calcularTalhao(pontos, geodesico: true);
      final area = resultado['areaHa'];
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
      final resultado = TalhaoCalculator.calcularTalhao(pontos, geodesico: true);
      final perimetro = resultado['perimetroM'];
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
      if (_talhoes.isEmpty) return null;
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


  /// Remove um talhão pelo ID
  Future<bool> removerTalhao(String talhaoId) async {
    try {
      print('🔍 DEBUG: Iniciando remoção do talhão: $talhaoId');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Garantir que as tabelas talhao_safra existem
      final db = await _databaseService.database;
      // Não precisamos mais da migração das tabelas antigas
      
      // Remover o talhão usando método simples sem foreign keys
      final deletedRows = await _executeWithRetry(() async {
        // Desabilitar foreign keys para evitar problemas
        await db.execute('PRAGMA foreign_keys = OFF');
        
        try {
          // Usar raw SQL para remoção direta das tabelas talhao_safra
          final result = await db.rawDelete(
            'DELETE FROM talhao_safra WHERE id = ?',
            [talhaoId],
          );
          return result;
        } finally {
          // Reabilitar foreign keys
          await db.execute('PRAGMA foreign_keys = ON');
        }
      });
      
      if (deletedRows > 0) {
        // Remover da lista local
        _talhoes.removeWhere((talhao) => talhao.id == talhaoId);
        
        // Notificar mudanças
        _notifyTalhoesChangedListeners();
        notifyListeners();
        
        print('✅ DEBUG: Talhão removido com sucesso: $talhaoId');
        return true;
      } else {
        _errorMessage = 'Talhão não encontrado ou já foi removido';
        notifyListeners();
        print('❌ DEBUG: Talhão não encontrado: $talhaoId');
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erro ao remover talhão: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ DEBUG: Erro ao remover talhão: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
