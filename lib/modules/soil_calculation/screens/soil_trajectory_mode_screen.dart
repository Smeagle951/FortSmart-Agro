import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../services/soil_gps_tracking_service.dart';
import '../services/soil_analysis_service.dart';
import '../services/soil_recommendation_service.dart';
import '../models/soil_compaction_point_model.dart';
import '../repositories/soil_compaction_point_repository.dart';
import '../constants/app_colors.dart';

/// Tela do Modo Trajeto de Avaliação com GPS ao vivo
class SoilTrajectoryModeScreen extends StatefulWidget {
  final int talhaoId;
  final String nomeTalhao;
  final List<LatLng> polygonCoordinates;

  const SoilTrajectoryModeScreen({
    Key? key,
    required this.talhaoId,
    required this.nomeTalhao,
    required this.polygonCoordinates,
  }) : super(key: key);

  @override
  State<SoilTrajectoryModeScreen> createState() => _SoilTrajectoryModeScreenState();
}

class _SoilTrajectoryModeScreenState extends State<SoilTrajectoryModeScreen> {
  final MapController _mapController = MapController();
  final SoilGpsTrackingService _gpsService = SoilGpsTrackingService();
  final SoilCompactionPointRepository _repository = SoilCompactionPointRepository();
  
  List<SoilCompactionPointModel> _pontosColetados = [];
  List<SoilCompactionPointModel> _pontosGerados = []; // Pontos gerados automaticamente
  List<LatLng> _trajetoria = [];
  bool _isTracking = false;
  bool _isConnectedBluetooth = false;
  Timer? _gpsTimer;
  String _status = 'Pronto para iniciar';
  double _distanciaTotal = 0.0;
  int _tempoDecorrido = 0;
  Timer? _timerTempo;
  bool _autoCollect = false;
  bool _mostrarPontosGerados = true;
  double _ultimaLatitude = 0.0;
  double _ultimaLongitude = 0.0;
  double _areaTalhao = 0.0;
  int _numeroPontosNecessarios = 0;
  String? _erroInicializacao;

  @override
  void initState() {
    super.initState();
    // Usa post-frame callback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarServicos();
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _timerTempo?.cancel();
    _gpsService.pararRastreamento();
    super.dispose();
  }

