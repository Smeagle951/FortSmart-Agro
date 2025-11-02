/// 📊 TELA DE REGISTRO DIÁRIO DE GERMINAÇÃO - VERSÃO SIMPLIFICADA
/// 
/// Tela para registro diário de testes de germinação
/// Versão simplificada para evitar erros de compilação

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/germination_test_model.dart';
import '../providers/germination_test_provider.dart';

/// 🎯 Tela Principal de Registro Diário
class GerminationDailyRecordScreen extends StatefulWidget {
  final GerminationTest test;
  final int? day;
  final GerminationDailyRecord? existingRecord;
  final String? subtestName; // Nome do subteste (A, B, C) ou null para teste individual
  
  const GerminationDailyRecordScreen({
    Key? key,
    required this.test,
    this.day,
    this.existingRecord,
    this.subtestName,
  }) : super(key: key);

  @override
  State<GerminationDailyRecordScreen> createState() => _GerminationDailyRecordScreenState();
}

class _GerminationDailyRecordScreenState extends State<GerminationDailyRecordScreen> {
  
  // Form key
  final _formKey = GlobalKey<FormState>();
  
  // Dados do teste
  bool _isLoading = false;
  bool _isSaving = false;
  DateTime _recordDate = DateTime.now();
  int _currentDay = 1;
  
  // Controllers para teste individual - ESTRUTURA AGRONÔMICA RIGOROSA
  final _normalGerminatedController = TextEditingController(); // Plântulas germinadas (normais)
  final _diseasedController = TextEditingController(); // Doentes
  final _yellowCotyledonsController = TextEditingController(); // Cotilédones amarelados
  final _spottedController = TextEditingController(); // Com manchas
  final _rottenController = TextEditingController(); // Com podridão
  final _temperatureController = TextEditingController(); // Temperatura ambiente (°C)
  final _humidityController = TextEditingController(); // Umidade relativa (%)
  final _notGerminatedController = TextEditingController(); // Calculado automaticamente
  final _observationsController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _currentDay = widget.day ?? 1;
    
