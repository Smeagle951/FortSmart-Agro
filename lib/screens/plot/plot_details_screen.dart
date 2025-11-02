import 'package:flutter/material.dart';
import '../../models/plot.dart';
import '../../routes.dart';
import '../../services/plot_service.dart';
import '../../utils/wrappers/notifications_wrapper.dart';
import '../../widgets/loading_indicator.dart';

class PlotDetailsScreen extends StatefulWidget {
  const PlotDetailsScreen({Key? key}) : super(key: key);

  @override
  _PlotDetailsScreenState createState() => _PlotDetailsScreenState();
}

class _PlotDetailsScreenState extends State<PlotDetailsScreen> {
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
  
  void _loadArguments() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    
    if (args != null && args.containsKey('plotId')) {
      _plotId = args['plotId'] as String;
      _loadPlot();
    }
  }
  
  Future<void> _loadPlot() async {
    if (_plotId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final plot = await _plotService.getPlotById(_plotId!);
      
      setState(() {
        _plot = plot;
      });
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
  
  Future<void> _deletePlot() async {
    if (_plot == null) return;
    
    final confirmed = await _notificationsWrapper.showConfirmationDialog(
      context,
      title: 'Remover Talhão',
      message: 'Tem certeza que deseja remover este talhão?',
      confirmText: 'Remover',
      cancelText: 'Cancelar',
    );
    
    if (confirmed) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final success = await _plotService.deletePlot(_plot!.id!);
        
        if (success) {
          _notificationsWrapper.showNotificationWithContext(
            context: context,
            message: 'Talhão removido com sucesso!',
            title: 'Sucesso',
            type: NotificationType.success,
          );
          
          Navigator.pop(context, true);
        } else {
          _notificationsWrapper.showNotificationWithContext(
            context: context,
            message: 'Erro ao remover talhão',
            title: 'Erro',
            type: NotificationType.error,
          );
        }
      } catch (e) {
        _notificationsWrapper.showNotificationWithContext(
          context: context,
          message: 'Erro ao remover talhão: $e',
          title: 'Erro',
          type: NotificationType.error,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_plot?.name ?? 'Detalhes do Talhão'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.plotEdit,
                arguments: {'plotId': _plotId},
              ).then((value) {
                if (value == true) {
                  _loadPlot();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deletePlot,
          ),
        ],
      ),
      body: Stack(
        children: [
          _plot == null
              ? const Center(child: Text('Nenhum talhão encontrado'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildActionsCard(),
                    ],
                  ),
                ),
          if (_isLoading) const LoadingIndicator(),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações do Talhão',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A4F3D),
              ),
            ),
            const Divider(),
            _buildInfoRow('Nome', _plot!.name),
            _buildInfoRow('Área', '${_plot!.area} ha'),
            if (_plot!.description != null && _plot!.description!.isNotEmpty)
              _buildInfoRow('Descrição', _plot!.description!),
            if (_plot!.cropName != null && _plot!.cropName!.isNotEmpty)
              _buildInfoRow('Cultura', _plot!.cropName!),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A4F3D),
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A4F3D),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.eco, color: Color(0xFF2A4F3D)),
              title: const Text('Registrar Plantio'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/plantio/registro',
                  arguments: {'plotId': _plotId},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pest_control, color: Color(0xFF2A4F3D)),
              title: const Text('Registrar Aplicação'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.applicationAdd,
                  arguments: {'plotId': _plotId},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.agriculture, color: Color(0xFF2A4F3D)),
              title: const Text('Registrar Colheita'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.harvestAdd,
                  arguments: {'plotId': _plotId},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
