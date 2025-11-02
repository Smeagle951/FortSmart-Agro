import 'package:flutter/material.dart';
import '../../models/plot.dart';
import '../../services/plot_service.dart';
import '../../utils/wrappers/notifications_wrapper.dart';
import '../../widgets/loading_indicator.dart';

class PlotEditScreen extends StatefulWidget {
  const PlotEditScreen({Key? key}) : super(key: key);

  @override
  _PlotEditScreenState createState() => _PlotEditScreenState();
}

class _PlotEditScreenState extends State<PlotEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _plotService = PlotService();
  final _notificationsWrapper = NotificationsWrapper();
  
  String? _plotId;
  Plot? _plot;
  bool _isLoading = false;
  
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
  
  void _loadArguments() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    
    if (args != null && args.containsKey('plotId')) {
      _plotId = args['plotId'] as String;
      _loadPlot();
    } else {
      Navigator.pop(context);
      _notificationsWrapper.showNotificationWithContext(
        context: context,
        title: 'Erro',
        message: 'ID do talhão não fornecido',
        type: NotificationType.error,
      );
    }
  }
  
  Future<void> _loadPlot() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final plot = await _plotService.getPlotById(_plotId!);
      
      if (plot != null) {
        setState(() {
          _plot = plot;
          _nameController.text = plot.name;
          _areaController.text = plot.area.toString();
          _descriptionController.text = plot.description ?? '';
        });
      } else {
        Navigator.pop(context);
        _notificationsWrapper.showNotificationWithContext(
          context: context,
          title: 'Erro',
          message: 'Talhão não encontrado',
          type: NotificationType.error,
        );
      }
    } catch (e) {
      _notificationsWrapper.showNotificationWithContext(
        context: context,
        title: 'Erro',
        message: 'Erro ao carregar talhão: $e',
        type: NotificationType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _updatePlot() async {
    if (!_formKey.currentState!.validate() || _plot == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedPlot = Plot(
        id: _plot!.id,
        name: _nameController.text,
        area: double.parse(_areaController.text),
        coordinates: _plot!.coordinates,
        farmId: _plot!.farmId,
        propertyId: _plot!.propertyId,
        description: _descriptionController.text,
        cropName: _plot!.cropName,
        createdAt: _plot!.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      await _plotService.updatePlot(updatedPlot);
      
      _notificationsWrapper.showNotificationWithContext(
        context: context,
        title: 'Sucesso',
        message: 'Talhão atualizado com sucesso!',
        type: NotificationType.success,
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      _notificationsWrapper.showNotificationWithContext(
        context: context,
        title: 'Erro',
        message: 'Erro ao atualizar talhão: $e',
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
        title: const Text('Editar Talhão'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
                    decoration: const InputDecoration(
                      labelText: 'Área (ha)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe a área do talhão';
                      }
                      try {
                        final area = double.parse(value);
                        if (area <= 0) {
                          return 'A área deve ser maior que zero';
                        }
                      } catch (e) {
                        return 'Por favor, informe um número válido';
                      }
                      return null;
                    },
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
                    onPressed: _updatePlot,
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Salvar Alterações'),
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
