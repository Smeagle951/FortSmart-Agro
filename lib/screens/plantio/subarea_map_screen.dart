import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../utils/fortsmart_theme.dart';
import '../../utils/snackbar_utils.dart';
import '../../config/maptiler_config.dart';
import '../../database/models/subarea_model.dart';
import '../../database/models/ponto_model.dart';
import '../../database/repositories/subarea_repository.dart';
import 'subarea_edit_screen.dart';
import 'subarea_aplicacoes_screen.dart';
import 'subarea_colheitas_screen.dart';

/// Tela de mapa para registro de subáreas com funcionalidades avançadas
class SubareaMapScreen extends StatefulWidget {
  final String experimentoId;
  final String talhaoId;
  final LatLng? talhaoCenter;
  final List<LatLng>? talhaoPolygon;

  const SubareaMapScreen({
    Key? key,
    required this.experimentoId,
    required this.talhaoId,
    this.talhaoCenter,
    this.talhaoPolygon,
  }) : super(key: key);

  @override
  State<SubareaMapScreen> createState() => _SubareaMapScreenState();
}

class _SubareaMapScreenState extends State<SubareaMapScreen> {
  late MapController _mapController;
  LatLng? _currentLocation;
  List<LatLng> _currentPolygon = [];
  bool _isDrawing = false;
  bool _isWalkMode = false;
  String _drawingMode = 'manual'; // 'manual' ou 'walk'
  
  // Dados da subárea sendo criada
  String _subareaName = '';
  String _subareaDetails = '';
  String _selectedCulture = '';
  String _selectedVariety = '';
  String _selectedProduct = '';
  double _desiredPopulation = 0.0;
  Color _subareaColor = Colors.blue;
  double _calculatedArea = 0.0;

