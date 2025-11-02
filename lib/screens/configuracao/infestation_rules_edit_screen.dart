import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/logger.dart';
import '../../services/organism_loader_service.dart';

/// Tela para editar regras de infestação diretamente nos JSONs
/// Permite customização por fazenda mantendo padrões científicos
class InfestationRulesEditScreen extends StatefulWidget {
  const InfestationRulesEditScreen({Key? key}) : super(key: key);

  @override
  State<InfestationRulesEditScreen> createState() => _InfestationRulesEditScreenState();
}

class _InfestationRulesEditScreenState extends State<InfestationRulesEditScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _catalogData;
  String? _errorMessage;
  String _selectedCulture = 'soja';
  String? _selectedOrganism;
  final OrganismLoaderService _loaderService = OrganismLoaderService();
  
  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  /// Carrega o catálogo de organismos
  Future<void> _loadCatalog() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Tentar carregar versão customizada primeiro
      final customFile = await _getCustomCatalogFile();
      String jsonString;
      
      if (await customFile.exists()) {
        Logger.info('📄 Carregando catálogo customizado');
        jsonString = await customFile.readAsString();
      } else {
        Logger.info('📄 Carregando catálogo padrão (todas as culturas)');
        jsonString = await _loadAllCultures();
      }

      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      setState(() {
        _catalogData = data;
        _isLoading = false;
      });
      
      Logger.info('✅ Catálogo carregado com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao carregar catálogo: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar catálogo: $e';
        _isLoading = false;
      });
    }
  }

  /// Obtém o arquivo customizado do catálogo
  Future<File> _getCustomCatalogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/organism_catalog_custom.json');
  }

  /// Carrega e mescla catálogos de todas as culturas usando organismos_*.json
  Future<String> _loadAllCultures() async {
    try {
      final cultureIds = ['soja', 'milho', 'algodao', 'sorgo', 'girassol', 'aveia', 'trigo', 'feijao', 'arroz'];

      final Map<String, dynamic> mergedCatalog = {
        'version': '2.0',
        'last_updated': DateTime.now().toIso8601String(),
        'cultures': <String, dynamic>{},
      };

      final culturesMap = mergedCatalog['cultures'] as Map<String, dynamic>;

      for (final cultureId in cultureIds) {
        try {
          // Carregar TODOS os organismos do arquivo organismos_*.json
          final cultureData = await _loaderService.loadCultureOrganisms('custom_$cultureId');
          culturesMap[cultureId] = cultureData;
          Logger.info('✅ ${cultureData['total_organisms'] ?? 0} organismos carregados para $cultureId');
        } catch (e) {
          Logger.warning('⚠️ Erro ao carregar $cultureId: $e');
        }
      }

      return json.encode(mergedCatalog);
    } catch (e) {
      Logger.error('❌ Erro ao mesclar culturas: $e');
      rethrow;
    }
  }

  /// Salva alterações no catálogo
  Future<void> _saveCatalog() async {
    try {
      Logger.info('💾 Salvando catálogo customizado...');
      
      // Atualizar timestamp
      _catalogData!['last_updated'] = DateTime.now().toIso8601String();
      
      // Salvar em arquivo customizado
      final customFile = await _getCustomCatalogFile();
      final jsonString = const JsonEncoder.withIndent('  ').convert(_catalogData);
      await customFile.writeAsString(jsonString);
      
      Logger.info('✅ Catálogo salvo com sucesso');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Regras salvas com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Logger.error('❌ Erro ao salvar catálogo: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao salvar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Restaura catálogo padrão
  Future<void> _restoreDefault() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restaurar Padrão'),
          content: const Text(
            'Isso irá restaurar todas as regras para os valores padrão científicos. '
            'Suas customizações serão perdidas.\n\n'
            'Deseja continuar?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      Logger.info('🔄 Restaurando catálogo padrão...');
      
      // Deletar arquivo customizado
      final customFile = await _getCustomCatalogFile();
      if (await customFile.exists()) {
        await customFile.delete();
      }
      
      // Recarregar catálogo
      await _loadCatalog();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Regras padrão restauradas!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('❌ Erro ao restaurar padrão: $e');
    }
  }

  /// Obtém lista de organismos da cultura selecionada
  List<Map<String, dynamic>> _getOrganisms() {
    if (_catalogData == null) return [];
    
    try {
      final cultures = _catalogData!['cultures'] as Map<String, dynamic>;
      final culture = cultures[_selectedCulture] as Map<String, dynamic>?;
      if (culture == null) return [];
      
      final organisms = culture['organisms'] as Map<String, dynamic>?;
      if (organisms == null) return [];
      
      final pests = organisms['pests'] as List<dynamic>? ?? [];
      return pests.cast<Map<String, dynamic>>();
    } catch (e) {
      Logger.error('Erro ao obter organismos: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regras de Infestação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restaurar Padrão',
            onPressed: _restoreDefault,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Salvar Alterações',
            onPressed: _catalogData != null ? _saveCatalog : null,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando catálogo...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCatalog,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_catalogData == null) {
      return const Center(child: Text('Nenhum dado disponível'));
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildOrganismsList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Configure os níveis de ação por estágio fenológico',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cada fazenda pode ter seus próprios níveis. '
            'Os valores padrão são baseados em pesquisas científicas.',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Cultura: ', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedCulture,
                items: const [
                  DropdownMenuItem(value: 'soja', child: Text('Soja')),
                  DropdownMenuItem(value: 'milho', child: Text('Milho')),
                  DropdownMenuItem(value: 'algodao', child: Text('Algodão')),
                  DropdownMenuItem(value: 'sorgo', child: Text('Sorgo')),
                  DropdownMenuItem(value: 'girassol', child: Text('Girassol')),
                  DropdownMenuItem(value: 'aveia', child: Text('Aveia')),
                  DropdownMenuItem(value: 'trigo', child: Text('Trigo')),
                  DropdownMenuItem(value: 'feijao', child: Text('Feijão')),
                  DropdownMenuItem(value: 'arroz', child: Text('Arroz')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCulture = value;
                      _selectedOrganism = null;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrganismsList() {
    final organisms = _getOrganisms();
    
    if (organisms.isEmpty) {
      return const Center(
        child: Text('Nenhum organismo encontrado para esta cultura'),
      );
    }

    return ListView.builder(
      itemCount: organisms.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final organism = organisms[index];
        return _buildOrganismCard(organism);
      },
    );
  }

  Widget _buildOrganismCard(Map<String, dynamic> organism) {
    // Tentar diferentes campos de nome
    final name = organism['nome'] as String? ?? 
                organism['name'] as String? ?? 
                organism['nome_cientifico'] as String? ?? 
                'Organismo sem nome';
    final scientificName = organism['nome_cientifico'] as String? ?? 
                          organism['scientific_name'] as String? ?? '';
    final criticalStages = (organism['critical_stages'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .join(', ') ?? 'Nenhum';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scientificName,
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Estágios críticos: $criticalStages',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ],
        ),
        children: [
          _buildPhenologicalThresholds(organism),
        ],
      ),
    );
  }

  Widget _buildPhenologicalThresholds(Map<String, dynamic> organism) {
    final thresholds = organism['phenological_thresholds'] as Map<String, dynamic>?;
    
    if (thresholds == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Nenhum threshold fenológico definido'),
      );
    }

    return Column(
      children: thresholds.entries.map((entry) {
        final stage = entry.key;
        final data = entry.value as Map<String, dynamic>;
        return _buildStageThresholds(organism, stage, data);
      }).toList(),
    );
  }

  Widget _buildStageThresholds(
    Map<String, dynamic> organism,
    String stage,
    Map<String, dynamic> data,
  ) {
    final isCritical = (organism['critical_stages'] as List<dynamic>?)
        ?.contains(stage.split('-').first) ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCritical ? Colors.red.shade300 : Colors.grey.shade300,
          width: isCritical ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isCritical ? Colors.red.shade50 : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isCritical)
                const Icon(Icons.warning, color: Colors.red, size: 20),
              if (isCritical)
                const SizedBox(width: 8),
              Text(
                'Estágio: $stage',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCritical ? Colors.red.shade900 : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data['description'] as String? ?? '',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          _buildThresholdSliders(organism, stage, data),
        ],
      ),
    );
  }

  Widget _buildThresholdSliders(
    Map<String, dynamic> organism,
    String stage,
    Map<String, dynamic> data,
  ) {
    // ✅ PADRÃO: organismos/ponto (cálculo usa MÉDIA por ponto)
    final unit = organism['unit'] as String? ?? 'organismos/ponto';
    
    return Column(
      children: [
        // ✅ NOVO: Seletor de unidade
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.straighten, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Unidade:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'organismos/ponto',
                      label: Text('Por Ponto', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.location_on, size: 14),
                    ),
                    ButtonSegment(
                      value: 'organismos/metro',
                      label: Text('Por Metro', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.straighten, size: 14),
                    ),
                  ],
                  selected: {unit},
                  onSelectionChanged: (Set<String> selected) {
                    _updateUnit(organism, selected.first);
                  },
                  style: ButtonStyle(
                    textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // ✅ Info sobre a unidade selecionada
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: unit == 'organismos/ponto' ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: unit == 'organismos/ponto' ? Colors.green.shade700 : Colors.orange.shade700,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  unit == 'organismos/ponto'
                      ? 'Recomendado! Cálculo usa MÉDIA por ponto de monitoramento'
                      : 'Valores serão considerados por metro linear',
                  style: TextStyle(
                    fontSize: 10,
                    color: unit == 'organismos/ponto' ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // ✅ Sliders com valores decimais
        _buildSlider(
          'BAIXO',
          data['low'] as num? ?? 0,
          Colors.green,
          (value) => _updateThreshold(organism, stage, 'low', value),
          unit,
        ),
        _buildSlider(
          'MÉDIO',
          data['medium'] as num? ?? 0,
          Colors.orange,
          (value) => _updateThreshold(organism, stage, 'medium', value),
          unit,
        ),
        _buildSlider(
          'ALTO',
          data['high'] as num? ?? 0,
          Colors.red,
          (value) => _updateThreshold(organism, stage, 'high', value),
          unit,
        ),
        _buildSlider(
          'CRÍTICO',
          data['critical'] as num? ?? 0,
          Colors.purple,
          (value) => _updateThreshold(organism, stage, 'critical', value),
          unit,
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    num value,
    Color color,
    Function(double) onChanged,
    String unit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 15, // ✅ REDUZIDO: Max 15 para permitir mais granularidade
              divisions: 150, // ✅ AUMENTADO: 150 divisões = precisão de 0.1
              activeColor: color,
              label: '${value.toDouble().toStringAsFixed(1)} $unit', // ✅ Mostra 1 decimal
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 90, // ✅ AUMENTADO: Para caber decimais
            child: Text(
              '${value.toDouble().toStringAsFixed(1)} $unit', // ✅ Mostra 1 decimal
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _updateThreshold(
    Map<String, dynamic> organism,
    String stage,
    String thresholdType,
    double value,
  ) {
    setState(() {
      final thresholds = organism['phenological_thresholds'] as Map<String, dynamic>;
      final stageData = thresholds[stage] as Map<String, dynamic>;
      // ✅ ALTERADO: Mantém valor DECIMAL (não converte para int)
      // Permite valores como 0.2, 0.5, 1.5, etc.
      stageData[thresholdType] = double.parse(value.toStringAsFixed(1));
    });
  }
  
  /// ✅ NOVO: Atualiza a unidade do organismo
  void _updateUnit(Map<String, dynamic> organism, String newUnit) {
    setState(() {
      organism['unit'] = newUnit;
      Logger.info('🔄 Unidade alterada para: $newUnit');
      
      // Mostrar dica ao usuário
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unidade alterada para: $newUnit'),
          duration: const Duration(seconds: 2),
          backgroundColor: newUnit == 'organismos/ponto' ? Colors.green : Colors.orange,
        ),
      );
    });
  }
}



