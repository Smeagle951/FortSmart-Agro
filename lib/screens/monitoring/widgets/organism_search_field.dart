import 'package:flutter/material.dart';
import '../../../services/culture_organisms_service.dart';

/// Widget para busca de organismos com autocomplete
class OrganismSearchField extends StatefulWidget {
  final String? selectedOrganism;
  final int culturaId;
  final String selectedType; // Tipo selecionado (Praga, Doença, Daninha)
  final Function(String) onOrganismSelected;
  final String? initialValue;

  const OrganismSearchField({
    Key? key,
    required this.culturaId,
    required this.selectedType,
    required this.onOrganismSelected,
    this.selectedOrganism,
    this.initialValue,
  }) : super(key: key);

  @override
  State<OrganismSearchField> createState() => _OrganismSearchFieldState();
}

class _OrganismSearchFieldState extends State<OrganismSearchField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final CultureOrganismsService _organismsService = CultureOrganismsService();
  List<String> _availableOrganisms = [];
  List<String> _filteredOrganisms = [];
  bool _showSuggestions = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrganismsForCulture();
    _searchController.text = widget.selectedOrganism ?? '';
  }

  @override
  void didUpdateWidget(OrganismSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.culturaId != widget.culturaId || oldWidget.selectedType != widget.selectedType) {
      _loadOrganismsForCulture();
      _searchController.clear();
      widget.onOrganismSelected('');
    }
  }

  Future<void> _loadOrganismsForCulture() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Inicializar dados padrão se necessário
      await _organismsService.initializeDefaultData();
      
      // Carregar organismos baseado na cultura real da fazenda
      final organisms = await _organismsService.getOrganismsByTalhaoId(
        widget.culturaId, // Usando como talhaoId
        widget.selectedType
      );
      
      setState(() {
        _availableOrganisms = organisms;
        _filteredOrganisms = organisms;
        _isLoading = false;
      });
      
      print('✅ Carregados ${organisms.length} organismos para ${widget.selectedType}');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Erro ao carregar organismos: $e');
    }
  }


  void _filterOrganisms(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOrganisms = _availableOrganisms;
      } else {
        _filteredOrganisms = _availableOrganisms
            .where((organism) =>
                organism.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _showSuggestions = query.isNotEmpty && _filteredOrganisms.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.selectedType.toLowerCase() == 'outro' 
              ? 'Descrição (digite manualmente):'
              : 'Infestação:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextFormField(
              controller: _searchController,
              focusNode: _focusNode,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: widget.selectedType.toLowerCase() == 'outro' 
                    ? 'Digite a descrição da ocorrência...'
                    : 'Buscar infestação...',
                prefixIcon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9CDB)),
                          ),
                        ),
                      )
                    : Icon(
                        widget.selectedType.toLowerCase() == 'outro' 
                            ? Icons.edit 
                            : Icons.search, 
                        color: const Color(0xFF95A5A6)
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2D9CDB), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: widget.selectedType.toLowerCase() == 'outro' 
                  ? (value) => widget.onOrganismSelected(value)
                  : _filterOrganisms,
              onTap: () {
                if (widget.selectedType.toLowerCase() != 'outro') {
                  setState(() {
                    _showSuggestions = _searchController.text.isNotEmpty;
                  });
                }
              },
            ),
            if (_showSuggestions && _filteredOrganisms.isNotEmpty && widget.selectedType.toLowerCase() != 'outro')
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredOrganisms.length,
                    itemBuilder: (context, index) {
                      final organism = _filteredOrganisms[index];
                      return ListTile(
                        title: Text(
                          organism,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                        onTap: () {
                          _searchController.text = organism;
                          widget.onOrganismSelected(organism);
                          setState(() {
                            _showSuggestions = false;
                          });
                          _focusNode.unfocus();
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
