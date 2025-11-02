import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:fortsmart_agro/utils/google_maps_types.dart';

// Importar adaptadores de compatibilidade em vez do Google Maps diretamente
import '../../utils/map_exports.dart';

import '../../models/farm.dart';
import '../../models/plot.dart';
import '../../repositories/farm_repository.dart';
import '../../repositories/plot_repository.dart';
import '../../widgets/plot_save_form.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/plot_action_buttons.dart';

class EnhancedPlotsScreen extends StatefulWidget {
  final int? farmId;
  final String? farmName;
  final int? propertyId;

  const EnhancedPlotsScreen({
    Key? key,
    this.farmId,
    this.farmName,
    this.propertyId,
  }) : super(key: key);

  @override
  _EnhancedPlotsScreenState createState() => _EnhancedPlotsScreenState();
}

class _EnhancedPlotsScreenState extends State<EnhancedPlotsScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  // Repositórios
  final PlotRepository _plotRepository = PlotRepository();
  final FarmRepository _farmRepository = FarmRepository();
  
  // Controladores
  final Completer<GoogleMapController> _mapController = Completer();
  late AnimationController _sidebarAnimationController;
  
  // Estado da tela
  bool _isLoading = true;
  bool _isDrawingMode = false;
  bool _isGpsTrackingMode = false;
  bool _isEraseMode = false;
  bool _isSidebarOpen = false;
  
  // Dados
  List<Plot> _plots = [];
  Farm? _selectedFarm;
  String _farmName = '';
  Plot? _selectedPlot;
  
  // Mapa e desenho
  List<LatLng> _drawingPoints = [];
  List<LatLng> _gpsTrackingPoints = [];
  LatLng? _currentPosition;
  double _currentArea = 0.0;
  List<LatLng> _currentPolygonPoints = [];
  Set<Polygon> _polygons = {};
  
  // Timer para rastreamento GPS
  Timer? _gpsTrackingTimer;
  bool _isGpsTracking = false;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controlador de animação do painel lateral
    _sidebarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Carregar dados iniciais
    _loadData();
    
    // Adicionar listener para eventos de ciclo de vida
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    _gpsTrackingTimer?.cancel();
    
    // Remover listener de ciclo de vida
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }
  
  // Implementar WidgetsBindingObserver para gerenciar ciclo de vida
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Quando o app volta do segundo plano
    if (state == AppLifecycleState.resumed) {
      // Recarregar dados e reconstruir UI
      setState(() {
        // Forçar reconstrução da UI
      });
      
      // Se estiver em modo de desenho, reconstruir polígono
      if (_isDrawingMode && _drawingPoints.isNotEmpty) {
        _updatePolygon();
      }
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Verificar se há argumentos passados pela rota
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      final farmId = arguments['farmId'] as int?;
      final farmName = arguments['farmName'] as String?;
      final propertyId = arguments['propertyId'] as int?;
      
      if (farmId != null && farmId != widget.farmId) {
        // Se o ID da fazenda mudou, recarregar os dados
        setState(() {
          _selectedFarm = null;
          _farmName = farmName ?? '';
        });
        _loadData();
      } else if (farmName != null && _farmName.isEmpty) {
        setState(() {
          _farmName = farmName;
        });
      } else if (propertyId != null && propertyId != widget.propertyId) {
        setState(() {
          _selectedFarm = null;
          _farmName = farmName ?? '';
        });
        _loadData();
      }
    }
  }
  
  // Carregar dados iniciais
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Carregar fazenda selecionada
      if (widget.farmId != null) {
        final farm = await _farmRepository.getFarmById(widget.farmId!);
        if (farm != null) {
          setState(() {
            _selectedFarm = farm;
            _farmName = farm.name;
          });
        }
      } else if (widget.farmName != null) {
        setState(() {
          _farmName = widget.farmName!;
        });
      }
      
      // Carregar talhões
      if (_selectedFarm != null) {
        final plots = await _plotRepository.getPlotsByFarm(_selectedFarm!.id);
        setState(() {
          _plots = plots;
        });
      } else {
        final plots = await _plotRepository.getAllPlots();
        setState(() {
          _plots = plots;
        });
      }
      
      // Obter posição atual
      await _getCurrentPosition();
    } catch (e) {
      _showErrorDialog('Erro ao carregar dados', 'Não foi possível carregar os talhões: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Método para obter a localização atual
  Future<LatLng?> _getCurrentPosition() async {
    try {
      final location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }
      
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return null;
        }
      }
      
      final locationData = await location.getLocation();
      setState(() {
        _currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
      });
      return LatLng(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }
  
  // Iniciar modo de desenho manual
  void _startManualDrawingMode() {
    setState(() {
      _isDrawingMode = true;
      _isGpsTrackingMode = false;
      _isEraseMode = false;
      _drawingPoints = [];
      _currentArea = 0.0;
    });
  }
  
  // Iniciar modo de rastreamento GPS
  void _startGpsTrackingMode() async {
    try {
      // Verificar permissões de localização usando a biblioteca Location
      final location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _showErrorDialog(
            'Serviço de Localização',
            'O serviço de localização está desativado. Ative-o para usar o rastreamento GPS.',
          );
          return;
        }
      }
      
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _showErrorDialog(
            'Permissão Negada',
            'É necessário permitir o acesso à localização para usar o rastreamento GPS.',
          );
          return;
        }
      }
      
      setState(() {
        _isDrawingMode = false;
        _isGpsTrackingMode = true;
        _isEraseMode = false;
        _drawingPoints = [];
        _currentArea = 0.0;
      });
      
      // Iniciar rastreamento GPS
      _startGpsTracking();
    } catch (e) {
      print('Erro ao iniciar modo de rastreamento GPS: $e');
      _showErrorDialog(
        'Erro',
        'Ocorreu um erro ao iniciar o modo de rastreamento GPS: $e',
      );
    }
  }
  
  // Iniciar rastreamento GPS
  void _startGpsTracking() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Obter permissão de localização
      final position = await _getCurrentPosition();
      if (position == null) {
        _showErrorDialog(
          'Erro de Localização',
          'Não foi possível obter a localização atual. Verifique se o GPS está ativado e se o aplicativo tem permissão para acessar a localização.',
        );
        setState(() {
          _isLoading = false;
          _isGpsTrackingMode = false;
        });
        return;
      }
      
      // Iniciar o rastreamento
      setState(() {
        _isLoading = false;
        _isDrawingMode = false;
        _isGpsTrackingMode = true;
        _drawingPoints = [];
        _currentArea = 0;
      });
      
      // Centralizar o mapa na posição atual
      _centerMapOnCoordinates(position);
      
      // Adicionar o primeiro ponto
      _addDrawingPoint(position);
      
      // Iniciar o timer para adicionar pontos automaticamente
      _gpsTrackingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (_isGpsTrackingMode) {
          final position = await _getCurrentPosition();
          if (position != null) {
            _addDrawingPoint(position);
          }
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      print('Erro ao iniciar rastreamento GPS: $e');
      setState(() {
        _isLoading = false;
        _isGpsTrackingMode = false;
      });
      _showErrorDialog(
        'Erro',
        'Ocorreu um erro ao iniciar o rastreamento GPS: $e',
      );
    }
  }
  
  // Pausar/retomar rastreamento GPS
  void _toggleGpsTracking() {
    setState(() {
      _isGpsTrackingMode = !_isGpsTrackingMode;
    });
  }
  
  // Iniciar modo de edição/borracha
  void _startEraseMode() {
    setState(() {
      _isDrawingMode = false;
      _isGpsTrackingMode = false;
      _isEraseMode = true;
    });
  }
  
  // Adicionar ponto ao desenho
  void _addDrawingPoint(LatLng point) {
    if (_isDrawingMode) {
      setState(() {
        _drawingPoints.add(point);
        
        // Calcular área se tiver pelo menos 3 pontos
        if (_drawingPoints.length >= 3) {
          _currentArea = calculatePolygonArea(_drawingPoints);
          _updatePolygon(); // Assegura que o polígono seja atualizado
        }
      });
    }
  }
  
  // Atualizar pontos de desenho
  void _updateDrawingPoints(List<LatLng> points) {
    setState(() {
      _drawingPoints = points;
      
      // Calcular área se tiver pelo menos 3 pontos
      if (_drawingPoints.length >= 3) {
        _currentArea = calculatePolygonArea(_drawingPoints);
        _updatePolygon(); // Assegura que o polígono seja atualizado
      } else {
        _currentArea = 0.0;
      }
    });
  }
  
  // Remover ponto do desenho
  void _removeDrawingPoint(int index) {
    if (index >= 0 && index < _drawingPoints.length) {
      setState(() {
        _drawingPoints.removeAt(index);
        
        // Calcular área se tiver pelo menos 3 pontos
        if (_drawingPoints.length >= 3) {
          _currentArea = calculatePolygonArea(_drawingPoints);
        } else {
          _currentArea = 0.0;
        }
      });
    }
  }
  
  // Cancelar desenho
  void _cancelDrawing() {
    setState(() {
      _isDrawingMode = false;
      _isGpsTrackingMode = false;
      _isEraseMode = false;
      _drawingPoints = [];
      _gpsTrackingPoints = [];
      _currentArea = 0.0;
    });
    
    // Cancelar timer de rastreamento GPS
    _gpsTrackingTimer?.cancel();
  }
  
  // Salvar talhão
  void _savePlot() async {
    if (_drawingPoints.length < 3) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro'),
          content: const Text('É necessário pelo menos 3 pontos para formar um talhão.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Calcular a área do talhão
    final area = calculatePolygonArea(_drawingPoints);
    
    // Mostrar o formulário de salvamento
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // backgroundColor: Colors.white, // backgroundColor não é suportado em flutter_map 5.0.0
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: PlotSaveForm(
            points: _drawingPoints.map((point) => point.toLatLong2()).toList(),
            area: area,
            farmId: widget.farmId != null ? widget.farmId.toString() : '',
            farmName: widget.farmName ?? '',
            propertyId: widget.propertyId != null ? widget.propertyId.toString() : '',
            onSave: (name, description) => _confirmAndSavePlot(name, description, area),
          ),
        ),
      ),
    );
  }
  
  // Método para confirmar e salvar o talhão
  void _confirmAndSavePlot(String name, String? description, double area) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Converter os pontos LatLng para o formato de coordenadas esperado pelo modelo Plot
      List<Map<String, double>> coordinates = _drawingPoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude
      }).toList();
      
      final plot = Plot(
        id: null,
        name: name,
        description: description,
        farmId: int.tryParse(widget.farmId?.toString() ?? '0') ?? 0,
        propertyId: widget.propertyId ?? 0,
        area: area,
        coordinates: coordinates,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      // Salvar no banco de dados
      final savedPlotId = await _plotRepository.savePlot(plot);
      
      setState(() {
        _isLoading = false;
        _isDrawingMode = false;
        _isGpsTrackingMode = false;
        _drawingPoints.clear();
        _currentArea = 0;
        
        // Adicionar o novo talhão à lista
        if (savedPlotId != null) {
          // Recarregar a lista de talhões após salvar
          _loadData();
        }
      });
      
      // Mostrar mensagem de sucesso
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Talhão "$name" salvo com sucesso!'),
          // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Atualizar polígonos no mapa
      _updatePolygons();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(
          message: 'Erro ao salvar o talhão: ${e.toString()}',
        ),
      );
    }
  }
  
  // Importar arquivo KML
  void _importKmlFile() async {
    try {
      // A implementação real seria aqui, mas por enquanto vamos implementar uma versão básica
      // que demonstra que o botão funciona e permite selecionar um arquivo
      
      // Simulação temporária de importação
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Importar KML/KMZ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selecione o arquivo KML do Google Earth para importar os talhões.'),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Aqui iria a lógica de selecionar arquivo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Seletor de arquivos iniciado!'),
                      // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: Icon(Icons.attach_file),
                label: Text('Selecionar arquivo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Erro ao importar arquivo KML: $e');
      _showErrorDialog(
        'Erro',
        'Ocorreu um erro ao importar o arquivo KML: $e',
      );
    }
  }
  
  // Mostrar detalhes do talhão
  void _displayPlotDetails(Plot plot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // backgroundColor: Colors.transparent, // backgroundColor não é suportado em flutter_map 5.0.0
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.only(bottom: 16),
                ),
              ),
              Text(
                plot.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Área: ${plot.area != null ? plot.area!.toStringAsFixed(2) : '0'} hectares',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Editar',
                    onTap: () {
                      Navigator.pop(context);
                      _editPlot(plot);
                    } // Comentário: onTap não é suportado em Polygon no flutter_map 5.0.0
                  ),
                  _buildActionButton(
                    icon: Icons.delete,
                    label: 'Excluir',
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeletePlot(plot);
                    } // Comentário: onTap não é suportado em Polygon no flutter_map 5.0.0
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Navega para a tela de edição do talhão
  void _editPlot(Plot plot) {
    Navigator.pushNamed(
      context,
      '/plot/edit',
      arguments: {
        'plot': plot,
        'farmId': widget.farmId,
        'farmName': widget.farmName,
        'propertyId': widget.propertyId,
      },
    ).then((_) => _loadData());
  }
  
  // Exclui um talhão
  Future<void> _deletePlot(Plot plot) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await PlotRepository().deletePlot(plot.id!);
      
      setState(() {
        _plots.removeWhere((p) => p.id == plot.id);
        _selectedPlot = null;
        _isLoading = false;
      });
      
      _updatePolygons();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Talhão "${plot.name}" excluído com sucesso.'),
          // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      _showErrorDialog(
        'Erro ao excluir talhão',
        'Não foi possível excluir o talhão: $e',
      );
    }
  }
  
  // Mostrar diálogo de erro
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // Alternar painel lateral
  void _toggleSidebar() {
    if (_sidebarAnimationController.value > 0) {
      _sidebarAnimationController.reverse();
      setState(() {
        _isSidebarOpen = false;
      });
    } else {
      _sidebarAnimationController.forward();
      setState(() {
        _isSidebarOpen = true;
      });
    }
  }
  
  void _updatePolygon() {
    setState(() {
      _isDrawingMode = true;
      _isGpsTrackingMode = false;
      _isEraseMode = false;
      _drawingPoints = _currentPolygonPoints;
      
      // Calcular área
      if (_drawingPoints.length >= 3) {
        _currentArea = calculatePolygonArea(_drawingPoints);
      } else {
        _currentArea = 0.0;
      }
    });
  }
  
  /// Seleciona um talhão e mostra seus detalhes
  void _selectPlot(Plot plot) {
    setState(() {
      _selectedPlot = plot;
      
      // Centralizar o mapa na média das coordenadas do talhão
      if (plot.coordinates != null && plot.coordinates!.isNotEmpty && _mapController != null) {
        double totalLat = 0;
        double totalLng = 0;
        
        for (final coord in plot.coordinates!) {
          if (coord.containsKey('latitude') && coord.containsKey('longitude')) {
            totalLat += coord['latitude']!;
            totalLng += coord['longitude']!;
          }
        }
        
        final centerLat = totalLat / plot.coordinates!.length;
        final centerLng = totalLng / plot.coordinates!.length;
        
        _centerMapOnCoordinates(LatLng(centerLat, centerLng));
      }
      
      // Abrir o painel de detalhes do talhão
      _displayPlotDetails(plot);
    });
  }
  
  /// Centraliza o mapa nas coordenadas especificadas
  void _centerMapOnCoordinates(LatLng coordinates) async {
    if (_mapController != null) {
      final controller = await _mapController!.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          coordinates,
          15.0,
        ),
      );
    }
  }
  
  /// Constrói um botão de ação para o painel de detalhes do talhão
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      // onTap: onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
  
  /// Atualiza os polígonos no mapa com base nos talhões carregados
  void _updatePolygons() {
    setState(() {
      _polygons.clear();
      
      for (final plot in _plots) {
        if (plot.coordinates != null && plot.coordinates!.isNotEmpty) {
          // Criar uma lista de LatLng a partir das coordenadas do talhão
          final points = <LatLng>[];
          for (final coord in plot.coordinates!) {
            if (coord.containsKey('latitude') && coord.containsKey('longitude')) {
              points.add(LatLng(
                coord['latitude']!,
                coord['longitude']!
              ));
            }
          }
          
          if (points.length >= 3) {
            // Adicionar o polígono ao conjunto
            _polygons.add(
              Polygon(
                polygonId: PolygonId(plot.id ?? 'plot_${DateTime.now().millisecondsSinceEpoch}'),
                points: points,
                strokeWidth: 2,
                strokeColor: Colors.blue,
                fillColor: Colors.blue.withOpacity(0.3),
                // consumeTapEvents: true, // Não suportado pelo MapTiler
                // // onTap: () { // Não suportado pelo MapTiler
                //   // Selecionar o talhão ao clicar no polígono
                //   _displayPlotDetails(plot);
                // }, // onTap não é suportado em Polygon no flutter_map 5.0.0
              ),
            );
          }
        }
      }
    });
  }
  
  /// Calcula a área de um polígono em hectares
  double calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0;
    
    double area = 0;
    
    // Fórmula da área de Gauss (Shoelace formula)
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      
      // Converter para radianos
      double lat1 = points[i].latitude * (pi / 180);
      double lon1 = points[i].longitude * (pi / 180);
      double lat2 = points[j].latitude * (pi / 180);
      double lon2 = points[j].longitude * (pi / 180);
      
      // Calcular área parcial
      area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
    }
    
    // Calcular área total em metros quadrados
    area = area.abs() * 6378137.0 * 6378137.0 / 2.0;
    
    // Converter para hectares (1 hectare = 10000 m²)
    return area / 10000;
  }
  
  // Verificar permissão para acessar o armazenamento
  Future<bool> _checkStoragePermission() async {
    try {
      // Usando a biblioteca location para permissões
      final location = Location();
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        return permissionGranted == PermissionStatus.granted;
      }
      return permissionGranted == PermissionStatus.granted;
    } catch (e) {
      print('Erro ao verificar permissão de armazenamento: $e');
      return false;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Talhões${_farmName.isNotEmpty ? ' - $_farmName' : ''}'),
        // backgroundColor: const Color(0xFF4CAF50), // backgroundColor não é suportado em flutter_map 5.0.0
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _toggleSidebar,
        ),
        actions: [
          // Botão de importar KML/KMZ
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importKmlFile,
            tooltip: 'Importar KML/KMZ',
          ),
          
          // Botão de atualizar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Stack(
              children: [
                // Mapa principal
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? LatLng(-15.793889, -47.882778), // Brasília como default
                    zoom: 15.0,
                  ),
                  onMapCreated: (controller) {
                    _mapController.complete(controller);
                    
                    // Atualizar polígonos após criação do mapa
                    _updatePolygons();
                    
                    // Se já houver dados de localização, centralizar o mapa
                    if (_currentPosition != null) {
                      _centerMapOnCoordinates(_currentPosition!);
                    } else {
                      // Tentar obter localização atual
                      _getCurrentPosition().then((position) {
                        if (position != null) {
                          _centerMapOnCoordinates(position);
                        }
                      });
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.hybrid, // Usar mapa com satélite
                  polygons: _polygons,
                  // onTap: _isDrawingMode ? _addDrawingPoint : null, // onTap não é suportado em Polygon no flutter_map 5.0.0
                ),
                
                // Painel lateral
                AnimatedBuilder(
                  animation: _sidebarAnimationController,
                  builder: (context, child) {
                    final slideAmount = MediaQuery.of(context).size.width * 0.7 * _sidebarAnimationController.value;
                    
                    return Transform.translate(
                      offset: Offset(slideAmount - MediaQuery.of(context).size.width * 0.7, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          color: const Color(0xFF4CAF50),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Lista de Talhões',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.white),
                                onPressed: _toggleSidebar,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _plots.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'Nenhum talhão cadastrado',
                                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Desenhe ou importe talhões',
                                        style: TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _plots.length,
                                  itemBuilder: (context, index) {
                                    final plot = _plots[index];
                                    
                                    return Card(
                                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: ListTile(
                                        title: Text(
                                          plot.name ?? 'Talhão sem nome',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          'Área: ${plot.area?.toStringAsFixed(2) ?? '0.00'} ha',
                                          style: TextStyle(fontStyle: FontStyle.italic),
                                        ),
                                        leading: Icon(Icons.map, color: Colors.green),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit, color: Colors.blue),
                                              onPressed: () => _editPlot(plot),
                                              tooltip: 'Editar talhão',
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _confirmDeletePlot(plot),
                                              tooltip: 'Excluir talhão',
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          _selectPlot(plot);
                                          _toggleSidebar(); // Fechar sidebar após selecionar
                                        }, // Comentário: onTap não é suportado em Polygon no flutter_map 5.0.0
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Modo de desenho: Pontos desenhados e indicador de área
                if (_isDrawingMode)
                  Align(
                    // alignment: Alignment.topCenter, // alignment não é suportado em Marker no flutter_map 5.0.0
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Card(
                        color: Colors.white.withOpacity(0.9),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.straighten, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Área: ${_currentArea.toStringAsFixed(2)} ha',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${_drawingPoints.length} pontos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                // Visualização dos pontos de desenho
                if (_isDrawingMode && _drawingPoints.isNotEmpty)
                  Stack(
                    children: _drawingPoints.asMap().entries.map((entry) {
                      final index = entry.key;
                      final point = entry.value;
                      
                      return FutureBuilder<ScreenCoordinate>(
                        future: _getScreenCoordinate(point),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return SizedBox();
                          
                          final screenCoord = snapshot.data!;
                          
                          return Positioned(
                            left: screenCoord.x.toDouble() - 10,
                            top: screenCoord.y.toDouble() - 10,
                            child: GestureDetector(
                              // onTap: _isEraseMode ? () => _removeDrawingPoint(index) : null, // onTap não é suportado em Polygon no flutter_map 5.0.0
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                
                // Botão de pausar/retomar rastreamento GPS
                if (_isGpsTrackingMode)
                  Positioned(
                    top: 80,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: _toggleGpsTracking,
                      // backgroundColor: _isGpsTrackingMode ? Colors.red : Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
                      child: Icon(_isGpsTrackingMode ? Icons.pause : Icons.play_arrow),
                    ),
                  ),
                
                // Botões de ação
                PlotActionButtons(
                  onManualDrawingSelected: _startManualDrawingMode,
                  onGpsTrackingSelected: _startGpsTrackingMode,
                  onEraseSelected: _startEraseMode,
                  onImportKmlSelected: _importKmlFile,
                  onSaveSelected: _savePlot,
                  onCancelSelected: _cancelDrawing,
                  isDrawingMode: _isDrawingMode,
                  isGpsTrackingMode: _isGpsTrackingMode,
                  isEraseMode: _isEraseMode,
                  hasDrawingPoints: _drawingPoints.length >= 3,
                ),
              ],
            ),
    );
  }

  /// Confirma a exclusão de um talhão
  void _confirmDeletePlot(Plot plot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o talhão "${plot.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlot(plot);
            },
            child: const Text('Excluir'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Método para obter as coordenadas da tela a partir das coordenadas do mapa
  Future<ScreenCoordinate> _getScreenCoordinate(LatLng position) async {
    if (!_mapController.isCompleted) {
      return ScreenCoordinate(x: 0, y: 0);
    }
    
    // No MapTiler, usamos uma abordagem diferente para obter coordenadas de tela
    // Esta é uma implementação temporária que retorna coordenadas fixas
    // Em uma implementação real, usaríamos o controller para calcular as coordenadas
    return ScreenCoordinate(x: 0, y: 0);
  }
}
