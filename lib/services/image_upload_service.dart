import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/sync/image_upload_progress.dart';
import '../services/image_repair_service.dart';
import '../utils/logger.dart';
import '../utils/config.dart';

/// Serviço responsável por gerenciar o upload de imagens
class ImageUploadService {
  final ImageRepairService _imageRepairService = ImageRepairService();
  
  /// Stream controller para notificar sobre o progresso de upload
  final _progressController = StreamController<ImageUploadProgress>.broadcast();
  
  /// Stream para acompanhar o progresso de upload
  Stream<ImageUploadProgress> get uploadProgress => _progressController.stream;
  
  /// Retorna um stream filtrado para uma entidade específica
  Stream<ImageUploadProgress?> getUploadProgressStream({
    required String entityId,
    required String entityType,
  }) {
    return _progressController.stream.where((progress) => 
      progress.entityId == entityId && progress.entityType == entityType
    );
  }
  
  /// Cancela um upload em andamento por entityId e entityType
  void cancelUploadByEntity({
    required String entityId,
    required String entityType,
  }) {
    final uploadKey = '$entityId-$entityType';
    if (_activeUploads.containsKey(uploadKey)) {
      // Atualizar o status para cancelado
      final progress = _activeUploads[uploadKey]!;
      progress.markCancelled();
      _progressController.add(progress);
      _activeUploads.remove(uploadKey);
    }
  }
  
  /// Lista de uploads ativos
  final Map<String, ImageUploadProgress> _activeUploads = {};
  
  /// Lista de lotes de uploads ativos
  final Map<String, ImageUploadBatch> _activeBatches = {};
  
  /// Faz o upload de uma imagem com monitoramento de progresso
  Future<Map<String, dynamic>> uploadImageWithProgress({
    required File imageFile,
    required String entityId,
    required String entityType,
    required String uploadUrl,
    Map<String, String>? headers,
    Map<String, String>? fields,
    bool validateBeforeUpload = true,
    bool repairIfNeeded = true,
    bool retryOnFailure = true,
    int maxRetries = 3,
  }) async {
    try {
      // Verificar se o arquivo existe
      if (!await imageFile.exists()) {
        return {
          'success': false,
          'error': 'Arquivo não encontrado: ${imageFile.path}',
        };
      }
      
      // Validar a imagem antes do upload
      File fileToUpload = imageFile;
      if (validateBeforeUpload) {
        final validationResult = await _imageRepairService.validateImage(imageFile);
        
        if (!validationResult['isValid']) {
          Logger.info('Imagem inválida: ${validationResult['error']}');
          
          // Tentar reparar a imagem se necessário
          if (repairIfNeeded && validationResult['canRepair']) {
            Logger.info('Tentando reparar a imagem antes do upload');
            final repairResult = await _imageRepairService.repairImage(imageFile);
            
            if (repairResult['success']) {
              fileToUpload = repairResult['repairedFile'];
              Logger.info('Imagem reparada com sucesso: ${repairResult['message']}');
            } else {
              return {
                'success': false,
                'error': 'Falha ao reparar imagem: ${repairResult['error']}',
              };
            }
          } else {
            return {
              'success': false,
              'error': 'Imagem inválida: ${validationResult['error']}',
              'canRepair': validationResult['canRepair'],
            };
          }
        }
      }
      
      // Criar ID único para o upload
      final uploadId = const Uuid().v4();
      final fileName = path.basename(fileToUpload.path);
      final fileSize = await fileToUpload.length();
      
      // Criar objeto de progresso
      final progress = ImageUploadProgress(
        uploadId: uploadId,
        entityId: entityId,
        entityType: entityType,
        imageFile: fileToUpload,
        fileName: fileName,
        totalBytes: fileSize,
        status: 'pending',
      );
      
      // Adicionar à lista de uploads ativos
      _activeUploads[uploadId] = progress;
      
      // Notificar sobre o início do upload
      _progressController.add(progress);
      
      // Iniciar o upload
      progress.status = 'uploading';
      _progressController.add(progress);
      
      // Configurar o cliente HTTP
      final uri = Uri.parse(uploadUrl);
      final request = http.MultipartRequest('POST', uri);
      
      // Adicionar headers
      if (headers != null) {
        request.headers.addAll(headers);
      }
      
      // Adicionar campos adicionais
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      // Adicionar o arquivo
      final fileStream = http.ByteStream(fileToUpload.openRead());
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileSize,
        filename: fileName,
      );
      request.files.add(multipartFile);
      
      // Monitorar o progresso do upload
      int bytesSent = 0;
      final streamedResponse = await request.send().timeout(
        Duration(seconds: Config.uploadTimeoutSeconds),
        onTimeout: () {
          progress.markFailed('Timeout durante o upload');
          _progressController.add(progress);
          throw TimeoutException('Upload timeout');
        },
      );
      
      streamedResponse.stream.listen(
        (List<int> chunk) {
          bytesSent += chunk.length;
          progress.updateProgress(bytesSent);
          _progressController.add(progress);
        },
        onDone: () async {
          if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
            // Upload bem-sucedido
            progress.markCompleted();
            _progressController.add(progress);
            
            // Remover da lista de uploads ativos
            _activeUploads.remove(uploadId);
          } else {
            // Falha no upload
            final responseBody = await streamedResponse.stream.bytesToString();
            final errorMessage = 'Erro ${streamedResponse.statusCode}: $responseBody';
            progress.markFailed(errorMessage);
            _progressController.add(progress);
            
            // Tentar novamente se configurado
            if (retryOnFailure && progress.bytesUploaded < fileSize) {
              await _retryUpload(
                progress, 
                uploadUrl, 
                headers, 
                fields, 
                maxRetries
              );
            } else {
              _activeUploads.remove(uploadId);
            }
          }
        },
        onError: (error) {
          progress.markFailed('Erro durante o upload: $error');
          _progressController.add(progress);
          
          // Tentar novamente se configurado
          if (retryOnFailure) {
            _retryUpload(progress, uploadUrl, headers, fields, maxRetries);
          } else {
            _activeUploads.remove(uploadId);
          }
        },
      );
      