  Future<void> _inicializarServicos() async {
    try {
      setState(() {
        _status = 'Inicializando...';
      });
      
      // Valida coordenadas do polígono
      if (widget.polygonCoordinates.isEmpty) {
        throw Exception('Coordenadas do talhão não disponíveis');
      }
      
      // Calcula área do talhão e gera pontos
      await _calcularAreaEGerarPontos();
      
      setState(() {
        _status = 'GPS pronto - ${_numeroPontosNecessarios} pontos gerados';
        _erroInicializacao = null;
      });
    } catch (e, stackTrace) {
      print('Erro ao inicializar serviços: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _status = 'Erro ao inicializar: $e';
        _erroInicializacao = e.toString();
      });
    }
  }

  /// Calcula a área do talhão e gera pontos automaticamente
  Future<void> _calcularAreaEGerarPontos() async {
    try {
      // Calcula área do polígono usando fórmula de Shoelace
      _areaTalhao = _calcularAreaPoligono(widget.polygonCoordinates);
      
      // Calcula número de pontos necessários (1 ponto a cada 10 hectares)
      _numeroPontosNecessarios = (_areaTalhao / 10).ceil();
      
      // Gera pontos distribuídos uniformemente no polígono
      _pontosGerados = await _gerarPontosUniformemente(
        widget.polygonCoordinates,
        _numeroPontosNecessarios,
      );
      
      setState(() {});
    } catch (e) {
      print('Erro ao calcular área e gerar pontos: $e');
    }
  }

  /// Calcula área do polígono em hectares usando fórmula de Shoelace
  double _calcularAreaPoligono(List<LatLng> coords) {
    if (coords.length < 3) return 0.0;
    
    double area = 0.0;
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    for (int i = 0; i < coords.length; i++) {
      int j = (i + 1) % coords.length;
      area += coords[i].longitude * coords[j].latitude;
      area -= coords[j].longitude * coords[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converte de graus quadrados para metros quadrados
    // Aproximação: 1 grau ≈ 111,320 km
    area = area * (111320 * 111320);
    
    // Converte de metros quadrados para hectares
    return area / 10000;
  }

  /// Gera pontos distribuídos uniformemente dentro do polígono
  Future<List<SoilCompactionPointModel>> _gerarPontosUniformemente(
    List<LatLng> polygonCoords,
    int numeroPontos,
  ) async {
    final List<SoilCompactionPointModel> pontos = [];
    
    if (polygonCoords.isEmpty || numeroPontos <= 0) return pontos;
    
    // Calcula bounding box do polígono
    double minLat = polygonCoords.map((c) => c.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = polygonCoords.map((c) => c.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = polygonCoords.map((c) => c.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = polygonCoords.map((c) => c.longitude).reduce((a, b) => a > b ? a : b);
    
    int tentativas = 0;
    int maxTentativas = numeroPontos * 10; // Evita loop infinito
    
    while (pontos.length < numeroPontos && tentativas < maxTentativas) {
      tentativas++;
      
      // Gera ponto aleatório dentro do bounding box
      final lat = minLat + (maxLat - minLat) * math.Random().nextDouble();
      final lng = minLng + (maxLng - minLng) * math.Random().nextDouble();
      final ponto = LatLng(lat, lng);
      
      // Verifica se o ponto está dentro do polígono
      if (_pontoDentroPoligono(ponto, polygonCoords)) {
        final soilPoint = SoilCompactionPointModel(
          pointCode: 'AUTO-${pontos.length + 1}',
          talhaoId: widget.talhaoId,
          dataColeta: DateTime.now(),
          latitude: lat,
          longitude: lng,
          isAutoGenerated: true,
          profundidadeInicio: 0,
          profundidadeFim: 20,
          observacoes: 'Ponto gerado automaticamente - ${_areaTalhao.toStringAsFixed(2)} ha',
          amostraColetada: false,
        );
        
        pontos.add(soilPoint);
      }
    }
    
    return pontos;
  }

  /// Verifica se um ponto está dentro do polígono usando Ray Casting
  bool _pontoDentroPoligono(LatLng ponto, List<LatLng> polygon) {
    bool dentro = false;
    int j = polygon.length - 1;
    
    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > ponto.latitude) != (polygon[j].latitude > ponto.latitude)) &&
          (ponto.longitude < (polygon[j].longitude - polygon[i].longitude) * 
           (ponto.latitude - polygon[i].latitude) / 
           (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        dentro = !dentro;
      }
      j = i;
    }
    
    return dentro;
  }

  Future<void> _iniciarTracking() async {
    if (_isTracking) return;

    try {
      final sucesso = await _gpsService.iniciarRastreamento();
      
      if (sucesso) {
        setState(() {
          _isTracking = true;
          _status = 'Rastreamento ativo';
        });

        // Timer para atualizar posição a cada 5 segundos
        _gpsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          _atualizarPosicao();
        });

        // Timer para contagem de tempo
        _timerTempo = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _tempoDecorrido++;
          });
        });
      } else {
        setState(() {
          _status = 'Falha ao iniciar rastreamento';
        });
      }

    } catch (e) {
      setState(() {
        _status = 'Erro ao iniciar rastreamento: $e';
      });
    }
  }

  Future<void> _pararTracking() async {
    if (!_isTracking) return;

    _gpsTimer?.cancel();
    _timerTempo?.cancel();
    _gpsService.pararRastreamento();
    
    setState(() {
      _isTracking = false;
      _status = 'Rastreamento parado';
    });
  }

  Future<void> _atualizarPosicao() async {
    final posicao = _gpsService.currentPosition;
    if (posicao != null) {
      final latLng = LatLng(posicao.latitude, posicao.longitude);
      
      // Calcula distância desde a última posição
      if (_ultimaLatitude != 0.0 && _ultimaLongitude != 0.0) {
        final distancia = _calcularDistancia(
          _ultimaLatitude, _ultimaLongitude,
          posicao.latitude, posicao.longitude,
        );
        _distanciaTotal += distancia;
      }
      
      setState(() {
        _trajetoria.add(latLng);
        _ultimaLatitude = posicao.latitude;
        _ultimaLongitude = posicao.longitude;
        _status = 'Posição: ${posicao.latitude.toStringAsFixed(6)}, ${posicao.longitude.toStringAsFixed(6)}';
      });

      // Coleta automática se habilitada
      if (_autoCollect && _pontosGerados.isNotEmpty) {
        _verificarColetaAutomatica(posicao);
      }
    }
  }

  double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Verifica se deve coletar um ponto automaticamente baseado na proximidade
  void _verificarColetaAutomatica(Position posicao) {
    const double distanciaMinima = 50.0; // 50 metros de proximidade
    
    for (final pontoGerado in _pontosGerados) {
      // Verifica se já foi coletado
      if (_pontosColetados.any((p) => p.pointCode == pontoGerado.pointCode)) {
        continue;
      }
      
      // Calcula distância até o ponto gerado
      final distancia = _calcularDistancia(
        posicao.latitude, posicao.longitude,
        pontoGerado.latitude, pontoGerado.longitude,
      );
      
      // Se está próximo o suficiente, coleta automaticamente
      if (distancia <= distanciaMinima) {
        _adicionarPontoAutomatico(pontoGerado);
        break; // Coleta apenas um ponto por vez
      }
    }
  }

  Future<void> _adicionarPontoAutomatico(SoilCompactionPointModel pontoBase) async {
    try {
      // Cria uma cópia do ponto gerado com dados atualizados
      final ponto = SoilCompactionPointModel(
        pointCode: pontoBase.pointCode,
        talhaoId: pontoBase.talhaoId,
        dataColeta: DateTime.now(),
        latitude: pontoBase.latitude,
        longitude: pontoBase.longitude,
        isAutoGenerated: true,
        profundidadeInicio: pontoBase.profundidadeInicio,
        profundidadeFim: pontoBase.profundidadeFim,
        observacoes: 'Coleta automática - ${pontoBase.observacoes}',
        amostraColetada: false,
      );

      await _repository.insert(ponto);
      
      setState(() {
        _pontosColetados.add(ponto);
      });

      _mostrarSnackBar('Ponto ${ponto.pointCode} coletado automaticamente!', Colors.blue);
    } catch (e) {
      print('Erro ao coletar ponto automático: $e');
    }
  }

  Future<void> _adicionarPontoManual() async {
    final posicao = _gpsService.currentPosition;
    if (posicao == null) {
      _mostrarSnackBar('GPS não disponível', Colors.red);
      return;
    }

    // Mostra dialog para coletar dados do ponto
    final dados = await _mostrarDialogColetaPonto();
    if (dados == null) return;

    try {
      final ponto = SoilCompactionPointModel(
        pointCode: 'C-${_pontosColetados.length + 1}',
        talhaoId: widget.talhaoId,
        dataColeta: DateTime.now(),
        latitude: posicao.latitude,
        longitude: posicao.longitude,
        isAutoGenerated: false,
        profundidadeInicio: dados['profundidadeInicio'],
        profundidadeFim: dados['profundidadeFim'],
        penetrometria: dados['penetrometria'],
        umidade: dados['umidade'],
        textura: dados['textura'],
        estrutura: dados['estrutura'],
        observacoes: dados['observacoes'],
        amostraColetada: dados['amostraColetada'],
      );

      await _repository.insert(ponto);
      
      setState(() {
        _pontosColetados.add(ponto);
      });

      _mostrarSnackBar('Ponto coletado com sucesso!', Colors.green);
    } catch (e) {
      _mostrarSnackBar('Erro ao salvar ponto: $e', Colors.red);
    }
  }

  Future<Map<String, dynamic>?> _mostrarDialogColetaPonto() async {
    final profundidadeInicioController = TextEditingController(text: '0');
    final profundidadeFimController = TextEditingController(text: '20');
    final penetrometriaController = TextEditingController();
    final umidadeController = TextEditingController();
    final observacoesController = TextEditingController();
    
    String? texturaSelecionada = 'Franco';
    String? estruturaSelecionada = 'Boa';
    bool amostraColetada = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coletar Ponto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: profundidadeInicioController,
                      decoration: const InputDecoration(
                        labelText: 'Prof. Início (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: profundidadeFimController,
                      decoration: const InputDecoration(
                        labelText: 'Prof. Fim (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: penetrometriaController,
                decoration: const InputDecoration(
                  labelText: 'Penetrometria (MPa)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: umidadeController,
                decoration: const InputDecoration(
                  labelText: 'Umidade (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: texturaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Textura',
                  border: OutlineInputBorder(),
                ),
                items: ['Argiloso', 'Arenoso', 'Franco']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => texturaSelecionada = value,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: estruturaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Estrutura',
                  border: OutlineInputBorder(),
                ),
                items: ['Boa', 'Moderada', 'Ruim']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => estruturaSelecionada = value,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: observacoesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Amostra Coletada'),
                value: amostraColetada,
                onChanged: (value) => amostraColetada = value ?? false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'profundidadeInicio': double.tryParse(profundidadeInicioController.text) ?? 0.0,
                'profundidadeFim': double.tryParse(profundidadeFimController.text) ?? 20.0,
                'penetrometria': double.tryParse(penetrometriaController.text),
                'umidade': double.tryParse(umidadeController.text),
                'textura': texturaSelecionada,
                'estrutura': estruturaSelecionada,
                'observacoes': observacoesController.text,
                'amostraColetada': amostraColetada,
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mostra erro se houver problema na inicialização
    if (_erroInicializacao != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Modo Trajeto - ${widget.nomeTalhao}'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  'Erro ao Inicializar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _erroInicializacao!,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _erroInicializacao = null;
                    });
                    _inicializarServicos();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Modo Trajeto - ${widget.nomeTalhao}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isConnectedBluetooth ? Icons.bluetooth_connected : Icons.bluetooth),
            onPressed: _isConnectedBluetooth ? _desconectarBluetooth : _conectarBluetooth,
            tooltip: _isConnectedBluetooth ? 'Desconectar Penetrômetro' : 'Conectar Penetrômetro',
          ),
        ],
      ),
      body: Column(
        children: [
          // Painel de controle
          _buildControlPanel(),
          
          // Mapa
          Expanded(
            child: Stack(
              children: [
                // Mapa
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: widget.polygonCoordinates.isNotEmpty
                        ? _calcularCentroPoligono(widget.polygonCoordinates)
                        : LatLng(-23.5505, -46.6333),
                    zoom: 16,
                    maxZoom: 20,
                    minZoom: 10,
                  ),
                  children: [
                    // Mapa base
                    TileLayer(
                      urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                      subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                    ),
                    
                    // Polígono do talhão
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: widget.polygonCoordinates,
                          color: AppColors.primaryColor.withOpacity(0.3),
                          borderColor: AppColors.primaryColor,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    
                    // Trajetória
                    if (_trajetoria.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _trajetoria,
                            color: Colors.red,
                            strokeWidth: 3,
                          ),
                        ],
                      ),
                    
                    // Pontos gerados (se habilitado)
                    if (_mostrarPontosGerados)
                      MarkerLayer(
                        markers: _pontosGerados.map((ponto) => _criarMarkerPontoGerado(ponto)).toList(),
                      ),
                    
                    // Pontos coletados
                    MarkerLayer(
                      markers: _pontosColetados.map((ponto) => _criarMarkerPonto(ponto)).toList(),
                    ),
                    
                    // Posição atual
                    if (_gpsService.currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _gpsService.currentPosition!.latitude,
                              _gpsService.currentPosition!.longitude,
                            ),
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
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
                
                // Botão de ação flutuante
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: _adicionarPontoManual,
                    backgroundColor: AppColors.primaryColor,
                    icon: const Icon(Icons.add_location, color: Colors.white),
                    label: const Text(
                      'Coletar Ponto',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status
          Text(
            _status,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          // Botões de controle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isTracking ? _pararTracking : _iniciarTracking,
                icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                label: Text(_isTracking ? 'Parar' : 'Iniciar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTracking ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _limparDados,
                icon: const Icon(Icons.clear),
                label: const Text('Limpar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Estatísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Coletados', '${_pontosColetados.length}/${_numeroPontosNecessarios}'),
              _buildStatCard('Área', '${_areaTalhao.toStringAsFixed(1)} ha'),
              _buildStatCard('Distância', '${(_distanciaTotal / 1000).toStringAsFixed(2)} km'),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Tempo', _formatarTempo(_tempoDecorrido)),
              _buildStatCard('Pontos Gerados', _pontosGerados.length.toString()),
              _buildStatCard('Restantes', '${_numeroPontosNecessarios - _pontosColetados.length}'),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Controles adicionais
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SwitchListTile(
                title: const Text('Coleta Auto'),
                subtitle: const Text('Coletar pontos automaticamente'),
                value: _autoCollect,
                onChanged: (value) {
                  setState(() {
                    _autoCollect = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Mostrar Pontos'),
                subtitle: const Text('Exibir pontos gerados no mapa'),
                value: _mostrarPontosGerados,
                onChanged: (value) {
                  setState(() {
                    _mostrarPontosGerados = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _regenerarPontos,
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _exportarDados,
                icon: const Icon(Icons.download),
                label: const Text('Exportar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Marker _criarMarkerPonto(SoilCompactionPointModel ponto) {
    final cor = _getCorCompactacao(ponto.penetrometria);
    
    return Marker(
      point: LatLng(ponto.latitude, ponto.longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _mostrarDetalhesPonto(ponto),
        child: Container(
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Marker _criarMarkerPontoGerado(SoilCompactionPointModel ponto) {
    // Verifica se o ponto já foi coletado
    final jaColetado = _pontosColetados.any((p) => p.pointCode == ponto.pointCode);
    
    return Marker(
      point: LatLng(ponto.latitude, ponto.longitude),
      width: 30,
      height: 30,
      child: GestureDetector(
        onTap: () => _mostrarDetalhesPontoGerado(ponto),
        child: Container(
          decoration: BoxDecoration(
            color: jaColetado ? Colors.green : Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(
              color: jaColetado ? Colors.green.shade700 : Colors.blue.shade700, 
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            jaColetado ? Icons.check : Icons.place,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Color _getCorCompactacao(double? penetrometria) {
    if (penetrometria == null) return Colors.grey;
    
    if (penetrometria < 1.5) return Colors.green;
    if (penetrometria < 2.0) return Colors.yellow;
    if (penetrometria < 2.5) return Colors.orange;
    return Colors.red;
  }

  void _mostrarDetalhesPonto(SoilCompactionPointModel ponto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ponto ${ponto.pointCode}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coordenadas: ${ponto.latitude.toStringAsFixed(6)}, ${ponto.longitude.toStringAsFixed(6)}'),
            Text('Profundidade: ${ponto.profundidadeInicio}-${ponto.profundidadeFim} cm'),
            if (ponto.penetrometria != null)
              Text('Penetrometria: ${ponto.penetrometria!.toStringAsFixed(2)} MPa'),
            if (ponto.umidade != null)
              Text('Umidade: ${ponto.umidade!.toStringAsFixed(1)}%'),
            if (ponto.textura != null)
              Text('Textura: ${ponto.textura}'),
            if (ponto.estrutura != null)
              Text('Estrutura: ${ponto.estrutura}'),
            if (ponto.observacoes != null && ponto.observacoes!.isNotEmpty)
              Text('Observações: ${ponto.observacoes}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalhesPontoGerado(SoilCompactionPointModel ponto) {
    final jaColetado = _pontosColetados.any((p) => p.pointCode == ponto.pointCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ponto ${ponto.pointCode}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coordenadas: ${ponto.latitude.toStringAsFixed(6)}, ${ponto.longitude.toStringAsFixed(6)}'),
            Text('Profundidade: ${ponto.profundidadeInicio}-${ponto.profundidadeFim} cm'),
            Text('Status: ${jaColetado ? "Coletado" : "Pendente"}'),
            if (ponto.observacoes != null && ponto.observacoes!.isNotEmpty)
              Text('Observações: ${ponto.observacoes}'),
            const SizedBox(height: 8),
            Text(
              jaColetado 
                  ? 'Este ponto já foi coletado automaticamente.'
                  : 'Este ponto está aguardando coleta. Ative a coleta automática ou colete manualmente.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: jaColetado ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          if (!jaColetado)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _adicionarPontoAutomatico(ponto);
              },
              child: const Text('Coletar Agora'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _conectarBluetooth() {
    // TODO: Implementar conexão Bluetooth
    setState(() {
      _isConnectedBluetooth = true;
      _status = 'Penetrômetro conectado';
    });
    _mostrarSnackBar('Penetrômetro conectado!', Colors.green);
  }

  void _desconectarBluetooth() {
    setState(() {
      _isConnectedBluetooth = false;
      _status = 'Penetrômetro desconectado';
    });
    _mostrarSnackBar('Penetrômetro desconectado!', Colors.orange);
  }

  void _limparDados() {
    setState(() {
      _pontosColetados.clear();
      _pontosGerados.clear();
      _trajetoria.clear();
      _distanciaTotal = 0.0;
      _tempoDecorrido = 0;
      _ultimaLatitude = 0.0;
      _ultimaLongitude = 0.0;
      _areaTalhao = 0.0;
      _numeroPontosNecessarios = 0;
      _status = 'Dados limpos';
    });
    _mostrarSnackBar('Dados limpos!', Colors.blue);
  }

  String _formatarTempo(int segundos) {
    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;
    final segs = segundos % 60;
    
    if (horas > 0) {
      return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
    } else {
      return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _exportarDados() async {
    try {
      // TODO: Implementar exportação de dados
      _mostrarSnackBar('Exportação em desenvolvimento', Colors.orange);
    } catch (e) {
      _mostrarSnackBar('Erro ao exportar dados: $e', Colors.red);
    }
  }

  Future<void> _regenerarPontos() async {
    try {
      setState(() {
        _pontosGerados.clear();
        _pontosColetados.clear();
        _status = 'Regenerando pontos...';
      });

      await _calcularAreaEGerarPontos();
      
      setState(() {
        _status = 'Pontos regenerados - ${_numeroPontosNecessarios} pontos gerados';
      });

      _mostrarSnackBar('Pontos regenerados com sucesso!', Colors.green);
    } catch (e) {
      _mostrarSnackBar('Erro ao regenerar pontos: $e', Colors.red);
    }
  }

  LatLng _calcularCentroPoligono(List<LatLng> coords) {
    if (coords.isEmpty) return LatLng(0, 0);
    
    double lat = 0, lng = 0;
    for (final coord in coords) {
      lat += coord.latitude;
      lng += coord.longitude;
    }
    
    return LatLng(lat / coords.length, lng / coords.length);
  }
}