import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/fortsmart_theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../services/data_cache_service.dart';
import '../../database/repositories/historico_plantio_repository.dart';
import '../../database/repositories/aplicacao_repository.dart';
import '../../database/repositories/colheita_repository.dart';

/// Relatório de Custos por Hectare
/// Análise detalhada dos custos de produção por hectare
class CostPerHectareReportScreen extends StatefulWidget {
  const CostPerHectareReportScreen({Key? key}) : super(key: key);

  @override
  State<CostPerHectareReportScreen> createState() => _CostPerHectareReportScreenState();
}

class _CostPerHectareReportScreenState extends State<CostPerHectareReportScreen> {
  final DataCacheService _dataCacheService = DataCacheService();
  final HistoricoPlantioRepository _plantioRepo = HistoricoPlantioRepository();
  final AplicacaoRepository _aplicacaoRepo = AplicacaoRepository();
  final ColheitaRepository _colheitaRepo = ColheitaRepository();
  
  String? _selectedSafra;
  List<Map<String, dynamic>> _safras = [];
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSafras();
  }

  Future<void> _loadSafras() async {
    try {
      final safras = await _dataCacheService.getSafras();
      setState(() {
        _safras = safras.map((s) => {
          'id': s.id.toString(),
          'nome': s.nomeSafra,
          'ano': s.anoSafra,
        }).toList();
        if (_safras.isNotEmpty) {
          _selectedSafra = _safras.first['id'];
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar safras: $e')),
      );
    }
  }

  Future<void> _generateReport() async {
    if (_selectedSafra == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Buscar dados da safra
      final plantios = await _plantioRepo.getPlantiosBySafra(_selectedSafra!);
      final aplicacoes = await _aplicacaoRepo.getAplicacoesBySafra(_selectedSafra!);
      final colheitas = await _colheitaRepo.getColheitasBySafra(_selectedSafra!);

      // Calcular custos por hectare
      final totalHectares = plantios.fold<double>(0, (sum, p) => sum + (p['area'] ?? 0.0));
      
      // Custos de plantio
      final custoPlantio = plantios.fold<double>(0, (sum, p) => sum + (p['custo'] ?? 0.0));
      final custoPlantioPorHectare = totalHectares > 0 ? custoPlantio / totalHectares : 0.0;
      
      // Custos de aplicação
      final custoAplicacao = aplicacoes.fold<double>(0, (sum, a) => sum + (a['custo'] ?? 0.0));
      final custoAplicacaoPorHectare = totalHectares > 0 ? custoAplicacao / totalHectares : 0.0;
      
      // Custo total
      final custoTotal = custoPlantio + custoAplicacao;
      final custoTotalPorHectare = totalHectares > 0 ? custoTotal / totalHectares : 0.0;
      
      // Receita e lucro
      final receitaTotal = colheitas.fold<double>(0, (sum, c) => sum + (c['receita'] ?? 0.0));
      final receitaPorHectare = totalHectares > 0 ? receitaTotal / totalHectares : 0.0;
      final lucroPorHectare = receitaPorHectare - custoTotalPorHectare;
      
      // Análise por talhão
      final analisePorTalhao = <Map<String, dynamic>>[];
      for (final plantio in plantios) {
        final talhaoId = plantio['talhaoId']?.toString();
        final area = plantio['area'] ?? 0.0;
        final custo = plantio['custo'] ?? 0.0;
        
        // Buscar aplicações do talhão
        final aplicacoesTalhao = aplicacoes.where((a) => a['talhaoId']?.toString() == talhaoId).toList();
        final custoAplicacaoTalhao = aplicacoesTalhao.fold<double>(0, (sum, a) => sum + (a['custo'] ?? 0.0));
        
        // Buscar colheitas do talhão
        final colheitasTalhao = colheitas.where((c) => c['talhaoId']?.toString() == talhaoId).toList();
        final receitaTalhao = colheitasTalhao.fold<double>(0, (sum, c) => sum + (c['receita'] ?? 0.0));
        
        final custoTotalTalhao = custo + custoAplicacaoTalhao;
        final custoPorHectareTalhao = area > 0 ? custoTotalTalhao / area : 0.0;
        final receitaPorHectareTalhao = area > 0 ? receitaTalhao / area : 0.0;
        final lucroPorHectareTalhao = receitaPorHectareTalhao - custoPorHectareTalhao;
        
        analisePorTalhao.add({
          'talhaoId': talhaoId,
          'talhaoNome': plantio['talhaoNome'] ?? 'Talhão sem nome',
          'area': area,
          'custoTotal': custoTotalTalhao,
          'custoPorHectare': custoPorHectareTalhao,
          'receitaTotal': receitaTalhao,
          'receitaPorHectare': receitaPorHectareTalhao,
          'lucroPorHectare': lucroPorHectareTalhao,
          'plantios': 1,
          'aplicacoes': aplicacoesTalhao.length,
          'colheitas': colheitasTalhao.length,
        });
      }

      setState(() {
        _reportData = {
          'safra': _safras.firstWhere((s) => s['id'] == _selectedSafra),
          'resumo': {
            'totalHectares': totalHectares,
            'custoTotal': custoTotal,
            'custoTotalPorHectare': custoTotalPorHectare,
            'custoPlantioPorHectare': custoPlantioPorHectare,
            'custoAplicacaoPorHectare': custoAplicacaoPorHectare,
            'receitaTotal': receitaTotal,
            'receitaPorHectare': receitaPorHectare,
            'lucroPorHectare': lucroPorHectare,
            'margemLucro': receitaTotal > 0 ? ((receitaTotal - custoTotal) / receitaTotal) * 100 : 0.0,
          },
          'analisePorTalhao': analisePorTalhao,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar relatório: $e')),
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
      appBar: AppBarWidget(
        title: 'Custos por Hectare',
        showBackButton: true,
        backgroundColor: FortSmartTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSafraSelector(),
            const SizedBox(height: 24),
            if (_reportData != null) ...[
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildCostBreakdown(),
              const SizedBox(height: 24),
              _buildTalhaoAnalysis(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FortSmartTheme.primaryColor, FortSmartTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análise de Custos por Hectare',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Análise detalhada dos custos de produção',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafraSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecionar Safra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: FortSmartTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSafra,
              decoration: InputDecoration(
                labelText: 'Safra',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _safras.map((safra) {
                return DropdownMenuItem<String>(
                  value: safra['id'],
                  child: Text('${safra['nome']} - ${safra['ano']}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSafra = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                icon: _isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.analytics),
                label: Text(_isLoading ? 'Gerando...' : 'Gerar Análise'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FortSmartTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final resumo = _reportData!['resumo'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo Financeiro',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FortSmartTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildSummaryCard(
              'Custo Total/ha',
              'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(resumo['custoTotalPorHectare'])}',
              Icons.attach_money,
              Colors.red,
            ),
            _buildSummaryCard(
              'Receita/ha',
              'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(resumo['receitaPorHectare'])}',
              Icons.trending_up,
              Colors.green,
            ),
            _buildSummaryCard(
              'Lucro/ha',
              'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(resumo['lucroPorHectare'])}',
              Icons.account_balance_wallet,
              resumo['lucroPorHectare'] >= 0 ? Colors.green : Colors.red,
            ),
            _buildSummaryCard(
              'Margem',
              '${NumberFormat('#,##0.0', 'pt_BR').format(resumo['margemLucro'])}%',
              Icons.percent,
              resumo['margemLucro'] >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final resumo = _reportData!['resumo'] as Map<String, dynamic>;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Composição dos Custos por Hectare',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: FortSmartTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildCostItem(
              'Plantio',
              resumo['custoPlantioPorHectare'],
              Colors.brown,
              Icons.grass,
            ),
            _buildCostItem(
              'Aplicações',
              resumo['custoAplicacaoPorHectare'],
              Colors.blue,
              Icons.local_drink,
            ),
            const Divider(),
            _buildCostItem(
              'Total',
              resumo['custoTotalPorHectare'],
              Colors.red,
              Icons.attach_money,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostItem(String title, double value, Color color, IconData icon, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(value)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTalhaoAnalysis() {
    final analisePorTalhao = _reportData!['analisePorTalhao'] as List<Map<String, dynamic>>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análise por Talhão',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FortSmartTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ...analisePorTalhao.map((talhao) => _buildTalhaoCard(talhao)),
      ],
    );
  }

  Widget _buildTalhaoCard(Map<String, dynamic> talhao) {
    final lucro = talhao['lucroPorHectare'] as double;
    final isLucrativo = lucro >= 0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.landscape,
                  color: FortSmartTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    talhao['talhaoNome'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLucrativo ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isLucrativo ? 'Lucrativo' : 'Prejuízo',
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
                Expanded(
                  child: _buildTalhaoMetric(
                    'Área',
                    '${NumberFormat('#,##0.0', 'pt_BR').format(talhao['area'])} ha',
                    Icons.landscape,
                  ),
                ),
                Expanded(
                  child: _buildTalhaoMetric(
                    'Custo/ha',
                    'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(talhao['custoPorHectare'])}',
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTalhaoMetric(
                    'Receita/ha',
                    'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(talhao['receitaPorHectare'])}',
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildTalhaoMetric(
                    'Lucro/ha',
                    'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(talhao['lucroPorHectare'])}',
                    Icons.account_balance_wallet,
                    color: isLucrativo ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTalhaoMetric(String label, String value, IconData icon, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implementar exportação para PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade de exportação em desenvolvimento')),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implementar compartilhamento
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidade de compartilhamento em desenvolvimento')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FortSmartTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
