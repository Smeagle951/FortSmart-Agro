import 'dart:io';
import '../database/daos/crop_dao.dart';
import '../database/daos/pest_dao.dart';
import '../database/daos/disease_dao.dart';
import '../database/daos/weed_dao.dart';
import '../database/app_database.dart';
import '../models/crop.dart';
import '../models/pest.dart';
import '../models/disease.dart';
import '../models/weed.dart';

void main() async {
  print('🔄 Iniciando atualização dos dados de culturas...');
  
  try {
    // Inicializar banco de dados
    final appDatabase = AppDatabase();
    await appDatabase.initialize();
    
    // Atualizar culturas
    final cropDao = CropDao();
    await cropDao.initialize();
    
    // Limpar dados existentes e inserir novos
    print('🗑️ Limpando dados existentes...');
    final db = await appDatabase.database;
    await db.delete('crops');
    await db.delete('pests');
    await db.delete('diseases');
    await db.delete('weeds');
    
    print('✅ Dados limpos. Inserindo novas culturas...');
    await cropDao.insertDefaultCrops();
    
    // Atualizar pragas
    print('🦗 Inserindo pragas atualizadas...');
    final pestDao = PestDao();
    await pestDao.initialize();
    await pestDao.insertDefaultPests();
    
    // Atualizar doenças
    print('🦠 Inserindo doenças atualizadas...');
    final diseaseDao = DiseaseDao();
    await diseaseDao.initialize();
    await diseaseDao.insertDefaultDiseases();
    
    // Atualizar plantas daninhas
    print('🌿 Inserindo plantas daninhas atualizadas...');
    final weedDao = WeedDao();
    await weedDao.initialize();
    await weedDao.insertDefaultWeeds();
    
    print('✅ Atualização concluída com sucesso!');
    print('📊 Dados inseridos:');
    print('   - 9 culturas principais');
    print('   - Pragas específicas por cultura');
    print('   - Doenças específicas por cultura');
    print('   - Plantas daninhas');
    print('   - Torrãozinho adicionado à soja');
    
  } catch (e) {
    print('❌ Erro durante a atualização: $e');
  }
  
  exit(0);
}
