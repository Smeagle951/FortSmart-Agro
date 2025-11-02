import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../../database/app_database.dart';
import '../../models/infestacao_model.dart';
import '../../models/ponto_monitoramento_model.dart';
import '../../repositories/infestacao_repository.dart';
import '../../utils/logger.dart';
import '../../utils/distance_calculator.dart';
import '../../utils/image_compression_service.dart';
import '../../services/monitoring_infestation_integration_service.dart';
import '../../services/smart_monitoring_navigation_service.dart';
import '../../services/background_monitoring_service.dart';
import '../monitoring/widgets/occurrence_type_selector.dart';
import '../monitoring/widgets/organism_search_field.dart';
import '../monitoring/widgets/quantity_input_field.dart';
import '../monitoring/widgets/occurrences_list_widget.dart';
import 'waiting_next_point_screen.dart';
import 'smart_navigation_screen.dart';

/// Tela unificada de ponto de monitoramento com design elegante
/// 
/// Esta tela resolve todos os problemas identificados:
/// - Tela única (sem básica vs avançada)
/// - Botões coloridos suaves para seleção de tipo
/// - Busca com autocomplete para organismos
/// - Input numérico em vez de percentual
/// - Lista sempre visível de ocorrências
/// - Design elegante com cores suaves e sombras discretas
class UnifiedPointMonitoringScreen extends StatefulWidget {
  final int pontoId;
  final int talhaoId;
  final int culturaId;

  const UnifiedPointMonitoringScreen({
    Key? key,
    required this.pontoId,
    required this.talhaoId,
    required this.culturaId,
  }) : super(key: key);

  @override
  State<UnifiedPointMonitoringScreen> createState() => _UnifiedPointMonitoringScreenState();
}

class _UnifiedPointMonitoringScreenState extends State<UnifiedPointMonitoringScreen> {
  // Estado da tela
  bool _isLoading = true;
  String? _error;
  Position? _currentPosition;
  double _distanceToPoint = 0.0;
  bool _isAtPoint = false;
  bool _isSaving = false;
  
  // Estado de navegação
  bool _hasOccurrences = false;
  bool _canSaveAndAdvance = false;
  bool _canGoBack = false;
  Timer? _locationTimer;
  bool _isNearNextPoint = false;
  
  // Estado do mapa GPS
  MapController? _mapController;
  LatLng? _deviceLocation;
  LatLng? _targetLocation;
  List<LatLng> _routePoints = [];
  bool _showMap = true;
  
  // Dados do monitoramento
  List<InfestacaoModel> _ocorrencias = [];
  List<PontoMonitoramentoModel> _pontos = [];
  String _culturaNome = '';
  
  // Formulário de nova ocorrência
  String? _selectedType;
  String? _selectedOrganism;
  int _quantity = 0;
  String _observacao = '';
  List<String> _fotoPaths = [];
  
  // Repositórios e serviços
  InfestacaoRepository? _infestacaoRepository;
  Database? _database;
  final MonitoringInfestationIntegrationService _integrationService = 
      MonitoringInfestationIntegrationService();
  
  // Sistema inteligente de navegação
  final SmartMonitoringNavigationService _smartNavigationService = SmartMonitoringNavigationService();
  final BackgroundMonitoringService _backgroundService = BackgroundMonitoringService();
  bool _isSmartNavigationActive = false;
  bool _canCreateOccurrence = false;
  bool _isNearPoint = false;
  bool _isAtPoint = false;
  
