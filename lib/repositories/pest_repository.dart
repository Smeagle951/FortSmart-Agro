import '../database/models/pest.dart';
import '../database/daos/pest_dao.dart';

class PestRepository {
  final PestDao _pestDao;
  
  PestRepository({PestDao? pestDao}) : _pestDao = pestDao ?? PestDao();

  Future<List<Pest>> getAllPests() async {
    return await _pestDao.getAllPests();
  }

  Future<List<Pest>> getPestsByCropId(int cropId) async {
    return await _pestDao.getPestsByCropId(cropId);
  }

  Future<Pest?> getPestById(int id) async {
    return await _pestDao.getPestById(id);
  }

  Future<int> insertPest(Pest pest) async {
    return await _pestDao.insertPest(pest);
  }

  Future<int> updatePest(Pest pest) async {
    return await _pestDao.updatePest(pest);
  }

  Future<int> deletePest(int id) async {
    return await _pestDao.deletePest(id);
  }

  Future<List<Pest>> getUnsyncedPests() async {
    // Implementação simplificada usando métodos existentes
    final allPests = await getAllPests();
    return allPests.where((pest) => pest.syncStatus == 0).toList();
  }

  Future<int> markPestAsSynced(int id) async {
    // Obtém a praga atual
    final pest = await getPestById(id);
    if (pest == null) {
      return 0;
    }
    
    // Atualiza o status de sincronização
    final updatedPest = pest.copyWith(syncStatus: 1);
    return await _pestDao.updatePest(updatedPest);
  }

  Future<int> insertOrUpdatePest(Pest pest) async {
    // Verificar se a praga já existe
    final existingPest = await _pestDao.getPestById(pest.id);
    
    if (existingPest != null) {
      // Atualizar
      return await _pestDao.updatePest(pest);
    }
    
    // Inserir
    return await _pestDao.insertPest(pest);
  }
}
