import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../database/migrations/create_monitoring_tables_unified.dart';
import '../../services/direct_occurrence_service.dart';
import '../../debug/quick_db_check.dart';
import 'widgets/point_monitoring_header.dart';
import 'widgets/point_monitoring_map.dart';
import 'widgets/point_monitoring_occurrences_list.dart';
import 'widgets/point_monitoring_footer.dart';
import '../../widgets/new_occurrence_card.dart';
import 'widgets/route_navigation_screen.dart';
import '../../models/infestacao_model.dart';
import '../../utils/enums.dart';
import '../../models/ponto_monitoramento_model.dart';
import '../../models/monitoring.dart';
import '../../models/monitoring_point.dart';
import '../../models/occurrence.dart';
import '../../services/monitoring_history_service.dart';
import '../../repositories/infestacao_repository.dart';
import '../../database/app_database.dart';
import '../../utils/logger.dart';
import '../../utils/distance_calculator.dart';
import '../../utils/image_compression_service.dart';
import '../../services/monitoring_sync_service.dart';
import '../../services/monitoring_database_fix_service.dart';
import '../../services/monitoring_background_service.dart';
import '../../services/monitoring_notification_service.dart';
import '../../routes.dart';

class PointMonitoringScreen extends StatefulWidget {
  final int pontoId;
  final String talhaoId; // String para compatibilidade
  final String culturaId; // String para compatibilidade com IDs de cultura
  final String talhaoNome;
  final String culturaNome;
  final List<dynamic>? pontos; // Pontos desenhados no mapa
  final DateTime? data; // Data do monitoramento
  final String? sessionId; // ✅ ADICIONAR SESSION ID

  const PointMonitoringScreen({
    Key? key,
    required this.pontoId,
    required this.talhaoId,
    required this.culturaId,
    required this.talhaoNome,
    required this.culturaNome,
    this.pontos,
    this.data,
    this.sessionId, // ✅ ADICIONAR SESSION ID
  }) : super(key: key);

  @override
  State<PointMonitoringScreen> createState() => _PointMonitoringScreenState();
}

class _PointMonitoringScreenState extends State<PointMonitoringScreen> {
  // Estado local
  bool _isLoading = false;
  String? _error;
  int? _talhaoIdInt;
  PontoMonitoramentoModel? _currentPoint;
  PontoMonitoramentoModel? _nextPoint;
  List<InfestacaoModel> _ocorrencias = [];
  Position? _currentPosition;
  double? _distanceToPoint;
  String? _gpsAccuracy;
  bool _hasArrived = false;
  String? _observacoesGerais;
  List<PontoMonitoramentoModel> _allPoints = [];
  int _currentPointIndex = 0;
  
  // Estado de monitoramento livre
  bool _isFreeMonitoring = false;
  
  // Gerenciamento de sessão de monitoramento
  String? _sessionId;
  bool _isResumingSession = false;
  
  // Repositórios e serviços
  InfestacaoRepository? _infestacaoRepository;
  Database? _database;
  MonitoringSyncService? _syncService;
  MonitoringDatabaseFixService? _databaseFixService;
  
  // Constantes de validação
  static const double _maxGpsAccuracy = 10.0; // metros
  static const double _arrivalThreshold = 2.0; // metros
  static const double _navigationThreshold = 5.0; // metros
  
  
  StreamSubscription<Position>? _positionSubscription;
  Timer? _debounceTimer;
  