  // Constantes de validação
  static const double _maxGpsAccuracy = 10.0;
  static const double _arrivalThreshold = 2.0;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeScreen();
    _startLocationTracking();
    _startSmartNavigation();
    _startBackgroundService();
  }
  
  @override
  void dispose() {
    _locationTimer?.cancel();
    _smartNavigationService.stopSmartTracking();
    _backgroundService.stopBackgroundService();
    super.dispose();
  }
  
  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final pontoId = widget.pontoId is int ? widget.pontoId : int.tryParse(widget.pontoId.toString()) ?? 0;
      final talhaoId = widget.talhaoId is int ? widget.talhaoId : int.tryParse(widget.talhaoId.toString()) ?? 0;
      
      await _initializeDatabase();
      await _integrationService.initialize();
      await _processMonitoringPoints(talhaoId);
      await _loadExistingOccurrences();
      _startGpsMonitoring();
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro na inicialização: $e');
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
      Logger.info('✅ [UNIFIED] Banco de dados inicializado');
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao inicializar banco: $e');
      rethrow;
    }
  }
  
  Future<void> _processMonitoringPoints(int talhaoId) async {
    try {
      final pontos = await _database!.query(
        'monitoring_points',
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'sequence ASC',
      );
      
      setState(() {
        _pontos = pontos.map((row) => PontoMonitoramentoModel.fromMap(row)).toList();
      });
      
      // Obter nome da cultura
      if (_pontos.isNotEmpty) {
        final cultura = await _database!.query(
          'culturas',
          where: 'id = ?',
          whereArgs: [widget.culturaId],
        );
        
        if (cultura.isNotEmpty) {
          setState(() {
            _culturaNome = cultura.first['nome'] as String? ?? 'Cultura';
          });
        }
      }
      
      Logger.info('✅ [UNIFIED] ${_pontos.length} pontos de monitoramento carregados');
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao carregar pontos: $e');
    }
  }
  
  Future<void> _loadExistingOccurrences() async {
    try {
      final ocorrencias = await _infestacaoRepository!.getByPontoId(widget.pontoId);
      setState(() {
        _ocorrencias = ocorrencias;
      });
      Logger.info('✅ [UNIFIED] ${_ocorrencias.length} ocorrências carregadas');
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao carregar ocorrências: $e');
    }
  }
  
  void _startGpsMonitoring() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen(
      (Position position) {
        _updateGpsPosition(position);
      },
      onError: (error) {
        Logger.error('❌ [UNIFIED] Erro GPS: $error');
      },
    );
  }
  
  void _updateGpsPosition(Position position) {
    setState(() {
      _currentPosition = position;
    });
    
    // Calcular distância até o ponto atual
    if (_pontos.isNotEmpty) {
      final pontoAtual = _pontos.firstWhere(
        (p) => p.id == widget.pontoId,
        orElse: () => _pontos.first,
      );
      
      if (pontoAtual.latitude != null && pontoAtual.longitude != null) {
        final distance = DistanceCalculator.calculateDistance(
          position.latitude,
          position.longitude,
          pontoAtual.latitude!,
          pontoAtual.longitude!,
        );
        
        setState(() {
          _distanceToPoint = distance;
          _isAtPoint = distance <= _arrivalThreshold;
        });
      }
    }
  }
  
  /// Inicia o sistema inteligente de navegação
  Future<void> _startSmartNavigation() async {
    if (_pontos.isEmpty) return;
    
    final currentPoint = _pontos.firstWhere(
      (p) => p.id == widget.pontoId,
      orElse: () => _pontos.first,
    );
    
    if (currentPoint.latitude == null || currentPoint.longitude == null) return;
    
    final targetPoint = LatLng(
      currentPoint.latitude!,
      currentPoint.longitude!,
    );
    
    await _smartNavigationService.startSmartTracking(
      targetPoint: targetPoint,
      onLocationUpdate: _onSmartLocationUpdate,
      onDistanceUpdate: _onSmartDistanceUpdate,
      onProximityChange: _onSmartProximityChange,
      onArrivalChange: _onSmartArrivalChange,
      onVibrationNotification: _onSmartVibrationNotification,
      onBackgroundSaveComplete: _onSmartBackgroundSaveComplete,
      talhaoId: widget.talhaoId.toString(),
    );
    
    setState(() {
      _isSmartNavigationActive = true;
    });
  }
  
  /// Inicia o serviço de persistência em segundo plano
  Future<void> _startBackgroundService() async {
    await _backgroundService.startBackgroundService(
      onDataSaved: _onBackgroundDataSaved,
      onDataRestored: _onBackgroundDataRestored,
      onError: _onBackgroundError,
    );
  }
  
  /// Callback de atualização de localização inteligente
  void _onSmartLocationUpdate(Position position) {
    setState(() {
      _currentPosition = position;
    });
  }
  
  /// Callback de atualização de distância inteligente
  void _onSmartDistanceUpdate(double distance) {
    setState(() {
      _distanceToPoint = distance;
    });
  }
  
  /// Callback de mudança de proximidade inteligente
  void _onSmartProximityChange(bool isNearPoint) {
    setState(() {
      _isNearPoint = isNearPoint;
    });
    
    if (isNearPoint) {
      _showProximityNotification();
    }
  }
  
  /// Callback de chegada ao ponto inteligente
  void _onSmartArrivalChange(bool isAtPoint) {
    setState(() {
      _isAtPoint = isAtPoint;
      _canCreateOccurrence = isAtPoint;
    });
    
    if (isAtPoint) {
      _showArrivalNotification();
    }
  }
  
  /// Callback de notificação vibratória inteligente
  void _onSmartVibrationNotification() {
    // Vibração já foi disparada pelo serviço
  }
  
  /// Callback de salvamento em segundo plano inteligente
  void _onSmartBackgroundSaveComplete() {
    Logger.info('💾 [SMART] Dados salvos em segundo plano');
  }
  
  /// Callback de dados salvos em segundo plano
  void _onBackgroundDataSaved() {
    Logger.info('💾 [BACKGROUND] Dados salvos com sucesso');
  }
  
  /// Callback de dados restaurados em segundo plano
  void _onBackgroundDataRestored() {
    Logger.info('🔄 [BACKGROUND] Dados restaurados com sucesso');
  }
  
  /// Callback de erro em segundo plano
  void _onBackgroundError(String error) {
    Logger.error('❌ [BACKGROUND] Erro: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro em segundo plano: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  /// Mostra notificação de proximidade
  void _showProximityNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.near_me, color: Colors.white),
            SizedBox(width: 8),
            Text('Aproximando-se do ponto de monitoramento'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Mostra notificação de chegada
  void _showArrivalNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.white),
            SizedBox(width: 8),
            Text('Você chegou ao ponto! Pode registrar ocorrências'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  Future<void> _saveOccurrence() async {
    if (_selectedType == null || _selectedOrganism == null || _quantity < 0) {
      _showErrorSnackBar('Preencha todos os campos obrigatórios e defina uma quantidade válida');
      return;
    }
    
    try {
      final novaOcorrencia = InfestacaoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pontoId: widget.pontoId,
        talhaoId: widget.talhaoId,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        tipo: _selectedType!,
        subtipo: _selectedOrganism!,
        nivel: _getNivelFromQuantity(_quantity),
        percentual: _quantity, // Agora armazena quantidade numérica
        observacao: _observacao.isNotEmpty ? _observacao : null,
        fotoPaths: _fotoPaths.isNotEmpty ? _fotoPaths.join(';') : null,
        dataHora: DateTime.now(),
        sincronizado: false,
      );
      
      await _infestacaoRepository!.insert(novaOcorrencia);
      
      setState(() {
        _ocorrencias = [..._ocorrencias, novaOcorrencia];
      });
      
      // Atualizar estados dos botões
      _updateButtonStates();
      
      // Enviar para o mapa de infestação
      await _integrationService.sendMonitoringDataToInfestationMap(
        occurrence: novaOcorrencia,
        preventDuplicates: true,
      );
      
      // Salvar no histórico de monitoramento
      await _saveToMonitoringHistory(novaOcorrencia);
      
      _clearForm();
      
      if (mounted) {
        _showSuccessSnackBar('Ocorrência salva com sucesso!');
      }
      
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao salvar ocorrência: $e');
      _showErrorSnackBar('Erro ao salvar ocorrência: $e');
    }
  }
  
  Future<void> _saveAndContinueOccurrence() async {
    if (_isSaving) {
      Logger.warning('⚠️ [UNIFIED] _saveAndContinueOccurrence já está em execução');
      return;
    }
    
    // VALIDAÇÃO DE DISTÂNCIA - Só permite salvar se estiver no ponto
    if (!_canCreateOccurrence) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Você precisa estar no ponto para salvar ocorrências'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    Logger.info('🔄 [UNIFIED] Iniciando _saveAndContinueOccurrence...');
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Salvar a ocorrência primeiro
      await _saveOccurrence();
      Logger.info('✅ [UNIFIED] Ocorrência salva com sucesso');
      
      // Salvar dados em segundo plano
      await _saveBackgroundData();
      
      // Mostrar feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorrência salva! Avançando para próximo ponto...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Aguardar um pouco e navegar diretamente
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Navegar para o próximo ponto
        _navigateToNextPoint();
      }
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro em _saveAndContinueOccurrence: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar e avançar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  /// Salva dados em segundo plano
  Future<void> _saveBackgroundData() async {
    try {
      if (_pontos.isNotEmpty) {
        final currentPoint = _pontos.firstWhere(
          (p) => p.id == widget.pontoId,
          orElse: () => _pontos.first,
        );
        
        await _backgroundService.saveMonitoringData(
          currentPoint: currentPoint,
          occurrences: _ocorrencias,
          navigationState: {
            'isAtPoint': _isAtPoint,
            'canCreateOccurrence': _canCreateOccurrence,
            'distanceToPoint': _distanceToPoint,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao salvar dados em segundo plano: $e');
    }
  }
  
  /// Abre a tela de navegação inteligente
  void _openSmartNavigation() {
    if (_pontos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum ponto de monitoramento disponível'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final currentPoint = _pontos.firstWhere(
      (p) => p.id == widget.pontoId,
      orElse: () => _pontos.first,
    );
    
    final nextPoint = _getNextPoint();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SmartNavigationScreen(
          currentPoint: currentPoint,
          nextPoint: nextPoint,
          cropName: _culturaNome,
          fieldName: 'Talhão ${widget.talhaoId}',
          onArriveAtPoint: () {
            setState(() {
              _canCreateOccurrence = true;
            });
          },
          onNavigateToNextPoint: _navigateToNextPoint,
        ),
      ),
    );
  }
  
  /// Obtém o próximo ponto
  MonitoringPoint? _getNextPoint() {
    final currentIndex = _pontos.indexWhere((p) => p.id == widget.pontoId);
    if (currentIndex == -1 || currentIndex >= _pontos.length - 1) {
      return null;
    }
    return _pontos[currentIndex + 1];
  }
  
  String? _getNextPointId() {
    // Implementar lógica para obter próximo ponto
    final currentId = widget.pontoId;
    return (currentId + 1).toString();
  }
  
  Map<String, dynamic>? _getNextPointData() {
    // Implementar lógica para obter dados do próximo ponto
    return {
      'latitude': -15.7801, // Exemplo
      'longitude': -47.9292, // Exemplo
      'name': 'Ponto ${_getNextPointId()}',
    };
  }
  
  void _navigateToNextPoint() {
    Logger.info('🚀 [UNIFIED] Navegando para próximo ponto...');
    
    // Parar o rastreamento de localização
    _locationTimer?.cancel();
    
    // Navegar para o próximo ponto
    final nextPointId = _getNextPointId();
    if (nextPointId != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => UnifiedPointMonitoringScreen(
            pontoId: int.parse(nextPointId),
            talhaoId: widget.talhaoId,
          ),
        ),
      );
    } else {
      // Se não há próximo ponto, voltar para a tela anterior
      Navigator.of(context).pop();
    }
  }
  
  /// Constrói uma tela de espera simples e funcional
  Widget _buildSimpleWaitingScreen() {
    Logger.info('🏗️ [UNIFIED] Construindo tela de espera simples...');
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Navegando para Próximo Ponto',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone de navegação
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 3),
              ),
              child: const Icon(
                Icons.navigation,
                color: Colors.blue,
                size: 64,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Texto principal
            const Text(
              'Navegando para Próximo Ponto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Ponto ${widget.pontoId} → ${_getNextPointId() ?? 'Final'}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Logger.info('⏩ [UNIFIED] Usuário pulou o próximo ponto');
                    Navigator.of(context).pop();
                    _navigateToNextPoint();
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Pular Ponto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: () {
                    Logger.info('🎯 [UNIFIED] Usuário chegou ao próximo ponto');
                    Navigator.of(context).pop();
                    _navigateToNextPoint();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Chegou!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Inicia o rastreamento de localização para detectar proximidade
  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateLocationAndCheckProximity();
    });
  }
  
  /// Atualiza localização e verifica proximidade com próximo ponto
  Future<void> _updateLocationAndCheckProximity() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _deviceLocation = LatLng(position.latitude, position.longitude);
      });
      
      // Calcular distância até próximo ponto
      final nextPoint = _getNextPointData();
      if (nextPoint != null) {
        final targetLat = nextPoint['latitude'] as double;
        final targetLng = nextPoint['longitude'] as double;
        
        setState(() {
          _targetLocation = LatLng(targetLat, targetLng);
        });
        
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          targetLat,
          targetLng,
        );
        
        setState(() {
          _distanceToPoint = distance;
        });
        
        // Gerar rota entre pontos
        _generateRoute();
        
        // Centralizar mapa no dispositivo
        _centerMapOnDevice();
        
        // Verificar se está próximo (menos de 50 metros)
        if (distance <= 50.0 && !_isNearNextPoint) {
          _onNearNextPoint();
        }
      }
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao atualizar localização: $e');
    }
  }
  
  /// Chamado quando está próximo do próximo ponto
  void _onNearNextPoint() {
    setState(() {
      _isNearNextPoint = true;
    });
    
    // Vibrar
    HapticFeedback.heavyImpact();
    
    // Mostrar notificação
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.white),
            SizedBox(width: 8),
            Text('Você está próximo do próximo ponto!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Parar o timer
    _locationTimer?.cancel();
  }
  
  /// Atualiza estado dos botões baseado nas ações do usuário
  void _updateButtonStates() {
    setState(() {
      _hasOccurrences = _ocorrencias.isNotEmpty;
      _canSaveAndAdvance = _hasOccurrences;
      _canGoBack = _hasOccurrences;
    });
  }

  /// Gera rota entre dispositivo e ponto de destino
  void _generateRoute() {
    if (_deviceLocation != null && _targetLocation != null) {
      // Criar pontos intermediários para uma rota mais realista
      final points = <LatLng>[];
      
      // Ponto inicial (dispositivo)
      points.add(_deviceLocation!);
      
      // Pontos intermediários (simulação de rota GPS)
      final latDiff = _targetLocation!.latitude - _deviceLocation!.latitude;
      final lngDiff = _targetLocation!.longitude - _deviceLocation!.longitude;
      
      // Adicionar 3 pontos intermediários
      for (int i = 1; i <= 3; i++) {
        final factor = i / 4.0;
        points.add(LatLng(
          _deviceLocation!.latitude + (latDiff * factor),
          _deviceLocation!.longitude + (lngDiff * factor),
        ));
      }
      
      // Ponto final (destino)
      points.add(_targetLocation!);
      
      setState(() {
        _routePoints = points;
      });
    }
  }
  
  /// Centraliza o mapa no dispositivo
  void _centerMapOnDevice() {
    if (_mapController != null && _deviceLocation != null) {
      _mapController!.move(_deviceLocation!, 16.0);
    }
  }
  
  /// Constrói uma linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Formata a distância para exibição
  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }
  
  void _clearForm() {
    setState(() {
      _selectedType = null;
      _selectedOrganism = null;
      _quantity = 0;
      _observacao = '';
      _fotoPaths = [];
    });
  }
  
  String _getNivelFromQuantity(int quantity) {
    if (quantity == 0) return 'Nenhum';
    if (quantity <= 2) return 'Baixo';
    if (quantity <= 5) return 'Médio';
    if (quantity <= 10) return 'Alto';
    return 'Crítico';
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      
      if (image != null) {
        final compressedPath = await ImageCompressionService.compressImage(image.path);
        setState(() {
          _fotoPaths.add(compressedPath);
        });
      }
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao capturar imagem: $e');
      _showErrorSnackBar('Erro ao capturar imagem');
    }
  }
  
  void _removePhoto(int index) {
    setState(() {
      _fotoPaths.removeAt(index);
    });
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Salva dados no histórico de monitoramento
  Future<void> _saveToMonitoringHistory(InfestacaoModel occurrence) async {
    try {
      // Primeiro, verificar se a tabela existe e criar se necessário
      await _ensureMonitoringHistoryTableExists();
      
      // Obter informações adicionais do talhão e cultura
      final talhaoInfo = await _getTalhaoInfo(occurrence.talhaoId);
      final culturaInfo = await _getCulturaInfo(widget.culturaId);
      
      await _database!.insert(
        'monitoring_history',
        {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'talhao_id': occurrence.talhaoId,
          'ponto_id': occurrence.pontoId,
          'cultura_id': widget.culturaId,
          'cultura_nome': culturaInfo['nome'] ?? 'Cultura',
          'talhao_nome': talhaoInfo['nome'] ?? 'Talhão',
          'latitude': occurrence.latitude ?? 0.0,
          'longitude': occurrence.longitude ?? 0.0,
          'tipo_ocorrencia': occurrence.tipo,
          'subtipo_ocorrencia': occurrence.subtipo,
          'nivel_ocorrencia': occurrence.nivel,
          'percentual_ocorrencia': occurrence.percentual,
          'observacao': occurrence.observacao,
          'foto_paths': occurrence.fotoPaths,
          'data_hora_ocorrencia': occurrence.dataHora.toIso8601String(),
          'data_hora_monitoramento': DateTime.now().toIso8601String(),
          'sincronizado': 1, // Marcado como sincronizado
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ [UNIFIED] Dados salvos no histórico de monitoramento');
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao salvar no histórico: $e');
    }
  }
  
  /// Garante que a tabela monitoring_history existe
  Future<void> _ensureMonitoringHistoryTableExists() async {
    try {
      await _database!.execute('''
        CREATE TABLE IF NOT EXISTS monitoring_history (
          id TEXT PRIMARY KEY,
          talhao_id INTEGER NOT NULL,
          ponto_id INTEGER NOT NULL,
          cultura_id INTEGER NOT NULL,
          cultura_nome TEXT NOT NULL,
          talhao_nome TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          tipo_ocorrencia TEXT NOT NULL,
          subtipo_ocorrencia TEXT NOT NULL,
          nivel_ocorrencia TEXT NOT NULL,
          percentual_ocorrencia INTEGER NOT NULL,
          observacao TEXT,
          foto_paths TEXT,
          data_hora_ocorrencia DATETIME NOT NULL,
          data_hora_monitoramento DATETIME NOT NULL,
          sincronizado INTEGER DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Criar índices
      await _database!.execute('CREATE INDEX IF NOT EXISTS idx_history_talhao ON monitoring_history(talhao_id)');
      await _database!.execute('CREATE INDEX IF NOT EXISTS idx_history_ponto ON monitoring_history(ponto_id)');
      await _database!.execute('CREATE INDEX IF NOT EXISTS idx_history_cultura ON monitoring_history(cultura_id)');
      await _database!.execute('CREATE INDEX IF NOT EXISTS idx_history_data ON monitoring_history(data_hora_monitoramento)');
      await _database!.execute('CREATE INDEX IF NOT EXISTS idx_history_sync ON monitoring_history(sincronizado)');
      
      Logger.info('✅ [UNIFIED] Tabela monitoring_history verificada/criada');
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao criar tabela monitoring_history: $e');
    }
  }
  
  /// Obtém informações do talhão
  Future<Map<String, dynamic>> _getTalhaoInfo(int talhaoId) async {
    try {
      final result = await _database!.query(
        'talhao',
        where: 'id = ?',
        whereArgs: [talhaoId],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return {
          'nome': result.first['nome'] ?? 'Talhão $talhaoId',
        };
      }
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao obter info do talhão: $e');
    }
    
    return {'nome': 'Talhão $talhaoId'};
  }
  
  /// Obtém informações da cultura
  Future<Map<String, dynamic>> _getCulturaInfo(int culturaId) async {
    try {
      final result = await _database!.query(
        'culturas',
        where: 'id = ?',
        whereArgs: [culturaId],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return {
          'nome': result.first['nome'] ?? 'Cultura $culturaId',
        };
      }
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao obter info da cultura: $e');
    }
    
    return {'nome': 'Cultura $culturaId'};
  }
  
  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Mapa compacto
          _buildCompactMap(),
          
          // Formulário de nova ocorrência
          _buildNewOccurrenceForm(),
          
          // Lista de ocorrências registradas
          Expanded(
            child: _buildOccurrencesList(),
          ),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ponto 1/1',
            style: const TextStyle(
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          Text(
            'TESTE • $_culturaNome',
            style: const TextStyle(
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF2C2C2C)),
      actions: [
        // Botão de navegação inteligente
        IconButton(
          icon: const Icon(Icons.navigation, color: Color(0xFF2C2C2C)),
          onPressed: _openSmartNavigation,
          tooltip: 'Navegação Inteligente',
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isAtPoint ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${_distanceToPoint.toStringAsFixed(1)}m',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // Ajuda
          },
          icon: const Icon(Icons.help_outline),
          tooltip: 'Ajuda',
        ),
        IconButton(
          onPressed: () {
            // Lista de ocorrências
          },
          icon: const Icon(Icons.list),
          tooltip: 'Lista de Ocorrências',
        ),
      ],
    );
  }
  
  Widget _buildCompactMap() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: const Color(0xFFE8F4FD),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mapa do Ponto de Monitoramento',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GPS: ${_distanceToPoint.toStringAsFixed(1)}m',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNewOccurrenceForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF2D9CDB),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Nova Ocorrência',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Seletor de tipo
          const Text(
            'Selecione o Tipo:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 12),
          OccurrenceTypeSelector(
            selectedType: _selectedType,
            onTypeSelected: (type) {
              setState(() {
                _selectedType = type;
                _selectedOrganism = null; // Reset organismo ao mudar tipo
              });
            },
            types: const ['Praga', 'Doença', 'Daninha', 'Outro'],
          ),
          
          const SizedBox(height: 20),
          
          // Busca de organismo
          if (_selectedType != null) ...[
            const Text(
              'Organismo:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),
            OrganismSearchField(
              culturaId: widget.culturaId,
              onOrganismSelected: (organism) {
                setState(() {
                  _selectedOrganism = organism;
                });
              },
              initialValue: _selectedOrganism,
            ),
            
            const SizedBox(height: 20),
          ],
          
          // Quantidade
          if (_selectedOrganism != null) ...[
            const Text(
              'Quantidade encontrada:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),
            QuantityInputField(
              initialValue: _quantity,
              onChanged: (quantity) {
                setState(() {
                  _quantity = quantity;
                });
              },
            ),
            
            const SizedBox(height: 20),
          ],
          
          // Observação
          if (_quantity > 0) ...[
            const Text(
              'Observação (opcional):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _observacao,
              onChanged: (value) {
                setState(() {
                  _observacao = value;
                });
              },
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Descreva a ocorrência observada...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2D9CDB), width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
          
          // Fotos
          if (_quantity > 0) ...[
            const Text(
              'Fotos (opcional):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Câmera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D9CDB),
                      side: const BorderSide(color: Color(0xFF2D9CDB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Galeria'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D9CDB),
                      side: const BorderSide(color: Color(0xFF2D9CDB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            // Preview das fotos
            if (_fotoPaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fotoPaths.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_fotoPaths[index]),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 20),
          ],
          
          // Mapa GPS de navegação
          if (_showMap && _deviceLocation != null) ...[
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _deviceLocation!,
                    initialZoom: 16.0,
                    minZoom: 10.0,
                    maxZoom: 20.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // Camada de tiles (mapa base)
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fortsmart.agro',
                    ),
                    
                    // Camada de rota
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                            pattern: const StrokePattern.dashed(),
                          ),
                        ],
                      ),
                    
                    // Marcadores
                    MarkerLayer(
                      markers: [
                        // Marcador do dispositivo (azul)
                        if (_deviceLocation != null)
                          Marker(
                            point: _deviceLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
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
                        
                        // Marcador do destino (verde)
                        if (_targetLocation != null)
                          Marker(
                            point: _targetLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.place,
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
            ),
            
            // Informações de navegação
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Navegando para Ponto ${_getNextPointId() ?? 'Final'}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Distância: ${_formatDistance(_distanceToPoint)}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
            Row(
              children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showMap = !_showMap;
                          });
                        },
                        icon: Icon(
                          _showMap ? Icons.list : Icons.map,
                          color: Colors.blue,
                        ),
                        tooltip: _showMap ? 'Ver Lista' : 'Ver Mapa',
                      ),
                      IconButton(
                        onPressed: _centerMapOnDevice,
                        icon: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                        ),
                        tooltip: 'Centralizar no Dispositivo',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (!_showMap) ...[
            // Vista de lista quando mapa está oculto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text(
                        'Informações de Navegação',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showMap = true;
                          });
                        },
                        icon: const Icon(Icons.map, color: Colors.blue),
                        tooltip: 'Ver Mapa',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_deviceLocation != null) ...[
                    _buildInfoRow('📍 Dispositivo', '${_deviceLocation!.latitude.toStringAsFixed(6)}, ${_deviceLocation!.longitude.toStringAsFixed(6)}'),
                    const SizedBox(height: 8),
                  ],
                  if (_targetLocation != null) ...[
                    _buildInfoRow('🎯 Destino', '${_targetLocation!.latitude.toStringAsFixed(6)}, ${_targetLocation!.longitude.toStringAsFixed(6)}'),
                    const SizedBox(height: 8),
                  ],
                  _buildInfoRow('📏 Distância', _formatDistance(_distanceToPoint)),
                  const SizedBox(height: 8),
                  _buildInfoRow('🎯 Próximo Ponto', 'Ponto ${_getNextPointId() ?? 'Final'}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Botões de ação - controlados por estado
          ...[
            Row(
              children: [
                // Botão Voltar - só habilitado após ter ocorrências
                if (_canGoBack) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE74C3C),
                        side: const BorderSide(color: Color(0xFFE74C3C)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Voltar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saveOccurrence,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D9CDB),
                      side: const BorderSide(color: Color(0xFF2D9CDB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Salvar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isSaving || !_canSaveAndAdvance) ? null : () {
                      Logger.info('🔄 [UNIFIED] Botão Salvar & Avançar pressionado');
                      // Feedback tátil imediato
                      HapticFeedback.lightImpact();
                      
                      // Debug visual imediato
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Botão pressionado! Processando...'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 1),
                        ),
                      );
                      
                      _saveAndContinueOccurrence();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaving 
                          ? const Color(0xFF95A5A6) 
                          : _canSaveAndAdvance 
                              ? const Color(0xFF27AE60) 
                              : const Color(0xFF95A5A6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving 
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Salvando...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Salvar & Avançar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Mostrar botões mesmo quando quantidade for 0, mas desabilitados
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: null, // Desabilitado
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF95A5A6),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Salvar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: null, // Desabilitado
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0E0E0),
                      foregroundColor: const Color(0xFF95A5A6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Salvar & Avançar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Preencha a quantidade para habilitar os botões',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildOccurrencesList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header da lista
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.list_alt,
                  color: Color(0xFF2D9CDB),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ocorrências Registradas neste Ponto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de ocorrências
          Expanded(
            child: _ocorrencias.isEmpty
                ? _buildEmptyState()
                : OccurrencesListWidget(
                    ocorrencias: _ocorrencias,
                    onEdit: (occurrence) {
                      // Implementar edição se necessário
                    },
                    onDelete: (id) async {
                      try {
                        await _infestacaoRepository!.delete(id);
                        setState(() {
                          _ocorrencias.removeWhere((o) => o.id == id);
                        });
                        _showSuccessSnackBar('Ocorrência removida com sucesso!');
                      } catch (e) {
                        _showErrorSnackBar('Erro ao remover ocorrência');
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma ocorrência registrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registre a primeira ocorrência acima',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tela de espera inovadora com distância, cronômetro e vibração
class _InnovativeWaitingScreen extends StatefulWidget {
  final String currentPointId;
  final String? nextPointId;
  final Map<String, dynamic>? nextPointData;
  final VoidCallback? onArrived;
  final VoidCallback? onSkip;

  const _InnovativeWaitingScreen({
    required this.currentPointId,
    this.nextPointId,
    this.nextPointData,
    this.onArrived,
    this.onSkip,
  });

  @override
  State<_InnovativeWaitingScreen> createState() => _InnovativeWaitingScreenState();
}

class _InnovativeWaitingScreenState extends State<_InnovativeWaitingScreen>
    with TickerProviderStateMixin {
  Position? _currentPosition;
  double _distanceToNext = 0.0;
  String _direction = 'Calculando...';
  Duration _elapsedTime = Duration.zero;
  bool _hasVibrated = false;
  
  late AnimationController _pulseController;
  late AnimationController _timerController;
  late Animation<double> _pulseAnimation;
  
  Timer? _locationTimer;
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLocationTracking();
    _startTimer();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateLocation();
    });
    _updateLocation(); // Primeira atualização imediata
  }

  void _startTimer() {
    _timerController.repeat();
    _timerController.addListener(() {
      setState(() {
        _elapsedTime = Duration(seconds: _timerController.value.toInt());
      });
    });
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      
      if (widget.nextPointData != null) {
        final nextLat = widget.nextPointData!['latitude'] as double?;
        final nextLng = widget.nextPointData!['longitude'] as double?;
        
        if (nextLat != null && nextLng != null) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            nextLat,
            nextLng,
          );
          
          final bearing = Geolocator.bearingBetween(
            position.latitude,
            position.longitude,
            nextLat,
            nextLng,
          );
          
          setState(() {
            _distanceToNext = distance;
            _direction = _getDirectionText(bearing);
          });
          
          // Verificar se chegou ao ponto (menos de 5 metros)
          if (distance <= 5.0 && !_hasVibrated) {
            _triggerArrivalNotification();
          }
        }
      }
    } catch (e) {
      Logger.error('❌ Erro ao atualizar localização: $e');
    }
  }

  void _triggerArrivalNotification() {
    setState(() {
      _hasVibrated = true;
    });
    
    // Vibrar
    HapticFeedback.heavyImpact();
    
    // Mostrar notificação
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Você chegou ao próximo ponto!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Auto-navegar após 3 segundos
    Timer(const Duration(seconds: 3), () {
      if (widget.onArrived != null) {
        widget.onArrived!();
      }
    });
  }

  String _getDirectionText(double bearing) {
    if (bearing >= -22.5 && bearing < 22.5) return 'Norte';
    if (bearing >= 22.5 && bearing < 67.5) return 'Nordeste';
    if (bearing >= 67.5 && bearing < 112.5) return 'Leste';
    if (bearing >= 112.5 && bearing < 157.5) return 'Sudeste';
    if (bearing >= 157.5 || bearing < -157.5) return 'Sul';
    if (bearing >= -157.5 && bearing < -112.5) return 'Sudoeste';
    if (bearing >= -112.5 && bearing < -67.5) return 'Oeste';
    if (bearing >= -67.5 && bearing < -22.5) return 'Noroeste';
    return 'Calculando...';
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timerController.dispose();
    _locationTimer?.cancel();
    _vibrationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Navegando para Próximo Ponto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ponto ${widget.currentPointId} → ${widget.nextPointId ?? 'Final'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Conteúdo principal
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cronômetro
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(_elapsedTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Text(
                          'Tempo decorrido',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Distância animada
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: _distanceToNext <= 5.0 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _distanceToNext <= 5.0 
                                  ? Colors.green
                                  : Colors.blue,
                              width: 3,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _distanceToNext <= 5.0 
                                    ? Icons.check_circle
                                    : Icons.navigation,
                                color: _distanceToNext <= 5.0 
                                    ? Colors.green
                                    : Colors.blue,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _formatDistance(_distanceToNext),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _distanceToNext <= 5.0 
                                    ? 'Você chegou!'
                                    : 'Distância restante',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Direção
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.compass_calibration,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _direction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Botões de ação
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onSkip,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Pular Ponto'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _distanceToNext <= 5.0 ? widget.onArrived : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _distanceToNext <= 5.0 
                            ? Colors.green 
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _distanceToNext <= 5.0 
                            ? 'Chegou!' 
                            : 'Aguardando chegada...',
                      ),
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
}
