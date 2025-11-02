import 'package:flutter/material.dart';
import '../../services/alertas_climaticos_v3_service.dart';
import '../../widgets/organisms/climatic_alert_card_widget.dart';
import '../../models/organism_catalog_v3.dart';
import '../../services/organism_catalog_loader_service_v3.dart';

/// Dashboard de riscos climáticos em tempo real usando dados v3.0
class ClimaticRisksDashboardV3 extends StatefulWidget {
  final String cultura;
  final double temperaturaAtual;
  final double umidadeAtual;

  const ClimaticRisksDashboardV3({
    Key? key,
    required this.cultura,
    required this.temperaturaAtual,
    required this.umidadeAtual,
  }) : super(key: key);

  @override
  State<ClimaticRisksDashboardV3> createState() => _ClimaticRisksDashboardV3State();
}

class _ClimaticRisksDashboardV3State extends State<ClimaticRisksDashboardV3> {
  final AlertasClimaticosV3Service _alertasService = AlertasClimaticosV3Service();
  final OrganismCatalogLoaderServiceV3 _loader = OrganismCatalogLoaderServiceV3();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _alertas = [];
  List<OrganismCatalogV3> _organismos = [];

  @override
  void initState() {
    super.initState();
    _loadAlertas();
  }

  Future<void> _loadAlertas() async {
    setState(() => _isLoading = true);

    try {
      // Carregar organismos da cultura
      _organismos = await _loader.loadCultureOrganismsV3(widget.cultura);

      // Gerar alertas
      _alertas = await _alertasService.gerarAlertasParaCultura(
        cultura: widget.cultura,
        temperaturaAtual: widget.temperaturaAtual,
        umidadeAtual: widget.umidadeAtual,
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar alertas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riscos Climáticos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlertas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAlertas,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card de condições atuais
                    _buildCurrentConditionsCard(),
                    
                    const SizedBox(height: 16),
                    
                    // Resumo de alertas
                    _buildAlertsSummary(),
                    
                    const SizedBox(height: 16),
                    
                    // Lista de alertas
                    if (_alertas.isEmpty)
                      _buildNoAlertsMessage()
                    else
                      ..._alertas.map((alerta) {
                        final organismo = _organismos.firstWhere(
                          (org) => org.id == alerta['organismo_id'],
                          orElse: () => _organismos.first,
                        );
                        
                        return ClimaticAlertCardWidget(
                          organismo: organismo,
                          temperaturaAtual: widget.temperaturaAtual,
                          umidadeAtual: widget.umidadeAtual,
                          onTap: () {
                            // TODO: Navegar para detalhes do organismo
                          },
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentConditionsCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildConditionItem(
              Icons.thermostat,
              'Temperatura',
              '${widget.temperaturaAtual.toStringAsFixed(1)}°C',
              Colors.orange,
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            _buildConditionItem(
              Icons.water_drop,
              'Umidade',
              '${widget.umidadeAtual.toStringAsFixed(0)}%',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSummary() {
    final altoRisco = _alertas.where((a) => a['nivel'] == 'Alto').length;
    final medioRisco = _alertas.where((a) => a['nivel'] == 'Médio').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo de Alertas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryChip(
                    'Alto Risco',
                    altoRisco,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryChip(
                    'Médio Risco',
                    medioRisco,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAlertsMessage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Nenhum Alerta de Risco',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'As condições climáticas atuais não favorecem\ninfestações significativas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

