import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../services/export_service.dart';
import '../../utils/app_theme.dart';

/// Tela para gerenciar exportações de relatórios
class ExportManagerScreen extends StatefulWidget {
  static const String routeName = '/reports/export-manager';

  const ExportManagerScreen({Key? key}) : super(key: key);

  @override
  _ExportManagerScreenState createState() => _ExportManagerScreenState();
}

class _ExportManagerScreenState extends State<ExportManagerScreen> {
  final ExportService _exportService = ExportService();
  
  List<Map<String, dynamic>> _exportedFiles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ExportFormat? _filterFormat;

  @override
  void initState() {
    super.initState();
    _loadExportedFiles();
  }

  Future<void> _loadExportedFiles() async {
    setState(() => _isLoading = true);
    
    try {
      final files = await _exportService.listExportedFiles();
      setState(() => _exportedFiles = files);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar arquivos: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciador de Exportações'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExportedFiles,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildFilters(),
                _buildStats(),
                Expanded(child: _buildFilesList()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColorLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Arquivos Exportados',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_exportedFiles.length} arquivo(s) encontrado(s)',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar arquivos...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<ExportFormat?>(
                value: _filterFormat,
                hint: const Text('Formato'),
                items: [
                  const DropdownMenuItem<ExportFormat?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  ...ExportFormat.values.map((format) => DropdownMenuItem(
                    value: format,
                    child: Text(format.name.toUpperCase()),
                  )),
                ],
                onChanged: (value) => setState(() => _filterFormat = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final filteredFiles = _getFilteredFiles();
    final totalSize = filteredFiles.fold<int>(0, (sum, file) => sum + (file['size'] as int));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard('Arquivos', filteredFiles.length.toString(), Icons.description),
          const SizedBox(width: 16),
          _buildStatCard('Tamanho Total', _formatFileSize(totalSize), Icons.storage),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    final filteredFiles = _getFilteredFiles();
    
    if (filteredFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum arquivo encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Exporte relatórios para ver os arquivos aqui',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredFiles.length,
      itemBuilder: (context, index) {
        final file = filteredFiles[index];
        return _buildFileCard(file);
      },
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file) {
    final fileName = file['name'] as String;
    final fileSize = file['size'] as int;
    final modified = file['modified'] as DateTime;
    final format = _getFileFormat(fileName);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getFormatIcon(format),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tamanho: ${_formatFileSize(fileSize)}'),
            Text('Modificado: ${DateFormat('dd/MM/yyyy HH:mm').format(modified)}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleFileAction(action, file),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Compartilhar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('Informações'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Excluir', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showFileInfo(file),
      ),
    );
  }

  Icon _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case ExportFormat.excel:
        return const Icon(Icons.table_chart, color: Colors.green);
      case ExportFormat.csv:
        return const Icon(Icons.table_view, color: Colors.blue);
      case ExportFormat.json:
        return const Icon(Icons.code, color: Colors.orange);
    }
  }

  ExportFormat _getFileFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return ExportFormat.pdf;
      case 'csv':
        return ExportFormat.csv;
      case 'json':
        return ExportFormat.json;
      default:
        return ExportFormat.csv;
    }
  }

  List<Map<String, dynamic>> _getFilteredFiles() {
    var filtered = _exportedFiles;
    
    // Filtro por busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((file) {
        final name = file['name'] as String;
        return name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Filtro por formato
    if (_filterFormat != null) {
      filtered = filtered.where((file) {
        final name = file['name'] as String;
        final format = _getFileFormat(name);
        return format == _filterFormat;
      }).toList();
    }
    
    return filtered;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleFileAction(String action, Map<String, dynamic> file) async {
    final filePath = file['path'] as String;
    
    switch (action) {
      case 'share':
        try {
          await _exportService.shareFile(filePath);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao compartilhar: $e')),
          );
        }
        break;
        
      case 'info':
        _showFileInfo(file);
        break;
        
      case 'delete':
        _confirmDelete(file);
        break;
    }
  }

  void _showFileInfo(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações do Arquivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${file['name']}'),
            Text('Tamanho: ${_formatFileSize(file['size'])}'),
            Text('Modificado: ${DateFormat('dd/MM/yyyy HH:mm').format(file['modified'])}'),
            Text('Caminho: ${file['path']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o arquivo "${file['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteFile(file);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    try {
      final success = await _exportService.deleteFile(file['path']);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo excluído com sucesso')),
        );
        _loadExportedFiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir arquivo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir arquivo: $e')),
      );
    }
  }
}
