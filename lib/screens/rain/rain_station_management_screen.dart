import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/rain_station_model.dart';
import '../../repositories/rain_station_repository.dart';
import '../../utils/logger.dart';
import 'rain_station_edit_screen.dart';

/// Tela para gerenciar pontos de coleta de chuva
class RainStationManagementScreen extends StatefulWidget {
  const RainStationManagementScreen({Key? key}) : super(key: key);

  @override
  State<RainStationManagementScreen> createState() => _RainStationManagementScreenState();
}

class _RainStationManagementScreenState extends State<RainStationManagementScreen> {
  final RainStationRepository _repository = RainStationRepository();
  List<RainStationModel> _stations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    
    try {
      _stations = await _repository.getAllRainStations();
      
      // Se não houver pontos, criar pontos padrão
      if (_stations.isEmpty) {
        await _repository.createDefaultRainStations();
        _stations = await _repository.getAllRainStations();
      }
      
      Logger.info('📊 ${_stations.length} pontos de chuva carregados');
    } catch (e) {
      Logger.error('❌ Erro ao carregar pontos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStation(RainStationModel station) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Remoção'),
          content: Text('Deseja remover o ponto "${station.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remover', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await _repository.deleteRainStation(station.id);
        if (success) {
          setState(() {
            _stations.removeWhere((s) => s.id == station.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ponto "${station.name}" removido'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('❌ Erro ao remover ponto: $e');
    }
  }

  Future<void> _toggleStationStatus(RainStationModel station) async {
    try {
      final updatedStation = station.copyWith(
        isActive: !station.isActive,
        updatedAt: DateTime.now(),
      );
      
      final success = await _repository.updateRainStation(updatedStation);
      if (success) {
        setState(() {
          final index = _stations.indexWhere((s) => s.id == station.id);
          if (index >= 0) {
            _stations[index] = updatedStation;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedStation.isActive 
                ? 'Ponto "${station.name}" ativado'
                : 'Ponto "${station.name}" desativado'
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      Logger.error('❌ Erro ao alterar status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pontos de Coleta de Chuva',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadStations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stations.isEmpty
              ? _buildEmptyState()
              : _buildStationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewStation(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhum ponto de chuva encontrado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Toque no botão + para adicionar um novo ponto',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stations.length,
      itemBuilder: (context, index) {
        final station = _stations[index];
        return _buildStationCard(station);
      },
    );
  }

  Widget _buildStationCard(RainStationModel station) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStationColor(station.color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.water_drop,
                    color: _getStationColor(station.color),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        station.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: station.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    station.isActive ? 'Ativo' : 'Inativo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${station.latitude.toStringAsFixed(4)}, ${station.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            
            if (station.notes != null && station.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      station.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editStation(station),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleStationStatus(station),
                    icon: Icon(
                      station.isActive ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(station.isActive ? 'Desativar' : 'Ativar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: station.isActive ? Colors.orange : Colors.green,
                      side: BorderSide(
                        color: station.isActive ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _deleteStation(station),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Remover'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStationColor(String? color) {
    switch (color) {
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      case 'purple': return Colors.purple;
      default: return Colors.blue;
    }
  }

  Future<void> _addNewStation() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RainStationEditScreen(),
      ),
    );
    
    if (result == true) {
      _loadStations();
    }
  }

  Future<void> _editStation(RainStationModel station) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RainStationEditScreen(station: station),
      ),
    );
    
    if (result == true) {
      _loadStations();
    }
  }
}
