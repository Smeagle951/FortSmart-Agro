import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/plantio_model.dart' as plantio_model;
import '../../services/plantio_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/loading_indicator.dart';
import 'plantio_registro_screen.dart';

class PlantioListaScreen extends StatefulWidget {
  const PlantioListaScreen({Key? key}) : super(key: key);

  @override
  State<PlantioListaScreen> createState() => _PlantioListaScreenState();
}

class _PlantioListaScreenState extends State<PlantioListaScreen> {
  final PlantioService _plantioService = PlantioService();
  
  List<plantio_model.PlantioModel> _plantios = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _carregarPlantios();
  }
  
  Future<void> _carregarPlantios() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final plantios = await _plantioService.getAllPlantios();
      
      setState(() {
        _plantios = plantios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar plantios: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deletarPlantio(String plantioId) async {
    try {
      await _plantioService.deletePlantio(plantioId);
      
      SnackbarUtils.showSuccessSnackBar(
        context, 
        'Plantio excluído com sucesso!'
      );
      
      _carregarPlantios();
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context, 
        'Erro ao excluir plantio: $e'
      );
    }
  }
  
  Future<String?> _getTalhaoNome(String? talhaoId) async {
    if (talhaoId == null) return 'Talhão não especificado';
    return 'Talhão $talhaoId';
  }
  
  Future<String?> _getCulturaNome(String? culturaId) async {
    if (culturaId == null) return 'Cultura não especificada';
    return 'Cultura $culturaId';
  }
  
  Future<String?> _getVariedadeNome(String? variedadeId, String? culturaId) async {
    if (variedadeId == null) return 'Variedade não especificada';
    return 'Variedade $variedadeId';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? Center(child: Text(_errorMessage ?? 'Erro desconhecido'))
              : _plantios.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.agriculture, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum plantio cadastrado',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Clique no botão de adicionar para começar.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _buildPlantiosList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PlantioRegistroScreen(),
            ),
          );
          
          if (result == true) {
            _carregarPlantios();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildPlantiosList() {
    return RefreshIndicator(
      onRefresh: _carregarPlantios,
      child: ListView.builder(
        itemCount: _plantios.length,
        itemBuilder: (context, index) {
          final plantio = _plantios[index];
          return _buildPlantioItem(plantio);
        },
      ),
    );
  }
  
  Widget _buildPlantioItem(plantio_model.PlantioModel plantio) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dataPlantio = plantio.dataPlantio != null 
        ? dateFormat.format(plantio.dataPlantio!) 
        : 'Data não informada';
    
    return FutureBuilder<List<String?>>(
      future: Future.wait([
        _getTalhaoNome(plantio.talhaoId),
        _getCulturaNome(plantio.culturaId),
        _getVariedadeNome(plantio.variedadeId, plantio.culturaId),
      ]),
      builder: (context, snapshot) {
        final talhaoNome = snapshot.data?[0] ?? 'Carregando...';
        final culturaNome = snapshot.data?[1] ?? 'Carregando...';
        final variedadeNome = snapshot.data?[2] ?? 'Carregando...';
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              '$talhaoNome - $culturaNome',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Variedade: $variedadeNome'),
                Text('Data: $dataPlantio'),
                Text('População: ${plantio.sementesHa?.toString() ?? 'N/A'} plantas/ha'),
                Text('Espaçamento: ${plantio.espacamento?.toString() ?? 'N/A'} cm'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Garantindo que o id seja uma string não nula
                        builder: (context) => PlantioRegistroScreen(plantioId: plantio.id),
                      ),
                    );
                    
                    if (result == true) {
                      _carregarPlantios();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text('Deseja realmente excluir este plantio?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _deletarPlantio(plantio.id!);
                            },
                            child: const Text('Excluir'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlantioRegistroScreen(plantioId: plantio.id),
                ),
              );
              // ignore: avoid_print
              print('Result: $result');
              if (result == true) {
                _carregarPlantios();
              }
            },
          ),
        );
      },
    );
  }
}
