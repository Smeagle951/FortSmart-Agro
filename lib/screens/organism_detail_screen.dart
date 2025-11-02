import 'package:flutter/material.dart';
import '../models/organism_catalog.dart';
import '../models/organism_catalog_v3.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';
import '../services/organism_detailed_data_service.dart';
import '../services/organism_v3_integration_service.dart';
import '../widgets/organisms/climatic_alert_card_widget.dart';
import '../widgets/organisms/roi_calculator_widget.dart';
import '../widgets/organisms/resistance_analysis_widget.dart';
import '../widgets/organisms/fontes_referencia_widget.dart';
import 'organism_form_screen.dart';

/// Tela de detalhes completa do organismo
/// Exibe todas as informações ricas dos arquivos JSON
class OrganismDetailScreen extends StatefulWidget {
  final OrganismCatalog organism;

  const OrganismDetailScreen({
    Key? key,
    required this.organism,
  }) : super(key: key);

  @override
  State<OrganismDetailScreen> createState() => _OrganismDetailScreenState();
}

class _OrganismDetailScreenState extends State<OrganismDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _detailedData;
  bool _isLoadingData = true;
  OrganismCatalogV3? _organismV3;
  final OrganismDetailedDataService _dataService = OrganismDetailedDataService();
  final OrganismV3IntegrationService _v3Service = OrganismV3IntegrationService();

  @override
  void initState() {
    super.initState();
    // 6 tabs: 5 originais + 1 nova (v3.0)
    _tabController = TabController(length: 6, vsync: this);
    _loadDetailedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Carrega dados detalhados do organismo
  Future<void> _loadDetailedData() async {
    try {
      setState(() => _isLoadingData = true);
      
      // Carregar dados reais dos arquivos JSON
      final detailedData = await _dataService.getDetailedData(widget.organism);
      
      if (detailedData != null) {
        _detailedData = detailedData;
        
        // Tentar carregar dados v3.0
        _organismV3 = await _v3Service.findOrganism(
          nomeOrganismo: widget.organism.name,
          cultura: widget.organism.cropName,
        );
        
        if (_organismV3 != null) {
          Logger.info('✅ Dados v3.0 carregados para ${widget.organism.name}');
        }
        
        Logger.info('✅ Dados detalhados carregados para ${widget.organism.name}');
      } else {
        // Fallback para dados simulados se não encontrar nos arquivos JSON
        _detailedData = {
          'sintomas': _getSymptoms(),
          'condicoes_favoraveis': _getFavorableConditions(),
          'manejo_quimico': _getChemicalControl(),
          'manejo_biologico': _getBiologicalControl(),
          'manejo_cultural': _getCulturalControl(),
          'niveis_infestacao': _getInfestationLevels(),
          'fenologia': _getPhenology(),
          'partes_afetadas': _getAffectedParts(),
          'dano_economico': _getEconomicDamage(),
          'fotos': _getPhotoUrls(),
        };
        Logger.warning('⚠️ Usando dados simulados para ${widget.organism.name}');
      }
    } catch (e) {
      Logger.error('Erro ao carregar dados detalhados: $e');
      // Fallback para dados simulados
      _detailedData = {
        'sintomas': _getSymptoms(),
        'condicoes_favoraveis': _getFavorableConditions(),
        'manejo_quimico': _getChemicalControl(),
        'manejo_biologico': _getBiologicalControl(),
        'manejo_cultural': _getCulturalControl(),
        'niveis_infestacao': _getInfestationLevels(),
        'fenologia': _getPhenology(),
        'partes_afetadas': _getAffectedParts(),
        'dano_economico': _getEconomicDamage(),
        'fotos': _getPhotoUrls(),
      };
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.organism.name),
        backgroundColor: _getTypeColor(),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editOrganism(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Informações', icon: Icon(Icons.info)),
            const Tab(text: 'Sintomas', icon: Icon(Icons.warning)),
            const Tab(text: 'Manejo', icon: Icon(Icons.agriculture)),
            const Tab(text: 'Limiares', icon: Icon(Icons.trending_up)),
            const Tab(text: 'Fotos', icon: Icon(Icons.photo)),
            Builder(
              builder: (context) => Tab(
                text: 'IA & Análises v3.0',
                icon: Icon(Icons.analytics, color: _organismV3 != null ? Colors.blue : Colors.grey),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildSymptomsTab(),
          _buildManagementTab(),
          _buildThresholdsTab(),
          _buildPhotosTab(),
          _buildV3AnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editOrganism(),
        icon: const Icon(Icons.edit),
        label: const Text('Editar'),
        backgroundColor: _getTypeColor(),
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Tab de informações básicas
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card principal do organismo
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getTypeColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTypeIcon(),
                          color: _getTypeColor(),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.organism.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.organism.scientificName.isNotEmpty)
                              Text(
                                widget.organism.scientificName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getTypeColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getTypeText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Informações básicas
                  _buildInfoRow('Cultura', widget.organism.cropName),
                  _buildInfoRow('Unidade', widget.organism.unit),
                  _buildInfoRow('Status', widget.organism.isActive ? 'Ativo' : 'Inativo'),
                  
                  if (widget.organism.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Descrição',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.organism.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Dados adicionais se disponíveis
          if (_detailedData != null && !_isLoadingData) ...[
            _buildAdditionalInfoCard('Fenologia', _extractList(_detailedData!['fenologia'])),
            _buildAdditionalInfoCard('Partes Afetadas', _extractList(_detailedData!['partes_afetadas'])),
            if (_detailedData!['dano_economico'] != null)
              _buildAdditionalInfoCard('Dano Econômico', _detailedData!['dano_economico']),
            if (_detailedData!['nivel_acao'] != null)
              _buildAdditionalInfoCard('Nível de Ação', _detailedData!['nivel_acao']),
            if (_detailedData!['monitoramento'] != null)
              _buildAdditionalInfoCard('Monitoramento', _detailedData!['monitoramento']),
            if (_detailedData!['tratamento'] != null)
              _buildAdditionalInfoCard('Tratamento', _detailedData!['tratamento']),
          ] else if (_isLoadingData) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tab de sintomas
  Widget _buildSymptomsTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final symptoms = _extractList(_detailedData?['sintomas']) ?? _getSymptoms();
    final conditions = _extractList(_detailedData?['condicoes_favoraveis']) ?? _getFavorableConditions();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sintomas
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Sintomas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...symptoms.map((symptom) => _buildSymptomItem(symptom)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Condições favoráveis
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud, color: Colors.blue, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Condições Favoráveis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...conditions.map((condition) => _buildConditionItem(condition)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab de manejo
  Widget _buildManagementTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final chemical = _extractList(_detailedData?['manejo_quimico']) ?? _getChemicalControl();
    final biological = _extractList(_detailedData?['manejo_biologico']) ?? _getBiologicalControl();
    final cultural = _extractList(_detailedData?['manejo_cultural']) ?? _getCulturalControl();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manejo químico
          _buildManagementCard(
            'Manejo Químico',
            Icons.science,
            Colors.red,
            chemical,
          ),
          
          const SizedBox(height: 16),
          
          // Manejo biológico
          _buildManagementCard(
            'Manejo Biológico',
            Icons.eco,
            Colors.green,
            biological,
          ),
          
          const SizedBox(height: 16),
          
          // Manejo cultural
          _buildManagementCard(
            'Manejo Cultural',
            Icons.agriculture,
            Colors.orange,
            cultural,
          ),
        ],
      ),
    );
  }

  /// Tab de limiares
  Widget _buildThresholdsTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final levels = _detailedData?['niveis_infestacao'] as Map<String, dynamic>? ?? _getInfestationLevels();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Limiares atuais
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.blue, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Limiares de Controle',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildThresholdItem('Baixo', widget.organism.lowLimit, Colors.green),
                  _buildThresholdItem('Médio', widget.organism.mediumLimit, Colors.orange),
                  _buildThresholdItem('Alto', widget.organism.highLimit, Colors.red),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Níveis de infestação detalhados
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.purple, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Níveis de Infestação',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...levels.entries.map((entry) => _buildInfestationLevelItem(entry.key, entry.value.toString())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab de fotos
  Widget _buildPhotosTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final photos = _extractList(_detailedData?['fotos']) ?? _getPhotoUrls();
    
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma foto disponível',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fotos serão adicionadas em breve',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              photos[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 32, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Imagem não disponível',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Métodos auxiliares para construir widgets
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(String title, dynamic data) {
    if (data == null || (data is List && data.isEmpty)) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (data is List)
              ...data.map((item) => _buildListItem(item))
            else
              Text(
                data.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomItem(String symptom) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              symptom,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem(String condition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_queue, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              condition,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(String title, IconData icon, Color color, List<String> items) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildManagementItem(item, color)),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementItem(String item, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdItem(String level, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            level,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '$value ${widget.organism.unit}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfestationLevelItem(String level, String description) {
    Color color;
    IconData icon;
    
    switch (level.toLowerCase()) {
      case 'baixo':
        color = Colors.green;
        icon = Icons.trending_down;
        break;
      case 'medio':
        color = Colors.orange;
        icon = Icons.trending_flat;
        break;
      case 'alto':
        color = Colors.red;
        icon = Icons.trending_up;
        break;
      case 'critico':
        color = Colors.purple;
        icon = Icons.warning;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos para obter dados simulados (baseados no organismo atual)
  
  List<String> _getSymptoms() {
    switch (widget.organism.type) {
      case OccurrenceType.pest:
        return [
          'Desfolha irregular',
          'Presença de lagartas',
          'Buracos nas folhas',
          'Redução do crescimento',
        ];
      case OccurrenceType.disease:
        return [
          'Manchas nas folhas',
          'Amarelecimento',
          'Murchamento',
          'Lesões necróticas',
        ];
      case OccurrenceType.weed:
        return [
          'Competição por nutrientes',
          'Sombra nas plantas',
          'Redução da produtividade',
          'Dificuldade na colheita',
        ];
      default:
        return ['Sintomas não especificados'];
    }
  }

  List<String> _getFavorableConditions() {
    return [
      'Alta umidade relativa',
      'Temperatura entre 20-30°C',
      'Solo com matéria orgânica',
      'Chuvas frequentes',
    ];
  }

  List<String> _getChemicalControl() {
    return [
      'Inseticidas registrados',
      'Aplicação no horário correto',
      'Rotação de ingredientes ativos',
      'Respeitar período de carência',
    ];
  }

  List<String> _getBiologicalControl() {
    return [
      'Inimigos naturais',
      'Fungos entomopatogênicos',
      'Bactérias específicas',
      'Plantas repelentes',
    ];
  }

  List<String> _getCulturalControl() {
    return [
      'Rotação de culturas',
      'Plantio na época correta',
      'Eliminação de restos culturais',
      'Adubação equilibrada',
    ];
  }

  Map<String, String> _getInfestationLevels() {
    return {
      'baixo': '1-2 indivíduos por ponto',
      'medio': '3-5 indivíduos por ponto',
      'alto': '6-8 indivíduos por ponto',
      'critico': 'Mais de 8 indivíduos por ponto',
    };
  }

  List<String> _getPhenology() {
    return ['Vegetativo', 'Floração', 'Frutiicação'];
  }

  List<String> _getAffectedParts() {
    return ['Folhas', 'Caule', 'Raízes'];
  }

  String _getEconomicDamage() {
    return 'Pode causar perdas de até 40% na produtividade';
  }

  List<String> _getPhotoUrls() {
    return []; // Por enquanto, sem fotos
  }

  /// Tab de análises IA v3.0
  Widget _buildV3AnalyticsTab() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_organismV3 == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Dados v3.0 não disponíveis',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este organismo ainda não possui dados\nenriquecidos da versão 3.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge v3.0
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.stars, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dados IA v3.0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        Text(
                          'Análises inteligentes com dados enriquecidos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Widget de Alerta Climático
          if (_organismV3!.climaticConditions != null)
            ClimaticAlertCardWidget(
              organismo: _organismV3!,
              temperaturaAtual: 28.0, // TODO: pegar do GPS/clima atual
              umidadeAtual: 75.0,
            ),
          
          const SizedBox(height: 16),
          
          // Widget de ROI
          if (_organismV3!.agronomicEconomics != null)
            ROICalculatorWidget(
              organismo: _organismV3!,
              areaHa: 1.0, // TODO: pegar do talhão atual
            ),
          
          const SizedBox(height: 16),
          
          // Widget de Análise de Resistência
          if (_organismV3!.resistanceRotation != null)
            ResistanceAnalysisWidget(
              organismo: _organismV3!,
              produtosUsados: [], // TODO: pegar do histórico de aplicações
            ),
          
          const SizedBox(height: 16),
          
          // Widget de Fontes de Referência
          FontesReferenciaWidget(
            organismo: _organismV3!,
            compact: false,
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (widget.organism.type) {
      case OccurrenceType.pest:
        return Colors.red;
      case OccurrenceType.disease:
        return Colors.orange;
      case OccurrenceType.weed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.organism.type) {
      case OccurrenceType.pest:
        return Icons.bug_report;
      case OccurrenceType.disease:
        return Icons.medical_services;
      case OccurrenceType.weed:
        return Icons.local_florist;
      default:
        return Icons.help;
    }
  }

  String _getTypeText() {
    switch (widget.organism.type) {
      case OccurrenceType.pest:
        return 'PRAGA';
      case OccurrenceType.disease:
        return 'DOENÇA';
      case OccurrenceType.weed:
        return 'PLANTA DANINHA';
      default:
        return 'ORGANISMO';
    }
  }

  /// Extrai lista de dados
  List<String>? _extractList(dynamic data) {
    if (data == null) return null;
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }
    return [data.toString()];
  }

  /// Navega para edição do organismo
  void _editOrganism() {
    // Navegar diretamente para o formulário de edição
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrganismFormScreen(
          organism: widget.organism,
          cropId: widget.organism.cropId,
          cropName: widget.organism.cropName,
        ),
      ),
    ).then((_) {
      // Recarregar dados após edição
      _loadDetailedData();
    });
  }
}

