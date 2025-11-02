import '../database/models/weed.dart';
import '../database/daos/weed_dao.dart';

class WeedRepository {
  final WeedDao _weedDao;
  
  WeedRepository({WeedDao? weedDao}) : _weedDao = weedDao ?? WeedDao();

  Future<List<Weed>> getAllWeeds() async {
    return await _weedDao.getAllWeeds();
  }

  Future<List<Weed>> getWeedsByCropId(int cropId) async {
    return await _weedDao.getWeedsByCropId(cropId);
  }

  Future<Weed?> getWeedById(int id) async {
    return await _weedDao.getWeedById(id);
  }

  Future<int> insertWeed(Weed weed) async {
    return await _weedDao.insertWeed(weed);
  }

  Future<int> updateWeed(Weed weed) async {
    return await _weedDao.updateWeed(weed);
  }

  Future<int> deleteWeed(int id) async {
    return await _weedDao.deleteWeed(id);
  }

  Future<List<Weed>> getUnsyncedWeeds() async {
    // Implementação simplificada usando métodos existentes
    final allWeeds = await getAllWeeds();
    return allWeeds.where((weed) => weed.syncStatus == 0).toList();
  }

  Future<int> markWeedAsSynced(int id) async {
    // Obtém a planta daninha atual
    final weed = await getWeedById(id);
    if (weed == null) {
      return 0;
    }
    
    // Atualiza o status de sincronização
    final updatedWeed = weed.copyWith(syncStatus: 1);
    return await updateWeed(updatedWeed);
  }

  Future<int> insertOrUpdateWeed(Weed weed) async {
    // Verificar se a planta daninha já existe
    final existingWeed = await getWeedById(weed.id);
    
    if (existingWeed != null) {
      // Atualizar
      return await updateWeed(weed);
    }
    
    // Inserir
    return await insertWeed(weed);
  }
}
