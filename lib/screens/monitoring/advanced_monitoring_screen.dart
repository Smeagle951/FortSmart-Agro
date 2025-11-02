import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../utils/app_colors.dart';
import '../../services/cultura_service.dart';
import '../../services/farm_culture_sync_service.dart';
import '../../services/background_service.dart';
import '../../services/talhao_unified_service.dart';
import '../../repositories/talhao_repository.dart';
import '../../models/talhao_model.dart';
import '../../models/cultura_model.dart';
import '../../models/monitoring_point.dart';
import '../../utils/logger.dart';
import '../../routes.dart';
import '../../database/app_database.dart';
import '../../utils/api_config.dart';

/// Tela de Monitoramento Avançado
class AdvancedMonitoringScreen extends StatefulWidget {
  const AdvancedMonitoringScreen({super.key});

  @override
  State<AdvancedMonitoringScreen> createState() => _AdvancedMonitoringScreenState();
}

class _AdvancedMonitoringScreenState extends State<AdvancedMonitoringScreen> {
  // Serviços
  final _culturaService = CulturaService();
  final _farmCultureSyncService = FarmCultureSyncService();
  final _talhaoRepository = TalhaoRepository();
  final _talhaoUnifiedService = TalhaoUnifiedService();
  final _backgroundService = BackgroundService();
  
  // Controladores
  late final MapController _mapController;
  
  // Estados
  bool _isLoading = true;
  bool _isDrawingMode = false;
  bool _isLoadingLocation = false;
  bool _showSatelliteLayer = false;
  bool _hasPausedSessions = false;
  
  // Dados de seleção
  TalhaoModel? _selectedTalhao;
  CulturaModel? _selectedCultura;
  DateTime _selectedDate = DateTime.now();
  
  // Dados de sessões pausadas
  List<Map<String, dynamic>> _pausedSessions = [];
  
  // Dados disponíveis
  List<TalhaoModel> _availableTalhoes = [];
  List<CulturaModel> _availableCulturas = [];
  List<LatLng> _routePoints = [];
  List<Marker> _pointMarkers = [];
  List<Polyline> _routeLines = [];

