import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../repositories/plot_repository.dart';
import '../../models/plot.dart';
import '../../routes.dart';

class SoilSamplePlotSelectionScreen extends StatefulWidget {
  const SoilSamplePlotSelectionScreen({Key? key}) : super(key: key);

  @override
  _SoilSamplePlotSelectionScreenState createState() => _SoilSamplePlotSelectionScreenState();
}

class _SoilSamplePlotSelectionScreenState extends State<SoilSamplePlotSelectionScreen> {
  final PlotRepository _repository = PlotRepository();
  List<Plot> _plots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlots();
  }

  Future<void> _loadPlots() async {
    try {
      final plots = await _repository.getAll();
      setState(() {
        _plots = plots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar talhões: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Talhão para Amostra de Solo'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plots.isEmpty
              ? const Center(child: Text('Nenhum talhão encontrado'))
              : ListView.builder(
                  itemCount: _plots.length,
                  itemBuilder: (context, index) {
                    final plot = _plots[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(plot.name),
                        subtitle: Text('Área: ${plot.area?.toStringAsFixed(2) ?? "N/A"} ha'),
                        onTap: () {
                          Navigator.pushNamed(
                            context, 
                            AppRoutes.addSoilAnalysis,
                            arguments: {'plotId': plot.id, 'plotName': plot.name}
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Mostrar mensagem informando que é necessário selecionar um talhão primeiro
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selecione um talhão para adicionar análise de solo'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
