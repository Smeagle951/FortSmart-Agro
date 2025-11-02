import 'package:flutter/material.dart';
import 'package:fortsmart_agro/services/plantio_integration_service.dart';
import 'package:fortsmart_agro/database/repositories/estande_plantas_repository.dart';
import 'package:fortsmart_agro/database/models/estande_plantas_model.dart';
import 'package:intl/intl.dart';

/// Widget para mostrar informações integradas do plantio na evolução fenológica
class PlantioInfoWidget extends StatefulWidget {
  final String talhaoId;
  final String culturaId;

  const PlantioInfoWidget({
    Key? key,
    required this.talhaoId,
    required this.culturaId,
  }) : super(key: key);

  @override
  State<PlantioInfoWidget> createState() => _PlantioInfoWidgetState();
}

class _PlantioInfoWidgetState extends State<PlantioInfoWidget> {
  PlantioIntegrado? _plantio;
  EstandePlantasModel? _estandeReal; // Dados REAIS do estande
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarPlantio();
  }

  Future<void> _carregarPlantio() async {
    try {
      final integrationService = PlantioIntegrationService();
      final plantios = await integrationService.buscarPlantiosParaEvolucaoFenologica(
        widget.talhaoId,
        widget.culturaId,
      );

      if (plantios.isNotEmpty) {
        _plantio = plantios.first; // Pegar o mais recente
        
        // Buscar dados REAIS do estande
        try {
          print('═══════════════════════════════════════════════');
          print('🔍 PLANTIO INFO WIDGET: Buscando estande real');
          print('   Talhão ID: ${widget.talhaoId}');
          print('   Cultura ID: ${widget.culturaId}');
          print('═══════════════════════════════════════════════');
          
          final estandeRepository = EstandePlantasRepository();
          
          // Debug: Listar TODOS os estandes para verificar
          try {
            final todosEstandes = await estandeRepository.buscarTodos();
            print('📋 TOTAL DE ESTANDES NO BANCO: ${todosEstandes.length}');
            for (var est in todosEstandes) {
              print('   - Talhão: ${est.talhaoId}, Cultura: ${est.culturaId}, Pop: ${est.plantasPorHectare}');
            }
          } catch (e) {
            print('⚠️ Erro ao listar estandes: $e');
          }
          
          _estandeReal = await estandeRepository.getLatestByTalhaoAndCultura(
            widget.talhaoId,
            widget.culturaId,
          );
          
          if (_estandeReal != null) {
            print('✅ ESTANDE REAL ENCONTRADO:');
            print('   ID: ${_estandeReal!.id}');
            print('   Talhão ID: ${_estandeReal!.talhaoId}');
            print('   Cultura ID: ${_estandeReal!.culturaId}');
            print('   População Real: ${_estandeReal!.plantasPorHectare?.toStringAsFixed(0)} plantas/ha');
            print('   Eficiência: ${_estandeReal!.eficiencia?.toStringAsFixed(1)}%');
            print('   Plantas por metro: ${_estandeReal!.plantasPorMetro?.toStringAsFixed(1)}');
            print('   População ideal: ${_estandeReal!.populacaoIdeal?.toStringAsFixed(0)}');
            print('   DAE: ${_estandeReal!.diasAposEmergencia}');
            print('═══════════════════════════════════════════════');
          } else {
            print('⚠️ NENHUM ESTANDE ENCONTRADO!');
            print('   Talhão procurado: ${widget.talhaoId}');
            print('   Cultura procurada: ${widget.culturaId}');
            print('═══════════════════════════════════════════════');
          }
        } catch (e, stackTrace) {
          print('❌ ERRO ao carregar dados de estande: $e');
          print('Stack trace: $stackTrace');
          print('═══════════════════════════════════════════════');
        }
        
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_plantio == null) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.warning_outlined,
                color: Colors.orange.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plantio não encontrado',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Não foi possível carregar informações do plantio para este talhão e cultura.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Calcular DAP baseado no estande real se disponível, senão usar data do plantio
    int diasPlantio;
    if (_estandeReal != null && _estandeReal!.diasAposEmergencia != null) {
      diasPlantio = _estandeReal!.diasAposEmergencia!;
    } else {
      diasPlantio = DateTime.now().difference(_plantio!.dataPlantio).inDays;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informações do Plantio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getSourceColor(_plantio!.fonte),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getSourceLabel(_plantio!.fonte),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: 'Data do Plantio',
                    value: dateFormat.format(_plantio!.dataPlantio),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.access_time,
                    label: 'Dias Após Plantio',
                    value: '$diasPlantio DAP',
                    color: _getDapColor(diasPlantio),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.eco,
                    label: 'Variedade',
                    value: _plantio!.variedadeId ?? 'Não definida',
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.straighten,
                    label: 'Espaçamento',
                    value: '${_plantio!.espacamento.toStringAsFixed(0)} cm',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // População
            _buildPopulacaoSection(),
            const SizedBox(height: 12),
            // Profundidade - só mostrar se foi informada (por enquanto não temos esse campo)
            // TODO: Adicionar campo profundidadeSementes no EstandePlantasModel
            if (_plantio!.observacoes != null && _plantio!.observacoes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Observações',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _plantio!.observacoes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_plantio!.historicos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_plantio!.historicos.length} registro(s) no histórico de plantio',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPopulacaoSection() {
    if (_estandeReal != null && _estandeReal!.plantasPorHectare != null) {
      // Tem estande real - mostrar população real e eficiência
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.eco_outlined,
                  label: 'Pop. Planejada',
                  value: _formatPopulation(_plantio!.populacao),
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItemDestaque(
                  icon: Icons.grass,
                  label: 'Pop. Real',
                  value: _formatPopulation(_estandeReal!.plantasPorHectare!.toInt()),
                  color: Colors.green,
                  isDestaque: true,
                ),
              ),
            ],
          ),
          if (_estandeReal!.eficiencia != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.check_circle_outline,
                    label: 'Eficiência',
                    value: '${_estandeReal!.eficiencia!.toStringAsFixed(1)}%',
                    color: _getEficienciaColor(_estandeReal!.eficiencia!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.straighten,
                    label: 'Plantas/Metro',
                    value: '${_estandeReal!.plantasPorMetro?.toStringAsFixed(1) ?? '0.0'}',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    } else {
      // ❌ SEM ESTANDE - NÃO mostrar população fictícia!
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'População não disponível',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Registre o estande de plantas para ver a população real',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItemDestaque({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isDestaque = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
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
      ),
    );
  }

  Color _getEficienciaColor(double eficiencia) {
    if (eficiencia >= 90) return Colors.green;
    if (eficiencia >= 75) return Colors.lightGreen;
    if (eficiencia >= 60) return Colors.orange;
    return Colors.red;
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
        return 'TABELA PRINCIPAL';
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
      return '${(populacao / 1000).toStringAsFixed(1)}k plantas/ha';
    }
    return '$populacao plantas/ha';
  }
}
