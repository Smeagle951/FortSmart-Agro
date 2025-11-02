import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../models/import_job_model.dart';
import '../services/import_export_service.dart';
import '../../../utils/logger.dart';
import '../../../constants/app_colors.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({Key? key}) : super(key: key);

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final ImportExportService _service = ImportExportService();
  
  // Controllers
  final _formKey = GlobalKey<FormState>();
  
  // Estado
  String _tipoSelecionado = 'prescricoes';
  PlatformFile? _arquivoSelecionado;
  List<Map<String, dynamic>> _dadosPreview = [];
  bool _mostrarPreview = false;
  
  // Filtros disponíveis
  final List<String> _tipos = ['prescricoes', 'talhoes'];
  
  // Estado de carregamento
  bool _isLoading = false;
  bool _isImporting = false;
  List<ImportJobModel> _jobsRecentes = [];
  
  @override
  void initState() {
    super.initState();
    _carregarJobsRecentes();
  }

  Future<void> _carregarJobsRecentes() async {
    try {
      final jobs = await _service.getImportJobs(status: 'concluido');
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
        title: const Text('Importar Dados'),
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
                  _buildImportForm(),
                  const SizedBox(height: 24),
                  if (_mostrarPreview) _buildDataPreview(),
                  const SizedBox(height: 24),
                  _buildRecentImports(),
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
            Icons.file_upload,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Importar Dados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Importe dados de outros sistemas ou arquivos de backup',
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

  Widget _buildImportForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuração da Importação',
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
                _arquivoSelecionado = null;
                _dadosPreview = [];
                _mostrarPreview = false;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Seleção de arquivo
          _buildFileSelection(),
          
          const SizedBox(height: 24),
          
          // Informações do arquivo
          if (_arquivoSelecionado != null) _buildFileInfo(),
          
          const SizedBox(height: 32),
          
          // Botões de ação
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
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

  Widget _buildFileSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecionar Arquivo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selecionarArquivo,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: _arquivoSelecionado != null ? Colors.green : Colors.grey[400]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: _arquivoSelecionado != null 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey[50],
            ),
            child: Column(
              children: [
                Icon(
                  _arquivoSelecionado != null ? Icons.check_circle : Icons.cloud_upload,
                  size: 48,
                  color: _arquivoSelecionado != null ? Colors.green : Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  _arquivoSelecionado != null 
                      ? 'Arquivo selecionado'
                      : 'Clique para selecionar arquivo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _arquivoSelecionado != null ? Colors.green : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Formatos suportados: CSV, XLSX, JSON',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileInfo() {
    if (_arquivoSelecionado == null) return const SizedBox.shrink();

    final sizeInMB = _arquivoSelecionado!.size / (1024 * 1024);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Informações do Arquivo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Nome', _arquivoSelecionado!.name),
          _buildInfoRow('Tamanho', '${sizeInMB.toStringAsFixed(2)} MB'),
          _buildInfoRow('Extensão', _arquivoSelecionado!.extension ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _arquivoSelecionado == null || _isImporting ? null : _previewDados,
            icon: const Icon(Icons.preview),
            label: const Text('Pré-visualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
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
          child: ElevatedButton.icon(
            onPressed: _arquivoSelecionado == null || _isImporting ? null : _importarDados,
            icon: _isImporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.file_upload),
            label: Text(_isImporting ? 'Importando...' : 'Importar Dados'),
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
      ],
    );
  }

  Widget _buildDataPreview() {
    if (_dadosPreview.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Nenhum dado para pré-visualizar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.table_chart, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(
              'Pré-visualização dos Dados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
            const Spacer(),
            Text(
              '${_dadosPreview.length} registros',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: _dadosPreview.isNotEmpty
                  ? _dadosPreview.first.keys.map((key) => DataColumn(label: Text(key))).toList()
                  : [],
              rows: _dadosPreview.take(10).map((row) {
                return DataRow(
                  cells: row.values.map((value) => DataCell(Text(value?.toString() ?? ''))).toList(),
                );
              }).toList(),
            ),
          ),
        ),
        if (_dadosPreview.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Mostrando os primeiros 10 registros de ${_dadosPreview.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentImports() {
    if (_jobsRecentes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Importações Recentes',
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
                title: Text('${_getTipoDisplayName(job.tipo)} - ${job.nomeArquivoOriginal ?? 'Arquivo'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${job.dataCriacao.day.toString().padLeft(2, '0')}/${job.dataCriacao.month.toString().padLeft(2, '0')}/${job.dataCriacao.year} - ${job.status}',
                    ),
                    if (job.totalRegistros != null)
                      Text(
                        '${job.registrosSucesso ?? 0}/${job.totalRegistros} registros importados',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                trailing: job.registrosErro != null && job.registrosErro! > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${job.registrosErro} erros',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
      case 'prescricoes':
        return 'Prescrições';
      case 'talhoes':
        return 'Talhões';
      default:
        return tipo;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'concluido':
        return Icons.check_circle;
      case 'validado':
        return Icons.verified;
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
      case 'validado':
        return Colors.blue;
      case 'pendente':
        return Colors.orange;
      case 'erro':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Ações

  Future<void> _selecionarArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _arquivoSelecionado = result.files.first;
          _dadosPreview = [];
          _mostrarPreview = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao selecionar arquivo: $e');
      _mostrarMensagem('Erro', 'Erro ao selecionar arquivo: $e');
    }
  }

  Future<void> _previewDados() async {
    if (_arquivoSelecionado == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('Iniciando preview do arquivo: ${_arquivoSelecionado!.name}');
      
      // Verificar se o arquivo tem path
      if (_arquivoSelecionado!.path == null) {
        throw Exception('Arquivo não possui caminho válido');
      }
      
      // Ler arquivo usando o serviço
      final dados = await _service.lerArquivo(_arquivoSelecionado!.path!);
      
      setState(() {
        _dadosPreview = dados.take(10).toList(); // Mostrar apenas os primeiros 10 registros
        _mostrarPreview = true;
      });
      
      Logger.info('Preview concluído: ${_dadosPreview.length} registros');
    } catch (e) {
      Logger.error('Erro ao fazer preview dos dados: $e');
      _mostrarMensagem('Erro', 'Erro ao fazer preview dos dados: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importarDados() async {
    if (_arquivoSelecionado == null) return;

    setState(() {
      _isImporting = true;
    });

    try {
      // Verificar se o arquivo tem path
      if (_arquivoSelecionado!.path == null) {
        throw Exception('Arquivo não possui caminho válido');
      }
      
      Logger.info('Iniciando importação do arquivo: ${_arquivoSelecionado!.name}');
      
      final resultado = await _service.importarDados(
        tipo: _tipoSelecionado,
        arquivoPath: _arquivoSelecionado!.path!,
        nomeArquivoOriginal: _arquivoSelecionado!.name,
        tamanhoArquivo: _arquivoSelecionado!.size / (1024 * 1024),
      );

      if (resultado['sucesso']) {
        _mostrarMensagem(
          'Importação concluída',
          '${resultado['registros_sucesso']} registros importados com sucesso',
        );
        
        // Limpar formulário
        setState(() {
          _arquivoSelecionado = null;
          _dadosPreview = [];
          _mostrarPreview = false;
        });
        
        await _carregarJobsRecentes();
      } else {
        final erros = resultado['erros'] as List<Map<String, dynamic>>?;
        final mensagemErro = erros?.isNotEmpty == true
            ? '${erros!.length} erros encontrados. Verifique os dados.'
            : resultado['erro'] ?? 'Erro desconhecido';
        
        _mostrarMensagem('Erro na importação', mensagemErro);
      }
    } catch (e) {
      Logger.error('Erro ao importar dados: $e');
      _mostrarMensagem('Erro', 'Erro ao processar importação: $e');
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
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