    // Se existir um registro, carregar os dados para edição
    if (widget.existingRecord != null) {
      _loadExistingRecord(widget.existingRecord!);
    }
  }
  
  void _loadExistingRecord(GerminationDailyRecord record) {
    _normalGerminatedController.text = record.normalGerminated.toString();
    _diseasedController.text = '${record.diseasedFungi + record.diseasedBacteria}';
    _notGerminatedController.text = record.notGerminated.toString();
    _observationsController.text = record.observations ?? '';
    _currentDay = record.day;
    _recordDate = record.recordDate; // Carregar a data do registro existente
  }
  
  @override
  void dispose() {
    _normalGerminatedController.dispose();
    _diseasedController.dispose();
    _yellowCotyledonsController.dispose();
    _spottedController.dispose();
    _rottenController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _notGerminatedController.dispose();
    _observationsController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _buildMainContent(),
    );
  }
  
  /// 🎯 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.green.shade600,
      foregroundColor: Colors.white,
      title: Text(
        widget.subtestName != null 
            ? 'Registro Diário - Subteste ${widget.subtestName}'
            : 'Registro Diário - Teste Individual',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// 🔄 Estado de carregamento
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando dados do teste...'),
        ],
      ),
    );
  }
  
  /// 📱 Conteúdo principal
  Widget _buildMainContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestInfoCard(),
            const SizedBox(height: 16),
            _buildDayInfoCard(),
            const SizedBox(height: 16),
            _buildIndividualTestSection(),
            const SizedBox(height: 16),
            _buildObservationsCard(),
            const SizedBox(height: 16),
            _buildSaveButton(),
            const SizedBox(height: 100), // Espaço para FAB
          ],
        ),
      ),
    );
  }
  
  /// 📋 Card de informações do teste
  Widget _buildTestInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.green.shade600, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Informações do Teste',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Nome do Teste:', '${widget.test.culture} - ${widget.test.variety}'),
            _buildInfoRow('ID do Teste:', '${widget.test.id}'),
            if (widget.subtestName != null) 
              _buildInfoRow('Subteste:', widget.subtestName!),
            _buildInfoRow('Dia Atual:', '$_currentDay'),
          ],
        ),
      ),
    );
  }
  
  /// 📅 Card de informações do dia
  Widget _buildDayInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Informações do Dia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectRecordDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data do Registro',
                  border: const OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade600),
                  hintText: 'Toque para alterar a data',
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(_recordDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 🧪 Seção de teste individual
  Widget _buildIndividualTestSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.green.shade600, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Registro Individual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Dados inseridos pelo usuário - ESTRUTURA AGRONÔMICA RIGOROSA
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📝 Dados Inseridos pelo Usuário:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _normalGerminatedController,
                          label: 'Plântulas Germinadas (Normais) *',
                          icon: Icons.check_circle,
                          color: Colors.green,
                          onChanged: _calculateNotGerminated,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField(
                          controller: _diseasedController,
                          label: 'Doentes *',
                          icon: Icons.sick,
                          color: Colors.red,
                          onChanged: _calculateNotGerminated,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _yellowCotyledonsController,
                          label: 'Cotilédones Amarelados *',
                          icon: Icons.warning_amber,
                          color: Colors.orange,
                          onChanged: _calculateNotGerminated,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField(
                          controller: _spottedController,
                          label: 'Com Manchas *',
                          icon: Icons.circle,
                          color: Colors.purple,
                          onChanged: _calculateNotGerminated,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _rottenController,
                          label: 'Com Podridão *',
                          icon: Icons.bug_report,
                          color: Colors.red,
                          onChanged: _calculateNotGerminated,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField(
                          controller: _temperatureController,
                          label: 'Temperatura Ambiente (°C) *',
                          icon: Icons.thermostat,
                          color: Colors.blue,
                          onChanged: null, // Não afeta cálculo
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _humidityController,
                          label: 'Umidade Relativa (%) *',
                          icon: Icons.water_drop,
                          color: Colors.cyan,
                          onChanged: null, // Não afeta cálculo
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField(
                          controller: _notGerminatedController,
                          label: 'Não Germinadas (Calculado)',
                          icon: Icons.cancel,
                          color: Colors.grey,
                          readOnly: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Fórmula de cálculo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🧮 Fórmula Automática:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Não Germinadas = Total - (Germinadas + Doentes + Amarelados + Manchas + Podridão)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                      fontStyle: FontStyle.italic,
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
  
  /// 📝 Card de observações
  Widget _buildObservationsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt, color: Colors.orange.shade600, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Observações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observationsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Observações do dia',
                hintText: 'Digite observações sobre o teste...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 💾 Botão de salvar
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveRecord,
        icon: _isSaving 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Salvando...' : 'Salvar Registro'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  // === WIDGETS AUXILIARES ===
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 📝 Campo de entrada
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color, size: 20),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: onChanged,
      validator: (value) {
        if (!readOnly && (value == null || value.isEmpty)) {
          return 'Campo obrigatório';
        }
        final number = int.tryParse(value ?? '0');
        if (number != null && number < 0) {
          return 'Valor inválido';
        }
        return null;
      },
    );
  }
  
  // === MÉTODOS DE CÁLCULO ===
  
  /// 🧮 Calcula sementes não germinadas
  /// 🧮 Calcula sementes não germinadas - ESTRUTURA AGRONÔMICA RIGOROSA
  void _calculateNotGerminated(String value) {
    // Determinar o total de sementes baseado no tipo de teste
    int totalSeeds;
    if (widget.test.useSubtests && widget.subtestName != null) {
      // Para subtestes, usar o número de sementes por subteste (padrão 100)
      totalSeeds = widget.test.subtestSeedCount;
    } else {
      // Para teste individual, usar o total de sementes
      totalSeeds = widget.test.totalSeeds;
    }
    
    // Dados inseridos pelo usuário - ESTRUTURA AGRONÔMICA RIGOROSA
    final normal = int.tryParse(_normalGerminatedController.text) ?? 0; // Plântulas germinadas (normais)
    final diseased = int.tryParse(_diseasedController.text) ?? 0; // Doentes
    final yellowCotyledons = int.tryParse(_yellowCotyledonsController.text) ?? 0; // Cotilédones amarelados
    final spotted = int.tryParse(_spottedController.text) ?? 0; // Com manchas
    final rotten = int.tryParse(_rottenController.text) ?? 0; // Com podridão
    
    // FÓRMULA AGRONÔMICA RIGOROSA:
    // Não Germinadas = Total - (Germinadas + Doentes + Amarelados + Manchas + Podridão)
    final notGerminated = totalSeeds - (normal + diseased + yellowCotyledons + spotted + rotten);
    
    _notGerminatedController.text = notGerminated.toString();
    
    // Calcular resultados em tempo real
    _calculateResults();
  }
  
  /// 📊 Calcula resultados em tempo real
  void _calculateResults() {
    // TODO: Implementar cálculos agronômicos em tempo real
    // - Germinação acumulada (%)
    // - Contaminação (%)
    // - Pureza fisiológica (%)
  }
  
  // === MÉTODOS DE AÇÃO ===
  
  void _selectRecordDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecione a data do registro',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    
    if (date != null) {
      setState(() {
        _recordDate = date;
      });
      
      // Mostrar feedback visual
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data alterada para: ${_formatDate(date)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final provider = Provider.of<GerminationTestProvider>(context, listen: false);
      
      final normalGerminated = int.tryParse(_normalGerminatedController.text) ?? 0;
      final diseased = int.tryParse(_diseasedController.text) ?? 0;
      final notGerminated = int.tryParse(_notGerminatedController.text) ?? 0;
      final observations = _observationsController.text.trim();
      
      if (widget.existingRecord != null) {
        // Atualizar registro existente
        final updatedRecord = widget.existingRecord!.copyWith(
          day: _currentDay,
          recordDate: _recordDate, // Usar a data selecionada pelo usuário
          normalGerminated: normalGerminated,
          diseasedFungi: diseased, // Simplificado - considera tudo como fungo
          diseasedBacteria: 0,
          notGerminated: notGerminated,
          observations: observations.isEmpty ? null : observations,
          updatedAt: DateTime.now(),
        );
        
        final success = await provider.updateDailyRecord(updatedRecord);
        
        if (!success) {
          throw Exception('Falha ao atualizar registro');
        }
        
        // Reordenar registros após atualização
        await provider.updateRecordsSequentialOrder(widget.test.id!);
      } else {
        // Criar novo registro usando o método que calcula automaticamente a ordenação
        final newRecord = await provider.addDailyRecord(
          testId: widget.test.id!,
          subtestId: widget.subtestName, // Passar o nome do subteste
          day: 0, // Será calculado automaticamente
          recordDate: _recordDate, // Usar a data selecionada pelo usuário
          normalGerminated: normalGerminated,
          abnormalGerminated: 0, // TODO: adicionar campo no formulário
          diseasedFungi: diseased,
          diseasedBacteria: 0,
          notGerminated: notGerminated,
          otherSeeds: 0,
          inertMatter: 0,
          observations: observations.isEmpty ? null : observations,
          photos: null,
        );
        
        if (newRecord == null) {
          throw Exception('Falha ao criar registro');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRecord != null 
                ? 'Registro atualizado com sucesso!' 
                : 'Registro salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      print('❌ Erro ao salvar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  // === MÉTODOS AUXILIARES ===
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
}