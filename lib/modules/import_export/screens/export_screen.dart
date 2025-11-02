import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../models/export_job_model.dart';
import '../services/import_export_service.dart';
import '../../../utils/logger.dart';
import '../../../constants/app_colors.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({Key? key}) : super(key: key);

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ImportExportService _service = ImportExportService();
  
  // Controllers
  final _formKey = GlobalKey<FormState>();
  
  // Estado
  String _tipoSelecionado = 'custos';
  String _formatoSelecionado = 'xlsx';
  DateTime? _dataInicio;
  DateTime? _dataFim;
  String? _talhaoSelecionado;
  String? _culturaSelecionada;
  String? _tipoOperacaoSelecionada;
  
  // Filtros disponíveis
  final List<String> _tipos = ['custos', 'prescricoes', 'talhoes'];
  final List<String> _formatos = ['xlsx', 'csv', 'json'];
  final List<String> _tiposOperacao = ['plantio', 'aplicacao', 'colheita', 'monitoramento'];
  
  // Estado de carregamento
  bool _isLoading = false;
  bool _isExporting = false;
  List<ExportJobModel> _jobsRecentes = [];
  
  @override
  void initState() {
    super.initState();
    _carregarJobsRecentes();
  }

  Future<void> _carregarJobsRecentes() async {
    try {
      final jobs = await _service.getExportJobs(status: 'concluido');
      setState(() {
        _jobsRecentes = jobs.take(5).toList();
      });
    } catch (e) {
      Logger.error('Erro ao carregar jobs recentes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Dados'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildExportForm(),
                  const SizedBox(height: 24),
                  _buildRecentExports(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.file_download,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exportar Dados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Exporte seus dados em diferentes formatos para análise externa ou backup',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuração da Exportação',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          
          // Tipo de dados
          _buildDropdownField(
            label: 'Tipo de Dados',
            value: _tipoSelecionado,
            items: _tipos.map((tipo) => DropdownMenuItem(
              value: tipo,
              child: Text(_getTipoDisplayName(tipo)),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _tipoSelecionado = value!;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Formato
          _buildDropdownField(
            label: 'Formato do Arquivo',
            value: _formatoSelecionado,
            items: _formatos.map((formato) => DropdownMenuItem(
              value: formato,
              child: Text(formato.toUpperCase()),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _formatoSelecionado = value!;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Filtros
          Text(
            'Filtros (Opcional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          
          // Período
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Data Início',
                  value: _dataInicio,
                  onChanged: (date) {
                    setState(() {
                      _dataInicio = date;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  label: 'Data Fim',
                  value: _dataFim,
                  onChanged: (date) {
                    setState(() {
                      _dataFim = date;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Talhão
          _buildDropdownField(
            label: 'Talhão (Opcional)',
            value: _talhaoSelecionado,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Todos os talhões'),
              ),
              // TODO: Carregar talhões do banco
              const DropdownMenuItem<String>(
                value: 'talhao_1',
                child: Text('Talhão 1'),
              ),
              const DropdownMenuItem<String>(
                value: 'talhao_2',
                child: Text('Talhão 2'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _talhaoSelecionado = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Cultura
          _buildDropdownField(
            label: 'Cultura (Opcional)',
            value: _culturaSelecionada,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Todas as culturas'),
              ),
              // TODO: Carregar culturas do banco
              const DropdownMenuItem<String>(
                value: 'soja',
                child: Text('Soja'),
              ),
              const DropdownMenuItem<String>(
                value: 'milho',
                child: Text('Milho'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _culturaSelecionada = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Tipo de operação
          _buildDropdownField(
            label: 'Tipo de Operação (Opcional)',
            value: _tipoOperacaoSelecionada,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Todas as operações'),
              ),
              ..._tiposOperacao.map((tipo) => DropdownMenuItem(
                value: tipo,
                child: Text(_getTipoOperacaoDisplayName(tipo)),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _tipoOperacaoSelecionada = value;
              });
            },
          ),
          
          const SizedBox(height: 32),
          
          // Botões de ação
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
                      : 'Selecionar data',
                  style: TextStyle(
                    color: value != null ? Colors.black : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportarDados,
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download),
            label: Text(_isExporting ? 'Exportando...' : 'Exportar Dados'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isExporting ? null : _limparFiltros,
            icon: const Icon(Icons.clear),
            label: const Text('Limpar Filtros'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentExports() {
    if (_jobsRecentes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exportações Recentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _jobsRecentes.length,
          itemBuilder: (context, index) {
            final job = _jobsRecentes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getStatusIcon(job.status),
                  color: _getStatusColor(job.status),
                ),
                title: Text('${_getTipoDisplayName(job.tipo)} (${job.formato.toUpperCase()})'),
                subtitle: Text(
                  '${job.dataCriacao.day.toString().padLeft(2, '0')}/${job.dataCriacao.month.toString().padLeft(2, '0')}/${job.dataCriacao.year} - ${job.status}',
                ),
                trailing: job.arquivoPath != null
                    ? IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _compartilharArquivo(job.arquivoPath!),
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  // Métodos auxiliares

  String _getTipoDisplayName(String tipo) {
    switch (tipo) {
      case 'custos':
        return 'Histórico de Custos';
      case 'prescricoes':
        return 'Prescrições';
      case 'talhoes':
        return 'Talhões';
      default:
        return tipo;
    }
  }

  String _getTipoOperacaoDisplayName(String tipo) {
    switch (tipo) {
      case 'plantio':
        return 'Plantio';
      case 'aplicacao':
        return 'Aplicação';
      case 'colheita':
        return 'Colheita';
      case 'monitoramento':
        return 'Monitoramento';
      default:
        return tipo;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'concluido':
        return Icons.check_circle;
      case 'pendente':
        return Icons.schedule;
      case 'erro':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'concluido':
        return Colors.green;
      case 'pendente':
        return Colors.orange;
      case 'erro':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Ações

  Future<void> _exportarDados() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final filtros = <String, dynamic>{};
      
      if (_dataInicio != null) filtros['data_inicio'] = _dataInicio!.toIso8601String();
      if (_dataFim != null) filtros['data_fim'] = _dataFim!.toIso8601String();
      if (_talhaoSelecionado != null) filtros['talhao_id'] = _talhaoSelecionado;
      if (_culturaSelecionada != null) filtros['cultura'] = _culturaSelecionada;
      if (_tipoOperacaoSelecionada != null) filtros['tipo_operacao'] = _tipoOperacaoSelecionada;

      final resultado = await _service.exportarDados(
        tipo: _tipoSelecionado,
        formato: _formatoSelecionado,
        filtros: filtros,
      );

      if (resultado['sucesso']) {
        if (resultado['arquivo_path'] != null) {
          await _compartilharArquivo(resultado['arquivo_path']);
        } else {
          _mostrarMensagem('Exportação concluída', 'Nenhum dado encontrado para os filtros aplicados');
        }
        await _carregarJobsRecentes();
      } else {
        _mostrarMensagem('Erro na exportação', resultado['erro'] ?? 'Erro desconhecido');
      }
    } catch (e) {
      Logger.error('Erro ao exportar dados: $e');
      _mostrarMensagem('Erro', 'Erro ao processar exportação: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _compartilharArquivo(String arquivoPath) async {
    try {
      final file = File(arquivoPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(arquivoPath)],
          text: 'Dados exportados do FortSmart Agro',
        );
      } else {
        _mostrarMensagem('Erro', 'Arquivo não encontrado');
      }
    } catch (e) {
      Logger.error('Erro ao compartilhar arquivo: $e');
      _mostrarMensagem('Erro', 'Erro ao compartilhar arquivo: $e');
    }
  }

  void _limparFiltros() {
    setState(() {
      _dataInicio = null;
      _dataFim = null;
      _talhaoSelecionado = null;
      _culturaSelecionada = null;
      _tipoOperacaoSelecionada = null;
    });
  }

  void _mostrarMensagem(String titulo, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$titulo: $mensagem'),
        backgroundColor: titulo == 'Erro' ? Colors.red : Colors.green,
      ),
    );
  }
}
