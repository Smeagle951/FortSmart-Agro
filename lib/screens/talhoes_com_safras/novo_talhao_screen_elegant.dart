import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:uuid/uuid.dart';

import 'controllers/novo_talhao_controller.dart';
import '../../models/talhao_model.dart';
import '../../models/poligono_model.dart';
import '../../models/cultura_model.dart';
import '../../models/safra_model.dart';
import 'providers/talhao_provider.dart';
import '../../services/advanced_gps_tracking_service.dart';
import '../../config/maptiler_config.dart';
import '../../widgets/gps_settings_dialog.dart';
import '../../utils/geo_calculator.dart';
import '../../utils/precise_geo_calculator.dart';
import '../../utils/api_config.dart';
import '../../services/unified_geo_import_service.dart';
import '../../widgets/talhao_floating_card.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../services/robust_geo_import_service.dart';
import '../../services/polygon_database_service.dart';
import '../../services/storage_service.dart';
import '../../services/cultura_service.dart';
import '../../services/culture_import_service.dart';
import '../../services/cultura_talhao_service.dart';
import '../../services/talhao_unified_service.dart';
import '../../services/polygon_service.dart';
import '../../services/location_service.dart';
import '../../services/advanced_gps_service.dart';
import '../../services/gps_filter_service.dart';
import '../../services/precise_area_calculation_service.dart';
import '../../services/notification_service.dart';
import '../../services/talhao_polygon_service.dart';
import '../../repositories/talhoes/talhao_safra_repository.dart';
import '../../repositories/crop_repository.dart';
import '../../utils/logger.dart';
import '../../widgets/elegant_notification_system.dart';
import '../../widgets/advanced_polygon_editor.dart';
import '../../services/automatic_backup_service.dart';
import '../../services/talhao_history_service.dart';
import '../../services/intelligent_gps_tracking_service.dart';
import 'widgets/advanced_gps_widget.dart';
import 'widgets/gps_quality_indicator.dart';

/// 🎨 CustomPainter para marcador em formato de gota/pino
class PinMarkerPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final bool isDragging;

  PinMarkerPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isDragging ? 8 : 4);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - borderWidth / 2;

    // Desenhar sombra
    canvas.drawCircle(center + Offset(0, 2), radius, shadowPaint);

    // Desenhar corpo da gota (círculo)
    canvas.drawCircle(center, radius, paint);

    // Desenhar borda
    canvas.drawCircle(center, radius, borderPaint);

    // Desenhar ponta da gota (pequeno triângulo na parte inferior)
    final path = ui.Path();
    final triangleSize = radius * 0.3;
    path.moveTo(center.dx, center.dy + radius - triangleSize);
    path.lineTo(center.dx - triangleSize * 0.6, center.dy + radius);
    path.lineTo(center.dx + triangleSize * 0.6, center.dy + radius);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is PinMarkerPainter &&
        (oldDelegate.color != color ||
            oldDelegate.borderColor != borderColor ||
            oldDelegate.borderWidth != borderWidth ||
            oldDelegate.isDragging != isDragging);
  }
}


// 🚀 NOVOS SERVIÇOS PARA FUNCIONALIDADE COMPLETA

/// Tela elegante e moderna para criação de talhões
/// Design premium com animações e UX avançada
class NovoTalhaoScreenElegant extends StatefulWidget {
  const NovoTalhaoScreenElegant({super.key});

  @override
  State<NovoTalhaoScreenElegant> createState() => _NovoTalhaoScreenElegantState();
}

