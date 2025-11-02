import 'package:flutter/material.dart';
import '../database/models/crop.dart';
import '../database/models/pest.dart';
import '../database/models/disease.dart';
import '../database/models/weed.dart';
import '../services/crop_service.dart';
import 'crops/crop_variety_list_screen.dart';

class CropDetailsScreen extends StatefulWidget {
  final int cropId;

  const CropDetailsScreen({Key? key, required this.cropId}) : super(key: key);

  @override
  _CropDetailsScreenState createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends State<CropDetailsScreen> with SingleTickerProviderStateMixin {
  final CropService _cropService = CropService();
  late TabController _tabController;
  
  Crop? _crop;
  List<Pest> _pests = [];
  List<Disease> _diseases = [];
  List<Weed> _weeds = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final crop = await _cropService.getCropById(widget.cropId);
      
      if (crop != null) {
        final pests = await _cropService.getPestsByCropId(widget.cropId);
        final diseases = await _cropService.getDiseasesByCropId(widget.cropId);
        final weeds = await _cropService.getWeedsByCropId(widget.cropId);
        
        setState(() {
          _crop = crop;
          _pests = pests;
          _diseases = diseases;
          _weeds = weeds;
        });
      } else {
        // Cultura não encontrada, voltar para a tela anterior
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cultura não encontrada')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
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
      appBar: AppBar(
        title: Text(_crop?.name ?? 'Detalhes da Cultura'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Detalhes'),
            Tab(text: 'Variedades'),
            Tab(text: 'Pragas'),
            Tab(text: 'Doenças'),
            Tab(text: 'Plantas Daninhas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildVarietiesTab(),
                _buildPestsTab(),
                _buildDiseasesTab(),
                _buildWeedsTab(),
              ],
            ),
    );
  }
  
  Widget _buildDetailsTab() {
    if (_crop == null) {
      return const Center(child: Text('Cultura não encontrada'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _crop!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nome científico: ${_crop!.scientificName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Descrição:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _crop!.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações de Cultivo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Ciclo de cultivo', '${_crop!.growthCycle} dias'),
                  _buildInfoRow('Espaçamento entre plantas', '${_crop!.plantSpacing} cm'),
                  _buildInfoRow('Espaçamento entre linhas', '${_crop!.rowSpacing} cm'),
                  _buildInfoRow('Profundidade de plantio', '${_crop!.plantingDepth} cm'),
                  _buildInfoRow('Temperatura ideal', '${_crop!.idealTemperature}°C'),
                  _buildInfoRow('Necessidade hídrica', '${_crop!.waterRequirement} mm'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVarietiesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CropVarietyListScreen(
                          cropId: widget.cropId.toString(),
                          cropName: _crop?.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Ver Todas as Variedades'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.grain,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gerenciar Variedades',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Clique no botão acima para visualizar e gerenciar as variedades desta cultura',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPestsTab() {
    if (_pests.isEmpty) {
      return const Center(
        child: Text('Nenhuma praga registrada para esta cultura'),
      );
    }
    
    return ListView.builder(
      itemCount: _pests.length,
      itemBuilder: (context, index) {
        final pest = _pests[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              pest.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(pest.scientificName),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/pest/details',
                arguments: pest.id,
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildDiseasesTab() {
    if (_diseases.isEmpty) {
      return const Center(
        child: Text('Nenhuma doença registrada para esta cultura'),
      );
    }
    
    return ListView.builder(
      itemCount: _diseases.length,
      itemBuilder: (context, index) {
        final disease = _diseases[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              disease.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(disease.scientificName),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/disease/details',
                arguments: disease.id,
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildWeedsTab() {
    if (_weeds.isEmpty) {
      return const Center(
        child: Text('Nenhuma planta daninha registrada para esta cultura'),
      );
    }
    
    return ListView.builder(
      itemCount: _weeds.length,
      itemBuilder: (context, index) {
        final weed = _weeds[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              weed.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(weed.scientificName),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/weed/details',
                arguments: weed.id,
              );
            },
          ),
        );
      },
    );
  }
}
