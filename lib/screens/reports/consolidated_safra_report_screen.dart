import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/fortsmart_theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../services/data_cache_service.dart';
import '../../database/repositories/historico_plantio_repository.dart';
import '../../database/repositories/aplicacao_repository.dart';
import '../../database/repositories/colheita_repository.dart';

/// Relatório Consolidado da Safra
/// Visão completa de todas as operações realizadas na safra
class ConsolidatedSafraReportScreen extends StatefulWidget {
  const ConsolidatedSafraReportScreen({Key? key}) : super(key: key);

  @override
  State<ConsolidatedSafraReportScreen> createState() => _ConsolidatedSafraReportScreenState();
}

class _ConsolidatedSafraReportScreenState extends State<ConsolidatedSafraReportScreen> {
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
      // Buscar dados consolidados da safra
      final plantios = await _plantioRepo.getPlantiosBySafra(_selectedSafra!);
      final aplicacoes = await _aplicacaoRepo.getAplicacoesBySafra(_selectedSafra!);
      final colheitas = await _colheitaRepo.getColheitasBySafra(_selectedSafra!);

      // Calcular estatísticas
      final totalHectares = plantios.fold<double>(0, (sum, p) => sum + (p['area'] ?? 0.0));
      final totalPlantios = plantios.length;
      final totalAplicacoes = aplicacoes.length;
      final totalColheitas = colheitas.length;

      // Calcular custos
      final custoPlantio = plantios.fold<double>(0, (sum, p) => sum + (p['custo'] ?? 0.0));
      final custoAplicacao = aplicacoes.fold<double>(0, (sum, a) => sum + (a['custo'] ?? 0.0));
      final custoTotal = custoPlantio + custoAplicacao;

      // Calcular produtividade
      final producaoTotal = colheitas.fold<double>(0, (sum, c) => sum + (c['producao'] ?? 0.0));
      final produtividade = totalHectares > 0 ? producaoTotal / totalHectares : 0.0;

      setState(() {
        _reportData = {
          'safra': _safras.firstWhere((s) => s['id'] == _selectedSafra),
          'resumo': {
            'totalHectares': totalHectares,
            'totalPlantios': totalPlantios,
            'totalAplicacoes': totalAplicacoes,
            'totalColheitas': totalColheitas,
            'custoTotal': custoTotal,
            'producaoTotal': producaoTotal,
            'produtividade': produtividade,
          },
          'plantios': plantios,
          'aplicacoes': aplicacoes,
          'colheitas': colheitas,
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
        title: 'Relatório Consolidado da Safra',
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
              _buildDetailedSections(),
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
                Icons.analytics,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relatório Consolidado da Safra',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Visão completa de todas as operações realizadas',
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
                label: Text(_isLoading ? 'Gerando...' : 'Gerar Relatório'),
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
          'Resumo da Safra',
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
              'Área Total',
              '${NumberFormat('#,##0.0', 'pt_BR').format(resumo['totalHectares'])} ha',
              Icons.landscape,
              FortSmartTheme.successColor,
            ),
            _buildSummaryCard(
              'Plantios',
              '${resumo['totalPlantios']}',
              Icons.grass,
              Colors.brown,
            ),
            _buildSummaryCard(
              'Aplicações',
              '${resumo['totalAplicacoes']}',
              Icons.local_drink,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Colheitas',
              '${resumo['totalColheitas']}',
              Icons.agriculture,
              Colors.amber,
            ),
            _buildSummaryCard(
              'Custo Total',
              'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(resumo['custoTotal'])}',
              Icons.attach_money,
              Colors.red,
            ),
            _buildSummaryCard(
              'Produtividade',
              '${NumberFormat('#,##0.0', 'pt_BR').format(resumo['produtividade'])} kg/ha',
              Icons.trending_up,
              FortSmartTheme.accentColor,
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
                fontSize: 18,
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

  Widget _buildDetailedSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalhamento por Operação',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FortSmartTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildOperationSection(
          'Plantios',
          _reportData!['plantios'] as List,
          Icons.grass,
          Colors.brown,
        ),
        const SizedBox(height: 16),
        _buildOperationSection(
          'Aplicações',
          _reportData!['aplicacoes'] as List,
          Icons.local_drink,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildOperationSection(
          'Colheitas',
          _reportData!['colheitas'] as List,
          Icons.agriculture,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildOperationSection(String title, List<dynamic> data, IconData icon, Color color) {
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
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${data.length} registros',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (data.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...data.take(3).map((item) => _buildOperationItem(item, color)),
              if (data.length > 3)
                Text(
                  '... e mais ${data.length - 3} registros',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Nenhum registro encontrado',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOperationItem(Map<String, dynamic> item, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item['nome'] ?? item['descricao'] ?? 'Registro sem nome',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (item['data'] != null)
            Text(
              DateFormat('dd/MM/yyyy').format(DateTime.parse(item['data'])),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
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
