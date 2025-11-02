import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/experimento_completo_model.dart';
import '../../services/experimento_service.dart';
import '../../services/precise_area_calculator_v2.dart';
import '../../widgets/app_bar_widget.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/responsive_utils.dart';

/// Tela de criar subárea com mapa full screen - estrutura leve e funcional
class CriarSubareaFullscreenScreen extends StatefulWidget {
  final String experimentoId;
  final String talhaoId;
  final List<LatLng>? talhaoPontos; // Pontos do talhão para centralizar o mapa

  const CriarSubareaFullscreenScreen({
    Key? key,
    required this.experimentoId,
    required this.talhaoId,
    this.talhaoPontos,
  }) : super(key: key);

  @override
  State<CriarSubareaFullscreenScreen> createState() => _CriarSubareaFullscreenScreenState();
}

class _CriarSubareaFullscreenScreenState extends State<CriarSubareaFullscreenScreen>
    with TickerProviderStateMixin {
  final ExperimentoService _experimentoService = ExperimentoService();
  final _nomeController = TextEditingController();
  final _observacoesController = TextEditingController();

  // Estado do mapa e desenho
  final MapController _mapController = MapController();
  List<LatLng> _pontosDesenho = [];
  bool _desenhando = false;
  bool _poligonoCompleto = false;
  double _areaCalculada = 0.0;
  double _perimetroCalculado = 0.0;

  // Estado do formulário
  bool _isLoading = false;
  String _tipoSelecionado = TipoExperimento.sementes;
  Color _corSelecionada = PaletaCoresSubareas.cores.first;
  DateTime _dataCriacao = DateTime.now();

  // Estado do GPS
  bool _isTrackingGPS = false;
  List<LatLng> _pontosGPS = [];
  StreamSubscription<Position>? _gpsSubscription;

  // Cores disponíveis
  final List<Color> _coresDisponiveis = PaletaCoresSubareas.cores;

  // Animação do FAB
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _fabExpanded = false;

  // Coordenadas padrão (Vitória, ES)
  static const LatLng _defaultCenter = LatLng(-20.3155, -40.3128);

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _centralizarNoTalhao();
    _carregarCoresDisponiveis();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _observacoesController.dispose();
    _mapController.dispose();
    _fabAnimationController.dispose();
    _gpsSubscription?.cancel();
    super.dispose();
  }

  void _centralizarNoTalhao() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.talhaoPontos != null && widget.talhaoPontos!.isNotEmpty) {
        _centralizarMapa(widget.talhaoPontos!);
      } else {
        _mapController.move(_defaultCenter, 15);
      }
    });
  }

  void _centralizarMapa(List<LatLng> pontos) {
    if (pontos.isEmpty) return;

    double minLat = pontos.first.latitude;
    double maxLat = pontos.first.latitude;
    double minLng = pontos.first.longitude;
    double maxLng = pontos.first.longitude;

    for (final ponto in pontos) {
      minLat = minLat < ponto.latitude ? minLat : ponto.latitude;
      maxLat = maxLat > ponto.latitude ? maxLat : ponto.latitude;
      minLng = minLng < ponto.longitude ? minLng : ponto.longitude;
      maxLng = maxLng > ponto.longitude ? maxLng : ponto.longitude;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    _mapController.move(LatLng(centerLat, centerLng), 16);
  }

  Future<void> _carregarCoresDisponiveis() async {
    try {
      final experimento = await _experimentoService.buscarExperimentoPorId(widget.experimentoId);
      if (experimento != null) {
        final coresUsadas = experimento.subareas.map((s) => s.cor.value).toSet();
        final coresDisponiveis = _coresDisponiveis.where((cor) => !coresUsadas.contains(cor.value)).toList();
        
        if (coresDisponiveis.isNotEmpty) {
          setState(() {
            _corSelecionada = coresDisponiveis.first;
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar cores disponíveis: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mapa em tela cheia
          _buildMapa(),
          
          // Overlay de informações da área (se desenhando)
          if (_pontosDesenho.isNotEmpty)
            _buildAreaOverlay(),
          
          // FAB Group para ações de desenho
          _buildFABGroup(),
          
          // Painel inferior (BottomSheet)
          if (_poligonoCompleto)
            _buildBottomSheet(),
          
          // Botões de controle do mapa
          _buildMapControls(),
        ],
      ),
    );
  }

  Widget _buildMapa() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.talhaoPontos?.isNotEmpty == true 
            ? widget.talhaoPontos!.first 
            : _defaultCenter,
        initialZoom: 15,
        maxZoom: 18,
        minZoom: 10,
        onTap: _onMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        
        // Polígono do talhão (se disponível)
        if (widget.talhaoPontos != null && widget.talhaoPontos!.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: widget.talhaoPontos!,
                color: Colors.blue.withOpacity(0.2),
                borderColor: Colors.blue,
                borderStrokeWidth: 2,
                isDotted: true,
              ),
            ],
          ),
        
        // Polígono sendo desenhado
        if (_pontosDesenho.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: _pontosDesenho,
                color: _corSelecionada.withOpacity(0.3),
                borderColor: _corSelecionada,
                borderStrokeWidth: 3,
                isFilled: _poligonoCompleto,
              ),
            ],
          ),
        
        // Marcadores dos pontos
        if (_pontosDesenho.isNotEmpty)
          MarkerLayer(
            markers: _pontosDesenho.asMap().entries.map((entry) {
              final index = entry.key;
              final ponto = entry.value;
              
              return Marker(
                point: ponto,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: _corSelecionada,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAreaOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _corSelecionada, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _corSelecionada,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Subárea ${_pontosDesenho.length} pontos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            if (_areaCalculada > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.crop_square, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Área: ${_areaCalculada < 1 ? "${(_areaCalculada * 10000).toStringAsFixed(0)} m²" : "${_areaCalculada.toStringAsFixed(3)} ha"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              if (_perimetroCalculado > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.straighten, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Perímetro: ${_perimetroCalculado.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
            
            if (_pontosDesenho.length >= 3 && !_poligonoCompleto) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Toque no primeiro ponto para fechar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFABGroup() {
    return Positioned(
      bottom: 120,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FABs secundários (animados)
          if (_fabExpanded) ...[
            _buildFAB(
              icon: Icons.gps_fixed,
              label: 'GPS',
              color: Colors.blue,
              onTap: _toggleGPSTracking,
              isActive: _isTrackingGPS,
            ),
            const SizedBox(height: 12),
            _buildFAB(
              icon: Icons.location_on,
              label: 'Ponto',
              color: Colors.green,
              onTap: _adicionarPonto,
            ),
            const SizedBox(height: 12),
          ],
          
          // FAB principal
          FloatingActionButton.extended(
            onPressed: _toggleFAB,
            backgroundColor: _fabExpanded ? Colors.red : Colors.blue,
            foregroundColor: Colors.white,
            icon: AnimatedRotation(
              turns: _fabExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(_fabExpanded ? Icons.close : Icons.add),
            ),
            label: Text(_fabExpanded ? 'Fechar' : 'Desenhar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: isActive ? color.withOpacity(0.7) : color,
      foregroundColor: Colors.white,
      child: Icon(icon),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Column(
        children: [
          // Botão centralizar
          FloatingActionButton.small(
            heroTag: 'center',
            onPressed: _centralizarNoTalhao,
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          // Botão limpar
          FloatingActionButton.small(
            heroTag: 'clear',
            onPressed: _limparDesenho,
            backgroundColor: Colors.white,
            foregroundColor: Colors.red,
            child: const Icon(Icons.clear),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Título
                const Text(
                  'Nova Subárea',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Nome
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Subárea *',
                    hintText: 'Ex: Teste Soja A',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Tipo
                DropdownButtonFormField<String>(
                  value: _tipoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo *',
                    border: OutlineInputBorder(),
                  ),
                  items: TipoExperimento.tipos.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Row(
                        children: [
                          Icon(TipoExperimento.getIcon(tipo), size: 20),
                          const SizedBox(width: 8),
                          Text(tipo),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tipoSelecionado = value!;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Cor
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cor da Subárea',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _coresDisponiveis.map((cor) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _corSelecionada = cor;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _corSelecionada == cor ? Colors.black : Colors.grey,
                                width: _corSelecionada == cor ? 3 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _corSelecionada == cor
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Data
                ListTile(
                  leading: Icon(Icons.calendar_today, color: Colors.orange[700]),
                  title: const Text('Data de Criação'),
                  subtitle: Text(
                    '${_dataCriacao.day.toString().padLeft(2, '0')}/${_dataCriacao.month.toString().padLeft(2, '0')}/${_dataCriacao.year}',
                  ),
                  onTap: _selecionarData,
                ),
                
                const SizedBox(height: 16),
                
                // Observações
                TextFormField(
                  controller: _observacoesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    hintText: 'Observações sobre a subárea...',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _limparDesenho,
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Limpar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _salvarSubarea,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save, size: 18),
                        label: Text(_isLoading ? 'Salvando...' : 'Salvar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_isTrackingGPS) return; // Não permitir toque durante rastreamento GPS

    setState(() {
      if (_pontosDesenho.length >= 3 && _pontosDesenho.isNotEmpty) {
        // Verificar se clicou próximo ao primeiro ponto (fechar polígono)
        final primeiroPonto = _pontosDesenho.first;
        final distancia = _calcularDistancia(point, primeiroPonto);
        
        if (distancia < 50) { // 50 metros de tolerância
          _poligonoCompleto = true;
          _desenhando = false;
          _calcularAreaEPerimetro();
        } else {
          _pontosDesenho.add(point);
          _calcularAreaEPerimetro();
        }
      } else {
        _pontosDesenho.add(point);
        _desenhando = true;
        if (_pontosDesenho.length >= 3) {
          _calcularAreaEPerimetro();
        }
      }
    });
  }

  void _calcularAreaEPerimetro() {
    if (_pontosDesenho.length < 3) {
      _areaCalculada = 0.0;
      _perimetroCalculado = 0.0;
      return;
    }

    // Usar o mesmo padrão do módulo de talhões
    _areaCalculada = PreciseAreaCalculatorV2.calculateManualDrawingArea(_pontosDesenho);
    _perimetroCalculado = _calcularPerimetro(_pontosDesenho);
  }

  double _calcularPerimetro(List<LatLng> pontos) {
    if (pontos.length < 2) return 0.0;

    double perimetro = 0.0;
    for (int i = 0; i < pontos.length; i++) {
      final j = (i + 1) % pontos.length;
      perimetro += _calcularDistancia(pontos[i], pontos[j]);
    }
    
    return perimetro;
  }

  double _calcularDistancia(LatLng ponto1, LatLng ponto2) {
    const double raioTerra = 6371000; // Raio da Terra em metros
    
    final lat1Rad = ponto1.latitude * pi / 180;
    final lat2Rad = ponto2.latitude * pi / 180;
    final deltaLatRad = (ponto2.latitude - ponto1.latitude) * pi / 180;
    final deltaLngRad = (ponto2.longitude - ponto1.longitude) * pi / 180;

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return raioTerra * c;
  }

  void _toggleFAB() {
    setState(() {
      _fabExpanded = !_fabExpanded;
    });

    if (_fabExpanded) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _toggleGPSTracking() {
    if (_isTrackingGPS) {
      _pararRastreamentoGPS();
    } else {
      _iniciarRastreamentoGPS();
    }
  }

  void _iniciarRastreamentoGPS() async {
    try {
      // Verificar permissões
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        SnackbarUtils.showErrorSnackBar(context, 'Serviços de localização desabilitados');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          SnackbarUtils.showErrorSnackBar(context, 'Permissão de localização negada');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        SnackbarUtils.showErrorSnackBar(context, 'Permissão de localização permanentemente negada');
        return;
      }

      setState(() {
        _isTrackingGPS = true;
        _pontosGPS.clear();
        _pontosDesenho.clear();
        _poligonoCompleto = false;
      });

      // Iniciar rastreamento GPS
      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // 5 metros
        ),
      ).listen((Position position) {
        final ponto = LatLng(position.latitude, position.longitude);
        
        setState(() {
          _pontosGPS.add(ponto);
          _pontosDesenho = List.from(_pontosGPS);
          
          if (_pontosDesenho.length >= 3) {
            _calcularAreaEPerimetro();
          }
        });
      });

      SnackbarUtils.showSuccessSnackBar(context, 'Rastreamento GPS iniciado');
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao iniciar GPS: $e');
      setState(() {
        _isTrackingGPS = false;
      });
    }
  }

  void _pararRastreamentoGPS() {
    _gpsSubscription?.cancel();
    setState(() {
      _isTrackingGPS = false;
      if (_pontosDesenho.length >= 3) {
        _poligonoCompleto = true;
        _calcularAreaEPerimetro();
      }
    });
    SnackbarUtils.showSuccessSnackBar(context, 'Rastreamento GPS finalizado');
  }

  void _adicionarPonto() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final ponto = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _pontosDesenho.add(ponto);
        if (_pontosDesenho.length >= 3) {
          _calcularAreaEPerimetro();
        }
      });
      
      SnackbarUtils.showSuccessSnackBar(context, 'Ponto adicionado');
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao obter localização: $e');
    }
  }

  void _limparDesenho() {
    setState(() {
      _pontosDesenho.clear();
      _pontosGPS.clear();
      _poligonoCompleto = false;
      _desenhando = false;
      _areaCalculada = 0.0;
      _perimetroCalculado = 0.0;
      _isTrackingGPS = false;
    });
    
    _gpsSubscription?.cancel();
    SnackbarUtils.showInfoSnackBar(context, 'Desenho limpo');
  }

  Future<void> _selecionarData() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _dataCriacao,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (result != null) {
      setState(() {
        _dataCriacao = result;
      });
    }
  }

  Future<void> _salvarSubarea() async {
    if (_pontosDesenho.length < 3) {
      SnackbarUtils.showErrorSnackBar(context, 'Desenhe pelo menos 3 pontos para formar um polígono');
      return;
    }

    if (_nomeController.text.trim().isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Nome da subárea é obrigatório');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _experimentoService.criarSubarea(
        experimentoId: widget.experimentoId,
        nome: _nomeController.text.trim(),
        tipo: _tipoSelecionado,
        pontos: _pontosDesenho,
        cor: _corSelecionada,
        observacoes: _observacoesController.text.trim().isEmpty 
            ? null 
            : _observacoesController.text.trim(),
      );

      SnackbarUtils.showSuccessSnackBar(context, 'Subárea criada com sucesso!');
      Navigator.of(context).pop(true);
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao criar subárea: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
