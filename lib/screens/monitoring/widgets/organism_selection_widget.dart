import 'package:flutter/material.dart';
import '../../../services/culture_organisms_monitoring_service.dart';
import '../../../utils/enums.dart';

/// Widget para seleção de organismos do módulo culturas
/// Interface limpa com lista de organismos específicos da cultura
class OrganismSelectionWidget extends StatefulWidget {
  final String culturaId;
  final String culturaNome;
  final OccurrenceType selectedType;
  final Function(OrganismInfo?) onOrganismSelected;
  final OrganismInfo? initialSelection;

  const OrganismSelectionWidget({
    Key? key,
    required this.culturaId,
    required this.culturaNome,
    required this.selectedType,
    required this.onOrganismSelected,
    this.initialSelection,
  }) : super(key: key);

  @override
  State<OrganismSelectionWidget> createState() => _OrganismSelectionWidgetState();
}

class _OrganismSelectionWidgetState extends State<OrganismSelectionWidget> {
  final CultureOrganismsMonitoringService _service = CultureOrganismsMonitoringService();
  List<OrganismInfo> _organisms = [];
  OrganismInfo? _selectedOrganism;
  bool _isLoading = false;
  String? _errorMessage;
  String? _realCultureName;

  @override
  void initState() {
    super.initState();
    _selectedOrganism = widget.initialSelection;
    _loadOrganisms();
  }

  @override
  void didUpdateWidget(OrganismSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType || 
        oldWidget.culturaId != widget.culturaId) {
      _loadOrganisms();
    }
  }

  Future<void> _loadOrganisms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedOrganism = null;
    });

    try {
      // Obter nome real da cultura
      final realCultureName = await _service.getCultureNameById(widget.culturaId);
      
      final organisms = await _service.getOrganismsByCultureAndType(
        culturaId: widget.culturaId,
        culturaNome: realCultureName, // Usar nome real
        tipo: widget.selectedType,
      );

      setState(() {
        _organisms = organisms;
        _realCultureName = realCultureName;
        _isLoading = false;
      });

      // Notificar que nenhum organismo foi selecionado
      widget.onOrganismSelected(null);

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar organismos: $e';
      });
    }
  }

  void _selectOrganism(OrganismInfo organism) {
    setState(() {
      _selectedOrganism = organism;
    });
    widget.onOrganismSelected(organism);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        Text(
          '${_getTypeDisplayName(widget.selectedType)}:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),

        // Conteúdo principal
        if (_isLoading)
          _buildLoadingWidget()
        else if (_errorMessage != null)
          _buildErrorWidget()
        else if (_organisms.isEmpty)
          _buildEmptyWidget()
        else
          _buildOrganismsList(),

        // Organismo selecionado
        if (_selectedOrganism != null) ...[
          const SizedBox(height: 12),
          _buildSelectedOrganism(),
        ],
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9CDB)),
          ),
          SizedBox(height: 12),
          Text(
            'Carregando organismos...',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadOrganisms,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[600], size: 32),
          const SizedBox(height: 8),
          Text(
            'Nenhum organismo encontrado',
            style: TextStyle(
              color: Colors.orange[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Não há ${_getTypeDisplayName(widget.selectedType).toLowerCase()} cadastrados para ${_realCultureName ?? widget.culturaNome}',
            style: TextStyle(
              color: Colors.orange[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrganismsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _organisms.length,
        itemBuilder: (context, index) {
          final organism = _organisms[index];
          final isSelected = _selectedOrganism?.id == organism.id;
          
          return _buildOrganismTile(organism, isSelected);
        },
      ),
    );
  }

  Widget _buildOrganismTile(OrganismInfo organism, bool isSelected) {
    return InkWell(
      onTap: () => _selectOrganism(organism),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? _getTypeBackgroundColor(widget.selectedType) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _getTypeColor(widget.selectedType) : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Row(
          children: [
            // Ícone do organismo
            Text(
              organism.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            
            // Informações do organismo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organism.nome,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? _getTypeColor(widget.selectedType) : const Color(0xFF2C2C2C),
                    ),
                  ),
                  if (organism.nomeCientifico != null && organism.nomeCientifico!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      organism.nomeCientifico!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (organism.categoria != null && organism.categoria!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        organism.categoria!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Indicador de seleção
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: _getTypeColor(widget.selectedType),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedOrganism() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTypeBackgroundColor(widget.selectedType),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getTypeColor(widget.selectedType)),
      ),
      child: Row(
        children: [
          Text(
            _selectedOrganism!.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecionado: ${_selectedOrganism!.nome}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(widget.selectedType),
                  ),
                ),
                if (_selectedOrganism!.nomeCientifico != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _selectedOrganism!.nomeCientifico!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedOrganism = null;
              });
              widget.onOrganismSelected(null);
            },
            icon: Icon(
              Icons.close,
              color: _getTypeColor(widget.selectedType),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return 'Praga';
      case OccurrenceType.disease:
        return 'Doença';
      case OccurrenceType.weed:
        return 'Planta Daninha';
      case OccurrenceType.deficiency:
        return 'Deficiência Nutricional';
      case OccurrenceType.other:
        return 'Outro';
    }
  }

  Color _getTypeColor(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return const Color(0xFF27AE60); // Verde
      case OccurrenceType.disease:
        return const Color(0xFFF2C94C); // Amarelo
      case OccurrenceType.weed:
        return const Color(0xFF2D9CDB); // Azul
      case OccurrenceType.deficiency:
        return const Color(0xFF9B59B6); // Roxo
      case OccurrenceType.other:
        return const Color(0xFF95A5A6); // Cinza
    }
  }

  Color _getTypeBackgroundColor(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return const Color(0xFFDFF5E1); // Verde suave
      case OccurrenceType.disease:
        return const Color(0xFFFFF6D1); // Amarelo pastel
      case OccurrenceType.weed:
        return const Color(0xFFE1F0FF); // Azul claro
      case OccurrenceType.deficiency:
        return const Color(0xFFF3E5F5); // Roxo claro
      case OccurrenceType.other:
        return const Color(0xFFF5F5F5); // Cinza claro
    }
  }
}
