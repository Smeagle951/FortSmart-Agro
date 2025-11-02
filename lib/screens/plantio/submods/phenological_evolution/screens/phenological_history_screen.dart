/// 📜 Screen: Histórico de Evolução Fenológica
/// 
/// Tela para visualização do histórico completo de registros
/// fenológicos com timeline e comparações.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/phenological_record_model.dart';
import '../models/phenological_stage_model.dart';
import '../providers/phenological_provider.dart';
import '../services/phenological_classification_service.dart';

class PhenologicalHistoryScreen extends StatefulWidget {
  final String talhaoId;
  final String culturaId;
  final String? talhaoNome;
  final String? culturaNome;

  const PhenologicalHistoryScreen({
    Key? key,
    required this.talhaoId,
    required this.culturaId,
    this.talhaoNome,
    this.culturaNome,
  }) : super(key: key);

  @override
  State<PhenologicalHistoryScreen> createState() => _PhenologicalHistoryScreenState();
}

class _PhenologicalHistoryScreenState extends State<PhenologicalHistoryScreen> {
  List<PhenologicalRecordModel> _registros = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<PhenologicalProvider>(context, listen: false);
      await provider.inicializar();
      await provider.carregarRegistros(widget.talhaoId, widget.culturaId);

      setState(() {
        _registros = provider.registros;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar histórico: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Histórico Fenológico'),
            if (widget.talhaoNome != null)
              Text(
                '${widget.talhaoNome} • ${widget.culturaNome ?? ""}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarHistorico,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildHistorico(),
    );
  }

  Widget _buildHistorico() {
    if (_registros.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _carregarHistorico,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _registros.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildResumo();
          }

          final registro = _registros[index - 1];
          final isFirst = index == 1;
          final isLast = index == _registros.length;

          return _buildRegistroCard(registro, isFirst, isLast);
        },
      ),
    );
  }

  Widget _buildResumo() {
    final totalRegistros = _registros.length;
    final ultimoRegistro = _registros.isNotEmpty ? _registros.first : null;

    return Card(
      color: Colors.blue.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Resumo Geral',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResumoItem(
                  'Total de Registros',
                  totalRegistros.toString(),
                  Icons.history,
                ),
                if (ultimoRegistro != null)
                  _buildResumoItem(
                    'Último DAE',
                    '${ultimoRegistro.diasAposEmergencia}',
                    Icons.event,
                  ),
                if (ultimoRegistro?.alturaCm != null)
                  _buildResumoItem(
                    'Altura Atual',
                    '${ultimoRegistro!.alturaCm!.toStringAsFixed(0)} cm',
                    Icons.height,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRegistroCard(
    PhenologicalRecordModel registro,
    bool isFirst,
    bool isLast,
  ) {
    final estagio = PhenologicalClassificationService.classificarEstagio(
      registro: registro,
      cultura: widget.culturaNome ?? '',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline vertical
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: estagio?.cor ?? Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Icon(
                  estagio?.icone ?? Icons.circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 120,
                  color: Colors.grey.shade300,
                ),
            ],
          ),
          const SizedBox(width: 12),
          
          // Card de conteúdo
          Expanded(
            child: Card(
              child: InkWell(
                onTap: () => _verDetalhes(registro),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(registro.dataRegistro),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: estagio?.cor.withOpacity(0.2) ?? Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              estagio?.codigo ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: estagio?.cor ?? Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estagio?.nome ?? 'Estágio não identificado',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildMiniIndicador(
                            Icons.calendar_today,
                            '${registro.diasAposEmergencia} DAE',
                          ),
                          if (registro.alturaCm != null) ...[
                            const SizedBox(width: 16),
                            _buildMiniIndicador(
                              Icons.height,
                              '${registro.alturaCm!.toStringAsFixed(1)} cm',
                            ),
                          ],
                          if (registro.percentualSanidade != null) ...[
                            const SizedBox(width: 16),
                            _buildMiniIndicador(
                              Icons.health_and_safety,
                              '${registro.percentualSanidade!.toStringAsFixed(0)}%',
                              color: _getSanidadeColor(registro.percentualSanidade),
                            ),
                          ],
                        ],
                      ),
                      if (registro.vagensPlanta != null || registro.espigasPlanta != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (registro.vagensPlanta != null)
                              _buildMiniIndicador(
                                Icons.apps,
                                '${registro.vagensPlanta!.toStringAsFixed(1)} vagens',
                              ),
                            if (registro.espigasPlanta != null)
                              _buildMiniIndicador(
                                Icons.local_florist,
                                '${registro.espigasPlanta!.toStringAsFixed(1)} espigas',
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIndicador(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: color ?? Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhum registro encontrado',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Adicione o primeiro registro fenológico',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getSanidadeColor(double? sanidade) {
    if (sanidade == null) return Colors.grey;
    if (sanidade >= 90) return Colors.green;
    if (sanidade >= 80) return Colors.lightGreen;
    if (sanidade >= 70) return Colors.orange;
    return Colors.red;
  }

  void _verDetalhes(PhenologicalRecordModel registro) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _buildDetalhesSheet(
          registro,
          scrollController,
        ),
      ),
    );
  }

  Widget _buildDetalhesSheet(
    PhenologicalRecordModel registro,
    ScrollController scrollController,
  ) {
    final estagio = PhenologicalClassificationService.classificarEstagio(
      registro: registro,
      cultura: widget.culturaNome ?? '',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: scrollController,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detalhes do Registro',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          _buildDetalheItem('📅 Data', DateFormat('dd/MM/yyyy').format(registro.dataRegistro)),
          _buildDetalheItem('🌱 DAE', '${registro.diasAposEmergencia} dias'),
          if (estagio != null) ...[
            _buildDetalheItem('🎯 Estágio', '${estagio.codigo} - ${estagio.nome}'),
          ],
          if (registro.alturaCm != null)
            _buildDetalheItem('📏 Altura', '${registro.alturaCm!.toStringAsFixed(1)} cm'),
          if (registro.numeroFolhas != null)
            _buildDetalheItem('🍃 Folhas', '${registro.numeroFolhas}'),
          if (registro.numeroFolhasTrifolioladas != null)
            _buildDetalheItem('🌿 Folhas Trifolioladas', '${registro.numeroFolhasTrifolioladas}'),
          if (registro.vagensPlanta != null)
            _buildDetalheItem('🌸 Vagens/Planta', registro.vagensPlanta!.toStringAsFixed(1)),
          if (registro.estandePlantas != null)
            _buildDetalheItem('🌾 Estande', '${(registro.estandePlantas! / 1000).toStringAsFixed(0)}k plantas/ha'),
          if (registro.percentualSanidade != null)
            _buildDetalheItem(
              '🩺 Sanidade',
              '${registro.percentualSanidade!.toStringAsFixed(1)}%',
              color: _getSanidadeColor(registro.percentualSanidade),
            ),
          if (registro.presencaPragas == true)
            _buildDetalheItem('🐛 Pragas', 'Presença detectada', color: Colors.red),
          if (registro.presencaDoencas == true)
            _buildDetalheItem('🦠 Doenças', 'Presença detectada', color: Colors.red),
          if (registro.sintomasObservados != null && registro.sintomasObservados!.isNotEmpty)
            _buildDetalheItem('👁️ Sintomas', registro.sintomasObservados!),
          if (registro.observacoes != null && registro.observacoes!.isNotEmpty)
            _buildDetalheItem('📝 Observações', registro.observacoes!),
        ],
      ),
    );
  }

  Widget _buildDetalheItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

