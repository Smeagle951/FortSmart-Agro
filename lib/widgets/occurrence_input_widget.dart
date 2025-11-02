import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/integrated_monitoring_service.dart';
import '../utils/logger.dart';

/// Widget para entrada de ocorrências com integração ao catálogo de organismos
class OccurrenceInputWidget extends StatefulWidget {
  final String cropName;
  final String fieldId;
  final Function(Map<String, dynamic>) onOccurrenceAdded;
  final List<Map<String, dynamic>>? historicalAlerts;

  const OccurrenceInputWidget({
    Key? key,
    required this.cropName,
    required this.fieldId,
    required this.onOccurrenceAdded,
    this.historicalAlerts,
  }) : super(key: key);

  @override
  _OccurrenceInputWidgetState createState() => _OccurrenceInputWidgetState();
}

class _OccurrenceInputWidgetState extends State<OccurrenceInputWidget> {
  final IntegratedMonitoringService _monitoringService = IntegratedMonitoringService();
  final TextEditingController _organismController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadOrganismSuggestions();
  }

  @override
  void dispose() {
    _organismController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _monitoringService.dispose();
    super.dispose();
  }

  /// Carrega sugestões de organismos baseadas na cultura
  Future<void> _loadOrganismSuggestions() async {
    try {
      setState(() => _isLoading = true);
      
      // Carregar dados reais do módulo de culturas
      final suggestions = await _monitoringService.getOrganismSuggestions(widget.cropName);
      
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
      
      Logger.info('✅ ${suggestions.length} organismos reais carregados para ${widget.cropName}');
    } catch (e) {
      Logger.error('Erro ao carregar sugestões: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Filtra sugestões baseadas no texto digitado
  List<Map<String, dynamic>> _getFilteredSuggestions() {
    if (_organismController.text.isEmpty) return _suggestions;
    
    return _suggestions.where((suggestion) =>
      suggestion['name'].toString().toLowerCase()
          .contains(_organismController.text.toLowerCase())
    ).toList();
  }

  /// Processa a ocorrência informada
  Future<void> _processOccurrence() async {
    if (_organismController.text.isEmpty || _quantityController.text.isEmpty) {
      _showErrorSnackBar('Preencha o organismo e a quantidade');
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      _showErrorSnackBar('Quantidade deve ser um número positivo');
      return;
    }

    try {
      setState(() => _isLoading = true);

      final processedOccurrence = await _monitoringService.processOccurrence(
        organismName: _organismController.text.trim(),
        quantity: quantity,
        cropName: widget.cropName,
        fieldId: widget.fieldId,
        notes: _notesController.text.trim(),
      );

      if (processedOccurrence != null) {
        // Limpar campos
        _organismController.clear();
        _quantityController.clear();
        _notesController.clear();
        
        // Notificar sucesso
        _showSuccessSnackBar('Ocorrência registrada: ${processedOccurrence.organismName}');
        
        // Chamar callback
        widget.onOccurrenceAdded(processedOccurrence.toMap());
        
        // Atualizar mapa de infestação
        await _monitoringService.updateInfestationMap(widget.fieldId);
      } else {
        _showErrorSnackBar('Organismo não encontrado no catálogo');
      }
    } catch (e) {
      Logger.error('Erro ao processar ocorrência: $e');
      _showErrorSnackBar('Erro ao processar ocorrência');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Registrar Ocorrência',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alertas históricos
            if (widget.historicalAlerts != null && widget.historicalAlerts!.isNotEmpty)
              _buildHistoricalAlerts(),

            const SizedBox(height: 16),

            // Campo de organismo
            TextField(
              controller: _organismController,
              decoration: InputDecoration(
                labelText: 'Organismo (praga/doença/daninha)',
                hintText: 'Ex: bicudo, lagarta, ferrugem...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _showSuggestions = value.isNotEmpty;
                });
              },
              onTap: () {
                setState(() {
                  _showSuggestions = _organismController.text.isNotEmpty;
                });
              },
            ),

            // Sugestões de organismos
            if (_showSuggestions && _getFilteredSuggestions().isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _getFilteredSuggestions().length,
                  itemBuilder: (context, index) {
                    final suggestion = _getFilteredSuggestions()[index];
                    return ListTile(
                      leading: Text(
                        suggestion['icon'] ?? '🔍',
                        style: TextStyle(fontSize: 20),
                      ),
                      title: Text(suggestion['name']),
                      subtitle: Text('${suggestion['type']} • ${suggestion['unit']}'),
                      onTap: () {
                        _organismController.text = suggestion['name'];
                        setState(() {
                          _showSuggestions = false;
                        });
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Campo de quantidade
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Quantidade encontrada',
                hintText: 'Ex: 20',
                prefixIcon: Icon(Icons.numbers),
                suffixText: 'unidades',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Campo de observações
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Observações (opcional)',
                hintText: 'Detalhes sobre a ocorrência...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botão de registrar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _processOccurrence,
                icon: _isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.add),
                label: Text(
                  _isLoading ? 'Processando...' : 'Registrar Ocorrência',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Informações sobre o processo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Como funciona:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Digite o nome do organismo (ex: "bicudo")\n'
                    '2. Informe a quantidade encontrada (ex: 20)\n'
                    '3. O sistema identifica automaticamente no catálogo\n'
                    '4. Calcula a porcentagem baseada nos limiares\n'
                    '5. Atualiza o mapa de infestação',
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
    );
  }

  /// Widget para exibir alertas históricos
  Widget _buildHistoricalAlerts() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Alertas Históricos:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.historicalAlerts!.map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(alert['icon'] ?? '⚠️'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert['message'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