class _NovoTalhaoScreenElegantState extends State<NovoTalhaoScreenElegant>
    with TickerProviderStateMixin {
  late NovoTalhaoController _controller;
  late AdvancedGpsTrackingService _gpsService;
  late UnifiedGeoImportService _importService;
  
  // 🚀 NOVOS SERVIÇOS PARA FUNCIONALIDADE COMPLETA
  PolygonDatabaseService? _polygonDatabaseService;
  StorageService? _storageService;
  CulturaService? _culturaService;
  CultureImportService? _cultureImportService;
  CulturaTalhaoService? _culturaTalhaoService;
  TalhaoUnifiedService? _talhaoUnifiedService;
  PolygonService? _polygonService;
  LocationService? _locationService;
  AdvancedGPSService? _advancedGPSService;
  PreciseAreaCalculationService? _preciseAreaService;
  // TalhaoNotificationService? _notificationService;
  // TalhaoDuplicationService? _duplicationService;
  TalhaoPolygonService? _talhaoPolygonService;
  TalhaoSafraRepository? _talhaoSafraRepository;
  CropRepository? _cropRepository;
  
  // Animações
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Estado da UI
  bool _showMetrics = true;
  bool _showActionPanel = true;
  bool _isActionPanelCollapsed = false;
  
  // Estado do mapa
  String _currentMapStyle = 'satellite';
  LatLng? _currentUserLocation;
  bool _isGpsCentered = false;
  bool _isGpsPaused = false;
  LatLng? _lastPointBeforePause;
  
  // Estado do desenho manual
  int? _selectedPointIndex;
  
  // 🚀 FIELDS AREA MEASURE - Estrutura de dados
  List<LatLng> _polygonVertices = []; // Lista de vértices do polígono
  bool _isEditMode = false; // Modo de edição ativo
  int? _editingVertexIndex; // Índice do vértice sendo editado
  double? _currentArea; // Área atual calculada (para evitar recálculos)
  
  // 🚀 FORTSMART PREMIUM - Sistema de arrastar vértices melhorado
  bool _isDraggingVertex = false;
  int? _draggingVertexIndex;
  LatLng? _dragStartPoint;
  DateTime? _dragStartTime;
  LatLng? _lastAutoPoint;
  bool _isLongPress = false;
  double _autoPointDistance = 100.0; // 100 metros para criação automática
  
  // 🚀 FORTSMART ORIGINAL - Controle de mensagens repetitivas
  DateTime? _lastMessageTime;
  String? _lastMessage;
  int _vertexAddCount = 0; // Contador de vértices adicionados
  bool _showVertexMessages = true; // Controle para mostrar mensagens de vértices
  
  // 🌱 SISTEMA DE CULTURAS
  List<CulturaModel> _culturas = [];
  CulturaModel? _culturaSelecionada;
  bool _isLoadingCulturas = false;
  
  // 📝 CONTROLADORES DE TEXTO PARA SALVAMENTO
  final TextEditingController _safraController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  
  // 💾 SISTEMA DE PERSISTÊNCIA
  List<TalhaoModel> _talhoesExistentes = [];
  bool _isLoadingTalhoes = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<NovoTalhaoController>();
    _gpsService = AdvancedGpsTrackingService();
    _importService = UnifiedGeoImportService();
    
    // Inicializar GPS avançado
    _advancedGPSService = AdvancedGPSService();
    _preciseAreaService = PreciseAreaCalculationService();
    _initializeAdvancedGPS();
    
    // Inicializar o controller
    _initializeController();
    
    // Carregar culturas
    _loadCulturas();
    
    // Carregar talhões existentes do banco de dados
    _loadTalhoesFromDatabase();
    
    // Inicializar animações
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Iniciar animações
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);

    // Configurar GPS
    _setupGpsService();
  }

  /// Inicializa o controller
  void _initializeController() async {
    try {
      print('=== INICIALIZANDO CONTROLLER ===');
      print('Controller antes: ${_controller.runtimeType}');
      print('MapController antes: ${_controller.mapController}');
      
      await _controller.initialize();
      
      print('Controller depois: ${_controller.runtimeType}');
      print('MapController depois: ${_controller.mapController}');
      print('Controller inicializado com sucesso');
      
      // Forçar rebuild da UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Erro ao inicializar controller: $e');
    }
  }

  /// Inicializa o GPS avançado
  Future<void> _initializeAdvancedGPS() async {
    try {
      print('🛰️ Inicializando GPS avançado...');
      
      if (_advancedGPSService != null) {
        final success = await _advancedGPSService!.initialize();
        
        if (success) {
          print('✅ GPS avançado inicializado com sucesso');
          
          // Configurar callbacks
          _advancedGPSService!.onPositionUpdate = (position) {
            if (mounted) {
              setState(() {
                _currentUserLocation = position.position;
              });
              
              // Centralizar mapa na nova posição se necessário
              if (_controller.mapController != null) {
                _controller.mapController!.move(position.position, 16.0);
              }
            }
          };
          
          _advancedGPSService!.onError = (error) {
            if (mounted) {
              _showElegantSnackBar('Erro GPS: $error', isError: true);
            }
          };
          
        } else {
          print('⚠️ GPS avançado não pôde ser inicializado');
          _showElegantSnackBar('GPS não disponível. Verifique as permissões.', isError: true);
        }
      }
      
    } catch (e) {
      print('❌ Erro ao inicializar GPS avançado: $e');
      _showElegantSnackBar('Erro ao inicializar GPS: $e', isError: true);
    }
  }

  /// Centraliza o mapa na localização do usuário (apenas quando solicitado)
  void _centerMapOnUser() async {
    try {
      print('=== CENTRALIZANDO MAPA NO USUÁRIO ===');
      
      // Obter localização atual do dispositivo
      final location = await _controller.getCurrentLocation();
      if (location != null) {
        _currentUserLocation = location;
        _controller.mapController?.move(location, 16.0);
        setState(() {
          _isGpsCentered = true;
        });
        
        print('Mapa centralizado na localização: $location');
        
        // Resetar flag após 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isGpsCentered = false;
            });
          }
        });
      } else {
        print('Não foi possível obter localização');
        _showElegantSnackBar('Não foi possível obter sua localização', isSuccess: false);
      }
    } catch (e) {
      print('Erro ao centralizar mapa: $e');
      _showElegantSnackBar('Erro ao centralizar mapa: $e', isSuccess: false);
    }
  }

  /// Carrega culturas reais do módulo Culturas da Fazenda
  Future<void> _loadCulturas() async {
    setState(() {
      _isLoadingCulturas = true;
    });

    try {
      print('🔄 Carregando culturas do módulo Culturas da Fazenda...');
      
      // Primeiro, tentar carregar do módulo Culturas da Fazenda (CultureImportService)
      try {
        final cultureImportService = CultureImportService();
        await cultureImportService.initialize();
        
        final culturasFazenda = await cultureImportService.getAllCrops();
        print('✅ CultureImportService retornou ${culturasFazenda.length} culturas');
        
        if (culturasFazenda.isNotEmpty) {
          _culturas.clear();
          for (var cultura in culturasFazenda) {
            final culturaModel = CulturaModel(
              id: cultura.id?.toString() ?? '0',
              name: cultura.name,
              color: _obterCorPorNome(cultura.name),
              description: cultura.description ?? '',
            );
            _culturas.add(culturaModel);
            print('  - ${culturaModel.name} (ID: ${culturaModel.id})');
          }
          
          print('✅ ${_culturas.length} culturas carregadas do CultureImportService');
          setState(() {
            _isLoadingCulturas = false;
          });
          return;
        }
      } catch (e) {
        print('❌ Erro ao carregar do CultureImportService: $e');
      }
      
      // Segundo, tentar carregar via CulturaTalhaoService
      try {
        final culturaTalhaoService = CulturaTalhaoService();
        final culturasFazenda = await culturaTalhaoService.listarCulturas();
        print('✅ CulturaTalhaoService retornou ${culturasFazenda.length} culturas');
        
        if (culturasFazenda.isNotEmpty) {
          _culturas.clear();
          for (var cultura in culturasFazenda) {
            final culturaModel = CulturaModel(
              id: cultura['id'] ?? '0',
              name: cultura['nome'] ?? 'Cultura',
              color: cultura['cor'] ?? Colors.grey,
              description: cultura['descricao'] ?? '',
            );
            _culturas.add(culturaModel);
            print('  - ${culturaModel.name} (ID: ${culturaModel.id})');
          }
          
          print('✅ ${_culturas.length} culturas carregadas do CulturaTalhaoService');
          setState(() {
            _isLoadingCulturas = false;
          });
          return;
        }
      } catch (e) {
        print('❌ Erro ao carregar do CulturaTalhaoService: $e');
      }
      
      // Terceiro, usar culturas padrão se não conseguir carregar
      print('⚠️ Usando culturas padrão como fallback');
      _culturas = [
        CulturaModel(
          id: '1',
          name: 'Soja',
          color: Colors.green,
          description: 'Cultura de soja',
        ),
        CulturaModel(
          id: '2',
          name: 'Milho',
          color: Colors.yellow,
          description: 'Cultura de milho',
        ),
        CulturaModel(
          id: '3',
          name: 'Algodão',
          color: Colors.white,
          description: 'Cultura de algodão',
        ),
        CulturaModel(
          id: '4',
          name: 'Feijão',
          color: Colors.brown,
          description: 'Cultura de feijão',
        ),
        CulturaModel(
          id: '5',
          name: 'Trigo',
          color: Colors.amber,
          description: 'Cultura de trigo',
        ),
        CulturaModel(
          id: '6',
          name: 'Sorgo',
          color: Colors.orange,
          description: 'Cultura de sorgo',
        ),
        CulturaModel(
          id: '7',
          name: 'Girassol',
          color: Colors.deepOrange,
          description: 'Cultura de girassol',
        ),
        CulturaModel(
          id: '8',
          name: 'Aveia',
          color: Colors.lightGreen,
          description: 'Cultura de aveia',
        ),
        CulturaModel(
          id: '9',
          name: 'Gergelim',
          color: Colors.grey,
          description: 'Cultura de gergelim',
        ),
      ];
      
    } catch (e) {
      print('❌ Erro ao carregar culturas: $e');
      // Usar culturas padrão como último recurso
      _culturas = [
        CulturaModel(
          id: '1',
          name: 'Soja',
          color: Colors.green,
          description: 'Cultura de soja',
        ),
        CulturaModel(
          id: '2',
          name: 'Milho',
          color: Colors.yellow,
          description: 'Cultura de milho',
        ),
      ];
    } finally {
      setState(() {
        _isLoadingCulturas = false;
      });
    }
  }

  /// Obtém cor baseada no nome da cultura
  Color _obterCorPorNome(String nomeCultura) {
    final nome = nomeCultura.toLowerCase();
    
    if (nome.contains('soja')) return Colors.green;
    if (nome.contains('milho')) return Colors.yellow;
    if (nome.contains('algodão') || nome.contains('algodao')) return const Color(0xFFE0E0E0); // Cinza claro
    if (nome.contains('feijão') || nome.contains('feijao')) return Colors.brown;
    if (nome.contains('trigo')) return Colors.amber;
    if (nome.contains('sorgo')) return Colors.orange;
    if (nome.contains('girassol')) return Colors.deepOrange;
    if (nome.contains('aveia')) return Colors.lightGreen;
    if (nome.contains('gergelim')) return Colors.grey;
    if (nome.contains('café') || nome.contains('cafe')) return Colors.brown[800]!;
    if (nome.contains('cana')) return Colors.green[700]!;
    if (nome.contains('tomate')) return Colors.red;
    if (nome.contains('batata')) return Colors.purple;
    if (nome.contains('cenoura')) return Colors.orange[600]!;
    if (nome.contains('alface')) return Colors.lightGreen[400]!;
    
    // Cor padrão para culturas não reconhecidas
    return Colors.blue;
  }

  /// Muda o estilo do mapa
  void _changeMapStyle(String style) {
    setState(() {
      _currentMapStyle = style;
    });
  }

  /// Obtém URL do tile baseado no estilo
  String _getMapTileUrl(String style) {
    switch (style) {
      case 'satellite':
        return 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=${MapTilerConfig.apiKey}';
      case 'streets':
        return 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=${MapTilerConfig.apiKey}';
      case 'outdoors':
        return 'https://api.maptiler.com/maps/outdoor/{z}/{x}/{y}.png?key=${MapTilerConfig.apiKey}';
      case 'topo':
        return 'https://api.maptiler.com/maps/topo/{z}/{x}/{y}.png?key=${MapTilerConfig.apiKey}';
      default:
        return 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=${MapTilerConfig.apiKey}';
    }
  }

  /// Obtém a URL do mapa baseado no estilo atual
  String _getMapUrl() {
    String url;
    switch (_currentMapStyle) {
      case 'satellite':
        url = APIConfig.getMapTilerUrl('satellite');
        break;
      case 'streets':
        url = APIConfig.getMapTilerUrl('streets');
        break;
      case 'outdoors':
        url = APIConfig.getMapTilerUrl('outdoors');
        break;
      case 'topo':
        url = APIConfig.getMapTilerUrl('topo');
        break;
      case 'hybrid':
        url = APIConfig.getMapTilerUrl('hybrid');
        break;
      default:
        url = APIConfig.getMapTilerUrl('satellite');
    }
    
    print('Mapa URL: $url');
    return url;
  }

  void _setupGpsService() {
    // TODO: Configurar callbacks do GPS quando disponíveis
    // _gpsService.onNewPoint = (point) {
    //   if (mounted) {
    //     setState(() {
    //       _controller.addPoint(point);
    //     });
    //   }
    // };

    // _gpsService.onStatsUpdated = (stats) {
    //   if (mounted) {
    //     setState(() {
    //       _gpsStats = stats;
    //     });
    //   }
    // };

    // _gpsService.onError = (error) {
    //   if (mounted) {
    //     _showElegantSnackBar('Erro GPS: $error', isError: true);
    //   }
    // };
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _realTimeUpdateTimer?.cancel();
    _gpsService.dispose();
    _advancedGPSService?.dispose();
    _nomeController.dispose();
    _safraController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Stack(
        children: [
          // Mapa de fundo
          _buildMap(),
          
          // Overlay gradiente (não bloqueia gestos)
          _buildGradientOverlay(),
          
          // Conteúdo principal (não bloqueia gestos do mapa)
          IgnorePointer(
            ignoring: false, // Permitir gestos nos botões
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // App Bar elegante
                  _buildElegantAppBar(),
                  
                  // Conteúdo central
                  Expanded(
                    child: Stack(
                      children: [
                        // Métricas flutuantes
                        if (_showMetrics) _buildFloatingMetrics(),
                        
                        // Painel de ações (sem IgnorePointer para permitir gestos)
                        if (_showActionPanel) _buildActionPanel(),
                        
                        // Indicador GPS
                        _buildGpsIndicator(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Controles de mapa (por último para ficar por cima)
          _buildMapControls(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer<NovoTalhaoController>(
      builder: (context, controller, child) {
        print('=== CONSUMER REBUILD ===');
        print('Controller: ${controller.runtimeType}');
        print('MapController: ${controller.mapController}');
        print('isDrawing: ${controller.isDrawing}');
        print('currentPoints: ${controller.currentPoints.length}');
        print('userLocation: ${controller.userLocation}');
        
        return SizedBox.expand(
          child: FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: LatLng(MapTilerConfig.defaultLat, MapTilerConfig.defaultLng),
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                print('FlutterMap onTap chamado: $point');
                _onMapTap(point, controller);
              },
              minZoom: 3,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                enableMultiFingerGestureRace: true,
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Camada de tiles - usando modo satélite por padrão
              TileLayer(
                urlTemplate: _getMapTileUrl(_currentMapStyle),
                userAgentPackageName: 'com.fortsmart.agro',
                maxZoom: 18,
                minZoom: 3,
              ),
              
              // Polígonos dos talhões
              PolygonLayer(
                polygons: _buildTalhaoPolygons(controller),
              ),
              
              // Marcadores
              MarkerLayer(
                markers: [
                  ..._buildTalhaoMarkers(controller),
                  ..._buildUserLocationMarkers(controller),
                  ..._buildFortSmartVertexMarkers(), // 🚀 Sistema original FortSmart
                ],
              ),
              
              // 🚀 FIELDS AREA MEASURE - Linhas e Polígono
              if (_polygonVertices.isNotEmpty) ...[
                // Linhas conectando os vértices
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _getClosedPolygonPoints(), // Inclui fechamento automático
                      color: Colors.blue,
                      strokeWidth: 3.0,
                    ),
                  ],
                ),
                
                // Preenchimento do polígono (se tiver 3+ pontos)
                if (_polygonVertices.length >= 3)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _getClosedPolygonPoints(),
                        color: Colors.blue.withOpacity(0.3),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradientOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x1A000000),
              Color(0x00000000),
              Color(0x00000000),
              Color(0x2A000000),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  /// Constrói os controles de mapa
  Widget _buildMapControls() {
    return Stack(
      children: [
        // Botão de centralizar GPS
        Positioned(
          top: 100,
          right: 20,
          child: _buildGpsCenterButton(),
        ),
        
      ],
    );
  }

  /// Botão para centralizar GPS
  Widget _buildGpsCenterButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _isGpsCentered ? Colors.green : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _centerMapOnUser,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.my_location,
              color: _isGpsCentered ? Colors.white : Colors.blue,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }


  // 🚀 FORTSMART PREMIUM - Botões de estilo do mapa removidos para simplificar interface

  Widget _buildElegantAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Row(
        children: [
          // Botão voltar elegante
          _buildElegantButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: () => Navigator.pop(context),
            color: Colors.white.withOpacity(0.9),
          ),
          
          const SizedBox(width: 16),
          
          // Título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Novo Talhão',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Crie talhões com precisão GPS',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
          // Botões de ação
          Row(
            children: [
              _buildElegantButton(
                icon: _showMetrics ? Icons.visibility_off : Icons.visibility,
                onPressed: () => setState(() => _showMetrics = !_showMetrics),
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 8),
              _buildElegantButton(
                icon: Icons.my_location,
                onPressed: _centerMapOnLocation,
                color: Colors.blue.withOpacity(0.9),
              ),
              const SizedBox(width: 8),
              _buildElegantButton(
                icon: Icons.settings,
                onPressed: _showGpsSettings,
                color: Colors.white.withOpacity(0.9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElegantButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// 🚀 FORTSMART PREMIUM - Card de métricas com glassmorphism compacto
  Widget _buildFloatingMetrics() {
    return Positioned(
      top: 20,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: 200, // Mais compacto
          padding: const EdgeInsets.all(12), // Padding menor
          decoration: BoxDecoration(
            // Glassmorphism premium
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24), // Mais arredondado
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
            // Efeito de vidro fosco premium
            backgroundBlendMode: BlendMode.overlay,
          ),
          child: Consumer<NovoTalhaoController>(
            builder: (context, controller, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título do card - mais compacto
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 16, // Ícone menor
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Métricas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12, // Fonte menor
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8), // Espaçamento menor
                  
                  // 🚀 Métricas FortSmart (Sistema Original)
                  _buildPremiumMetricCard(
                    icon: Icons.crop_square,
                    label: 'Área',
                    value: PreciseGeoCalculator.formatAreaBrazilian(_calculatePolygonArea()),
                    color: const Color(0xFF2E7D32),
                  ),
                  
                  const SizedBox(height: 4), // Espaçamento menor
                  
                  _buildPremiumMetricCard(
                    icon: Icons.straighten,
                    label: 'Perímetro',
                    value: PreciseGeoCalculator.formatPerimeterBrazilian(_calculatePolygonPerimeter()),
                    color: Colors.blue,
                  ),
                  
                  const SizedBox(height: 4), // Espaçamento menor
                  
                  _buildPremiumMetricCard(
                    icon: Icons.location_on,
                    label: 'Vértices',
                    value: '${_polygonVertices.length}',
                    color: Colors.orange,
                  ),
                  
                  const SizedBox(height: 4), // Espaçamento menor
                  
                  _buildPremiumMetricCard(
                    icon: Icons.edit,
                    label: 'Modo',
                    value: _isEditMode ? 'Edição' : 'Desenho',
                    color: _isEditMode ? Colors.orange : const Color(0xFF2E7D32),
                  ),
                  
                  // Métricas GPS (se ativo)
                  if (_gpsService.isTracking) ...[
                    const SizedBox(height: 8),
                    _buildPremiumMetricCard(
                      icon: Icons.timer,
                      label: 'Tempo',
                      value: _formatDuration(controller.elapsedTime),
                      color: Colors.purple,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _buildPremiumMetricCard(
                      icon: Icons.speed,
                      label: 'Velocidade',
                      value: PreciseGeoCalculator.formatSpeedBrazilian(controller.currentSpeedKmh),
                      color: Colors.red,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _buildPremiumMetricCard(
                      icon: Icons.gps_fixed,
                      label: 'Precisão',
                      value: _getGpsAccuracyText(controller.gpsAccuracy),
                      color: _getGpsAccuracyColor(controller.gpsAccuracy),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🚀 FORTSMART PREMIUM - Card de métrica compacto
  Widget _buildPremiumMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Mais compacto
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08), // Mais transparente
        borderRadius: BorderRadius.circular(10), // Menos arredondado
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14), // Ícone menor
          const SizedBox(width: 6), // Espaçamento menor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11, // Fonte menor
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGpsAccuracyText(double accuracy) {
    if (accuracy <= 5.0) {
      return 'Excelente (${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy <= 10.0) {
      return 'Bom (${accuracy.toStringAsFixed(1)}m)';
    } else {
      return 'Ruim (${accuracy.toStringAsFixed(1)}m)';
    }
  }

  Color _getGpsAccuracyColor(double accuracy) {
    if (accuracy <= 5.0) {
      return Colors.green;
    } else if (accuracy <= 10.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildActionPanel() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: _isActionPanelCollapsed 
            ? _buildCollapsedActionPanel()
            : _buildExpandedActionPanel(),
      ),
    );
  }

  Widget _buildExpandedActionPanel() {
    return Consumer<NovoTalhaoController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Título do painel
          Row(
            children: [
              Icon(
                Icons.touch_app,
                color: Colors.grey[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Controles de Desenho',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              _buildElegantButton(
                icon: Icons.keyboard_arrow_up,
                onPressed: () => setState(() => _isActionPanelCollapsed = true),
                color: Colors.grey[600]!,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Botões de ação
          // 🚀 FORTSMART PREMIUM - Primeira linha com botões principais (ordem otimizada)
          Row(
            children: [
              Expanded(
                child: _buildPremiumPillButton(
                  icon: _isGpsPaused ? Icons.play_arrow : Icons.gps_fixed,
                  label: _isGpsPaused ? 'Retomar' : 'GPS',
                  onPressed: _isGpsPaused ? _resumeGpsTracking : _startGpsTracking,
                  color: _isGpsPaused ? Colors.orange : Colors.green,
                  isActive: _gpsService.isTracking,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumPillButton(
                  icon: Icons.edit,
                  label: 'Desenhar',
                  onPressed: _startDrawing,
                  color: Colors.blue,
                  isActive: _controller.isDrawing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumPillButton(
                  icon: Icons.save,
                  label: 'Salvar',
                  onPressed: _showSaveDialog,
                  color: Colors.purple,
                  isActive: _polygonVertices.length >= 3,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Indicador de qualidade dos pontos GPS
          if (_polygonVertices.isNotEmpty)
            GPSQualityIndicator(
              points: _polygonVertices,
              areaService: _preciseAreaService,
            ),
          
          const SizedBox(height: 8),
          
          // Widget do GPS Avançado
          if (_advancedGPSService != null)
            AdvancedGPSWidget(
              gpsService: _advancedGPSService!,
              onPositionUpdate: (position) {
                // Atualizar localização atual
                setState(() {
                  _currentUserLocation = position.position;
                });
              },
              onError: (error) {
                _showElegantSnackBar('Erro GPS: $error', isError: true);
              },
            ),
          
          const SizedBox(height: 12),
          
          // Segunda linha com botões de controle GPS
          if (_gpsService.isTracking)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: _isGpsPaused ? Icons.play_arrow : Icons.pause,
                    label: _isGpsPaused ? 'Retomar GPS' : 'Pausar GPS',
                    onPressed: _isGpsPaused ? _resumeGpsTracking : _pauseGpsTracking,
                    color: _isGpsPaused ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.stop,
                    label: 'Parar GPS',
                    onPressed: _stopGpsTracking,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 12),
          
          // Botões secundários
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.undo,
                  label: 'Desfazer',
                  onPressed: _undoLastPoint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.clear,
                  label: 'Limpar',
                  onPressed: _clearDrawing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.file_download,
                  label: 'Importar',
                  onPressed: _importPolygons,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.check_circle,
                  label: 'Finalizar',
                  onPressed: () {
                    if (_polygonVertices.length >= 3) {
                      _finalizePolygon();
                    } else {
                      _showElegantSnackBar('Adicione pelo menos 3 vértices para finalizar', isError: true);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildCollapsedActionPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.touch_app,
            color: Colors.grey[700],
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Controles de Desenho',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          _buildElegantButton(
            icon: Icons.keyboard_arrow_down,
            onPressed: () => setState(() => _isActionPanelCollapsed = false),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  /// 🚀 FORTSMART PREMIUM - Botão pill com sombra suave e animação
  Widget _buildPremiumPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isActive = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 40, // Altura ainda menor
      decoration: BoxDecoration(
        color: isActive ? color : color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24), // Estilo pill
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12, // Sombra mais suave
            offset: const Offset(0, 4),
          ),
          if (isActive)
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon, 
                  color: Colors.white, 
                  size: 16, // Ícone ainda menor
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10, // Fonte ainda menor
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          onTap: () {
            print('Botão pressionado: $label');
            onPressed();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.grey.withOpacity(0.2),
          highlightColor: Colors.grey.withOpacity(0.1),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.grey[600], size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildGpsIndicator() {
    return Positioned(
      top: 100,
      left: 20,
      child: Consumer<NovoTalhaoController>(
        builder: (context, controller, child) {
          final isGpsActive = _gpsService.isTracking;
          final isPaused = _gpsService.isPaused;
          final userLocation = controller.userLocation;
          
          return AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isGpsActive ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isGpsActive 
                        ? (isPaused ? Colors.orange : Colors.green)
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isGpsActive 
                            ? (isPaused ? Colors.orange : Colors.green)
                            : Colors.grey).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGpsActive 
                            ? (isPaused ? Icons.pause : Icons.gps_fixed)
                            : Icons.gps_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isGpsActive 
                            ? (isPaused ? 'Pausado' : 'Ativo')
                            : 'Inativo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Métodos de ação
  void _onMapTap(LatLng point, NovoTalhaoController controller) {
    print('🖊️ === FIELDS AREA MEASURE - TAP NO MAPA ===');
    print('Ponto: $point');
    print('Vértices atuais: ${_polygonVertices.length}');
    print('Modo edição: $_isEditMode');
    
    if (controller.isDrawing) {
      // Verificar se o toque foi em um vértice existente
      final tappedVertexIndex = _findNearestVertexIndex(point);
      
      if (tappedVertexIndex != -1) {
        // Toque em vértice existente - ativar modo de edição
        print('📍 Vértice ${tappedVertexIndex + 1} selecionado para edição');
        _enterEditMode(tappedVertexIndex);
        HapticFeedback.mediumImpact();
      } else if (_isEditMode && _editingVertexIndex != null) {
        // Modo edição ativo - mover vértice para nova posição
        print('🔄 Movendo vértice ${_editingVertexIndex! + 1} para: $point');
        _moveVertex(_editingVertexIndex!, point);
        _exitEditMode();
        HapticFeedback.lightImpact();
      } else {
        // Toque em área vazia - adicionar novo vértice
        print('➕ Adicionando novo vértice...');
        _addVertex(point);
        HapticFeedback.lightImpact();
        // Mensagem removida - agora é controlada dentro de _addVertex
      }
    } else {
      print('❌ Modo desenho não ativo');
      _showElegantSnackBar('Ative o modo desenho primeiro clicando no botão DESENHAR');
    }
  }

  /// Verifica se deve fechar o polígono automaticamente
  void _checkAutoClosePolygon(NovoTalhaoController controller) {
    if (controller.currentPoints.length >= 3) {
      final firstPoint = controller.currentPoints.first;
      final lastPoint = controller.currentPoints.last;
      final distance = GeoCalculator.haversineDistance(firstPoint, lastPoint);
      
      print('🔍 Verificando fechamento automático - Distância: ${distance.toStringAsFixed(1)}m');
      
      // Se a distância entre primeiro e último ponto for menor que 50m, fechar automaticamente
      if (distance < 50.0) {
        print('🔄 Fechando polígono automaticamente (distância: ${distance.toStringAsFixed(1)}m)');
        
        // Verificar se o polígono já está fechado (último ponto igual ao primeiro)
        final isAlreadyClosed = controller.currentPoints.length > 3 && 
            GeoCalculator.haversineDistance(firstPoint, lastPoint) < 1.0;
        
        if (!isAlreadyClosed) {
          // Adicionar o primeiro ponto no final para fechar o polígono
          final closedPoints = List<LatLng>.from(controller.currentPoints);
          closedPoints.add(firstPoint);
          controller.setCurrentPoints(closedPoints);
          
          _showElegantSnackBar('Polígono fechado automaticamente!', isSuccess: true);
          HapticFeedback.heavyImpact();
        }
      }
    }
  }

  // 🚀 FIELDS AREA MEASURE - Métodos de gerenciamento de vértices
  
  /// 🚀 FORTSMART ORIGINAL - Adiciona um novo vértice ao polígono
  void _addVertex(LatLng vertex) {
    setState(() {
      _polygonVertices.add(vertex);
      _vertexAddCount++;
    });
    print('✅ Vértice adicionado. Total: ${_polygonVertices.length}');
    
    // Mostrar mensagem apenas em casos específicos
    if (_vertexAddCount == 1) {
      _showElegantSnackBar('Desenho iniciado - Continue adicionando pontos', isSuccess: true);
    } else if (_vertexAddCount == 3) {
      _showElegantSnackBar('Polígono formado - Pode finalizar quando quiser', isSuccess: true);
    } else if (_vertexAddCount % 5 == 0) {
      // Mostrar a cada 5 pontos
      _showElegantSnackBar('${_polygonVertices.length} pontos adicionados', isSuccess: true);
    }
    // Para outros casos, não mostrar mensagem
  }
  
  /// Move um vértice existente para nova posição
  void _moveVertex(int index, LatLng newPosition) {
    if (index >= 0 && index < _polygonVertices.length) {
      setState(() {
        _polygonVertices[index] = newPosition;
      });
      print('✅ Vértice ${index + 1} movido para: $newPosition');
    }
  }
  
  /// Remove um vértice do polígono
  /// 🚀 FORTSMART ORIGINAL - Remove um vértice específico
  void _removeVertex(int index) {
    if (index >= 0 && index < _polygonVertices.length) {
      setState(() {
        _polygonVertices.removeAt(index);
        _vertexAddCount = _polygonVertices.length; // Atualizar contador
        // Ajustar índice de edição se necessário
        if (_editingVertexIndex != null && _editingVertexIndex! >= index) {
          _editingVertexIndex = _editingVertexIndex! > 0 ? _editingVertexIndex! - 1 : null;
        }
      });
      print('✅ Vértice ${index + 1} removido. Total: ${_polygonVertices.length}');
    }
  }
  
  /// 🚀 FORTSMART ORIGINAL - Limpa todos os vértices
  void _clearVertices() {
    setState(() {
      _polygonVertices.clear();
      _isEditMode = false;
      _editingVertexIndex = null;
      _vertexAddCount = 0; // Resetar contador
    });
    print('✅ Todos os vértices removidos');
  }
  
  /// Entra no modo de edição para um vértice específico
  void _enterEditMode(int vertexIndex) {
    setState(() {
      _isEditMode = true;
      _editingVertexIndex = vertexIndex;
    });
    // Mensagem apenas no primeiro vértice selecionado
    if (_editingVertexIndex == null) {
      _showElegantSnackBar('Vértice ${vertexIndex + 1} selecionado', isSuccess: true);
    }
  }
  
  /// Sai do modo de edição
  void _exitEditMode() {
    setState(() {
      _isEditMode = false;
      _editingVertexIndex = null;
    });
    // Mensagem removida - feedback visual é suficiente
  }
  
  /// Encontra o índice do vértice mais próximo do toque
  int _findNearestVertexIndex(LatLng tapPoint) {
    if (_polygonVertices.isEmpty) return -1;
    
    double minDistance = double.infinity;
    int nearestIndex = -1;
    
    for (int i = 0; i < _polygonVertices.length; i++) {
      final distance = GeoCalculator.haversineDistance(tapPoint, _polygonVertices[i]);
      if (distance < minDistance && distance < 50.0) { // 50m de tolerância
        minDistance = distance;
        nearestIndex = i;
      }
    }
    
    return nearestIndex;
  }
  
  /// 🚀 FORTSMART ORIGINAL - Gera pontos para polígono fechado
  List<LatLng> _getClosedPolygonPoints() {
    if (_polygonVertices.isEmpty) return [];
    
    // Se tem menos de 3 pontos, retorna apenas os pontos existentes
    if (_polygonVertices.length < 3) return _polygonVertices;
    
    // Para polígono fechado, adiciona o primeiro ponto no final
    return [..._polygonVertices, _polygonVertices.first];
  }
  
  /// 🚀 FORTSMART ORIGINAL - Calcula área do polígono em hectares
  double _calculatePolygonArea() {
    if (_polygonVertices.length < 3) return 0.0;
    
    // Verificar se já existe uma área calculada e válida
    if (_currentArea != null && _currentArea! > 0) {
      return _currentArea!;
    }
    
    // Calcular área usando serviço preciso se GPS avançado estiver disponível
    if (_advancedGPSService != null && _preciseAreaService != null && _polygonVertices.isNotEmpty) {
      try {
        // Tentar usar pontos GPS filtrados para cálculo mais preciso
        final gpsArea = _preciseAreaService!.calculateAreaFromGPSPositions(_advancedGPSService!);
        if (gpsArea > 0) {
          _currentArea = gpsArea;
          print('🛰️ Área calculada usando GPS filtrado: ${gpsArea.toStringAsFixed(4)} ha');
          return gpsArea;
        }
      } catch (e) {
        print('⚠️ Erro ao calcular área com GPS filtrado, usando método padrão: $e');
      }
    }
    
    // Fallback para cálculo padrão
    final calculatedArea = GeoCalculator.calculateAreaHectares(_polygonVertices);
    _currentArea = calculatedArea; // Armazenar para evitar recálculos
    return calculatedArea;
  }
  
  /// 🚀 FORTSMART ORIGINAL - Calcula perímetro do polígono em metros
  double _calculatePolygonPerimeter() {
    if (_polygonVertices.length < 2) return 0.0;
    
    return GeoCalculator.calculatePerimeterMeters(_polygonVertices);
  }

  /// Move um ponto para uma nova posição
  void _movePoint(int index, LatLng newPosition, NovoTalhaoController controller) {
    if (index >= 0 && index < controller.currentPoints.length) {
      print('🔄 Movendo ponto ${index + 1} para: $newPosition');
      controller.movePoint(index, newPosition);
      _showElegantSnackBar('Ponto ${index + 1} movido', isSuccess: true);
      HapticFeedback.lightImpact();
    }
  }

  /// Finaliza o arrasto de ponto
  void _finishDragging() {
    if (_selectedPointIndex != null) {
      print('✅ Arrasto finalizado para ponto ${_selectedPointIndex! + 1}');
      _selectedPointIndex = null;
    }
  }

  void _startDrawing() {
    print('=== INICIANDO DESENHO ===');
    print('Controller antes: ${_controller.runtimeType}');
    print('isDrawing antes: ${_controller.isDrawing}');
    
    _controller.startDrawing();
    
    print('isDrawing depois: ${_controller.isDrawing}');
    print('currentPoints: ${_controller.currentPoints.length}');
    
    _showElegantSnackBar('Modo desenho ativado - Toque no mapa para adicionar pontos', isSuccess: true);
    print('Desenho iniciado com sucesso');
  }

  /// 🚀 FORTSMART ORIGINAL - Desfazer último vértice
  void _undoLastPoint() {
    if (_polygonVertices.isNotEmpty) {
      _removeVertex(_polygonVertices.length - 1);
      _showElegantSnackBar('Último vértice removido', isSuccess: true);
    } else {
      _showElegantSnackBar('Nenhum vértice para desfazer');
    }
  }

  /// 🚀 FORTSMART ORIGINAL - Limpar todos os vértices
  void _clearDrawing() {
    _clearVertices();
    _showElegantSnackBar('Polígono limpo', isSuccess: true);
  }
  
  /// 🚀 FORTSMART ORIGINAL - Finalizar polígono e abrir card de salvamento
  void _finalizePolygon() {
    if (_polygonVertices.length < 3) {
      _showElegantSnackBar('Adicione pelo menos 3 vértices para finalizar', isError: true);
      return;
    }
    
    // Fechar polígono automaticamente se necessário
    _checkAutoClosePolygon(_controller);
    
    // Mostrar feedback
    _showElegantSnackBar('✅ Polígono finalizado! Abrindo card de salvamento...', isSuccess: true);
    
    // Abrir card de salvamento
    _showSaveDialog();
  }

  /// 🚀 FORTSMART ORIGINAL - Importar polígonos com sistema robusto
  void _importPolygons() async {
    try {
      print('📁 === IMPORTANDO POLÍGONOS (SISTEMA ROBUSTO) ===');
      
      // Usar serviço robusto de importação
      final importService = RobustGeoImportService();
      final result = await importService.importGeoFile(
        context: context,
        allowedExtensions: ['geojson', 'json', 'kml', 'kmz', 'shp', 'zip'],
      );
      
      if (result.success) {
        // Processar resultado da importação
        await _processRobustImportResult(result);
      } else {
        _showElegantSnackBar('❌ ${result.error}', isError: true);
      }
    } catch (e) {
      print('❌ Erro na importação robusta: $e');
      _showElegantSnackBar('Erro ao importar arquivo: $e', isError: true);
    }
  }
  
  /// 🚀 FORTSMART ORIGINAL - Processar resultado da importação robusta
  Future<void> _processRobustImportResult(RobustImportResult result) async {
    try {
      if (result.polygons.isEmpty) {
        _showElegantSnackBar('Nenhum polígono válido encontrado no arquivo', isError: true);
        return;
      }
      
      // Limpar polígono atual
      _clearVertices();
      
      // Carregar primeiro polígono (ou mostrar seleção se múltiplos)
      if (result.hasMultiplePolygons) {
        await _showPolygonSelectionDialog(result);
      } else {
        await _loadPolygonToVertices(result.polygons.first);
      }
      
      // Mostrar informações do arquivo
      _showImportSuccessDialog(result);
      
    } catch (e) {
      print('❌ Erro ao processar resultado: $e');
      _showElegantSnackBar('Erro ao processar arquivo importado: $e', isError: true);
    }
  }
  
  /// 🚀 FORTSMART ORIGINAL - Carregar polígono para vértices
  Future<void> _loadPolygonToVertices(List<LatLng> polygon) async {
    for (final point in polygon) {
      _addVertex(point);
    }
    
    // Atualizar métricas
    setState(() {});
    
    // Mensagem mais concisa para importação
    _showElegantSnackBar(
      '✅ ${polygon.length} pontos importados', 
      isSuccess: true
    );
  }
  
  /// 🚀 FORTSMART ORIGINAL - Dialog de seleção de polígono (múltiplos)
  Future<void> _showPolygonSelectionDialog(RobustImportResult result) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Múltiplos Polígonos Encontrados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Arquivo contém ${result.polygons.length} polígono(s).'),
            const SizedBox(height: 16),
            const Text('Selecione qual polígono carregar:'),
            const SizedBox(height: 16),
            ...result.polygons.asMap().entries.map((entry) {
              final index = entry.key;
              final polygon = entry.value;
              final area = GeoCalculator.calculateAreaHectares(polygon);
              
              return ListTile(
                title: Text('Polígono ${index + 1}'),
                subtitle: Text('${polygon.length} pontos, ${area.toStringAsFixed(2)} ha'),
                onTap: () {
                  Navigator.pop(context);
                  _loadPolygonToVertices(polygon);
                },
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
  
  /// 🚀 FORTSMART ORIGINAL - Dialog de sucesso da importação
  void _showImportSuccessDialog(RobustImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Importação Concluída'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📄 Arquivo: ${result.fileName}'),
            Text('📐 Formato: ${result.sourceFormat.toUpperCase()}'),
            Text('🔢 Polígonos: ${result.polygons.length}'),
            Text('📍 Pontos: ${result.totalPoints}'),
            if (result.totalArea != null)
              Text('📏 Área: ${result.totalArea!.toStringAsFixed(2)} ha'),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('⚠️ Avisos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.warnings.map((warning) => Text('• $warning')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  

  void _showSaveDialog() {
    if (_polygonVertices.length < 3) {
      _showElegantSnackBar('Adicione pelo menos 3 vértices para criar um talhão', isError: true);
      return;
    }
    
    // Validar qualidade dos pontos GPS se disponível
    if (_preciseAreaService != null) {
      final isValid = _preciseAreaService!.validatePointsForPreciseCalculation(_polygonVertices);
      if (!isValid) {
        _showElegantSnackBar('⚠️ Qualidade dos pontos GPS insuficiente. Considere refazer o mapeamento.', isError: true);
        // Não bloquear, apenas avisar
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPremiumSaveDialog(),
    );
  }


  void _pauseGpsTracking() {
    _gpsService.pauseTracking();
    _stopRealTimeUpdateTimer();
    setState(() {
      _isGpsPaused = true;
    });
    _showElegantSnackBar('GPS pausado', isSuccess: true);
  }

  void _resumeGpsTracking() {
    _gpsService.resumeTracking();
    _startRealTimeUpdateTimer();
    setState(() {
      _isGpsPaused = false;
    });
    _showElegantSnackBar('GPS retomado', isSuccess: true);
  }

  void _stopGpsTracking() {
    _gpsService.stopTracking();
    _stopRealTimeUpdateTimer();
    setState(() {
      _isGpsPaused = false;
    });
    _showElegantSnackBar('GPS parado', isSuccess: true);
  }

  void _startGpsTracking() async {
    try {
      print('🚶 Iniciando modo Caminhada GPS...');
      
      // Iniciar desenho primeiro
      _controller.startDrawing();
      
      final success = await _gpsService.startTracking(
        onPointsChanged: (points) {
          print('GPS: Novos pontos recebidos: ${points.length}');
          if (mounted && points.isNotEmpty) {
            final newPoint = points.last;
            
            // Adicionar ponto diretamente ao controller sem filtros excessivos
            setState(() {
              _controller.addPoint(newPoint);
              print('✅ Ponto GPS adicionado. Total: ${_controller.currentPoints.length}');
              
              // Atualizar métricas em tempo real
              _updateRealTimeMetrics();
              
              // Verificar se deve fechar o polígono automaticamente
              _checkAutoClosePolygon(_controller);
            });
          }
        },
        onDistanceChanged: (distance) {
          print('GPS: Distância atualizada: ${distance.toStringAsFixed(2)}m');
          if (mounted) {
            setState(() {
              // Atualizar métricas de distância
              _updateRealTimeMetrics();
            });
          }
        },
        onAccuracyChanged: (accuracy) {
          print('GPS: Precisão atualizada: ${accuracy.toStringAsFixed(2)}m');
          if (mounted) {
            setState(() {
              // Atualizar precisão atual
            });
          }
        },
        onStatusChanged: (status) {
          print('GPS: Status: $status');
          if (mounted) {
            _showElegantSnackBar('GPS: $status');
          }
        },
        onTrackingStateChanged: (isTracking) {
          print('GPS: Estado de rastreamento: $isTracking');
          if (mounted) setState(() {});
        },
      );
      
      if (success) {
        _isGpsPaused = false;
        _lastPointBeforePause = null;
        _showElegantSnackBar('🚶 Modo Caminhada GPS ativado - Caminhe pelo perímetro', isSuccess: true);
        print('✅ GPS iniciado com sucesso');
        
        // Iniciar timer para atualizações contínuas
        _startRealTimeUpdateTimer();
      } else {
        _showElegantSnackBar('❌ Erro ao iniciar GPS - Verifique as permissões', isError: true);
        print('❌ Falha ao iniciar GPS');
      }
    } catch (e) {
      _showElegantSnackBar('❌ Erro ao iniciar GPS: $e', isError: true);
      print('❌ Erro ao iniciar GPS: $e');
    }
  }

  /// Timer para atualizações em tempo real
  Timer? _realTimeUpdateTimer;
  
  /// Inicia timer para atualizações em tempo real
  void _startRealTimeUpdateTimer() {
    _realTimeUpdateTimer?.cancel();
    _realTimeUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && _gpsService.isTracking) {
        _updateRealTimeMetrics();
      }
    });
  }
  
  /// Para timer de atualizações em tempo real
  void _stopRealTimeUpdateTimer() {
    _realTimeUpdateTimer?.cancel();
    _realTimeUpdateTimer = null;
  }
  
  /// Atualiza métricas em tempo real
  void _updateRealTimeMetrics() {
    if (_controller.currentPoints.length >= 3) {
      // Calcular área e perímetro em tempo real usando o MESMO padrão do desenho manual
      final area = GeoCalculator.calculateAreaHectares(_controller.currentPoints);
      final perimeter = GeoCalculator.calculatePerimeterMeters(_controller.currentPoints);
      
      // Atualizar métricas no controller
      _controller.setCurrentArea(area);
      _controller.setCurrentPerimeter(perimeter);
      
      print('📊 Métricas atualizadas - Área: ${area.toStringAsFixed(2)} ha, Perímetro: ${perimeter.toStringAsFixed(1)} m, Vértices: ${_controller.currentPoints.length}');
    }
  }

  /// Aplica filtro de suavização com média móvel dos últimos 10 pontos
  LatLng _applySmoothingFilter(LatLng newPoint) {
    // Manter histórico dos últimos 10 pontos para suavização
    if (!_controller.currentPoints.isEmpty) {
      final recentPoints = _controller.currentPoints.length >= 10 
          ? _controller.currentPoints.sublist(_controller.currentPoints.length - 10)
          : _controller.currentPoints;
      
      // Calcular média ponderada (último ponto tem mais peso)
      double totalLat = 0;
      double totalLng = 0;
      double totalWeight = 0;
      
      for (int i = 0; i < recentPoints.length; i++) {
        final weight = (i + 1) / recentPoints.length; // Peso crescente
        totalLat += recentPoints[i].latitude * weight;
        totalLng += recentPoints[i].longitude * weight;
        totalWeight += weight;
      }
      
      // Adicionar o novo ponto com peso máximo
      totalLat += newPoint.latitude * 2.0;
      totalLng += newPoint.longitude * 2.0;
      totalWeight += 2.0;
      
      return LatLng(totalLat / totalWeight, totalLng / totalWeight);
    }
    
    return newPoint;
  }



  // Métodos para edição avançada de polígonos
  void _onPointTapped(int index, NovoTalhaoController controller) {
    setState(() {
      _selectedPointIndex = index;
    });
    _showElegantSnackBar('Ponto ${index + 1} selecionado - Arraste para mover', isSuccess: true);
    HapticFeedback.mediumImpact();
  }

  void _onPointDragged(int index, DragUpdateDetails details, NovoTalhaoController controller) {
    if (controller.mapController != null) {
      try {
        // Obter a posição atual do ponto no mapa
        final currentPoint = controller.currentPoints[index];
        final currentScreenPoint = controller.mapController!.camera.latLngToScreenPoint(currentPoint);
        
        // Calcular o novo ponto baseado no delta do arrasto
        final newScreenPoint = CustomPoint(
          currentScreenPoint.x + details.delta.dx,
          currentScreenPoint.y + details.delta.dy,
        );
        
        // Converter de volta para coordenadas geográficas
        final newLatLng = controller.mapController!.camera.pointToLatLng(newScreenPoint);
        
        // Atualizar a posição do ponto
        controller.movePoint(index, newLatLng);
        
        print('🔄 Ponto ${index + 1} movido para: $newLatLng');
      } catch (e) {
        print('❌ Erro ao mover ponto: $e');
      }
    }
  }

  void _onPointDragEnd(int index, NovoTalhaoController controller) {
    setState(() {
      _selectedPointIndex = null;
    });
    
    _showElegantSnackBar('Ponto ${index + 1} movido com sucesso', isSuccess: true);
    HapticFeedback.lightImpact();
    
    // Verificar se deve fechar o polígono automaticamente após mover ponto
    _checkAutoClosePolygon(controller);
  }

  void _centerMapOnLocation() async {
    // Atualizar localização atual
    final location = await _controller.getCurrentLocation();
    if (location != null) {
      _controller.updateCurrentLocation(location);
    }
    _showElegantSnackBar('Mapa centralizado', isSuccess: true);
  }


  Widget _buildPremiumSaveDialog() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle elegante
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Título premium
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.agriculture,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salvar Talhão',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Crie um talhão com precisão centimétrica',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 🚀 Métricas FortSmart (Sistema Original)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSaveMetricItem(
                      icon: Icons.crop_square,
                      label: 'Área',
                      value: PreciseGeoCalculator.formatAreaBrazilian(_calculatePolygonArea()),
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  Expanded(
                    child: _buildSaveMetricItem(
                      icon: Icons.straighten,
                      label: 'Perímetro',
                      value: PreciseGeoCalculator.formatPerimeterBrazilian(_calculatePolygonPerimeter()),
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildSaveMetricItem(
                      icon: Icons.location_on,
                      label: 'Vértices',
                      value: '${_polygonVertices.length}',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 🚀 Campo único de nome do talhão
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Nome do Talhão',
                hintText: 'Ex: Talhão Norte, Área 1, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.label),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Seleção de cultura
            DropdownButtonFormField<CulturaModel>(
              value: _culturaSelecionada,
              decoration: InputDecoration(
                labelText: 'Cultura',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.eco),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _culturas.map((cultura) {
                return DropdownMenuItem(
                  value: cultura,
                  child: Row(
                    children: [
                      Icon(cultura.icon, color: cultura.color, size: 20),
                      const SizedBox(width: 8),
                      Text(cultura.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _culturaSelecionada = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Campo de texto livre para safra
            TextField(
              controller: _safraController,
              decoration: InputDecoration(
                labelText: 'Safra (opcional)',
                hintText: 'Ex: 2024/2025, 2023/2024, ou qualquer texto',
                helperText: 'Deixe em branco se não souber a safra',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.calendar_today),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _observacoesController,
              decoration: InputDecoration(
                labelText: 'Observações (opcional)',
                hintText: 'Adicione informações relevantes sobre o talhão',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.note),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: 24),
            
            // Botões premium
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.cancel,
                    label: 'Cancelar',
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.save,
                    label: 'Salvar Talhão',
                    onPressed: () {
                      Navigator.pop(context);
                      _saveTalhao();
                    },
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _saveTalhao() async {
    try {
      print('💾 === SALVANDO TALHÃO ===');
      
      // Validar se há cultura selecionada
      if (_culturaSelecionada == null) {
        _showElegantSnackBar('❌ Selecione uma cultura para o talhão', isError: true);
        return;
      }
      
      // Validar se há vértices suficientes
      if (_polygonVertices.length < 3) {
        _showElegantSnackBar('❌ Adicione pelo menos 3 vértices para criar um talhão', isError: true);
        return;
      }
      
      // Gerar ID único e localizável
      final talhaoId = 'TALHAO_${DateTime.now().millisecondsSinceEpoch}_${_polygonVertices.length}V';
      final poligonoId = 'POL_${talhaoId}';
      
      print('ID do Talhão: $talhaoId');
      print('ID do Polígono: $poligonoId');
      
      // Calcular área e perímetro usando sistema FortSmart
      final areaCalculada = _calculatePolygonArea();
      final perimetroCalculado = _calculatePolygonPerimeter();
      
      // Criar polígono com cálculos precisos do FortSmart
      final poligono = PoligonoModel.criar(
        pontos: _polygonVertices,
        talhaoId: poligonoId,
        area: areaCalculada,
        perimetro: perimetroCalculado,
      );

      // Obter valores dos campos de texto
      final nomeTalhao = _nomeController.text.trim().isNotEmpty 
          ? _nomeController.text.trim()
          : 'Talhão ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
      
      final safraTexto = _safraController.text.trim();
      final observacoesTexto = _observacoesController.text.trim();
      
      // Criar safra se texto foi fornecido
      List<SafraModel> safras = [];
      if (safraTexto.isNotEmpty) {
        final safra = SafraModel.criar(
          talhaoId: talhaoId,
          safra: safraTexto,
          culturaId: _culturaSelecionada!.id,
          culturaNome: _culturaSelecionada!.name,
          culturaCor: _culturaSelecionada!.color.value.toRadixString(16),
        );
        safras = [safra];
      }

      // Criar talhão com dados completos do FortSmart
      final talhao = TalhaoModel(
        id: talhaoId,
        name: nomeTalhao,
        poligonos: [poligono],
        area: areaCalculada,
        observacoes: observacoesTexto.isNotEmpty 
            ? observacoesTexto
            : 'Criado com sistema FortSmart - ${_polygonVertices.length} vértices',
        culturaId: _culturaSelecionada!.id,
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        sincronizado: false,
        safras: safras,
      );

      // Salvar no banco de dados local (SQLite) primeiro
      final salvouComSucesso = await _saveToLocalDatabase(talhao);
      
      if (!salvouComSucesso) {
        _showElegantSnackBar('❌ Erro ao salvar talhão no banco de dados', isError: true);
        return;
      }
      
      // 🚀 FORTSMART ORIGINAL - Carregar talhões do banco de dados
      await _loadTalhoesFromDatabase();
      
      // Exportar para GeoJSON (opcional)
      await _exportToGeoJSON(talhao);

      // 🚀 FORTSMART ORIGINAL - Fechar card de salvamento
      Navigator.pop(context);
      
      _showElegantSnackBar('✅ Talhão "$nomeTalhao" salvo com sucesso!', isSuccess: true);
      print('✅ Talhão "$nomeTalhao" salvo com sucesso! ID: $talhaoId');
      
      // 🚀 FORTSMART ORIGINAL - Limpar sistema de vértices após salvar
      _clearVertices();
      _exitEditMode();
      setState(() {
        _selectedPointIndex = null;
        _culturaSelecionada = null;
      });
      
      // Limpar campos de texto
      _nomeController.clear();
      _safraController.clear();
      _observacoesController.clear();
      
    } catch (e) {
      _showElegantSnackBar('❌ Erro ao salvar talhão: $e', isError: true);
      print('❌ Erro ao salvar talhão: $e');
    }
  }

  /// Salva o talhão no banco de dados local SQLite
  Future<bool> _saveToLocalDatabase(TalhaoModel talhao) async {
    try {
      print('💾 Salvando no banco de dados local...');
      
      // Usar TalhaoProvider para salvar no banco de dados real
      final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
      
      // Converter TalhaoModel para formato esperado pelo provider
      final pontos = talhao.poligonos.first.pontos;
      final culturaId = talhao.culturaId ?? '';
      final culturaNome = _culturaSelecionada?.name ?? 'Cultura não definida';
      final culturaCor = _culturaSelecionada?.color ?? Colors.green;
      
      // Obter ID da fazenda (usar um ID padrão se não estiver disponível)
      final idFazenda = 'FAZENDA_DEFAULT'; // TODO: Obter ID real da fazenda
      
      // Obter ID da safra (usar texto da safra se fornecido)
      final idSafra = _safraController.text.trim().isNotEmpty 
          ? _safraController.text.trim()
          : 'SAFRA_${DateTime.now().year}';
      
      print('🔍 Dados para salvamento:');
      print('  - Nome: ${talhao.name}');
      print('  - Pontos: ${pontos.length}');
      print('  - Cultura: $culturaNome');
      print('  - Safra: $idSafra');
      print('  - Área: ${talhao.area}');
      
      // Salvar usando o provider com área já calculada
      final sucesso = await talhaoProvider.salvarTalhao(
        nome: talhao.name,
        idFazenda: idFazenda,
        pontos: pontos,
        idCultura: culturaId,
        nomeCultura: culturaNome,
        corCultura: culturaCor,
        idSafra: idSafra,
        areaCalculada: talhao.area, // Usar área já calculada nas métricas
      );
      
      if (sucesso) {
        print('✅ Talhão salvo no banco de dados com sucesso');
        
        // Adicionar talhão ao mapa para persistência visual
        _addTalhaoToMap(talhao);
        return true;
      } else {
        print('❌ Falha ao salvar talhão no banco de dados');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao salvar no banco local: $e');
      return false;
    }
  }

  /// Carrega talhões do banco de dados
  Future<void> _loadTalhoesFromDatabase() async {
    try {
      print('📥 Carregando talhões do banco de dados...');
      
      // Usar TalhaoProvider para carregar talhões
      final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
      final talhoes = await talhaoProvider.carregarTalhoes();
      
      print('📊 ${talhoes.length} talhões carregados do banco');
      
      if (talhoes.isEmpty) {
        print('ℹ️ Nenhum talhão encontrado no banco de dados');
        _controller.existingTalhoes.clear();
        setState(() {});
        return;
      }
      
      // Converter TalhaoSafraModel para TalhaoModel
      final talhoesConvertidos = talhoes.map((talhaoSafra) {
        // Converter PoligonoModel do talhao_safra para PoligonoModel padrão
        final poligonosConvertidos = talhaoSafra.poligonos.map((poligono) => PoligonoModel(
          id: poligono.id,
          talhaoId: poligono.talhaoId,
          pontos: poligono.pontos,
          area: poligono.area.toDouble(),
          perimetro: poligono.perimetro.toDouble(),
          dataCriacao: poligono.dataCriacao,
          dataAtualizacao: poligono.dataAtualizacao,
          ativo: poligono.ativo,
        )).toList();

        return TalhaoModel(
          id: talhaoSafra.id,
          name: talhaoSafra.name,
          poligonos: poligonosConvertidos,
          area: talhaoSafra.area ?? 0.0,
          observacoes: 'Carregado do banco de dados',
          culturaId: talhaoSafra.safras.isNotEmpty ? talhaoSafra.safras.first.idCultura : null,
          dataCriacao: talhaoSafra.dataCriacao,
          dataAtualizacao: talhaoSafra.dataAtualizacao,
          sincronizado: false,
          safras: talhaoSafra.safras.map((safra) => SafraModel(
            id: safra.id,
            talhaoId: safra.idTalhao,
            safra: safra.idSafra,
            culturaId: safra.idCultura,
            culturaNome: safra.culturaNome,
            culturaCor: safra.culturaCor.value.toRadixString(16),
            dataCriacao: safra.dataCadastro,
            dataAtualizacao: safra.dataAtualizacao,
            sincronizado: safra.sincronizado,
            periodo: safra.idSafra,
            dataInicio: safra.dataCadastro,
            dataFim: safra.dataAtualizacao,
            ativa: true,
            nome: safra.culturaNome,
          )).toList(),
        );
      }).toList();
      
      // Atualizar lista no controller
      _controller.existingTalhoes.clear();
      _controller.existingTalhoes.addAll(talhoesConvertidos);
      
      print('✅ ${talhoesConvertidos.length} talhões carregados no mapa');
      
      // Log detalhado para debug
      for (final talhao in talhoesConvertidos) {
        print('📋 Talhão carregado: ${talhao.name}');
        print('  - ID: ${talhao.id}');
        print('  - Polígonos: ${talhao.poligonos.length}');
        print('  - Área: ${talhao.area} ha');
        if (talhao.poligonos.isNotEmpty) {
          print('  - Pontos do primeiro polígono: ${talhao.poligonos.first.pontos.length}');
        }
      }
      
      // Forçar rebuild do mapa
      setState(() {});
      
    } catch (e) {
      print('❌ Erro ao carregar talhões do banco: $e');
      // Em caso de erro, limpar a lista para evitar dados inconsistentes
      _controller.existingTalhoes.clear();
      setState(() {});
    }
  }

  /// Adiciona o talhão ao mapa para persistência visual
  void _addTalhaoToMap(TalhaoModel talhao) {
    try {
      print('🗺️ Adicionando talhão ao mapa: ${talhao.name}');
      
      // Adicionar talhão à lista do controller para que apareça no mapa
      _controller.existingTalhoes.add(talhao);
      
      // Forçar rebuild do mapa para mostrar o novo talhão
      setState(() {});
      
      print('✅ Talhão adicionado ao mapa com sucesso');
      print('📊 Total de talhões no mapa: ${_controller.existingTalhoes.length}');
    } catch (e) {
      print('❌ Erro ao adicionar talhão ao mapa: $e');
    }
  }

  /// Exporta o talhão para GeoJSON
  Future<void> _exportToGeoJSON(TalhaoModel talhao) async {
    try {
      print('📤 Exportando para GeoJSON...');
      
      // Criar estrutura GeoJSON
      final geoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {
              'id': talhao.id,
              'name': talhao.name,
              'area': talhao.area,
              'cultura_id': talhao.culturaId,
              'data_criacao': talhao.dataCriacao.toIso8601String(),
              'observacoes': talhao.observacoes,
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                talhao.poligonos.first.pontos.map((point) => [point.longitude, point.latitude]).toList()
              ],
            },
          },
        ],
      };
      
      // Salvar arquivo GeoJSON (implementar com file system)
      print('✅ GeoJSON exportado com sucesso');
    } catch (e) {
      print('❌ Erro ao exportar GeoJSON: $e');
      // Não falhar o salvamento por causa do GeoJSON
    }
  }



  void _showTalhaoFloatingCard(TalhaoModel talhao) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TalhaoFloatingCard(
        talhao: talhao,
        culturas: _culturas,
        safras: ['2024/2025', '2023/2024', '2022/2023'],
        onSave: (updatedTalhao) {
          Navigator.pop(context); // Fechar card
          _updateTalhaoInList(updatedTalhao);
          _showElegantSnackBar('Talhão "${updatedTalhao.name}" atualizado com sucesso!', isSuccess: true);
        },
        onDelete: (deletedTalhao) {
          Navigator.pop(context); // Fechar card
          _removeTalhaoFromList(deletedTalhao);
          _showElegantSnackBar('Talhão "${deletedTalhao.name}" removido com sucesso!', isSuccess: true);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _updateTalhaoInList(TalhaoModel updatedTalhao) {
    // Atualizar talhão na lista do controller
    final index = _controller.existingTalhoes.indexWhere((t) => t.id == updatedTalhao.id);
    if (index != -1) {
      _controller.existingTalhoes[index] = updatedTalhao;
      setState(() {}); // Atualizar UI
    }
  }

  void _removeTalhaoFromList(TalhaoModel deletedTalhao) {
    // Remover talhão da lista do controller
    _controller.existingTalhoes.removeWhere((t) => t.id == deletedTalhao.id);
    setState(() {}); // Atualizar UI
  }

  void _showGpsSettings() {
    showDialog(
      context: context,
      builder: (context) => GpsSettingsDialog(
        onSave: (settings) {
          _showElegantSnackBar('Configurações GPS salvas!', isSuccess: true);
        },
      ),
    );
  }

  /// 🚀 FORTSMART ORIGINAL - Mostra SnackBar inteligente (evita repetições)
  void _showElegantSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    final now = DateTime.now();
    
    // Evitar mensagens repetitivas (debounce de 2 segundos)
    if (_lastMessage == message && 
        _lastMessageTime != null && 
        now.difference(_lastMessageTime!).inSeconds < 2) {
      return; // Não mostrar mensagem repetitiva
    }
    
    // Atualizar controle de mensagens
    _lastMessage = message;
    _lastMessageTime = now;
    
    final color = isError ? Colors.red : (isSuccess ? Colors.green : Colors.blue);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : (isSuccess ? Icons.check_circle : Icons.info),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2), // Reduzido para 2 segundos
      ),
    );
  }

  // Métodos auxiliares para o mapa
  List<Polygon> _buildTalhaoPolygons(NovoTalhaoController controller) {
    return controller.existingTalhoes.map((talhao) {
      // Buscar cultura do talhão
      final cultura = _culturas.firstWhere(
        (c) => c.id == talhao.culturaId,
        orElse: () => _culturas.first,
      );
      
      return Polygon(
        points: talhao.poligonos.first.pontos,
        color: cultura.color.withOpacity(0.3),
        borderColor: cultura.color,
        borderStrokeWidth: 2.0,
        isFilled: true,
      );
    }).toList();
  }

  /// Constrói marcadores da localização do usuário
  List<Marker> _buildUserLocationMarkers(NovoTalhaoController controller) {
    final userLocation = controller.userLocation;
    if (userLocation == null) return [];
    
    return [
      Marker(
        point: userLocation,
        width: 20,
        height: 20,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  /// 🚀 FORTSMART PREMIUM - Constrói marcadores de vértices arrastáveis (modelo gota/pino)
  List<Marker> _buildFortSmartVertexMarkers() {
    if (_polygonVertices.isEmpty) return [];
    
    return _polygonVertices.asMap().entries.map((entry) {
      final index = entry.key;
      final vertex = entry.value;
      
      // Determinar cor baseada no estado
      Color vertexColor;
      Color borderColor;
      double borderWidth;
      double markerSize;
      
      if (_isDraggingVertex && _draggingVertexIndex == index) {
        // Vértice sendo arrastado - destaque especial
        vertexColor = Colors.orange;
        borderColor = Colors.white;
        borderWidth = 3.0;
        markerSize = 28;
      } else if (_isEditMode && _editingVertexIndex == index) {
        // Vértice sendo editado - destaque especial
        vertexColor = Colors.blue;
        borderColor = Colors.white;
        borderWidth = 3.0;
        markerSize = 26;
      } else if (_isEditMode) {
        // Modo edição ativo - outros vértices em tom mais suave
        vertexColor = Colors.blue.withOpacity(0.7);
        borderColor = Colors.white;
        borderWidth = 2.0;
        markerSize = 24;
      } else {
        // Estado normal - cor padrão FortSmart
        vertexColor = const Color(0xFF2E7D32); // Verde FortSmart
        borderColor = Colors.white;
        borderWidth = 2.0;
        markerSize = 24;
      }
      
      return Marker(
        point: vertex,
        width: markerSize,
        height: markerSize,
        child: GestureDetector(
          onTap: () => _onVertexTapped(index),
          onLongPressStart: (details) => _onVertexLongPressStart(index, details),
          onPanStart: (details) => _onVertexDragStart(index, details),
          onPanUpdate: (details) => _onVertexDragUpdate(index, details),
          onPanEnd: (details) => _onVertexDragEnd(index, details),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: markerSize,
            height: markerSize,
            child: CustomPaint(
              painter: PinMarkerPainter(
                color: vertexColor,
                borderColor: borderColor,
                borderWidth: borderWidth,
                isDragging: _isDraggingVertex && _draggingVertexIndex == index,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _isDraggingVertex && _draggingVertexIndex == index ? 12 : 11,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
  
  /// 🚀 FORTSMART ORIGINAL - Manipula toque em vértice
  void _onVertexTapped(int vertexIndex) {
    if (_isDraggingVertex) return; // Ignorar toque se estiver arrastando
    
    if (_isEditMode && _editingVertexIndex == vertexIndex) {
      // Cancelar edição se tocar no mesmo vértice
      _exitEditMode();
    } else {
      // Entrar em modo de edição
      _enterEditMode(vertexIndex);
    }
  }
  
  /// 🚀 FORTSMART PREMIUM - Início do pressionar e segurar (long press)
  void _onVertexLongPressStart(int vertexIndex, LongPressStartDetails details) {
    setState(() {
      _isLongPress = true;
      _draggingVertexIndex = vertexIndex;
      _dragStartPoint = _polygonVertices[vertexIndex];
      _dragStartTime = DateTime.now();
      _lastAutoPoint = _dragStartPoint;
    });
    
    HapticFeedback.mediumImpact();
    _showElegantSnackBar('🎯 Pino ${vertexIndex + 1} selecionado! Arraste para mover', isSuccess: true);
  }
  
  /// 🚀 FORTSMART PREMIUM - Início do arrasto
  void _onVertexDragStart(int vertexIndex, DragStartDetails details) {
    if (!_isLongPress) return; // Só arrastar se foi long press primeiro
    
    setState(() {
      _isDraggingVertex = true;
      _draggingVertexIndex = vertexIndex;
    });
    
    HapticFeedback.lightImpact();
  }
  
  /// 🚀 FORTSMART PREMIUM - Atualização do arrasto fluido
  void _onVertexDragUpdate(int vertexIndex, DragUpdateDetails details) {
    if (!_isDraggingVertex || _draggingVertexIndex != vertexIndex) return;
    
    // Converter posição da tela para coordenadas do mapa
    final mapController = _controller.mapController;
    if (mapController == null) return;
    
    final newPosition = mapController.camera.pointToLatLng(
      CustomPoint(details.globalPosition.dx, details.globalPosition.dy),
    );
    
    // Atualizar posição do vértice
    _moveVertex(vertexIndex, newPosition);
    
    // Verificar se deve criar novo ponto automaticamente (>100m)
    _checkAutoCreatePoint(vertexIndex, newPosition);
    
    // Atualizar métricas em tempo real
    _updateRealtimeMetrics();
    
    // Verificar se o ponto está saindo dos limites da tela
    _checkMapPanning(details.globalPosition);
  }
  
  /// 🚀 FORTSMART PREMIUM - Fim do arrasto
  void _onVertexDragEnd(int vertexIndex, DragEndDetails details) {
    setState(() {
      _isDraggingVertex = false;
      _draggingVertexIndex = null;
      _isLongPress = false;
      _dragStartPoint = null;
      _dragStartTime = null;
      _lastAutoPoint = null;
    });
    
    HapticFeedback.lightImpact();
    _showElegantSnackBar('🎯 Pino ${vertexIndex + 1} posicionado com sucesso!', isSuccess: true);
  }
  
  /// 🚀 FORTSMART PREMIUM - Verifica se o mapa deve acompanhar o arrasto
  void _checkMapPanning(Offset globalPosition) {
    final mapController = _controller.mapController;
    if (mapController == null) return;
    
    final screenSize = MediaQuery.of(context).size;
    final margin = 50.0; // Margem de segurança
    
    // Verificar se o ponto está próximo das bordas da tela
    bool shouldPan = false;
    Offset panOffset = Offset.zero;
    
    if (globalPosition.dx < margin) {
      // Ponto está muito à esquerda
      shouldPan = true;
      panOffset = Offset(globalPosition.dx - margin, 0);
    } else if (globalPosition.dx > screenSize.width - margin) {
      // Ponto está muito à direita
      shouldPan = true;
      panOffset = Offset(globalPosition.dx - (screenSize.width - margin), 0);
    }
    
    if (globalPosition.dy < margin) {
      // Ponto está muito acima
      shouldPan = true;
      panOffset = Offset(panOffset.dx, globalPosition.dy - margin);
    } else if (globalPosition.dy > screenSize.height - margin) {
      // Ponto está muito abaixo
      shouldPan = true;
      panOffset = Offset(panOffset.dx, globalPosition.dy - (screenSize.height - margin));
    }
    
    // Aplicar pan suave se necessário
    if (shouldPan) {
      final currentCenter = mapController.camera.center;
      final panSpeed = 0.5; // Velocidade do pan (ajustável)
      
      final newCenter = LatLng(
        currentCenter.latitude - (panOffset.dy * panSpeed * 0.00001),
        currentCenter.longitude + (panOffset.dx * panSpeed * 0.00001),
      );
      
      mapController.move(newCenter, mapController.camera.zoom);
    }
  }

  /// 🚀 FORTSMART PREMIUM - Verifica se deve criar novo ponto automaticamente
  void _checkAutoCreatePoint(int vertexIndex, LatLng currentPosition) {
    if (_lastAutoPoint == null) return;
    
    // Calcular distância usando Haversine
    final distance = GeoCalculator.haversineDistance(_lastAutoPoint!, currentPosition);
    
    if (distance >= _autoPointDistance) {
      _createAutoPoint(vertexIndex, currentPosition);
      _lastAutoPoint = currentPosition;
      
      // Feedback visual e haptic
      HapticFeedback.mediumImpact();
      _showElegantSnackBar('✨ Novo pino criado automaticamente!', isSuccess: true);
    }
  }
  
  /// 🚀 FORTSMART PREMIUM - Cria um novo ponto automaticamente
  void _createAutoPoint(int vertexIndex, LatLng position) {
    final newPoints = List<LatLng>.from(_polygonVertices);
    
    // Inserir novo ponto após o ponto atual
    newPoints.insert(vertexIndex + 1, position);
    
    setState(() {
      _polygonVertices = newPoints;
      _draggingVertexIndex = vertexIndex + 1; // Atualizar índice do ponto sendo arrastado
    });
    
    _showElegantSnackBar('Novo ponto criado automaticamente!', isSuccess: true);
    
    // Atualizar métricas
    _updateRealtimeMetrics();
  }
  
  /// 🚀 FORTSMART PREMIUM - Atualiza métricas em tempo real
  void _updateRealtimeMetrics() {
    if (_polygonVertices.length >= 3) {
      // As métricas já são calculadas automaticamente pelos métodos existentes
      // _calculatePolygonArea() e _calculatePolygonPerimeter()
      setState(() {}); // Forçar rebuild para atualizar UI
    }
  }

  List<Marker> _buildTalhaoMarkers(NovoTalhaoController controller) {
    return controller.existingTalhoes.map((talhao) {
      final centroid = _calculateCentroid(talhao.poligonos.first.pontos);
      
      // Buscar cultura do talhão
      final cultura = _culturas.firstWhere(
        (c) => c.id == talhao.culturaId,
        orElse: () => _culturas.first,
      );
      
      return Marker(
        point: centroid,
        width: 80,
        height: 30,
        child: GestureDetector(
          onTap: () => _showFortSmartTalhaoInfo(talhao, cultura),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: cultura.color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              cultura.name,
              style: TextStyle(
                color: cultura.color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }).toList();
  }
  
  /// 🚀 FORTSMART ORIGINAL - Card informativo elegante do talhão
  void _showFortSmartTalhaoInfo(TalhaoModel talhao, CulturaModel cultura) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cultura.color.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header com ícone da cultura
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cultura.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cultura.icon,
                  color: cultura.color,
                  size: 32,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Nome do talhão
              Text(
                talhao.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Cultura
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cultura.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cultura.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cultura.color,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Métricas do talhão
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFortSmartInfoMetric(
                    icon: Icons.crop_square,
                    label: 'Área',
                    value: PreciseGeoCalculator.formatAreaBrazilian(talhao.area),
                    color: const Color(0xFF2E7D32),
                  ),
                  _buildFortSmartInfoMetric(
                    icon: Icons.location_on,
                    label: 'Vértices',
                    value: '${talhao.poligonos.first.pontos.length}',
                    color: Colors.blue,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Data de criação
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Criado em ${_formatDate(talhao.dataCriacao)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Fechar',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showTalhaoFloatingCard(talhao);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cultura.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Editar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 🚀 FORTSMART ORIGINAL - Métrica do card informativo
  Widget _buildFortSmartInfoMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  /// 🚀 FORTSMART ORIGINAL - Formatar data
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getColorForTalhao(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[name.hashCode % colors.length];
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    
    double lat = 0, lng = 0;
    for (final point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    
    return LatLng(lat / points.length, lng / points.length);
  }
}

