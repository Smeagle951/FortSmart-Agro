import '../database/daos/property_dao.dart';
import '../database/models/property.dart' as DbModel;
import '../models/property.dart';
import '../services/file_manager.dart';
import 'dart:io';

class PropertyRepository {
  final PropertyDao _propertyDao = PropertyDao();
  final FileManager _fileManager = FileManager();

  // Obter todas as propriedades
  Future<List<Property>> getAllProperties() async {
    final dbProperties = await _propertyDao.getAll();
    List<Property> result = [];
    for (var dbProperty in dbProperties) {
      result.add(Property.fromDbModel(dbProperty));
    }
    return result;
  }

  // Obter uma propriedade pelo ID
  Future<Property?> getPropertyById(int id) async {
    final dbProperty = await _propertyDao.getById(id);
    if (dbProperty == null) return null;
    return Property.fromDbModel(dbProperty);
  }

  // Adicionar uma nova propriedade
  Future<int> addProperty(Property property, {File? imageFile}) async {
    // Converter para o modelo do banco de dados
    final dbProperty = DbModel.Property(
      id: property.id,
      name: property.name,
      address: property.address,
      totalArea: property.area,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      syncStatus: property.syncStatus,
    );

    // Inserir no banco de dados
    final propertyId = await _propertyDao.insert(dbProperty);

    // Salvar imagem se fornecida
    if (imageFile != null) {
      await _fileManager.savePropertyImage(imageFile, propertyId);
    }

    return propertyId;
  }

  // Atualizar uma propriedade existente
  Future<bool> updateProperty(Property property, {File? imageFile}) async {
    // Buscar a propriedade existente no banco de dados
    final existingDbProperty = await _propertyDao.getById(property.id);
    if (existingDbProperty == null) return false;
    
    // Atualizar os campos com os novos valores
    final dbProperty = DbModel.Property(
      id: property.id,
      name: property.name,
      address: property.address,
      totalArea: property.area,
      createdAt: existingDbProperty.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      syncStatus: 0,
      remoteId: existingDbProperty.remoteId,
      polygonJson: existingDbProperty.polygonJson,
      city: existingDbProperty.city,
      state: existingDbProperty.state,
    );

    // Atualizar no banco de dados
    final result = await _propertyDao.update(dbProperty);
    final success = result > 0;

    // Salvar imagem se fornecida
    if (success && imageFile != null) {
      await _fileManager.savePropertyImage(imageFile, property.id);
    }

    return success;
  }

  // Excluir uma propriedade
  Future<bool> deleteProperty(Property property) async {
    if (property.id <= 0) return false;
    
    final result = await _propertyDao.delete(property.id);
    return result > 0;
  }
}
