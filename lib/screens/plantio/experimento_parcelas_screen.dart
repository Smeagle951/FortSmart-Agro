import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../config/maptiler_config.dart';
import '../../database/models/experimento_model.dart';
import '../../database/models/tratamento_model.dart';
import '../../database/models/parcela_model.dart';
import '../../database/models/subarea_model.dart';
import 'parcela_form_screen.dart';

/// Tela para gerenciar parcelas experimentais
class ExperimentoParcelasScreen extends StatefulWidget {
  final ExperimentoModel experimento;

  const ExperimentoParcelasScreen({
    Key? key,
    required this.experimento,
  }) : super(key: key);

  @override
  State<ExperimentoParcelasScreen> createState() => _ExperimentoParcelasScreenState();
}

class _ExperimentoParcelasScreenState extends State<ExperimentoParcelasScreen> {
  final MapController _mapController = MapController();
  
  List<TratamentoModel> _tratamentos = [];
  List<ParcelaModel> _parcelas = [];
  List<SubareaModel> _subareas = [];
  bool _isLoading = true;
  
  // Cores para tratamentos
  final List<Color> _coresTratamentos = [
    Colors.red, Colors.blue, Colors.green, Colors.orange,
    Colors.purple, Colors.teal, Colors.brown, Colors.indigo,
    Colors.pink, Colors.cyan, Colors.amber, Colors.lime,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implementar carregamento real do banco
      // Listas vazias para dados reais
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _tratamentos = [];
        _parcelas = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar dados: $e');
    }
  }

  List<LatLng> _generateMockPolygon(int codigo) {
    // Gerar polígonos mock para demonstração
    final baseLat = -20.2764 + (codigo * 0.001);
    final baseLng = -40.3000 + (codigo * 0.001);
    
    return [
      LatLng(baseLat, baseLng),
      LatLng(baseLat + 0.001, baseLng),
      LatLng(baseLat + 0.001, baseLng + 0.001),
      LatLng(baseLat, baseLng + 0.001),
    ];
  }

  Future<void> _addNovaParcela() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParcelaFormScreen(
          experimento: widget.experimento,
          tratamentos: _tratamentos,
          parcela: null,
        ),
      ),
    );

    if (result != null) {
      await _loadData();
      SnackbarUtils.showSuccessSnackBar(context, 'Parcela adicionada com sucesso!');
    }
  }

  Future<void> _editParcela(ParcelaModel parcela) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParcelaFormScreen(
          experimento: widget.experimento,
          tratamentos: _tratamentos,
          parcela: parcela,
        ),
      ),
    );

    if (result != null) {
      await _loadData();
      SnackbarUtils.showSuccessSnackBar(context, 'Parcela atualizada com sucesso!');
    }
  }

  Color _getCorTratamento(int numeroTratamento) {
    final index = (numeroTratamento - 1) % _coresTratamentos.length;
    return _coresTratamentos[index];
  }

  TratamentoModel? _getTratamentoPorNumero(int numeroTratamento) {
    try {
      return _tratamentos[numeroTratamento - 1];
    } catch (e) {
      return null;
    }
  }

  Widget _buildParcelaCard(ParcelaModel parcela) {
    final tratamento = _getTratamentoPorNumero(parcela.numeroTratamento);
    final cor = _getCorTratamento(parcela.numeroTratamento);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor,
          child: Text(
            parcela.codigo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          tratamento?.nome ?? 'Tratamento ${parcela.numeroTratamento}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Repetição ${parcela.numeroRepeticao} | ${NumberFormat("#,##0.00", "pt_BR").format(parcela.area)} ha'),
            Text(
              'Status: ${parcela.status.replaceAll('_', ' ').toUpperCase()}',
              style: TextStyle(
                color: parcela.status == 'plantada' ? Colors.green : 
                       parcela.status == 'colhida' ? Colors.orange : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editParcela(parcela);
                break;
              case 'plant':
                _marcarComoPlantada(parcela);
                break;
              case 'harvest':
                _marcarComoColhida(parcela);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (parcela.status == 'planejada')
              const PopupMenuItem(
                value: 'plant',
                child: ListTile(
                  leading: Icon(Icons.eco, color: Colors.green),
                  title: Text('Marcar como Plantada'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (parcela.status == 'plantada')
              const PopupMenuItem(
                value: 'harvest',
                child: ListTile(
                  leading: Icon(Icons.agriculture, color: Colors.orange),
                  title: Text('Marcar como Colhida'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _marcarComoPlantada(ParcelaModel parcela) async {
    // TODO: Implementar atualização real no banco
    setState(() {
      final index = _parcelas.indexWhere((p) => p.id == parcela.id);
      if (index != -1) {
        _parcelas[index] = parcela.copyWith(
          status: 'plantada',
          dataPlantio: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    });
    SnackbarUtils.showSuccessSnackBar(context, 'Parcela marcada como plantada!');
  }

  Future<void> _marcarComoColhida(ParcelaModel parcela) async {
    // TODO: Implementar atualização real no banco
    setState(() {
      final index = _parcelas.indexWhere((p) => p.id == parcela.id);
      if (index != -1) {
        _parcelas[index] = parcela.copyWith(
          status: 'colhida',
          dataColheita: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    });
    SnackbarUtils.showSuccessSnackBar(context, 'Parcela marcada como colhida!');
  }

  Widget _buildMapaParcelas() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: LatLng(-20.2764, -40.3000),
            zoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: MapTilerConfig.mapTileUrl,
              userAgentPackageName: 'com.fortsmart.agro',
            ),
            
            // Polígonos das parcelas
            PolygonLayer(
              polygons: _parcelas.map((parcela) {
                final cor = _getCorTratamento(parcela.numeroTratamento);
                return Polygon(
                  points: parcela.pontos,
                  color: cor.withOpacity(0.3),
                  borderColor: cor,
                  borderStrokeWidth: 2,
                  isFilled: true,
                );
              }).toList(),
            ),
            
            // Marcadores com códigos das parcelas
            MarkerLayer(
              markers: _parcelas.map((parcela) {
                final cor = _getCorTratamento(parcela.numeroTratamento);
                return Marker(
                  point: parcela.centro,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        parcela.codigo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
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

  Widget _buildLegendaTratamentos() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legenda dos Tratamentos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _tratamentos.asMap().entries.map((entry) {
              final index = entry.key;
              final tratamento = entry.value;
              final cor = _coresTratamentos[index % _coresTratamentos.length];
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${tratamento.codigo}: ${tratamento.nome}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parcelas - ${widget.experimento.nome}'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNovaParcela,
            tooltip: 'Nova Parcela',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Mapa das parcelas
                _buildMapaParcelas(),
                
                // Legenda dos tratamentos
                _buildLegendaTratamentos(),
                
                const SizedBox(height: 16),
                
                // Lista de parcelas
                Expanded(
                  child: _parcelas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.grid_view,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma parcela cadastrada',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toque no + para adicionar a primeira parcela',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _parcelas.length,
                          itemBuilder: (context, index) {
                            return _buildParcelaCard(_parcelas[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNovaParcela,
        backgroundColor: FortSmartTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Nova Parcela',
      ),
    );
  }
}
