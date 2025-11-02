/// 📝 Screen: Registro Fenológico Quinzenal
/// 
/// Tela para registro de dados de campo (altura, vagens, sanidade, etc.)
/// com classificação automática de estágio fenológico.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/phenological_record_model.dart';
import '../providers/phenological_provider.dart';
import '../services/phenological_classification_service.dart';
import '../services/phenological_alert_service.dart';
import '../helpers/phenological_fields_helper.dart';

class PhenologicalRecordScreen extends StatefulWidget {
  final String? talhaoId;
  final String? culturaId;
  final String? talhaoNome;
  final String? culturaNome;
  final PhenologicalRecordModel? registroExistente;

  const PhenologicalRecordScreen({
    Key? key,
    this.talhaoId,
    this.culturaId,
    this.talhaoNome,
    this.culturaNome,
    this.registroExistente,
  }) : super(key: key);

  @override
  State<PhenologicalRecordScreen> createState() => _PhenologicalRecordScreenState();
}

class _PhenologicalRecordScreenState extends State<PhenologicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers de texto
  final _dataRegistroController = TextEditingController();
  final _daeController = TextEditingController();
  final _alturaController = TextEditingController();
  final _numeroFolhasController = TextEditingController();
  final _numeroFolhasTrifolioladasController = TextEditingController();
  final _diametroColmoController = TextEditingController();
  final _vagensPlantaController = TextEditingController();
  final _espigasPlantaController = TextEditingController();
  final _comprimentoVagensController = TextEditingController();
  final _graosVagemController = TextEditingController();
  final _estandeController = TextEditingController();
  final _percentualFalhasController = TextEditingController();
  final _percentualSanidadeController = TextEditingController();
  final _sintomasController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Controllers para novos campos dinâmicos
  final _numeroNosController = TextEditingController();
  final _espacamentoEntreNosController = TextEditingController();
  final _numeroRamosVegetativosController = TextEditingController();
  final _numeroRamosReprodutivosController = TextEditingController();
  final _alturaPrimeiroRamoFrutiferoController = TextEditingController();
  final _numeroBotoesFloraisController = TextEditingController();
  final _numeroMacasCapulhosController = TextEditingController();
  final _numeroAfilhosController = TextEditingController();
  final _comprimentoPaniculaController = TextEditingController();
  final _insercaoEspigaController = TextEditingController();
  final _comprimentoEspigaController = TextEditingController();
  final _numeroFileirasGraosController = TextEditingController();
  
  // Variáveis de estado
  bool _presencaPragas = false;
  bool _presencaDoencas = false;
  DateTime _dataRegistro = DateTime.now();
  bool _isSaving = false;
  
  // Campos dinâmicos por cultura
  List<String> _camposDisponiveis = [];

  @override
  void initState() {
    super.initState();
    _dataRegistroController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    // Carregar campos dinâmicos baseados na cultura
    _carregarCamposDinamicos();
    
    if (widget.registroExistente != null) {
      _carregarRegistroExistente();
    }
  }
  
  void _carregarCamposDinamicos() {
    if (widget.culturaId != null) {
      _camposDisponiveis = PhenologicalFieldsHelper.getFieldsForCulture(widget.culturaId!);
    } else {
      _camposDisponiveis = PhenologicalFieldsHelper.getFieldsForCulture('soja'); // Default
    }
  }

  void _carregarRegistroExistente() {
    final r = widget.registroExistente!;
    _dataRegistroController.text = DateFormat('dd/MM/yyyy').format(r.dataRegistro);
    _daeController.text = r.diasAposEmergencia.toString();
    _alturaController.text = r.alturaCm?.toString() ?? '';
    _numeroFolhasController.text = r.numeroFolhas?.toString() ?? '';
    _numeroFolhasTrifolioladasController.text = r.numeroFolhasTrifolioladas?.toString() ?? '';
    _diametroColmoController.text = r.diametroColmoMm?.toString() ?? '';
    _vagensPlantaController.text = r.vagensPlanta?.toString() ?? '';
    _espigasPlantaController.text = r.espigasPlanta?.toString() ?? '';
    _comprimentoVagensController.text = r.comprimentoVagensCm?.toString() ?? '';
    _graosVagemController.text = r.graosVagem?.toString() ?? '';
    _estandeController.text = r.estandePlantas?.toString() ?? '';
    _percentualFalhasController.text = r.percentualFalhas?.toString() ?? '';
    _percentualSanidadeController.text = r.percentualSanidade?.toString() ?? '';
    _sintomasController.text = r.sintomasObservados ?? '';
    _observacoesController.text = r.observacoes ?? '';
    _presencaPragas = r.presencaPragas ?? false;
    _presencaDoencas = r.presencaDoencas ?? false;
    
    // Carregar novos campos dinâmicos
    _numeroNosController.text = r.numeroNos?.toString() ?? '';
    _espacamentoEntreNosController.text = r.espacamentoEntreNosCm?.toString() ?? '';
    _numeroRamosVegetativosController.text = r.numeroRamosVegetativos?.toString() ?? '';
    _numeroRamosReprodutivosController.text = r.numeroRamosReprodutivos?.toString() ?? '';
    _alturaPrimeiroRamoFrutiferoController.text = r.alturaPrimeiroRamoFrutiferoCm?.toString() ?? '';
    _numeroBotoesFloraisController.text = r.numeroBotoesFlorais?.toString() ?? '';
    _numeroMacasCapulhosController.text = r.numeroMacasCapulhos?.toString() ?? '';
    _numeroAfilhosController.text = r.numeroAfilhos?.toString() ?? '';
    _comprimentoPaniculaController.text = r.comprimentoPaniculaCm?.toString() ?? '';
    _insercaoEspigaController.text = r.insercaoEspigaCm?.toString() ?? '';
    _comprimentoEspigaController.text = r.comprimentoEspigaCm?.toString() ?? '';
    _numeroFileirasGraosController.text = r.numeroFileirasGraos?.toString() ?? '';
  }

  @override
  void dispose() {
    _dataRegistroController.dispose();
    _daeController.dispose();
    _alturaController.dispose();
    _numeroFolhasController.dispose();
    _numeroFolhasTrifolioladasController.dispose();
    _diametroColmoController.dispose();
    _vagensPlantaController.dispose();
    _espigasPlantaController.dispose();
    _comprimentoVagensController.dispose();
    _graosVagemController.dispose();
    _estandeController.dispose();
    _percentualFalhasController.dispose();
    _percentualSanidadeController.dispose();
    _sintomasController.dispose();
    _observacoesController.dispose();
    
    // Dispose dos novos controllers
    _numeroNosController.dispose();
    _espacamentoEntreNosController.dispose();
    _numeroRamosVegetativosController.dispose();
    _numeroRamosReprodutivosController.dispose();
    _alturaPrimeiroRamoFrutiferoController.dispose();
    _numeroBotoesFloraisController.dispose();
    _numeroMacasCapulhosController.dispose();
    _numeroAfilhosController.dispose();
    _comprimentoPaniculaController.dispose();
    _insercaoEspigaController.dispose();
    _comprimentoEspigaController.dispose();
    _numeroFileirasGraosController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.registroExistente == null 
                ? 'Novo Registro Fenológico' 
                : 'Editar Registro'),
            if (widget.talhaoNome != null)
              Text(
                '${widget.talhaoNome} • ${widget.culturaNome ?? ""}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSecaoIdentificacao(),
                  const SizedBox(height: 16),
                  _buildSecaoCrescimentoVegetativo(),
                  const SizedBox(height: 16),
                  _buildSecaoCamposDinamicos(),
                  const SizedBox(height: 16),
                  _buildSecaoDesenvolvimentoReprodutivo(),
                  const SizedBox(height: 16),
                  _buildSecaoEstandeDensidade(),
                  const SizedBox(height: 16),
                  _buildSecaoSanidade(),
                  const SizedBox(height: 16),
                  _buildSecaoObservacoes(),
                  const SizedBox(height: 24),
                  _buildBotaoSalvar(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSecaoIdentificacao() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 Identificação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dataRegistroController,
              decoration: const InputDecoration(
                labelText: 'Data do Registro',
                hintText: 'DD/MM/AAAA',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () => _selecionarData(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _daeController,
              decoration: const InputDecoration(
                labelText: 'Dias Após Emergência (DAE) *',
                hintText: 'Ex: 45',
                prefixIcon: Icon(Icons.event_note),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoCrescimentoVegetativo() {
    final cultura = widget.culturaNome?.toLowerCase() ?? '';
    
    // Identificar tipo de cultura
    final isSoja = cultura.contains('soja');
    final isFeijao = cultura.contains('feij');
    final isMilho = cultura.contains('milho');
    final isSorgo = cultura.contains('sorgo');
    final isArroz = cultura.contains('arroz');
    final isTrigo = cultura.contains('trigo');
    final isAveia = cultura.contains('aveia');
    final isGirassol = cultura.contains('girassol');
    final isGergelim = cultura.contains('gergelim');
    final isAlgodao = cultura.contains('algod');
    final isTomate = cultura.contains('tomate');
    final isCana = cultura.contains('cana');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌱 Crescimento Vegetativo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // ALTURA - Todas as culturas
            TextFormField(
              controller: _alturaController,
              decoration: InputDecoration(
                labelText: 'Altura Média das Plantas',
                hintText: _getHintAltura(cultura),
                suffixText: 'cm',
                prefixIcon: const Icon(Icons.height),
                border: const OutlineInputBorder(),
                helperText: _getHelperAltura(cultura),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 12),
            
            // NÚMERO DE FOLHAS - Maioria das culturas
            if (!isCana) ...[
              TextFormField(
                controller: _numeroFolhasController,
                decoration: InputDecoration(
                  labelText: _getLabelFolhas(cultura),
                  hintText: _getHintFolhas(cultura),
                  prefixIcon: const Icon(Icons.eco),
                  border: const OutlineInputBorder(),
                  helperText: _getHelperFolhas(cultura),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
            ],
            
            // FOLHAS TRIFOLIOLADAS - Soja e Feijão
            if (isSoja || isFeijao) ...[
              TextFormField(
                controller: _numeroFolhasTrifolioladasController,
                decoration: InputDecoration(
                  labelText: isSoja ? '🌿 Folhas Trifolioladas (Soja)' : '🌿 Folhas Trifolioladas (Feijão)',
                  hintText: 'Ex: 4 (conta V1, V2, V3, V4...)',
                  prefixIcon: const Icon(Icons.energy_savings_leaf),
                  border: const OutlineInputBorder(),
                  helperText: 'Campo CRÍTICO para classificação do estágio vegetativo',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
            ],
            
            // DIÂMETRO DO COLMO - Milho e Sorgo
            if (isMilho || isSorgo) ...[
              TextFormField(
                controller: _diametroColmoController,
                decoration: InputDecoration(
                  labelText: '📏 Diâmetro do Colmo (${isMilho ? "Milho" : "Sorgo"})',
                  hintText: 'Ex: 22.5',
                  suffixText: 'mm',
                  prefixIcon: const Icon(Icons.straighten),
                  border: const OutlineInputBorder(),
                  helperText: 'Indicador de vigor da planta',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // PERFILHOS/AFILHOS - Cereais e Cana
            if (isArroz || isTrigo || isAveia || isCana) ...[
              TextFormField(
                controller: _numeroFolhasController,
                decoration: InputDecoration(
                  labelText: isCana ? '🌾 Perfilhos por Metro' : '🌾 Número de Afilhos/Perfilhos',
                  hintText: isCana ? 'Ex: 12' : 'Ex: 8',
                  prefixIcon: const Icon(Icons.grass),
                  border: const OutlineInputBorder(),
                  helperText: isCana 
                      ? 'Quantidade de colmos por metro linear' 
                      : 'Cada afilho/perfilho pode gerar uma espiga/panícula',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
            ],
            
            // PARES DE FOLHAS - Girassol
            if (isGirassol) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🌻 Girassol: Conte PARES de folhas (4 pares = 8 folhas, 8 pares = 16 folhas)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
  
  // Helpers para textos adaptativos
  String _getHintAltura(String cultura) {
    if (cultura.contains('soja')) return 'Ex: 50 (V4), 70 (R3), 100 (R9)';
    if (cultura.contains('milho')) return 'Ex: 90 (V4), 200 (VT), 250 (R6)';
    if (cultura.contains('cana')) return 'Ex: 100 (PE), 250 (CE), 320 (MA)';
    if (cultura.contains('tomate')) return 'Ex: 40 (V6), 100 (R3), 150 (R6)';
    return 'Ex: 45.5';
  }
  
  String _getHelperAltura(String cultura) {
    if (cultura.contains('cana')) return 'Altura dos colmos principais';
    if (cultura.contains('tomate')) return 'Do solo até o ápice (tutor se houver)';
    return 'Altura do solo até o ápice da planta';
  }
  
  String _getLabelFolhas(String cultura) {
    if (cultura.contains('girassol')) return '🌻 Pares de Folhas (Girassol)';
    if (cultura.contains('trigo') || cultura.contains('aveia')) return '🌾 Número de Afilhos';
    if (cultura.contains('arroz')) return '🌾 Número de Perfilhos';
    if (cultura.contains('cana')) return '🌾 Perfilhos por Metro';
    return 'Número de Folhas Expandidas';
  }
  
  String _getHintFolhas(String cultura) {
    if (cultura.contains('girassol')) return 'Ex: 8 (= 16 folhas totais)';
    if (cultura.contains('soja')) return 'Ex: 8';
    if (cultura.contains('milho')) return 'Ex: 6 (para V6), 14 (para VT)';
    return 'Ex: 8';
  }
  
  String _getHelperFolhas(String cultura) {
    if (cultura.contains('girassol')) return 'Girassol: conte PARES (V4=4 pares, V8=8 pares)';
    if (cultura.contains('trigo') || cultura.contains('aveia')) return 'Cada afilho pode produzir uma espiga';
    if (cultura.contains('arroz')) return 'Cada perfilho pode produzir uma panícula';
    return 'Folhas completamente expandidas';
  }

  Widget _buildSecaoDesenvolvimentoReprodutivo() {
    final cultura = widget.culturaNome?.toLowerCase() ?? '';
    
    // Identificar tipo de cultura
    final isSoja = cultura.contains('soja');
    final isFeijao = cultura.contains('feij');
    final isMilho = cultura.contains('milho');
    final isSorgo = cultura.contains('sorgo');
    final isArroz = cultura.contains('arroz');
    final isTrigo = cultura.contains('trigo');
    final isAveia = cultura.contains('aveia');
    final isGirassol = cultura.contains('girassol');
    final isGergelim = cultura.contains('gergelim');
    final isAlgodao = cultura.contains('algod');
    final isTomate = cultura.contains('tomate');
    final isCana = cultura.contains('cana');
    
    // Cereais com panícula/espiga
    final isCereal = isArroz || isTrigo || isAveia || isSorgo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌸 Desenvolvimento Reprodutivo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // LEGUMINOSAS (Soja, Feijão) - VAGENS
            if (isSoja || isFeijao) ...[
              TextFormField(
                controller: _vagensPlantaController,
                decoration: InputDecoration(
                  labelText: '🌸 Número de Vagens por Planta',
                  hintText: isSoja ? 'Ex: 40 (ideal), 25 (médio)' : 'Ex: 12 (ideal), 8 (médio)',
                  prefixIcon: const Icon(Icons.apps),
                  border: const OutlineInputBorder(),
                  helperText: 'Campo CRÍTICO para R3, R5, R8',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _comprimentoVagensController,
                decoration: InputDecoration(
                  labelText: '📏 Comprimento Médio das Vagens',
                  hintText: 'Ex: 1.2 (R3), 2.5 (R5), 4.0 (R8)',
                  suffixText: 'cm',
                  prefixIcon: const Icon(Icons.straighten),
                  border: const OutlineInputBorder(),
                  helperText: 'Ajuda a diferenciar R3 (<1.5cm) de R5 (>2cm)',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _graosVagemController,
                decoration: InputDecoration(
                  labelText: '🌾 Grãos por Vagem',
                  hintText: isSoja ? 'Ex: 2.5 (média soja)' : 'Ex: 5.0 (média feijão)',
                  prefixIcon: const Icon(Icons.grain),
                  border: const OutlineInputBorder(),
                  helperText: 'Para estimativa de produtividade',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
            
            // MILHO - ESPIGAS
            if (isMilho) ...[
              TextFormField(
                controller: _espigasPlantaController,
                decoration: const InputDecoration(
                  labelText: '🌽 Número de Espigas por Planta',
                  hintText: 'Ex: 1 (normal), 2 (prolífico)',
                  prefixIcon: Icon(Icons.local_florist),
                  border: OutlineInputBorder(),
                  helperText: 'Maioria dos híbridos = 1 espiga/planta',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _graosVagemController,
                decoration: const InputDecoration(
                  labelText: '🌾 Grãos por Espiga (Estimativa)',
                  hintText: 'Ex: 450 (média), 600 (alto potencial)',
                  prefixIcon: Icon(Icons.grain),
                  border: OutlineInputBorder(),
                  helperText: 'Contar em 3-5 espigas e fazer média',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
            
            // CEREAIS (Arroz, Trigo, Aveia, Sorgo) - PANÍCULAS/ESPIGAS
            if (isCereal) ...[
              TextFormField(
                controller: _espigasPlantaController,
                decoration: InputDecoration(
                  labelText: isArroz || isSorgo ? '🌾 Panículas por Planta' : '🌾 Espigas por Planta',
                  hintText: 'Ex: 1 (por afilho/perfilho)',
                  prefixIcon: const Icon(Icons.grain),
                  border: const OutlineInputBorder(),
                  helperText: 'Normalmente 1 por afilho/perfilho',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _graosVagemController,
                decoration: InputDecoration(
                  labelText: isArroz || isSorgo ? '🌾 Grãos por Panícula' : '🌾 Grãos por Espiga',
                  hintText: _getHintGraos(cultura),
                  prefixIcon: const Icon(Icons.grain),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
            
            // ALGODÃO - BOTÕES, FLORES, CAPULHOS
            if (isAlgodao) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: const Text(
                  '🌾 ALGODÃO: Preencha conforme a fase\n'
                  '• Fase B1: Conte botões florais\n'
                  '• Fase F1: Conte flores abertas\n'
                  '• Fase C1-C2: Conte capulhos',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vagensPlantaController,
                decoration: const InputDecoration(
                  labelText: '☁️ Capulhos por Planta (Algodão)',
                  hintText: 'Ex: 35 (bom estande)',
                  prefixIcon: Icon(Icons.cloud),
                  border: OutlineInputBorder(),
                  helperText: 'Conte capulhos totais (verdes + maduros)',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
            
            // GIRASSOL - CAPÍTULO E AQUÊNIOS
            if (isGirassol) ...[
              TextFormField(
                controller: _espigasPlantaController,
                decoration: const InputDecoration(
                  labelText: '🌻 Capítulos por Planta',
                  hintText: 'Ex: 1 (normal)',
                  prefixIcon: Icon(Icons.wb_sunny),
                  border: OutlineInputBorder(),
                  helperText: 'Geralmente 1 capítulo por planta',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _graosVagemController,
                decoration: const InputDecoration(
                  labelText: '🌻 Aquênios por Capítulo (Estimativa)',
                  hintText: 'Ex: 900 (média), 1200 (alto potencial)',
                  prefixIcon: Icon(Icons.grain),
                  border: OutlineInputBorder(),
                  helperText: 'Difícil contar exato, use estimativa',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
            
            // GERGELIM - CÁPSULAS
            if (isGergelim) ...[
              TextFormField(
                controller: _vagensPlantaController,
                decoration: const InputDecoration(
                  labelText: '📦 Cápsulas por Planta',
                  hintText: 'Ex: 80 (média)',
                  prefixIcon: Icon(Icons.crop_square),
                  border: OutlineInputBorder(),
                  helperText: 'Cápsulas totais (verdes + maduras)',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _graosVagemController,
                decoration: const InputDecoration(
                  labelText: '🌾 Sementes por Cápsula',
                  hintText: 'Ex: 70 (média)',
                  prefixIcon: Icon(Icons.grain),
                  border: OutlineInputBorder(),
                  helperText: 'Abrir 3-5 cápsulas e contar',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
            
            // TOMATE - PENCAS E FRUTOS
            if (isTomate) ...[
              TextFormField(
                controller: _espigasPlantaController,
                decoration: const InputDecoration(
                  labelText: '🍅 Pencas por Planta',
                  hintText: 'Ex: 8 (média)',
                  prefixIcon: Icon(Icons.view_agenda),
                  border: OutlineInputBorder(),
                  helperText: 'Conte pencas com frutos',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _graosVagemController,
                decoration: const InputDecoration(
                  labelText: '🍅 Frutos por Penca',
                  hintText: 'Ex: 5 (média)',
                  prefixIcon: Icon(Icons.circle),
                  border: OutlineInputBorder(),
                  helperText: 'Média de frutos por penca',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              // Indicador de cor dos frutos
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '🍅 Cor predominante dos frutos:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '🟢 Verde → R3, R4 (fruto formado)\n'
                      '🟠 Breaker (mudando cor) → R5\n'
                      '🔴 Vermelho → R6 (ponto colheita)',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
            
            // ALGODÃO - CAPULHOS
            if (isAlgodao) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: const Text(
                  '🌾 ALGODÃO: Progressão reprodutiva\n'
                  '• B1 (35-50 DAE): Botões florais visíveis\n'
                  '• F1 (45-65 DAE): Flores abertas (rosa)\n'
                  '• C1 (65-90 DAE): Capulhos formados (verdes)\n'
                  '• C2 (110-140 DAE): Capulhos abrindo (brancos)',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vagensPlantaController,
                decoration: const InputDecoration(
                  labelText: '☁️ Capulhos por Planta',
                  hintText: 'Ex: 35 (bom estande)',
                  prefixIcon: Icon(Icons.cloud),
                  border: OutlineInputBorder(),
                  helperText: 'Conte capulhos totais (verdes + abertos)',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
            
            // MILHO - ESPIGAS
            if (isMilho) ...[
              TextFormField(
                controller: _espigasPlantaController,
                decoration: const InputDecoration(
                  labelText: '🌽 Espigas por Planta',
                  hintText: 'Ex: 1 (normal), 2 (prolífico)',
                  prefixIcon: Icon(Icons.local_florist),
                  border: OutlineInputBorder(),
                  helperText: 'Maioria dos híbridos: 1 espiga/planta',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _graosVagemController,
                decoration: const InputDecoration(
                  labelText: '🌽 Grãos por Espiga (Estimativa)',
                  hintText: 'Ex: 450 (média), 600 (alto potencial)',
                  prefixIcon: Icon(Icons.grain),
                  border: OutlineInputBorder(),
                  helperText: 'Contar em 3-5 espigas e fazer média',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
            
            // CEREAIS (Arroz, Trigo, Aveia, Sorgo) - PANÍCULAS/ESPIGAS
            if (isCereal) ...[
              TextFormField(
                controller: _espigasPlantaController,
                decoration: InputDecoration(
                  labelText: isArroz || isSorgo ? '🌾 Panículas por Afilho' : '🌾 Espigas por Afilho',
                  hintText: 'Ex: 1 (normal)',
                  prefixIcon: const Icon(Icons.grain),
                  border: const OutlineInputBorder(),
                  helperText: 'Cada afilho produz 1 panícula/espiga',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _graosVagemController,
                decoration: InputDecoration(
                  labelText: isArroz || isSorgo ? '🌾 Grãos por Panícula' : '🌾 Grãos por Espiga',
                  hintText: _getHintGraosCereal(cultura),
                  prefixIcon: const Icon(Icons.grain),
                  border: const OutlineInputBorder(),
                  helperText: 'Contar em 3-5 panículas/espigas',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
            
            // GIRASSOL - CAPÍTULO
            if (isGirassol) ...[
              TextFormField(
                controller: _espigasPlantaController,
                decoration: const InputDecoration(
                  labelText: '🌻 Capítulos por Planta',
                  hintText: 'Ex: 1 (normal)',
                  prefixIcon: Icon(Icons.wb_sunny),
                  border: OutlineInputBorder(),
                  helperText: 'Normalmente 1 capítulo por planta',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _graosVagemController,
                decoration: const InputDecoration(
                  labelText: '🌻 Aquênios por Capítulo (Estimativa)',
                  hintText: 'Ex: 900 (média), 1200 (alto)',
                  prefixIcon: Icon(Icons.grain),
                  border: OutlineInputBorder(),
                  helperText: 'Estimativa visual (difícil contar exato)',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
            
            // GERGELIM - CÁPSULAS
            if (isGergelim) ...[
              TextFormField(
                controller: _vagensPlantaController,
                decoration: const InputDecoration(
                  labelText: '📦 Cápsulas por Planta',
                  hintText: 'Ex: 80 (média)',
                  prefixIcon: Icon(Icons.crop_square),
                  border: OutlineInputBorder(),
                  helperText: 'Cápsulas ao longo do caule',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _graosVagemController,
                decoration: const InputDecoration(
                  labelText: '🌰 Sementes por Cápsula',
                  hintText: 'Ex: 70 (média)',
                  prefixIcon: Icon(Icons.grain),
                  border: OutlineInputBorder(),
                  helperText: 'Abrir 3-5 cápsulas maduras e contar',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
            
            // CANA - Não tem campos reprodutivos (ciclo vegetativo)
            if (isCana) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info, color: Colors.green, size: 32),
                    SizedBox(height: 8),
                    Text(
                      '🌾 CANA-DE-AÇÚCAR\n\n'
                      'Cultura com ciclo vegetativo longo.\n'
                      'Foco em: Perfilhamento, Altura e Diâmetro dos colmos.\n\n'
                      'Não possui fase reprodutiva típica (colheita dos colmos).',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _getHintGraos(String cultura) {
    if (cultura.contains('arroz')) return 'Ex: 110 (média arroz)';
    if (cultura.contains('sorgo')) return 'Ex: 1800 (média sorgo)';
    if (cultura.contains('trigo')) return 'Ex: 35 (média trigo)';
    if (cultura.contains('aveia')) return 'Ex: 40 (média aveia)';
    return 'Ex: 100';
  }
  
  String _getHintGraosCereal(String cultura) {
    if (cultura.contains('arroz')) return 'Ex: 110 (média arroz)';
    if (cultura.contains('sorgo')) return 'Ex: 1800 (média sorgo)';
    if (cultura.contains('trigo')) return 'Ex: 35 (média trigo)';
    if (cultura.contains('aveia')) return 'Ex: 40 (média aveia)';
    return 'Ex: 100';
  }

  Widget _buildSecaoEstandeDensidade() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌾 Estande e Densidade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _estandeController,
              decoration: const InputDecoration(
                labelText: 'Estande Real',
                hintText: 'Ex: 280000',
                suffixText: 'plantas/ha',
                prefixIcon: Icon(Icons.people),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _percentualFalhasController,
              decoration: const InputDecoration(
                labelText: 'Percentual de Falhas',
                hintText: 'Ex: 5.5',
                suffixText: '%',
                prefixIcon: Icon(Icons.warning),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoSanidade() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🩺 Sanidade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _percentualSanidadeController,
              decoration: const InputDecoration(
                labelText: 'Percentual de Plantas Sadias',
                hintText: 'Ex: 85',
                suffixText: '%',
                prefixIcon: Icon(Icons.health_and_safety),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Presença de Pragas'),
              value: _presencaPragas,
              onChanged: (value) => setState(() => _presencaPragas = value),
              secondary: const Icon(Icons.bug_report),
            ),
            SwitchListTile(
              title: const Text('Presença de Doenças'),
              value: _presencaDoencas,
              onChanged: (value) => setState(() => _presencaDoencas = value),
              secondary: const Icon(Icons.coronavirus),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sintomasController,
              decoration: const InputDecoration(
                labelText: 'Sintomas Observados',
                hintText: 'Descreva sintomas visuais (clorose, necrose, etc.)',
                prefixIcon: Icon(Icons.visibility),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoObservacoes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 Observações Gerais',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Anotações adicionais sobre o registro...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoSalvar() {
    return ElevatedButton.icon(
      onPressed: _salvarRegistro,
      icon: const Icon(Icons.save),
      label: const Text('Salvar Registro'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataRegistro,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _dataRegistro = picked;
        _dataRegistroController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _salvarRegistro() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrija os erros no formulário'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validações adicionais
    if (widget.talhaoId == null || widget.talhaoId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erro: ID do talhão não foi fornecido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.culturaId == null || widget.culturaId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erro: ID da cultura não foi fornecido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      print('📝 Iniciando salvamento do registro...');
      print('   Talhão: ${widget.talhaoId}');
      print('   Cultura: ${widget.culturaId} (${widget.culturaNome})');
      
      // Criar modelo de registro
      final registro = PhenologicalRecordModel.novo(
        talhaoId: widget.talhaoId!,
        culturaId: widget.culturaId!,
        dataRegistro: _dataRegistro,
        diasAposEmergencia: int.parse(_daeController.text),
        alturaCm: _alturaController.text.isNotEmpty 
            ? double.parse(_alturaController.text.replaceAll(',', '.')) 
            : null,
        numeroFolhas: _numeroFolhasController.text.isNotEmpty 
            ? int.parse(_numeroFolhasController.text) 
            : null,
        numeroFolhasTrifolioladas: _numeroFolhasTrifolioladasController.text.isNotEmpty 
            ? int.parse(_numeroFolhasTrifolioladasController.text) 
            : null,
        diametroColmoMm: _diametroColmoController.text.isNotEmpty 
            ? double.parse(_diametroColmoController.text.replaceAll(',', '.')) 
            : null,
        vagensPlanta: _vagensPlantaController.text.isNotEmpty 
            ? double.parse(_vagensPlantaController.text.replaceAll(',', '.')) 
            : null,
        espigasPlanta: _espigasPlantaController.text.isNotEmpty 
            ? double.parse(_espigasPlantaController.text.replaceAll(',', '.')) 
            : null,
        comprimentoVagensCm: _comprimentoVagensController.text.isNotEmpty 
            ? double.parse(_comprimentoVagensController.text.replaceAll(',', '.')) 
            : null,
        graosVagem: _graosVagemController.text.isNotEmpty 
            ? double.parse(_graosVagemController.text.replaceAll(',', '.')) 
            : null,
        estandePlantas: _estandeController.text.isNotEmpty 
            ? double.parse(_estandeController.text.replaceAll(',', '.')) 
            : null,
        percentualFalhas: _percentualFalhasController.text.isNotEmpty 
            ? double.parse(_percentualFalhasController.text.replaceAll(',', '.')) 
            : null,
        percentualSanidade: _percentualSanidadeController.text.isNotEmpty 
            ? double.parse(_percentualSanidadeController.text.replaceAll(',', '.')) 
            : null,
        sintomasObservados: _sintomasController.text.isNotEmpty 
            ? _sintomasController.text 
            : null,
        presencaPragas: _presencaPragas,
        presencaDoencas: _presencaDoencas,
        observacoes: _observacoesController.text.isNotEmpty 
            ? _observacoesController.text 
            : null,
        // Novos campos dinâmicos
        numeroNos: _numeroNosController.text.isNotEmpty 
            ? int.parse(_numeroNosController.text) 
            : null,
        espacamentoEntreNosCm: _espacamentoEntreNosController.text.isNotEmpty 
            ? double.parse(_espacamentoEntreNosController.text.replaceAll(',', '.')) 
            : null,
        numeroRamosVegetativos: _numeroRamosVegetativosController.text.isNotEmpty 
            ? int.parse(_numeroRamosVegetativosController.text) 
            : null,
        numeroRamosReprodutivos: _numeroRamosReprodutivosController.text.isNotEmpty 
            ? int.parse(_numeroRamosReprodutivosController.text) 
            : null,
        alturaPrimeiroRamoFrutiferoCm: _alturaPrimeiroRamoFrutiferoController.text.isNotEmpty 
            ? double.parse(_alturaPrimeiroRamoFrutiferoController.text.replaceAll(',', '.')) 
            : null,
        numeroBotoesFlorais: _numeroBotoesFloraisController.text.isNotEmpty 
            ? int.parse(_numeroBotoesFloraisController.text) 
            : null,
        numeroMacasCapulhos: _numeroMacasCapulhosController.text.isNotEmpty 
            ? int.parse(_numeroMacasCapulhosController.text) 
            : null,
        numeroAfilhos: _numeroAfilhosController.text.isNotEmpty 
            ? int.parse(_numeroAfilhosController.text) 
            : null,
        comprimentoPaniculaCm: _comprimentoPaniculaController.text.isNotEmpty 
            ? double.parse(_comprimentoPaniculaController.text.replaceAll(',', '.')) 
            : null,
        insercaoEspigaCm: _insercaoEspigaController.text.isNotEmpty 
            ? double.parse(_insercaoEspigaController.text.replaceAll(',', '.')) 
            : null,
        comprimentoEspigaCm: _comprimentoEspigaController.text.isNotEmpty 
            ? double.parse(_comprimentoEspigaController.text.replaceAll(',', '.')) 
            : null,
        numeroFileirasGraos: _numeroFileirasGraosController.text.isNotEmpty 
            ? int.parse(_numeroFileirasGraosController.text) 
            : null,
      );

      print('✅ Modelo de registro criado: ${registro.id}');

      // Classificar estágio fenológico
      print('🌱 Classificando estágio fenológico...');
      final estagio = PhenologicalClassificationService.classificarEstagio(
        registro: registro,
        cultura: widget.culturaNome ?? '',
      );

      print('   Estágio identificado: ${estagio?.codigo ?? "Não identificado"}');

      final registroComEstagio = registro.copyWith(
        estagioFenologico: estagio?.codigo,
        descricaoEstagio: estagio?.nome,
      );

      // Salvar no provider
      print('💾 Obtendo provider...');
      final provider = Provider.of<PhenologicalProvider>(context, listen: false);
      
      print('💾 Salvando registro no banco de dados...');
      await provider.adicionarRegistro(registroComEstagio);
      print('✅ Registro salvo no banco!');

      // Gerar alertas
      print('🚨 Analisando e gerando alertas...');
      final alertas = PhenologicalAlertService.analisarEGerarAlertas(
        registro: registroComEstagio,
        cultura: widget.culturaNome ?? '',
      );

      print('   ${alertas.length} alerta(s) gerado(s)');

      // Salvar alertas
      for (final alerta in alertas) {
        print('   Salvando alerta: ${alerta.titulo}');
        await provider.adicionarAlerta(alerta);
      }

      print('✅ Processo de salvamento concluído com sucesso!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Registro salvo com sucesso!\n'
              'Estágio: ${estagio?.codigo ?? "N/A"}\n'
              'Alertas: ${alertas.length}'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar sucesso
      }
    } catch (e, stackTrace) {
      print('❌ ERRO AO SALVAR REGISTRO:');
      print('   Erro: $e');
      print('   Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Erro ao salvar registro:\n${e.toString()}\n\n'
              'Verifique o console para mais detalhes.'
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  /// Constrói seção de campos dinâmicos baseados na cultura
  Widget _buildSecaoCamposDinamicos() {
    if (_camposDisponiveis.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.agriculture, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '🌱 Parâmetros Específicos - ${widget.culturaNome ?? "Cultura"}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Campos específicos para esta cultura baseados no guia técnico de Crescimento e Desenvolvimento:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._camposDisponiveis.map((campo) => _buildCampoDinamico(campo)).toList(),
          ],
        ),
      ),
    );
  }
  
  /// Constrói um campo dinâmico específico
  Widget _buildCampoDinamico(String campoId) {
    final label = PhenologicalFieldsHelper.getFieldLabel(campoId);
    final controller = _getControllerForField(campoId);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Digite o valor...',
          border: const OutlineInputBorder(),
          prefixIcon: _getIconForField(campoId),
        ),
        keyboardType: _getKeyboardTypeForField(campoId),
        inputFormatters: _getInputFormattersForField(campoId),
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final numValue = double.tryParse(value.replaceAll(',', '.'));
            if (numValue == null) {
              return 'Digite um valor numérico válido';
            }
            if (numValue < 0) {
              return 'O valor deve ser positivo';
            }
          }
          return null;
        },
      ),
    );
  }
  
  /// Obtém o controller apropriado para o campo
  TextEditingController _getControllerForField(String campoId) {
    switch (campoId) {
      case 'numeroNos': return _numeroNosController;
      case 'espacamentoEntreNosCm': return _espacamentoEntreNosController;
      case 'numeroRamosVegetativos': return _numeroRamosVegetativosController;
      case 'numeroRamosReprodutivos': return _numeroRamosReprodutivosController;
      case 'alturaPrimeiroRamoFrutiferoCm': return _alturaPrimeiroRamoFrutiferoController;
      case 'numeroBotoesFlorais': return _numeroBotoesFloraisController;
      case 'numeroMacasCapulhos': return _numeroMacasCapulhosController;
      case 'numeroAfilhos': return _numeroAfilhosController;
      case 'comprimentoPaniculaCm': return _comprimentoPaniculaController;
      case 'insercaoEspigaCm': return _insercaoEspigaController;
      case 'comprimentoEspigaCm': return _comprimentoEspigaController;
      case 'numeroFileirasGraos': return _numeroFileirasGraosController;
      default: return TextEditingController();
    }
  }
  
  /// Obtém o ícone apropriado para o campo
  Widget _getIconForField(String campoId) {
    return Icon(_getIconDataForField(campoId));
  }

  /// Obtém o IconData para o campo
  IconData _getIconDataForField(String campoId) {
    switch (campoId) {
      case 'numeroNos': return Icons.straighten;
      case 'espacamentoEntreNosCm': return Icons.straighten;
      case 'numeroRamosVegetativos': return Icons.eco;
      case 'numeroRamosReprodutivos': return Icons.local_florist;
      case 'alturaPrimeiroRamoFrutiferoCm': return Icons.height;
      case 'numeroBotoesFlorais': return Icons.wb_sunny;
      case 'numeroMacasCapulhos': return Icons.apple;
      case 'numeroAfilhos': return Icons.account_tree;
      case 'comprimentoPaniculaCm': return Icons.straighten;
      case 'insercaoEspigaCm': return Icons.height;
      case 'comprimentoEspigaCm': return Icons.straighten;
      case 'numeroFileirasGraos': return Icons.grain;
      default: return Icons.agriculture;
    }
  }
  
  /// Obtém o tipo de teclado apropriado para o campo
  TextInputType _getKeyboardTypeForField(String campoId) {
    switch (campoId) {
      case 'numeroNos':
      case 'numeroRamosVegetativos':
      case 'numeroRamosReprodutivos':
      case 'numeroBotoesFlorais':
      case 'numeroMacasCapulhos':
      case 'numeroAfilhos':
      case 'numeroFileirasGraos':
        return TextInputType.number;
      default:
        return const TextInputType.numberWithOptions(decimal: true);
    }
  }
  
  /// Obtém os formatadores de entrada apropriados para o campo
  List<TextInputFormatter> _getInputFormattersForField(String campoId) {
    switch (campoId) {
      case 'numeroNos':
      case 'numeroRamosVegetativos':
      case 'numeroRamosReprodutivos':
      case 'numeroBotoesFlorais':
      case 'numeroMacasCapulhos':
      case 'numeroAfilhos':
      case 'numeroFileirasGraos':
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    }
  }
}

