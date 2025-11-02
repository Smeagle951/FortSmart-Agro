import 'package:flutter/material.dart';
import 'package:fortsmart_agro/modules/planting/models/plantio_model.dart';
import 'package:fortsmart_agro/modules/planting/services/data_cache_service.dart';
import 'package:fortsmart_agro/modules/planting/services/plantio_service.dart';
import 'package:fortsmart_agro/utils/date_formatter.dart';
import 'package:fortsmart_agro/utils/logger.dart';
import 'package:fortsmart_agro/widgets/empty_state.dart';
import 'package:fortsmart_agro/widgets/error_state.dart';

/// Tela para listagem de plantios cadastrados
class PlantioListaScreen extends StatefulWidget {
  const PlantioListaScreen({Key? key}) : super(key: key);

  @override
  State<PlantioListaScreen> createState() => _PlantioListaScreenState();
}

class _PlantioListaScreenState extends State<PlantioListaScreen> {
  final PlantioService _plantioService = PlantioService();
  final DataCacheService _dataCacheService = DataCacheService();
  
  List<PlantioModel>? _plantios;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _carregarPlantios();
  }
  
  Future<void> _carregarPlantios() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final plantios = await _plantioService.listar();
      
      if (mounted) {
        setState(() {
          _plantios = plantios;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar plantios: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar plantios: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<String> _getNomeTalhao(String talhaoId) async {
    try {
      final talhao = await _dataCacheService.getTalhao(talhaoId);
      return talhao?.nome ?? 'Talhão não encontrado';
    } catch (e) {
      return 'Talhão não encontrado';
    }
  }
  
  Future<String> _getNomeCultura(String culturaId) async {
    try {
      final cultura = await _dataCacheService.getCultura(culturaId);
      return cultura?.name ?? 'Cultura não encontrada';
    } catch (e) {
      return 'Cultura não encontrada';
    }
  }
  
  Future<void> _excluirPlantio(PlantioModel plantio) async {
    try {
      await _plantioService.excluir(plantio.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantio excluído com sucesso!')),
        );
        _carregarPlantios();
      }
    } catch (e) {
      Logger.error('Erro ao excluir plantio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir plantio: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantios'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/plantio/cadastro').then((value) {
            if (value == true) {
              _carregarPlantios();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _carregarPlantios,
      );
    }
    
    if (_plantios == null || _plantios!.isEmpty) {
      return EmptyState(
        icon: Icons.grass,
        title: 'Nenhum plantio cadastrado',
        message: 'Cadastre seu primeiro plantio clicando no botão abaixo',
        buttonText: 'Novo Plantio',
        onButtonPressed: () { // Corrigido: onPressed -> onButtonPressed
          Navigator.pushNamed(context, '/plantio/cadastro').then((value) {
            if (value == true) {
              _carregarPlantios();
            }
          });
        },
      );
    }
    
    return RefreshIndicator(
      onRefresh: _carregarPlantios,
      child: ListView.builder(
        itemCount: _plantios!.length,
        itemBuilder: (context, index) {
          final plantio = _plantios![index];
          return FutureBuilder<List<String>>(
            future: Future.wait([
              _getNomeTalhao(plantio.talhaoId),
              _getNomeCultura(plantio.culturaId),
            ]),
            builder: (context, snapshot) {
              final nomeTalhao = snapshot.data?[0] ?? 'Carregando...';
              final nomeCultura = snapshot.data?[1] ?? 'Carregando...';
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('$nomeTalhao - $nomeCultura'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Data: ${DateFormatter.format(plantio.dataPlantio)}'),
                      Text('População: ${plantio.populacao} plantas/ha'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar exclusão'),
                          content: const Text('Deseja realmente excluir este plantio?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _excluirPlantio(plantio);
                              },
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/plantio/detalhes',
                      arguments: plantio,
                    ).then((value) {
                      if (value == true) {
                        _carregarPlantios();
                      }
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
