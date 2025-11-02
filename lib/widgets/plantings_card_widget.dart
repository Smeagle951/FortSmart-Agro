import 'package:flutter/material.dart';
import '../services/dashboard_data_service.dart';
import '../utils/logger.dart';
import '../debug/check_historico_plantio.dart';
import '../debug/populate_historico_plantio.dart';

/// Widget para card de plantios com dados em tempo real
class PlantingsCardWidget extends StatefulWidget {
  final VoidCallback? onTap;
  
  const PlantingsCardWidget({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  State<PlantingsCardWidget> createState() => _PlantingsCardWidgetState();
}

class _PlantingsCardWidgetState extends State<PlantingsCardWidget> {
  final DashboardDataService _dashboardDataService = DashboardDataService();
  
  Map<String, dynamic> _plantingsData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlantingsData();
  }

  Future<void> _loadPlantingsData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Logger.info('🔍 Carregando dados REAIS de plantios para o card...');
      
      // ✅ BUSCAR DADOS REAIS do DashboardDataService
      final plantingsData = await _dashboardDataService.getPlantingsData();
      
      Logger.info('📊 Dados de plantios recebidos:');
      Logger.info('   - Total: ${plantingsData['total']}');
      Logger.info('   - Ativos: ${plantingsData['ativos']}');
      Logger.info('   - Culturas: ${(plantingsData['culturas'] as List).length}');
      Logger.info('   - Área total: ${plantingsData['area_total']} ha');
      
      if (mounted) {
        setState(() {
          _plantingsData = plantingsData;
          _isLoading = false;
        });
      }
      
      Logger.info('✅ Card de plantios atualizado com dados reais: ${plantingsData['total']} plantios');
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados de plantios: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
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
                      color: Colors.lightGreen.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_florist,
                      color: Colors.lightGreen.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plantios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        if (_isLoading)
                          const Text(
                            'Carregando...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          )
                        else if (_error != null)
                          Text(
                            'Erro ao carregar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          )
                        else
                          Text(
                            'Sistema: Funcionando normalmente',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isLoading && _error == null)
                    IconButton(
                      onPressed: _loadPlantingsData,
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      tooltip: 'Atualizar dados',
                    ),
                  // 🔍 Botão de diagnóstico
                  IconButton(
                    onPressed: () => CheckHistoricoPlantio.verificarDados(context),
                    icon: Icon(
                      Icons.bug_report,
                      color: Colors.orange.shade600,
                      size: 20,
                    ),
                    tooltip: 'Diagnóstico de dados',
                  ),
                  // 🔧 Botão para popular histórico
                  IconButton(
                    onPressed: () async {
                      await PopulateHistoricoPlantio.executar(context);
                      // Recarregar dados após popular
                      _loadPlantingsData();
                    },
                    icon: Icon(
                      Icons.build,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    tooltip: 'Popular histórico',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Erro ao carregar dados',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadPlantingsData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildPlantingsContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantingsContent() {
    final total = _plantingsData['total'] ?? 0;
    final ativos = _plantingsData['ativos'] ?? 0;
    final areaTotal = _plantingsData['area_total'] ?? 0.0;
    final culturas = _plantingsData['culturas'] as List<String>? ?? [];
    
    if (total == 0) {
      return Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nenhum plantio cadastrado',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure plantios para começar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navegar para configuração de plantios
                Navigator.of(context).pushNamed('/planting/setup');
              },
              icon: const Icon(Icons.add),
              label: const Text('Configurar Plantios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      children: [
        // Contadores principais
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total',
                '$total',
                Icons.agriculture,
                Colors.lightGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Ativos',
                '$ativos',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Área total
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Área Total',
                '${areaTotal.toStringAsFixed(1)} ha',
                Icons.area_chart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Culturas',
                '${culturas.length}',
                Icons.eco,
                Colors.purple,
              ),
            ),
          ],
        ),
        
        // Lista de culturas
        if (culturas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.lightGreen.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.lightGreen.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.eco,
                      color: Colors.lightGreen.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Culturas Ativas',
                      style: TextStyle(
                        color: Colors.lightGreen.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...culturas.take(3).map((cultura) => _buildCulturaItem(cultura)).toList(),
                if (culturas.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '... e mais ${culturas.length - 3} culturas',
                      style: TextStyle(
                        color: Colors.lightGreen.shade700,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCulturaItem(String cultura) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.lightGreen.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cultura,
              style: TextStyle(
                color: Colors.lightGreen.shade800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
