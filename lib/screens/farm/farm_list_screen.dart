import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/farm.dart';
import '../../routes.dart';
import '../../services/farm_service.dart';
import '../../utils/wrappers/notifications_wrapper.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/farm_selector_widget.dart';
import '../../providers/farm_selection_provider.dart';

class FarmListScreen extends StatefulWidget {
  const FarmListScreen({Key? key}) : super(key: key);

  @override
  _FarmListScreenState createState() => _FarmListScreenState();
}

class _FarmListScreenState extends State<FarmListScreen> {
  final _farmService = FarmService();
  final _notificationsWrapper = NotificationsWrapper();
  
  List<Farm> _farms = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadFarms();
  }
  
  Future<void> _loadFarms() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final farms = await _farmService.getAllFarms();
      
      setState(() {
        _farms = farms;
      });
    } catch (e) {
      _notificationsWrapper.showNotificationWithContext(
        context: context,
        message: 'Erro ao carregar fazendas: $e',
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
        title: const Text('Minhas Fazendas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFarms,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _farms.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Seletor de fazenda (se houver múltiplas fazendas)
                    if (_farms.length > 1)
                      FarmSelectorWidget(
                        selectedFarmId: null,
                        onFarmSelected: (farmId) {
                          // Aqui você pode implementar filtro na lista se necessário
                          print('Fazenda selecionada: $farmId');
                        },
                        showAllOption: true,
                        label: 'Filtrar por Fazenda',
                      ),
                    // Lista de fazendas
                    Expanded(
                      child: _buildFarmList(),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.farmAdd).then((_) => _loadFarms());
        },
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Fazenda',
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.agriculture,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma fazenda cadastrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione sua primeira fazenda clicando no botão abaixo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.farmAdd).then((_) => _loadFarms());
            },
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Fazenda'),
            style: ElevatedButton.styleFrom(
              // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFarmList() {
    return RefreshIndicator(
      onRefresh: _loadFarms,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _farms.length,
        itemBuilder: (context, index) {
          final farm = _farms[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                radius: 24,
                child: farm.logoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          farm.logoUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.agriculture, color: Colors.white);
                          },
                        ),
                      )
                    : const Icon(Icons.agriculture, color: Colors.white),
              ),
              title: Text(
                farm.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(farm.address),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.grass, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${farm.plotsCount} talhões'),
                      const SizedBox(width: 12),
                      Icon(Icons.area_chart, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${farm.totalArea.toStringAsFixed(2)} ha'),
                    ],
                  ),
                  if (_farms.length > 1) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: farm.isActive ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            farm.isActive ? Icons.check_circle : Icons.cancel,
                            size: 12,
                            color: farm.isActive ? Colors.green.shade600 : Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            farm.isActive ? 'Ativa' : 'Inativa',
                            style: TextStyle(
                              fontSize: 11,
                              color: farm.isActive ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              trailing: farm.isActive
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.cancel, color: Colors.red),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.farmProfile,
                  arguments: farm.id,
                ).then((_) => _loadFarms());
              },
            ),
          );
        },
      ),
    );
  }
}
