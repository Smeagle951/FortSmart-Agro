import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/experimento_completo_model.dart';
import '../../services/experimento_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';

/// Tela melhorada para criar subáreas com mapa full screen
class CriarSubareaMelhoradaScreen extends StatefulWidget {
  final String experimentoId;
  final String talhaoId;

  const CriarSubareaMelhoradaScreen({
    Key? key,
    required this.experimentoId,
    required this.talhaoId,
  }) : super(key: key);

  @override
  State<CriarSubareaMelhoradaScreen> createState() => _CriarSubareaMelhoradaScreenState();
}

class _CriarSubareaMelhoradaScreenState extends State<CriarSubareaMelhoradaScreen> {
  final ExperimentoService _experimentoService = ExperimentoService();
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _observacoesController = TextEditingController();

  // Estado
  bool _isLoading = false;
  String _tipoSelecionado = TipoExperimento.sementes;
  String? _cultura;
  String? _variedade;
  Color _corSelecionada = PaletaCoresSubareas.cores.first;
  
  // Mapa
  final MapController _mapController = MapController();
  List<LatLng> _pontosDesenho = [];
  bool _desenhando = false;
  bool _poligonoCompleto = false;

  // Cores disponíveis
  final List<Color> _coresDisponiveis = PaletaCoresSubareas.cores;

  @override
  void initState() {
    super.initState();
    _carregarCoresDisponiveis();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _observacoesController.dispose();
    _mapController.dispose();
    super.dispose();
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
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'Nova Subárea',
        showBackButton: true,
        actions: [
          if (_poligonoCompleto)
            TextButton(
              onPressed: _salvarSubarea,
              child: const Text(
                'Salvar',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Formulário de Informações
          _buildFormulario(),
          
          // Mapa
          Expanded(
            child: _buildMapa(),
          ),
          
          // Instruções
          _buildInstrucoes(),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Nome da Subárea
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
            
            // Tipo e Cor
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cor da Subárea', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: _coresDisponiveis.map((cor) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _corSelecionada = cor;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: cor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _corSelecionada == cor ? Colors.black : Colors.grey,
                                  width: _corSelecionada == cor ? 3 : 1,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Cultura e Variedade (opcional)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    onChanged: (value) => _cultura = value.trim().isEmpty ? null : value.trim(),
                    decoration: const InputDecoration(
                      labelText: 'Cultura',
                      hintText: 'Ex: Soja',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    onChanged: (value) => _variedade = value.trim().isEmpty ? null : value.trim(),
                    decoration: const InputDecoration(
                      labelText: 'Variedade',
                      hintText: 'Ex: RR 60.51',
                      border: OutlineInputBorder(),
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

  Widget _buildMapa() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-20.3155, -40.3128), // Coordenadas padrão
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
              
              // Polígono sendo desenhado
              if (_pontosDesenho.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _pontosDesenho,
                      color: _corSelecionada.withOpacity(0.3),
                      borderColor: _corSelecionada,
                      borderStrokeWidth: 2,
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
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _corSelecionada,
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
                    );
                  }).toList(),
                ),
            ],
          ),
          
          // Controles do Mapa
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'center',
                  onPressed: _centralizarMapa,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'clear',
                  onPressed: _limparDesenho,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.clear, color: Colors.red),
                ),
              ],
            ),
          ),
          
          // Status do Desenho
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusTexto(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrucoes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          top: BorderSide(color: Colors.blue[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Instruções',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Toque no mapa para desenhar os vértices da subárea\n'
            '• Toque no primeiro ponto novamente para fechar o polígono\n'
            '• Use os botões para centralizar o mapa ou limpar o desenho\n'
            '• Preencha as informações acima antes de salvar',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      if (_pontosDesenho.length >= 3 && _pontosDesenho.isNotEmpty) {
        // Verificar se clicou próximo ao primeiro ponto (fechar polígono)
        final primeiroPonto = _pontosDesenho.first;
        final distancia = _calcularDistancia(point, primeiroPonto);
        
        if (distancia < 50) { // 50 metros de tolerância
          _poligonoCompleto = true;
          _desenhando = false;
        } else {
          _pontosDesenho.add(point);
        }
      } else {
        _pontosDesenho.add(point);
        _desenhando = true;
      }
    });
  }

  double _calcularDistancia(LatLng ponto1, LatLng ponto2) {
    const double raioTerra = 6371000; // Raio da Terra em metros
    
    final lat1Rad = ponto1.latitude * 3.14159265359 / 180;
    final lat2Rad = ponto2.latitude * 3.14159265359 / 180;
    final deltaLatRad = (ponto2.latitude - ponto1.latitude) * 3.14159265359 / 180;
    final deltaLngRad = (ponto2.longitude - ponto1.longitude) * 3.14159265359 / 180;

    final a = (deltaLatRad / 2).sin() * (deltaLatRad / 2).sin() +
        lat1Rad.cos() * lat2Rad.cos() *
        (deltaLngRad / 2).sin() * (deltaLngRad / 2).sin();
    final c = 2 * (a.sqrt()).atan2((1 - a).sqrt());

    return raioTerra * c;
  }

  String _getStatusTexto() {
    if (_pontosDesenho.isEmpty) {
      return 'Toque no mapa para começar a desenhar a subárea';
    } else if (_pontosDesenho.length < 3) {
      return 'Desenhe pelo menos 3 pontos para formar um polígono';
    } else if (!_poligonoCompleto) {
      return 'Toque no primeiro ponto para fechar o polígono (${_pontosDesenho.length} pontos)';
    } else {
      return 'Polígono completo! Preencha as informações e salve';
    }
  }

  void _centralizarMapa() {
    if (_pontosDesenho.isNotEmpty) {
      // Calcular centro dos pontos
      double centerLat = _pontosDesenho.map((p) => p.latitude).reduce((a, b) => a + b) / _pontosDesenho.length;
      double centerLng = _pontosDesenho.map((p) => p.longitude).reduce((a, b) => a + b) / _pontosDesenho.length;
      
      _mapController.move(LatLng(centerLat, centerLng), 16);
    }
  }

  void _limparDesenho() {
    setState(() {
      _pontosDesenho.clear();
      _poligonoCompleto = false;
      _desenhando = false;
    });
  }

  Future<void> _salvarSubarea() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pontosDesenho.length < 3) {
      SnackbarUtils.showErrorSnackBar(context, 'Desenhe pelo menos 3 pontos para formar um polígono');
      return;
    }

    if (!_poligonoCompleto) {
      SnackbarUtils.showErrorSnackBar(context, 'Feche o polígono tocando no primeiro ponto');
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
        descricao: _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
        cultura: _cultura,
        variedade: _variedade,
        observacoes: _observacoesController.text.trim().isEmpty ? null : _observacoesController.text.trim(),
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
