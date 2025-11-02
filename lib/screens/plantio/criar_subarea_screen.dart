import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/subarea_experimento_model.dart';
import '../../models/drawing_polygon_model.dart';
import '../../models/drawing_vertex_model.dart';
import '../../utils/api_config.dart';
import '../../utils/constants.dart';
import '../../utils/type_utils.dart';
import '../../utils/geodetic_utils.dart';

class CriarSubareaScreen extends StatefulWidget {
  final String experimentoId;
  final String talhaoId;

  const CriarSubareaScreen({
    Key? key,
    required this.experimentoId,
    required this.talhaoId,
  }) : super(key: key);

  @override
  State<CriarSubareaScreen> createState() => _CriarSubareaScreenState();
}

class _CriarSubareaScreenState extends State<CriarSubareaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  String? _culturaSelecionada;
  String? _variedadeSelecionada;
  DateTime _dataInicio = DateTime.now();
  Color _corSelecionada = Colors.blue;
  List<DrawingVertex> _vertices = [];
  bool _isDrawing = false;

  final List<String> _culturas = [
    'Soja',
    'Milho',
    'Algodão',
    'Café',
    'Cana-de-açúcar',
    'Trigo',
    'Arroz',
  ];

  final List<String> _variedades = [
    'TMG',
    'Pioneira',
    'Syngenta',
    'Bayer',
    'Corteva',
  ];

  final List<Color> _coresDisponiveis = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Criar Subárea'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvarSubarea,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Formulário - Lado esquerdo
                Expanded(
                  flex: 1,
                  child: _buildFormulario(),
                ),
                // Mapa - Lado direito
                Expanded(
                  flex: 2,
                  child: _buildMapa(),
                ),
              ],
            ),
          ),
          // Botões de ação
          _buildBotoesAcao(),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_location, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Dados da Subárea',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nome
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Subárea',
                    prefixIcon: Icon(Icons.label),
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

                // Cultura
                DropdownButtonFormField<String>(
                  value: _culturaSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Cultura',
                    prefixIcon: Icon(Icons.eco),
                    border: OutlineInputBorder(),
                  ),
                  items: _culturas.map((cultura) {
                    return DropdownMenuItem(
                      value: cultura,
                      child: Text(cultura),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _culturaSelecionada = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Variedade
                DropdownButtonFormField<String>(
                  value: _variedadeSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Variedade',
                    prefixIcon: Icon(Icons.grain),
                    border: OutlineInputBorder(),
                  ),
                  items: _variedades.map((variedade) {
                    return DropdownMenuItem(
                      value: variedade,
                      child: Text(variedade),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _variedadeSelecionada = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Data de Início
                InkWell(
                  onTap: _selecionarData,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data de Início',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${_dataInicio.day.toString().padLeft(2, '0')}/${_dataInicio.month.toString().padLeft(2, '0')}/${_dataInicio.year}',
                    ),
                  ),
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
                            ),
                            child: _corSelecionada == cor
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Observações
                TextFormField(
                  controller: _observacoesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Estatísticas
                if (_vertices.isNotEmpty) _buildEstatisticas(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapa() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(-20.3155, -40.3128), // Coordenadas padrão
            initialZoom: 15,
            onTap: _isDrawing ? _adicionarVertice : null,
          ),
          children: [
            TileLayer(
              urlTemplate: APIConfig.getMapTilerUrl('satellite'),
              userAgentPackageName: 'com.fortsmart.agro',
              maxZoom: 20,
              minZoom: 10,
            ),
            // Polígono sendo desenhado
            if (_vertices.length >= 3)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _vertices.map((v) => v.toLatLng()).toList(),
                    color: _corSelecionada.withOpacity(0.3),
                    borderColor: _corSelecionada,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            // Marcadores dos vértices
            if (_vertices.isNotEmpty)
              MarkerLayer(
                markers: _vertices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final vertex = entry.value;
                  return Marker(
                    point: vertex.toLatLng(),
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _corSelecionada,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
      ),
    );
  }

  Widget _buildEstatisticas() {
    return FutureBuilder<double>(
      future: _calcularArea(),
      builder: (context, areaSnapshot) {
        return FutureBuilder<double>(
          future: _calcularPerimetro(),
          builder: (context, perimetroSnapshot) {
            final area = areaSnapshot.data ?? 0.0;
            final perimetro = perimetroSnapshot.data ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Área', '${area.toStringAsFixed(2)} ha', Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem('Perímetro', '${perimetro.toStringAsFixed(0)} m', Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatItem('Vértices', '${_vertices.length} pontos', Colors.orange),
        ],
      ),
    );
  },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotoesAcao() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _limparDesenho,
              icon: const Icon(Icons.clear),
              label: const Text('Limpar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isDrawing ? _finalizarDesenho : _iniciarDesenho,
              icon: Icon(_isDrawing ? Icons.check : Icons.edit),
              label: Text(_isDrawing ? 'Finalizar' : 'Desenhar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDrawing ? Colors.green : Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _iniciarDesenho() {
    setState(() {
      _isDrawing = true;
      _vertices.clear();
    });
  }

  void _finalizarDesenho() {
    if (_vertices.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É necessário pelo menos 3 pontos para formar um polígono'),
        ),
      );
      return;
    }

    setState(() {
      _isDrawing = false;
    });
  }

  void _adicionarVertice(TapPosition tapPosition, LatLng point) {
    setState(() {
      final vertex = DrawingVertex(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: point.latitude,
        longitude: point.longitude,
        accuracy: 0.0,
        timestamp: DateTime.now(),
        source: 'manual',
      );
      _vertices.add(vertex);
    });
  }

  void _limparDesenho() {
    setState(() {
      _vertices.clear();
      _isDrawing = false;
    });
  }

  void _selecionarData() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        _dataInicio = date;
      });
    }
  }

  Future<double> _calcularArea() async {
    if (_vertices.length < 3) return 0.0;

    final latLngVertices = _vertices.map((v) => v.toLatLng()).toList();
    final areaM2 = await GeodeticUtils.calculatePolygonArea(latLngVertices);
    return areaM2 / 10000; // Converter para hectares
  }

  Future<double> _calcularPerimetro() async {
    if (_vertices.length < 2) return 0.0;

    final latLngVertices = _vertices.map((v) => v.toLatLng()).toList();
    return await GeodeticUtils.calculatePolygonPerimeter(latLngVertices);
  }

  double _calcularDistancia(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    final double lat1Rad = p1.latitude * (3.14159265359 / 180);
    final double lat2Rad = p2.latitude * (3.14159265359 / 180);
    final double deltaLatRad = (p2.latitude - p1.latitude) * (3.14159265359 / 180);
    final double deltaLngRad = (p2.longitude - p1.longitude) * (3.14159265359 / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  void _salvarSubarea() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_vertices.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É necessário desenhar um polígono com pelo menos 3 pontos'),
        ),
      );
      return;
    }

    // Criar polígono
    final polygon = DrawingPolygon(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nomeController.text.trim(),
      vertices: _vertices,
      createdAt: DateTime.now(),
      isClosed: true,
    );

    // Calcular área e perímetro
    final areaHa = await _calcularArea();
    final perimetroM = await _calcularPerimetro();

    final subarea = Subarea(
      talhaoId: int.parse(widget.talhaoId),
      nome: _nomeController.text.trim(),
      cultura: _culturaSelecionada,
      variedade: _variedadeSelecionada,
      populacao: 60000, // Valor padrão
      cor: _corSelecionada,
      polygon: polygon,
      areaHa: areaHa,
      perimetroM: perimetroM,
      dataInicio: _dataInicio,
      criadoEm: DateTime.now(),
      observacoes: _observacoesController.text.trim().isEmpty
          ? null
          : _observacoesController.text.trim(),
    );

    // Aqui você salvaria a subárea no banco de dados
    // Por enquanto, apenas navega de volta
    Navigator.pop(context, subarea);
  }
}
