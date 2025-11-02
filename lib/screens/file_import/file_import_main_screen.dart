import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/geojson_reader_service.dart';
import '../../services/geojson_integration_service.dart';
import '../../services/import_history_service.dart';
import '../../models/talhao_model.dart';
import '../../utils/logger.dart';
import 'widgets/file_import_card.dart';
import 'widgets/import_progress_dialog.dart';
import 'widgets/import_result_viewer.dart';

/// Tela principal do módulo de importação de arquivos
class FileImportMainScreen extends StatefulWidget {
  const FileImportMainScreen({Key? key}) : super(key: key);

  @override
  State<FileImportMainScreen> createState() => _FileImportMainScreenState();
}

class _FileImportMainScreenState extends State<FileImportMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<ImportResult> _importResults = [];
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadImportHistory();
  }

  /// Carrega histórico de importações
  Future<void> _loadImportHistory() async {
    try {
      final history = await ImportHistoryService.loadImportHistory();
      setState(() {
        _importResults = history;
      });
      Logger.info('📖 [FILE_IMPORT] Histórico carregado: ${history.length} itens');
    } catch (e) {
      Logger.error('❌ [FILE_IMPORT] Erro ao carregar histórico: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Importação de Arquivos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.file_upload),
              text: 'Importar',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Histórico',
            ),
            Tab(
              icon: Icon(Icons.help),
              text: 'Ajuda',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImportTab(),
          _buildHistoryTab(),
          _buildHelpTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilePicker,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Importar Arquivo',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  /// Tab de importação
  Widget _buildImportTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildSupportedFormatsCard(),
            const SizedBox(height: 24),
            _buildQuickActionsCard(),
            const SizedBox(height: 24),
            if (_importResults.isNotEmpty) ...[
              _buildRecentImportsCard(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  /// Tab de histórico
  Widget _buildHistoryTab() {
    return Container(
      color: Colors.white,
      child: _importResults.isEmpty
          ? _buildEmptyHistory()
          : Column(
              children: [
                // Cabeçalho com ações
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_importResults.length} importações',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _clearHistory,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Limpar Tudo'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de histórico
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _importResults.length,
                    itemBuilder: (context, index) {
                      final result = _importResults[index];
                      return _buildHistoryItem(result, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// Tab de ajuda
  Widget _buildHelpTab() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpCard(
              'Formatos Suportados',
              'O sistema suporta os seguintes formatos de arquivo:',
              [
                '• GeoJSON (.geojson) - Dados geográficos padrão',
                '• JSON (.json) - Arquivos JSON com estrutura GeoJSON',
                '• Arquivos de texto com dados GeoJSON válidos',
              ],
              Icons.description,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              'Tipos de Dados Suportados',
              'O sistema detecta automaticamente o tipo de dados:',
              [
                '• Talhões agrícolas (com campos: nome, área, cultura)',
                '• Trabalhos de máquina (com campos: máquina, dose, aplicação)',
                '• Áreas de plantio (com campos: variedade, data, semente)',
                '• Dados de colheita (com campos: produção, rendimento)',
                '• Amostras de solo (com campos: pH, nutrientes, análise)',
                '• Sistemas de irrigação (com campos: tipo, vazão, área)',
              ],
              Icons.agriculture,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              'Dicas de Importação',
              'Para melhores resultados:',
              [
                '• Use coordenadas em WGS84 (EPSG:4326)',
                '• Inclua propriedades relevantes (nome, área, tipo)',
                '• Verifique a estrutura GeoJSON válida',
                '• Use nomes únicos para cada feature',
                '• Inclua metadados como fazenda_id quando possível',
              ],
              Icons.lightbulb,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  /// Card de boas-vindas
  Widget _buildWelcomeCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade400,
              Colors.green.shade600,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.file_upload,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Importe seus Dados',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Traga seus talhões, trabalhos e dados para o FortSmart',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showFilePicker,
              icon: const Icon(Icons.add),
              label: const Text('Começar Importação'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card de formatos suportados
  Widget _buildSupportedFormatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                const Text(
                  'Formatos Suportados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildFormatChip('GeoJSON', '.geojson', Colors.blue),
                _buildFormatChip('JSON', '.json', Colors.green),
                _buildFormatChip('Texto', '.txt', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card de ações rápidas
  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                const Text(
                  'Ações Rápidas',
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
                  child: _buildQuickActionButton(
                    'Importar Talhões',
                    Icons.agriculture,
                    Colors.green,
                    () => _importSpecificType('talhoes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Importar Máquinas',
                    Icons.agriculture,
                    Colors.blue,
                    () => _importSpecificType('maquinas'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Importar Plantio',
                    Icons.eco,
                    Colors.orange,
                    () => _importSpecificType('plantio'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Importar Solo',
                    Icons.terrain,
                    Colors.brown,
                    () => _importSpecificType('solo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card de importações recentes
  Widget _buildRecentImportsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.purple.shade600),
                const SizedBox(width: 12),
                const Text(
                  'Importações Recentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._importResults.take(3).map((result) => _buildRecentImportItem(result)),
          ],
        ),
      ),
    );
  }

  /// Histórico vazio
  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma importação realizada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Importe seus primeiros arquivos para começar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Item do histórico
  Widget _buildHistoryItem(ImportResult result, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(result.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(result.status),
            color: _getStatusColor(result.status),
          ),
        ),
        title: Text(
          result.fileName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.itemCount} itens importados'),
            Text(
              _formatDate(result.importDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleHistoryAction(value, result),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Visualizar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remover'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _viewImportResult(result),
      ),
    );
  }

  /// Card de ajuda
  Widget _buildHelpCard(
    String title,
    String description,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Chip de formato
  Widget _buildFormatChip(String name, String extension, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            extension,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Botão de ação rápida
  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  /// Item de importação recente
  Widget _buildRecentImportItem(ImportResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getStatusColor(result.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getStatusIcon(result.status),
              color: _getStatusColor(result.status),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${result.itemCount} itens • ${_formatDate(result.importDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility, size: 16),
            onPressed: () => _viewImportResult(result),
          ),
        ],
      ),
    );
  }

  /// Mostra seletor de arquivos
  Future<void> _showFilePicker() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['geojson', 'json', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        await _importFile(file);
      }
    } catch (e) {
      Logger.error('FileImportMainScreen: Erro ao selecionar arquivo: $e');
      _showErrorSnackBar('Erro ao selecionar arquivo: $e');
    }
  }

  /// Importa arquivo específico
  Future<void> _importFile(File file) async {
    setState(() {
      _isImporting = true;
    });

    try {
      // Mostrar diálogo de progresso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ImportProgressDialog(
          fileName: file.path.split('/').last,
        ),
      );

      Logger.info('🔄 [FILE_IMPORT] Iniciando importação do arquivo: ${file.path}');

      // Integrar arquivo GeoJSON
      final integrationResult = await GeoJSONIntegrationService.integrateGeoJSONFile(file);
      
      Logger.info('✅ [FILE_IMPORT] Integração concluída: ${integrationResult.success}');

      // Criar resultado de importação
      final result = ImportResult(
        fileName: file.path.split('/').last,
        filePath: file.path,
        itemCount: integrationResult.importedItems,
        status: integrationResult.success ? ImportStatus.success : ImportStatus.error,
        importDate: DateTime.now(),
        data: integrationResult.data?.toJson() ?? {},
        errors: integrationResult.errors,
        statistics: integrationResult.statistics,
      );

      setState(() {
        _importResults.insert(0, result);
      });

      // Salvar no histórico
      await ImportHistoryService.saveImportResult(result);

      // Fechar diálogo de progresso
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar resultado
      if (mounted) {
        if (integrationResult.success) {
          _showSuccessSnackBar(integrationResult.message);
          _viewImportResult(result);
        } else {
          _showErrorSnackBar(integrationResult.message);
        }
      }

    } catch (e) {
      Logger.error('FileImportMainScreen: Erro na importação: $e');
      
      // Fechar diálogo de progresso
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      _showErrorSnackBar('Erro na importação: $e');
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  /// Importa tipo específico
  Future<void> _importSpecificType(String type) async {
    try {
      // Mostrar seletor de arquivos específico para o tipo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['geojson', 'json', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        
        // Mostrar diálogo de confirmação com informações do tipo
        final confirmed = await _showTypeConfirmationDialog(type, file.path.split('/').last);
        
        if (confirmed) {
          await _importFileWithType(file, type);
        }
      }
    } catch (e) {
      Logger.error('FileImportMainScreen: Erro ao importar tipo específico $type: $e');
      _showErrorSnackBar('Erro ao importar $type: $e');
    }
  }

  /// Mostra diálogo de confirmação para importação por tipo
  Future<bool> _showTypeConfirmationDialog(String type, String fileName) async {
    final typeInfo = _getTypeInfo(type);
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(typeInfo['icon'], color: typeInfo['color']),
            const SizedBox(width: 8),
            Text('Importar ${typeInfo['name']}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Arquivo: $fileName'),
            const SizedBox(height: 8),
            Text('Tipo: ${typeInfo['name']}'),
            const SizedBox(height: 8),
            Text('Descrição: ${typeInfo['description']}'),
            const SizedBox(height: 8),
            Text('Campos esperados: ${typeInfo['expectedFields']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: typeInfo['color'],
              foregroundColor: Colors.white,
            ),
            child: const Text('Importar'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Importa arquivo com tipo específico
  Future<void> _importFileWithType(File file, String type) async {
    setState(() {
      _isImporting = true;
    });

    try {
      // Mostrar diálogo de progresso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ImportProgressDialog(
          fileName: file.path.split('/').last,
          type: type,
        ),
      );

      Logger.info('🔄 [FILE_IMPORT] Iniciando importação de $type: ${file.path}');

      // Integrar arquivo GeoJSON
      final integrationResult = await GeoJSONIntegrationService.integrateGeoJSONFile(file);
      
      Logger.info('✅ [FILE_IMPORT] Integração de $type concluída: ${integrationResult.success}');

      // Criar resultado de importação
      final result = ImportResult(
        fileName: file.path.split('/').last,
        filePath: file.path,
        itemCount: integrationResult.importedItems,
        status: integrationResult.success ? ImportStatus.success : ImportStatus.error,
        importDate: DateTime.now(),
        data: integrationResult.data?.toJson() ?? {},
        errors: integrationResult.errors,
        statistics: integrationResult.statistics,
        importType: type,
      );

      setState(() {
        _importResults.insert(0, result);
      });

      // Salvar no histórico
      await ImportHistoryService.saveImportResult(result);

      // Fechar diálogo de progresso
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar resultado
      if (mounted) {
        if (integrationResult.success) {
          _showSuccessSnackBar('${integrationResult.message} (Tipo: $type)');
          _viewImportResult(result);
        } else {
          _showErrorSnackBar('Erro na importação de $type: ${integrationResult.message}');
        }
      }

    } catch (e) {
      Logger.error('FileImportMainScreen: Erro na importação de $type: $e');
      
      // Fechar diálogo de progresso
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      _showErrorSnackBar('Erro na importação de $type: $e');
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  /// Obtém informações do tipo de dados
  Map<String, dynamic> _getTypeInfo(String type) {
    switch (type) {
      case 'talhoes':
        return {
          'name': 'Talhões',
          'icon': Icons.agriculture,
          'color': Colors.green,
          'description': 'Dados de talhões agrícolas com polígonos e propriedades',
          'expectedFields': 'nome, área, cultura_id, fazenda_id',
        };
      case 'maquinas':
        return {
          'name': 'Trabalhos de Máquina',
          'icon': Icons.agriculture,
          'color': Colors.blue,
          'description': 'Dados de trabalhos realizados por máquinas agrícolas',
          'expectedFields': 'máquina, dose, aplicação, velocidade, data',
        };
      case 'plantio':
        return {
          'name': 'Dados de Plantio',
          'icon': Icons.eco,
          'color': Colors.orange,
          'description': 'Informações sobre plantio e sementes',
          'expectedFields': 'variedade, semente, data_plantio, densidade',
        };
      case 'solo':
        return {
          'name': 'Amostras de Solo',
          'icon': Icons.terrain,
          'color': Colors.brown,
          'description': 'Análises e amostras de solo',
          'expectedFields': 'pH, nutrientes, matéria_orgânica, textura',
        };
      default:
        return {
          'name': 'Dados Genéricos',
          'icon': Icons.help,
          'color': Colors.grey,
          'description': 'Dados geoespaciais genéricos',
          'expectedFields': 'coordenadas, propriedades personalizadas',
        };
    }
  }

  /// Visualiza resultado da importação
  void _viewImportResult(ImportResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImportResultViewer(result: result),
      ),
    );
  }

  /// Manipula ações do histórico
  Future<void> _handleHistoryAction(String action, ImportResult result) async {
    switch (action) {
      case 'view':
        _viewImportResult(result);
        break;
      case 'remove':
        await _removeFromHistory(result);
        break;
    }
  }

  /// Limpa todo o histórico
  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Histórico'),
        content: const Text('Deseja remover todas as importações do histórico? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar Tudo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ImportHistoryService.clearHistory();
        setState(() {
          _importResults.clear();
        });
        _showSuccessSnackBar('Histórico limpo com sucesso');
      } catch (e) {
        _showErrorSnackBar('Erro ao limpar histórico: $e');
      }
    }
  }

  /// Remove item do histórico
  Future<void> _removeFromHistory(ImportResult result) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover do Histórico'),
        content: Text('Deseja remover "${result.fileName}" do histórico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ImportHistoryService.removeImportResult(result.fileName);
        setState(() {
          _importResults.removeWhere((r) => r.fileName == result.fileName);
        });
        _showSuccessSnackBar('Item removido do histórico');
      } catch (e) {
        _showErrorSnackBar('Erro ao remover do histórico: $e');
      }
    }
  }

  /// Métodos auxiliares
  Color _getStatusColor(ImportStatus status) {
    switch (status) {
      case ImportStatus.success:
        return Colors.green;
      case ImportStatus.error:
        return Colors.red;
      case ImportStatus.warning:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(ImportStatus status) {
    switch (status) {
      case ImportStatus.success:
        return Icons.check_circle;
      case ImportStatus.error:
        return Icons.error;
      case ImportStatus.warning:
        return Icons.warning;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Status da importação
enum ImportStatus { success, error, warning }

/// Resultado da importação
class ImportResult {
  final String fileName;
  final String filePath;
  final int itemCount;
  final ImportStatus status;
  final DateTime importDate;
  final Map<String, dynamic> data;
  final List<String> errors;
  final Map<String, dynamic>? statistics;
  final String? importType;

  ImportResult({
    required this.fileName,
    required this.filePath,
    required this.itemCount,
    required this.status,
    required this.importDate,
    required this.data,
    this.errors = const [],
    this.statistics,
    this.importType,
  });
}
