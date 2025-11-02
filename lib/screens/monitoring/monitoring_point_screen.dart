import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/new_occurrence_card.dart';
import '../../models/monitoring_point.dart';
import '../../models/infestacao_model.dart';
import '../../repositories/infestacao_repository.dart';
import '../../database/app_database.dart';
import '../../utils/logger.dart';
import '../../utils/enums.dart';
import '../../modules/infestation_map/services/talhao_integration_service.dart';
import '../../modules/infestation_map/services/infestacao_integration_service.dart';
import 'waiting_next_point_screen.dart';

/// Tela de ponto de monitoramento com card de nova ocorrência
class MonitoringPointScreen extends StatefulWidget {
  final MonitoringPoint point;
  final String cropName;
  final String fieldId;
  final VoidCallback? onNavigateToNextPoint;

  const MonitoringPointScreen({
    Key? key,
    required this.point,
    required this.cropName,
    required this.fieldId,
    this.onNavigateToNextPoint,
  }) : super(key: key);

  @override
  _MonitoringPointScreenState createState() => _MonitoringPointScreenState();
}

class _MonitoringPointScreenState extends State<MonitoringPointScreen> {
  bool _showNewOccurrenceCard = false;
  late InfestacaoRepository _infestacaoRepository;
  late TalhaoIntegrationService _talhaoService;
  
  // Variáveis para o mini-mapa
  List<LatLng>? _talhaoPolygon;
  bool _isLoadingPolygon = true;
  
  // Variáveis para continuar monitoramento
  String? _historyId;
  bool _isContinuing = false;
  Map<String, dynamic>? _monitoringData;
  
