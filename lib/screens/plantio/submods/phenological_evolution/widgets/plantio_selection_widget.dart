import 'package:flutter/material.dart';
import 'package:fortsmart_agro/modules/planting/models/plantio_model.dart';
import 'package:fortsmart_agro/services/plantio_integration_service.dart';
import 'package:intl/intl.dart';

/// Widget para seleção elegante de plantios na evolução fenológica
class PlantioSelectionWidget extends StatefulWidget {
  final Function(PlantioModel) onPlantioSelected;
  final String? talhaoId;
  final String? culturaId;

  const PlantioSelectionWidget({
    Key? key,
    required this.onPlantioSelected,
    this.talhaoId,
    this.culturaId,
  }) : super(key: key);

  @override
  State<PlantioSelectionWidget> createState() => _PlantioSelectionWidgetState();
}

class _PlantioSelectionWidgetState extends State<PlantioSelectionWidget> {
  List<PlantioIntegrado> _plantiosDisponiveis = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarPlantios();
  }

  Future<void> _carregarPlantios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final integrationService = PlantioIntegrationService();
      _plantiosDisponiveis = await integrationService.buscarPlantiosParaEvolucaoFenologica(
        widget.talhaoId,
        widget.culturaId,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar plantios: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarPlantios,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_plantiosDisponiveis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum plantio encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie um plantio no submódulo "Novo Plantio" primeiro',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Criar Plantio'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecione um Plantio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_plantiosDisponiveis.length} plantios encontrados',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _plantiosDisponiveis.length,
            itemBuilder: (context, index) {
              final plantio = _plantiosDisponiveis[index];
              return _buildPlantioCard(plantio);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlantioCard(PlantioIntegrado plantio) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final diasPlantio = DateTime.now().difference(plantio.dataPlantio).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          widget.onPlantioSelected(plantio.toPlantioModel());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getSourceColor(plantio.fonte),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getSourceLabel(plantio.fonte),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(plantio.dataPlantio),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.agriculture,
                    size: 20,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plantio.culturaId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    plantio.talhaoNome,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.eco_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      plantio.variedadeId ?? 'Variedade não definida',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: '$diasPlantio DAP',
                    color: _getDapColor(diasPlantio),
                  ),
                  // ❌ NÃO EXIBIR ESPAÇAMENTO E POPULAÇÃO FICTÍCIOS
                  // Esses dados virão do submodulo "Novo Estande de Plantas"
                  // const SizedBox(width: 8),
                  // _buildInfoChip(
                  //   icon: Icons.straighten,
                  //   label: '${plantio.espacamento.toStringAsFixed(0)} cm',
                  //   color: Colors.blue,
                  // ),
                  // const SizedBox(width: 8),
                  // _buildInfoChip(
                  //   icon: Icons.group,
                  //   label: '${_formatPopulation(plantio.populacao)}',
                  //   color: Colors.orange,
                  // ),
                ],
              ),
              if (plantio.historicos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${plantio.historicos.length} registro(s) no histórico',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor(String fonte) {
    switch (fonte) {
      case 'principal':
        return Colors.blue;
      case 'submodulo':
        return Colors.green;
      case 'historico':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getSourceLabel(String fonte) {
    switch (fonte) {
      case 'principal':
        return 'PRINCIPAL';
      case 'submodulo':
        return 'SUBMÓDULO';
      case 'historico':
        return 'HISTÓRICO';
      default:
        return 'DESCONHECIDO';
    }
  }

  Color _getDapColor(int dias) {
    if (dias < 30) return Colors.green;
    if (dias < 60) return Colors.orange;
    if (dias < 90) return Colors.red;
    return Colors.purple;
  }

  String _formatPopulation(int populacao) {
    if (populacao >= 1000) {
      return '${(populacao / 1000).toStringAsFixed(0)}k/ha';
    }
    return '$populacao/ha';
  }
}
