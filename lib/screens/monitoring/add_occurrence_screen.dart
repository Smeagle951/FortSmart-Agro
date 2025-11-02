import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/occurrence.dart';
import '../../utils/enums.dart';
import '../../services/cultura_talhao_service.dart';
import '../../services/integrated_monitoring_service.dart';

/// Tela premium para adicionar nova ocorrência com design profissional
class AddOccurrenceScreen extends StatefulWidget {
  final String cropName;
  final String plotName;
  final int currentPointIndex;
  final int totalPoints;
  final Function(Occurrence) onOccurrenceAdded;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const AddOccurrenceScreen({
    super.key,
    required this.cropName,
    required this.plotName,
    required this.currentPointIndex,
    required this.totalPoints,
    required this.onOccurrenceAdded,
    this.onPrevious,
    this.onNext,
  });

  @override
  State<AddOccurrenceScreen> createState() => _AddOccurrenceScreenState();
}

class _AddOccurrenceScreenState extends State<AddOccurrenceScreen>
    with TickerProviderStateMixin {
  final CulturaTalhaoService _culturaService = CulturaTalhaoService();
  final IntegratedMonitoringService _monitoringService = IntegratedMonitoringService();
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  OccurrenceType _selectedType = OccurrenceType.pest;
  String _selectedName = '';
  double _quantity = 0.0;
  final List<PlantSection> _selectedSections = [];
  
  List<Map<String, dynamic>> _availableOrganisms = [];
  List<Map<String, dynamic>> _filteredOrganisms = [];
  bool _showSuggestions = false;
  bool _isLoading = true;
  bool _isFormValid = false;
  double _infestationIndex = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCatalog();
    _searchController.addListener(_filterOrganisms);
    _quantityController.addListener(_updateInfestationIndex);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  /// Inicializa os organismos específicos da cultura
  Future<void> _initializeCatalog() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Carregar organismos específicos da cultura da fazenda
      final cropId = await _getCropIdByName(widget.cropName);
      if (cropId != null) {
        final organisms = await _culturaService.getOrganismsByCrop(cropId);
        
        setState(() {
          _availableOrganisms = organisms;
          _filteredOrganisms = organisms;
          _isLoading = false;
        });
        
        Logger.info('✅ ${organisms.length} organismos carregados para ${widget.cropName}');
      } else {
        setState(() {
          _availableOrganisms = [];
          _filteredOrganisms = [];
          _isLoading = false;
        });
        _showErrorMessage('Cultura não encontrada: ${widget.cropName}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Erro ao carregar organismos da cultura: $e');
    }
  }

  /// Obtém o ID da cultura pelo nome
  Future<String?> _getCropIdByName(String cropName) async {
    try {
      final culturas = await _culturaService.listarCulturas();
      for (final cultura in culturas) {
        if (cultura['nome']?.toString().toLowerCase() == cropName.toLowerCase()) {
          return cultura['id']?.toString();
        }
      }
      return null;
    } catch (e) {
      Logger.error('Erro ao obter ID da cultura: $e');
      return null;
    }
  }

  /// Filtra organismos baseado na busca
  void _filterOrganisms() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredOrganisms = _availableOrganisms;
        _showSuggestions = false;
      });
      return;
    }

    final filtered = _availableOrganisms.where((organism) {
      final name = organism['nome']?.toString().toLowerCase() ?? '';
      final tipo = organism['tipo']?.toString().toLowerCase() ?? '';
      final categoria = organism['categoria']?.toString().toLowerCase() ?? '';
      
      return name.contains(query) || 
             tipo.contains(query) || 
             categoria.contains(query);
    }).toList();

    setState(() {
      _filteredOrganisms = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  /// Atualiza o índice de infestação
  void _updateInfestationIndex() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    setState(() {
      _quantity = quantity;
      _infestationIndex = _calculateInfestationIndex(quantity, _selectedType, _selectedSections);
      _validateForm();
    });
  }

  /// Calcula o índice de infestação
  double _calculateInfestationIndex(double quantity, OccurrenceType type, List<PlantSection> sections) {
    double baseIndex = quantity;
    
    // Multiplicador por tipo
    switch (type) {
      case OccurrenceType.pest:
        baseIndex *= 1.5; // Pragas têm peso maior
        break;
      case OccurrenceType.disease:
        baseIndex *= 1.3; // Doenças têm peso médio
        break;
      case OccurrenceType.weed:
        baseIndex *= 1.0; // Plantas daninhas têm peso normal
        break;
      case OccurrenceType.deficiency:
        baseIndex *= 1.2; // Deficiências têm peso médio-alto
        break;
      case OccurrenceType.other:
        baseIndex *= 0.8; // Outros têm peso menor
        break;
    }
    
    // Multiplicador por seções afetadas
    final sectionMultiplier = sections.length / 5.0;
    baseIndex *= (1.0 + sectionMultiplier);
    
    return baseIndex.clamp(0.0, 100.0);
  }

  /// Valida o formulário
  void _validateForm() {
    final isValid = _selectedName.isNotEmpty && 
                   _quantity > 0 && 
                   _selectedSections.isNotEmpty;
    
    setState(() {
      _isFormValid = isValid;
    });
  }

  /// Seleciona um organismo
  void _selectOrganism(Map<String, dynamic> organism) {
    setState(() {
      _selectedName = organism['nome']?.toString() ?? '';
      _selectedType = _getOccurrenceType(organism['tipo']?.toString() ?? '');
      _showSuggestions = false;
      _searchController.text = _selectedName;
      _validateForm();
    });
  }

  /// Converte tipo de organismo para OccurrenceType
  OccurrenceType _getOccurrenceType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'praga':
        return OccurrenceType.pest;
      case 'doenca':
        return OccurrenceType.disease;
      case 'daninha':
        return OccurrenceType.weed;
      case 'deficiencia':
        return OccurrenceType.deficiency;
      default:
        return OccurrenceType.other;
    }
  }

  /// Alterna seleção de seção da planta
  void _toggleSection(PlantSection section) {
    setState(() {
      if (_selectedSections.contains(section)) {
        _selectedSections.remove(section);
      } else {
        _selectedSections.add(section);
      }
      _updateInfestationIndex();
    });
  }

  /// Salva a ocorrência
  void _saveOccurrence() {
    if (!_isFormValid) return;

    final occurrence = Occurrence(
      type: _selectedType,
      name: _selectedName,
      infestationIndex: _infestationIndex,
      affectedSections: List.from(_selectedSections),
    );

    widget.onOccurrenceAdded(occurrence);
    Navigator.pop(context);
  }

  /// Exibe mensagem de erro
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        title: Text(
          'Adicionar Ocorrência',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.onPrevious != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: widget.onPrevious,
              tooltip: 'Ponto anterior',
            ),
          if (widget.onNext != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: widget.onNext,
              tooltip: 'Próximo ponto',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildOrganismSearch(),
                      const SizedBox(height: 24),
                      _buildQuantityInput(),
                      const SizedBox(height: 24),
                      _buildPlantSections(),
                      const SizedBox(height: 24),
                      _buildInfestationSlider(),
                      const SizedBox(height: 24),
                      _buildObservations(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.agriculture,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cropName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      widget.plotName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ponto ${widget.currentPointIndex + 1} de ${widget.totalPoints}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrganismSearch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.search,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Buscar Organismo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Digite o nome do organismo...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
                             prefixIcon: Text(
                 _getOccurrenceIcon(_selectedType),
                 style: TextStyle(
                   fontSize: 20,
                   color: Colors.grey.shade600,
                 ),
               ),
            ),
          ),
          if (_showSuggestions) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredOrganisms.length,
                itemBuilder: (context, index) {
                  final organism = _filteredOrganisms[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTypeColor(_getOccurrenceType(organism['tipo']?.toString() ?? '')),
                      child: Text(
                        _getOccurrenceIcon(_getOccurrenceType(organism['tipo']?.toString() ?? '')),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    title: Text(
                      organism['nome']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      organism['tipo']?.toString() ?? '',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    onTap: () => _selectOrganism(organism),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.numbers,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quantidade',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Digite a quantidade...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              suffixIcon: Icon(
                Icons.analytics,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantSections() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Seções Afetadas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlantSection.values.map((section) {
              final isSelected = _selectedSections.contains(section);
              return FilterChip(
                label: Text(section.name),
                selected: isSelected,
                onSelected: (_) => _toggleSection(section),
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.green.shade100,
                checkmarkColor: Colors.green.shade700,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.green.shade700 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfestationSlider() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Índice de Infestação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                '${_infestationIndex.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getSeverityColor(_infestationIndex),
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _getSeverityColor(_infestationIndex),
                  thumbColor: _getSeverityColor(_infestationIndex),
                  overlayColor: _getSeverityColor(_infestationIndex).withOpacity(0.2),
                ),
                child: Slider(
                  value: _infestationIndex,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  onChanged: (value) {
                    setState(() {
                      _infestationIndex = value;
                      _quantityController.text = value.toStringAsFixed(1);
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Baixa',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Média',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Alta',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObservations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Observações',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _observationsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Observações adicionais (opcional)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade600, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isFormValid ? _saveOccurrence : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Salvar Ocorrência',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Obtém ícone baseado no tipo de ocorrência
  String _getOccurrenceIcon(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return '🐛';
      case OccurrenceType.disease:
        return '🦠';
      case OccurrenceType.weed:
        return '🌿';
      case OccurrenceType.deficiency:
        return '⚠️';
      case OccurrenceType.other:
        return '❓';
    }
  }

  /// Obtém cor baseada na severidade
  Color _getSeverityColor(double index) {
    if (index < 25) return Colors.green;
    if (index < 50) return Colors.yellow.shade700;
    if (index < 75) return Colors.orange;
    return Colors.red;
  }

  /// Obtém cor baseada no tipo
  Color _getTypeColor(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return Colors.red.shade100;
      case OccurrenceType.disease:
        return Colors.orange.shade100;
      case OccurrenceType.weed:
        return Colors.green.shade100;
      case OccurrenceType.deficiency:
        return Colors.yellow.shade100;
      case OccurrenceType.other:
        return Colors.grey.shade100;
    }
  }
}
