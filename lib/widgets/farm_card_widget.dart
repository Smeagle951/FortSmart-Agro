import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/farm_provider.dart';
import '../utils/logger.dart';

/// Widget para card de fazenda com dados em tempo real
class FarmCardWidget extends StatefulWidget {
  final VoidCallback? onTap;
  
  const FarmCardWidget({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  State<FarmCardWidget> createState() => _FarmCardWidgetState();
}

class _FarmCardWidgetState extends State<FarmCardWidget> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFarmData();
  }

  Future<void> _loadFarmData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Logger.info('🔍 Carregando dados da fazenda para o card...');
      
      final farmProvider = Provider.of<FarmProvider>(context, listen: false);
      await farmProvider.loadFarms();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      Logger.info('✅ Dados da fazenda carregados');
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados da fazenda: $e');
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
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fazenda',
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
                      onPressed: _loadFarmData,
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      tooltip: 'Atualizar dados',
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
                          onPressed: _loadFarmData,
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
                _buildFarmContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmContent() {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final farm = farmProvider.selectedFarm;
        final farms = farmProvider.farms;
        
        if (farm == null && farms.isEmpty) {
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
                        'Nenhuma fazenda cadastrada',
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
                'Configure uma fazenda para começar',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          );
        }
        
        return Column(
          children: [
            // Informações da fazenda selecionada
            if (farm != null) ...[
              _buildFarmInfo(farm),
              const SizedBox(height: 12),
            ],
            
            // Estatísticas gerais
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    '${farms.length}',
                    Icons.agriculture,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Selecionada',
                    farm != null ? 'Sim' : 'Não',
                    Icons.check_circle,
                    farm != null ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            
            // Botão para configurar se não há fazenda
            if (farm == null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navegar para configuração de fazenda
                    Navigator.of(context).pushNamed('/farm/setup');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Configurar Fazenda'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFarmInfo(dynamic farm) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.agriculture,
                color: Colors.green.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  farm.name ?? 'Fazenda sem nome',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (farm.location != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.grey.shade600,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    farm.location!,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (farm.area != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.area_chart,
                  color: Colors.grey.shade600,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${farm.area!.toStringAsFixed(1)} ha',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
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
