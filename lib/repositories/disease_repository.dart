import '../database/models/disease.dart';
import '../database/daos/disease_dao.dart';

class DiseaseRepository {
  final DiseaseDao _diseaseDao;
  
  DiseaseRepository({DiseaseDao? diseaseDao}) : _diseaseDao = diseaseDao ?? DiseaseDao();

  Future<List<Disease>> getAllDiseases() async {
    return await _diseaseDao.getAllDiseases();
  }

  Future<List<Disease>> getDiseasesByCropId(int cropId) async {
    return await _diseaseDao.getDiseasesByCropId(cropId);
  }

  Future<Disease?> getDiseaseById(int id) async {
    return await _diseaseDao.getDiseaseById(id);
  }

  Future<int> insertDisease(Disease disease) async {
    return await _diseaseDao.insertDisease(disease);
  }

  Future<int> updateDisease(Disease disease) async {
    return await _diseaseDao.updateDisease(disease);
  }

  Future<int> deleteDisease(int id) async {
    return await _diseaseDao.deleteDisease(id);
  }

  Future<List<Disease>> getUnsyncedDiseases() async {
    // Implementação simplificada usando métodos existentes
    final allDiseases = await getAllDiseases();
    return allDiseases.where((disease) => disease.syncStatus == 0).toList();
  }

  Future<int> markDiseaseAsSynced(int id) async {
    // Obtém a doença atual
    final disease = await getDiseaseById(id);
    if (disease == null) {
      return 0;
    }
    
    // Atualiza o status de sincronização
    final updatedDisease = disease.copyWith(syncStatus: 1);
    return await updateDisease(updatedDisease);
  }

  Future<int> insertOrUpdateDisease(Disease disease) async {
    // Verificar se a doença já existe
    final existingDisease = await getDiseaseById(disease.id);
    
    if (existingDisease != null) {
      // Atualizar
      return await updateDisease(disease);
    }
    
    // Inserir
    return await insertDisease(disease);
  }
}