  // Lista de subáreas já criadas
  List<Map<String, dynamic>> _subareas = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
    _centerOnTalhao();
    _loadSavedSubareas();
  }

  Future<void> _loadSavedSubareas() async {
    // TODO: Implementar carregamento real do banco
    // Por enquanto, lista vazia
    setState(() {
      _subareas = [];
    });
  }

  /// Obter localização atual
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Erro ao obter localização: $e');
    }
  }

  /// Centralizar no talhão
  void _centerOnTalhao() {
    if (widget.talhaoCenter != null) {
      _mapController.move(widget.talhaoCenter!, 16.0);
    }
  }

  /// Calcular área do polígono usando fórmula de Shoelace
  double _calculatePolygonArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;
    
    double area = 0.0;
    final int n = polygon.length;
    
    for (int i = 0; i < n; i++) {
      final int j = (i + 1) % n;
      area += polygon[i].longitude * polygon[j].latitude;
      area -= polygon[j].longitude * polygon[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para hectares (aproximação)
    // 1 grau ≈ 111 km, então 1 grau² ≈ 12,321 km²
    return area * 12321; // Em hectares
  }

  /// Verificar se ponto está dentro do polígono do talhão
  bool _isPointInTalhaoPolygon(LatLng point) {
    if (widget.talhaoPolygon == null || widget.talhaoPolygon!.isEmpty) {
      return true; // Se não há polígono definido, permitir qualquer ponto
    }
    
    return _pointInPolygon(point, widget.talhaoPolygon!);
  }

  /// Algoritmo Ray Casting para verificar se ponto está dentro do polígono
  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    int crossings = 0;
    for (int i = 0; i < polygon.length; i++) {
      final int j = (i + 1) % polygon.length;
      
      if (((polygon[i].latitude <= point.latitude) && (point.latitude < polygon[j].latitude)) ||
          ((polygon[j].latitude <= point.latitude) && (point.latitude < polygon[i].latitude))) {
        
        final double x = (point.longitude - polygon[i].longitude) * 
                        (polygon[j].latitude - polygon[i].latitude) / 
                        (polygon[j].longitude - polygon[i].longitude) + 
                        polygon[i].latitude;
        
        if (point.latitude < x) crossings++;
      }
    }
    return (crossings % 2) == 1;
  }

  /// Iniciar desenho manual
  void _startManualDrawing() {
    setState(() {
      _isDrawing = true;
      _drawingMode = 'manual';
      _currentPolygon = [];
    });
  }

  /// Iniciar modo caminhada
  void _startWalkMode() {
    setState(() {
      _isDrawing = true;
      _drawingMode = 'walk';
      _isWalkMode = true;
      _currentPolygon = [];
    });
  }

  /// Parar desenho
  void _stopDrawing() {
    setState(() {
      _isDrawing = false;
      _isWalkMode = false;
      if (_currentPolygon.length >= 3) {
        _calculatedArea = _calculatePolygonArea(_currentPolygon);
        _showSubareaForm();
      } else {
        _currentPolygon = [];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Polígono deve ter pelo menos 3 pontos'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  /// Cancelar desenho atual
  void _cancelDrawing() {
    setState(() {
      _isDrawing = false;
      _isWalkMode = false;
      _currentPolygon = [];
    });
  }

  /// Mostrar formulário de cadastro da subárea
  void _showSubareaForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSubareaForm(),
    );
  }

  /// Construir formulário Material 3 para subárea
  Widget _buildSubareaForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle do modal
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.add_location_alt, color: FortSmartTheme.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Nova Subárea',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Formulário
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Área calculada
                  _buildAreaCard(),
                  const SizedBox(height: 20),
                  
                  // Nome da subárea
                  _buildTextField(
                    label: 'Nome da Subárea',
                    hint: 'Ex: Subárea A',
                    icon: Icons.label,
                    onChanged: (value) => _subareaName = value,
                  ),
                  const SizedBox(height: 16),
                  
                  // Detalhes
                  _buildTextField(
                    label: 'Detalhes',
                    hint: 'Descrição da subárea...',
                    icon: Icons.description,
                    maxLines: 3,
                    onChanged: (value) => _subareaDetails = value,
                  ),
                  const SizedBox(height: 16),
                  
                  // Cultura
                  _buildDropdownField(
                    label: 'Cultura',
                    icon: Icons.eco,
                    items: ['Soja', 'Milho', 'Algodão', 'Feijão', 'Cana-de-açúcar', 'Tomate'],
                    onChanged: (value) => _selectedCulture = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  
                  // Variedade
                  _buildTextField(
                    label: 'Variedade',
                    hint: 'Nome da variedade',
                    icon: Icons.grass,
                    onChanged: (value) => _selectedVariety = value,
                  ),
                  const SizedBox(height: 16),
                  
                  // Produto/Sementes
                  _buildTextField(
                    label: 'Produto/Sementes',
                    hint: 'Tipo de sementes ou produto',
                    icon: Icons.agriculture,
                    onChanged: (value) => _selectedProduct = value,
                  ),
                  const SizedBox(height: 16),
                  
                  // População desejada
                  _buildTextField(
                    label: 'População Desejada (plantas/ha)',
                    hint: 'Ex: 280000',
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _desiredPopulation = double.tryParse(value) ?? 0.0,
                  ),
                  const SizedBox(height: 16),
                  
                  // Cor da subárea
                  _buildColorSelector(),
                  const SizedBox(height: 20),
                  
                  // Botões de ação
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card da área calculada
  Widget _buildAreaCard() {
    return Card(
      elevation: 2,
      color: FortSmartTheme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.area_chart, color: FortSmartTheme.primaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Área Calculada',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_calculatedArea.toStringAsFixed(2)} hectares',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: FortSmartTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Campo de texto
  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: FortSmartTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }

  /// Campo dropdown
  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: FortSmartTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: FortSmartTheme.primaryColor, width: 2),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item),
      )).toList(),
      onChanged: onChanged,
    );
  }

  /// Seletor de cor
  Widget _buildColorSelector() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor da Subárea',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: colors.map((color) => GestureDetector(
            onTap: () => setState(() => _subareaColor = color),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: _subareaColor == color 
                    ? Border.all(color: Colors.black, width: 3)
                    : null,
              ),
              child: _subareaColor == color
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          )).toList(),
        ),
      ],
    );
  }

  /// Botões de ação
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: FortSmartTheme.primaryColor),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveSubarea,
            style: ElevatedButton.styleFrom(
              backgroundColor: FortSmartTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Salvar Subárea'),
          ),
        ),
      ],
    );
  }

  /// Salvar subárea
  void _saveSubarea() {
    if (_subareaName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome da subárea é obrigatório'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final subarea = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _subareaName,
      'details': _subareaDetails,
      'culture': _selectedCulture,
      'variety': _selectedVariety,
      'product': _selectedProduct,
      'population': _desiredPopulation,
      'color': _subareaColor,
      'area': _calculatedArea,
      'polygon': _currentPolygon,
      'createdAt': DateTime.now(),
    };

    setState(() {
      _subareas.add(subarea);
      _currentPolygon = [];
      _subareaName = '';
      _subareaDetails = '';
      _selectedCulture = '';
      _selectedVariety = '';
      _selectedProduct = '';
      _desiredPopulation = 0.0;
      _calculatedArea = 0.0;
    });

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Subárea "${_subareaName}" salva com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editSubarea(SubareaModel subarea) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubareaEditScreen(subarea: subarea),
      ),
    );
    
    if (result != null) {
      // Recarregar subáreas após edição
      await _loadSavedSubareas();
      SnackbarUtils.showSuccessSnackBar(context, 'Subárea atualizada!');
    }
  }

  void _openAplicacoes(SubareaModel subarea) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubareaAplicacoesScreen(subarea: subarea),
      ),
    );
  }

  void _openColheitas(SubareaModel subarea) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubareaColheitasScreen(subarea: subarea),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Subárea'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _centerOnTalhao,
            tooltip: 'Centralizar no Talhão',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.talhaoCenter ?? const LatLng(-20.3155, -40.3128),
              initialZoom: 16.0,
              onTap: _isDrawing ? _onMapTap : null,
            ),
            children: [
              // Tile layer com API correta
              TileLayer(
                urlTemplate: MapTilerConfig.mapTileUrl,
                userAgentPackageName: 'com.fortsmart.agro',
              ),
              
              // Polígono do talhão (se existir)
              if (widget.talhaoPolygon != null)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: widget.talhaoPolygon!,
                      color: Colors.blue.withOpacity(0.3),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              
              // Polígonos das subáreas salvas
              PolygonLayer(
                polygons: _subareas.map((subarea) => Polygon(
                  points: List<LatLng>.from(subarea['polygon']),
                  color: (subarea['color'] as Color).withOpacity(0.4),
                  borderColor: subarea['color'] as Color,
                  borderStrokeWidth: 2,
                )).toList(),
              ),
              
              // Polígono sendo desenhado
              if (_currentPolygon.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _currentPolygon,
                      color: _subareaColor.withOpacity(0.3),
                      borderColor: _subareaColor,
                      borderStrokeWidth: 3,
                      isFilled: false,
                    ),
                  ],
                ),
              
              // Marcadores dos pontos do polígono atual
              if (_currentPolygon.isNotEmpty)
                MarkerLayer(
                  markers: _currentPolygon.map((point) => Marker(
                    point: point,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _subareaColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  )).toList(),
                ),
            ],
          ),
          
          // Cards das subáreas salvas
          if (_subareas.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: _subareas.map((subarea) => _buildSubareaMiniCard(subarea)).toList(),
              ),
            ),
          
          // Botões de controle
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                if (!_isDrawing) ...[
                  FloatingActionButton(
                    onPressed: _startManualDrawing,
                    backgroundColor: FortSmartTheme.primaryColor,
                    child: const Icon(Icons.edit, color: Colors.white),
                    tooltip: 'Desenho Manual',
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    onPressed: _startWalkMode,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.directions_walk, color: Colors.white),
                    tooltip: 'Modo Caminhada',
                  ),
                ] else ...[
                  FloatingActionButton(
                    onPressed: _stopDrawing,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.check, color: Colors.white),
                    tooltip: 'Finalizar Desenho',
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    onPressed: _cancelDrawing,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Cancelar',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construir card mini da subárea
  Widget _buildSubareaMiniCard(Map<String, dynamic> subarea) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: () => _showSubareaDetails(subarea),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: subarea['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subarea['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => _editSubarea(subarea['model'] as SubareaModel),
                      tooltip: 'Editar Subárea',
                    ),
                    IconButton(
                      icon: const Icon(Icons.agriculture, size: 16),
                      onPressed: () => _openAplicacoes(subarea['model'] as SubareaModel),
                      tooltip: 'Aplicações',
                    ),
                    IconButton(
                      icon: const Icon(Icons.grass, size: 16),
                      onPressed: () => _openColheitas(subarea['model'] as SubareaModel),
                      tooltip: 'Colheitas',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${(subarea['area'] as double).toStringAsFixed(2)} ha',
                  style: TextStyle(
                    color: FortSmartTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                if (subarea['culture'] != null && (subarea['culture'] as String).isNotEmpty)
                  Text(
                    subarea['culture'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mostrar detalhes da subárea
  void _showSubareaDetails(Map<String, dynamic> subarea) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(subarea['name'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Área', '${(subarea['area'] as double).toStringAsFixed(2)} hectares'),
            if (subarea['culture'] != null && (subarea['culture'] as String).isNotEmpty)
              _buildDetailRow('Cultura', subarea['culture'] as String),
            if (subarea['variety'] != null && (subarea['variety'] as String).isNotEmpty)
              _buildDetailRow('Variedade', subarea['variety'] as String),
            if (subarea['product'] != null && (subarea['product'] as String).isNotEmpty)
              _buildDetailRow('Produto', subarea['product'] as String),
            if (subarea['population'] != null && (subarea['population'] as double) > 0)
              _buildDetailRow('População', '${(subarea['population'] as double).toStringAsFixed(0)} plantas/ha'),
            if (subarea['details'] != null && (subarea['details'] as String).isNotEmpty)
              _buildDetailRow('Detalhes', subarea['details'] as String),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (subarea['model'] != null) {
                _editSubarea(subarea['model'] as SubareaModel);
              }
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  /// Linha de detalhe
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }


  /// Manipular toque no mapa
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_isDrawing) return;
    
    // Verificar se ponto está dentro do talhão
    if (!_isPointInTalhaoPolygon(point)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ponto deve estar dentro do polígono do talhão'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _currentPolygon.add(point);
    });
  }
}