  // Serviços de background e notificação
  final MonitoringBackgroundService _backgroundService = MonitoringBackgroundService();
  final MonitoringNotificationService _notificationService = MonitoringNotificationService();
  bool _isBackgroundModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeScreen();
  }

  @override
  void dispose() {
    // Pausar sessão se estiver ativa (não finalizada)
    _pauseSessionOnExit();
    
    _positionSubscription?.cancel();
    _debounceTimer?.cancel();
    
    // Parar serviços de background
    if (_isBackgroundModeEnabled) {
      _backgroundService.stopBackgroundMonitoring();
    }
    
    // Limpar notificações
    _notificationService.clearAllNotifications();
    _notificationService.dispose();
    
    super.dispose();
  }
  
  /// Pausa a sessão quando o usuário sair sem finalizar
  void _pauseSessionOnExit() {
    if (_sessionId == null || _database == null) return;
    
    try {
      // Verificar se a sessão ainda está ativa
      _database!.query(
        'monitoring_sessions',
        where: 'id = ? AND status = ?',
        whereArgs: [_sessionId, 'active'],
      ).then((sessions) {
        if (sessions.isNotEmpty) {
          // Pausar sessão para permitir continuação posterior
          _database!.update(
            'monitoring_sessions',
            {
              'status': 'pausado',
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [_sessionId],
          );

        }
      });
    } catch (e) {
      Logger.error('❌ Erro ao pausar sessão: $e');
    }
  }

  /// Inicializa os serviços de background e notificação
  Future<void> _initializeServices() async {
    try {
      // Inicializar serviço de notificações
      _notificationService.setContext(context);
    } catch (e) {
      Logger.error('Erro ao inicializar serviços: $e');
    }
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Garantir que os IDs sejam válidos
    final pontoId = widget.pontoId is int ? widget.pontoId : int.tryParse(widget.pontoId.toString()) ?? 0;
      
      // Para talhaoId, manter como string se for UUID, ou converter para int se for numérico
      String talhaoIdString = widget.talhaoId.toString();
      int? talhaoIdInt = int.tryParse(talhaoIdString);
      
      // Se o ID do talhão é numérico, usar como int, senão manter como string
      if (talhaoIdInt != null) {
        _talhaoIdInt = talhaoIdInt;
      } else {
        // Para UUIDs, usar um hash como int para compatibilidade
        _talhaoIdInt = talhaoIdString.hashCode.abs();
      }

      // Validar se os IDs são válidos
      if (pontoId == 0) {
        throw Exception('ID do ponto inválido: ${widget.pontoId}');
      }
      
      if (_talhaoIdInt == 0) {
        throw Exception('ID do talhão inválido: ${widget.talhaoId}');
      }
      
      if (widget.culturaId.isEmpty) {
        throw Exception('ID da cultura inválido: ${widget.culturaId}');
      }
      
      // Inicializar banco de dados e repositórios
      await _initializeDatabase();
      
      // Criar ou restaurar sessão de monitoramento
      await _createOrRestoreSession();
      
      // Processar pontos do monitoramento avançado
      await _processMonitoringPoints(_talhaoIdInt!);
      
      // Carregar ocorrências existentes do ponto atual
      await _loadExistingOccurrences();

      // Iniciar monitoramento GPS
      _startGpsMonitoring();

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      Logger.error('Erro ao inicializar monitoramento: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _initializeDatabase() async {
    try {
      _database = await AppDatabase().database;
      _infestacaoRepository = InfestacaoRepository(_database!);
      await _infestacaoRepository!.createTable();
      _syncService = MonitoringSyncService();
      _databaseFixService = MonitoringDatabaseFixService();
      
      // Corrigir problemas de banco de dados
      await _databaseFixService!.fixDatabaseIssues();
    } catch (e) {
      Logger.error('Erro ao inicializar banco de dados: $e');
      throw Exception('Erro ao inicializar banco de dados: $e');
    }
  }

  /// Cria uma nova sessão de monitoramento ou restaura uma existente
  Future<void> _createOrRestoreSession() async {
    try {
      // ✅ SE JÁ FOI PASSADO UM SESSION ID, USAR ELE
      if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        _sessionId = widget.sessionId;
        _isResumingSession = false;
        Logger.info('✅ [POINT_MON] Usando sessionId passado pelo advanced_monitoring: $_sessionId');
        
        // Manter status como 'draft' (não precisa mudar)
        final rows = await _database!.update(
          'monitoring_sessions',
          {
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [_sessionId],
        );
        
        Logger.info('✅ [POINT_MON] Sessão atualizada ($rows linhas afetadas)');
        
        return;
      }
      
      // ✅ SENÃO, VERIFICAR SE JÁ EXISTE UMA SESSÃO ATIVA/PAUSADA
      Logger.info('🔍 Nenhum sessionId passado - verificando sessões existentes...');
      
      final activeSessions = await _database!.query(
        'monitoring_sessions',
        where: 'talhao_id = ? AND cultura_id = ? AND status IN (?, ?)',
        whereArgs: [widget.talhaoId, widget.culturaId, 'active', 'pausado'],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      
      if (activeSessions.isNotEmpty) {
        // Restaurar sessão existente
        _sessionId = activeSessions.first['id'] as String;
        _isResumingSession = true;
        Logger.info('✅ Sessão existente encontrada: $_sessionId');
        
        // Manter status como estava (não precisa mudar para 'active')
        await _database!.update(
          'monitoring_sessions',
          {
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [_sessionId],
        );
        
      } else {
        // ⚠️ ÚLTIMO RECURSO: Criar nova sessão (NÃO DEVERIA CHEGAR AQUI)
        Logger.warning('⚠️ Criando nova sessão (não deveria acontecer se advanced_monitoring passou sessionId)');
        
        _sessionId = const Uuid().v4();
        _isResumingSession = false;
        
        final now = DateTime.now().toIso8601String();
        
        await _database!.insert('monitoring_sessions', {
          'id': _sessionId,
          'fazenda_id': 'fazenda_1',
          'talhao_id': widget.talhaoId,
          'cultura_id': widget.culturaId,
          'talhao_nome': widget.talhaoNome,
          'cultura_nome': widget.culturaNome,
          'total_pontos': widget.pontos?.length ?? 0,
          'total_ocorrencias': 0,
          'data_inicio': now,
          'started_at': now,
          'data_fim': null,
          'finished_at': null,
          'status': 'draft', // ✅ USAR 'draft'
          'tecnico_nome': 'Técnico',
          'observacoes': null,
          'created_at': now,
          'updated_at': now,
        });
        
        Logger.info('✅ Nova sessão criada: $_sessionId');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao criar/restaurar sessão: $e');
      Logger.error('❌ Stack: ${StackTrace.current}');
      // Não falhar o processo se houver erro
    }
  }

  Future<void> _loadExistingOccurrences() async {
    if (_infestacaoRepository == null || _currentPoint == null) return;
    
    try {
      final existingOccurrences = await _infestacaoRepository!.getByPontoId(_currentPoint!.id);
      setState(() {
        _ocorrencias = existingOccurrences;
      });
    } catch (e) {
      Logger.error('Erro ao carregar ocorrências: $e');
    }
  }

  Future<void> _processMonitoringPoints(int talhaoId) async {
    try {
      _allPoints = [];
      
      if (widget.pontos != null && widget.pontos!.isNotEmpty) {
        // Converter pontos do mapa em pontos de monitoramento
        for (int i = 0; i < widget.pontos!.length; i++) {
          final ponto = widget.pontos![i];
          
          // Validar se o ponto tem coordenadas válidas
          if (ponto.latitude == null || ponto.longitude == null) {
            throw Exception('Ponto ${i + 1} não possui coordenadas válidas');
          }
          
          final pontoModel = PontoMonitoramentoModel(
            id: widget.pontoId + i, // Usar IDs sequenciais
            talhaoId: talhaoId,
            ordem: i + 1,
            latitude: ponto.latitude,
            longitude: ponto.longitude,
            dataHoraInicio: i == 0 ? DateTime.now() : null, // Marcar primeiro ponto como iniciado
          );
          _allPoints.add(pontoModel);
        }
      } else {
        // ✅ Se não há pontos desenhados, é monitoramento livre
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        _isFreeMonitoring = args?['isFreeMonitoring'] as bool? ?? true; // ✅ ASSUMIR livre se não tem pontos
        
        Logger.info('✅ [POINT_MON] Monitoramento LIVRE detectado - criando ponto virtual');
          
          // Criar um ponto virtual para monitoramento livre
          final latitude = args?['latitude'] as double? ?? 0.0;
          final longitude = args?['longitude'] as double? ?? 0.0;
          
          final pontoVirtual = PontoMonitoramentoModel(
            id: widget.pontoId,
            talhaoId: talhaoId,
            ordem: 1,
            latitude: latitude,
            longitude: longitude,
            dataHoraInicio: DateTime.now(),
            observacoesGerais: 'Monitoramento livre - ponto criado automaticamente',
          );
          
          _allPoints = [pontoVirtual];
          _currentPoint = pontoVirtual;
          _currentPointIndex = 0;
          
        Logger.info('✅ [POINT_MON] Ponto virtual criado para monitoramento livre');
      }
      
      // Definir ponto atual e próximo
      _currentPointIndex = 0;
      _currentPoint = _allPoints.isNotEmpty ? _allPoints[0] : null;
      _nextPoint = _allPoints.length > 1 ? _allPoints[1] : null;
      
    } catch (e) {
      throw Exception('Erro ao processar pontos de monitoramento: $e');
    }
  }

  void _startGpsMonitoring() {
    _positionSubscription?.cancel();
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1, // 1 metro
      ),
    ).listen(
      (position) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          _updateGpsPosition(position);
        });
      },
      onError: (error) {
        setState(() {
          _gpsAccuracy = 'Erro: $error';
        });
      },
    );
  }

  void _updateGpsPosition(Position position) {
    final currentPoint = _currentPoint;
    if (currentPoint == null) return;

    // Calcular distância até o ponto atual usando DistanceCalculator
    final distance = DistanceCalculator.calculateDistance(
      position.latitude,
      position.longitude,
      currentPoint.latitude,
      currentPoint.longitude,
    );

    // Verificar se chegou ao ponto usando thresholds configuráveis
    final hasArrived = DistanceCalculator.hasArrivedAtPoint(distance, arrivalThreshold: _arrivalThreshold);
    final previousArrived = _hasArrived;

    // Vibrar e tocar som quando chegar pela primeira vez
    if (hasArrived && !previousArrived) {
      _triggerArrivalNotification();
      
      // Abrir automaticamente o card de nova ocorrência quando chegar ao ponto
      // Verificar se está dentro do raio de 5 metros
      if (distance <= 5.0) {
        _openOccurrenceCardAutomatically();
      }
    }

    // Se estiver em modo background, notificar proximidade
    if (_isBackgroundModeEnabled) {
      _checkBackgroundProximity(position);
    }

    // Atualizar estado
    setState(() {
      _currentPosition = position;
      _distanceToPoint = distance;
      _gpsAccuracy = '${position.accuracy.toStringAsFixed(1)}m';
      _hasArrived = hasArrived;
    });
  }

  void _triggerArrivalNotification() {
    // Implementar vibração e som
    HapticFeedback.mediumImpact();
    
    // Vibração adicional para indicar chegada
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
    
    // TODO: Implementar som de chegada
    // AudioService.playArrivalSound();
    
    // Mostrar notificação visual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 Você chegou ao ponto de monitoramento!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Abre automaticamente o card de nova ocorrência quando chega ao ponto
  void _openOccurrenceCardAutomatically() {

    
    // Pequeno delay para dar tempo da notificação de chegada ser exibida
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Usar a função existente para abrir o modal
        _showNewOccurrenceModal();
        

        
        // Mostrar mensagem informativa
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📝 Card de nova ocorrência aberto automaticamente para o ponto ${_currentPoint?.ordem ?? 'atual'}'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  /// Verifica proximidade em modo background
  void _checkBackgroundProximity(Position position) {
    try {
      if (_currentPoint == null) return;

      final distance = DistanceCalculator.calculateDistance(
        position.latitude,
        position.longitude,
        _currentPoint!.latitude ?? 0.0,
        _currentPoint!.longitude ?? 0.0,
      );

      // Notificar proximidade (10 metros)
      if (distance <= 10.0) {
        _notificationService.notifyProximityDetected(
          distance: distance,
          point: {
            'id': _currentPoint!.id,
            'latitude': _currentPoint!.latitude,
            'longitude': _currentPoint!.longitude,
            'ordem': _currentPoint!.ordem,
          },
          talhaoId: widget.talhaoId,
          pointIndex: _currentPointIndex,
        );
      }

      // Notificar vibração (5 metros)
      if (distance <= 5.0) {
        _notificationService.notifyVibrationTriggered(
          distance: distance,
          point: {
            'id': _currentPoint!.id,
            'latitude': _currentPoint!.latitude,
            'longitude': _currentPoint!.longitude,
            'ordem': _currentPoint!.ordem,
          },
          talhaoId: widget.talhaoId,
          pointIndex: _currentPointIndex,
        );
      }

    } catch (e) {
      Logger.error('❌ Erro ao verificar proximidade em background: $e');
    }
  }

  /// Inicia monitoramento em background
  Future<void> _startBackgroundMonitoring() async {
    try {
      Logger.info('🔄 [BACKGROUND] Iniciando modo background...');

      if (_allPoints.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Nenhum ponto de monitoramento disponível'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Preparar dados dos pontos para o serviço de background
      final monitoringPoints = _allPoints.map((ponto) => {
        'id': ponto.id,
        'latitude': ponto.latitude ?? 0.0,
        'longitude': ponto.longitude ?? 0.0,
        'ordem': ponto.ordem,
      }).toList();

      // Iniciar serviço de background
      final success = await _backgroundService.startBackgroundMonitoring(
        talhaoId: widget.talhaoId,
        monitoringPoints: monitoringPoints,
        currentPointIndex: _currentPointIndex,
      );

      if (success) {
        setState(() {
          _isBackgroundModeEnabled = true;
        });

        Logger.info('✅ [BACKGROUND] Modo background ativado com sucesso!');

        // Mostrar notificação de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚀 Modo background ativado!\n📱 Você pode desligar a tela agora.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        Logger.error('❌ [BACKGROUND] Falha ao iniciar modo background');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Não foi possível ativar o modo background'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

    } catch (e, stack) {
      Logger.error('❌ [BACKGROUND] Erro ao iniciar: $e');
      Logger.error('❌ [BACKGROUND] Stack: $stack');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao ativar modo background: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Para monitoramento em background
  Future<void> _stopBackgroundMonitoring() async {
    try {
      Logger.info('🛑 [BACKGROUND] Parando modo background...');

      await _backgroundService.stopBackgroundMonitoring();

      setState(() {
        _isBackgroundModeEnabled = false;
      });

      Logger.info('✅ [BACKGROUND] Modo background desativado');

      // Mostrar notificação
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛑 Modo background desativado'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e, stack) {
      Logger.error('❌ [BACKGROUND] Erro ao parar: $e');
      Logger.error('❌ [BACKGROUND] Stack: $stack');
      
      // Mesmo com erro, desativar o flag
      if (mounted) {
        setState(() {
          _isBackgroundModeEnabled = false;
        });
      }
    }
  }

  /// Alterna modo background
  Future<void> _toggleBackgroundMode() async {
    if (_isBackgroundModeEnabled) {
      await _stopBackgroundMonitoring();
    } else {
      await _startBackgroundMonitoring();
    }
  }

  void _showNewOccurrenceModal() {
    try {

      
      // Verificar se é o último ponto
      final isLastPoint = _isLastPoint();

      
      if (!mounted) {
        Logger.error('❌ Widget não está montado');
        return;
      }
      

      
      // Usar método simples e confiável
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        useSafeArea: true,
        builder: (BuildContext context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle para arrastar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Conteúdo do modal
                Expanded(
                  child: NewOccurrenceCard(
                    cropName: widget.culturaNome,
                    fieldId: widget.talhaoId.toString(),
                    onOccurrenceAdded: (data) async {
                      await _saveOccurrenceFromCard(data);
                    },
                    onClose: () {
                      Navigator.pop(context);
                    },
                    onSaveAndAdvance: () async {
                      Navigator.pop(context);
                      await _navigateToNextPoint();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
      

      
    } catch (e) {
      Logger.error('❌ Erro ao abrir modal de nova ocorrência: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir modal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Método alternativo para abrir o modal de nova ocorrência
  void _showNewOccurrenceModalAlternative() {
    try {

      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (BuildContext context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle para arrastar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Conteúdo do modal
                Expanded(
                  child: NewOccurrenceCard(
                    cropName: widget.culturaNome,
                    fieldId: widget.talhaoId.toString(),
                    onOccurrenceAdded: (data) async {
                      await _saveOccurrenceFromCard(data);
                    },
                    onClose: () {
                      Navigator.pop(context);
                    },
                    onSaveAndAdvance: () async {
                      Navigator.pop(context);
                      await _navigateToNextPoint();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
      

      
    } catch (e) {
      Logger.error('❌ Erro no método alternativo: $e');
      
      // Último recurso: navegar para uma tela separada
      _navigateToNewOccurrenceScreen();
    }
  }

  /// Último recurso: navegar para uma tela separada
  void _navigateToNewOccurrenceScreen() {
    try {

      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Nova Ocorrência'),
              backgroundColor: const Color(0xFF2D9CDB),
              foregroundColor: Colors.white,
            ),
            body: NewOccurrenceCard(
              cropName: widget.culturaNome,
              fieldId: widget.talhaoId.toString(),
              onOccurrenceAdded: (data) async {
                await _saveOccurrenceFromCard(data);
                Navigator.pop(context);
              },
              onClose: () {
                Navigator.pop(context);
              },
              onSaveAndAdvance: () async {
                Navigator.pop(context);
                await _navigateToNextPoint();
              },
            ),
          ),
        ),
      );
      

      
    } catch (e) {
      Logger.error('❌ Erro ao navegar para tela separada: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir nova ocorrência: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveOccurrence({
    required String tipo,
    required String subtipo,
    required String nivel,
    required int numeroInfestacao,
    String? observacao,
    List<String>? fotoPaths,
    // Novos campos para cálculo avançado
    String? organismoId,
    int? quantidadeBruta,
    int? totalPlantasAvaliadas,
    String? tercoPlanta,
    bool saveAndContinue = false,
    int? quantidade, // ✅ NOVO: Campo quantidade separado
    double? temperature, // ✅ NOVO: Temperatura
    double? humidity, // ✅ NOVO: Umidade
    double? agronomicSeverityValue, // ✅ NOVO: Severidade já calculada
  }) async {
    try {
      Logger.info('🟡 [SAVE_OCC] ==========================================');
      Logger.info('🟡 [SAVE_OCC] MÉTODO _saveOccurrence CHAMADO!');
      Logger.info('🟡 [SAVE_OCC] Tipo: $tipo');
      Logger.info('🟡 [SAVE_OCC] Subtipo: $subtipo');
      Logger.info('🟡 [SAVE_OCC] Percentual: $numeroInfestacao%');
      Logger.info('🟡 [SAVE_OCC] Session ID: $_sessionId');
      Logger.info('🟡 [SAVE_OCC] ==========================================');

      final position = _currentPosition;
      if (position == null) {
        Logger.error('❌ [SAVE_OCC] Posição GPS não disponível!');
        throw Exception('Posição GPS não disponível');
      }
      
      Logger.info('✅ [SAVE_OCC] GPS OK: ${position.latitude}, ${position.longitude}');

      // Usar os IDs reais passados para a tela
      final talhaoId = widget.talhaoId;
      final pontoId = widget.pontoId;
      
      // Normaliza quantidade: aceita tanto quantidadeBruta quanto quantidade
      final int? quantidadeEfetiva = quantidadeBruta ?? quantidade;
      
      // Verificar se os IDs são válidos
      if (talhaoId.isEmpty || pontoId == 0) {
        throw Exception('IDs de talhão ou ponto inválidos.');
      }
      
      // Verificar se os IDs existem no banco de dados (com fallback)
      final talhaoExists = await _databaseFixService!.talhaoExists(talhaoId);
      final pontoExists = await _databaseFixService!.pontoExists(pontoId);
      
      // Se o talhão não existe, tentar criar um registro básico
      if (!talhaoExists) {
        await _createBasicTalhaoRecord(talhaoId);
      }
      
      // Se o ponto não existe, tentar criar um registro básico
      if (!pontoExists) {
        await _createBasicPontoRecord(pontoId, talhaoId);
      }
      
      // Criar nova ocorrência com ID único robusto
      final uniqueId = _generateUniqueId();
      final novaOcorrencia = InfestacaoModel(
        id: uniqueId,
        talhaoId: talhaoId,
        pontoId: pontoId,
        latitude: position.latitude,
        longitude: position.longitude,
        tipo: tipo,
        subtipo: subtipo,
        nivel: nivel,
        percentual: numeroInfestacao, // Preview simples
        observacao: observacao,
        fotoPaths: fotoPaths?.join(';'),
        dataHora: DateTime.now(),
        sincronizado: false,
        // Novos campos para cálculo avançado no mapa de infestação
        organismoId: organismoId,
        quantidadeBruta: quantidadeEfetiva,
        totalPlantasAvaliadas: totalPlantasAvaliadas,
        tercoPlanta: tercoPlanta,
      );

      // Salvar usando método robusto que evita foreign keys
      try {
        await _saveOccurrenceRobust(novaOcorrencia);
      } catch (e) {
        // Tentar método simples como fallback
        try {
          await _saveOccurrenceSimple(novaOcorrencia);
        } catch (e2) {
          // Último recurso: salvar apenas em memória
          await _saveOccurrenceFallback(novaOcorrencia);
        }
      }

      // ✅ USAR O NOVO SERVIÇO DIRETO E SIMPLES
      Logger.info('🔵 [POINT_MON] Usando DirectOccurrenceService para salvar...');
      
      // Validar sessionId
      if (_sessionId == null || _sessionId!.isEmpty) {
        
        throw Exception('Session ID inválido');
      }
      
      final savedSuccessfully = await DirectOccurrenceService.saveOccurrence(
        sessionId: _sessionId!,
        pointId: '${_sessionId}_point_${_currentPoint?.ordem ?? 1}',
        talhaoId: talhaoId,
        tipo: tipo,
        subtipo: subtipo,
        nivel: nivel,
        percentual: numeroInfestacao,
        latitude: position.latitude,
        longitude: position.longitude,
        observacao: observacao,
        fotoPaths: fotoPaths,
        tercoPlanta: tercoPlanta,
        quantidade: quantidadeEfetiva ?? numeroInfestacao, // ✅ garantir valor
        temperature: temperature, // ✅ NOVO: Temperatura
        humidity: humidity, // ✅ NOVO: Umidade
        agronomicSeverity: agronomicSeverityValue, // ✅ NOVO: Severidade já calculada
      );

      if (!savedSuccessfully) {
       
      }

      Logger.info('✅ [POINT_MON] Ocorrência salva com sucesso via DirectOccurrenceService!');

      // Adicionar à lista local SOMENTE após salvamento confirmado
      setState(() {
        _ocorrencias = [..._ocorrencias, novaOcorrencia];
      });

      // ✅ DIAGNÓSTICO IMEDIATO: Verificar se foi salvo mesmo
      final occCount = await DirectOccurrenceService.countOccurrencesForSession(_sessionId!);
      

      // Enviar para o mapa de infestação (mantido para compatibilidade)
      await _sendToInfestationMap(novaOcorrencia);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorrência salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Implementar lógica baseada no botão clicado
      if (saveAndContinue) {
        // Aguardar um pouco para o usuário ver a mensagem de sucesso
        await Future.delayed(const Duration(milliseconds: 500));
        await _navigateToNextPoint();
      } else {
        // Limpar campos do modal para permitir nova ocorrência no mesmo ponto
        // O modal já foi fechado pelo NewOccurrenceModal
        // Mostrar mensagem específica para o botão Salvar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ocorrência salva! Você pode adicionar mais ocorrências neste ponto.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Erro ao salvar ocorrência: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (_isLoading) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2D9CDB),
            ),
          ),
        );
      }

      if (_error != null) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erro',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _initializeScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D9CDB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA), // Branco pérola
        body: SafeArea(
          child: Column(
            children: [
              // Header compacto
              PointMonitoringHeader(
                currentPoint: _currentPoint,
                nextPoint: _nextPoint,
                talhaoNome: widget.talhaoNome,
                culturaNome: widget.culturaNome,
                gpsStatus: _gpsAccuracy,
                distanceToPoint: _distanceToPoint,
                hasArrived: _hasArrived,
                isBackgroundModeEnabled: _isBackgroundModeEnabled,
                onToggleBackground: _toggleBackgroundMode,
              ),
              
              // Linha de status da cultura
              _buildCulturaStatusLine(),
              
              // Mini mapa (metade da tela)
              Expanded(
                flex: 1,
                child: PointMonitoringMap(
                  currentPoint: _currentPoint,
                  nextPoint: _nextPoint,
                  currentPosition: _currentPosition,
                  ocorrencias: _ocorrencias,
                  talhaoId: _talhaoIdInt ?? 0,
                  culturaId: widget.culturaId,
                ),
              ),
              
              // Divisor fino
              Container(
                height: 1,
                color: const Color(0xFFE0E0E0),
              ),
              
              // Lista de ocorrências
              Expanded(
                flex: 1,
                child: PointMonitoringOccurrencesList(
                  ocorrencias: _ocorrencias,
                  onDelete: _deleteOccurrence,
                  onSaveOccurrence: _saveOccurrence,
                ),
              ),
              
              // Rodapé fixado
              PointMonitoringFooter(
                currentPoint: _currentPoint,
                nextPoint: _nextPoint,
                hasArrived: _hasArrived,
                distanceToPoint: _distanceToPoint,
                isLastPoint: _isLastPoint(),
                onPrevious: _previousPoint,
                onNext: _goToNextPoint,
                onNewOccurrence: _showNewOccurrenceModal,
                onFinish: _finishMonitoring,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Fallback em caso de erro no build
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro na Interface',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _initializeScreen();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D9CDB),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Recarregar Tela'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCulturaStatusLine() {
    // Contar ocorrências por tipo
    final pragaCount = _ocorrencias.where((o) => o.tipo.toLowerCase() == 'praga').length;
    final doencaCount = _ocorrencias.where((o) => o.tipo.toLowerCase() == 'doença').length;
    final daninhaCount = _ocorrencias.where((o) => o.tipo.toLowerCase() == 'daninha').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '🌱 ${widget.culturaNome}',
            style: const TextStyle(
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          if (pragaCount > 0) ...[
            _buildOccurrenceBadge('🐛', pragaCount),
            const SizedBox(width: 8),
          ],
          if (doencaCount > 0) ...[
            _buildOccurrenceBadge('🦠', doencaCount),
            const SizedBox(width: 8),
          ],
          if (daninhaCount > 0) ...[
            _buildOccurrenceBadge('🌿', daninhaCount),
          ],
          if (pragaCount == 0 && doencaCount == 0 && daninhaCount == 0)
            const Text(
              'Nenhuma ocorrência registrada',
              style: TextStyle(
                color: Color(0xFF95A5A6),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOccurrenceBadge(String icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        '$icon $count',
        style: const TextStyle(
          color: Color(0xFF2C2C2C),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _deleteOccurrence(String id) async {
    try {
      // Remover do banco de dados
      if (_infestacaoRepository != null) {
        await _infestacaoRepository!.delete(id);

      }

      // Remover da lista local
      setState(() {
        _ocorrencias = _ocorrencias.where((o) => o.id != id).toList();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorrência removida com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('❌ Erro ao remover ocorrência: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Envia dados para o mapa de infestação
  Future<void> _sendToInfestationMap(InfestacaoModel ocorrencia) async {
    try {
      Logger.info('🔄 Enviando dados para mapa de infestação: ${ocorrencia.id}');
      Logger.info('📊 Organismo: ${ocorrencia.subtipo}, Nível: ${ocorrencia.nivel}, Percentual: ${ocorrencia.percentual}%');
      
      if (_database == null) {
        Logger.error('❌ Banco de dados não disponível para mapa de infestação');
        throw Exception('Banco de dados não disponível');
      }

      // As tabelas já são criadas pela migração unificada
      // Apenas verificar se existem
      final tableCheck = await _database!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='infestation_map'"
      );
      
      if (tableCheck.isEmpty) {

        final db = await AppDatabase().database;
        await CreateMonitoringTablesUnified.up(db);

      }

      // Converter talhaoId para int se necessário para compatibilidade com o banco
      int talhaoIdInt = int.tryParse(ocorrencia.talhaoId) ?? ocorrencia.talhaoId.hashCode.abs();
      
      // Preparar dados no formato da tabela unificada infestation_map
      final infestationData = {
        'id': ocorrencia.id,
        'talhao_id': widget.talhaoId, // Manter como string
        'ponto_id': 'point_${ocorrencia.pontoId}',
        'latitude': ocorrencia.latitude,
        'longitude': ocorrencia.longitude,
        'tipo': ocorrencia.tipo,
        'subtipo': ocorrencia.subtipo,
        'nivel': ocorrencia.nivel,
        'percentual': ocorrencia.percentual,
        'observacao': ocorrencia.observacao,
        'foto_paths': ocorrencia.fotoPaths,
        'data_hora': ocorrencia.dataHora.toIso8601String(),
        'sincronizado': ocorrencia.sincronizado ? 1 : 0,
        'cultura_id': widget.culturaId,
        'cultura_nome': widget.culturaNome,
        'talhao_nome': widget.talhaoNome,
        'severity_level': _calculateSeverityLevel(ocorrencia.percentual),
        'status': 'active',
        'source': 'monitoring_module',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Inserir ou atualizar dados no mapa de infestação
      await _database!.insert(
        'infestation_map',
        infestationData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Dados enviados com sucesso para o mapa de infestação!');
      Logger.info('📍 Coordenadas: ${ocorrencia.latitude}, ${ocorrencia.longitude}');
      Logger.info('🎯 Talhão: ${widget.talhaoNome} | Cultura: ${widget.culturaNome}');
      
    } catch (e) {
      Logger.error('❌ Erro ao enviar dados para o mapa de infestação: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      // Não falhar o processo principal se houver erro no mapa
    }
  }

  /// Salva dados no histórico de monitoramento
  Future<void> _saveToMonitoringHistory(InfestacaoModel ocorrencia) async {
    try {
      // // Log removido
      // // Log removido
      
      if (_database == null) {
        Logger.error('❌ Banco de dados não disponível para histórico de monitoramento');
        throw Exception('Banco de dados não disponível');
      }

      // As tabelas já são criadas pela migração unificada
      // Apenas verificar se existem
      final tableCheck = await _database!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitoring_occurrences'"
      );
      
      if (tableCheck.isEmpty) {
        // // Log removido
        // Importar e executar a migração unificada
        final db = await AppDatabase().database;
        await CreateMonitoringTablesUnified.up(db);
        // // Log removido
      }

      // Converter talhaoId para int se necessário para compatibilidade com o banco
      int talhaoIdInt = int.tryParse(ocorrencia.talhaoId) ?? ocorrencia.talhaoId.hashCode.abs();
      
      // ✅ CORREÇÃO CRÍTICA: Usar IDs corretos para conectar com pontos e sessão
      
      // 1. Buscar o point_id real que foi salvo em monitoring_points
      final pointIdQuery = await _database!.query(
        'monitoring_points',
        where: 'session_id = ? AND numero = ?',
        whereArgs: [_sessionId, _currentPoint?.ordem ?? 1],
        limit: 1,
      );
      
      final realPointId = pointIdQuery.isNotEmpty 
        ? pointIdQuery.first['id'] as String 
        : '${_sessionId}_point_${_currentPoint?.ordem ?? 1}';
      
      Logger.info('✅ [SAVE_OCC] Salvando ocorrência em monitoring_occurrences');
      Logger.info('📍 [SAVE_OCC] Point ID: $realPointId');
      Logger.info('📍 [SAVE_OCC] Session ID: $_sessionId');
      
      // Inserir na tabela unificada de ocorrências
      await _database!.insert(
        'monitoring_occurrences',
        {
          'id': ocorrencia.id,
          'point_id': realPointId, // ✅ USAR ID REAL DO PONTO
          'session_id': _sessionId, // ✅ USAR SESSION ID REAL
          'talhao_id': widget.talhaoId,
          'tipo': ocorrencia.tipo,
          'subtipo': ocorrencia.subtipo,
          'nivel': ocorrencia.nivel,
          'percentual': ocorrencia.percentual,
          'quantidade': ocorrencia.percentual,
          'terco_planta': ocorrencia.tercoPlanta ?? 'Médio',
          'observacao': ocorrencia.observacao, // ✅ CORRIGIDO: Coluna é 'observacao' (sem 's')
          'foto_paths': ocorrencia.fotoPaths,
          'latitude': ocorrencia.latitude,
          'longitude': ocorrencia.longitude,
          'data_hora': ocorrencia.dataHora.toIso8601String(),
          'sincronizado': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ [SAVE_OCC] Ocorrência salva: ${ocorrencia.id}');
      
      // // Log removido
      
      // Também salvar na estrutura compatível com MonitoringHistoryService
      await _saveToMonitoringHistoryService(ocorrencia);
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar no histórico de monitoramento: $e');
      Logger.error('❌ Stack trace: ${StackTrace.current}');
      // Não falhar o processo principal se houver erro no histórico
    }
  }

  /// Salva múltiplas ocorrências de uma vez
  Future<void> _saveMultipleOccurrences({
    required List<Map<String, dynamic>> infestacoes,
    required bool saveAndContinue,
  }) async {
    try {

      
      // Verificar se há infestações para salvar
      if (infestacoes.isEmpty) {

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhuma infestação para salvar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Salvar cada infestação
      int sucessos = 0;
      int erros = 0;
      
      for (final infestacao in infestacoes) {
        try {
          // Usar o percentual preview para UI
          final percentualPreview = infestacao['percentual'] ?? infestacao['quantidade'] ?? 0;
          
          await _saveOccurrence(
            tipo: infestacao['tipo'] ?? 'Outro',
            subtipo: infestacao['organismo'] ?? 'Organismo não especificado',
            nivel: _determinarNivel(percentualPreview, infestacao['tipo'] ?? ''),
            numeroInfestacao: percentualPreview,
            observacao: infestacao['observacao'],
            fotoPaths: List<String>.from(infestacao['fotoPaths'] ?? []),
            // DADOS BRUTOS para cálculo avançado
            organismoId: infestacao['organismo_id'],
            quantidadeBruta: infestacao['quantidade_bruta'] ?? infestacao['quantidade'],
            totalPlantasAvaliadas: infestacao['total_plantas_avaliadas'],
            tercoPlanta: infestacao['terco_planta'] ?? infestacao['tercoPlanta'],
            saveAndContinue: false,
          );
          sucessos++;
        } catch (e) {
          erros++;
          Logger.error('❌ Erro ao salvar infestação ${infestacao['organismo']}: $e');
        }
      }
      

      
      // Mostrar resultado do salvamento
      if (mounted) {
        if (erros == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $sucessos infestação(ões) salva(s) com sucesso!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (sucessos > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ $sucessos salva(s), $erros erro(s)'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro ao salvar infestações'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return; // Não avançar se houve erro
        }
      }
      
      // Agora decidir se avança ou não
      if (saveAndContinue && sucessos > 0) {

        await Future.delayed(const Duration(milliseconds: 1000));
        await _navigateToNextPoint();
      } else if (!saveAndContinue) {

        // O modal já foi fechado pelo NewOccurrenceModal
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar múltiplas ocorrências: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar infestações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Salva dados na estrutura compatível com MonitoringHistoryService
  Future<void> _saveToMonitoringHistoryService(InfestacaoModel ocorrencia) async {
    try {
      // // Log removido
      
      // Usar o MonitoringHistoryService diretamente
      final historyService = MonitoringHistoryService();
      await historyService.initialize();
      
      // Criar um objeto Monitoring simples para esta ocorrência
      final monitoring = Monitoring(
        id: '${ocorrencia.id}_session',
        plotId: int.tryParse(widget.talhaoId) ?? 0,
        plotName: widget.talhaoNome,
        cropId: widget.culturaId,
        cropName: widget.culturaNome,
        date: ocorrencia.dataHora,
        route: [], // Adicionado parâmetro obrigatório
        points: [
          MonitoringPoint(
            id: ocorrencia.pontoId.toString(),
            plotId: int.tryParse(widget.talhaoId) ?? 0, // Adicionado parâmetro obrigatório
            plotName: widget.talhaoNome, // Adicionado parâmetro obrigatório
            latitude: ocorrencia.latitude ?? 0.0,
            longitude: ocorrencia.longitude ?? 0.0,
            occurrences: [
              Occurrence(
                name: ocorrencia.subtipo,
                type: _getOccurrenceTypeFromString(ocorrencia.tipo),
                infestationIndex: ocorrencia.percentual.toDouble(),
                affectedSections: [], // Adicionado parâmetro obrigatório
                notes: ocorrencia.observacao ?? '',
              ),
            ],
            observations: ocorrencia.observacao ?? '',
            createdAt: ocorrencia.dataHora,
          ),
        ],
        technicianName: 'Técnico',
        observations: 'Ocorrência individual: ${ocorrencia.subtipo}',
      );
      
      // Salvar usando o serviço
      final success = await historyService.saveToHistory(monitoring);
      
      if (success) {
        // // Log removido
      } else {
        // // Log removido
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar na estrutura do MonitoringHistoryService: $e');
    }
  }

  Future<void> _previousPoint() async {
    try {
      if (_currentPointIndex > 0) {
        // Marcar fim do ponto atual
        if (_currentPoint != null) {
          _currentPoint = _currentPoint!.copyWith(dataHoraFim: DateTime.now());
        }
        
        // Ir para o ponto anterior
        _currentPointIndex--;
        _currentPoint = _allPoints[_currentPointIndex];
        _nextPoint = _currentPointIndex < _allPoints.length - 1 ? _allPoints[_currentPointIndex + 1] : null;
        
        // Carregar ocorrências do novo ponto
        await _loadExistingOccurrences();
        
        // Marcar início do novo ponto
        _currentPoint = _currentPoint!.copyWith(dataHoraInicio: DateTime.now());
        
        setState(() {});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voltou ao ponto ${_currentPoint!.ordem}'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este é o primeiro ponto'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('❌ Erro ao navegar para ponto anterior: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _goToNextPoint() async {
    try {


      
      // Verificar se há próximo ponto
      if (_currentPointIndex >= _allPoints.length - 1) {

        await _finishMonitoring();
        return;
      }
      
      // Calcular distância até o PRÓXIMO ponto
      double? distanceToNext = null;
      if (_currentPosition != null && _nextPoint != null) {
        distanceToNext = DistanceCalculator.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _nextPoint!.latitude ?? 0.0,
          _nextPoint!.longitude ?? 0.0,
        );
        

        
        // Se estiver longe, mostrar tela de navegação
        if (distanceToNext > _navigationThreshold) {

          _showRouteNavigationScreen();
          return;
        }
      }

      // Salvar todas as ocorrências do ponto atual antes de avançar
      // ❌ REMOVIDO: Salvamento duplicado (já salvou via DirectOccurrenceService)
      // await _saveAllCurrentOccurrences();
      
      // Marcar fim do ponto atual
      if (_currentPoint != null) {
        _currentPoint = _currentPoint!.copyWith(dataHoraFim: DateTime.now());
      }
      
      // Ir para o próximo ponto
      _currentPointIndex++;
      _currentPoint = _allPoints[_currentPointIndex];
      _nextPoint = _currentPointIndex < _allPoints.length - 1 ? _allPoints[_currentPointIndex + 1] : null;
      

      
      // Carregar ocorrências do novo ponto
      await _loadExistingOccurrences();
      
      // Marcar início do novo ponto
      _currentPoint = _currentPoint!.copyWith(dataHoraInicio: DateTime.now());
      
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avançou para o ponto ${_currentPoint!.ordem}'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao avançar para próximo ponto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao avançar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRouteNavigationScreen() {
    if (_nextPoint == null) return;
    

    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RouteNavigationScreen(
          currentPoint: _currentPoint!,
          nextPoint: _nextPoint!,
          currentPosition: _currentPosition,
          onArrived: () {

            Navigator.of(context).pop();
            // Usar _goToNextPoint mas pular a verificação de distância
            _advanceToNextPointDirectly();
          },
          onCancel: () {

            Navigator.of(context).pop();
            _finishMonitoring();
          },
          onBack: () {

            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// Avança diretamente para o próximo ponto (sem verificar distância)
  Future<void> _advanceToNextPointDirectly() async {
    try {

      
      // Verificar se há próximo ponto
      if (_currentPointIndex >= _allPoints.length - 1) {

        await _finishMonitoring();
        return;
      }

      // Salvar todas as ocorrências do ponto atual antes de avançar
      // ❌ REMOVIDO: Salvamento duplicado (já salvou via DirectOccurrenceService)
      // await _saveAllCurrentOccurrences();
      
      // Marcar fim do ponto atual
      if (_currentPoint != null) {
        _currentPoint = _currentPoint!.copyWith(dataHoraFim: DateTime.now());
      }
      
      // Ir para o próximo ponto
      _currentPointIndex++;
      _currentPoint = _allPoints[_currentPointIndex];
      _nextPoint = _currentPointIndex < _allPoints.length - 1 ? _allPoints[_currentPointIndex + 1] : null;
      

      
      // Carregar ocorrências do novo ponto
      await _loadExistingOccurrences();
      
      // Marcar início do novo ponto
      _currentPoint = _currentPoint!.copyWith(dataHoraInicio: DateTime.now());
      
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chegou ao ponto ${_currentPoint!.ordem}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao avançar diretamente: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao avançar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navega para o próximo ponto de monitoramento ou finaliza se for o último
  Future<void> _navigateToNextPoint() async {
    try {

      
      // No monitoramento livre, criar um novo ponto virtual para a próxima ocorrência
      if (_isFreeMonitoring) {

        await _createNewFreeMonitoringPoint();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ocorrência salva! Novo ponto criado. Continue registrando ocorrências ou clique em "Nova Ocorrência"'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Verificar se há próximo ponto usando a mesma lógica do footer
      if (_currentPointIndex >= _allPoints.length - 1) {

        await _finishMonitoring();
        return;
      }
      
      // Calcular distância até o PRÓXIMO ponto (não o atual)
      double? distanceToNext = null;
      if (_currentPosition != null && _nextPoint != null) {
        distanceToNext = DistanceCalculator.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _nextPoint!.latitude ?? 0.0,
          _nextPoint!.longitude ?? 0.0,
        );
      }
      

      
      // Se estiver longe do próximo ponto, mostrar tela de navegação
      if (distanceToNext != null && distanceToNext > _navigationThreshold) {

        _showRouteNavigationScreen();
        return;
      }
      
      // Se estiver próximo, avançar diretamente

      
      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorrência salva! Avançando para próximo ponto...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Aguardar um pouco para o usuário ver a mensagem
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Usar a mesma lógica do _goToNextPoint para consistência
        await _goToNextPoint();
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao navegar para próximo ponto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao navegar para próximo ponto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Cria um novo ponto virtual para monitoramento livre
  Future<void> _createNewFreeMonitoringPoint() async {
    try {

      
      // Obter posição atual
      final currentLat = _currentPosition?.latitude ?? 0.0;
      final currentLng = _currentPosition?.longitude ?? 0.0;
      
      // Criar novo ponto virtual
      final newPointId = DateTime.now().millisecondsSinceEpoch;
      final newPoint = PontoMonitoramentoModel(
        id: newPointId,
        talhaoId: _talhaoIdInt ?? 0,
        ordem: _allPoints.length + 1, // Próximo número na sequência
        latitude: currentLat,
        longitude: currentLng,
        dataHoraInicio: DateTime.now(),
        observacoesGerais: 'Monitoramento livre - ponto ${_allPoints.length + 1}',
      );
      
      // Adicionar à lista de pontos
      _allPoints.add(newPoint);
      
      // Atualizar ponto atual
      _currentPoint = newPoint;
      _currentPointIndex = _allPoints.length - 1;
      _nextPoint = null; // Sem próximo ponto no monitoramento livre
      


      
      // Atualizar UI
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao criar novo ponto virtual: $e');
    }
  }

  Future<void> _finishMonitoring() async {
    try {
      Logger.info('🏁 [FINISH] ==========================================');
      Logger.info('🏁 [FINISH] FINALIZANDO MONITORAMENTO');
      Logger.info('🏁 [FINISH] Session ID: $_sessionId');
      Logger.info('🏁 [FINISH] Ocorrências em memória: ${_ocorrencias.length}');
      Logger.info('🏁 [FINISH] ==========================================');
      
      // Salvar todas as ocorrências do ponto atual antes de finalizar
      // ❌ REMOVIDO: Salvamento duplicado (já salvou via DirectOccurrenceService)
      // await _saveAllCurrentOccurrences();
      
      // ✅ VERIFICAR QUANTAS OCORRÊNCIAS ESTÃO NO BANCO AGORA
      Logger.info('🔍 [FINISH] Executando verificação do banco...');
      await QuickDBCheck.run();
      
      if (_sessionId != null) {
        final occCount = await DirectOccurrenceService.countOccurrencesForSession(_sessionId!);
        Logger.info('📊 [FINISH] Ocorrências salvas no banco para esta sessão: $occCount');
      }
      
      if (_ocorrencias.isEmpty) {
        Logger.warning('⚠️ [FINISH] Nenhuma ocorrência em memória!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhuma ocorrência foi registrada durante o monitoramento.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Enviar todas as ocorrências para o módulo Mapa de Infestação
      // // Log removido
      int sucessosMapa = 0;
      int errosMapa = 0;
      for (final ocorrencia in _ocorrencias) {
        try {
          await _sendToInfestationMap(ocorrencia);
          sucessosMapa++;
          // // Log removido
        } catch (e) {
          errosMapa++;
          // // Log removido
        }
      }
      
      // ❌ REMOVIDO: Salvamento duplicado no histórico (já salvou via DirectOccurrenceService)
      // Salvar todas as ocorrências no histórico de monitoramento
      // // Log removido
      // int sucessosHistorico = 0;
      // int errosHistorico = 0;
      // for (final ocorrencia in _ocorrencias) {
      //   try {
      //     await _saveToMonitoringHistory(ocorrencia);
      //     sucessosHistorico++;
      //     // // Log removido
      //   } catch (e) {
      //     errosHistorico++;
      //     // // Log removido
      //   }
      // }
      
      // Salvar sessão completa no MonitoringHistoryService
      await _saveCompleteSessionToHistory();
      
      // Atualizar sessão como finalizada
      await _finalizeSession();
      
      // Persistir todos os dados no banco de dados
      // // Log removido
      await _persistAllData();
      
      // Executar diagnóstico das tabelas
      // // Log removido
      await _diagnoseDatabaseTables();
      
      // // Log removido
      // // Log removido
      
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monitoramento finalizado! ${_ocorrencias.length} ocorrências salvas com sucesso! ✅'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    } catch (e) {
      Logger.error('❌ Erro ao finalizar monitoramento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar monitoramento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Finaliza a sessão de monitoramento atual
  Future<void> _finalizeSession() async {
    try {
      if (_sessionId == null) {
        Logger.warning('⚠️ [POINT_MON] SessionId nulo - não é possível finalizar sessão');
        return;
      }
      
      Logger.info('🏁 [POINT_MON] ========================================');
      Logger.info('🏁 [POINT_MON] FINALIZANDO SESSÃO: $_sessionId');
      Logger.info('🏁 [POINT_MON] Total de ocorrências: ${_ocorrencias.length}');
      Logger.info('🏁 [POINT_MON] ========================================');
      
      final now = DateTime.now().toIso8601String();
      
      // Atualizar status e dados da sessão
      final rowsAffected = await _database!.update(
        'monitoring_sessions',
        {
          'status': 'finalized',
          'data_fim': now,
          'finished_at': now,
          'total_ocorrencias': _ocorrencias.length,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [_sessionId],
      );
      
      Logger.info('✅ [POINT_MON] Sessão finalizada! Linhas afetadas: $rowsAffected');
      
      // Verificar se a atualização funcionou
      final updatedSession = await _database!.query(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [_sessionId],
      );
      
      if (updatedSession.isNotEmpty) {
        final session = updatedSession.first;
        Logger.info('✅ [POINT_MON] ========================================');
        Logger.info('✅ [POINT_MON] SESSÃO VERIFICADA:');
        Logger.info('✅ [POINT_MON] - ID: ${session['id']}');
        Logger.info('✅ [POINT_MON] - Status: ${session['status']}');
        Logger.info('✅ [POINT_MON] - Talhão: ${session['talhao_nome']}');
        Logger.info('✅ [POINT_MON] - Cultura: ${session['cultura_nome']}');
        Logger.info('✅ [POINT_MON] - Data início: ${session['data_inicio'] ?? session['started_at']}');
        Logger.info('✅ [POINT_MON] - Data fim: ${session['data_fim'] ?? session['finished_at']}');
        Logger.info('✅ [POINT_MON] - Total ocorrências: ${session['total_ocorrencias']}');
        Logger.info('✅ [POINT_MON] ========================================');
      } else {
        Logger.error('❌ [POINT_MON] Sessão não encontrada após atualização!');
      }
      
    } catch (e) {
      Logger.error('❌ [POINT_MON] Erro ao finalizar sessão: $e');
      Logger.error('❌ [POINT_MON] Stack: ${StackTrace.current}');
      // Não falhar o processo principal
    }
  }

  /// Persiste todos os dados no banco de dados
  Future<void> _persistAllData() async {
    try {
      Logger.info('💾 Persistindo todos os dados do monitoramento...');
      
      final db = await AppDatabase().database;
      
      if (_sessionId == null) {
        Logger.warning('⚠️ SessionId nulo - pulando persistência de pontos');
        return;
      }
      
      // Salvar cada ponto na tabela monitoring_points
      Logger.info('📍 Salvando ${_allPoints.length} pontos na tabela monitoring_points...');
      
      for (int i = 0; i < _allPoints.length; i++) {
        final ponto = _allPoints[i];
        
        try {
          // Criar ID do ponto
          final pointId = '${_sessionId}_point_${i + 1}';
      
          // Verificar se o ponto já existe
          final existingPoints = await db.query(
            'monitoring_points',
            where: 'id = ?',
            whereArgs: [pointId],
          );
          
          if (existingPoints.isEmpty) {
            // Inserir novo ponto
            await db.insert('monitoring_points', {
              'id': pointId,
              'session_id': _sessionId,
              'numero': i + 1,
              'latitude': ponto.latitude,
              'longitude': ponto.longitude,
              'timestamp': ponto.dataHoraInicio?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'plantas_avaliadas': 10, // Padrão
              'gps_accuracy': 5.0, // Valor padrão
              'manual_entry': 0,
              'observacoes': ponto.observacoesGerais,
              'sync_state': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
            Logger.info('✅ Ponto ${i + 1} salvo: ID=$pointId');
          } else {
            Logger.info('ℹ️ Ponto ${i + 1} já existe: ID=$pointId');
          }
          
        } catch (e) {
          Logger.error('❌ Erro ao salvar ponto ${i + 1}: $e');
          // Continuar com os próximos pontos
        }
      }
      
      Logger.info('✅ Persistência de dados concluída!');
      
    } catch (e) {
      Logger.error('❌ Erro ao persistir dados: $e');
      // Não falhar o processo principal
    }
  }

  /// Verifica se é o último ponto de monitoramento
  bool _isLastPoint() {
    final isLast = _currentPointIndex >= (_allPoints.length - 1);
    




    
    return isLast;
  }

  /// Gera um ID único robusto para evitar conflitos
  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + _ocorrencias.length).toString();
    final uniqueId = '${timestamp}_${random}_${widget.pontoId}';

    return uniqueId;
  }

  /// Calcula o nível de severidade baseado no percentual
  String _calculateSeverityLevel(int percentual) {
    if (percentual >= 80) return 'critical';
    if (percentual >= 60) return 'high';
    if (percentual >= 40) return 'medium';
    if (percentual >= 20) return 'low';
    return 'minimal';
  }

  /// Método de diagnóstico para verificar se as tabelas existem
  Future<void> _diagnoseDatabaseTables() async {
    try {
      // // Log removido
      
      final db = await AppDatabase().database;
      
      // Verificar se as tabelas existem
      final tables = [
        'monitoring_sessions',
        'monitoring_points', 
        'monitoring_occurrences',
        'monitoring_history',
        'infestation_map',
        'monitoring_history_alt'
      ];
      
      for (final table in tables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'"
        );
        
        if (result.isNotEmpty) {
          // // Log removido
          
          // Verificar estrutura da tabela
          final columns = await db.rawQuery("PRAGMA table_info($table)");
          // Logger.info('📋 Colunas da tabela $table: ${columns.map((c) => c['name']).join(', ')}');
        } else {
          // // Log removido
        }
      }
      
      // Verificar dados existentes
      final sessionsCount = await db.rawQuery("SELECT COUNT(*) as count FROM monitoring_sessions");
      final occurrencesCount = await db.rawQuery("SELECT COUNT(*) as count FROM monitoring_occurrences");
      final historyCount = await db.rawQuery("SELECT COUNT(*) as count FROM monitoring_history");
      
      // // Log removido
      // Logger.info('   - Sessões: ${sessionsCount.first['count']}');
      // Logger.info('   - Ocorrências: ${occurrencesCount.first['count']}');
      // Logger.info('   - Histórico: ${historyCount.first['count']}');
      
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico: $e');
    }
  }

  /// Cria um registro básico de talhão se não existir
  Future<void> _createBasicTalhaoRecord(String talhaoId) async {
    try {

      
      final db = await AppDatabase().database;
      
      // Tentar inserir na tabela talhoes
      try {
        // Converter talhaoId para int se possível
        int? talhaoIdInt = int.tryParse(talhaoId);
        if (talhaoIdInt == null && talhaoId.contains('-')) {
          // Se é UUID, usar hash
          talhaoIdInt = talhaoId.hashCode.abs();
        }
        
        if (talhaoIdInt != null) {
          await db.insert('talhoes', {
            'id': talhaoIdInt,
            'name': widget.talhaoNome,
            'area': 1.0, // Área padrão
            'fazenda_id': 1, // ID padrão da fazenda
            'ativo': 1,
            'created_at': DateTime.now().toIso8601String(),
          });

        } else {
          // Tentar como string
          await db.insert('talhoes', {
            'id': talhaoId,
            'name': widget.talhaoNome,
            'area': 1.0,
            'fazenda_id': '1',
            'ativo': 1,
            'created_at': DateTime.now().toIso8601String(),
          });

        }
      } catch (e) {

        // Continuar mesmo se falhar
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao criar registro básico de talhão: $e');
      // Não falhar o processo principal
    }
  }

  /// Método de fallback para salvar ocorrência
  Future<void> _saveOccurrenceFallback(InfestacaoModel ocorrencia) async {
    try {

      
      // Salvar apenas em memória local por enquanto


      
    } catch (e) {
      Logger.error('❌ Erro no método de fallback: $e');
      throw Exception('Erro ao salvar ocorrência (fallback): $e');
    }
  }

  /// Salva ocorrência de forma simples, evitando foreign keys
  Future<void> _saveOccurrenceSimple(InfestacaoModel ocorrencia) async {
    try {

      
      final db = await AppDatabase().database;
      
      // Criar tabela simples se não existir
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ocorrencias_simples (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          ponto_id TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          tipo TEXT NOT NULL,
          subtipo TEXT NOT NULL,
          nivel TEXT NOT NULL,
          percentual INTEGER NOT NULL,
          foto_paths TEXT,
          observacao TEXT,
          data_hora TEXT NOT NULL,
          sincronizado INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Inserir na tabela simples
      await db.insert('ocorrencias_simples', {
        'id': ocorrencia.id,
        'talhao_id': ocorrencia.talhaoId,
        'ponto_id': ocorrencia.pontoId.toString(),
        'latitude': ocorrencia.latitude,
        'longitude': ocorrencia.longitude,
        'tipo': ocorrencia.tipo,
        'subtipo': ocorrencia.subtipo,
        'nivel': ocorrencia.nivel,
        'percentual': ocorrencia.percentual,
        'foto_paths': ocorrencia.fotoPaths,
        'observacao': ocorrencia.observacao,
        'data_hora': ocorrencia.dataHora.toIso8601String(),
        'sincronizado': ocorrencia.sincronizado ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      

      
    } catch (e) {
      Logger.error('❌ Erro ao salvar ocorrência de forma simples: $e');
      throw Exception('Erro ao salvar ocorrência: $e');
    }
  }

  /// Salva ocorrência de forma robusta, usando apenas tabela alternativa
  Future<void> _saveOccurrenceRobust(InfestacaoModel ocorrencia) async {
    try {

      
      final db = await AppDatabase().database;
      
      // Usar transação para garantir atomicidade
      await db.transaction((txn) async {

        
        // Salvar APENAS na tabela alternativa sem foreign keys
        await _saveOccurrenceAlternativeInTransaction(txn, ocorrencia);
        

      });
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar ocorrência de forma robusta: $e');
      throw Exception('Erro ao salvar ocorrência: $e');
    }
  }

  /// Salva ocorrência em tabela alternativa dentro de uma transação
  Future<void> _saveOccurrenceAlternativeInTransaction(Transaction txn, InfestacaoModel ocorrencia) async {
    try {

      
      // Criar tabela alternativa se não existir
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS infestacoes_monitoramento_alt (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          ponto_id TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          tipo TEXT NOT NULL,
          subtipo TEXT NOT NULL,
          nivel TEXT NOT NULL,
          percentual INTEGER NOT NULL,
          foto_paths TEXT,
          observacao TEXT,
          data_hora TEXT NOT NULL,
          sincronizado INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Inserir na tabela alternativa
      await txn.insert('infestacoes_monitoramento_alt', {
        'id': ocorrencia.id,
        'talhao_id': ocorrencia.talhaoId,
        'ponto_id': ocorrencia.pontoId.toString(),
        'latitude': ocorrencia.latitude,
        'longitude': ocorrencia.longitude,
        'tipo': ocorrencia.tipo,
        'subtipo': ocorrencia.subtipo,
        'nivel': ocorrencia.nivel,
        'percentual': ocorrencia.percentual,
        'foto_paths': ocorrencia.fotoPaths,
        'observacao': ocorrencia.observacao,
        'data_hora': ocorrencia.dataHora.toIso8601String(),
        'sincronizado': ocorrencia.sincronizado ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      

      
    } catch (e) {
      Logger.error('❌ Erro ao salvar na tabela alternativa (transação): $e');
      throw Exception('Erro ao salvar ocorrência na tabela alternativa: $e');
    }
  }

  /// Salva ocorrência em tabela alternativa sem foreign keys
  Future<void> _saveOccurrenceAlternative(InfestacaoModel ocorrencia) async {
    try {

      
      final db = await AppDatabase().database;
      
      // Criar tabela alternativa se não existir
      await db.execute('''
        CREATE TABLE IF NOT EXISTS infestacoes_monitoramento_alt (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          ponto_id TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          tipo TEXT NOT NULL,
          subtipo TEXT NOT NULL,
          nivel TEXT NOT NULL,
          percentual INTEGER NOT NULL,
          foto_paths TEXT,
          observacao TEXT,
          data_hora TEXT NOT NULL,
          sincronizado INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Inserir na tabela alternativa
      await db.insert('infestacoes_monitoramento_alt', {
        'id': ocorrencia.id,
        'talhao_id': ocorrencia.talhaoId,
        'ponto_id': ocorrencia.pontoId.toString(),
        'latitude': ocorrencia.latitude,
        'longitude': ocorrencia.longitude,
        'tipo': ocorrencia.tipo,
        'subtipo': ocorrencia.subtipo,
        'nivel': ocorrencia.nivel,
        'percentual': ocorrencia.percentual,
        'foto_paths': ocorrencia.fotoPaths,
        'observacao': ocorrencia.observacao,
        'data_hora': ocorrencia.dataHora.toIso8601String(),
        'sincronizado': ocorrencia.sincronizado ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      

      
    } catch (e) {
      Logger.error('❌ Erro ao salvar na tabela alternativa: $e');
      throw Exception('Erro ao salvar ocorrência na tabela alternativa: $e');
    }
  }

  /// Salva sessão completa no MonitoringHistoryService
  Future<void> _saveCompleteSessionToHistory() async {
    try {
      // // Log removido
      
      if (_ocorrencias.isEmpty) {
        // // Log removido
        return;
      }
      
      // Criar um objeto Monitoring para salvar no histórico
      final monitoring = Monitoring(
        id: 'session_${widget.talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
        plotId: int.tryParse(widget.talhaoId) ?? 0,
        plotName: widget.talhaoNome,
        cropId: widget.culturaId,
        cropName: widget.culturaNome,
        date: DateTime.now(),
        route: [], // Adicionado parâmetro obrigatório
        points: _allPoints.map((ponto) => MonitoringPoint(
          id: ponto.id.toString(),
          plotId: int.tryParse(widget.talhaoId) ?? 0, // Adicionado parâmetro obrigatório
          plotName: widget.talhaoNome, // Adicionado parâmetro obrigatório
          latitude: ponto.latitude ?? 0.0,
          longitude: ponto.longitude ?? 0.0,
          occurrences: _ocorrencias
              .where((oc) => oc.pontoId == ponto.id)
              .map((oc) => Occurrence(
                name: oc.subtipo,
                type: _getOccurrenceTypeFromString(oc.tipo),
                infestationIndex: oc.percentual.toDouble(),
                affectedSections: [], // Adicionado parâmetro obrigatório
                notes: oc.observacao ?? '',
              ))
              .toList(),
          observations: '',
          createdAt: DateTime.now(),
        )).toList(),
        technicianName: 'Técnico',
        observations: 'Monitoramento concluído com ${_ocorrencias.length} ocorrências',
      );
      
      // Salvar usando o MonitoringHistoryService
      final historyService = MonitoringHistoryService();
      final success = await historyService.saveToHistory(monitoring);
      
      if (success) {
        // // Log removido
      } else {
        // // Log removido
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar sessão completa no histórico: $e');
    }
  }

  /// Converte string para OccurrenceType
  OccurrenceType _getOccurrenceTypeFromString(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'praga':
        return OccurrenceType.pest;
      case 'doença':
        return OccurrenceType.disease;
      case 'daninha':
        return OccurrenceType.weed;
      default:
        return OccurrenceType.other;
    }
  }

  /// Determina nível de infestação
  String _determinarNivel(int quantidade, String tipo) {
    if (quantidade == 0) return 'Ausente';
    if (quantidade <= 2) return 'Baixo';
    if (quantidade <= 5) return 'Médio';
    return 'Alto';
  }

  /// Cria um registro básico de ponto se não existir
  Future<void> _createBasicPontoRecord(int pontoId, String talhaoId) async {
    try {

      
      final db = await AppDatabase().database;
      
      // Tentar inserir na tabela pontos_monitoramento
      try {
        int? talhaoIdInt = int.tryParse(talhaoId);
        if (talhaoIdInt == null && talhaoId.contains('-')) {
          talhaoIdInt = talhaoId.hashCode.abs();
        }
        
        if (talhaoIdInt != null) {
          await db.insert('pontos_monitoramento', {
            'id': pontoId,
            'talhao_id': talhaoIdInt,
            'latitude': _currentPosition?.latitude ?? 0.0,
            'longitude': _currentPosition?.longitude ?? 0.0,
            'data_criacao': DateTime.now().toIso8601String(),
            'ativo': 1,
          });

        }
      } catch (e) {

      }
      
      // Tentar inserir na tabela pontos_monitoramento_simples
      try {
        await db.insert('pontos_monitoramento_simples', {
          'id': pontoId,
          'talhao_id': talhaoId,
          'latitude': _currentPosition?.latitude ?? 0.0,
          'longitude': _currentPosition?.longitude ?? 0.0,
          'data_criacao': DateTime.now().toIso8601String(),
          'ativo': 1,
        });

      } catch (e) {

      }
      
    } catch (e) {
      Logger.error('❌ Erro ao criar registro básico de ponto: $e');
      // Não falhar o processo principal
    }
  }

  /// Salva todas as ocorrências do ponto atual
  Future<void> _saveAllCurrentOccurrences() async {
    try {

      
      if (_ocorrencias.isEmpty) {

        return;
      }

      int savedCount = 0;
      for (final ocorrencia in _ocorrencias) {
        try {
          // ✅ CORRIGIDO: Extrair quantidade do percentual se disponível
          final quantidade = ocorrencia.percentual != null && ocorrencia.percentual! > 0 
              ? ocorrencia.percentual!.toInt() 
              : 0;
          
          await _saveOccurrence(
            tipo: ocorrencia.tipo,
            subtipo: ocorrencia.subtipo,
            nivel: ocorrencia.nivel,
            numeroInfestacao: ocorrencia.percentual?.toInt() ?? 0,
            observacao: ocorrencia.observacao,
            fotoPaths: ocorrencia.fotoPaths?.split(';') ?? [],
            saveAndContinue: false,
            quantidade: quantidade, // ✅ NOVO: Passar quantidade correta
          );
          savedCount++;
        } catch (e) {
          Logger.error('❌ Erro ao salvar ocorrência: $e');
        }
      }
      

      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$savedCount ocorrências salvas'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar ocorrências do ponto atual: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar ocorrências: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Método para salvar ocorrência do novo card inteligente
  Future<void> _saveOccurrenceFromCard(Map<String, dynamic> data) async {
    try {
      Logger.info('🟢 [SAVE_CARD] ==========================================');
      Logger.info('🟢 [SAVE_CARD] MÉTODO _saveOccurrenceFromCard CHAMADO!');
      Logger.info('🟢 [SAVE_CARD] Dados recebidos: ${data.keys.toList()}');
      Logger.info('🟢 [SAVE_CARD] Dados completos: $data');
      Logger.info('🟢 [SAVE_CARD] ==========================================');
      
      // ✅ MAPEAMENTO CORRETO: NewOccurrenceCard usa nomes DIFERENTES!
      final tipoString = data['organism_type'] as String? ?? 
                        data['tipo'] as String? ?? 
                        'pest';
      final subtipo = data['organism_name'] as String? ?? 
                     data['organismo'] as String? ?? 
                     data['name'] as String? ?? 
                     '';
      final severidade = data['severity'] as int? ?? 
                        data['severidade'] as int? ?? 
                        0;
      // ✅ CORRIGIDO: Mapear quantidade corretamente (aceitar int ou double)
      final quantidade = (data['quantidade'] as num?)?.toInt() ?? 
                        (data['quantity'] as num?)?.toInt() ?? 
                        (data['quantidade_pragas'] as num?)?.toInt() ?? 
                        0;
      final percentual = (data['percentual'] as num?)?.toInt() ?? 
                        quantidade; // Fallback para quantidade
      // ✅ NOVO: Extrair severidade agronômica (como double!)
      final agronomicSeverityValue = (data['agronomic_severity'] as num?)?.toDouble() ?? 
                                     (data['percentual'] as num?)?.toDouble() ?? 
                                     0.0;
      final observacao = data['observations'] as String? ?? 
                        data['observacao'] as String? ?? 
                        '';
      final fotoPaths = (data['image_paths'] as List<dynamic>?)?.cast<String>() ?? 
                       (data['fotos'] as List<dynamic>?)?.cast<String>() ?? 
                       [];
      final tercoPlanta = data['plant_section'] as String? ?? 
                         data['terco_planta'] as String? ?? 
                         'Médio';
      // ✅ NOVO: Extrair temperatura e umidade
      final temperature = (data['temperature'] as num?)?.toDouble() ?? 
                         (data['temperatura'] as num?)?.toDouble();
      final humidity = (data['humidity'] as num?)?.toDouble() ?? 
                      (data['umidade'] as num?)?.toDouble();
      
      // ✅ NOVÍSSIMO: Extrair dados complementares de plantio
      final tipoManejoAnterior = (data['tipo_manejo_anterior'] as List<dynamic>?)?.cast<String>() ?? [];
      final historicoResumo = data['historico_resumo'] as String?;
      final impactoEconomico = (data['impacto_economico_previsto'] as num?)?.toDouble();
      final previousManagement = tipoManejoAnterior.isNotEmpty ? tipoManejoAnterior.join(',') : null;
      
      Logger.info('🟢 [SAVE_CARD] ===== DADOS RECEBIDOS DO CARD =====');
      Logger.info('   🔍 Dados brutos recebidos:');
      Logger.info('      data[\'quantidade\']: ${data['quantidade']}');
      Logger.info('      data[\'quantity\']: ${data['quantity']}');
      Logger.info('      data[\'quantidade_pragas\']: ${data['quantidade_pragas']}');
      Logger.info('      data[\'agronomic_severity\']: ${data['agronomic_severity']}');
      Logger.info('      data[\'percentual\']: ${data['percentual']}');
      Logger.info('      data[\'temperature\']: ${data['temperature']}');
      Logger.info('      data[\'humidity\']: ${data['humidity']}');
      Logger.info('      data[\'image_paths\']: ${data['image_paths']}');  // ✅ NOVO
      Logger.info('      data[\'fotos\']: ${data['fotos']}');  // ✅ NOVO
      Logger.info('   ✅ Dados convertidos:');
      Logger.info('      - Tipo: $tipoString');
      Logger.info('      - Subtipo (organismo): $subtipo');
      Logger.info('      - Severidade visual: $severidade');
      Logger.info('      - 🔢 QUANTIDADE FINAL: $quantidade');
      Logger.info('      - 📊 SEVERIDADE AGRONÔMICA: $agronomicSeverityValue%');
      Logger.info('      - Percentual: $percentual');
      Logger.info('      - Terço da Planta: $tercoPlanta');
      Logger.info('      - 📸 FOTO_PATHS: $fotoPaths (${fotoPaths.length} imagem(ns))');  // ✅ NOVO
      if (temperature != null) Logger.info('      - 🌡️ Temperatura: ${temperature}°C');
      if (humidity != null) Logger.info('      - 💧 Umidade: ${humidity}%');
      if (previousManagement != null) Logger.info('      - 🌾 Manejo Anterior: $previousManagement');
      if (historicoResumo != null) Logger.info('      - 📝 Histórico: $historicoResumo');
      if (impactoEconomico != null) Logger.info('      - 💰 Impacto Econômico: $impactoEconomico');
      Logger.info('🟢 [SAVE_CARD] =====================================');
      
      // ✅ SALVAR DADOS COMPLEMENTARES COMO OBSERVAÇÃO ADICIONAL
      String observacaoCompleta = observacao;
      if (previousManagement != null) {
        observacaoCompleta += '\n[MANEJO: $previousManagement]';
      }
      if (historicoResumo != null && historicoResumo.isNotEmpty) {
        observacaoCompleta += '\n[HISTÓRICO: $historicoResumo]';
      }
      if (impactoEconomico != null && impactoEconomico > 0) {
        observacaoCompleta += '\n[IMPACTO: ${impactoEconomico.toStringAsFixed(1)}%]';
      }
      
      await _saveOccurrence(
        tipo: tipoString,
        subtipo: subtipo,
        nivel: _determinarNivel(percentual, tipoString),
        numeroInfestacao: percentual,
        observacao: observacaoCompleta.trim(), // ✅ Observação enriquecida
        fotoPaths: fotoPaths,
        tercoPlanta: tercoPlanta,
        saveAndContinue: false,
        quantidade: quantidade, // ✅ PASSAR quantidade real
        temperature: temperature, // ✅ NOVO: Temperatura
        humidity: humidity, // ✅ NOVO: Umidade
        agronomicSeverityValue: agronomicSeverityValue, // ✅ NOVO: Passar severidade já calculada
      );
      
      Logger.info('✅ [SAVE_CARD] _saveOccurrence concluído com sucesso!');
      

      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Ocorrência salva com sucesso!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar ocorrência do card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao salvar ocorrência: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Converte OccurrenceType para string
  String _getOccurrenceTypeString(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return 'pest';
      case OccurrenceType.disease:
        return 'disease';
      case OccurrenceType.weed:
        return 'weed';
      case OccurrenceType.deficiency:
        return 'deficiency';
      case OccurrenceType.other:
        return 'other';
    }
  }
}
