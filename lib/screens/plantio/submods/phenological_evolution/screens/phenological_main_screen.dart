/// 📊 Screen: Dashboard Principal de Evolução Fenológica
/// 
/// Tela principal do submódulo com visão geral dos indicadores,
/// gráficos de evolução e alertas ativos.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/phenological_record_model.dart';
import '../models/phenological_alert_model.dart';
import '../providers/phenological_provider.dart';
import '../services/phenological_classification_service.dart';
import '../services/growth_analysis_service.dart';
import '../services/productivity_estimation_service.dart';
import '../widgets/growth_indicators_widget.dart';
import '../widgets/plantio_selection_widget.dart';
import '../widgets/plantio_info_widget.dart';
import 'phenological_record_screen.dart';
import 'phenological_history_screen.dart';
import 'package:fortsmart_agro/modules/planting/repositories/plantio_repository.dart';
import 'package:fortsmart_agro/modules/planting/models/plantio_model.dart';
import 'package:fortsmart_agro/services/plantio_integration_service.dart';
import 'package:fortsmart_agro/services/data_cache_service.dart';
import 'package:fortsmart_agro/models/agricultural_product.dart';
import 'package:fortsmart_agro/providers/talhao_provider.dart';

class PhenologicalMainScreen extends StatefulWidget {
  final String? talhaoId;
  final String? culturaId;
  final String? talhaoNome;
  final String? culturaNome;

  const PhenologicalMainScreen({
    Key? key,
    this.talhaoId,
    this.culturaId,
    this.talhaoNome,
    this.culturaNome,
  }) : super(key: key);

  @override
  State<PhenologicalMainScreen> createState() => _PhenologicalMainScreenState();
}

class _PhenologicalMainScreenState extends State<PhenologicalMainScreen> {
  bool _isLoading = true;
  PhenologicalRecordModel? _ultimoRegistro;
  List<PhenologicalRecordModel> _historico = [];
  List<PhenologicalAlertModel> _alertas = [];
  List<PlantioModel> _plantiosDisponiveis = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<PhenologicalProvider>(context, listen: false);
      await provider.inicializar();

      // Se não há talhão/cultura selecionados, carregar lista de plantios disponíveis
      if (widget.talhaoId == null || widget.culturaId == null) {
        print('📋 Nenhum talhão/cultura selecionado - carregando plantios disponíveis...');
        await _carregarPlantiosDisponiveis();
        setState(() => _isLoading = false);
        return;
      }

      // Carregar dados específicos do talhão/cultura
      await provider.carregarRegistros(widget.talhaoId!, widget.culturaId!);
      await provider.carregarAlertas(widget.talhaoId!, widget.culturaId!);

      _ultimoRegistro = await provider.buscarUltimoRegistro(
        widget.talhaoId!,
        widget.culturaId!,
      );

      _historico = await provider.obterRegistrosParaGraficos(
        widget.talhaoId!,
        widget.culturaId!,
      );

