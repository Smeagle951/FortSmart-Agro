import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/download_fazenda_offline_widget.dart';
import '../../widgets/farm_selector_widget.dart';
import '../../providers/farm_selection_provider.dart';
import '../../services/farm_service.dart';
import '../../models/farm.dart';

/// Tela para download de fazenda completa para modo offline
/// Permite usar os módulos Talhões, Monitoramento e Mapa de Infestação sem internet
class DownloadFazendaScreen extends StatefulWidget {
  const DownloadFazendaScreen({Key? key}) : super(key: key);

  @override
  State<DownloadFazendaScreen> createState() => _DownloadFazendaScreenState();
}

class _DownloadFazendaScreenState extends State<DownloadFazendaScreen> {
  final FarmService _farmService = FarmService();
  
  String? _selectedFarmId;
  Farm? _selectedFarm;
  bool _isLoading = true;
  List<Farm> _farms = [];

  @override
  void initState() {
    super.initState();
    _carregarFazendas();
  }

  Future<void> _carregarFazendas() async {
    setState(() => _isLoading = true);
    
    try {
      // ⚠️ TEMPORÁRIO: getFarms não existe - usando getAllFarms
      _farms = await _farmService.getAllFarms();
      
      // Selecionar a primeira fazenda por padrão
      if (_farms.isNotEmpty) {
        setState(() {
          _selectedFarm = _farms.first;
          _selectedFarmId = _farms.first.id;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar fazendas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onFarmSelected(String? farmId) {
    if (farmId == null) return;
    
    final farm = _farms.firstWhere(
      (f) => f.id == farmId,
      orElse: () => _farms.first,
    );
    
    setState(() {
      _selectedFarmId = farmId;
      _selectedFarm = farm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📥 Download Offline'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _mostrarAjuda,
            tooltip: 'Ajuda',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card explicativo
                  _buildExplicacaoCard(),
                  const SizedBox(height: 16),
                  
                  // Seletor de fazenda
                  _buildSeletorFazenda(),
                  const SizedBox(height: 16),
                  
                  // Widget de download
                  if (_selectedFarm != null)
                    DownloadFazendaOfflineWidget(
                      fazendaId: _selectedFarm!.id,
                      fazendaNome: _selectedFarm!.name,
                    )
                  else
                    _buildSemFazenda(),
                ],
              ),
            ),
    );
  }

  Widget _buildExplicacaoCard() {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Como funciona?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Selecione a fazenda que deseja baixar\n'
              '2. Escolha a qualidade dos mapas (maior = mais dados)\n'
              '3. Clique em "Baixar Fazenda Completa"\n'
              '4. Aguarde o download concluir (pode levar alguns minutos)\n'
              '5. Pronto! Use os módulos offline mesmo sem internet',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: const [
                  Icon(Icons.verified_user, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Funciona nos módulos: Talhões, Monitoramento e Mapa de Infestação',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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

  Widget _buildSeletorFazenda() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏡 Selecionar Fazenda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FarmSelectorWidget(
              selectedFarmId: _selectedFarmId,
              onFarmSelected: _onFarmSelected,
              showAllOption: false,
              label: 'Fazenda para Download',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemFazenda() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.agriculture, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Nenhuma fazenda selecionada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecione uma fazenda acima para começar',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgresso() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.downloading, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Download em andamento...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // A barra de progresso é renderizada no widget principal
        ],
      ),
    );
  }

  void _mostrarAjuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Ajuda - Download Offline'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAjudaTopico(
                '📱 Para que serve?',
                'Permite usar o FortSmart sem internet. Todos os mapas e dados da fazenda ficam salvos no seu celular.',
              ),
              const Divider(),
              _buildAjudaTopico(
                '🗺️ Quais módulos funcionam offline?',
                '• Módulo Talhões (visualizar e editar)\n'
                '• Módulo Monitoramento (registrar pontos)\n'
                '• Módulo Mapa de Infestação (visualizar e analisar)',
              ),
              const Divider(),
              _buildAjudaTopico(
                '💾 Quanto espaço ocupa?',
                'Depende da qualidade:\n'
                '• Baixa: ~50 MB\n'
                '• Média: ~150 MB\n'
                '• Alta: ~600 MB\n'
                '• Máxima: ~1 GB',
              ),
              const Divider(),
              _buildAjudaTopico(
                '⚡ Recomendações',
                '• Use Wi-Fi para baixar (economiza dados móveis)\n'
                '• Qualidade "Média" é suficiente para maioria dos usos\n'
                '• Faça o download antes de ir ao campo',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Widget _buildAjudaTopico(String titulo, String conteudo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            conteudo,
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