      // Retornar informações sobre o upload iniciado
      return {
        'success': true,
        'uploadId': uploadId,
        'message': 'Upload iniciado',
        'progress': progress,
      };
    } catch (e) {
      Logger.error('Erro ao iniciar upload de imagem: $e');
      return {
        'success': false,
        'error': 'Erro ao iniciar upload: $e',
      };
    }
  }
  
  /// Tenta novamente um upload que falhou
  Future<void> _retryUpload(
    ImageUploadProgress progress,
    String uploadUrl,
    Map<String, String>? headers,
    Map<String, String>? fields,
    int maxRetries,
  ) async {
    // Verificar se já excedeu o número máximo de tentativas
    final retryCount = progress.toMap()['retryCount'] ?? 0;
    if (retryCount >= maxRetries) {
      progress.markFailed('Número máximo de tentativas excedido');
      _progressController.add(progress);
      _activeUploads.remove(progress.uploadId);
      return;
    }
    
    // Aguardar um tempo antes de tentar novamente (backoff exponencial)
    final backoffSeconds = Config.backoffInitialSeconds * (1 << retryCount);
    final delay = Duration(seconds: backoffSeconds.clamp(
      Config.backoffInitialSeconds, 
      Config.backoffMaxSeconds
    ));
    
    Logger.info('Tentando novamente upload ${progress.uploadId} em ${delay.inSeconds} segundos (tentativa ${retryCount + 1}/$maxRetries)');
    
    await Future.delayed(delay);
    
    // Tentar o upload novamente
    progress.status = 'retrying';
    _progressController.add(progress);
    
    await uploadImageWithProgress(
      imageFile: progress.imageFile,
      entityId: progress.entityId,
      entityType: progress.entityType,
      uploadUrl: uploadUrl,
      headers: headers,
      fields: fields,
      validateBeforeUpload: false, // Já foi validado
      repairIfNeeded: false, // Já foi reparado se necessário
      retryOnFailure: true,
      maxRetries: maxRetries - 1,
    );
  }
  
  /// Faz o upload de um lote de imagens
  Future<Map<String, dynamic>> uploadImageBatch({
    required List<File> imageFiles,
    required String entityId,
    required String entityType,
    required String uploadUrl,
    Map<String, String>? headers,
    Map<String, String> Function(File file)? fieldsBuilder,
    bool validateBeforeUpload = true,
    bool repairIfNeeded = true,
    bool parallelUploads = true,
    int maxConcurrentUploads = Config.maxParallelUploads,
  }) async {
    try {
      // Criar ID único para o lote
      final batchId = const Uuid().v4();
      final uploads = <ImageUploadProgress>[];
      
      // Criar lote
      final batch = ImageUploadBatch(
        batchId: batchId,
        uploads: uploads,
      );
      
      // Adicionar à lista de lotes ativos
      _activeBatches[batchId] = batch;
      
      // Iniciar uploads
      final results = <Map<String, dynamic>>[];
      
      if (parallelUploads) {
        // Dividir em lotes para controlar o número máximo de uploads paralelos
        final chunks = <List<File>>[];
        for (var i = 0; i < imageFiles.length; i += maxConcurrentUploads) {
          final end = (i + maxConcurrentUploads < imageFiles.length) 
              ? i + maxConcurrentUploads 
              : imageFiles.length;
          chunks.add(imageFiles.sublist(i, end));
        }
        
        // Processar cada lote sequencialmente, mas com uploads paralelos dentro de cada lote
        for (final chunk in chunks) {
          final chunkResults = await Future.wait(
            chunk.map((file) async {
              final fields = fieldsBuilder != null ? fieldsBuilder(file) : null;
              return await uploadImageWithProgress(
                imageFile: file,
                entityId: entityId,
                entityType: entityType,
                uploadUrl: uploadUrl,
                headers: headers,
                fields: fields,
                validateBeforeUpload: validateBeforeUpload,
                repairIfNeeded: repairIfNeeded,
              );
            }),
          );
          
          results.addAll(chunkResults);
          
          // Adicionar os uploads ao lote
          for (final result in chunkResults) {
            if (result['success'] && result['progress'] != null) {
              batch.addUpload(result['progress']);
            }
          }
          
          // Atualizar status do lote
          batch.updateStatus();
        }
      } else {
        // Processar sequencialmente
        for (final file in imageFiles) {
          final fields = fieldsBuilder != null ? fieldsBuilder(file) : null;
          final result = await uploadImageWithProgress(
            imageFile: file,
            entityId: entityId,
            entityType: entityType,
            uploadUrl: uploadUrl,
            headers: headers,
            fields: fields,
            validateBeforeUpload: validateBeforeUpload,
            repairIfNeeded: repairIfNeeded,
          );
          
          results.add(result);
          
          // Adicionar o upload ao lote
          if (result['success'] && result['progress'] != null) {
            batch.addUpload(result['progress']);
          }
          
          // Atualizar status do lote
          batch.updateStatus();
        }
      }
      
      // Retornar informações sobre o lote
      return {
        'success': true,
        'batchId': batchId,
        'message': 'Lote de uploads iniciado',
        'batch': batch,
        'results': results,
      };
    } catch (e) {
      Logger.error('Erro ao iniciar lote de uploads: $e');
      return {
        'success': false,
        'error': 'Erro ao iniciar lote de uploads: $e',
      };
    }
  }
  
  /// Cancela um upload em andamento por uploadId
  Future<bool> cancelUpload(String uploadId) async {
    final upload = _activeUploads[uploadId];
    if (upload == null) {
      return false;
    }
    
    upload.markCancelled();
    _progressController.add(upload);
    _activeUploads.remove(uploadId);
    return true;
  }
  
  /// Cancela um lote de uploads
  Future<bool> cancelBatch(String batchId) async {
    final batch = _activeBatches[batchId];
    if (batch == null) {
      return false;
    }
    
    batch.cancelAll();
    _activeBatches.remove(batchId);
    return true;
  }
  
  /// Obtém o status de um upload
  ImageUploadProgress? getUploadStatus(String uploadId) {
    return _activeUploads[uploadId];
  }
  
  /// Obtém o status de um lote
  ImageUploadBatch? getBatchStatus(String batchId) {
    return _activeBatches[batchId];
  }
  
  /// Libera recursos ao destruir o serviço
  void dispose() {
    _progressController.close();
  }
}