  // Localização atual
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
        _inicializarTela();
  }
  
  /// Inicializa os serviços offline
  Future<void> _inicializarServicosOffline() async {
    try {
      Logger.info('🔄 Inicializando serviços offline no monitoramento...');
      
      // Inicializar serviço de background
      await _backgroundService.initialize();
      
      // Configurar callbacks do background service usando métodos seguros
      _backgroundService.onStatusUpdate = _handleStatusUpdate;
      _backgroundService.onError = _handleError;
      _backgroundService.onProgress = _handleProgress;
      
      // Iniciar processamento em segundo plano
      await _backgroundService.startBackgroundProcessing();
      
      Logger.info('✅ Serviços offline inicializados com sucesso no monitoramento');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar serviços offline: $e');
      _safeShowSnackBar('Erro ao inicializar serviços: $e', isError: true);
    }
  }

  /// Handler para atualizações de status
  void _handleStatusUpdate(String status) {
    Logger.info('📊 Status atualizado: $status');
    _safeShowSnackBar('Status: $status');
  }

  /// Handler para erros
  void _handleError(String error) {
    Logger.error('❌ Erro no background service: $error');
    _safeShowSnackBar('Erro: $error', isError: true);
  }

  /// Handler para progresso
  void _handleProgress(Map<String, dynamic> progress) {
    Logger.info('📈 Progresso: $progress');
  }

  /// Gera um ID numérico único para o plot baseado no ID do talhão
  int _generatePlotId(String talhaoId) {
    // Se o ID já for um número, usar diretamente
    final numericId = int.tryParse(talhaoId);
    if (numericId != null && numericId > 0) {
      return numericId;
    }
    
    // Se não for um número (UUID), gerar um hash baseado no ID
    int hash = 0;
    for (int i = 0; i < talhaoId.length; i++) {
      hash = ((hash << 5) - hash) + talhaoId.codeUnitAt(i);
      hash = hash & hash; // Convert to 32bit integer
    }
    
    // Garantir que seja um número positivo e não seja 0
    final result = hash.abs();
    return result > 0 ? result : 1; // Evitar 0
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Inicializa a tela
  Future<void> _inicializarTela() async {
    try {
      setState(() => _isLoading = true);
      
      // Inicializar serviços offline
      await _inicializarServicosOffline();
      
      // Garantir que as tabelas de monitoramento existam
      await _ensureMonitoringTablesExist();
      
      // Carregar dados básicos
      await _carregarTalhoes();
      await _carregarCulturas();
      await _obterLocalizacao();
      
      // Verificar sessões pausadas
      await _verificarSessoesPausadas();
      
      setState(() => _isLoading = false);
      } catch (e) {
      print('❌ Erro ao inicializar tela: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Garante que as tabelas de monitoramento existam
  Future<void> _ensureMonitoringTablesExist() async {
    try {
      Logger.info('🔄 Verificando/criando tabelas de monitoramento...');
      
      final db = await AppDatabase().database;
      Logger.info('✅ Banco de dados obtido para criação de tabelas');
      
      // Criar tabela de sessões de monitoramento se não existir
      Logger.info('📋 Criando tabela monitoring_sessions...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monitoring_sessions (
          id TEXT PRIMARY KEY,
          fazenda_id TEXT NOT NULL,
          talhao_id TEXT NOT NULL,
          cultura_id TEXT NOT NULL,
          amostragem_padrao_plantas_por_ponto INTEGER DEFAULT 10,
          started_at DATETIME NOT NULL,
          finished_at DATETIME,
          status TEXT NOT NULL CHECK (status IN ('draft', 'finalized', 'cancelled')) DEFAULT 'draft',
          device_id TEXT,
          catalog_version TEXT,
          sync_state TEXT NOT NULL CHECK (sync_state IN ('pending', 'syncing', 'synced', 'error')) DEFAULT 'pending',
          sync_error TEXT,
          retry_count INTEGER DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      Logger.info('✅ Tabela monitoring_sessions criada/verificada');
      
      // Criar tabela de pontos de monitoramento se não existir
      Logger.info('📋 Criando tabela monitoring_points...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monitoring_points (
          id TEXT PRIMARY KEY,
          session_id TEXT NOT NULL,
          numero INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          timestamp DATETIME NOT NULL,
          plantas_avaliadas INTEGER,
          gps_accuracy REAL,
          manual_entry INTEGER DEFAULT 0,
          attachments_json TEXT,
          observacoes TEXT,
          sync_state TEXT NOT NULL CHECK (sync_state IN ('pending', 'syncing', 'synced', 'error')) DEFAULT 'pending',
          sync_error TEXT,
          retry_count INTEGER DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY(session_id) REFERENCES monitoring_sessions(id) ON DELETE CASCADE,
          UNIQUE(session_id, numero)
        )
      ''');
      Logger.info('✅ Tabela monitoring_points criada/verificada');
      
      // Verificar se as tabelas foram criadas corretamente
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name IN ('monitoring_sessions', 'monitoring_points')");
      Logger.info('📊 Tabelas encontradas: ${tables.map((t) => t['name']).join(', ')}');
      
      if (tables.length != 2) {
        Logger.error('❌ Nem todas as tabelas foram criadas. Esperado: 2, Encontrado: ${tables.length}');
        throw Exception('Falha ao criar tabelas de monitoramento');
      }
      
      Logger.info('✅ Tabelas de monitoramento verificadas/criadas com sucesso');
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar/criar tabelas de monitoramento: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      rethrow; // Re-throw para que o erro seja propagado
    }
  }

  /// Método setState seguro
  void _safeSetState(VoidCallback fn) {
      if (mounted) {
      setState(fn);
    }
  }

  /// Método showSnackBar seguro
  void _safeShowSnackBar(String message, {bool isError = false}) {
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Carrega talhões com polígonos e centraliza automaticamente
  Future<void> _carregarTalhoes() async {
    try {
      setState(() => _isLoading = true);
      
      Logger.info('🔄 Iniciando carregamento de talhões...');
      
      // Carregar talhões usando serviço unificado
      final talhoes = await _talhaoUnifiedService.carregarTalhoesParaModulo(
        nomeModulo: 'MONITORAMENTO',
        forceRefresh: true,
      );
      
      Logger.info('📊 Total de talhões carregados: ${talhoes.length}');
      
      // Debug: mostrar detalhes de cada talhão
      for (var talhao in talhoes) {
        Logger.info('🔍 Talhão: ${talhao.name} (ID: ${talhao.id})');
        Logger.info('   - Polígonos: ${talhao.poligonos.length}');
        if (talhao.poligonos.isNotEmpty) {
          Logger.info('   - Pontos no primeiro polígono: ${talhao.poligonos.first.pontos.length}');
        }
      }
      
      // Filtrar apenas talhões com polígonos válidos
      final talhoesComPoligonos = talhoes.where((talhao) => 
        talhao.poligonos.isNotEmpty && 
        talhao.poligonos.first.pontos.length >= 3
      ).toList();
      
      Logger.info('✅ Talhões com polígonos válidos: ${talhoesComPoligonos.length}');
      
            _safeSetState(() {
        _availableTalhoes = talhoesComPoligonos;
      });
      
      // Se há talhões disponíveis, centralizar no primeiro
      if (talhoesComPoligonos.isNotEmpty) {
        final primeiroTalhao = talhoesComPoligonos.first;
        _centralizarNoTalhao(primeiroTalhao);
        _safeShowSnackBar('✅ ${talhoesComPoligonos.length} talhões carregados com polígonos');
        } else {
        _safeShowSnackBar('⚠️ Nenhum talhão com polígonos válidos encontrado', isError: true);
        Logger.warning('⚠️ Nenhum talhão válido encontrado. Total carregado: ${talhoes.length}');
      }
      
      Logger.info('✅ Talhões carregados: ${talhoesComPoligonos.length} de ${talhoes.length} total');
      } catch (e) {
      Logger.error('❌ Erro ao carregar talhões: $e');
      _safeShowSnackBar('Erro ao carregar talhões: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Centraliza no talhão especificado
  void _centralizarNoTalhao(TalhaoModel talhao) {
    try {
      if (talhao.poligonos.isEmpty) return;
      
      final poligono = talhao.poligonos.first;
      final center = poligono.center;
      final zoom = 16.0;

      Logger.info('🎯 Centralizando mapa no talhão ${talhao.name}');
      
      _mapController.move(center, zoom);
      
      // Selecionar automaticamente o talhão
      _safeSetState(() {
        _selectedTalhao = talhao;
      });
      
      if (mounted) {
        _safeShowSnackBar('🎯 Centralizado no talhão: ${talhao.name}');
      }
    } catch (e) {
      Logger.error('❌ Erro ao centralizar no talhão: $e');
    }
  }

  /// Carrega culturas do módulo e da fazenda
  Future<void> _carregarCulturas() async {
    try {
      setState(() => _isLoading = true);
      
      Logger.info('🔄 Carregando culturas para monitoramento avançado...');
      
      // Carregar culturas usando o método listarCulturas que usa o CultureImportService
      final culturasModulo = await _culturaService.listarCulturas();
      
      Logger.info('📊 Culturas carregadas do módulo: ${culturasModulo.length}');
      
      // Sincronizar culturas da fazenda
      final sincronizacaoSucesso = await _farmCultureSyncService.syncFarmCulturesToMonitoring();
      
      // Usar culturas do módulo (sincronização já foi feita)
      final todasCulturas = <CulturaModel>[];
      final idsExistentes = <String>{};
      
      // Adicionar culturas do módulo
      for (var cultura in culturasModulo) {
        if (!idsExistentes.contains(cultura.id)) {
          todasCulturas.add(cultura);
          idsExistentes.add(cultura.id);
        }
      }
      
      _safeSetState(() {
        _availableCulturas = todasCulturas;
      });
      
      if (todasCulturas.isNotEmpty) {
        _safeShowSnackBar('✅ ${todasCulturas.length} culturas carregadas');
        Logger.info('✅ Culturas disponíveis:');
        for (var cultura in todasCulturas) {
          Logger.info('  - ${cultura.name} (ID: ${cultura.id})');
        }
      } else {
        _safeShowSnackBar('⚠️ Nenhuma cultura encontrada', isError: true);
        Logger.warning('⚠️ Nenhuma cultura foi carregada');
      }
      
      Logger.info('✅ Culturas carregadas: ${todasCulturas.length} (${culturasModulo.length} do módulo, sincronização: ${sincronizacaoSucesso ? 'sucesso' : 'falha'})');
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas: $e');
      _safeShowSnackBar('Erro ao carregar culturas: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Centraliza GPS
  Future<void> _centralizarGPS() async {
    try {
      setState(() => _isLoadingLocation = true);
      
      // Verificar se o GPS está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _safeShowSnackBar('GPS desabilitado. Ative o GPS nas configurações.', isError: true);
        setState(() => _isLoadingLocation = false);
        return;
      }
      
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _safeShowSnackBar('Permissão de localização negada.', isError: true);
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _safeShowSnackBar('Permissão de localização negada permanentemente.', isError: true);
        setState(() => _isLoadingLocation = false);
        return;
      }
      
      // Obter posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Centralizar mapa na posição atual
      _mapController.move(_currentPosition!, 15.0);

      // Mostrar feedback ao usuário
      _safeShowSnackBar('GPS centralizado!');

      Logger.info('✅ GPS centralizado com sucesso: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      Logger.error('❌ Erro ao centralizar GPS: $e');
      _safeShowSnackBar('Erro ao obter localização: $e', isError: true);
      setState(() => _isLoadingLocation = false);
    }
  }

  /// Centraliza no talhão selecionado
  void _centralizarNoTalhaoSelecionado() {
    if (_selectedTalhao == null || _selectedTalhao!.poligonos.isEmpty) {
      _safeShowSnackBar('Selecione um talhão válido para centralizar.', isError: true);
        return;
      }
      
    try {
      final poligono = _selectedTalhao!.poligonos.first;
      final center = poligono.center;
      final zoom = 16.0;

      Logger.info('🎯 Centralizando mapa no talhão ${_selectedTalhao!.name}');
      
      _mapController.move(center, zoom);
      
      if (mounted) {
        _safeShowSnackBar('🎯 Centralizado no talhão: ${_selectedTalhao!.name}');
      }
    } catch (e) {
      Logger.error('❌ Erro ao centralizar no talhão: $e');
    }
  }
  
  /// Obtém localização atual
  Future<void> _obterLocalizacao() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _safeSetState(() {
          _currentPosition = const LatLng(-15.5484, -54.2933);
        });
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _safeSetState(() {
            _currentPosition = const LatLng(-15.5484, -54.2933);
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _safeSetState(() {
          _currentPosition = const LatLng(-15.5484, -54.2933);
        });
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

        _safeSetState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_currentPosition!, 15.0);
    } catch (e) {
      print('❌ Erro ao obter localização: $e');
      _safeSetState(() {
        _currentPosition = const LatLng(-15.5484, -54.2933);
      });
    }
  }

  /// Verifica se há sessões de monitoramento pausadas
  Future<void> _verificarSessoesPausadas() async {
    try {
      Logger.info('🔍 Verificando sessões pausadas...');
      
      final db = await AppDatabase.instance.database;
      
      // Buscar sessões pausadas ou ativas
      final pausedSessions = await db.query(
        'monitoring_sessions',
        where: 'status IN (?, ?)',
        whereArgs: ['pausado', 'active'],
        orderBy: 'updated_at DESC',
      );
      
      Logger.info('📊 ${pausedSessions.length} sessões pausadas encontradas');
      
      setState(() {
        _pausedSessions = pausedSessions;
        _hasPausedSessions = pausedSessions.isNotEmpty;
      });
      
      if (_hasPausedSessions) {
        Logger.info('✅ Sessões pausadas detectadas - mostrando interface de continuação');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar sessões pausadas: $e');
      setState(() {
        _hasPausedSessions = false;
        _pausedSessions = [];
      });
    }
  }

  /// Continua uma sessão pausada
  Future<void> _continuarSessaoPausada(Map<String, dynamic> sessao) async {
    try {
      Logger.info('🔄 Continuando sessão pausada: ${sessao['id']}');
      
      final db = await AppDatabase.instance.database;
      
      // Buscar pontos já registrados da sessão
      final existingPoints = await db.query(
        'monitoring_points',
        where: 'session_id = ?',
        whereArgs: [sessao['id']],
        orderBy: 'numero ASC',
      );
      
      Logger.info('📊 ${existingPoints.length} pontos encontrados na sessão');
      
      // Converter pontos para formato LatLng
      List<LatLng> pontosLatLng = existingPoints.map((p) {
        return LatLng(
          p['latitude'] as double,
          p['longitude'] as double,
        );
      }).toList();
      
      // Se não houver pontos, criar um ponto virtual para monitoramento livre
      if (pontosLatLng.isEmpty) {
        Logger.info('ℹ️ Nenhum ponto encontrado - criando ponto virtual para monitoramento livre');
        // Usar posição atual ou posição padrão
        pontosLatLng = [_currentPosition ?? const LatLng(-15.5484, -54.2933)];
      }
      
      // Marcar sessão como ativa novamente
      await db.update(
        'monitoring_sessions',
        {
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [sessao['id']],
      );
      
      // Determinar próximo ponto
      final proximoPontoNumero = existingPoints.length + 1;
      
      // Navegar para a tela de monitoramento
      final result = await Navigator.pushNamed(
        context,
        AppRoutes.monitoringPoint,
        arguments: {
          'pontoId': proximoPontoNumero,
          'talhaoId': sessao['talhao_id'],
          'culturaId': sessao['cultura_id'],
          'talhaoNome': sessao['talhao_nome'] ?? 'Talhão ${sessao['talhao_id']}',
          'culturaNome': sessao['cultura_nome'] ?? 'Cultura',
          'pontos': pontosLatLng, // Passar pontos existentes
          'sessionId': sessao['id'],
          'isContinuing': true,
          'monitoringData': sessao,
          'data': DateTime.now(),
        },
      );
      
      // Recarregar sessões após retornar
      if (result == true) {
        await _verificarSessoesPausadas();
        _safeShowSnackBar('Monitoramento continuado com sucesso!');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao continuar sessão: $e');
      _safeShowSnackBar('Erro ao continuar monitoramento: $e', isError: true);
    }
  }

  /// Verifica se um ponto está dentro do talhão selecionado
  bool _isPointInsideTalhao(LatLng point) {
    if (_selectedTalhao == null || _selectedTalhao!.poligonos.isEmpty) {
      return false;
    }

    // Verificar se o ponto está dentro de algum polígono do talhão
    for (var poligono in _selectedTalhao!.poligonos) {
      if (_isPointInPolygon(point, poligono.pontos)) {
        return true;
      }
    }
    return false;
  }

  /// Algoritmo para verificar se um ponto está dentro de um polígono
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersections = 0;
    int n = polygon.length;

    for (int i = 0; i < n; i++) {
      LatLng p1 = polygon[i];
      LatLng p2 = polygon[(i + 1) % n];

      if (p1.longitude > p2.longitude) {
        LatLng temp = p1;
        p1 = p2;
        p2 = temp;
      }

      if (point.longitude >= p1.longitude && point.longitude < p2.longitude) {
        double intersectionLat = p1.latitude + 
            (point.longitude - p1.longitude) * (p2.latitude - p1.latitude) / 
            (p2.longitude - p1.longitude);
        
        if (point.latitude <= intersectionLat) {
          intersections++;
        }
      }
    }

    return (intersections % 2) == 1;
  }

  /// Adiciona ponto ao mapa
  void _addPointToMap(LatLng point) {
    // Verificar se há um talhão selecionado
    if (_selectedTalhao == null) {
      _safeShowSnackBar('Selecione um talhão antes de desenhar pontos.', isError: true);
        return;
      }

    // Verificar se o ponto está dentro do talhão selecionado
    if (!_isPointInsideTalhao(point)) {
      _safeShowSnackBar('Ponto deve estar dentro do talhão selecionado.', isError: true);
      return;
    }

    _safeSetState(() {
      _routePoints.add(point);
      _pointMarkers.add(_createPointMarker(point, _routePoints.length - 1));
      _updateRouteLines();
    });
    
    _safeShowSnackBar('Ponto adicionado!');
    Logger.info('📍 Ponto adicionado: ${point.latitude}, ${point.longitude}');
  }
  
  /// Cria marcador de ponto
  Marker _createPointMarker(LatLng point, int index) {
    return Marker(
      point: point,
      width: 30,
      height: 30,
              child: GestureDetector(
          onTap: () {
            if (mounted && context.mounted) {
              _selectPoint(index);
            }
          },
          child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Seleciona um ponto
  void _selectPoint(int index) {
    if (index >= 0 && index < _routePoints.length) {
      _safeShowSnackBar('Ponto ${index + 1} selecionado');
      Logger.info('📍 Ponto selecionado: ${index + 1}');
    }
  }

  /// Atualiza linhas da rota
  void _updateRouteLines() {
    _routeLines.clear();
    if (_routePoints.length > 1) {
      _routeLines.add(
        Polyline(
          points: _routePoints,
          strokeWidth: 3.0,
          color: Colors.red,
        ),
      );
    }
  }

  /// Remove último ponto
  void _removeLastPoint() {
    if (_routePoints.isNotEmpty) {
      _safeSetState(() {
        _routePoints.removeLast();
        _pointMarkers.removeLast();
        _updateRouteLines();
      });
    }
  }

  /// Remove todos os pontos
  void _removeAllPoints() {
    _safeSetState(() {
      _routePoints.clear();
      _pointMarkers.clear();
      _routeLines.clear();
    });
    _safeShowSnackBar('Todos os pontos removidos');
  }

  /// Limpa todos os pontos
  void _clearAllPoints() {
    _removeAllPoints();
  }

  /// Toggle modo de desenho
  void _toggleDrawingMode() {
    _safeSetState(() {
      _isDrawingMode = !_isDrawingMode;
    });
  }

  /// Toggle camada de satélite
  void _toggleSatelliteLayer() {
    _safeSetState(() {
      _showSatelliteLayer = !_showSatelliteLayer;
    });
    _safeShowSnackBar(_showSatelliteLayer ? 'Camada de satélite ativada' : 'Mapa normal ativado');
    Logger.info('🛰️ Camada de satélite: ${_showSatelliteLayer ? 'ATIVADA' : 'DESATIVADA'}');
  }
  
  /// Verifica se pode iniciar monitoramento
  bool _canStartMonitoring() {
    return _selectedTalhao != null && _selectedCultura != null && _routePoints.isNotEmpty;
  }
  
  /// Inicia monitoramento e prepara dados para tela de ponto de monitoramento
  void _startMonitoring() {
    if (!_canStartMonitoring()) {
      String errorMessage = '';
      if (_selectedTalhao == null) errorMessage += 'Selecione um talhão. ';
      if (_selectedCultura == null) errorMessage += 'Selecione uma cultura. ';
      if (_routePoints.isEmpty) errorMessage += 'Adicione pontos de monitoramento. ';
      
        _safeShowSnackBar('Não é possível iniciar monitoramento: $errorMessage', isError: true);
      return;
      }

    if (_routePoints.length < 1) {
      _safeShowSnackBar('Desenhe pelo menos 1 ponto no mapa.', isError: true);
      return;
    }
    
    // Preparar dados para tela de ponto de monitoramento
    final monitoringData = {
      'talhao': _selectedTalhao,
      'cultura': _selectedCultura,
      'pontos': _routePoints,
      'data': _selectedDate,
      'plotId': _generatePlotId(_selectedTalhao!.id),
      'poligonos': _selectedTalhao!.poligonos,
      'area': _selectedTalhao!.area,
    };

    _safeShowSnackBar('Monitoramento iniciado! Navegando para tela de pontos...');
    Logger.info('🚀 Monitoramento iniciado para talhão: ${_selectedTalhao!.name}');
    Logger.info('📊 Pontos desenhados: ${_routePoints.length}');
    Logger.info('🌱 Cultura selecionada: ${_selectedCultura!.name}');
    Logger.info('📅 Data selecionada: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}');
    Logger.info('🆔 Plot ID gerado: ${monitoringData['plotId']}');
    
    // Navegar para o primeiro ponto de monitoramento
    _navigateToFirstMonitoringPoint();
  }
  
  /// Navega para o primeiro ponto de monitoramento
  void _navigateToFirstMonitoringPoint() async {
    if (_routePoints.isEmpty || _selectedTalhao == null || _selectedCultura == null) {
      _safeShowSnackBar('Erro: Dados insuficientes para navegação', isError: true);
      return;
    }
    
    try {
      // Debug: Verificar o ID real do talhão
      Logger.info('🔍 ID do talhão selecionado: "${_selectedTalhao!.id}" (tipo: ${_selectedTalhao!.id.runtimeType})');
      
      // Usar ID do talhão como string (UUID) - não converter para int
      final talhaoIdString = _selectedTalhao!.id;
      final culturaIdString = _selectedCultura!.id;
      
      Logger.info('🔍 Usando ID do talhão como string: $talhaoIdString');
      Logger.info('🔍 Cultura ID: $culturaIdString');
      
      // Validar se o ID não está vazio
      if (talhaoIdString.isEmpty) {
        Logger.error('❌ ID do talhão está vazio');
        _safeShowSnackBar('Erro: ID do talhão está vazio', isError: true);
        return;
      }
      
      // Validar se a cultura ID é válida (não vazio)
      if (culturaIdString.isEmpty) {
        Logger.error('❌ ID da cultura está vazio: ${_selectedCultura!.id}');
        _safeShowSnackBar('Erro: ID da cultura está vazio', isError: true);
        return;
      }
      
      // Criar ou obter ponto de monitoramento usando ID string
      final pontoId = await _createOrGetMonitoringPointString(talhaoIdString);
      
      if (pontoId == 0) {
        Logger.warning('⚠️ Tentando método alternativo de criação de ponto...');
        // Tentar método alternativo mais simples
        final pontoIdAlternativo = await _createSimpleMonitoringPoint(talhaoIdString);
        
        if (pontoIdAlternativo == 0) {
          _safeShowSnackBar('Erro: Não foi possível criar ponto de monitoramento', isError: true);
          return;
        }
        
        // Usar o ID alternativo
      // ✅ OBTER SESSION ID ANTES DE PASSAR
      final sessionId = await _createOrGetMonitoringSession(
        talhaoIdString,
      );
      Logger.info('🎯 [ADVANCED_MON] SessionId criado/obtido: $sessionId');
      
        final arguments = {
          'pontoId': pontoIdAlternativo,
          'talhaoId': talhaoIdString,
          'culturaId': culturaIdString,
          'talhaoNome': _selectedTalhao!.name,
          'culturaNome': _selectedCultura!.name,
          'pontos': _routePoints,
          'data': _selectedDate,
        'sessionId': sessionId, // ✅ PASSAR SESSION ID
        };
        
      Logger.info('📋 [ADVANCED_MON] Argumentos preparados (método alternativo):');
        Logger.info('  - pontoId: $pontoIdAlternativo (${pontoIdAlternativo.runtimeType})');
        Logger.info('  - talhaoId: $talhaoIdString (${talhaoIdString.runtimeType})');
        Logger.info('  - culturaId: $culturaIdString (${culturaIdString.runtimeType})');
        Logger.info('  - talhaoNome: ${_selectedTalhao!.name}');
        Logger.info('  - culturaNome: ${_selectedCultura!.name}');
      Logger.info('  - sessionId: $sessionId ✅');
        Logger.info('  - pontos: ${_routePoints.length} pontos');
        Logger.info('  - data: ${_selectedDate}');
        
        // Navegar para a tela de ponto de monitoramento
        Logger.info('🚀 Navegando para tela de ponto de monitoramento (método alternativo)...');
        
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.monitoringPoint,
          arguments: arguments,
        );
        
        // Callback executado quando volta da tela de monitoramento
        _safeShowSnackBar('Monitoramento finalizado!');
        Logger.info('✅ Retornou da tela de monitoramento: $result');
        return;
      }
      
      Logger.info('✅ Ponto de monitoramento criado: $pontoId');
      
      // Preparar argumentos para a tela de ponto de monitoramento
      // Usar o ID original do talhão (string) para compatibilidade
      // ✅ OBTER SESSION ID ANTES DE PASSAR
      final sessionId = await _createOrGetMonitoringSession(
        talhaoIdString,
      );
      Logger.info('🎯 [ADVANCED_MON] SessionId criado/obtido: $sessionId');
      
      final arguments = {
        'pontoId': pontoId,
        'talhaoId': talhaoIdString, // Usar ID original (string)
        'culturaId': culturaIdString,
        'talhaoNome': _selectedTalhao!.name,
        'culturaNome': _selectedCultura!.name,
        'pontos': _routePoints,
        'data': _selectedDate,
        'sessionId': sessionId, // ✅ PASSAR SESSION ID
      };
      
      Logger.info('📋 [ADVANCED_MON] Argumentos preparados:');
      Logger.info('  - pontoId: $pontoId (${pontoId.runtimeType})');
      Logger.info('  - talhaoId: $talhaoIdString (${talhaoIdString.runtimeType})');
      Logger.info('  - culturaId: $culturaIdString (${culturaIdString.runtimeType})');
      Logger.info('  - talhaoNome: ${_selectedTalhao!.name}');
      Logger.info('  - culturaNome: ${_selectedCultura!.name}');
      Logger.info('  - sessionId: $sessionId ✅');
      Logger.info('  - pontos: ${_routePoints.length} pontos');
      Logger.info('  - data: ${_selectedDate}');
      
      // Navegar para a tela de ponto de monitoramento
      Logger.info('🚀 Navegando para tela de ponto de monitoramento...');
      
      final result = await Navigator.pushNamed(
        context,
        AppRoutes.monitoringPoint,
        arguments: arguments,
      );
      
      // Callback executado quando volta da tela de monitoramento
      _safeShowSnackBar('Monitoramento finalizado!');
      Logger.info('✅ Retornou da tela de monitoramento: $result');
      
    } catch (e) {
      Logger.error('❌ Erro ao navegar para ponto de monitoramento: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      _safeShowSnackBar('Erro ao abrir monitoramento: $e', isError: true);
    }
  }
  
  /// Cria ou obtém um ponto de monitoramento real (versão com ID string)
  Future<int> _createOrGetMonitoringPointString(String talhaoId) async {
    try {
      Logger.info('🔄 Iniciando criação de ponto de monitoramento para talhão: $talhaoId');
      
      final db = await AppDatabase().database;
      Logger.info('✅ Banco de dados obtido com sucesso');
      
      // Garantir que as tabelas existam antes de tentar usar
      await _ensureMonitoringTablesExist();
      Logger.info('✅ Tabelas de monitoramento verificadas');
      
      // Usar a nova estrutura de monitoramento com sessões
      // Primeiro, criar ou obter uma sessão de monitoramento
      final sessionId = await _createOrGetMonitoringSession(talhaoId);
      Logger.info('🔍 SessionId obtido: $sessionId');
      
      if (sessionId.isEmpty) {
        Logger.error('❌ Não foi possível criar/obter sessão de monitoramento');
        return 0;
      }
      
      // Verificar se já existe um ponto para esta sessão
      Logger.info('🔍 Verificando pontos existentes para sessão: $sessionId');
      final existingPoints = await db.query(
        'monitoring_points',
        columns: ['id'],
        where: 'session_id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      
      if (existingPoints.isNotEmpty) {
        final existingId = existingPoints.first['id'] as String;
        Logger.info('✅ Ponto de monitoramento existente encontrado: $existingId');
        // Retornar um ID numérico baseado no hash da string
        final numericId = existingId.hashCode.abs();
        Logger.info('🔢 ID numérico gerado: $numericId');
        return numericId;
      }
      
      // Criar novo ponto de monitoramento
      Logger.info('🆕 Criando novo ponto de monitoramento...');
      final newPointId = const Uuid().v4();
      Logger.info('🆔 Novo ID gerado: $newPointId');
      
      // Verificar se temos pontos desenhados
      if (_routePoints.isEmpty) {
        Logger.error('❌ Nenhum ponto desenhado no mapa');
        return 0;
      }
      
      final firstPoint = _routePoints.first;
      Logger.info('📍 Primeiro ponto: ${firstPoint.latitude}, ${firstPoint.longitude}');
      
      // Inserir novo ponto
      final insertData = {
        'id': newPointId,
        'session_id': sessionId,
        'numero': 1,
        'latitude': firstPoint.latitude,
        'longitude': firstPoint.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'plantas_avaliadas': 10, // Valor padrão
        'gps_accuracy': 5.0, // Valor padrão
        'manual_entry': 0,
        'observacoes': 'Ponto criado via monitoramento avançado',
        'sync_state': 'pending',
      };
      
      Logger.info('💾 Inserindo dados: $insertData');
      await db.insert('monitoring_points', insertData);
      Logger.info('✅ Ponto inserido no banco de dados');
      
      // Verificar se foi inserido corretamente
      final insertedPoint = await db.query(
        'monitoring_points',
        where: 'id = ?',
        whereArgs: [newPointId],
        limit: 1,
      );
      
      if (insertedPoint.isEmpty) {
        Logger.error('❌ Ponto não foi inserido corretamente');
        return 0;
      }
      
      Logger.info('✅ Novo ponto de monitoramento criado com sucesso: $newPointId para sessão: $sessionId');
      
      // Retornar um ID numérico baseado no hash da string
      final numericId = newPointId.hashCode.abs();
      Logger.info('🔢 ID numérico final: $numericId');
      return numericId;
      
    } catch (e) {
      Logger.error('❌ Erro ao criar/obter ponto de monitoramento: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      return 0;
    }
  }

  /// Cria ou obtém uma sessão de monitoramento
  Future<String> _createOrGetMonitoringSession(String talhaoId, {
    double? temperatura,
    double? umidade,
  }) async {
    Logger.info('🚨 [ADVANCED_MON] ========================================');
    Logger.info('🚨 [ADVANCED_MON] FUNÇÃO CHAMADA! _createOrGetMonitoringSession');
    Logger.info('🚨 [ADVANCED_MON] Talhão ID recebido: $talhaoId');
    Logger.info('🚨 [ADVANCED_MON] ========================================');
    
    try {
      Logger.info('🔄 [ADVANCED_MON] Iniciando criação/obtenção de sessão');
      Logger.info('🔄 [ADVANCED_MON] Talhão Nome: ${_selectedTalhao?.name ?? "NULL"}');
      Logger.info('🔄 [ADVANCED_MON] Cultura Nome: ${_selectedCultura?.name ?? "NULL"}');
      
      final db = await AppDatabase().database;
      Logger.info('✅ [ADVANCED_MON] Banco de dados obtido');
      
      // Verificar se já existe uma sessão ativa para este talhão
      Logger.info('🔍 [ADVANCED_MON] Verificando sessões existentes (active ou pausado)...');
      final existingSessions = await db.query(
        'monitoring_sessions',
        columns: ['id'],
        where: 'talhao_id = ? AND status IN (?, ?)',
        whereArgs: [talhaoId, 'active', 'pausado'],
        limit: 1,
      );
      
      Logger.info('🔍 [ADVANCED_MON] Sessões encontradas: ${existingSessions.length}');
      
      if (existingSessions.isNotEmpty) {
        final existingId = existingSessions.first['id'] as String;
        Logger.info('✅ [ADVANCED_MON] Sessão existente encontrada: $existingId');
        return existingId;
      }
      
      // Criar nova sessão de monitoramento
      Logger.info('🆕 [ADVANCED_MON] Criando NOVA sessão de monitoramento...');
      final newSessionId = const Uuid().v4();
      Logger.info('🆔 [ADVANCED_MON] Novo ID gerado: $newSessionId');
      
      // Verificar se temos cultura selecionada
      if (_selectedCultura == null) {
        Logger.error('❌ [ADVANCED_MON] ERRO: Nenhuma cultura selecionada!');
        return '';
      }
      
      if (_selectedTalhao == null) {
        Logger.error('❌ [ADVANCED_MON] ERRO: Nenhum talhão selecionado!');
        return '';
      }
      
      final now = DateTime.now().toIso8601String();
      
      final sessionData = {
        'id': newSessionId,
        'fazenda_id': 'fazenda_default',
        'talhao_id': talhaoId,
        'cultura_id': _selectedCultura!.id,
        'talhao_nome': _selectedTalhao!.name,
        'cultura_nome': _selectedCultura!.name,
        'total_pontos': 0,
        'total_ocorrencias': 0,
        'amostragem_padrao_plantas_por_ponto': 10,
        'data_inicio': now,
        'started_at': now,
        'data_fim': null,
        'finished_at': null,
        'status': 'draft', // ✅ USAR 'draft' (aceito pela constraint)
        'tecnico_nome': 'Técnico',
        'observacoes': null,
        'device_id': 'device_default',
        'catalog_version': '1.0.0',
        'sync_state': 'pending',
        'created_at': now,
        'updated_at': now,
      };
      
      Logger.info('💾 [ADVANCED_MON] Inserindo sessão no banco...');
      Logger.info('💾 [ADVANCED_MON] Dados: $sessionData');
      
      await db.insert('monitoring_sessions', sessionData);
      
      Logger.info('✅ [ADVANCED_MON] INSERT executado!');
      
      // Verificar se foi inserida corretamente
      final insertedSession = await db.query(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [newSessionId],
        limit: 1,
      );
      
      Logger.info('🔍 [ADVANCED_MON] Verificando inserção: ${insertedSession.length} registro(s)');
      
      if (insertedSession.isEmpty) {
        Logger.error('❌ [ADVANCED_MON] ERRO CRÍTICO: Sessão não foi inserida!');
        return '';
      }
      
      Logger.info('✅ [ADVANCED_MON] ========================================');
      Logger.info('✅ [ADVANCED_MON] SESSÃO CRIADA COM SUCESSO!');
      Logger.info('✅ [ADVANCED_MON] ID: $newSessionId');
      Logger.info('✅ [ADVANCED_MON] Talhão: ${insertedSession.first['talhao_nome']}');
      Logger.info('✅ [ADVANCED_MON] Cultura: ${insertedSession.first['cultura_nome']}');
      Logger.info('✅ [ADVANCED_MON] Status: ${insertedSession.first['status']}');
      Logger.info('✅ [ADVANCED_MON] ========================================');
      
      return newSessionId;
      
    } catch (e, stack) {
      Logger.error('❌ [ADVANCED_MON] ERRO CRÍTICO ao criar sessão: $e');
      Logger.error('❌ [ADVANCED_MON] Stack: $stack');
      return '';
    }
  }

  /// Método alternativo simples para criar ponto de monitoramento
  Future<int> _createSimpleMonitoringPoint(String talhaoId) async {
    try {
      Logger.info('🔄 Método alternativo: Criando ponto de monitoramento simples...');
      
      // Gerar um ID simples baseado no timestamp
      final pontoId = DateTime.now().millisecondsSinceEpoch;
      Logger.info('🆔 ID simples gerado: $pontoId');
      
      // Verificar se temos pontos desenhados
      if (_routePoints.isEmpty) {
        Logger.error('❌ Nenhum ponto desenhado no mapa');
        return 0;
      }
      
      final firstPoint = _routePoints.first;
      Logger.info('📍 Primeiro ponto: ${firstPoint.latitude}, ${firstPoint.longitude}');
      
      // Tentar salvar em uma tabela simples (se existir)
      try {
        final db = await AppDatabase().database;
        
        // Criar tabela simples se não existir
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pontos_monitoramento_simples (
            id INTEGER PRIMARY KEY,
            talhao_id TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            data_criacao TEXT NOT NULL,
            ativo INTEGER DEFAULT 1
          )
        ''');
        
        // Inserir ponto
        await db.insert('pontos_monitoramento_simples', {
          'id': pontoId,
          'talhao_id': talhaoId,
          'latitude': firstPoint.latitude,
          'longitude': firstPoint.longitude,
          'data_criacao': DateTime.now().toIso8601String(),
          'ativo': 1,
        });
        
        Logger.info('✅ Ponto simples salvo no banco de dados');
      } catch (e) {
        Logger.warning('⚠️ Não foi possível salvar no banco, mas continuando com ID: $e');
      }
      
      Logger.info('✅ Ponto de monitoramento simples criado: $pontoId');
      return pontoId;
      
    } catch (e) {
      Logger.error('❌ Erro no método alternativo: $e');
      return 0;
    }
  }

  /// Cria ou obtém um ponto de monitoramento real (versão com ID int - mantida para compatibilidade)
  Future<int> _createOrGetMonitoringPoint(int talhaoId) async {
    try {
      final db = await AppDatabase().database;
      
      // Verificar se já existe um ponto para este talhão
      final existingPoints = await db.query(
        'pontos_monitoramento',
        columns: ['id'],
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        limit: 1,
      );
      
      if (existingPoints.isNotEmpty) {
        final existingId = existingPoints.first['id'] as int;
        Logger.info('✅ Ponto de monitoramento existente encontrado: $existingId');
        return existingId;
      }
      
      // Criar novo ponto de monitoramento
      final newPointId = DateTime.now().millisecondsSinceEpoch;
      
      await db.insert('pontos_monitoramento', {
        'id': newPointId,
        'talhao_id': talhaoId, // Usar int para compatibilidade com tabela
        'latitude': _routePoints.isNotEmpty ? _routePoints.first.latitude : 0.0,
        'longitude': _routePoints.isNotEmpty ? _routePoints.first.longitude : 0.0,
        'data_criacao': DateTime.now().toIso8601String(),
        'ativo': 1,
      });
      
      Logger.info('✅ Novo ponto de monitoramento criado: $newPointId');
      return newPointId;
      
    } catch (e) {
      Logger.error('❌ Erro ao criar/obter ponto de monitoramento: $e');
      return 0;
    }
  }
  
  /// Mostra diálogo de monitoramento concluído
  void _showMonitoringCompletedDialog() {
    if (!mounted || !context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Monitoramento Concluído',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O monitoramento do talhão "${_selectedTalhao?.name ?? 'Selecionado'}" foi concluído com sucesso!',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'Os dados foram salvos e enviados para análise.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Próximos passos:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text('• Análise e Alertas', style: TextStyle(fontSize: 13)),
              const Text('• Mapa de Infestação', style: TextStyle(fontSize: 13)),
              const Text('• Histórico de Monitoramento', style: TextStyle(fontSize: 13)),
            ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (mounted && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
        );
      },
    );
  }


  /// Diagnostica dados
  Future<void> _diagnosticarDados() async {
    try {
      Logger.info('🔍 Iniciando diagnóstico de dados...');
      
      // Verificar talhões
      final talhoes = await _talhaoRepository.getTalhoes();
      Logger.info('📊 Talhões encontrados: ${talhoes.length}');
      
      for (var talhao in talhoes) {
        Logger.info('  - ${talhao.name}: ${talhao.poligonos.length} polígonos');
        if (talhao.poligonos.isNotEmpty) {
          final poligono = talhao.poligonos.first;
          Logger.info('    Centro: ${poligono.center.latitude}, ${poligono.center.longitude}');
          Logger.info('    Pontos: ${poligono.pontos.length}');
        }
      }
      
      // Verificar culturas
      final culturas = await _culturaService.loadCulturas();
      Logger.info('🌱 Culturas encontradas: ${culturas.length}');
      
      for (var cultura in culturas) {
        Logger.info('  - ${cultura.name}');
      }
      
      // Verificar localização
      if (_currentPosition != null) {
        Logger.info('📍 Localização atual: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      } else {
        Logger.warning('⚠️ Localização não disponível');
      }
      
      Logger.info('✅ Diagnóstico concluído');
      _safeShowSnackBar('Diagnóstico concluído. Verifique os logs.');
      
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico: $e');
      _safeShowSnackBar('Erro no diagnóstico: $e', isError: true);
    }
  }

  /// Sincroniza culturas
  Future<void> _sincronizarCulturas() async {
    try {
      setState(() => _isLoading = true);
      
      if (mounted && context.mounted) {
        _safeShowSnackBar('🔄 Sincronizando culturas da fazenda...');
      }
      
      // Sincronizar culturas
      final culturasSincronizadas = await _farmCultureSyncService.syncFarmCulturesToMonitoring();
      
      // Recarregar culturas
      if (mounted && context.mounted) await _carregarCulturas();
      
      // Mostrar resultado
      if (mounted && context.mounted) {
        _safeShowSnackBar('✅ Culturas sincronizadas com sucesso!');
      }
    } catch (e) {
      print('❌ Erro ao sincronizar culturas: $e');
      if (mounted && context.mounted) {
        _safeShowSnackBar('❌ Erro ao sincronizar culturas: $e', isError: true);
      }
    } finally {
      if (mounted && context.mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Constrói seção de configuração
  Widget _buildConfigSection() {
    return Card(
      margin: const EdgeInsets.all(4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Configuração do Monitoramento',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
                  value: _selectedTalhao?.id,
                  decoration: const InputDecoration(
                    labelText: 'Talhão *',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Selecione o talhão'),
                  items: _availableTalhoes.map((t) => DropdownMenuItem<String>(
                        value: t.id,
                child: Text(t.name),
                      )).toList(),
                  onChanged: (value) {
                final talhaoSelecionado = _availableTalhoes.firstWhere(
                          (t) => t.id == value,
                        );
                setState(() {
                  _selectedTalhao = talhaoSelecionado;
                });
                // Centralizar automaticamente no talhão selecionado
                _centralizarNoTalhao(talhaoSelecionado);
              },
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
                  value: _selectedCultura?.id,
                  decoration: const InputDecoration(
                    labelText: 'Cultura *',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Selecione a cultura'),
                  items: _availableCulturas.map((c) => DropdownMenuItem<String>(
                    value: c.id,
                child: Text(c.name),
                  )).toList(),
                  onChanged: (value) {
                setState(() {
                      _selectedCultura = _availableCulturas.firstWhere(
                        (c) => c.id == value,
                      );
                    });
                  },
                ),
            const SizedBox(height: 4),
            _buildDateField(),
        ],
        ),
      ),
    );
  }

  /// Constrói banner para mostrar sessões pausadas
  Widget _buildPausedSessionsBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.orange[50],
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pause_circle_filled, color: Colors.orange[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoramento Pausado',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        Text(
                          '${_pausedSessions.length} sessão(ões) aguardando continuação',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Lista de sessões pausadas (máximo 3)
              ...(_pausedSessions.take(3).map((sessao) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Talhão: ${sessao['talhao_nome'] ?? sessao['talhao_id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Iniciado: ${_formatSessionDate(sessao['data_inicio'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _continuarSessaoPausada(sessao),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Continuar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ))).toList(),
              
              // Botão para ver todas as sessões se houver mais de 3
              if (_pausedSessions.length > 3)
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/monitoring/history-v2');
                    },
                    child: Text(
                      'Ver todas as ${_pausedSessions.length} sessões pausadas',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatar data da sessão
  String _formatSessionDate(dynamic data) {
    try {
      if (data == null) return 'Data não disponível';
      
      DateTime date;
      if (data is String) {
        date = DateTime.parse(data);
      } else if (data is DateTime) {
        date = data;
      } else {
        return 'Data inválida';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Hoje às ${DateFormat('HH:mm').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Ontem às ${DateFormat('HH:mm').format(date)}';
      } else {
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
    } catch (e) {
      return 'Data inválida';
    }
  }
  
  /// Constrói campo de data
  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        if (mounted) {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) {
            setState(() {
              _selectedDate = date;
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
            const SizedBox(width: 6),
            Text(
              'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Constrói seção de seleção
  Widget _buildSelectionSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            const Text(
              'Seleção de Dados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
          if (mounted && context.mounted) {
                        _carregarTalhoes();
          }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recarregar Talhões'),
        style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
          onPressed: () {
            if (mounted && context.mounted) {
                        _sincronizarCulturas();
                      }
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Sincronizar Culturas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
          onPressed: () {
            if (mounted && context.mounted) {
                    _diagnosticarDados();
            }
          },
                icon: const Icon(Icons.bug_report),
                label: const Text('Diagnosticar Dados'),
                style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
        ),
        const SizedBox(height: 16),
            if (_selectedTalhao != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Talhão Selecionado: ${_selectedTalhao!.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Área: ${_selectedTalhao!.area?.toStringAsFixed(2) ?? 'N/A'} hectares'),
              Text('Polígonos: ${_selectedTalhao!.poligonos.length}'),
            ],
            if (_selectedCultura != null) ...[
              const SizedBox(height: 8),
              Text(
                'Cultura Selecionada: ${_selectedCultura!.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói seção do mapa
  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _currentPosition ?? const LatLng(-15.7801, -47.9292),
            zoom: 15.0,
            onTap: _isDrawingMode ? (_, point) => _addPointToMap(point) : null,
          ),
              children: [
            TileLayer(
              urlTemplate: _showSatelliteLayer
                  ? APIConfig.getMapTilerUrl('satellite')
                  : APIConfig.getMapTilerUrl('streets'),
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            
            // Polígonos do talhão selecionado
            if (_selectedTalhao != null && _selectedTalhao!.poligonos.isNotEmpty)
              PolygonLayer(
                polygons: _selectedTalhao!.poligonos.map((poligono) => Polygon(
                  points: poligono.pontos,
                  borderStrokeWidth: 3.0,
                  borderColor: Colors.blue,
                  color: Colors.blue.withOpacity(0.2),
                )).toList(),
              ),

            // Polylines dos pontos de monitoramento
            if (_routeLines.isNotEmpty)
              PolylineLayer(
                polylines: _routeLines,
              ),

            // Marcadores dos pontos de monitoramento
            if (_pointMarkers.isNotEmpty)
              MarkerLayer(
                markers: _pointMarkers,
              ),

            // Marcador da localização atual
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
        point: _currentPosition!,
        child: Container(
          decoration: BoxDecoration(
                        color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Constrói botões flutuantes
  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botão GPS
        FloatingActionButton(
          onPressed: _isLoadingLocation ? null : _centralizarGPS,
          backgroundColor: _isLoadingLocation ? Colors.grey : Colors.blue,
          child: _isLoadingLocation
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Icon(Icons.my_location, color: Colors.white),
        ),
        const SizedBox(height: 16),

        // Botão lápis/desenho
        FloatingActionButton(
          onPressed: _toggleDrawingMode,
          backgroundColor: _isDrawingMode ? Colors.orange : Colors.green,
          child: Icon(_isDrawingMode ? Icons.edit_off : Icons.edit_location, color: Colors.white),
        ),
        const SizedBox(height: 16),

        // Botão desfazer
        FloatingActionButton(
          onPressed: _routePoints.isNotEmpty ? _removeLastPoint : null,
          backgroundColor: _routePoints.isNotEmpty ? Colors.orange : Colors.grey,
          child: const Icon(Icons.undo, color: Colors.white),
        ),
        const SizedBox(height: 16),

        // Botão deletar
        FloatingActionButton(
          onPressed: _routePoints.isNotEmpty ? _clearAllPoints : null,
          backgroundColor: _routePoints.isNotEmpty ? Colors.red : Colors.grey,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
      ],
    );
  }

  /// Constrói botões de iniciar
  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            // Botão Monitoramento Guiado (com pontos)
            ElevatedButton(
              onPressed: _canStartMonitoring() ? _startMonitoring : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canStartMonitoring() 
                    ? Colors.green.withOpacity(0.9) 
                    : Colors.grey.withOpacity(0.6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _canStartMonitoring() ? Icons.play_arrow : Icons.settings,
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _canStartMonitoring() 
                        ? 'Monitoramento Guiado (${_routePoints.length} pontos)' 
                        : 'Configure os dados acima',
                    style: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Botão Monitoramento Livre (sem pontos)
            ElevatedButton(
              onPressed: _selectedTalhao != null && _selectedCultura != null 
                  ? _startFreeMonitoring 
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTalhao != null && _selectedCultura != null
                    ? Colors.orange.withOpacity(0.9) 
                    : Colors.grey.withOpacity(0.6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.explore,
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTalhao != null && _selectedCultura != null
                        ? 'Monitoramento Livre (sem pontos)' 
                        : 'Selecione talhão e cultura',
                    style: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Inicia monitoramento livre (abre tela de ponto de monitoramento)
  Future<void> _startFreeMonitoring() async {
    try {
      if (_selectedTalhao == null || _selectedCultura == null) {
        _safeShowSnackBar('Selecione talhão e cultura', isError: true);
        return;
      }
      
      Logger.info('🆓 [FREE_MON] ========================================');
      Logger.info('🆓 [FREE_MON] Iniciando MONITORAMENTO LIVRE');
      Logger.info('🆓 [FREE_MON] Talhão: ${_selectedTalhao!.name} (${_selectedTalhao!.id})');
      Logger.info('🆓 [FREE_MON] Cultura: ${_selectedCultura!.name} (${_selectedCultura!.id})');
      Logger.info('🆓 [FREE_MON] ========================================');
      
      // ✅ CRIAR SESSÃO ANTES DE NAVEGAR (sem solicitar temperatura/umidade)
      final sessionId = await _createOrGetMonitoringSession(
        _selectedTalhao!.id,
      );
      
      if (sessionId.isEmpty) {
        Logger.error('❌ [FREE_MON] Erro ao criar sessão!');
        _safeShowSnackBar('Erro ao criar sessão de monitoramento', isError: true);
        return;
      }
      
      Logger.info('✅ [FREE_MON] Sessão criada: $sessionId');
      
      // Gerar ID único para o ponto virtual
      final pontoId = DateTime.now().millisecondsSinceEpoch;
      
      // Navegar para a tela de ponto de monitoramento com argumentos corretos
      Logger.info('🚀 [FREE_MON] Navegando para tela de pontos com sessionId...');
      Logger.info('📦 [FREE_MON] Argumentos: {');
      Logger.info('     pontoId: $pontoId,');
      Logger.info('     talhaoId: ${_selectedTalhao!.id},');
      Logger.info('     culturaId: ${_selectedCultura!.id},');
      Logger.info('     talhaoNome: ${_selectedTalhao!.name},');
      Logger.info('     culturaNome: ${_selectedCultura!.name},');
      Logger.info('     sessionId: $sessionId,');
      Logger.info('     isFreeMonitoring: true,');
      Logger.info('  }');
      
      final result = await Navigator.of(context).pushNamed(
        '/monitoring/point',
        arguments: {
          'pontoId': pontoId,
          'talhaoId': _selectedTalhao!.id,
          'culturaId': _selectedCultura!.id,
          'talhaoNome': _selectedTalhao!.name,
          'culturaNome': _selectedCultura!.name,
          'sessionId': sessionId, // ✅ PASSAR SESSION ID!
          'isFreeMonitoring': true,
          'latitude': _currentPosition?.latitude ?? 0.0,
          'longitude': _currentPosition?.longitude ?? 0.0,
        },
      );
      
      Logger.info('✅ [FREE_MON] Navegação executada! Resultado: $result');
      
    } catch (e, stack) {
      Logger.error('❌ [FREE_MON] ERRO AO INICIAR MONITORAMENTO LIVRE: $e');
      Logger.error('❌ [FREE_MON] Stack trace: $stack');
      _safeShowSnackBar('Erro ao iniciar monitoramento livre: $e', isError: true);
    }
  }
    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoramento Avançado'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleSatelliteLayer,
            icon: Icon(_showSatelliteLayer ? Icons.map : Icons.satellite),
            tooltip: _showSatelliteLayer ? 'Mapa Normal' : 'Camada de Satélite',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/monitoring/history-v2');
            },
            icon: const Icon(Icons.history),
            tooltip: 'Histórico de Monitoramentos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Banner de sessões pausadas
                if (_hasPausedSessions) _buildPausedSessionsBanner(),
          // Configuração (flexível)
          if (!_isDrawingMode) 
            Flexible(
              flex: 2,
              child: _buildConfigSection(),
            ),
          
          // Mapa (flexível)
          Flexible(
            flex: 5,
            child: Stack(
              children: [
                _buildMapSection(),
                Positioned(
                  right: 16,
                  bottom: 100, // Ajustado para não conflitar com o botão de iniciar
                  child: _buildFloatingActionButtons(),
                ),
                // Botão para centralizar no talhão
                if (_selectedTalhao != null)
                  Positioned(
                    left: 16,
                    bottom: 100, // Ajustado para não conflitar com o botão de iniciar
                    child: FloatingActionButton(
                      onPressed: _centralizarNoTalhaoSelecionado,
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.center_focus_strong, color: Colors.white),
                    ),
                  ),
                // Botão iniciar sobreposto no mapa
                if (!_isDrawingMode && (_routePoints.length >= 1 || (_selectedTalhao != null && _selectedCultura != null)))
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildStartButton(),
                  ),
              ],
            ),
                ),
              ],
            ),
    );
  }
  
  /// Diálogo para coletar temperatura e umidade
  Future<Map<String, double>?> _showClimateDataDialog() async {
    double? temperatura;
    double? umidade;
    final formKey = GlobalKey<FormState>();
    
    return showDialog<Map<String, double>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wb_sunny, color: Colors.orange),
            SizedBox(width: 12),
            Text('Condições Climáticas'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Informe as condições ambientais atuais:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Temperatura (°C)',
                  prefixIcon: Icon(Icons.thermostat),
                  border: OutlineInputBorder(),
                  hintText: '25.0',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a temperatura';
                  }
                  final temp = double.tryParse(value.replaceAll(',', '.'));
                  if (temp == null || temp < -10 || temp > 50) {
                    return 'Temperatura inválida (-10 a 50°C)';
                  }
                  return null;
                },
                onSaved: (value) {
                  temperatura = double.tryParse(value!.replaceAll(',', '.'));
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Umidade (%)',
                  prefixIcon: Icon(Icons.water_drop),
                  border: OutlineInputBorder(),
                  hintText: '60.0',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a umidade';
                  }
                  final umid = double.tryParse(value.replaceAll(',', '.'));
                  if (umid == null || umid < 0 || umid > 100) {
                    return 'Umidade inválida (0 a 100%)';
                  }
                  return null;
                },
                onSaved: (value) {
                  umidade = double.tryParse(value!.replaceAll(',', '.'));
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(context, {
                  'temperatura': temperatura!,
                  'umidade': umidade!,
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