      _alertas = provider.alertasAtivos;

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      setState(() => _isLoading = false);
    }
  }

  // Armazena os plantios integrados completos (com talhaoNome)
  List<PlantioIntegrado> _plantiosIntegrados = [];

  /// Carrega plantios disponíveis usando o serviço de integração
  Future<void> _carregarPlantiosDisponiveis() async {
    try {
      print('🔄 EVOLUÇÃO FENOLÓGICA: Carregando plantios integrados...');
      print('🔍 PARÂMETROS: talhaoId=${widget.talhaoId}, culturaId=${widget.culturaId}');
      
      // Usar o serviço de integração para buscar todos os plantios
      final integrationService = PlantioIntegrationService();
      
      print('📞 Chamando buscarPlantiosParaEvolucaoFenologica...');
      _plantiosIntegrados = await integrationService.buscarPlantiosParaEvolucaoFenologica(
        widget.talhaoId, 
        widget.culturaId
      );
      
      print('📦 Retornado: ${_plantiosIntegrados.length} plantios integrados do serviço');
      
      // Converter para PlantioModel para compatibilidade
      _plantiosDisponiveis = _plantiosIntegrados.map((p) => p.toPlantioModel()).toList();
      
      print('📋 EVOLUÇÃO FENOLÓGICA: ${_plantiosDisponiveis.length} plantios integrados encontrados');
      
      if (_plantiosDisponiveis.isNotEmpty) {
        print('✅ EVOLUÇÃO FENOLÓGICA: Plantios integrados encontrados:');
        for (int i = 0; i < _plantiosDisponiveis.length; i++) {
          final plantio = _plantiosDisponiveis[i];
          final integrado = _plantiosIntegrados[i];
          print('  📍 ${i + 1}. Cultura: ${plantio.culturaId}');
          print('     Talhão ID: ${plantio.talhaoId}');
          print('     Talhão Nome: ${integrado.talhaoNome}');
          print('     Data: ${plantio.dataPlantio}');
          print('     Variedade: ${plantio.variedadeId ?? "Não definida"}');
          print('     Fonte: ${integrado.fonte}');
          print('     Históricos: ${integrado.historicos.length}');
          print('     ---');
        }
      } else {
        print('⚠️ EVOLUÇÃO FENOLÓGICA: Nenhum plantio encontrado');
        _errorMessage = 'Nenhum plantio encontrado. Crie um plantio no submódulo "Novo Plantio" primeiro.';
      }
      
    } catch (e, stackTrace) {
      print('❌ EVOLUÇÃO FENOLÓGICA: Erro ao carregar plantios integrados: $e');
      print('Stack trace: $stackTrace');
      _errorMessage = 'Erro ao carregar plantios: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Evolução Fenológica'),
            if (widget.talhaoNome != null)
              Text(
                'Talhão ${widget.talhaoNome}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _abrirHistorico(),
            tooltip: 'Histórico Completo',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _carregarDados(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: _buildDashboard(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _novoRegistro(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Registro'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildDashboard() {
    if (widget.talhaoId == null || widget.culturaId == null) {
      return _buildPlantioSelection();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informações do Plantio Integrado
          PlantioInfoWidget(
            talhaoId: widget.talhaoId!,
            culturaId: widget.culturaId!,
          ),
          const SizedBox(height: 16),

          // Alertas Críticos
          if (_alertas.isNotEmpty) ...[
            _buildAlertasCriticos(),
            const SizedBox(height: 16),
          ],

          // Status Atual
          if (_ultimoRegistro != null) ...[
            _buildStatusAtual(),
            const SizedBox(height: 16),
          ],

          // Indicadores Principais
          _buildIndicadoresPrincipais(),
          const SizedBox(height: 16),

          // Indicadores de Crescimento Avançados
          if (_ultimoRegistro != null && _historico.isNotEmpty) ...[
            _buildIndicadoresCrescimento(),
            const SizedBox(height: 16),
          ],

          // Gráfico de Evolução (Placeholder)
          _buildGraficoEvolucao(),
          const SizedBox(height: 16),

          // Recomendações
          if (_ultimoRegistro != null) ...[
            _buildRecomendacoes(),
            const SizedBox(height: 80), // Espaço para o FAB
          ],
        ],
      ),
    );
  }

  Widget _buildAlertasCriticos() {
    final alertasCriticos = _alertas
        .where((a) => a.severidade == AlertSeverity.critica || 
                     a.severidade == AlertSeverity.alta)
        .toList();

    if (alertasCriticos.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  '${alertasCriticos.length} Alerta(s) Crítico(s)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alertasCriticos.take(3).map((alerta) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(alerta.icone, size: 20, color: alerta.cor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alerta.titulo,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
            if (alertasCriticos.length > 3)
              TextButton(
                onPressed: () {
                  // TODO: Abrir tela de alertas
                },
                child: Text('Ver todos os ${alertasCriticos.length} alertas'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAtual() {
    final estagio = PhenologicalClassificationService.classificarEstagio(
      registro: _ultimoRegistro!,
      cultura: widget.culturaNome ?? '',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Atual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Estágio Fenológico',
                    estagio?.codigo ?? 'N/A',
                    estagio?.nome ?? 'Não identificado',
                    estagio?.icone ?? Icons.help_outline,
                    estagio?.cor ?? Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'DAE',
                    '${_ultimoRegistro!.diasAposEmergencia}',
                    'dias após emergência',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIndicadoresPrincipais() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indicadores Principais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_ultimoRegistro != null) ...[
              _buildIndicador(
                'Altura Média',
                _ultimoRegistro!.alturaCm != null
                    ? '${_ultimoRegistro!.alturaCm!.toStringAsFixed(1)} cm'
                    : 'N/A',
                Icons.height,
                Colors.green,
              ),
              const Divider(),
              _buildIndicador(
                'Estande',
                _ultimoRegistro!.estandePlantas != null
                    ? '${(_ultimoRegistro!.estandePlantas! / 1000).toStringAsFixed(0)}k plantas/ha'
                    : 'N/A',
                Icons.people,
                Colors.blue,
              ),
              const Divider(),
              _buildIndicador(
                'Sanidade',
                _ultimoRegistro!.percentualSanidade != null
                    ? '${_ultimoRegistro!.percentualSanidade!.toStringAsFixed(1)}%'
                    : 'N/A',
                Icons.healing,
                _getSanidadeColor(_ultimoRegistro!.percentualSanidade),
              ),
              if (_ultimoRegistro!.vagensPlanta != null) ...[
                const Divider(),
                _buildIndicador(
                  'Vagens/Planta',
                  '${_ultimoRegistro!.vagensPlanta!.toStringAsFixed(1)}',
                  Icons.local_florist,
                  Colors.purple,
                ),
              ],
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Nenhum registro encontrado'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicador(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoEvolucao() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolução de Crescimento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Placeholder para gráfico
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Gráfico de evolução será exibido aqui',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_historico.length >= 2)
              Text(
                GrowthAnalysisService.analisarTendencia(_historico),
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecomendacoes() {
    final estagio = PhenologicalClassificationService.classificarEstagio(
      registro: _ultimoRegistro!,
      cultura: widget.culturaNome ?? '',
    );

    if (estagio == null || estagio.recomendacoes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Recomendações Agronômicas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...estagio.recomendacoes.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Plantios Disponíveis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_plantiosDisponiveis.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _plantiosDisponiveis.length,
                  itemBuilder: (context, index) {
                    final plantio = _plantiosDisponiveis[index];
                    final plantioIntegrado = _plantiosIntegrados[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(Icons.agriculture, color: Colors.teal.shade700),
                        ),
                             title: Text(
                               plantio.culturaId ?? 'Cultura não definida',
                               style: const TextStyle(fontWeight: FontWeight.bold),
                             ),
                             subtitle: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text('Talhão: ${plantioIntegrado.talhaoNome}'),
                                 Text('Plantio: ${plantio.dataPlantio}'),
                                 if (plantio.variedadeId != null)
                                   Text('Variedade: ${plantio.variedadeId}'),
                               ],
                             ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navegar para evolução fenológica deste plantio
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                 builder: (context) => PhenologicalMainScreen(
                                   talhaoId: plantio.talhaoId,
                                   culturaId: plantio.culturaId,
                                   talhaoNome: plantioIntegrado.talhaoNome,
                                   culturaNome: plantio.culturaId,
                                 ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Text(
                'Crie plantios no submódulo "Novo Plantio" para acompanhar a evolução fenológica.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Criar Novo Plantio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSanidadeColor(double? sanidade) {
    if (sanidade == null) return Colors.grey;
    if (sanidade >= 90) return Colors.green;
    if (sanidade >= 80) return Colors.lightGreen;
    if (sanidade >= 70) return Colors.orange;
    return Colors.red;
  }

  void _novoRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhenologicalRecordScreen(
          talhaoId: widget.talhaoId,
          culturaId: widget.culturaId,
          talhaoNome: widget.talhaoNome,
          culturaNome: widget.culturaNome,
        ),
      ),
    ).then((_) => _carregarDados());
  }

  void _abrirHistorico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhenologicalHistoryScreen(
          talhaoId: widget.talhaoId ?? '',
          culturaId: widget.culturaId ?? '',
          talhaoNome: widget.talhaoNome,
          culturaNome: widget.culturaNome,
        ),
      ),
    );
  }
  
  /// Constrói seção de indicadores de crescimento avançados
  Widget _buildIndicadoresCrescimento() {
    if (_ultimoRegistro == null || _historico.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return GrowthIndicatorsWidget(
      registro: _ultimoRegistro!,
      cultura: widget.culturaId ?? 'soja',
      historico: _historico,
    );
  }

  /// Constrói widget de seleção de plantios
  Widget _buildPlantioSelection() {
    return PlantioSelectionWidget(
      talhaoId: widget.talhaoId,
      culturaId: widget.culturaId,
      onPlantioSelected: (plantio) async {
        // Buscar o PlantioIntegrado correspondente para obter o talhaoNome
        final integrationService = PlantioIntegrationService();
        final plantiosIntegrados = await integrationService.buscarPlantiosParaEvolucaoFenologica(
          plantio.talhaoId,
          plantio.culturaId,
        );
        
        String talhaoNome = 'Talhão ${plantio.talhaoId}'; // Fallback
        if (plantiosIntegrados.isNotEmpty) {
          talhaoNome = plantiosIntegrados.first.talhaoNome;
        }
        
        // Navegar para a evolução fenológica do plantio selecionado
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PhenologicalMainScreen(
              talhaoId: plantio.talhaoId,
              culturaId: plantio.culturaId,
              talhaoNome: talhaoNome,
              culturaNome: plantio.culturaId,
            ),
          ),
        );
      },
    );
  }
}

