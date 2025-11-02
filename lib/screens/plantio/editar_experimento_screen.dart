import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/experimento_completo_model.dart';
import '../../services/experimento_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../utils/snackbar_utils.dart';

/// Tela para editar experimento
class EditarExperimentoScreen extends StatefulWidget {
  final ExperimentoCompleto experimento;

  const EditarExperimentoScreen({
    Key? key,
    required this.experimento,
  }) : super(key: key);

  @override
  State<EditarExperimentoScreen> createState() => _EditarExperimentoScreenState();
}

class _EditarExperimentoScreenState extends State<EditarExperimentoScreen> {
  final ExperimentoService _experimentoService = ExperimentoService();
  final _formKey = GlobalKey<FormState>();
  
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _objetivoController = TextEditingController();

  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime.now().add(const Duration(days: 90));
  ExperimentoStatus _status = ExperimentoStatus.ativo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

  void _carregarDados() {
    _nomeController.text = widget.experimento.nome;
    _descricaoController.text = widget.experimento.descricao ?? '';
    _objetivoController.text = widget.experimento.objetivo ?? '';
    _dataInicio = widget.experimento.dataInicio;
    _dataFim = widget.experimento.dataFim;
    _status = widget.experimento.status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBarWidget(
        title: 'Editar Experimento',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _salvarAlteracoes,
            child: const Text(
              'Salvar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de Informações Básicas
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Informações Básicas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Nome do Experimento
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Experimento *',
                          hintText: 'Ex: Experimento Soja 2024',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nome é obrigatório';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Status
                      DropdownButtonFormField<ExperimentoStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status *',
                          border: OutlineInputBorder(),
                        ),
                        items: ExperimentoStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_getStatusText(status)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Card de Datas
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Período do Experimento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: Icon(Icons.play_circle, color: Colors.green[700]),
                              title: const Text('Data de Início'),
                              subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataInicio)),
                              onTap: _selecionarDataInicio,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ListTile(
                              leading: Icon(Icons.stop_circle, color: Colors.red[700]),
                              title: const Text('Data de Fim'),
                              subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataFim)),
                              onTap: _selecionarDataFim,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Informação sobre duração
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Duração: ${_dataFim.difference(_dataInicio).inDays} dias',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Card de Descrições
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, color: Colors.purple[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Descrições',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Descrição
                      TextFormField(
                        controller: _descricaoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          hintText: 'Descreva o experimento...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Objetivo
                      TextFormField(
                        controller: _objetivoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Objetivo',
                          hintText: 'Qual é o objetivo do experimento?',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Card de Resumo
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.summarize, color: Colors.teal[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Resumo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildResumoItem(
                              'Talhão',
                              widget.experimento.talhaoNome,
                              Icons.landscape,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildResumoItem(
                              'Subáreas',
                              '${widget.experimento.subareas.length}/6',
                              Icons.grid_view,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildResumoItem(
                              'Status',
                              _getStatusText(_status),
                              Icons.flag,
                              _getStatusColor(_status),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildResumoItem(
                              'Duração',
                              '${_dataFim.difference(_dataInicio).inDays} dias',
                              Icons.schedule,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _salvarAlteracoes,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: Text(_isLoading ? 'Salvando...' : 'Salvar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ExperimentoStatus status) {
    switch (status) {
      case ExperimentoStatus.ativo:
        return Colors.green;
      case ExperimentoStatus.concluido:
        return Colors.blue;
      case ExperimentoStatus.pendente:
        return Colors.orange;
      case ExperimentoStatus.cancelado:
        return Colors.red;
    }
  }

  String _getStatusText(ExperimentoStatus status) {
    switch (status) {
      case ExperimentoStatus.ativo:
        return 'Ativo';
      case ExperimentoStatus.concluido:
        return 'Concluído';
      case ExperimentoStatus.pendente:
        return 'Pendente';
      case ExperimentoStatus.cancelado:
        return 'Cancelado';
    }
  }

  Future<void> _selecionarDataInicio() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (result != null) {
      setState(() {
        _dataInicio = result;
        // Ajustar data fim se necessário
        if (_dataFim.isBefore(_dataInicio)) {
          _dataFim = _dataInicio.add(const Duration(days: 90));
        }
      });
    }
  }

  Future<void> _selecionarDataFim() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _dataFim,
      firstDate: _dataInicio,
      lastDate: DateTime(2030),
    );

    if (result != null) {
      setState(() {
        _dataFim = result;
      });
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final experimentoAtualizado = widget.experimento.copyWith(
        nome: _nomeController.text.trim(),
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        status: _status,
        descricao: _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
        objetivo: _objetivoController.text.trim().isEmpty ? null : _objetivoController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _experimentoService.atualizarExperimento(experimentoAtualizado);

      SnackbarUtils.showSuccessSnackBar(context, 'Experimento atualizado com sucesso!');
      Navigator.of(context).pop(true);
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao atualizar experimento: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
