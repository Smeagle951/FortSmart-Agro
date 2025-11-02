import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/crop.dart';
import '../database/app_database.dart';

/// Repositório para gerenciar operações relacionadas às culturas
class CropRepository {
  final AppDatabase _appDatabase = AppDatabase();
  
  Future<Database> get database async => await _appDatabase.database;
  
  /// Obtém todas as culturas do banco de dados
  Future<List<Crop>> getAllCrops() async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query('crops');
    
    return List.generate(maps.length, (i) {
      return Crop.fromMap(maps[i]);
    });
  }
  
  /// Obtém uma cultura pelo ID
  Future<Crop?> getCropById(int id) async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'crops',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return Crop.fromMap(maps.first);
  }
  
  /// Insere uma nova cultura no banco de dados
  Future<int> insertCrop(Crop crop) async {
    final db = await _appDatabase.database;
    return await db.insert('crops', crop.toMap());
  }
  
  /// Atualiza uma cultura existente
  Future<int> updateCrop(Crop crop) async {
    final db = await _appDatabase.database;
    return await db.update(
      'crops',
      crop.toMap(),
      where: 'id = ?',
      whereArgs: [crop.id],
    );
  }
  
  /// Exclui uma cultura pelo ID
  Future<int> deleteCrop(int id) async {
    final db = await _appDatabase.database;
    return await db.delete(
      'crops',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Salva a imagem do ícone da cultura no armazenamento local
  Future<String?> saveIconImage(File imageFile, String cropId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cropIconsDir = Directory('${appDir.path}/crop_icons');
      
      // Cria o diretório se não existir
      if (!await cropIconsDir.exists()) {
        await cropIconsDir.create(recursive: true);
      }
      
      // Define o caminho do arquivo
      final fileName = 'crop_icon_$cropId${extension(imageFile.path)}';
      final savedImage = await imageFile.copy('${cropIconsDir.path}/$fileName');
      
      return savedImage.path;
    } catch (e) {
      print('Erro ao salvar imagem: $e');
      return null;
    }
  }
}
