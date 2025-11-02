import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../utils/snackbar_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../database/models/subarea_model.dart';
import '../../database/models/ponto_model.dart';
import '../../database/repositories/subarea_repository.dart';
import '../../config/maptiler_config.dart';

/// Tela para edição de subáreas existentes
class SubareaEditScreen extends StatefulWidget {
  final SubareaModel subarea;

  const SubareaEditScreen({
    Key? key,
    required this.subarea,
  }) : super(key: key);

  @override
  State<SubareaEditScreen> createState() => _SubareaEditScreenState();
}

class _SubareaEditScreenState extends State<SubareaEditScreen> {
  final MapController _mapController = MapController();
  final SubareaRepository _subareaRepository = SubareaRepository();
  final Uuid _uuid = Uuid();

  // Controllers para formulário
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _cultureController = TextEditingController();
  final TextEditingController _varietyController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _populationController = TextEditingController();

  // Estado do mapa e desenho
  List<LatLng> _currentPolygon = [];
  Color _selectedColor = Colors.blue;
  bool _isDrawing = false;
  double _calculatedArea = 0.0;

  // Opções de cores
  final List<Color> _colorOptions = [
    Colors.blue, Colors.red, Colors.green, Colors.orange,
    Colors.purple, Colors.teal, Colors.brown, Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadSubareaData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _cultureController.dispose();
    _varietyController.dispose();
    _productController.dispose();
    _populationController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _nameController.text = widget.subarea.nome;
    _detailsController.text = widget.subarea.descricao ?? '';
    _cultureController.text = widget.subarea.cultura ?? '';
    _varietyController.text = widget.subarea.variedade ?? '';
    _productController.text = widget.subarea.produto ?? '';
    _populationController.text = widget.subarea.populacaoDesejada.toString();
    _selectedColor = Color(widget.subarea.cor);
    _calculatedArea = widget.subarea.areaHa;
  }

