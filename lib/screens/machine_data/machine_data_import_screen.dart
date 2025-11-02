import 'package:flutter/material.dart';
import '../../services/agricultural_machine_data_service.dart';
import 'machine_data_thermal_viewer.dart';
import 'widgets/machine_data_import_card.dart';
import 'widgets/machine_data_progress_dialog.dart';

/// Tela principal para importação de dados de máquinas agrícolas
class MachineDataImportScreen extends StatefulWidget {
  const MachineDataImportScreen({Key? key}) : super(key: key);

  @override
  State<MachineDataImportScreen> createState() => _MachineDataImportScreenState();
}

class _MachineDataImportScreenState extends State<MachineDataImportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<MachineWorkData> _importedData = [];
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Dados de Máquinas Agrícolas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.agriculture),
              text: 'Importar',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Histórico',
            ),
            Tab(
              icon: Icon(Icons.help),
              text: 'Ajuda',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImportTab(),
          _buildHistoryTab(),
          _buildHelpTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importMachineData,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.agriculture, color: Colors.white),
        label: const Text(
          'Importar Dados',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  /// Tab de importação
  Widget _buildImportTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildSupportedMachinesCard(),
            const SizedBox(height: 24),
            _buildQuickImportCard(),
            const SizedBox(height: 24),
            if (_importedData.isNotEmpty) ...[
              _buildRecentImportsCard(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  /// Tab de histórico
  Widget _buildHistoryTab() {
    return Container(
      color: Colors.white,
      child: _importedData.isEmpty
          ? _buildEmptyHistory()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _importedData.length,
              itemBuilder: (context, index) {
                final data = _importedData[index];
                return _buildHistoryItem(data, index);
              },
            ),
    );
  }

  /// Tab de ajuda
  Widget _buildHelpTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpCard(
              'Máquinas Suportadas',
              'O sistema suporta dados das seguintes marcas:',
              [
                '• Jacto NPK 5030 - Aplicação de fertilizantes',
                '• Stara - Plantio, colheita e aplicação',
                '• John Deere - Plantio, colheita e aplicação',
                '• Case - Plantio e colheita',
                '• New Holland - Operações gerais',
                '• Massey Ferguson - Operações gerais',
                '• Valtra - Operações gerais',
                '• Fendt - Operações gerais',
              ],
              Icons.agriculture,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              'Formatos Suportados',
              'Você pode importar dados dos seguintes formatos:',
              [
                '• Shapefile (.shp) - Dados geoespaciais',
                '• CSV (.csv) - Dados tabulares',
                '• Arquivos de texto (.txt, .dat, .log)',
                '• Arquivos específicos das máquinas',
              ],
              Icons.description,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              'Dados Analisados',
              'O sistema analisa os seguintes parâmetros:',
              [
                '• Taxa de aplicação (kg/ha)',
                '• Velocidade de trabalho (km/h)',
                '• Total aplicado (kg)',
                '• Área coberta (ha)',
                '• Eficiência de trabalho (%)',
                '• Mapas térmicos coloridos',
              ],
              Icons.analytics,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              'Visualização Térmica',
              'Recursos de visualização disponíveis:',
              [
                '• Mapas térmicos com cores verde-vermelho',
                '• Filtros avançados por parâmetro',
                '• Análises estatísticas detalhadas',
                '• Gráficos de performance',
                '• Exportação de dados',
              ],
              Icons.map,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  /// Card de boas-vindas
  Widget _buildWelcomeCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade400,
              Colors.green.shade600,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.agriculture,
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
                        'Dados de Máquinas Agrícolas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Importe e analise dados de Jacto, Stara, John Deere e outras marcas',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _importMachineData,
              icon: const Icon(Icons.agriculture),
              label: const Text('Importar Dados de Máquina'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card de máquinas suportadas
  Widget _buildSupportedMachinesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture, color: Colors.green.shade600),
                const SizedBox(width: 12),
                const Text(
                  'Máquinas Suportadas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMachineChip('Jacto NPK 5030', Colors.green),
                _buildMachineChip('Stara', Colors.blue),
                _buildMachineChip('John Deere', Colors.orange),
                _buildMachineChip('Case', Colors.red),
                _buildMachineChip('New Holland', Colors.purple),
                _buildMachineChip('Massey Ferguson', Colors.brown),
                _buildMachineChip('Valtra', Colors.cyan),
                _buildMachineChip('Fendt', Colors.indigo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card de importação rápida
  Widget _buildQuickImportCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                const Text(
                  'Importação Rápida',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickImportButton(
                    'Jacto NPK 5030',
                    Icons.agriculture,
                    Colors.green,
                    () => _importSpecificMachine(MachineType.jactoNPK),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickImportButton(
                    'Stara Plantio',
                    Icons.agriculture,
                    Colors.blue,
                    () => _importSpecificMachine(MachineType.staraPlantio),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickImportButton(
                    'John Deere',
                    Icons.agriculture,
                    Colors.orange,
                    () => _importSpecificMachine(MachineType.johnDeerePlantio),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickImportButton(
                    'Case Colheita',
                    Icons.agriculture,
                    Colors.red,
                    () => _importSpecificMachine(MachineType.caseColheita),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card de importações recentes
  Widget _buildRecentImportsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.purple.shade600),
                const SizedBox(width: 12),
                const Text(
                  'Importações Recentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._importedData.take(3).map((data) => _buildRecentImportItem(data)),
          ],
        ),
      ),
    );
  }

  /// Histórico vazio
  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.agriculture,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum dado de máquina importado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Importe dados de suas máquinas para começar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Item do histórico
  Widget _buildHistoryItem(MachineWorkData data, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.agriculture, color: Colors.green),
        ),
        title: Text(
          data.machineModel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${data.workPoints.length} pontos • ${data.statistics.totalArea.toStringAsFixed(2)} ha'),
            Text(
              _formatDate(data.workDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: () => _viewMachineData(data),
        ),
        onTap: () => _viewMachineData(data),
      ),
    );
  }

  /// Card de ajuda
  Widget _buildHelpCard(
    String title,
    String description,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Chip de máquina
  Widget _buildMachineChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Botão de importação rápida
  Widget _buildQuickImportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  /// Item de importação recente
  Widget _buildRecentImportItem(MachineWorkData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.agriculture,
              color: Colors.green,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.machineModel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${data.workPoints.length} pontos • ${_formatDate(data.workDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility, size: 16),
            onPressed: () => _viewMachineData(data),
          ),
        ],
      ),
    );
  }

  /// Importa dados de máquina
  Future<void> _importMachineData() async {
    setState(() {
      _isImporting = true;
    });

    try {
      // Mostrar diálogo de progresso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MachineDataProgressDialog(
          machineType: 'Máquina Agrícola',
        ),
      );

      // Importar dados
      final machineData = await AgriculturalMachineDataService.readMachineDataFile();

      // Fechar diálogo de progresso
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (machineData != null) {
        setState(() {
          _importedData.insert(0, machineData);
        });

        // Mostrar visualizador térmico
        if (mounted) {
          _viewMachineData(machineData);
        }
      }

    } catch (e) {
      // Fechar diálogo de progresso
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      _showErrorSnackBar('Erro na importação: $e');
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  /// Importa máquina específica
  Future<void> _importSpecificMachine(MachineType machineType) async {
    // Implementar importação específica por tipo de máquina
    _showInfoSnackBar('Importação de ${_getMachineTypeName(machineType)} em desenvolvimento');
  }

  /// Visualiza dados da máquina
  void _viewMachineData(MachineWorkData data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MachineDataThermalViewer(machineData: data),
      ),
    );
  }

  /// Métodos auxiliares
  String _getMachineTypeName(MachineType type) {
    switch (type) {
      case MachineType.jactoNPK:
        return 'Jacto NPK 5030';
      case MachineType.staraPlantio:
        return 'Stara Plantio';
      case MachineType.staraColheita:
        return 'Stara Colheita';
      case MachineType.staraAplicacao:
        return 'Stara Aplicação';
      case MachineType.johnDeerePlantio:
        return 'John Deere Plantio';
      case MachineType.johnDeereColheita:
        return 'John Deere Colheita';
      case MachineType.johnDeereAplicacao:
        return 'John Deere Aplicação';
      case MachineType.casePlantio:
        return 'Case Plantio';
      case MachineType.caseColheita:
        return 'Case Colheita';
      case MachineType.newHolland:
        return 'New Holland';
      case MachineType.masseyFerguson:
        return 'Massey Ferguson';
      case MachineType.valtra:
        return 'Valtra';
      case MachineType.fendt:
        return 'Fendt';
      case MachineType.desconhecido:
        return 'Máquina Desconhecida';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
