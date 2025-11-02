import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../models/farm.dart';
import '../repositories/farm_repository.dart';
import '../widgets/file_picker_wrapper.dart';
import '../widgets/notifications_wrapper.dart';
import '../models/plot.dart';
import '../repositories/plot_repository.dart';
import '../database/app_database.dart'; // Adicionando import do AppDatabase

class FarmService {
  final FarmRepository _repository = FarmRepository();
  final FilePickerWrapper _filePicker = FilePickerWrapper();
  final PlotRepository _plotRepository = PlotRepository();
  final AppDatabase _appDatabase = AppDatabase(); // Adicionando instância do AppDatabase
  Farm? _currentFarm;
  
  /// Retorna a fazenda atual selecionada
  Future<Farm?> getCurrentFarm() async {
    await _ensureDatabaseOpen();
    if (_currentFarm == null) {
      // Tenta obter a primeira fazenda cadastrada como padrão
      final farms = await getAllFarms();
      if (farms.isNotEmpty) {
        _currentFarm = farms.first;
      }
    }
    return _currentFarm;
  }
  
  /// Define a fazenda atual
  void setCurrentFarm(Farm farm) {
    _currentFarm = farm;
  }
  
  // Método para garantir que o banco de dados esteja aberto antes de qualquer operação
  Future<void> _ensureDatabaseOpen() async {
    try {
      // Apenas acessar o banco de dados para garantir que está aberto
      await _appDatabase.database;
    } catch (e) {
      print('Erro ao verificar banco de dados: $e');
      // Não propagar o erro, apenas registrar
    }
  }

  // Obter todas as fazendas
  Future<List<Farm>> getAllFarms() async {
    await _ensureDatabaseOpen();
    return await _repository.getAllFarms();
  }

  // Obter uma fazenda pelo ID
  Future<Farm?> getFarmById(String id) async {
    await _ensureDatabaseOpen();
    Farm? farm = await _repository.getFarmById(id);
    
    // Se a fazenda não existir, criar uma padrão
    if (farm == null) {
      farm = await _createDefaultFarm(id);
    }
    
    return farm;
  }
  
  // Criar uma fazenda padrão
  Future<Farm> _createDefaultFarm(String id) async {
    final defaultFarm = Farm(
      id: id,
      name: 'Minha Fazenda',
      address: 'Endereço não informado',
      isActive: true,
      totalArea: 0.0,
      plotsCount: 0,
      crops: [], // Campo obrigatório
      hasIrrigation: false,
    );
    
    await addFarm(defaultFarm);
    return defaultFarm;
  }

  // Adicionar uma nova fazenda
  Future<String> addFarm(Farm farm) async {
    // Garantir que os campos opcionais sejam inicializados como nulos para novas instalações
    farm = Farm(
      id: farm.id,
      name: farm.name,
      address: farm.address,
      logoUrl: null, // Sempre inicializar como nulo
      isActive: farm.isActive,
      plots: farm.plots,
      responsiblePerson: farm.responsiblePerson?.isEmpty == true ? null : farm.responsiblePerson,
      documentNumber: farm.documentNumber?.isEmpty == true ? null : farm.documentNumber,
      phone: farm.phone?.isEmpty == true ? null : farm.phone,
      email: farm.email?.isEmpty == true ? null : farm.email,
      totalArea: farm.totalArea,
      plotsCount: farm.plotsCount,
      crops: farm.crops,
      cultivationSystem: farm.cultivationSystem?.isEmpty == true ? null : farm.cultivationSystem,
      hasIrrigation: farm.hasIrrigation,
      irrigationType: farm.irrigationType?.isEmpty == true ? null : farm.irrigationType,
      mechanizationLevel: farm.mechanizationLevel?.isEmpty == true ? null : farm.mechanizationLevel,
      technicalResponsibleName: farm.technicalResponsibleName?.isEmpty == true ? null : farm.technicalResponsibleName,
      technicalResponsibleId: farm.technicalResponsibleId?.isEmpty == true ? null : farm.technicalResponsibleId,
    );
    
    return await _repository.addFarm(farm);
  }

  // Atualizar uma fazenda existente
  Future<void> updateFarm(Farm farm) async {
    await _ensureDatabaseOpen();
    final success = await _repository.updateFarm(farm);
    if (!success) {
      throw Exception('Falha ao atualizar fazenda');
    }
  }

  // Excluir uma fazenda
  Future<bool> deleteFarm(String id) async {
    await _ensureDatabaseOpen();
    return await _repository.deleteFarm(id);
  }

  // Verificar se uma fazenda está verificada
  bool isFarmVerified(Farm farm) {
    // Uma fazenda é considerada verificada se todos os campos obrigatórios estiverem preenchidos
    return farm.name.isNotEmpty &&
        farm.responsiblePerson?.isNotEmpty == true &&
        farm.documentNumber?.isNotEmpty == true &&
        farm.phone?.isNotEmpty == true &&
        farm.email?.isNotEmpty == true &&
        farm.address.isNotEmpty &&
        farm.totalArea > 0 &&
        farm.crops.isNotEmpty &&
        farm.cultivationSystem?.isNotEmpty == true &&
        farm.technicalResponsibleName?.isNotEmpty == true &&
        farm.technicalResponsibleId?.isNotEmpty == true;
  }

