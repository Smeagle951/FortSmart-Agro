import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../services/image_integrity_service.dart';
import '../../services/image_repair_service.dart';
import '../../models/sync/sync_progress.dart';
import '../../utils/logger.dart';

/// Tela para monitorar e gerenciar a integridade das imagens
class ImageIntegrityDashboard extends StatefulWidget {
  const ImageIntegrityDashboard({Key? key}) : super(key: key);

  @override
  _ImageIntegrityDashboardState createState() => _ImageIntegrityDashboardState();
}

class _ImageIntegrityDashboardState extends State<ImageIntegrityDashboard> with SingleTickerProviderStateMixin {
  final ImageIntegrityService _imageIntegrityService = GetIt.instance<ImageIntegrityService>();
  final ImageRepairService _imageRepairService = GetIt.instance<ImageRepairService>();
  
  late TabController _tabController;
  
  bool _isLoading = false;
  bool _isRepairing = false;
  bool _isCleaningUp = false;
  
  Map<String, dynamic>? _imageReferencesReport;
  Map<String, dynamic>? _orphanedImagesReport;
  List<Map<String, dynamic>> _sampleIntegrityReports = [];
  
  String? _errorMessage;
  
  // Stream para acompanhar o progresso da verificação/reparo
  final _progressStreamController = StreamController<SyncProgress>.broadcast();
  Stream<SyncProgress> get progressStream => _progressStreamController.stream;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _progressStreamController.close();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    await _verifyImageReferences();
  }
  
  Future<void> _verifyImageReferences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      _progressStreamController.add(SyncProgress(
        entityType: 'image_references',
        status: 'running',
        message: 'Verificando referências a imagens...',
        progress: 0,
      ));
      
      final result = await _imageIntegrityService.verifyImageReferences();
      
      _progressStreamController.add(SyncProgress(
        entityType: 'image_references',
        status: 'completed',
        message: 'Verificação de referências concluída',
        progress: 100,
      ));
      
      setState(() {
        _imageReferencesReport = result;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao verificar referências de imagens: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      _progressStreamController.add(SyncProgress(
        entityType: 'image_references',
        status: 'error',
        message: 'Erro: $e',
        progress: 0,
      ));
    }
  }
  
  Future<void> _cleanupInvalidReferences() async {
    setState(() {
      _isCleaningUp = true;
      _errorMessage = null;
    });
    
    try {
      _progressStreamController.add(SyncProgress(
        entityType: 'cleanup_references',
        status: 'running',
        message: 'Limpando referências inválidas...',
        progress: 0,
      ));
      
      final result = await _imageIntegrityService.cleanupInvalidImageReferences();
      
      _progressStreamController.add(SyncProgress(
        entityType: 'cleanup_references',
        status: 'completed',
        message: 'Limpeza de referências concluída',
        progress: 100,
      ));
      
      // Atualizar relatório
      await _verifyImageReferences();
      
      setState(() {
        _isCleaningUp = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Limpeza concluída: ${result['cleanedCount']} referências removidas'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Logger.error('Erro ao limpar referências inválidas: $e');
      setState(() {
        _errorMessage = e.toString();
        _isCleaningUp = false;
      });
      
      _progressStreamController.add(SyncProgress(
        entityType: 'cleanup_references',
        status: 'error',
        message: 'Erro: $e',
        progress: 0,
      ));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    }
  }
  
  Future<void> _cleanupOrphanedImages() async {
    setState(() {
      _isCleaningUp = true;
      _errorMessage = null;
    });
    
    try {
      _progressStreamController.add(SyncProgress(
        entityType: 'cleanup_orphaned',
        status: 'running',
        message: 'Limpando imagens órfãs...',
        progress: 0,
      ));
      
      final result = await _imageIntegrityService.cleanupOrphanedImages();
      
      _progressStreamController.add(SyncProgress(
        entityType: 'cleanup_orphaned',
        status: 'completed',
        message: 'Limpeza de imagens órfãs concluída',
        progress: 100,
      ));
      
      setState(() {
        _orphanedImagesReport = result;
        _isCleaningUp = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Limpeza concluída: ${result['deletedCount']} imagens removidas'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Logger.error('Erro ao limpar imagens órfãs: $e');
      setState(() {
        _errorMessage = e.toString();
        _isCleaningUp = false;
      });
      
      _progressStreamController.add(SyncProgress(
        entityType: 'cleanup_orphaned',
        status: 'error',
        message: 'Erro: $e',
        progress: 0,
      ));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    }
  }
  
  Future<void> _verifySampleImages(String sampleId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      _progressStreamController.add(SyncProgress(
        entityType: 'verify_sample',
        status: 'running',
        message: 'Verificando imagens da amostra $sampleId...',
        progress: 0,
      ));
      
      final result = await _imageIntegrityService.verifySampleImagesIntegrity(sampleId);
      
      _progressStreamController.add(SyncProgress(
        entityType: 'verify_sample',
        status: 'completed',
        message: 'Verificação de imagens da amostra concluída',
        progress: 100,
      ));
      
      setState(() {
        // Adicionar ou atualizar relatório da amostra
        final existingIndex = _sampleIntegrityReports.indexWhere(
          (report) => report['sampleId'] == sampleId
        );
        
        if (existingIndex >= 0) {
          _sampleIntegrityReports[existingIndex] = result;
        } else {
          _sampleIntegrityReports.add(result);
        }
        
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao verificar imagens da amostra $sampleId: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      _progressStreamController.add(SyncProgress(
        entityType: 'verify_sample',
        status: 'error',
        message: 'Erro: $e',
        progress: 0,
      ));
    }
  }
  
  Future<void> _repairSampleImages(String sampleId) async {
    setState(() {
      _isRepairing = true;
      _errorMessage = null;
    });
    
    try {
      _progressStreamController.add(SyncProgress(
        entityType: 'repair_sample',
        status: 'running',
        message: 'Reparando imagens da amostra $sampleId...',
        progress: 0,
      ));
      
      final result = await _imageIntegrityService.repairSampleImages(sampleId);
      
      _progressStreamController.add(SyncProgress(
        entityType: 'repair_sample',
        status: 'completed',
        message: 'Reparo de imagens da amostra concluído',
        progress: 100,
      ));
      
      // Atualizar verificação da amostra
      await _verifySampleImages(sampleId);
      
      setState(() {
        _isRepairing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reparo concluído: ${result['repairedCount']} imagens reparadas'),
          backgroundColor: result['success'] ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      Logger.error('Erro ao reparar imagens da amostra $sampleId: $e');
      setState(() {
        _errorMessage = e.toString();
        _isRepairing = false;
      });
      
      _progressStreamController.add(SyncProgress(
        entityType: 'repair_sample',
        status: 'error',
        message: 'Erro: $e',
        progress: 0,
      ));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integridade de Imagens'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Referências'),
            Tab(text: 'Imagens Órfãs'),
            Tab(text: 'Amostras'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de progresso
          StreamBuilder<SyncProgress>(
            stream: progressStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && 
                  snapshot.data!.status == 'running') {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: snapshot.data!.progress > 0 
                          ? snapshot.data!.progress / 100 
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        snapshot.data!.message,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox(height: 4);
            },
          ),
          
          // Conteúdo das tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReferencesTab(),
                _buildOrphanedImagesTab(),
                _buildSamplesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReferencesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Erro: $_errorMessage',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _verifyImageReferences,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    
    if (_imageReferencesReport == null) {
      return Center(
        child: ElevatedButton(
          onPressed: _verifyImageReferences,
          child: const Text('Verificar Referências'),
        ),
      );
    }
    
    final success = _imageReferencesReport!['success'] as bool;
    final totalImages = _imageReferencesReport!['totalImages'] as int;
    final validReferences = _imageReferencesReport!['validReferences'] as int;
    final invalidReferences = _imageReferencesReport!['invalidReferences'] as int;
    final missingFiles = _imageReferencesReport!['missingFiles'] as List<dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estatísticas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    success 
                        ? 'Todas as referências estão válidas' 
                        : 'Encontradas referências inválidas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: success ? Colors.green : Colors.orange,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildStatRow('Total de imagens', totalImages.toString()),
                  _buildStatRow('Referências válidas', validReferences.toString()),
                  _buildStatRow(
                    'Referências inválidas', 
                    invalidReferences.toString(),
                    color: invalidReferences > 0 ? Colors.orange : null,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Ações
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _verifyImageReferences,
                icon: const Icon(Icons.refresh),
                label: const Text('Verificar novamente'),
              ),
              ElevatedButton.icon(
                onPressed: invalidReferences > 0 && !_isCleaningUp
                    ? _cleanupInvalidReferences
                    : null,
                icon: const Icon(Icons.cleaning_services),
                label: Text(_isCleaningUp ? 'Limpando...' : 'Limpar referências inválidas'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Lista de arquivos ausentes
          if (missingFiles.isNotEmpty) ...[
            const Text(
              'Arquivos ausentes:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: missingFiles.length,
              itemBuilder: (context, index) {
                final file = missingFiles[index] as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  title: Text(
                    file['id'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    file['path'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const Icon(Icons.broken_image, color: Colors.red),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildOrphanedImagesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Verificação de imagens órfãs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Imagens órfãs são arquivos de imagem que não estão\nreferenciados no banco de dados.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          if (_orphanedImagesReport != null) ...[
            Text(
              'Encontradas ${_orphanedImagesReport!['orphanedCount']} imagens órfãs',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          ElevatedButton.icon(
            onPressed: !_isCleaningUp ? _cleanupOrphanedImages : null,
            icon: const Icon(Icons.cleaning_services),
            label: Text(_isCleaningUp ? 'Limpando...' : 'Limpar imagens órfãs'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSamplesTab() {
    return Column(
      children: [
        // Formulário para verificar amostra específica
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'ID da Amostra',
                    hintText: 'Digite o ID da amostra para verificar',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _verifySampleImages(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Implementar seleção de amostra
                },
                child: const Text('Selecionar'),
              ),
            ],
          ),
        ),
        
        // Lista de relatórios de amostras
        Expanded(
          child: _sampleIntegrityReports.isEmpty
              ? const Center(
                  child: Text('Nenhuma amostra verificada'),
                )
              : ListView.builder(
                  itemCount: _sampleIntegrityReports.length,
                  itemBuilder: (context, index) {
                    final report = _sampleIntegrityReports[index];
                    final sampleId = report['sampleId'] as String;
                    final success = report['success'] as bool;
                    final imagesCount = report['imagesCount'] as int;
                    final validImages = report['validImages'] as int;
                    final invalidImages = report['invalidImages'] as int;
                    final missingImages = report['missingImages'] as int;
                    final issues = report['issues'] as List<dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        title: Text('Amostra: $sampleId'),
                        subtitle: Text(
                          success
                              ? 'Todas as imagens estão íntegras'
                              : '${issues.length} problemas encontrados',
                          style: TextStyle(
                            color: success ? Colors.green : Colors.orange,
                          ),
                        ),
                        leading: Icon(
                          success ? Icons.check_circle : Icons.warning,
                          color: success ? Colors.green : Colors.orange,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatRow('Total de imagens', imagesCount.toString()),
                                _buildStatRow('Imagens válidas', validImages.toString()),
                                _buildStatRow(
                                  'Imagens inválidas', 
                                  invalidImages.toString(),
                                  color: invalidImages > 0 ? Colors.orange : null,
                                ),
                                _buildStatRow(
                                  'Imagens ausentes', 
                                  missingImages.toString(),
                                  color: missingImages > 0 ? Colors.red : null,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Ações
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _verifySampleImages(sampleId),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Verificar novamente'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: !success && !_isRepairing
                                          ? () => _repairSampleImages(sampleId)
                                          : null,
                                      icon: const Icon(Icons.healing),
                                      label: Text(_isRepairing ? 'Reparando...' : 'Reparar imagens'),
                                    ),
                                  ],
                                ),
                                
                                // Lista de problemas
                                if (issues.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Problemas encontrados:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ...issues.map((issue) {
                                    final imageId = issue['imageId'] as String;
                                    final path = issue['path'] as String;
                                    final issueType = issue['issue'] as String;
                                    final message = issue['message'] as String;
                                    final canRepair = issue['canRepair'] as bool? ?? false;
                                    
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        'ID: $imageId',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Problema: $message',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          Text(
                                            path,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      leading: Icon(
                                        issueType == 'missing' 
                                            ? Icons.not_interested
                                            : Icons.broken_image,
                                        color: issueType == 'missing' 
                                            ? Colors.red 
                                            : Colors.orange,
                                        size: 20,
                                      ),
                                      trailing: canRepair
                                          ? const Icon(
                                              Icons.healing,
                                              color: Colors.green,
                                              size: 16,
                                            )
                                          : null,
                                    );
                                  }).toList(),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
