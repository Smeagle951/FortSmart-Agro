import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/polygon_database_service.dart';
import '../../services/polygon_service.dart';
import '../../database/models/polygon_model.dart';

class EditarPoligonoScreen extends StatefulWidget {
  final int polygonId;
  final String polygonName;

  const EditarPoligonoScreen({
    Key? key,
    required this.polygonId,
    required this.polygonName,
  }) : super(key: key);

  @override
  State<EditarPoligonoScreen> createState() => _EditarPoligonoScreenState();
}

class _EditarPoligonoScreenState extends State<EditarPoligonoScreen> {
  final MapController _mapController = MapController();
  final PolygonDatabaseService _polygonDatabaseService = PolygonDatabaseService.instance;

  // Dados do polígono
  PolygonModel? _polygon;
  List<LatLng> _points = [];
  List<LatLng> _originalPoints = [];
  
  // Estado de edição
  bool _isLoading = true;
  bool _isEditing = false;
  bool _hasChanges = false;
  int _selectedPointIndex = -1;
  
  // Métricas
  double _area = 0.0;
  double _perimeter = 0.0;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fazendaController = TextEditingController();
  final TextEditingController _culturaController = TextEditingController();
  final TextEditingController _safraController = TextEditingController();
  
  // GPS
  Position? _currentPosition;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadPolygon();
    _setupTextControllers();
  }
  
  /// Configura os listeners dos controllers de texto
  void _setupTextControllers() {
    _nameController.addListener(_onTextChanged);
    _culturaController.addListener(_onTextChanged);
    _safraController.addListener(_onTextChanged);
    _fazendaController.addListener(_onTextChanged);
  }
  
  /// Callback quando o texto é alterado
  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fazendaController.dispose();
    _culturaController.dispose();
    _safraController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Carrega dados do polígono
  Future<void> _loadPolygon() async {
    try {
      setState(() => _isLoading = true);
      
      print('🔄 Carregando polígono ID: ${widget.polygonId}');
      
      await _polygonDatabaseService.initialize();
      final storageService = _polygonDatabaseService.storageService;
      
      if (storageService == null) {
        throw Exception('Serviço de armazenamento não disponível');
      }
      
      // Carregar polígono
      final polygon = await storageService.polygonDao.getPolygonById(widget.polygonId);
      if (polygon == null) {
        throw Exception('Polígono não encontrado');
      }
      
      print('📊 Polígono carregado: ${polygon.name}');
      print('  - Área: ${polygon.areaHa} ha');
      print('  - Cultura: ${polygon.culturaId}');
      print('  - Safra: ${polygon.safraId}');
      
      // Converter coordenadas
      final geojson = jsonDecode(polygon.coordinates);
      final coordinates = geojson['coordinates'][0] as List;
      final points = coordinates.map((coord) {
        return LatLng(coord[1] as double, coord[0] as double);
      }).toList();
      
      setState(() {
        _polygon = polygon;
        _points = List.from(points);
        _originalPoints = List.from(points);
        _nameController.text = polygon.name;
        _fazendaController.text = polygon.fazendaId ?? '';
        _culturaController.text = polygon.culturaId ?? '';
        _safraController.text = polygon.safraId ?? '';
        _isLoading = false;
      });
      
      _updateMetrics();
      _centerMap();
      
      print('✅ Polígono carregado com sucesso');
      
    } catch (e) {
      print('❌ Erro ao carregar polígono: $e');
      setState(() => _isLoading = false);
      _showError('Erro ao carregar polígono: $e');
    }
  }

  /// Centraliza mapa no polígono
  void _centerMap() {
    if (_points.isNotEmpty) {
      final bounds = PolygonService.calculateBounds(_points);
      final southwest = bounds['southwest'] as LatLng;
      final northeast = bounds['northeast'] as LatLng;
      _mapController.fitBounds(
        LatLngBounds(southwest, northeast),
        options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
      );
    }
  }
  
  /// Obtém localização atual do GPS
  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isGettingLocation = true);
      
      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Serviço de localização desabilitado');
        return;
      }

      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permissão de localização negada');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Permissão de localização negada permanentemente');
        return;
      }

      // Obter posição
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _currentPosition = position;
        _isGettingLocation = false;
      });
      
      // Centralizar mapa na posição atual
      _centerMapOnGPS();
      
    } catch (e) {
      setState(() => _isGettingLocation = false);
      _showError('Erro ao obter localização: $e');
    }
  }
  
  /// Centraliza mapa na posição do GPS
  void _centerMapOnGPS() {
    if (_currentPosition != null) {
      final latLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _mapController.move(latLng, 15.0);
      
      // Mostrar feedback visual
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mapa centralizado na sua localização'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  /// Adiciona ponto na posição atual do GPS
  void _addPointAtGPSLocation() {
    if (!_isEditing || _currentPosition == null) {
      _showError('Modo de edição não está ativo ou GPS não disponível');
      return;
    }
    
    final latLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    _addPoint(latLng);
    
    // Centralizar mapa na posição
    _centerMapOnGPS();
    
    // Mostrar feedback visual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ponto adicionado na sua localização'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// Atualiza métricas
  void _updateMetrics() {
    if (_points.length >= 3) {
      setState(() {
        _area = PolygonService.calculateArea(_points);
        _perimeter = PolygonService.calculatePerimeter(_points);
      });
    }
  }

  /// Inicia modo de edição
  void _startEditing() {
    setState(() {
      _isEditing = true;
      _selectedPointIndex = -1;
    });
  }

  /// Para modo de edição
  void _stopEditing() {
    setState(() {
      _isEditing = false;
      _selectedPointIndex = -1;
    });
  }

  /// Adiciona ponto no polígono
  void _addPoint(LatLng point) {
    if (!_isEditing) return;
    
    setState(() {
      _points.add(point);
      _hasChanges = true;
    });
    
    _updateMetrics();
  }

  /// Remove ponto do polígono
  void _removePoint(int index) {
    if (!_isEditing || index < 0 || index >= _points.length) return;
    
    setState(() {
      _points.removeAt(index);
      _hasChanges = true;
      _selectedPointIndex = -1;
    });
    
    _updateMetrics();
  }

  /// Move ponto do polígono
  void _movePoint(int index, LatLng newPosition) {
    if (!_isEditing || index < 0 || index >= _points.length) return;
    
    setState(() {
      _points[index] = newPosition;
      _hasChanges = true;
    });
    
    _updateMetrics();
  }

  /// Seleciona ponto para edição
  void _selectPoint(int index) {
    if (!_isEditing) return;
    
    setState(() {
      _selectedPointIndex = index;
    });
  }

  /// Salva alterações
  Future<void> _saveChanges() async {
    try {
      print('🔄 Iniciando salvamento do polígono ${widget.polygonId}...');
      
      // Validar dados mínimos
      if (_nameController.text.trim().isEmpty) {
        _showError('Nome do polígono é obrigatório');
        return;
      }
      
      if (_points.length < 3) {
        _showError('Polígono deve ter pelo menos 3 pontos');
        return;
      }
      
      final storageService = _polygonDatabaseService.storageService;
      if (storageService == null) {
        _showError('Serviço de armazenamento não disponível');
        return;
      }
      
      // Preparar dados para salvamento
      final name = _nameController.text.trim();
      final culturaId = _culturaController.text.trim().isEmpty ? null : _culturaController.text.trim();
      final safraId = _safraController.text.trim().isEmpty ? null : _safraController.text.trim();
      final fazendaId = _fazendaController.text.trim().isEmpty ? null : _fazendaController.text.trim();
      
      print('📊 Dados para salvamento:');
      print('  - Nome: $name');
      print('  - Cultura: $culturaId');
      print('  - Safra: $safraId');
      print('  - Fazenda: $fazendaId');
      print('  - Área: ${_area.toStringAsFixed(2)} ha');
      print('  - Perímetro: ${_perimeter.toStringAsFixed(2)} m');
      print('  - Pontos: ${_points.length}');
      
      // Atualizar métricas antes de salvar
      _updateMetrics();
      
      print('🔄 Chamando storageService.updatePolygon...');
      final success = await storageService.updatePolygon(
        id: widget.polygonId,
        name: name,
        points: _points,
        areaHa: _area,
        perimeterM: _perimeter,
        fazendaId: fazendaId,
        culturaId: culturaId,
        safraId: safraId,
      );
      
      print('📊 Resultado do salvamento: $success');
      print('📊 Tipo do resultado: ${success.runtimeType}');
      
      if (success) {
        setState(() {
          _hasChanges = false;
          _originalPoints = List.from(_points);
        });
        
        // Atualizar o polígono local
        if (_polygon != null) {
          _polygon = _polygon!.copyWith(
            name: name,
            culturaId: culturaId,
            safraId: safraId,
            fazendaId: fazendaId,
            areaHa: _area,
            perimeterM: _perimeter,
            updatedAt: DateTime.now().toIso8601String(),
          );
        }
        
        _showSuccess('Polígono atualizado com sucesso! ID: ${widget.polygonId}');
        
        // Aguardar um pouco antes de fechar para mostrar a mensagem
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showError('Erro ao salvar alterações. Verifique os dados e tente novamente.');
      }
      
    } catch (e) {
      print('❌ Erro ao salvar polígono: $e');
      _showError('Erro ao salvar: $e');
    }
  }

  /// Cancela alterações
  void _cancelChanges() {
    setState(() {
      _points = List.from(_originalPoints);
      _hasChanges = false;
      _selectedPointIndex = -1;
    });
    
    _updateMetrics();
    _stopEditing();
  }

  /// Reverte para original
  void _revertToOriginal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reverter Alterações'),
        content: const Text('Deseja descartar todas as alterações?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelChanges();
            },
            child: const Text('Reverter'),
          ),
        ],
      ),
    );
  }

  /// Exclui polígono
  void _deletePolygon() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Polígono'),
        content: const Text('Tem certeza que deseja excluir este polígono?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  /// Confirma exclusão
  Future<void> _confirmDelete() async {
    try {
      final storageService = _polygonDatabaseService.storageService;
      if (storageService == null) {
        _showError('Serviço de armazenamento não disponível');
        return;
      }
      
      final success = await storageService.deletePolygon(widget.polygonId);
      
      if (success) {
        _showSuccess('Polígono excluído com sucesso!');
        Navigator.pop(context, true);
      } else {
        _showError('Erro ao excluir polígono');
      }
      
    } catch (e) {
      _showError('Erro ao excluir: $e');
    }
  }

  /// Mostra erro
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Mostra sucesso
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar: ${widget.polygonName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing && _hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Salvar',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopEditing,
              tooltip: 'Parar Edição',
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _startEditing,
              tooltip: 'Editar',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'revert':
                  _revertToOriginal();
                  break;
                case 'delete':
                  _deletePolygon();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'revert',
                child: Row(
                  children: [
                    Icon(Icons.undo),
                    SizedBox(width: 8),
                    Text('Reverter'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Informações do polígono
                _buildPolygonInfo(),
                
                // Mapa
                Expanded(
                  child: _buildMap(),
                ),
                
                // Métricas
                _buildMetrics(),
                
                // Controles de edição
                if (_isEditing) _buildEditControls(),
              ],
            ),
    );
  }

  /// Constrói informações do polígono
  Widget _buildPolygonInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do Polígono',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _hasChanges = true),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fazendaController,
                  decoration: const InputDecoration(
                    labelText: 'Fazenda',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _hasChanges = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _culturaController,
                  decoration: const InputDecoration(
                    labelText: 'Cultura',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _hasChanges = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _safraController,
            decoration: const InputDecoration(
              labelText: 'Safra',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _hasChanges = true),
          ),
        ],
      ),
    );
  }

  /// Constrói mapa
  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _points.isNotEmpty ? _points.first : const LatLng(-15.7801, -47.9292),
            zoom: 15.0,
            onTap: _isEditing ? (_, point) => _addPoint(point) : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            PolygonLayer(
              polygons: [
                Polygon(
                  points: _points,
                  color: _isEditing ? Colors.blue.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                  borderStrokeWidth: 2,
                  borderColor: _isEditing ? Colors.blue : Colors.green,
                ),
              ],
            ),
            MarkerLayer(
              markers: _points.asMap().entries.map((entry) {
                final index = entry.key;
                final point = entry.value;
                final isSelected = index == _selectedPointIndex;
                
                return Marker(
                  point: point,
                  width: isSelected ? 20 : 15,
                  height: isSelected ? 20 : 15,
                  child: GestureDetector(
                    onTap: _isEditing ? () => _selectPoint(index) : null,
                    onLongPress: _isEditing ? () => _removePoint(index) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red : Colors.blue,
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
                  ),
                );
              }).toList(),
            ),
            // Marcador da posição atual do GPS
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        // Botão de centralizar GPS
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _isGettingLocation ? null : _getCurrentLocation,
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            mini: true,
            child: _isGettingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                : const Icon(Icons.my_location),
          ),
        ),
        // Botão de centralizar no polígono
        Positioned(
          top: 16,
          right: 80,
          child: FloatingActionButton(
            onPressed: _centerMap,
            backgroundColor: Colors.white,
            foregroundColor: Colors.green,
            mini: true,
            child: const Icon(Icons.center_focus_strong),
          ),
        ),
      ],
    );
  }

  /// Constrói métricas
  Widget _buildMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard('Área', '${_area.toStringAsFixed(2)} ha', Icons.area_chart),
              _buildMetricCard('Perímetro', '${_perimeter.toStringAsFixed(0)} m', Icons.straighten),
              _buildMetricCard('Pontos', '${_points.length}', Icons.location_on),
            ],
          ),
          const SizedBox(height: 12),
          _buildGPSStatus(),
        ],
      ),
    );
  }
  
  /// Constrói status do GPS
  Widget _buildGPSStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _currentPosition != null ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _currentPosition != null ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _currentPosition != null ? Icons.my_location : Icons.location_off,
            color: _currentPosition != null ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _currentPosition != null 
                ? 'GPS Ativo - ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                : 'GPS Inativo - Toque no botão para ativar',
            style: TextStyle(
              fontSize: 12,
              color: _currentPosition != null ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói card de métrica
  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Constrói controles de edição
  Widget _buildEditControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border(top: BorderSide(color: Colors.blue.withOpacity(0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modo de Edição Ativo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Toque no mapa para adicionar pontos\n'
            '• Toque em um ponto para selecionar\n'
            '• Pressione longo em um ponto para remover',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _hasChanges ? _saveChanges : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _cancelChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentPosition != null ? _addPointAtGPSLocation : null,
                  icon: const Icon(Icons.add_location),
                  label: const Text('Adicionar Ponto GPS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
