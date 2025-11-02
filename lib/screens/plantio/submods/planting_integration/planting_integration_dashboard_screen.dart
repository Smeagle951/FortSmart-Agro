import 'package:flutter/material.dart';
import '../../../../models/planting_cv_model.dart';
import '../../../../models/planting_stand_model.dart';
import '../../../../models/planting_integration_model.dart';
import '../../../../services/planting_ai_integration_service.dart';
import '../../../../utils/logger.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/loading_widget.dart';
import '../planting_cv/planting_cv_calculation_screen.dart';
import 'widgets/integration_analysis_card.dart';
import 'widgets/ai_diagnosis_card.dart';
import 'widgets/recommendations_card.dart';

/// Dashboard para análise integrada de CV% + Estande com IA
class PlantingIntegrationDashboardScreen extends StatefulWidget {
  final String talhaoId;
  final String talhaoNome;
  final String culturaId;
  final String culturaNome;
  final PlantingCVModel? cvPlantio;
  final PlantingStandModel? estandePlantas;

  const PlantingIntegrationDashboardScreen({
    Key? key,
    required this.talhaoId,
    required this.talhaoNome,
    required this.culturaId,
    required this.culturaNome,
    this.cvPlantio,
    this.estandePlantas,
  }) : super(key: key);

  @override
  State<PlantingIntegrationDashboardScreen> createState() => _PlantingIntegrationDashboardScreenState();
}

class _PlantingIntegrationDashboardScreenState extends State<PlantingIntegrationDashboardScreen> {
  final _aiIntegrationService = PlantingAIIntegrationService();
  
  bool _isLoading = false;
  PlantingIntegrationModel? _integracao;
  Map<String, dynamic>? _riscosFuturos;

  @override
  void initState() {
    super.initState();
    _analisarIntegracao();
  }

  /// Analisa a integração entre CV% e Estande usando IA
  Future<void> _analisarIntegracao() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('🤖 Iniciando análise de integração com IA');

      final integracao = await _aiIntegrationService.analisarIntegracaoComIA(
        cvPlantio: widget.cvPlantio,
        estandePlantas: widget.estandePlantas,
        talhaoId: widget.talhaoId,
        talhaoNome: widget.talhaoNome,
        culturaId: widget.culturaId,
        culturaNome: widget.culturaNome,
      );

      // Predizer riscos futuros
      final riscosFuturos = await _aiIntegrationService.predizerRiscosFuturos(
        integracao: integracao,
        condicoesClimaticas: {
          'temperatura': 25.0,
          'umidade': 70.0,
          'precipitacao': 15.0,
        },
      );

      setState(() {
        _integracao = integracao;
        _riscosFuturos = riscosFuturos;
        _isLoading = false;
      });

      Logger.info('✅ Análise de integração concluída');

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      Logger.error('❌ Erro na análise de integração: $e');
      _mostrarErro('Erro na análise: ${e.toString()}');
    }
  }

  /// Mostra mensagem de erro
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Navega para tela de cálculo de CV%
  Future<void> _navegarParaCV() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantingCVCalculationScreen(
          talhaoId: widget.talhaoId,
          talhaoNome: widget.talhaoNome,
          culturaId: widget.culturaId,
          culturaNome: widget.culturaNome,
        ),
      ),
    );

    if (resultado != null && resultado is PlantingCVModel) {
      // Atualizar dados e reanalisar
      setState(() {
        // TODO: Atualizar cvPlantio com o resultado
      });
      _analisarIntegracao();
    }
  }

  /// Navega para tela de registro de estande
  Future<void> _navegarParaEstande() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantingStandRegistrationScreen(
          talhaoId: widget.talhaoId,
          talhaoNome: widget.talhaoNome,
          culturaId: widget.culturaId,
          culturaNome: widget.culturaNome,
        ),
      ),
    );

    if (resultado != null && resultado is PlantingStandModel) {
      // Atualizar dados e reanalisar
      setState(() {
        // TODO: Atualizar estandePlantas com o resultado
      });
      _analisarIntegracao();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Análise Integrada - ${widget.talhaoNome}',
        subtitle: widget.culturaNome,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _analisarIntegracao,
            tooltip: 'Atualizar análise',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status dos dados
                  _buildDataStatusCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Análise de integração
                  if (_integracao != null) ...[
                    IntegrationAnalysisCard(integracao: _integracao!),
                    
                    const SizedBox(height: 16),
                    
                    // Diagnóstico da IA
                    AIDiagnosisCard(
                      diagnostico: _integracao!.diagnosticoIA,
                      analise: _integracao!.analiseIntegracao,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Recomendações
                    RecommendationsCard(
                      recomendacoes: _integracao!.recomendacoes,
                      nivelPrioridade: _integracao!.nivelPrioridade,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Riscos futuros
                    if (_riscosFuturos != null && _riscosFuturos!.isNotEmpty)
                      _buildRisksCard(),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Botões de ação
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  /// Constrói card de status dos dados
  Widget _buildDataStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status dos Dados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildDataStatusItem(
                    'CV% do Plantio',
                    widget.cvPlantio != null,
                    widget.cvPlantio?.coeficienteVariacao.toStringAsFixed(1) ?? 'N/A',
                    '%',
                    Icons.straighten,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDataStatusItem(
                    'Estande de Plantas',
                    widget.estandePlantas != null,
                    widget.estandePlantas?.populacaoRealPorHectare.toStringAsFixed(0) ?? 'N/A',
                    'plantas/ha',
                    Icons.eco,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói item de status dos dados
  Widget _buildDataStatusItem(
    String title,
    bool disponivel,
    String valor,
    String unidade,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: disponivel ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: disponivel ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: disponivel ? Colors.green[600] : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: disponivel ? Colors.green[700] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: disponivel ? Colors.green[700] : Colors.grey[600],
            ),
          ),
          Text(
            unidade,
            style: TextStyle(
              fontSize: 10,
              color: disponivel ? Colors.green[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói card de riscos futuros
  Widget _buildRisksCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'Riscos Futuros Identificados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._riscosFuturos!.entries.map((entry) {
              final risco = entry.value as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            risco['nivel']?.toString().toUpperCase() ?? 'MEDIO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(risco['probabilidade'] * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      risco['descricao'] ?? 'Risco identificado',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Constrói botões de ação
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: widget.cvPlantio != null ? 'Atualizar CV%' : 'Calcular CV%',
                onPressed: _navegarParaCV,
                icon: Icons.straighten,
                variant: widget.cvPlantio != null ? ButtonVariant.secondary : ButtonVariant.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: widget.estandePlantas != null ? 'Atualizar Estande' : 'Registrar Estande',
                onPressed: _navegarParaEstande,
                icon: Icons.eco,
                variant: widget.estandePlantas != null ? ButtonVariant.secondary : ButtonVariant.primary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (_integracao != null)
          CustomButton(
            text: 'Salvar Análise',
            onPressed: () {
              // TODO: Implementar salvamento
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Análise salva com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: Icons.save,
            variant: ButtonVariant.secondary,
          ),
      ],
    );
  }
}
