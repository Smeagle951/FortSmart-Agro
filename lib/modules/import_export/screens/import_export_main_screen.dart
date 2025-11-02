import 'package:flutter/material.dart';

import '../services/import_export_service.dart';
import '../../../constants/app_colors.dart';
import 'export_screen.dart';
import 'import_screen.dart';
import 'export_agricultural_machines_screen.dart';

class ImportExportMainScreen extends StatefulWidget {
  const ImportExportMainScreen({Key? key}) : super(key: key);

  @override
  State<ImportExportMainScreen> createState() => _ImportExportMainScreenState();
}

class _ImportExportMainScreenState extends State<ImportExportMainScreen> {
  final ImportExportService _service = ImportExportService();
  
  // Estado de carregamento
  bool _isLoading = false;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _service.getStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      // Ignorar erro de estatísticas
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar/Exportar Dados'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatisticsCards(),
                  const SizedBox(height: 24),
                  _buildMainActions(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
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
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.swap_horiz,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Importar/Exportar Dados',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gerencie a transferência de dados entre sistemas e faça backup das suas informações',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final exportStats = _statistics['exportacao'] as Map<String, dynamic>? ?? {};
    final importStats = _statistics['importacao'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estatísticas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Exportações',
                icon: Icons.file_download,
                color: Colors.blue,
                stats: [
                  StatItem('Total', exportStats['total']?.toString() ?? '0'),
                  StatItem('Últimos 30 dias', exportStats['ultimos_30_dias']?.toString() ?? '0'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Importações',
                icon: Icons.file_upload,
                color: Colors.green,
                stats: [
                  StatItem('Total', importStats['total']?.toString() ?? '0'),
                  StatItem('Registros processados', importStats['total_processados']?.toString() ?? '0'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<StatItem> stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...stats.map((stat) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stat.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Principais',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Exportar Dados',
                subtitle: 'Exporte dados em CSV, XLSX ou JSON',
                icon: Icons.file_download,
                color: Colors.blue,
                onTap: () => _navegarParaExportacao(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Importar Dados',
                subtitle: 'Importe dados de outros sistemas',
                icon: Icons.file_upload,
                color: Colors.green,
                onTap: () => _navegarParaImportacao(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Exportar para Máquinas',
                subtitle: 'Shapefile e ISOXML para monitores agrícolas',
                icon: Icons.agriculture,
                color: Colors.orange,
                onTap: () => _navegarParaExportacaoAgricola(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(), // Espaço vazio para manter layout
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickActionTile(
          title: 'Exportar Histórico de Custos',
          subtitle: 'Exporte relatórios de custos por talhão',
          icon: Icons.attach_money,
          onTap: () => _exportarCustos(),
        ),
        const SizedBox(height: 12),
        _buildQuickActionTile(
          title: 'Exportar Prescrições',
          subtitle: 'Exporte prescrições agronômicas',
          icon: Icons.medical_services,
          onTap: () => _exportarPrescricoes(),
        ),
        const SizedBox(height: 12),
        _buildQuickActionTile(
          title: 'Importar Prescrições',
          subtitle: 'Importe prescrições de outros sistemas',
          icon: Icons.upload_file,
          onTap: () => _importarPrescricoes(),
        ),
        const SizedBox(height: 12),
        _buildQuickActionTile(
          title: 'Exportar Talhões para Máquinas',
          subtitle: 'Exporte talhões em formato Shapefile/ISOXML',
          icon: Icons.agriculture,
          onTap: () => _navegarParaExportacaoAgricola(),
        ),
        const SizedBox(height: 12),
        _buildQuickActionTile(
          title: 'Limpar Jobs Antigos',
          subtitle: 'Remova jobs antigos para liberar espaço',
          icon: Icons.cleaning_services,
          onTap: () => _limparJobsAntigos(),
        ),
      ],
    );
  }

  Widget _buildQuickActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // Navegação

  void _navegarParaExportacao() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExportScreen()),
    ).then((_) => _carregarEstatisticas());
  }

  void _navegarParaImportacao() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportScreen()),
    ).then((_) => _carregarEstatisticas());
  }

  void _navegarParaExportacaoAgricola() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExportAgriculturalMachinesScreen()),
    ).then((_) => _carregarEstatisticas());
  }

  // Ações rápidas

  Future<void> _exportarCustos() async {
    try {
      final resultado = await _service.exportarDados(
        tipo: 'custos',
        formato: 'xlsx',
        filtros: {},
      );

      if (resultado['sucesso']) {
        _mostrarMensagem('Sucesso', 'Histórico de custos exportado com sucesso');
      } else {
        _mostrarMensagem('Erro', resultado['erro'] ?? 'Erro ao exportar custos');
      }
    } catch (e) {
      _mostrarMensagem('Erro', 'Erro ao exportar custos: $e');
    }
  }

  Future<void> _exportarPrescricoes() async {
    try {
      final resultado = await _service.exportarDados(
        tipo: 'prescricoes',
        formato: 'xlsx',
        filtros: {},
      );

      if (resultado['sucesso']) {
        _mostrarMensagem('Sucesso', 'Prescrições exportadas com sucesso');
      } else {
        _mostrarMensagem('Erro', resultado['erro'] ?? 'Erro ao exportar prescrições');
      }
    } catch (e) {
      _mostrarMensagem('Erro', 'Erro ao exportar prescrições: $e');
    }
  }

  void _importarPrescricoes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportScreen()),
    ).then((_) => _carregarEstatisticas());
  }

  Future<void> _limparJobsAntigos() async {
    try {
      await _service.cleanupOldJobs();
      _mostrarMensagem('Sucesso', 'Jobs antigos removidos com sucesso');
      await _carregarEstatisticas();
    } catch (e) {
      _mostrarMensagem('Erro', 'Erro ao limpar jobs antigos: $e');
    }
  }

  void _mostrarMensagem(String titulo, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$titulo: $mensagem'),
        backgroundColor: titulo == 'Erro' ? Colors.red : Colors.green,
      ),
    );
  }
}

class StatItem {
  final String label;
  final String value;

  StatItem(this.label, this.value);
}
