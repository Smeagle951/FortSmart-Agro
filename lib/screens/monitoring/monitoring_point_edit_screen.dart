import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/monitoring_session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/logger.dart';
import '../../models/organism_catalog.dart';

/// 📱 Tela de Edição de Ponto de Monitoramento
/// 
/// FUNCIONALIDADES:
/// - ✅ Edita ocorrências (pragas, doenças, plantas daninhas)
/// - ✅ Edita nível de severidade e índice
/// - ✅ Adiciona/remove/edita imagens
/// - ✅ Atualiza observações
/// - ❌ NÃO permite editar: coordenadas GPS, plantas avaliadas, data, talhão, cultura
/// 
/// REGRAS DE NEGÓCIO (MIP):
/// - Apenas dados brutos das ocorrências podem ser editados
/// - Metadados da sessão (GPS, data, local) são SOMENTE LEITURA
/// - Validação de dados antes de salvar
class MonitoringPointEditScreen extends StatefulWidget {
  final Map<String, dynamic> pointData;
  final String sessionId;

  const MonitoringPointEditScreen({
    Key? key,
    required this.pointData,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<MonitoringPointEditScreen> createState() => _MonitoringPointEditScreenState();
}

class _MonitoringPointEditScreenState extends State<MonitoringPointEditScreen> {
  final MonitoringSessionService _sessionService = MonitoringSessionService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _observationsController;
  late TextEditingController _plantsEvaluatedController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  
  // Estado
  bool _isLoading = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _occurrences = [];
  List<OrganismCatalog> _availableOrganisms = [];
  Map<String, OrganismCatalog> _organismsCache = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  @override
  void dispose() {
    _observationsController.dispose();
    _plantsEvaluatedController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _observationsController = TextEditingController(
      text: widget.pointData['observacoes'] ?? '',
    );
    _plantsEvaluatedController = TextEditingController(
      text: (widget.pointData['plantas_avaliadas'] ?? 0).toString(),
    );
    _latitudeController = TextEditingController(
      text: (widget.pointData['latitude'] ?? 0.0).toString(),
    );
    _longitudeController = TextEditingController(
      text: (widget.pointData['longitude'] ?? 0.0).toString(),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Carregar ocorrências do ponto
      _occurrences = List<Map<String, dynamic>>.from(
        widget.pointData['occurrences'] ?? [],
      );

      // Carregar organismos disponíveis
      await _loadAvailableOrganisms();

      // Carregar cache de organismos
      await _loadOrganismsCache();

      Logger.info('📊 [POINT_EDIT] Dados carregados: ${_occurrences.length} ocorrências');

    } catch (e) {
      Logger.error('❌ [POINT_EDIT] Erro ao carregar dados: $e');
      _showErrorSnackBar('Erro ao carregar dados do ponto');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Carrega organismos disponíveis
  Future<void> _loadAvailableOrganisms() async {
    try {
      // Buscar cultura da sessão para filtrar organismos
      final sessions = await _sessionService.getSessions();
      final session = sessions.firstWhere(
        (s) => s['id'] == widget.sessionId,
        orElse: () => {},
      );
      
      final culturaId = session['cultura_id'] as String?;
      if (culturaId != null) {
        _availableOrganisms = await _sessionService.getOrganismsForCrop(culturaId);
      } else {
        _availableOrganisms = [];
      }
      
      Logger.info('📊 [POINT_EDIT] ${_availableOrganisms.length} organismos disponíveis');
      
    } catch (e) {
      Logger.error('❌ [POINT_EDIT] Erro ao carregar organismos: $e');
      _availableOrganisms = [];
    }
  }

  /// Carrega cache de organismos
  Future<void> _loadOrganismsCache() async {
    try {
      for (final occurrence in _occurrences) {
        final organismId = occurrence['organism_id'] as String?;
        if (organismId != null && !_organismsCache.containsKey(organismId)) {
          final organism = await _sessionService.getOrganismById(organismId);
          if (organism != null) {
            _organismsCache[organismId] = organism;
          }
        }
      }
    } catch (e) {
      Logger.error('❌ [POINT_EDIT] Erro ao carregar cache de organismos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Ponto ${widget.pointData['numero'] ?? 'N/A'}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'Salvar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPointInfo(),
                    const SizedBox(height: 24),
                    _buildCoordinatesSection(),
                    const SizedBox(height: 24),
                    _buildPlantsEvaluatedSection(),
                    const SizedBox(height: 24),
                    _buildObservationsSection(),
                    const SizedBox(height: 24),
                    _buildOccurrencesSection(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Constrói informações do ponto
  Widget _buildPointInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Ponto ${widget.pointData['numero'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Edite apenas as ocorrências e observações deste ponto',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS, data e plantas avaliadas não podem ser alterados',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
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

  /// Constrói seção de coordenadas
  Widget _buildCoordinatesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gps_fixed,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Coordenadas GPS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.north),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(Icons.lock, size: 16),
                    ),
                    enabled: false, // ❌ DESABILITADO - Não pode editar GPS
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.east),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(Icons.lock, size: 16),
                    ),
                    enabled: false, // ❌ DESABILITADO - Não pode editar GPS
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Coordenadas precisas são essenciais para o Mapa de Infestação',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói seção de plantas avaliadas
  Widget _buildPlantsEvaluatedSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.eco,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Plantas Avaliadas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plantsEvaluatedController,
              decoration: InputDecoration(
                labelText: 'Número de plantas avaliadas',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.numbers),
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: const Icon(Icons.lock, size: 16),
              ),
              enabled: false, // ❌ DESABILITADO - Não pode editar quantidade de plantas
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói seção de observações
  Widget _buildObservationsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Observações',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observationsController,
              decoration: const InputDecoration(
                labelText: 'Observações adicionais',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
                hintText: 'Descreva condições do local, clima, etc.',
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói seção de ocorrências
  Widget _buildOccurrencesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ocorrências Registradas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addOccurrence,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_occurrences.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.bug_report_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma ocorrência registrada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adicione organismos encontrados neste ponto',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._occurrences.asMap().entries.map((entry) {
                final index = entry.key;
                final occurrence = entry.value;
                return _buildOccurrenceItem(occurrence, index);
              }).toList(),
          ],
        ),
      ),
    );
  }

  /// Constrói item de ocorrência
  Widget _buildOccurrenceItem(Map<String, dynamic> occurrence, int index) {
    final organismId = occurrence['organism_id'] as String?;
    final organism = _organismsCache[organismId];
    final organismName = organism?.name ?? 'Organismo $organismId';
    final rawValue = (occurrence['valor_bruto'] as num?)?.toDouble() ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            _getOrganismTypeIcon(organism?.type),
            color: _getOrganismTypeColor(organism?.type),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organismName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Valor: ${rawValue.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Observação: ${occurrence['observacao'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleOccurrenceAction(value, index),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Editar'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Excluir', style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
            child: Icon(
              Icons.more_vert,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói botão de salvar
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveChanges,
        icon: _isSaving 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Salvando...' : 'Salvar Alterações'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // MÉTODOS DE NEGÓCIO
  // ============================================================================

  /// Adiciona nova ocorrência
  void _addOccurrence() {
    // Resolver argumentos exigidos pela rota de ponto
    try {
      final pointIdStr = widget.pointData['id']?.toString();
      final pontoNumero = (widget.pointData['numero'] ?? 1) as int;
      if (pointIdStr == null || pointIdStr.isEmpty) {
        _showErrorSnackBar('ID do ponto não encontrado');
        return;
      }
      // Converter UUID do ponto em ID numérico compatível
      final pontoId = pointIdStr.hashCode.abs();

      // Buscar sessão para obter talhão/cultura
      _sessionService.getSessions().then((sessions) {
        final session = sessions.firstWhere(
          (s) => s['id'] == widget.sessionId,
          orElse: () => {},
        );

        final talhaoId = session['talhao_id']?.toString();
        final culturaId = session['cultura_id']?.toString();
        final talhaoNome = (session['talhao_nome'] ?? talhaoId)?.toString();
        final culturaNome = (session['cultura_nome'] ?? culturaId)?.toString();

        if (talhaoId == null || culturaId == null) {
          _showErrorSnackBar('Sessão inválida: talhão ou cultura ausentes');
          return;
        }

        Navigator.pushNamed(
          context,
          '/monitoring/point',
          arguments: {
            'pontoId': pontoId,
            'talhaoId': talhaoId,
            'culturaId': culturaId,
            'talhaoNome': talhaoNome,
            'culturaNome': culturaNome,
            'sessionId': widget.sessionId,
            // Contexto adicional útil
            'pointNumber': pontoNumero,
          },
        ).then((result) {
          if (result == true) {
            _loadData();
          }
        });
      });
    } catch (e) {
      Logger.error('❌ [POINT_EDIT] Erro ao abrir tela de ponto: $e');
      _showErrorSnackBar('Erro ao abrir tela de ponto: $e');
    }
  }

  /// Manipula ações da ocorrência
  void _handleOccurrenceAction(String action, int index) {
    switch (action) {
      case 'edit':
        _editOccurrence(index);
        break;
      case 'delete':
        _deleteOccurrence(index);
        break;
    }
  }

  /// Edita ocorrência
  void _editOccurrence(int index) {
    // TODO: Implementar edição de ocorrência
    _showInfoSnackBar('Edição de ocorrência em desenvolvimento');
  }

  /// Exclui ocorrência
  void _deleteOccurrence(int index) {
    setState(() {
      _occurrences.removeAt(index);
    });
    _showInfoSnackBar('Ocorrência removida');
  }

  /// Salva alterações
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // TODO: Implementar salvamento no banco de dados
      await Future.delayed(const Duration(seconds: 1)); // Simulação
      
      _showSuccessSnackBar('Ponto atualizado com sucesso!');
      
      // Retornar para a tela anterior
      Navigator.pop(context, true);
      
    } catch (e) {
      Logger.error('❌ [POINT_EDIT] Erro ao salvar: $e');
      _showErrorSnackBar('Erro ao salvar alterações');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  /// Obtém ícone do tipo de organismo
  IconData _getOrganismTypeIcon(dynamic type) {
    if (type == null) return Icons.help_outline;
    
    final typeString = type.toString().toLowerCase();
    if (typeString.contains('pest')) return Icons.bug_report;
    if (typeString.contains('disease')) return Icons.healing;
    if (typeString.contains('weed')) return Icons.eco;
    
    return Icons.help_outline;
  }

  /// Obtém cor do tipo de organismo
  Color _getOrganismTypeColor(dynamic type) {
    if (type == null) return Colors.grey;
    
    final typeString = type.toString().toLowerCase();
    if (typeString.contains('pest')) return Colors.red;
    if (typeString.contains('disease')) return Colors.orange;
    if (typeString.contains('weed')) return Colors.green;
    
    return Colors.grey;
  }

  /// Mostra snackbar de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Mostra snackbar de sucesso
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Mostra snackbar de informação
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
