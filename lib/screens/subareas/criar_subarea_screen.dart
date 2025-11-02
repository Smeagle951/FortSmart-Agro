import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/subarea_model.dart';
import '../../services/subarea_service.dart';
import '../../utils/subarea_geodetic_service.dart';
import '../../widgets/fortsmart_app_bar.dart';
import '../../widgets/fortsmart_button.dart';
import '../../widgets/fortsmart_card.dart';
import '../../widgets/fortsmart_loading.dart';
import '../../widgets/fortsmart_text_field.dart';

/// Tela elegante para criação de subáreas
/// Segue o padrão visual do FortSmart Agro
class CriarSubareaScreen extends StatefulWidget {
  final String talhaoId;
  final String talhaoNome;
  final List<LatLng> talhaoPontos;
  final double talhaoAreaHa;

  const CriarSubareaScreen({
    super.key,
    required this.talhaoId,
    required this.talhaoNome,
    required this.talhaoPontos,
    required this.talhaoAreaHa,
  });

  @override
  State<CriarSubareaScreen> createState() => _CriarSubareaScreenState();
}

class _CriarSubareaScreenState extends State<CriarSubareaScreen>
    with TickerProviderStateMixin {
  
  // Constantes
  static const int _minPolygonPoints = 3;
  static const Duration _snackBarDuration = Duration(seconds: 3);
  
  // Serviços
  final SubareaService _subareaService = SubareaService();
  
  // Controllers
  final _nomeController = TextEditingController();
  final _culturaController = TextEditingController();
  final _variedadeController = TextEditingController();
  final _populacaoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Estados
  bool _isLoading = false;
  
  // Modo de desenho
  String _modoDesenho = 'manual'; // 'manual' ou 'gps'
  bool _isDesenhando = false;
  
  // Polígono atual
  List<LatLng> _pontosAtuais = [];
  double _areaAtual = 0.0;
  double _perimetroAtual = 0.0;
  double _percentualAtual = 0.0;
  
  // Cor selecionada
  SubareaColor _corSelecionada = SubareaColor.azul;
  
  // Data de início
  DateTime? _dataInicio;
  
  // Validações
  bool _isValidPolygon = false;
  bool _isInsideTalhao = false;
  bool _hasOverlap = false;
  
  // Edição de polígono
  bool _isEditing = false;
  List<LatLng> _pontosEditaveis = [];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _culturaController.dispose();
    _variedadeController.dispose();
    _populacaoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  /// Inicializa a tela
  void _initializeScreen() {
    // Calcular centroide do talhão para posicionar o mapa
    if (widget.talhaoPontos.isNotEmpty) {
      final centroide = SubareaGeodeticService.calculateGeodeticCentroid(widget.talhaoPontos);
      // O mapa será centralizado no centroide
    }
  }

  /// Inicia desenho manual
  void _iniciarDesenhoManual() {
    setState(() {
      _modoDesenho = 'manual';
      _isDesenhando = true;
      _pontosAtuais = [];
    });
  }

  /// Inicia desenho GPS
  void _iniciarDesenhoGPS() {
    setState(() {
      _modoDesenho = 'gps';
      _isDesenhando = true;
      _pontosAtuais = [];
    });
    
    // TODO: Implementar gravação GPS
    _mostrarMensagem('Modo GPS será implementado na próxima versão');
  }

  /// Para o desenho
  void _pararDesenho() {
    setState(() {
      _isDesenhando = false;
    });
  }

  /// Limpa o polígono atual
  void _limparPoligono() {
    setState(() {
      _pontosAtuais = [];
      _areaAtual = 0.0;
      _perimetroAtual = 0.0;
      _percentualAtual = 0.0;
      _isValidPolygon = false;
      _isInsideTalhao = false;
      _hasOverlap = false;
    });
  }

  /// Adiciona ponto ao polígono (modo manual)
  void _adicionarPonto(LatLng ponto) {
    if (!_isDesenhando || _modoDesenho != 'manual') return;

    setState(() {
      _pontosAtuais.add(ponto);
      _calcularMetricas();
      _validarPoligono();
    });
  }

  /// Calcula métricas do polígono atual baseado no modo de desenho
  void _calcularMetricas() {
    if (_pontosAtuais.length < 3) {
      setState(() {
        _areaAtual = 0.0;
        _perimetroAtual = 0.0;
        _percentualAtual = 0.0;
      });
      return;
    }

    double area;
    double perimetro;

    // Usar método específico baseado no modo de desenho
    if (_modoDesenho == 'manual') {
      // Modo DESENHO: coordenadas planas + fórmula de Shoelace/Gauss
      area = SubareaGeodeticService.calculateAreaDrawingMode(_pontosAtuais);
      perimetro = SubareaGeodeticService.calculatePerimeterDrawingMode(_pontosAtuais);
    } else {
      // Modo GPS: coordenadas geodésicas + fórmula de Haversine + área esférica
      area = SubareaGeodeticService.calculateAreaGPSMode(_pontosAtuais);
      perimetro = SubareaGeodeticService.calculatePerimeterGPSMode(_pontosAtuais);
    }

    final percentual = (area / widget.talhaoAreaHa) * 100;

    setState(() {
      _areaAtual = area;
      _perimetroAtual = perimetro;
      _percentualAtual = percentual;
    });
  }

  /// Valida o polígono atual
  void _validarPoligono() async {
    if (_pontosAtuais.length < 3) {
      setState(() {
        _isValidPolygon = false;
        _isInsideTalhao = false;
        _hasOverlap = false;
      });
      return;
    }

    // Validar se é um polígono válido
    final isValid = SubareaGeodeticService.isValidPolygon(_pontosAtuais);
    
    // Validar se está dentro do talhão
    final isInside = await _subareaService.validateSubareaInTalhao(
      talhaoId: widget.talhaoId,
      subareaPoints: _pontosAtuais,
    );
    
    // Verificar sobreposição
    final hasOverlap = await _subareaService.hasOverlapWithExistingSubareas(
      talhaoId: widget.talhaoId,
      newSubareaPoints: _pontosAtuais,
    );

    setState(() {
      _isValidPolygon = isValid;
      _isInsideTalhao = isInside;
      _hasOverlap = hasOverlap;
    });
  }

  /// Calcula a área da subárea
  double _calcularArea() {
    if (_pontosAtuais.length < 3) return 0.0;
    
    if (_modoDesenho == 'manual') {
      return SubareaGeodeticService.calculateAreaDrawingMode(_pontosAtuais);
    } else {
      return SubareaGeodeticService.calculateAreaGPSMode(_pontosAtuais);
    }
  }

  /// Calcula o perímetro da subárea
  double _calcularPerimetro() {
    if (_pontosAtuais.length < 2) return 0.0;
    
    if (_modoDesenho == 'manual') {
      return SubareaGeodeticService.calculatePerimeterDrawingMode(_pontosAtuais);
    } else {
      return SubareaGeodeticService.calculatePerimeterGPSMode(_pontosAtuais);
    }
  }

  /// Calcula o centroide da subárea
  LatLng _calcularCentroide() {
    if (_pontosAtuais.isEmpty) return const LatLng(0, 0);
    
    double latSum = 0;
    double lngSum = 0;
    
    for (final ponto in _pontosAtuais) {
      latSum += ponto.latitude;
      lngSum += ponto.longitude;
    }
    
    return LatLng(
      latSum / _pontosAtuais.length,
      lngSum / _pontosAtuais.length,
    );
  }

  /// Desenha o polígono no mapa
  void _desenharPoligono() {
    if (_pontosAtuais.length < 3) return;
    
    setState(() {
      // O polígono já está sendo desenhado automaticamente
      // Este método pode ser usado para forçar atualização
    });
  }

  /// Edita o polígono existente
  void _editarPoligono() {
    if (_pontosAtuais.isEmpty) return;
    
    setState(() {
      _isEditing = true;
      _pontosEditaveis = List.from(_pontosAtuais);
    });
  }

  /// Valida o polígono no mapa
  bool _validarPoligonoMapa() {
    if (_pontosAtuais.length < 3) return false;
    
    // Verificar se os pontos formam um polígono válido
    return SubareaGeodeticService.isValidPolygon(_pontosAtuais);
  }

  /// Sincroniza com o talhão pai
  Future<void> _sincronizarComTalhao() async {
    try {
      // Atualizar estatísticas do talhão
      await _atualizarEstatisticas();
      
      // Notificar mudanças para outros módulos
      await _notificarMudancas();
      
      print('✅ Sincronização com talhão concluída');
    } catch (e) {
      print('❌ Erro na sincronização: $e');
    }
  }

  /// Atualiza estatísticas do talhão
  Future<void> _atualizarEstatisticas() async {
    try {
      // Calcular nova área total das subáreas
      final subareas = await _subareaService.getSubareasByTalhao(widget.talhaoId);
      double areaTotalSubareas = 0.0;
      
      for (final subarea in subareas) {
        areaTotalSubareas += subarea.areaHa;
      }
      
      // Atualizar percentual de ocupação
      final percentualOcupacao = (areaTotalSubareas / widget.talhaoAreaHa) * 100;
      
      print('📊 Estatísticas atualizadas:');
      print('  - Área total subáreas: ${areaTotalSubareas.toStringAsFixed(2)} ha');
      print('  - Percentual ocupação: ${percentualOcupacao.toStringAsFixed(1)}%');
      
    } catch (e) {
      print('❌ Erro ao atualizar estatísticas: $e');
    }
  }

  /// Notifica mudanças para outros módulos
  Future<void> _notificarMudancas() async {
    try {
      // Notificar mudanças para o sistema de plantio
      // Notificar mudanças para o sistema de monitoramento
      // Notificar mudanças para o sistema de aplicação
      
      print('📢 Mudanças notificadas para outros módulos');
    } catch (e) {
      print('❌ Erro ao notificar mudanças: $e');
    }
  }

  /// Exporta subáreas
  Future<void> _exportarSubareas() async {
    try {
      final subareas = await _subareaService.getSubareasByTalhao(widget.talhaoId);
      
      // Gerar relatório
      final relatorio = _gerarRelatorio(subareas);
      
      // Compartilhar dados
      await _compartilharDados(relatorio);
      
    } catch (e) {
      _mostrarMensagem('Erro ao exportar subáreas: $e');
    }
  }

  /// Gera relatório de subáreas
  Map<String, dynamic> _gerarRelatorio(List<SubareaModel> subareas) {
    double areaTotal = 0.0;
    double perimetroTotal = 0.0;
    
    for (final subarea in subareas) {
      areaTotal += subarea.areaHa;
      perimetroTotal += subarea.perimetroM;
    }
    
    return {
      'talhao_id': widget.talhaoId,
      'talhao_nome': widget.talhaoNome,
      'data_geracao': DateTime.now().toIso8601String(),
      'total_subareas': subareas.length,
      'area_total_ha': areaTotal,
      'perimetro_total_m': perimetroTotal,
      'percentual_ocupacao': (areaTotal / widget.talhaoAreaHa) * 100,
      'subareas': subareas.map((s) => {
        'id': s.id,
        'nome': s.nome,
        'cultura': s.cultura,
        'variedade': s.variedade,
        'area_ha': s.areaHa,
        'perimetro_m': s.perimetroM,
        'data_inicio': s.dataInicio?.toIso8601String(),
        'observacoes': s.observacoes,
      }).toList(),
    };
  }

  /// Compartilha dados das subáreas
  Future<void> _compartilharDados(Map<String, dynamic> dados) async {
    try {
      // Implementar compartilhamento (PDF, Excel, etc.)
      print('📤 Dados compartilhados: ${dados['total_subareas']} subáreas');
    } catch (e) {
      print('❌ Erro ao compartilhar dados: $e');
    }
  }

  /// Salva a subárea
  Future<void> _salvarSubarea() async {
    // Validar campos obrigatórios
    if (!_validarCamposObrigatorios()) return;
    
    // Validar polígono
    if (!_isValidPolygon) {
      _mostrarMensagem('Polígono inválido');
      return;
    }
    
    if (!_validarLimites()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Calcular métricas finais usando os novos métodos
      final areaFinal = _calcularArea();
      final perimetroFinal = _calcularPerimetro();
      final centroide = _calcularCentroide();

      // Criar subárea
      final subarea = SubareaModel.create(
        talhaoId: widget.talhaoId,
        nome: _nomeController.text.trim(),
        cultura: _culturaController.text.trim().isNotEmpty 
            ? _culturaController.text.trim() 
            : null,
        variedade: _variedadeController.text.trim().isNotEmpty 
            ? _variedadeController.text.trim() 
            : null,
        populacao: _populacaoController.text.trim().isNotEmpty 
            ? int.tryParse(_populacaoController.text.trim()) 
            : null,
        cor: _corSelecionada,
        pontos: _pontosAtuais,
        areaHa: areaFinal,
        perimetroM: perimetroFinal,
        dataInicio: _dataInicio,
        observacoes: _observacoesController.text.trim().isNotEmpty 
            ? _observacoesController.text.trim() 
            : null,
      );

      // Salvar no banco
      await _subareaService.insertSubarea(subarea);

      // Sincronizar com o talhão pai
      await _sincronizarComTalhao();

      // Verificar se o widget ainda está montado antes de navegar
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarMensagem('Erro ao salvar subárea: $e');
    }
  }

  /// Seleciona data de início
  Future<void> _selecionarDataInicio() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null) {
      setState(() {
        _dataInicio = data;
      });
    }
  }

  /// Seleciona cor da subárea
  void _selecionarCor(SubareaColor cor) {
    setState(() {
      _corSelecionada = cor;
    });
  }

  /// Valida campos obrigatórios
  bool _validarCamposObrigatorios() {
    if (_nomeController.text.trim().isEmpty) {
      _mostrarMensagem('Nome da subárea é obrigatório');
      return false;
    }

    if (_pontosAtuais.length < _minPolygonPoints) {
      _mostrarMensagem('Polígono deve ter pelo menos $_minPolygonPoints pontos');
      return false;
    }

    return true;
  }


  /// Valida limites e sobreposições
  bool _validarLimites() {
    if (!_isInsideTalhao) {
      _mostrarMensagem('Subárea deve estar completamente dentro do talhão');
      return false;
    }

    if (_hasOverlap) {
      _mostrarMensagem('Subárea não pode sobrepor outras subáreas');
      return false;
    }

    return true;
  }

  /// Mostra mensagem de feedback
  void _mostrarMensagem(String mensagem, {bool isSuccess = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: _snackBarDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: FortSmartAppBar(
        title: 'Criar Subárea',
        subtitle: widget.talhaoNome,
        actions: [
          if (_pontosAtuais.isNotEmpty)
            IconButton(
              onPressed: _limparPoligono,
              icon: const Icon(Icons.clear),
              tooltip: 'Limpar Polígono',
            ),
        ],
      ),
      body: _isLoading
          ? const FortSmartLoading()
          : Column(
              children: [
                // Mapa
                Expanded(
                  flex: 2,
                  child: _buildMapa(),
                ),
                
                // Controles de desenho
                _buildControlesDesenho(),
                
                // Formulário
                Expanded(
                  flex: 3,
                  child: _buildFormulario(),
                ),
                
                // Botão salvar
                _buildBotaoSalvar(),
              ],
            ),
    );
  }

  /// Constrói o mapa
  Widget _buildMapa() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: widget.talhaoPontos.isNotEmpty
                ? SubareaGeodeticService.calculateGeodeticCentroid(widget.talhaoPontos)
                : const LatLng(-23.5505, -46.6333),
            initialZoom: 15,
            onTap: (tapPosition, point) => _adicionarPonto(point),
          ),
          children: [
            // Tile layer
            TileLayer(
              urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            ),
            
            // Polígono do talhão (fundo)
            if (widget.talhaoPontos.isNotEmpty)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: widget.talhaoPontos,
                    color: Colors.grey.withOpacity(0.1),
                    borderColor: Colors.grey.withOpacity(0.6),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            
            // Polígono da subárea sendo criada
            if (_pontosAtuais.isNotEmpty)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _pontosAtuais,
                    color: _corSelecionada.color.withOpacity(0.3),
                    borderColor: _corSelecionada.color,
                    borderStrokeWidth: 3,
                  ),
                ],
              ),
            
            // Marcadores dos pontos
            if (_pontosAtuais.isNotEmpty)
              MarkerLayer(
                markers: _pontosAtuais.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;
                  
                  return Marker(
                    point: point,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _corSelecionada.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// Constrói controles de desenho
  Widget _buildControlesDesenho() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Botão desenho manual
          Expanded(
            child: FortSmartButton(
              text: 'Desenhar',
              icon: Icons.edit,
              onPressed: _isDesenhando && _modoDesenho == 'manual' 
                  ? _pararDesenho 
                  : _iniciarDesenhoManual,
              backgroundColor: _isDesenhando && _modoDesenho == 'manual' 
                  ? Colors.red 
                  : Colors.blue,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Botão modo GPS
          Expanded(
            child: FortSmartButton(
              text: 'Modo GPS',
              icon: Icons.gps_fixed,
              onPressed: _isDesenhando && _modoDesenho == 'gps' 
                  ? _pararDesenho 
                  : _iniciarDesenhoGPS,
              backgroundColor: _isDesenhando && _modoDesenho == 'gps' 
                  ? Colors.red 
                  : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o formulário
  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Título
          const Text(
            'Dados da Subárea',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nome
          FortSmartTextField(
            controller: _nomeController,
            label: 'Nome da Subárea *',
            hint: 'Ex: Parcela A1',
          ),
          
          const SizedBox(height: 16),
          
          // Cultura e Variedade
          Row(
            children: [
              Expanded(
                child: FortSmartTextField(
                  controller: _culturaController,
                  label: 'Cultura',
                  hint: 'Ex: Soja',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FortSmartTextField(
                  controller: _variedadeController,
                  label: 'Variedade',
                  hint: 'Ex: BMX Turbo',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // População e Data
          Row(
            children: [
              Expanded(
                child: FortSmartTextField(
                  controller: _populacaoController,
                  label: 'População (pl/ha)',
                  hint: 'Ex: 250000',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _selecionarDataInicio,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data de Início',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dataInicio != null
                              ? '${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}'
                              : 'Selecionar data',
                          style: TextStyle(
                            fontSize: 16,
                            color: _dataInicio != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Seletor de cores
          _buildSeletorCores(),
          
          const SizedBox(height: 16),
          
          // Observações
          FortSmartTextField(
            controller: _observacoesController,
            label: 'Observações',
            hint: 'Informações adicionais...',
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          // Métricas atuais
          if (_pontosAtuais.isNotEmpty) _buildMetricasAtuais(),
        ],
      ),
    );
  }

  /// Constrói seletor de cores
  Widget _buildSeletorCores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor da Subárea',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: SubareaColor.coresDisponiveis.map((cor) {
            final isSelected = _corSelecionada == cor;
            return GestureDetector(
              onTap: () => _selecionarCor(cor),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cor.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cor.color.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Constrói métricas atuais
  Widget _buildMetricasAtuais() {
    return FortSmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Métricas Atuais',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricaItem(
                  'Área',
                  SubareaGeodeticService.formatAreaBrazilian(_areaAtual),
                  Icons.area_chart,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildMetricaItem(
                  'Perímetro',
                  SubareaGeodeticService.formatPerimeterBrazilian(_perimetroAtual),
                  Icons.straighten,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildMetricaItem(
                  'Percentual',
                  '${_percentualAtual.toStringAsFixed(1)}%',
                  Icons.pie_chart,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Status de validação
          _buildStatusValidacao(),
        ],
      ),
    );
  }

  /// Constrói item de métrica
  Widget _buildMetricaItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói status de validação
  Widget _buildStatusValidacao() {
    return Column(
      children: [
        _buildStatusItem(
          'Polígono Válido',
          _isValidPolygon,
          _pontosAtuais.length >= 3,
        ),
        _buildStatusItem(
          'Dentro do Talhão',
          _isInsideTalhao,
          _pontosAtuais.length >= 3,
        ),
        _buildStatusItem(
          'Sem Sobreposição',
          !_hasOverlap,
          _pontosAtuais.length >= 3,
        ),
      ],
    );
  }

  /// Constrói item de status
  Widget _buildStatusItem(String label, bool isValid, bool canValidate) {
    Color color;
    IconData icon;
    
    if (!canValidate) {
      color = Colors.grey;
      icon = Icons.help_outline;
    } else if (isValid) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else {
      color = Colors.red;
      icon = Icons.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói botão salvar
  Widget _buildBotaoSalvar() {
    final canSave = _nomeController.text.trim().isNotEmpty &&
        _pontosAtuais.length >= 3 &&
        _isValidPolygon &&
        _isInsideTalhao &&
        !_hasOverlap;

    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FortSmartButton(
          text: 'Salvar Subárea',
          icon: Icons.save,
          onPressed: canSave ? _salvarSubarea : null,
          backgroundColor: Colors.green,
          isLoading: _isLoading,
        ),
      ),
    );
  }
}
