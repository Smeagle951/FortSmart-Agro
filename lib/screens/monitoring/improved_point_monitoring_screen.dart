import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'widgets/point_monitoring_header.dart';
import 'widgets/point_monitoring_map.dart';
import 'widgets/occurrence_type_selector.dart';
import 'widgets/organism_search_field.dart';
import 'widgets/quantity_input_field.dart';
import 'widgets/occurrences_list_widget.dart';

import '../../models/infestacao_model.dart';
import '../../models/ponto_monitoramento_model.dart';
import '../../repositories/infestacao_repository.dart';
import '../../database/app_database.dart';
import '../../utils/logger.dart';
import '../../utils/distance_calculator.dart';
import '../../utils/image_compression_service.dart';
import '../../services/monitoring_sync_service.dart';
import '../../services/monitoring_infestation_integration_service.dart';

class ImprovedPointMonitoringScreen extends StatefulWidget {
  final int pontoId;
  final int talhaoId;
  final int culturaId;
  final String talhaoNome;
  final String culturaNome;
  final List<dynamic>? pontos;
  final DateTime? data;

  const ImprovedPointMonitoringScreen({
    Key? key,
    required this.pontoId,
    required this.talhaoId,
    required this.culturaId,
    required this.talhaoNome,
    required this.culturaNome,
    this.pontos,
    this.data,
  }) : super(key: key);

  @override
  State<ImprovedPointMonitoringScreen> createState() => _ImprovedPointMonitoringScreenState();
}

class _ImprovedPointMonitoringScreenState extends State<ImprovedPointMonitoringScreen> {
  // Estado local
  bool _isLoading = false;
  String? _error;
  PontoMonitoramentoModel? _currentPoint;
  PontoMonitoramentoModel? _nextPoint;
  List<InfestacaoModel> _ocorrencias = [];
  Position? _currentPosition;
  double? _distanceToPoint;
  String? _gpsAccuracy;
  bool _hasArrived = false;
  List<PontoMonitoramentoModel> _allPoints = [];
  int _currentPointIndex = 0;
  
  // Estado do formulário de nova ocorrência
  String? _selectedType;
  String? _selectedOrganism;
  int _quantity = 0;
  String _observacao = '';
  List<String> _fotoPaths = [];
  List<String> _availableOrganisms = [];
  
  // Repositórios e serviços
  InfestacaoRepository? _infestacaoRepository;
  Database? _database;
  MonitoringSyncService? _syncService;
  final MonitoringInfestationIntegrationService _integrationService = 
      MonitoringInfestationIntegrationService();
  
  // Constantes de validação
  static const double _maxGpsAccuracy = 10.0;
  static const double _arrivalThreshold = 2.0;
  static const double _navigationThreshold = 5.0;
  
  StreamSubscription<Position>? _positionSubscription;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pontoId = widget.pontoId is int ? widget.pontoId : int.tryParse(widget.pontoId.toString()) ?? 0;
      final talhaoId = widget.talhaoId is int ? widget.talhaoId : int.tryParse(widget.talhaoId.toString()) ?? 0;
      
      await _initializeDatabase();
      await _integrationService.initialize();
      await _processMonitoringPoints(talhaoId);
      await _loadExistingOccurrences();
      _startGpsMonitoring();

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _initializeDatabase() async {
    try {
      _database = await AppDatabase().database;
      _infestacaoRepository = InfestacaoRepository(_database!);
      await _infestacaoRepository!.createTable();
      _syncService = MonitoringSyncService();
      Logger.info('✅ Banco de dados e serviços inicializados para monitoramento');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar banco de dados: $e');
      throw Exception('Erro ao inicializar banco de dados: $e');
    }
  }

  Future<void> _loadExistingOccurrences() async {
    if (_infestacaoRepository == null || _currentPoint == null) return;
    
    try {
      final existingOccurrences = await _infestacaoRepository!.getByPontoId(_currentPoint!.id);
      setState(() {
        _ocorrencias = existingOccurrences;
      });
      Logger.info('✅ Carregadas ${existingOccurrences.length} ocorrências existentes');
    } catch (e) {
      Logger.error('❌ Erro ao carregar ocorrências existentes: $e');
    }
  }