  void _loadSubareaData() {
    setState(() {
      _currentPolygon = widget.subarea.pontos.map((p) => LatLng(p.latitude, p.longitude)).toList();
    });
    
    if (_currentPolygon.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapOnPolygon();
      });
    }
  }

  void _centerMapOnPolygon() {
    if (_currentPolygon.isEmpty) return;
    
    double minLat = _currentPolygon.first.latitude;
    double maxLat = _currentPolygon.first.latitude;
    double minLng = _currentPolygon.first.longitude;
    double maxLng = _currentPolygon.first.longitude;
    
    for (final point in _currentPolygon) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 16.0);
  }

  void _startDrawing() {
    setState(() {
      _isDrawing = true;
      _currentPolygon.clear();
      _calculatedArea = 0.0;
    });
    SnackbarUtils.showInfoSnackBar(context, 'Modo de desenho ativado. Toque no mapa para redesenhar o polígono.');
  }

  void _stopDrawing() {
    setState(() {
      _isDrawing = false;
    });
    
    if (_currentPolygon.length < 3) {
      SnackbarUtils.showErrorSnackBar(context, 'Um polígono precisa de pelo menos 3 pontos.');
      _currentPolygon.clear();
      _calculatedArea = 0.0;
    } else {
      _calculateArea();
      SnackbarUtils.showSuccessSnackBar(context, 'Polígono atualizado!');
    }
  }

  void _onMapTap(LatLng point) {
    if (!_isDrawing) return;

    setState(() {
      _currentPolygon.add(point);
      if (_currentPolygon.length >= 3) {
        _calculateArea();
      }
    });
  }

  void _calculateArea() {
    if (_currentPolygon.length < 3) {
      setState(() {
        _calculatedArea = 0.0;
      });
      return;
    }

    double area = 0.0;
    int j = _currentPolygon.length - 1;
    for (int i = 0; i < _currentPolygon.length; i++) {
      area += (_currentPolygon[j].latitude + _currentPolygon[i].latitude) *
              (_currentPolygon[j].longitude - _currentPolygon[i].longitude);
      j = i;
    }
    
    // Conversão aproximada para hectares
    setState(() {
      _calculatedArea = (area.abs() * 111320 * 111320) / 10000;
    });
  }

  void _clearDrawing() {
    setState(() {
      _currentPolygon.clear();
      _calculatedArea = 0.0;
      _isDrawing = false;
    });
    SnackbarUtils.showInfoSnackBar(context, 'Desenho limpo.');
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Nome da subárea é obrigatório.');
      return;
    }

    if (_currentPolygon.length < 3) {
      SnackbarUtils.showErrorSnackBar(context, 'Polígono deve ter pelo menos 3 pontos.');
      return;
    }

    try {
      // Atualizar pontos
      final pontos = _currentPolygon.map((p) => PontoModel(
        id: _uuid.v4(),
        latitude: p.latitude,
        longitude: p.longitude,
        subareaId: widget.subarea.id,
      )).toList();

      // Criar subárea atualizada
      final updatedSubarea = widget.subarea.copyWith(
        nome: _nameController.text,
        descricao: _detailsController.text,
        cultura: _cultureController.text,
        variedade: _varietyController.text,
        produto: _productController.text,
        populacaoDesejada: double.tryParse(_populationController.text) ?? 0.0,
        cor: _selectedColor.value,
        areaHa: _calculatedArea,
        pontos: pontos,
        updatedAt: DateTime.now(),
      );

      await _subareaRepository.updateSubarea(updatedSubarea);
      
      SnackbarUtils.showSuccessSnackBar(context, 'Subárea atualizada com sucesso!');
      Navigator.pop(context, updatedSubarea);

    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar alterações: $e');
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      decoration: FortSmartTheme.createInputDecoration(
        label,
        prefixIcon: icon,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cor da Subárea:',
          style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colorOptions.map((color) => GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedColor == color ? FortSmartTheme.primaryColor : Colors.transparent,
                  width: 3,
                ),
              ),
              child: _selectedColor == color
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          )).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Subárea'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isDrawing ? const Icon(Icons.stop) : const Icon(Icons.edit_location_alt),
            onPressed: _isDrawing ? _stopDrawing : _startDrawing,
            tooltip: _isDrawing ? 'Parar Desenho' : 'Redesenhar Polígono',
          ),
          if (_isDrawing)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearDrawing,
              tooltip: 'Limpar Desenho',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Salvar Alterações',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mapa
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: LatLng(-20.2764, -40.3000),
                    zoom: 13.0,
                    onTap: _isDrawing ? (tapPosition, point) => _onMapTap(point) : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapTilerConfig.mapTileUrl,
                      userAgentPackageName: 'com.fortsmart.agro',
                    ),
                    
                    // Polígono atual
                    if (_currentPolygon.isNotEmpty)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: _currentPolygon,
                            color: _selectedColor.withOpacity(0.5),
                            borderColor: _selectedColor,
                            borderStrokeWidth: 3,
                            isFilled: true,
                          ),
                        ],
                      ),
                    
                    // Marcadores dos pontos
                    if (_currentPolygon.isNotEmpty)
                      MarkerLayer(
                        markers: _currentPolygon.map((point) => Marker(
                          point: point,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        )).toList(),
                      ),
                  ],
                ),
                
                // Indicador de modo de desenho
                if (_isDrawing)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: FortSmartTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Modo Desenho Ativo',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Formulário
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Nome da Subárea',
                    icon: Icons.label,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    label: 'Detalhes/Descrição',
                    icon: Icons.description,
                    controller: _detailsController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Cultura',
                          icon: Icons.eco,
                          controller: _cultureController,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          label: 'Variedade',
                          icon: Icons.category,
                          controller: _varietyController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    label: 'Produto/Sementes',
                    icon: Icons.agriculture,
                    controller: _productController,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    label: 'População Desejada (plantas/ha)',
                    icon: Icons.people,
                    controller: _populationController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildColorSelector(),
                  const SizedBox(height: 16),
                  
                  // Área calculada
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FortSmartTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FortSmartTheme.primaryColor),
                    ),
                    child: Text(
                      'Área Calculada: ${NumberFormat("#,##0.00", "pt_BR").format(_calculatedArea)} ha',
                      style: FortSmartTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: FortSmartTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