  // Adicionar logo da fazenda
  Future<String?> addFarmLogo(BuildContext context, String farmId) async {
    try {
      // Pedir ao usuário para selecionar uma imagem
      final imageSource = await _showImageSourceDialog(context);
      if (imageSource == null) return null;
      
      // Obter a imagem usando o FilePickerWrapper
      final File? imageFile = await _filePicker.pickImage(source: imageSource);
      if (imageFile == null) return null;
      
      // Obter o diretório de documentos
      final appDir = await getApplicationDocumentsDirectory();
      final farmLogoDir = Directory('${appDir.path}/farm_logos');
      
      // Criar o diretório se não existir
      if (!await farmLogoDir.exists()) {
        await farmLogoDir.create(recursive: true);
      }
      
      // Gerar um nome de arquivo único
      final uuid = const Uuid().v4();
      final fileExtension = path.extension(imageFile.path);
      final fileName = 'farm_logo_${farmId}_$uuid$fileExtension';
      
      // Copiar o arquivo para o diretório de logos
      final savedImagePath = '${farmLogoDir.path}/$fileName';
      final savedImage = await imageFile.copy(savedImagePath);
      
      // Atualizar a fazenda com o novo logo
      final farm = await getFarmById(farmId);
      if (farm != null) {
        farm.logoUrl = savedImage.path;
        await updateFarm(farm);
      }
      
      return savedImage.path;
    } catch (e) {
      print('Erro ao adicionar logo: $e');
      return null;
    }
  }
  
  // Mostrar diálogo para escolher a fonte da imagem
  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar imagem de'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  // Adicionar documento da fazenda
  Future<FarmDocument?> addFarmDocument(
    BuildContext context,
    String farmId,
    String documentName,
    String documentType,
  ) async {
    try {
      // Mostrar diálogo para escolher o arquivo
      String? filePath;
      
      await _filePicker.showImagePickerDialog(
        context,
        onImageSelected: (path) {
          filePath = path;
        },
      );
      
      if (filePath == null) {
        return null;
      }
      
      // Copiar o arquivo para a pasta de documentos da fazenda
      final appDir = await getApplicationDocumentsDirectory();
      final farmDocsDir = Directory('${appDir.path}/farm_documents/$farmId');
      
      if (!await farmDocsDir.exists()) {
        await farmDocsDir.create(recursive: true);
      }
      
      final fileExtension = path.extension(filePath!);
      final fileName = '${const Uuid().v4()}$fileExtension';
      final targetPath = '${farmDocsDir.path}/$fileName';
      
      // Copiar o arquivo
      await File(filePath!).copy(targetPath);
      
      // Criar o documento
      final document = FarmDocument(
        id: const Uuid().v4(),
        name: documentName,
        type: documentType,
        fileUrl: targetPath,
        uploadDate: DateTime.now(),
      );
      
      // Atualizar a fazenda com o novo documento
      final farm = await _repository.getFarmById(farmId);
      
      if (farm != null) {
        final documents = List<FarmDocument>.from(farm.documents);
        documents.add(document);
        
        final updatedFarm = farm.copyWith(documents: documents);
        await _repository.updateFarm(updatedFarm);
      }
      
      return document;
    } catch (e) {
      NotificationsWrapper().showNotification(
        context,
        title: 'Erro',
        message: 'Erro ao adicionar documento da fazenda: $e',
        isError: true,
      );
      return null;
    }
  }