  Future<void> _processMonitoringPoints(int talhaoId) async {
    try {
      _allPoints = [];
      
      if (widget.pontos != null && widget.pontos!.isNotEmpty) {
        for (int i = 0; i < widget.pontos!.length; i++) {
          final ponto = widget.pontos![i];
          
          if (ponto.latitude == null || ponto.longitude == null) {
            throw Exception('Ponto ${i + 1} não possui coordenadas válidas');
          }
          
          final pontoModel = PontoMonitoramentoModel(
            id: widget.pontoId + i,
            talhaoId: talhaoId,
            ordem: i + 1,
            latitude: ponto.latitude,
            longitude: ponto.longitude,
            dataHoraInicio: i == 0 ? DateTime.now() : null,
          );
          _allPoints.add(pontoModel);
        }
      } else {
        throw Exception('Nenhum ponto de monitoramento foi desenhado no mapa');
      }
      
      _currentPointIndex = 0;
      _currentPoint = _allPoints.isNotEmpty ? _allPoints[0] : null;
      _nextPoint = _allPoints.length > 1 ? _allPoints[1] : null;
      
    } catch (e) {
      throw Exception('Erro ao processar pontos de monitoramento: $e');
    }
  }

  void _startGpsMonitoring() {
    _positionSubscription?.cancel();
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen(
      (position) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          _updateGpsPosition(position);
        });
      },
      onError: (error) {
        setState(() {
          _gpsAccuracy = 'Erro: $error';
        });
      },
    );
  }

  void _updateGpsPosition(Position position) {
    final currentPoint = _currentPoint;
    if (currentPoint == null) return;

    final distance = DistanceCalculator.calculateDistance(
      position.latitude,
      position.longitude,
      currentPoint.latitude,
      currentPoint.longitude,
    );

    final hasArrived = DistanceCalculator.hasArrivedAtPoint(distance, arrivalThreshold: _arrivalThreshold);
    final previousArrived = _hasArrived;

    if (hasArrived && !previousArrived) {
      _triggerArrivalNotification();
    }

    setState(() {
      _currentPosition = position;
      _distanceToPoint = distance;
      _gpsAccuracy = '${position.accuracy.toStringAsFixed(1)}m';
      _hasArrived = hasArrived;
    });
  }

  void _triggerArrivalNotification() {
    HapticFeedback.mediumImpact();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 Você chegou ao ponto de monitoramento!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2D9CDB),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF2C2C2C),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D9CDB),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header compacto
            PointMonitoringHeader(
              currentPoint: _currentPoint,
              nextPoint: _nextPoint,
              talhaoNome: widget.talhaoNome,
              culturaNome: widget.culturaNome,
              gpsStatus: _gpsAccuracy,
              distanceToPoint: _distanceToPoint,
              hasArrived: _hasArrived,
            ),
            
            // Linha de status da cultura
            _buildCulturaStatusLine(),
            
            // Mini mapa (metade da tela)
            Expanded(
              flex: 1,
              child: PointMonitoringMap(
                currentPoint: _currentPoint,
                nextPoint: _nextPoint,
                currentPosition: _currentPosition,
                ocorrencias: _ocorrencias,
                talhaoId: widget.talhaoId,
                culturaId: widget.culturaId,
              ),
            ),
            
            // Divisor fino
            Container(
              height: 1,
              color: const Color(0xFFE0E0E0),
            ),
            
            // Formulário de nova ocorrência e lista
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção de nova ocorrência
                    _buildNewOccurrenceSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Lista de ocorrências registradas
                    OccurrencesListWidget(
                      occurrences: _ocorrencias,
                      onDeleteOccurrence: _deleteOccurrence,
                      onEditOccurrence: _editOccurrence,
                    ),
                  ],
                ),
              ),
            ),
            
            // Rodapé com botões de ação
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCulturaStatusLine() {
    final pragaCount = _ocorrencias.where((o) => o.tipo.toLowerCase() == 'praga').length;
    final doencaCount = _ocorrencias.where((o) => o.tipo.toLowerCase() == 'doença').length;
    final daninhaCount = _ocorrencias.where((o) => o.tipo.toLowerCase() == 'daninha').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '🌱 ${widget.culturaNome}',
            style: const TextStyle(
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          if (pragaCount > 0) ...[
            _buildOccurrenceBadge('🐛', pragaCount),
            const SizedBox(width: 8),
          ],
          if (doencaCount > 0) ...[
            _buildOccurrenceBadge('🦠', doencaCount),
            const SizedBox(width: 8),
          ],
          if (daninhaCount > 0) ...[
            _buildOccurrenceBadge('🌿', daninhaCount),
          ],
          if (pragaCount == 0 && doencaCount == 0 && daninhaCount == 0)
            const Text(
              'Nenhuma ocorrência registrada',
              style: TextStyle(
                color: Color(0xFF95A5A6),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOccurrenceBadge(String icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        '$icon $count',
        style: const TextStyle(
          color: Color(0xFF2C2C2C),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNewOccurrenceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF2D9CDB),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Nova Ocorrência',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Seletor de tipo
          OccurrenceTypeSelector(
            selectedType: _selectedType,
            onTypeSelected: (type) {
              setState(() {
                _selectedType = type;
                _selectedOrganism = null;
                _quantity = 0;
              });
            },
          ),
          
          if (_selectedType != null) ...[
            const SizedBox(height: 16),
            
            // Busca de organismo
            OrganismSearchField(
              selectedOrganism: _selectedOrganism,
              selectedType: _selectedType,
              culturaId: widget.culturaId,
              onOrganismSelected: (organism) {
                setState(() {
                  _selectedOrganism = organism;
                });
              },
              onOrganismsLoaded: (organisms) {
                setState(() {
                  _availableOrganisms = organisms;
                });
              },
            ),
            
            if (_selectedOrganism != null && _selectedOrganism!.isNotEmpty) ...[
              const SizedBox(height: 16),
              
              // Campo de quantidade
              QuantityInputField(
                initialValue: _quantity,
                onQuantityChanged: (quantity) {
                  setState(() {
                    _quantity = quantity;
                  });
                },
                organismName: _selectedOrganism,
              ),
              
              const SizedBox(height: 16),
              
              // Campo de observação
              const Text(
                'Observação (opcional):',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Descreva a ocorrência observada...',
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
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  _observacao = value;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Seção de fotos
              _buildPhotosSection(),
              
              const SizedBox(height: 16),
              
              // Botões de ação
              _buildActionButtons(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotos (opcional):',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        
        // Grid de fotos
        if (_fotoPaths.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _fotoPaths.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_fotoPaths[index]),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(
                              Icons.image,
                              color: Color(0xFF95A5A6),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        
        // Botões de adicionar foto
        if (_fotoPaths.length < 4)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Câmera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D9CDB),
                    side: const BorderSide(color: Color(0xFF2D9CDB)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Galeria'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D9CDB),
                    side: const BorderSide(color: Color(0xFF2D9CDB)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearForm,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF95A5A6),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Limpar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _canSaveOccurrence() ? _saveOccurrence : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D9CDB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Salvar'),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE0E0E0)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _currentPointIndex > 0 ? _previousPoint : null,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Anterior'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D9CDB),
                side: const BorderSide(color: Color(0xFF2D9CDB)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _hasArrived ? _goToNextPoint : null,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Próximo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSaveOccurrence() {
    return _selectedType != null &&
           _selectedOrganism != null &&
           _selectedOrganism!.isNotEmpty &&
           _quantity > 0;
  }

  void _clearForm() {
    setState(() {
      _selectedType = null;
      _selectedOrganism = null;
      _quantity = 0;
      _observacao = '';
      _fotoPaths.clear();
    });
  }

  Future<void> _saveOccurrence() async {
    if (!_canSaveOccurrence()) return;

    try {
      final position = _currentPosition;
      if (position == null) {
        throw Exception('Posição GPS não disponível');
      }

      final talhaoId = widget.talhaoId is int ? widget.talhaoId : int.tryParse(widget.talhaoId.toString()) ?? 0;
      final pontoId = widget.pontoId is int ? widget.pontoId : int.tryParse(widget.pontoId.toString()) ?? 0;
      
      // Calcular nível automaticamente baseado na quantidade
      final nivel = _calculateLevel(_quantity);
      
      final novaOcorrencia = InfestacaoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        talhaoId: talhaoId,
        pontoId: pontoId,
        latitude: position.latitude,
        longitude: position.longitude,
        tipo: _selectedType!,
        subtipo: _selectedOrganism!,
        nivel: nivel,
        percentual: _quantity,
        observacao: _observacao.isEmpty ? null : _observacao,
        fotoPaths: _fotoPaths.isEmpty ? null : _fotoPaths.join(';'),
        dataHora: DateTime.now(),
        sincronizado: false,
      );

      if (_infestacaoRepository != null) {
        await _infestacaoRepository!.insert(novaOcorrencia);
        Logger.info('✅ Ocorrência salva no banco de dados: ${novaOcorrencia.id}');
      }

      setState(() {
        _ocorrencias = [..._ocorrencias, novaOcorrencia];
      });

      // Enviar para o mapa de infestação usando o novo serviço
      await _integrationService.sendMonitoringDataToInfestationMap(
        occurrence: novaOcorrencia,
        preventDuplicates: true,
      );
      
      _clearForm();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorrência salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('❌ Erro ao salvar ocorrência: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _calculateLevel(int quantity) {
    // Lógica simplificada para cálculo de nível
    // Em uma implementação real, isso viria do catálogo de organismos
    if (quantity == 0) return 'Nenhum';
    if (quantity <= 2) return 'Baixo';
    if (quantity <= 5) return 'Médio';
    if (quantity <= 10) return 'Alto';
    return 'Crítico';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        setState(() {
          _fotoPaths.add(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao capturar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _fotoPaths.removeAt(index);
    });
  }

  Future<void> _deleteOccurrence(String id) async {
    try {
      if (_infestacaoRepository != null) {
        await _infestacaoRepository!.delete(id);
        Logger.info('✅ Ocorrência removida do banco de dados: $id');
      }

      setState(() {
        _ocorrencias = _ocorrencias.where((o) => o.id != id).toList();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorrência removida com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('❌ Erro ao remover ocorrência: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editOccurrence(InfestacaoModel occurrence) {
    // Implementar edição de ocorrência
    // Por enquanto, apenas mostrar um snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editar ocorrência: ${occurrence.subtipo}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _sendToInfestationMap(InfestacaoModel ocorrencia) async {
    try {
      if (_database != null) {
        await _database!.insert(
          'infestation_map',
          {
            'id': ocorrencia.id,
            'talhao_id': ocorrencia.talhaoId,
            'ponto_id': ocorrencia.pontoId,
            'latitude': ocorrencia.latitude,
            'longitude': ocorrencia.longitude,
            'tipo': ocorrencia.tipo,
            'subtipo': ocorrencia.subtipo,
            'nivel': ocorrencia.nivel,
            'percentual': ocorrencia.percentual,
            'observacao': ocorrencia.observacao,
            'foto_paths': ocorrencia.fotoPaths,
            'data_hora': ocorrencia.dataHora.toIso8601String(),
            'sincronizado': ocorrencia.sincronizado ? 1 : 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        Logger.info('✅ Dados enviados para o mapa de infestação: ${ocorrencia.id}');
      }
    } catch (e) {
      Logger.error('❌ Erro ao enviar dados para o mapa de infestação: $e');
    }
  }

  Future<void> _saveToMonitoringHistory(InfestacaoModel ocorrencia) async {
    try {
      if (_database != null) {
        await _database!.insert(
          'monitoring_history',
          {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'talhao_id': ocorrencia.talhaoId,
            'ponto_id': ocorrencia.pontoId,
            'cultura_id': widget.culturaId,
            'cultura_nome': widget.culturaNome,
            'talhao_nome': widget.talhaoNome,
            'latitude': ocorrencia.latitude,
            'longitude': ocorrencia.longitude,
            'tipo_ocorrencia': ocorrencia.tipo,
            'subtipo_ocorrencia': ocorrencia.subtipo,
            'nivel_ocorrencia': ocorrencia.nivel,
            'percentual_ocorrencia': ocorrencia.percentual,
            'observacao': ocorrencia.observacao,
            'foto_paths': ocorrencia.fotoPaths,
            'data_hora_ocorrencia': ocorrencia.dataHora.toIso8601String(),
            'data_hora_monitoramento': DateTime.now().toIso8601String(),
            'sincronizado': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        Logger.info('✅ Dados salvos no histórico de monitoramento: ${ocorrencia.id}');
      }
    } catch (e) {
      Logger.error('❌ Erro ao salvar no histórico de monitoramento: $e');
    }
  }

  Future<void> _previousPoint() async {
    try {
      if (_currentPointIndex > 0) {
        if (_currentPoint != null) {
          _currentPoint = _currentPoint!.copyWith(dataHoraFim: DateTime.now());
        }
        
        _currentPointIndex--;
        _currentPoint = _allPoints[_currentPointIndex];
        _nextPoint = _currentPointIndex < _allPoints.length - 1 ? _allPoints[_currentPointIndex + 1] : null;
        
        await _loadExistingOccurrences();
        
        _currentPoint = _currentPoint!.copyWith(dataHoraInicio: DateTime.now());
        
        setState(() {});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voltou ao ponto ${_currentPoint!.ordem}'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este é o primeiro ponto'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('❌ Erro ao navegar para ponto anterior: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _goToNextPoint() async {
    try {
      if (_distanceToPoint != null && !DistanceCalculator.isNearPoint(_distanceToPoint!, threshold: _navigationThreshold)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Você está a ${DistanceCalculator.formatDistance(_distanceToPoint!)} do próximo ponto. Aproxime-se a ≤${_navigationThreshold}m para habilitar avanço.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (_currentPointIndex < _allPoints.length - 1) {
        if (_currentPoint != null) {
          _currentPoint = _currentPoint!.copyWith(dataHoraFim: DateTime.now());
        }
        
        _currentPointIndex++;
        _currentPoint = _allPoints[_currentPointIndex];
        _nextPoint = _currentPointIndex < _allPoints.length - 1 ? _allPoints[_currentPointIndex + 1] : null;
        
        await _loadExistingOccurrences();
        
        _currentPoint = _currentPoint!.copyWith(dataHoraInicio: DateTime.now());
        
        setState(() {});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Avançou para o ponto ${_currentPoint!.ordem}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _finishMonitoring();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _finishMonitoring() async {
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monitoramento finalizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