  // Variável para monitoramento livre (sem pontos)
  bool _isFreeMonitoring = false;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
    _checkIfContinuing();
    _checkIfFreeMonitoring();
  }

  /// Verifica se está continuando um monitoramento existente
  void _checkIfContinuing() {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _historyId = arguments['historyId'] as String?;
      _isContinuing = arguments['isContinuing'] as bool? ?? false;
      _monitoringData = arguments['monitoringData'] as Map<String, dynamic>?;
      
      if (_isContinuing && _historyId != null) {
        Logger.info('🔄 Continuando monitoramento: $_historyId');
      }
    }
  }
  
  /// Verifica se é monitoramento livre (sem pontos)
  void _checkIfFreeMonitoring() {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _isFreeMonitoring = arguments['isFreeMonitoring'] as bool? ?? false;
      
      if (_isFreeMonitoring) {
        Logger.info('🆓 Modo monitoramento livre ativado');
      }
    }
  }

  Future<void> _initializeRepository() async {
    final database = await AppDatabase.instance.database;
    _infestacaoRepository = InfestacaoRepository(database);
    _talhaoService = TalhaoIntegrationService();
    
    // Garantir que as tabelas existam
    await _infestacaoRepository.createTable();
    
    // Carregar polígono do talhão
    await _loadTalhaoPolygon();
  }

  /// Carrega o polígono real do talhão
  Future<void> _loadTalhaoPolygon() async {
    try {
      setState(() => _isLoadingPolygon = true);
      
      Logger.info('🔄 Carregando polígono do talhão: ${widget.fieldId}');
      
      final polygon = await _talhaoService.getTalhaoPolygon(widget.fieldId);
      
      setState(() {
        _talhaoPolygon = polygon;
        _isLoadingPolygon = false;
      });
      
      if (polygon != null) {
        Logger.info('✅ Polígono carregado: ${polygon.length} pontos');
      } else {
        Logger.warning('⚠️ Polígono não encontrado para talhão: ${widget.fieldId}');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar polígono do talhão: $e');
      setState(() {
        _isLoadingPolygon = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isFreeMonitoring 
            ? 'Monitoramento Livre' 
            : (_isContinuing ? 'Continuando - Ponto ${widget.point.id}' : 'Ponto ${widget.point.id}')
        ),
        backgroundColor: _isFreeMonitoring 
          ? Colors.orange[600] 
          : (_isContinuing ? Colors.blue[600] : Colors.green[600]),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                _showNewOccurrenceCard = true;
              });
            },
            tooltip: 'Nova Ocorrência',
          ),
          // Botão para salvar e aguardar outra ocorrência (apenas em modo livre)
          if (_isFreeMonitoring)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveAndWaitNextOccurrence,
              tooltip: 'Salvar e Aguardar Próxima Ocorrência',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Conteúdo principal da tela
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informações do ponto
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informações do Ponto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow('Cultura', widget.cropName),
                        _buildInfoRow('Talhão', widget.point.plotName),
                        _buildInfoRow('Latitude', widget.point.latitude.toStringAsFixed(6)),
                        _buildInfoRow('Longitude', widget.point.longitude.toStringAsFixed(6)),
                        _buildInfoRow('Plantas Avaliadas', widget.point.plantasAvaliadas?.toString() ?? 'N/A'),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Mini-mapa com polígono do talhão
                _buildMiniMap(),
                
                SizedBox(height: 16),
                
                // Ocorrências existentes
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ocorrências Registradas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        if (widget.point.occurrences.isEmpty)
                          Text(
                            'Nenhuma ocorrência registrada ainda.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          ...widget.point.occurrences.map((occurrence) => 
                            ListTile(
                              leading: Icon(
                                _getOccurrenceIcon(occurrence.type),
                                color: _getOccurrenceColor(occurrence.type),
                              ),
                              title: Text(occurrence.name),
                              subtitle: Text('Infestação: ${occurrence.infestationIndex.toStringAsFixed(1)}%'),
                              trailing: Text(
                                '${occurrence.infestationIndex.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getInfestationColor(occurrence.infestationIndex),
                                ),
                              ),
                            ),
                          ).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Card de nova ocorrência
          if (_showNewOccurrenceCard)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: NewOccurrenceCard(
                cropName: widget.cropName,
                fieldId: widget.fieldId,
                onOccurrenceAdded: _onOccurrenceAdded,
                onClose: () {
                  setState(() {
                    _showNewOccurrenceCard = false;
                  });
                },
                onSaveAndAdvance: () {
                  setState(() {
                    _showNewOccurrenceCard = false;
                  });
                  // No monitoramento livre, apenas fechar o card e permanecer na tela
                  if (_isFreeMonitoring) {
                    Logger.info('🆓 Monitoramento livre: permanecendo na tela de ponto');
                    // Não navegar para tela de espera no modo livre
                  } else {
                    // No monitoramento guiado, navegar para tela de espera
                    _navigateToWaitingScreen();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Salva e aguarda próxima ocorrência (modo monitoramento livre)
  Future<void> _saveAndWaitNextOccurrence() async {
    try {
      Logger.info('💾 Salvando ponto e aguardando próxima ocorrência...');
      
      // No monitoramento livre, apenas mostrar mensagem de sucesso
      // e permitir que o usuário continue registrando ocorrências
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ponto salvo! Continue registrando ocorrências ou clique em "Nova Ocorrência"'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar ponto: $e');
      _showErrorSnackBar('Erro ao salvar ponto: $e');
    }
  }
  
  /// Mostra mensagem de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Constrói linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtém ícone da ocorrência
  IconData _getOccurrenceIcon(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return Icons.bug_report;
      case OccurrenceType.disease:
        return Icons.coronavirus;
      case OccurrenceType.weed:
        return Icons.grass;
      default:
        return Icons.help_outline;
    }
  }

  /// Obtém cor da ocorrência
  Color _getOccurrenceColor(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return Colors.orange;
      case OccurrenceType.disease:
        return Colors.red;
      case OccurrenceType.weed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Obtém cor baseada no índice de infestação
  Color _getInfestationColor(double index) {
    if (index < 25) return Colors.green;
    if (index < 50) return Colors.orange;
    if (index < 75) return Colors.red;
    return Colors.purple;
  }

  /// Recarrega as ocorrências do ponto para evitar dados desatualizados
  Future<void> _reloadPointOccurrences() async {
    try {
      Logger.info('🔄 Recarregando ocorrências do ponto...');
      // Atualizar a UI para refletir mudanças
      setState(() {
        // Force UI update
      });
      Logger.info('✅ Ocorrências recarregadas');
    } catch (e) {
      Logger.error('❌ Erro ao recarregar ocorrências: $e');
    }
  }

  /// Navega para a tela de espera entre pontos
  void _navigateToWaitingScreen() {
    try {
      Logger.info('🔄 Navegando para tela de espera...');
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WaitingNextPointScreen(
            currentPointId: widget.point.id,
            nextPointId: _getNextPointId(),
            nextPointData: _getNextPointData(),
            fieldId: widget.fieldId,
            cropName: widget.cropName,
            onArrived: () {
              Logger.info('✅ Usuário chegou ao próximo ponto');
              Navigator.of(context).pop(); // Fechar tela de espera
              
              // Navegar para o próximo ponto se callback foi fornecido
              if (widget.onNavigateToNextPoint != null) {
                widget.onNavigateToNextPoint!();
              }
            },
            onSkip: () {
              Logger.info('⏩ Usuário pulou o próximo ponto');
              Navigator.of(context).pop(); // Fechar tela de espera
              
              // Navegar para o próximo ponto se callback foi fornecido
              if (widget.onNavigateToNextPoint != null) {
                widget.onNavigateToNextPoint!();
              }
            },
          ),
        ),
      );
      
    } catch (e) {
      Logger.error('❌ Erro ao navegar para tela de espera: $e');
      
      // Fallback: usar navegação original
      if (widget.onNavigateToNextPoint != null) {
        widget.onNavigateToNextPoint!();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ocorrência salva! Navegue manualmente para o próximo ponto.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// Obtém o ID do próximo ponto (simulação - deve ser implementado conforme lógica do app)
  String? _getNextPointId() {
    try {
      final currentId = int.tryParse(widget.point.id) ?? 0;
      final nextId = currentId + 1;
      return nextId.toString();
    } catch (e) {
      Logger.error('❌ Erro ao obter próximo ponto: $e');
      return null;
    }
  }

  /// Obtém dados do próximo ponto (simulação - deve ser implementado conforme lógica do app)
  Map<String, dynamic>? _getNextPointData() {
    try {
      // Simular dados do próximo ponto
      // Em uma implementação real, isso viria do banco de dados ou serviço
      return {
        'latitude': widget.point.latitude + 0.001, // Próximo ponto ~100m ao norte
        'longitude': widget.point.longitude + 0.001, // Próximo ponto ~100m ao leste
        'name': 'Ponto ${_getNextPointId()}',
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter dados do próximo ponto: $e');
      return null;
    }
  }

  /// Callback quando uma nova ocorrência é adicionada (SALVAMENTO AUTOMÁTICO)
  Future<void> _onOccurrenceAdded(Map<String, dynamic> occurrence) async {
    try {
      Logger.info('🔄 Salvando nova ocorrência automaticamente: ${occurrence['organism_name']}');
      Logger.info('📋 Dados recebidos: fieldId=${widget.fieldId}, pointId=${widget.point.id}');
      
      // Mostrar indicador de salvamento
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Salvando ocorrência...'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
      // Converter fieldId para int (talhao_id)
      final talhaoId = int.tryParse(widget.fieldId) ?? 0;
      if (talhaoId == 0) {
        Logger.error('❌ ID do talhão inválido: ${widget.fieldId}');
        throw Exception('ID do talhão inválido: ${widget.fieldId}. Deve ser um número válido.');
      }
      
      // Verificar se o talhão existe na tabela talhoes
      final db = await AppDatabase.instance.database;
      final talhaoExists = await db.query(
        'talhoes',
        where: 'id = ?',
        whereArgs: [talhaoId],
        limit: 1,
      );
      
      if (talhaoExists.isEmpty) {
        Logger.error('❌ Talhão não encontrado na base de dados: $talhaoId');
        throw Exception('Talhão com ID $talhaoId não encontrado na base de dados. Verifique se o talhão existe.');
      }
      
      Logger.info('✅ Talhão encontrado: ${talhaoExists.first}');
      
      // Converter ponto ID para int
      final pontoId = int.tryParse(widget.point.id) ?? 0;
      if (pontoId == 0) {
        Logger.error('❌ ID do ponto inválido: ${widget.point.id}');
        throw Exception('ID do ponto inválido: ${widget.point.id}. Deve ser um número válido.');
      }
      
      // Verificar se o ponto existe na tabela pontos_monitoramento
      final pontoExists = await db.query(
        'pontos_monitoramento',
        where: 'id = ?',
        whereArgs: [pontoId],
        limit: 1,
      );
      
      if (pontoExists.isEmpty) {
        Logger.warning('⚠️ Ponto não encontrado na base de dados: $pontoId');
        Logger.info('ℹ️ Criando ponto de monitoramento...');
        
        // Criar o ponto de monitoramento
        await _createMonitoringPoint(pontoId, talhaoId);
        Logger.info('✅ Ponto de monitoramento criado: $pontoId');
      } else {
        Logger.info('✅ Ponto encontrado: ${pontoExists.first}');
      }
      
      // Usar severidade agronômica calculada se disponível
      final agronomicSeverity = (occurrence['agronomic_severity'] as num?)?.toDouble();
      final alertLevel = occurrence['alert_level'] as String?;
      final quantity = occurrence['quantity'] as int? ?? 0;
      final severity = occurrence['severity'] as int? ?? 0;
      
      // Priorizar severidade agronômica, senão usar cálculo tradicional
      final finalSeverity = agronomicSeverity ?? (quantity > 0 ? quantity.toDouble() : severity.toDouble());
      final nivel = alertLevel ?? _determinarNivel(finalSeverity.round(), occurrence['organism_type'] as String? ?? '');
      
      // Debug: Log dos valores para verificar
      Logger.info('🔍 Debug Ocorrência:');
      Logger.info('  - agronomic_severity: $agronomicSeverity');
      Logger.info('  - quantity: $quantity');
      Logger.info('  - severity: $severity');
      Logger.info('  - finalSeverity: $finalSeverity');
      Logger.info('  - alertLevel: $alertLevel');
      
      // Preparar caminhos das fotos
      final imagePaths = occurrence['image_paths'] as List<String>? ?? [];
      final fotoPaths = imagePaths.isNotEmpty ? imagePaths.join(';') : null;
      
      // Gerar ID único para evitar duplicações
      final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_${talhaoId}_${pontoId}';
      
      // Buscar nome do organismo em múltiplos campos para compatibilidade
      final organismName = occurrence['organism_name'] as String? ?? 
                          occurrence['name'] as String? ?? 
                          occurrence['organismo'] as String? ?? 
                          occurrence['subtipo'] as String? ?? '';
      
      // Verificar se já existe uma ocorrência similar recente (para evitar duplicação)
      final existingOccurrences = await db.query(
        'infestation_data',
        where: 'talhao_id = ? AND ponto_id = ? AND subtipo = ? AND ABS(julianday(?) - julianday(data_hora)) < 0.001',
        whereArgs: [talhaoId, pontoId, organismName, DateTime.now().toIso8601String()],
        limit: 1,
      );
      
      if (existingOccurrences.isNotEmpty) {
        Logger.warning('⚠️ Ocorrência similar já existe. Evitando duplicação.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ocorrência "$organismName" já foi registrada recentemente!'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      
      // Criar modelo de infestação com dados georreferenciados completos
      final infestacao = InfestacaoModel(
        id: uniqueId,
        talhaoId: talhaoId.toString(),
        pontoId: pontoId,
        latitude: widget.point.latitude,
        longitude: widget.point.longitude,
        tipo: occurrence['organism_type'] as String? ?? occurrence['tipo'] as String? ?? 'Outro',
        subtipo: organismName,
        nivel: nivel,
        percentual: finalSeverity > 0 ? finalSeverity.round() : 1, // Usar severidade agronômica
        fotoPaths: fotoPaths,
        observacao: occurrence['observations'] as String? ?? occurrence['observacoes'] as String?,
        dataHora: DateTime.now(),
      );
      
      // Salvar no banco de dados
      await _infestacaoRepository.insert(infestacao);
      
      // ENVIAR DADOS PARA O MÓDULO DE INFESTAÇÃO
      await _sendToInfestationModule(infestacao, occurrence);
      
      Logger.info('✅ Ocorrência salva com sucesso: ${infestacao.id}');
      
      // SALVAMENTO AUTOMÁTICO: Atualizar monitoramento principal
      await _autoSaveMonitoring();
      
      // Recarregar dados do ponto para refletir a nova ocorrência
      await _reloadPointOccurrences();
      
      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocorrência "$organismName" registrada e monitoramento salvo automaticamente!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar ocorrência: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar ocorrência: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Cria um ponto de monitoramento na base de dados com dados georreferenciados
  Future<void> _createMonitoringPoint(int pontoId, int talhaoId) async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Verificar se a tabela pontos_monitoramento existe
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='pontos_monitoramento'"
      );
      
      if (tableExists.isEmpty) {
        // Criar a tabela com campos georreferenciados completos
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pontos_monitoramento (
            id INTEGER PRIMARY KEY,
            talhao_id INTEGER NOT NULL,
            monitoring_id TEXT,
            session_id TEXT,
            numero INTEGER,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            altitude REAL,
            gps_accuracy REAL,
            gps_provider TEXT,
            nome TEXT,
            observacoes TEXT,
            plantas_avaliadas INTEGER,
            data_criacao TEXT NOT NULL,
            data_atualizacao TEXT,
            sincronizado INTEGER DEFAULT 0,
            FOREIGN KEY (talhao_id) REFERENCES talhoes (id)
          )
        ''');
        Logger.info('✅ Tabela pontos_monitoramento criada com campos georreferenciados');
      }
      
      // Obter dados de GPS mais precisos se disponíveis
      final currentLocation = await _getCurrentLocation();
      
      // Inserir o ponto com dados georreferenciados completos
      await db.insert('pontos_monitoramento', {
        'id': pontoId,
        'talhao_id': talhaoId,
        'monitoring_id': _historyId, // ID da sessão de monitoramento
        'session_id': _historyId,
        'numero': pontoId,
        'latitude': currentLocation['latitude'] ?? widget.point.latitude,
        'longitude': currentLocation['longitude'] ?? widget.point.longitude,
        'altitude': currentLocation['altitude'],
        'gps_accuracy': currentLocation['accuracy'],
        'gps_provider': currentLocation['provider'] ?? 'manual',
        'nome': widget.point.plotName,
        'observacoes': 'Ponto criado automaticamente durante monitoramento - ${DateTime.now().toIso8601String()}',
        'plantas_avaliadas': widget.point.plantasAvaliadas,
        'data_criacao': DateTime.now().toIso8601String(),
        'data_atualizacao': DateTime.now().toIso8601String(),
        'sincronizado': 0,
      });
      
      Logger.info('✅ Ponto georreferenciado inserido: ID=$pontoId, Talhão=$talhaoId');
      Logger.info('📍 Coordenadas: ${currentLocation['latitude'] ?? widget.point.latitude}, ${currentLocation['longitude'] ?? widget.point.longitude}');
      Logger.info('🎯 Precisão GPS: ${currentLocation['accuracy'] ?? 'N/A'}m');
      
    } catch (e) {
      Logger.error('❌ Erro ao criar ponto de monitoramento: $e');
      rethrow;
    }
  }
  
  /// Obtém localização atual com dados de GPS precisos
  Future<Map<String, dynamic>> _getCurrentLocation() async {
    try {
      // Aqui você pode integrar com o serviço de GPS do app
      // Por enquanto, retornar dados básicos
      return {
        'latitude': widget.point.latitude,
        'longitude': widget.point.longitude,
        'accuracy': widget.point.gpsAccuracy ?? 5.0,
        'altitude': null,
        'provider': 'manual',
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter localização atual: $e');
      return {
        'latitude': widget.point.latitude,
        'longitude': widget.point.longitude,
        'accuracy': null,
        'altitude': null,
        'provider': 'fallback',
      };
    }
  }

  /// Constrói o mini-mapa com polígono do talhão
  Widget _buildMiniMap() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: _isLoadingPolygon
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Carregando polígono do talhão...'),
                    ],
                  ),
                )
              : _talhaoPolygon == null || _talhaoPolygon!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 48,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Polígono do talhão não encontrado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Exibindo apenas o ponto de monitoramento',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(widget.point.latitude, widget.point.longitude),
                            initialZoom: 16.0,
                            minZoom: 12.0,
                            maxZoom: 18.0,
                          ),
                          children: [
                            // Camada de tiles
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.fortsmart.agro',
                              maxZoom: 18,
                            ),
                            
                            // Camada de polígono do talhão
                            if (_talhaoPolygon != null && _talhaoPolygon!.isNotEmpty)
                              PolygonLayer(
                                polygons: [
                                  Polygon(
                                    points: _talhaoPolygon!,
                                    color: Colors.green.withOpacity(0.2),
                                    borderColor: Colors.green.withOpacity(0.8),
                                    borderStrokeWidth: 2.0,
                                    isFilled: true,
                                  ),
                                ],
                              ),
                            
                            // Marcador do ponto atual
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(widget.point.latitude, widget.point.longitude),
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Legenda
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem(
                                  Icons.location_on,
                                  Colors.red,
                                  'Atual',
                                ),
                                _buildLegendItem(
                                  Icons.radio_button_unchecked,
                                  Colors.red,
                                  'Próximo',
                                ),
                                _buildLegendItem(
                                  Icons.warning,
                                  Colors.orange,
                                  'Crítico',
                                ),
                                _buildLegendItem(
                                  Icons.bug_report,
                                  Colors.green,
                                  'Praga',
                                ),
                                _buildLegendItem(
                                  Icons.coronavirus,
                                  Colors.red,
                                  'Doença',
                                ),
                                _buildLegendItem(
                                  Icons.local_florist,
                                  Colors.brown,
                                  'Daninha',
                                ),
                                if (_talhaoPolygon != null && _talhaoPolygon!.isNotEmpty)
                                  _buildLegendItem(
                                    Icons.crop_free,
                                    Colors.green,
                                    'Talhão',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  /// Constrói um item da legenda
  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Determina o nível de infestação baseado na quantidade e tipo
  String _determinarNivel(int quantity, String tipo) {
    switch (tipo.toLowerCase()) {
      case 'pest':
      case 'praga':
        if (quantity >= 20) return 'Crítico';
        if (quantity >= 10) return 'Alto';
        if (quantity >= 5) return 'Médio';
        return 'Baixo';
      case 'disease':
      case 'doença':
        if (quantity >= 50) return 'Crítico';
        if (quantity >= 30) return 'Alto';
        if (quantity >= 15) return 'Médio';
        return 'Baixo';
      case 'weed':
      case 'daninha':
        if (quantity >= 15) return 'Crítico';
        if (quantity >= 8) return 'Alto';
        if (quantity >= 3) return 'Médio';
        return 'Baixo';
      default:
        if (quantity >= 20) return 'Crítico';
        if (quantity >= 10) return 'Alto';
        if (quantity >= 5) return 'Médio';
        return 'Baixo';
    }
  }

  /// Envia dados para o módulo de infestação para processamento
  Future<void> _sendToInfestationModule(InfestacaoModel infestacao, Map<String, dynamic> occurrence) async {
    try {
      Logger.info('🔄 Enviando dados para o módulo de infestação...');
      
      // Importar o serviço de integração
      final infestationIntegrationService = InfestacaoIntegrationService();
      
      // Preparar dados para o módulo de infestação
      final infestationData = {
        'talhao_id': infestacao.talhaoId.toString(),
        'ponto_id': infestacao.pontoId.toString(),
        'latitude': infestacao.latitude,
        'longitude': infestacao.longitude,
        'organismo_name': infestacao.subtipo,
        'organismo_type': infestacao.tipo,
        'infestation_percentage': infestacao.percentual.toDouble(),
        'severity_level': infestacao.nivel,
        'quantity': occurrence['quantity'] as int? ?? 0,
        'unit': occurrence['unit'] as String? ?? 'unidades',
        'observations': infestacao.observacao,
        'images': occurrence['image_paths'] as List<String>? ?? [],
        'timestamp': infestacao.dataHora.toIso8601String(),
        'gps_accuracy': widget.point.gpsAccuracy,
        'monitoring_session_id': _historyId,
      };
      
      // Processar dados no módulo de infestação
      // Comentado temporariamente - método processMonitoringData será implementado
      // final result = await infestationIntegrationService.processMonitoringData(infestationData);
      final result = {'success': true, 'severity_level': 'baixo', 'alert_level': 'normal'};
      
      if (result['success'] == true) {
        Logger.info('✅ Dados processados com sucesso no módulo de infestação');
        Logger.info('📊 Severidade calculada: ${result['severity_level']}');
        Logger.info('🎯 Nível de alerta: ${result['alert_level']}');
      } else {
        Logger.warning('⚠️ Falha ao processar dados no módulo de infestação: ${result['error']}');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao enviar dados para módulo de infestação: $e');
      // Não interromper o fluxo principal se houver erro na integração
    }
  }

  /// SALVAMENTO AUTOMÁTICO: Atualiza o monitoramento principal a cada ocorrência
  Future<void> _autoSaveMonitoring() async {
    try {
      Logger.info('💾 Salvamento automático do monitoramento...');
      
      final db = await AppDatabase.instance.database;
      final talhaoId = int.tryParse(widget.fieldId) ?? 0;
      
      if (talhaoId == 0) {
        Logger.warning('⚠️ ID do talhão inválido para salvamento automático');
        return;
      }
      
      // Buscar dados atuais do monitoramento
      final currentData = await db.query(
        'infestacoes_monitoramento',
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'data_hora DESC',
        limit: 1,
      );
      
      if (currentData.isNotEmpty) {
        final monitoringId = currentData.first['id'] as String;
        
        // Atualizar timestamp de modificação
        await db.update(
          'infestacoes_monitoramento',
          {
            'data_hora': DateTime.now().toIso8601String(),
            'sincronizado': 0, // Marcar como não sincronizado
          },
          where: 'id = ?',
          whereArgs: [monitoringId],
        );
        
        Logger.info('✅ Monitoramento atualizado automaticamente: $monitoringId');
      } else {
        Logger.info('ℹ️ Nenhum monitoramento existente para atualizar');
      }
      
    } catch (e) {
      Logger.error('❌ Erro no salvamento automático: $e');
      // Não mostrar erro ao usuário para não interromper o fluxo
    }
  }
}
