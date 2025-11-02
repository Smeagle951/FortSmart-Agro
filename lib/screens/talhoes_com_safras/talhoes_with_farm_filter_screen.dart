import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/talhoes/talhao_safra_model.dart';
import '../../providers/talhao_provider.dart';
import '../../widgets/farm_selector_widget.dart';
import '../../providers/farm_selection_provider.dart';
import '../../services/farm_service.dart';
import '../../models/farm.dart';

/// Exemplo de tela de talhões com filtro por fazenda
/// Demonstra como implementar o filtro de fazenda nos módulos
class TalhoesWithFarmFilterScreen extends StatefulWidget {
  const TalhoesWithFarmFilterScreen({Key? key}) : super(key: key);

  @override
  State<TalhoesWithFarmFilterScreen> createState() => _TalhoesWithFarmFilterScreenState();
}

class _TalhoesWithFarmFilterScreenState extends State<TalhoesWithFarmFilterScreen> {
  final FarmService _farmService = FarmService();
  List<TalhaoSafraModel> _talhoes = [];
  List<TalhaoSafraModel> _talhoesFiltrados = [];
  String? _selectedFarmId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTalhoes();
  }

  Future<void> _loadTalhoes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
      _talhoes = await talhaoProvider.carregarTalhoes();
      _aplicarFiltro();
    } catch (e) {
      print('❌ Erro ao carregar talhões: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar talhões: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltro() {
    if (_selectedFarmId == null) {
      // Mostrar todos os talhões
      _talhoesFiltrados = _talhoes;
    } else {
      // Filtrar por fazenda selecionada
      _talhoesFiltrados = _talhoes.where((talhao) => 
        talhao.idFazenda == _selectedFarmId
      ).toList();
    }
  }

  void _onFarmSelected(String? farmId) {
    setState(() {
      _selectedFarmId = farmId;
      _aplicarFiltro();
    });
  }

  String _getEstatisticas() {
    if (_talhoesFiltrados.isEmpty) {
      return 'Nenhum talhão encontrado';
    }

    final totalTalhoes = _talhoesFiltrados.length;
    final areaTotal = _talhoesFiltrados.fold(0.0, (sum, talhao) => sum + talhao.area);
    
    return '$totalTalhoes talhões • ${areaTotal.toStringAsFixed(1)} ha';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talhões por Fazenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTalhoes,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Seletor de fazenda
                FarmSelectorWidget(
                  selectedFarmId: _selectedFarmId,
                  onFarmSelected: _onFarmSelected,
                  showAllOption: true,
                  label: 'Filtrar por Fazenda',
                ),
                
                // Estatísticas
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        _getEstatisticas(),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Lista de talhões
                Expanded(
                  child: _talhoesFiltrados.isEmpty
                      ? _buildEmptyState()
                      : _buildTalhoesList(),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFarmId == null ? Icons.grass : Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFarmId == null 
                ? 'Nenhum talhão cadastrado'
                : 'Nenhum talhão encontrado para esta fazenda',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFarmId == null
                ? 'Cadastre seu primeiro talhão'
                : 'Tente selecionar outra fazenda',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTalhoesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _talhoesFiltrados.length,
      itemBuilder: (context, index) {
        final talhao = _talhoesFiltrados[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: talhao.safras.isNotEmpty 
                  ? talhao.safras.first.culturaCor
                  : Colors.grey,
              child: Icon(
                Icons.grass,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              talhao.nome,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.area_chart, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('${talhao.area.toStringAsFixed(2)} ha'),
                    const SizedBox(width: 12),
                    Icon(Icons.agriculture, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      talhao.safras.isNotEmpty 
                          ? talhao.safras.first.culturaNome
                          : 'Sem cultura',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Fazenda: ${talhao.idFazenda}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: talhao.sincronizado ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                talhao.sincronizado ? 'Sincronizado' : 'Local',
                style: TextStyle(
                  fontSize: 10,
                  color: talhao.sincronizado ? Colors.green.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            onTap: () {
              // Navegar para detalhes do talhão
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Visualizar talhão: ${talhao.nome}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
