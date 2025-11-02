import 'package:flutter/material.dart';
import '../models/enhanced_ai_organism_data.dart';
import '../services/enhanced_ai_diagnosis_service.dart';
import '../repositories/enhanced_ai_organism_repository.dart';
import '../../../utils/logger.dart';

/// Dashboard expandido da IA com funcionalidades avançadas
class EnhancedAIDashboardScreen extends StatefulWidget {
  const EnhancedAIDashboardScreen({super.key});

  @override
  State<EnhancedAIDashboardScreen> createState() => _EnhancedAIDashboardScreenState();
}

class _EnhancedAIDashboardScreenState extends State<EnhancedAIDashboardScreen>
    with TickerProviderStateMixin {
  final EnhancedAIDiagnosisService _diagnosisService = EnhancedAIDiagnosisService();
  final EnhancedAIOrganismRepository _repository = EnhancedAIOrganismRepository();
  
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<EnhancedAIOrganismData> _recentOrganisms = [];
  List<EnhancedAIOrganismData> _featuredOrganisms = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Carrega estatísticas
      _stats = await _diagnosisService.getEnhancedStats();
      
      // Carrega organismos recentes
      _recentOrganisms = await _repository.getAllOrganisms();
      _recentOrganisms = _recentOrganisms.take(10).toList();
      
      // Carrega organismos em destaque (com dados expandidos)
      _featuredOrganisms = await _repository.getOrganismsWithPhaseData();
      _featuredOrganisms = _featuredOrganisms.take(5).toList();
      
      setState(() => _isLoading = false);
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 IA FortSmart - Dashboard Expandido'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '📊 Visão Geral', icon: Icon(Icons.dashboard)),
            Tab(text: '🔬 Diagnóstico', icon: Icon(Icons.search)),
            Tab(text: '📈 Análise', icon: Icon(Icons.analytics)),
            Tab(text: '🌱 Culturas', icon: Icon(Icons.eco)),
            Tab(text: '🦠 Organismos', icon: Icon(Icons.bug_report)),
            Tab(text: '⚙️ Configurações', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDiagnosisTab(),
                _buildAnalysisTab(),
                _buildCropsTab(),
                _buildOrganismsTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildFeaturedOrganisms(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          title: 'Total de Organismos',
          value: '${_stats['totalOrganisms'] ?? 0}',
          icon: Icons.bug_report,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Culturas Atendidas',
          value: '${_stats['culturesCount'] ?? 0}',
          icon: Icons.eco,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Com Dados de Fase',
          value: '${_stats['organismsWithPhaseData'] ?? 0}',
          icon: Icons.timeline,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Com Dados Econômicos',
          value: '${_stats['organismsWithEconomicData'] ?? 0}',
          icon: Icons.attach_money,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedOrganisms() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌟 Organismos em Destaque',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._featuredOrganisms.map((organism) => _buildOrganismTile(organism)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganismTile(EnhancedAIOrganismData organism) {
    return ListTile(
      leading: Text(organism.icone, style: const TextStyle(fontSize: 24)),
      title: Text(organism.name),
      subtitle: Text('${organism.scientificName} • ${organism.categoria}'),
      trailing: Chip(
        label: Text('${organism.fases.length} fases'),
        backgroundColor: Colors.blue[100],
      ),
      onTap: () => _showOrganismDetails(organism),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Atividade Recente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.search, color: Colors.blue),
              title: Text('Diagnóstico por sintomas realizado'),
              subtitle: Text('Soja • Lagarta-da-soja'),
              trailing: Text('2 min atrás'),
            ),
            const ListTile(
              leading: Icon(Icons.analytics, color: Colors.green),
              title: Text('Análise econômica concluída'),
              subtitle: Text('Milho • 50 hectares'),
              trailing: Text('5 min atrás'),
            ),
            const ListTile(
              leading: Icon(Icons.timeline, color: Colors.orange),
              title: Text('Diagnóstico por fase realizado'),
              subtitle: Text('Algodão • Bicudo'),
              trailing: Text('10 min atrás'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDiagnosisCard(
            title: '🔍 Diagnóstico por Sintomas',
            subtitle: 'Identifique pragas e doenças pelos sintomas observados',
            icon: Icons.search,
            color: Colors.blue,
            onTap: () => _showSymptomDiagnosis(),
          ),
          const SizedBox(height: 16),
          _buildDiagnosisCard(
            title: '📏 Diagnóstico por Tamanho',
            subtitle: 'Identifique a fase de desenvolvimento pelo tamanho',
            icon: Icons.straighten,
            color: Colors.orange,
            onTap: () => _showSizeDiagnosis(),
          ),
          const SizedBox(height: 16),
          _buildDiagnosisCard(
            title: '🌡️ Predição de Severidade',
            subtitle: 'Preveja a severidade baseada nas condições ambientais',
            icon: Icons.thermostat,
            color: Colors.red,
            onTap: () => _showSeverityPrediction(),
          ),
          const SizedBox(height: 16),
          _buildDiagnosisCard(
            title: '💰 Análise Econômica',
            subtitle: 'Calcule o impacto econômico dos danos',
            icon: Icons.attach_money,
            color: Colors.green,
            onTap: () => _showEconomicAnalysis(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisSection(
            title: '📊 Estatísticas por Cultura',
            child: _buildCropStats(),
          ),
          const SizedBox(height: 20),
          _buildAnalysisSection(
            title: '🦠 Distribuição por Tipo',
            child: _buildTypeDistribution(),
          ),
          const SizedBox(height: 20),
          _buildAnalysisSection(
            title: '📈 Dados Expandidos',
            child: _buildEnhancedDataStats(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCropStats() {
    final cropStats = _stats['byCrop'] as Map<String, dynamic>? ?? {};
    return Column(
      children: cropStats.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key),
              Chip(
                label: Text('${entry.value}'),
                backgroundColor: Colors.blue[100],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeDistribution() {
    final typeStats = _stats['byType'] as Map<String, dynamic>? ?? {};
    return Column(
      children: typeStats.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key),
              Chip(
                label: Text('${entry.value}'),
                backgroundColor: Colors.green[100],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnhancedDataStats() {
    return Column(
      children: [
        _buildEnhancedDataRow(
          'Dados de Fase',
          '${_stats['organismsWithPhaseData'] ?? 0}',
          '${_stats['phaseDataPercentage'] ?? '0%'}',
          Colors.orange,
        ),
        _buildEnhancedDataRow(
          'Dados de Severidade',
          '${_stats['organismsWithSeverityData'] ?? 0}',
          '${_stats['severityDataPercentage'] ?? '0%'}',
          Colors.red,
        ),
        _buildEnhancedDataRow(
          'Dados Econômicos',
          '${_stats['organismsWithEconomicData'] ?? 0}',
          '${_stats['economicDataPercentage'] ?? '0%'}',
          Colors.purple,
        ),
        _buildEnhancedDataRow(
          'Dados de Manejo',
          '${_stats['organismsWithManagementData'] ?? 0}',
          '${_stats['managementDataPercentage'] ?? '0%'}',
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildEnhancedDataRow(String title, String count, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Row(
            children: [
              Chip(
                label: Text(count),
                backgroundColor: color.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(percentage),
                backgroundColor: color.withOpacity(0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCropCard(
            name: 'Soja',
            icon: '🌱',
            description: 'Principal cultura do Brasil',
            organismCount: 12,
            hasEnhancedData: true,
          ),
          const SizedBox(height: 16),
          _buildCropCard(
            name: 'Milho',
            icon: '🌽',
            description: 'Segunda maior cultura',
            organismCount: 8,
            hasEnhancedData: true,
          ),
          const SizedBox(height: 16),
          _buildCropCard(
            name: 'Algodão',
            icon: '🌾',
            description: 'Cultura de alta rentabilidade',
            organismCount: 6,
            hasEnhancedData: true,
          ),
          const SizedBox(height: 16),
          _buildCropCard(
            name: 'Sorgo',
            icon: '🌾',
            description: 'Cultura resistente à seca',
            organismCount: 4,
            hasEnhancedData: true,
          ),
          const SizedBox(height: 16),
          _buildCropCard(
            name: 'Cana-de-açúcar',
            icon: '🎋',
            description: 'Principal cultura para etanol',
            organismCount: 5,
            hasEnhancedData: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard({
    required String name,
    required String icon,
    required String description,
    required int organismCount,
    required bool hasEnhancedData,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Chip(
                  label: Text('$organismCount organismos'),
                  backgroundColor: Colors.blue[100],
                ),
                const SizedBox(height: 4),
                if (hasEnhancedData)
                  Chip(
                    label: const Text('Dados Expandidos'),
                    backgroundColor: Colors.green[100],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganismsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrganismFilter(),
          const SizedBox(height: 16),
          _buildOrganismList(),
        ],
      ),
    );
  }

  Widget _buildOrganismFilter() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 Filtros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Cultura',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'soja', child: Text('Soja')),
                      DropdownMenuItem(value: 'milho', child: Text('Milho')),
                      DropdownMenuItem(value: 'algodao', child: Text('Algodão')),
                      DropdownMenuItem(value: 'sorgo', child: Text('Sorgo')),
                      DropdownMenuItem(value: 'cana', child: Text('Cana-de-açúcar')),
                    ],
                    onChanged: (value) {
                      // Implementar filtro
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pest', child: Text('Praga')),
                      DropdownMenuItem(value: 'disease', child: Text('Doença')),
                      DropdownMenuItem(value: 'weed', child: Text('Planta Daninha')),
                    ],
                    onChanged: (value) {
                      // Implementar filtro
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganismList() {
    return Column(
      children: _recentOrganisms.map((organism) => _buildOrganismCard(organism)).toList(),
    );
  }

  Widget _buildOrganismCard(EnhancedAIOrganismData organism) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(organism.icone, style: const TextStyle(fontSize: 24)),
        title: Text(organism.name),
        subtitle: Text('${organism.scientificName} • ${organism.categoria}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (organism.fases.isNotEmpty)
              const Icon(Icons.timeline, color: Colors.orange, size: 16),
            if (organism.severidadeDetalhada.isNotEmpty)
              const Icon(Icons.warning, color: Colors.red, size: 16),
            if (organism.danoEconomico.descricao.isNotEmpty)
              const Icon(Icons.attach_money, color: Colors.green, size: 16),
          ],
        ),
        onTap: () => _showOrganismDetails(organism),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSection(
            title: '🔧 Configurações da IA',
            children: [
              _buildSettingsTile(
                title: 'Limiar de Confiança',
                subtitle: 'Ajuste a sensibilidade do diagnóstico',
                trailing: const Text('0.3'),
                onTap: () {},
              ),
              _buildSettingsTile(
                title: 'Dados Expandidos',
                subtitle: 'Ativar/desativar dados ricos do catálogo',
                trailing: Switch(value: true, onChanged: (value) {}),
              ),
              _buildSettingsTile(
                title: 'Predição de Severidade',
                subtitle: 'Ativar predições baseadas em condições',
                trailing: Switch(value: true, onChanged: (value) {}),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsSection(
            title: '📊 Estatísticas',
            children: [
              _buildSettingsTile(
                title: 'Recarregar Dados',
                subtitle: 'Atualizar dados do catálogo',
                trailing: const Icon(Icons.refresh),
                onTap: () => _loadData(),
              ),
              _buildSettingsTile(
                title: 'Exportar Relatório',
                subtitle: 'Gerar relatório de organismos',
                trailing: const Icon(Icons.download),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showOrganismDetails(EnhancedAIOrganismData organism) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${organism.icone} ${organism.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nome Científico: ${organism.scientificName}'),
              Text('Categoria: ${organism.categoria}'),
              Text('Culturas: ${organism.crops.join(', ')}'),
              if (organism.fases.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Fases de Desenvolvimento:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...organism.fases.map((fase) => Text('• ${fase.fase}: ${fase.tamanhoMM}mm')),
              ],
              if (organism.severidadeDetalhada.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Níveis de Severidade:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...organism.severidadeDetalhada.entries.map((entry) => 
                  Text('• ${entry.key}: ${entry.value.descricao}')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showSymptomDiagnosis() {
    // Implementar diagnóstico por sintomas
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
    );
  }

  void _showSizeDiagnosis() {
    // Implementar diagnóstico por tamanho
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
    );
  }

  void _showSeverityPrediction() {
    // Implementar predição de severidade
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
    );
  }

  void _showEconomicAnalysis() {
    // Implementar análise econômica
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
    );
  }
}