  // Remover documento da fazenda
  Future<bool> removeFarmDocument(BuildContext context, String farmId, String documentId) async {
    try {
      // Obter a fazenda atual
      final farm = await getFarmById(farmId);
      if (farm == null) {
        return false;
      }
      
      // Encontrar o documento a ser removido
      final documentIndex = farm.documents.indexWhere((doc) => doc.id == documentId);
      if (documentIndex == -1) {
        return false;
      }
      
      // Remover o arquivo físico se existir
      final document = farm.documents[documentIndex];
      if (document.fileUrl != null) {
        final file = File(document.fileUrl!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Remover o documento da lista
      final updatedDocuments = List<FarmDocument>.from(farm.documents)..removeAt(documentIndex);
      final updatedFarm = farm.copyWith(documents: updatedDocuments);
      
      // Atualizar a fazenda
      await _repository.updateFarm(updatedFarm);
      
      return true;
    } catch (e) {
      print('Erro ao remover documento da fazenda: $e');
      return false;
    }
  }

  // Atualizar contagem de talhões
  Future<bool> updatePlotsCount(String farmId, int count) async {
    try {
      final farm = await _repository.getFarmById(farmId);
      
      if (farm == null) {
        return false;
      }
      
      final updatedFarm = farm.copyWith(plotsCount: count);
      await _repository.updateFarm(updatedFarm);
      
      return true;
    } catch (e) {
      print('Erro ao atualizar contagem de talhões: $e');
      return false;
    }
  }

  // Desativar fazenda
  Future<bool> deactivateFarm(String id) async {
    try {
      final farm = await getFarmById(id);
      if (farm != null) {
        farm.isActive = false;
        await updateFarm(farm);
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao desativar fazenda: $e');
      return false;
    }
  }

  // Carregar os talhões associados a uma fazenda
  Future<List<Plot>?> getPlotsByFarm(String farmId) async {
    try {
      return await _plotRepository.getPlotsByFarm(farmId);
    } catch (e) {
      print('Erro ao carregar talhões: $e');
      return null;
    }
  }

  // Atualizar o logo da fazenda
  Future<bool> updateFarmLogo(String farmId, String logoPath) async {
    try {
      // Obter a fazenda atual
      final farm = await getFarmById(farmId);
      if (farm == null) {
        return false;
      }
      
      // Copiar o arquivo para o diretório de documentos do aplicativo
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'farm_logo_${farmId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = path.join(appDir.path, 'farm_logos', fileName);
      
      // Criar diretório se não existir
      final directory = Directory(path.dirname(targetPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Copiar o arquivo
      final file = File(logoPath);
      await file.copy(targetPath);
      
      // Atualizar a fazenda com o novo caminho do logo
      final updatedFarm = farm.copyWith(logoUrl: targetPath);
      await _repository.updateFarm(updatedFarm);
      
      return true;
    } catch (e) {
      print('Erro ao atualizar logo da fazenda: $e');
      return false;
    }
  }
  
  // Alternar o status da fazenda (ativar/desativar)
  Future<bool> toggleFarmStatus(String farmId) async {
    try {
      // Obter a fazenda atual
      final farm = await getFarmById(farmId);
      if (farm == null) {
        return false;
      }
      
      // Inverter o status atual
      final updatedFarm = farm.copyWith(isActive: !farm.isActive);
      await _repository.updateFarm(updatedFarm);
      
      return true;
    } catch (e) {
      print('Erro ao alternar status da fazenda: $e');
      return false;
    }
  }
  
  // Adicionar um documento à fazenda
  Future<bool> addFarmDocumentSimple(BuildContext context, String farmId) async {
    try {
      // Obter a fazenda atual
      final farm = await getFarmById(farmId);
      if (farm == null) {
        return false;
      }
      
      // Solicitar o arquivo
      final filePath = await _filePicker.pickImage(source: ImageSource.gallery);
      if (filePath == null) {
        return false;
      }
      
      // Solicitar nome e tipo do documento
      String? documentName;
      String? documentType;
      
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Informações do Documento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nome do Documento',
                  hintText: 'Ex: CAR, CCIR, Matrícula',
                ),
                onChanged: (value) => documentName = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Tipo do Documento',
                  hintText: 'Ex: Ambiental, Fundiário, Legal',
                ),
                onChanged: (value) => documentType = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      );
      
      if (result != true) {
        return false;
      }
      
      // Copiar o arquivo para o diretório da aplicação
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'farm_doc_${farmId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(filePath.path)}';
      final targetPath = path.join(appDir.path, 'documents', fileName);
      
      // Criar o diretório se não existir
      final directory = Directory(path.dirname(targetPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Copiar o arquivo
      final file = File(filePath.path);
      await file.copy(targetPath);
      
      // Criar o novo documento
      final newDocument = FarmDocument(
        id: const Uuid().v4(),
        name: documentName ?? 'Documento sem nome',
        type: documentType ?? 'Outro',
        fileUrl: targetPath,
        uploadDate: DateTime.now(),
      );
      
      // Adicionar o documento à lista de documentos da fazenda
      final updatedDocuments = List<FarmDocument>.from(farm.documents)..add(newDocument);
      final updatedFarm = farm.copyWith(documents: updatedDocuments);
      
      // Atualizar a fazenda
      await _repository.updateFarm(updatedFarm);
      
      return true;
    } catch (e) {
      print('Erro ao adicionar documento à fazenda: $e');
      return false;
    }
  }
  
  // Remover um documento da fazenda
  Future<bool> removeFarmDocumentNew(BuildContext context, String farmId, String documentId) async {
    try {
      // Obter a fazenda atual
      final farm = await getFarmById(farmId);
      if (farm == null) {
        return false;
      }
      
      // Encontrar o documento a ser removido
      final documentIndex = farm.documents.indexWhere((doc) => doc.id == documentId);
      if (documentIndex == -1) {
        return false;
      }
      
      // Remover o arquivo físico se existir
      final document = farm.documents[documentIndex];
      if (document.fileUrl != null) {
        final file = File(document.fileUrl!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Remover o documento da lista
      final updatedDocuments = List<FarmDocument>.from(farm.documents)..removeAt(documentIndex);
      final updatedFarm = farm.copyWith(documents: updatedDocuments);
      
      // Atualizar a fazenda
      await _repository.updateFarm(updatedFarm);
      
      return true;
    } catch (e) {
      print('Erro ao remover documento da fazenda: $e');
      return false;
    }
  }
}
