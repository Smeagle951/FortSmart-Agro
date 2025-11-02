import 'package:flutter/material.dart';
import '../../models/plot.dart';
import '../../services/plot_service.dart';
import '../../utils/wrappers/notifications_wrapper.dart';
import '../../widgets/loading_indicator.dart';
import 'plot_map_draw_screen.dart';
import 'dart:convert';

class PlotAddScreen extends StatefulWidget {
  const PlotAddScreen({Key? key}) : super(key: key);

  @override
  _PlotAddScreenState createState() => _PlotAddScreenState();
}

class _PlotAddScreenState extends State<PlotAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _plotService = PlotService();
  final _notificationsWrapper = NotificationsWrapper();
  
  List<Map<String, double>>? _coordinates;
  String? _polygonJson;
  bool _hasDrawnPlot = false;
  
  String? _farmId;
  String? _plotId;
  bool _isLoading = false;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArguments();
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _loadArguments() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      _farmId = args['farmId'] as String?;
      _plotId = args['plotId'] as String?;
      
      if (_plotId != null) {
        _isEditing = true;
        await _loadPlot(_plotId!);
      }
    }
  }
  
  Future<void> _loadPlot(String plotId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final plot = await _plotService.getPlotById(plotId);
      
      if (plot != null) {
        setState(() {
          _nameController.text = plot.name;
          _areaController.text = plot.area.toString();
          _descriptionController.text = plot.description ?? '';
          _polygonJson = plot.polygonJson;
          
          if (plot.polygonJson != null) {
            try {
              final coords = jsonDecode(plot.polygonJson!);
              _coordinates = List<Map<String, double>>.from(
                (coords as List).map((e) => {
                  'lat': (e['lat'] as num).toDouble(),
                  'lng': (e['lng'] as num).toDouble(),
                })
              );
              _hasDrawnPlot = true;
            } catch (e) {
              debugPrint('Erro ao decodificar coordenadas: $e');
            }
          }
        });
      }
    } catch (e) {
      _notificationsWrapper.showNotificationWithContext(
        context: context,
        message: 'Erro ao carregar talhão: $e',
        title: 'Erro',
        type: NotificationType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Abre a tela de desenho do talhão no mapa
  Future<void> _openMapDrawScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlotMapDrawScreen(
          existingPlot: _isEditing ? Plot(
            id: _plotId,
            name: _nameController.text,
            area: double.tryParse(_areaController.text) ?? 0,
            polygonJson: _polygonJson,
            farmId: int.tryParse(_farmId ?? '0') ?? 0,
            propertyId: 0,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            description: _descriptionController.text,
          ) : null,
          farmId: _farmId,
        ),
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _coordinates = result['coordinates'] as List<Map<String, double>>?;
        _polygonJson = result['polygonJson'] as String?;
        _areaController.text = (result['area'] as double).toStringAsFixed(2);
        _hasDrawnPlot = true;
      });
    }
  }

  Future<void> _savePlot() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final name = _nameController.text;
      final area = double.parse(_areaController.text);
      final description = _descriptionController.text;
      
      // Verifica se o usuário desenhou o talhão
      if (!_hasDrawnPlot) {
        _notificationsWrapper.showNotificationWithContext(
          context: context,
          message: 'Por favor, desenhe o talhão no mapa antes de salvar.',
          title: 'Atenção',
          type: NotificationType.warning,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final now = DateTime.now().toIso8601String();
      final plot = Plot(
        id: _isEditing ? _plotId : null,
        name: name,
        area: area,
        coordinates: _coordinates,
        polygonJson: _polygonJson,
        farmId: int.tryParse(_farmId ?? '0') ?? 0,
        propertyId: 0, // Valor temporário
        createdAt: now,
        updatedAt: now,
        description: description,
      );
      
      if (_isEditing) {
        await _plotService.updatePlot(plot);
        _notificationsWrapper.showNotificationWithContext(
          context: context,
          message: 'Talhão atualizado com sucesso!',
          title: 'Sucesso',
          type: NotificationType.success,
        );
      } else {
        await _plotService.addPlot(plot);
        _notificationsWrapper.showNotificationWithContext(
          context: context,
          message: 'Talhão adicionado com sucesso!',
          title: 'Sucesso',
          type: NotificationType.success,
        );
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      _notificationsWrapper.showNotificationWithContext(
        context: context,
        message: 'Erro ao salvar talhão: $e',
        title: 'Erro',
        type: NotificationType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Talhão' : 'Adicionar Talhão'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Talhão',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe o nome do talhão';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _areaController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Área (hectares)',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.refresh),
                        tooltip: 'Calcular área do desenho',
                        onPressed: _hasDrawnPlot ? () {
                          // A área é calculada automaticamente ao desenhar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Área calculada do desenho: ${_areaController.text} hectares'))
                          );
                        } : null,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe a área do talhão';
                      }
                      try {
                        double.parse(value);
                      } catch (e) {
                        return 'Por favor, informe um número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(_hasDrawnPlot ? Icons.edit_location : Icons.add_location),
                    label: Text(_hasDrawnPlot ? 'Editar Talhão no Mapa' : 'Desenhar Talhão no Mapa'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _openMapDrawScreen(),
                  ),
                  if (_hasDrawnPlot)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Talhão desenhado com ${_coordinates?.length ?? 0} pontos',
                        style: TextStyle(color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _savePlot,
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_isEditing ? 'Atualizar Talhão' : 'Adicionar Talhão'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) const LoadingIndicator(),
        ],
      ),
    );
  }
}
