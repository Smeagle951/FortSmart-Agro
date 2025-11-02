import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:sqflite/sqflite.dart';
import '../models/praga_image.dart';
import '../services/database_service.dart';

class PragaImageService {
  static const String tableName = 'praga_images';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_base64 TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        crop_id INTEGER,
        pest_id INTEGER,
        disease_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<int> savePragaImage(PragaImage pragaImage) async {
    final db = await DatabaseService().database;
    return await db.insert(tableName, pragaImage.toMap());
  }

  static Future<List<PragaImage>> getAllPragaImages() async {
    final db = await DatabaseService().database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) => PragaImage.fromMap(maps[i]));
  }

  static Future<List<PragaImage>> getPragaImagesByCrop(int cropId) async {
    final db = await DatabaseService().database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'crop_id = ?',
      whereArgs: [cropId],
    );
    return List.generate(maps.length, (i) => PragaImage.fromMap(maps[i]));
  }

  static Future<List<PragaImage>> getPragaImagesByPest(int pestId) async {
    final db = await DatabaseService().database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'pest_id = ?',
      whereArgs: [pestId],
    );
    return List.generate(maps.length, (i) => PragaImage.fromMap(maps[i]));
  }

  static Future<List<PragaImage>> getPragaImagesByDisease(int diseaseId) async {
    final db = await DatabaseService().database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'disease_id = ?',
      whereArgs: [diseaseId],
    );
    return List.generate(maps.length, (i) => PragaImage.fromMap(maps[i]));
  }

  static Future<List<PragaImage>> getPragaImagesByWeed(int weedId) async {
    final db = await DatabaseService().database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'weed_id = ?',
      whereArgs: [weedId],
    );
    return List.generate(maps.length, (i) => PragaImage.fromMap(maps[i]));
  }

  static Future<void> deletePragaImage(int id) async {
    final db = await DatabaseService().database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<PragaImage?> getPragaImageById(int id) async {
    final db = await DatabaseService().database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return PragaImage.fromMap(maps.first);
    }
    return null;
  }

  static Future<void> updatePragaImage(
    int id,
    String imageBase64,
    String colorHex,
    String? cropId,
    String? pestId,
    String? diseaseId,
  ) async {
    final db = await DatabaseService().database;
    
    final Map<String, dynamic> data = {
      'image_base64': imageBase64,
      'color_hex': colorHex,
      'crop_id': cropId != null ? int.tryParse(cropId) : null,
      'pest_id': pestId != null ? int.tryParse(pestId) : null,
      'disease_id': diseaseId != null ? int.tryParse(diseaseId) : null,
    };
    
    await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método para processar e salvar imagem
  static Future<String> processAndSaveImage(File imageFile, String colorHex, {
    int? cropId,
    int? pestId,
    int? diseaseId,
    int? weedId,
  }) async {
    try {
      // Ler a imagem
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        throw Exception('Não foi possível decodificar a imagem');
      }

      // Redimensionar para 64x64
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: 64,
        height: 64,
        interpolation: img.Interpolation.linear,
      );

      // Converter para PNG
      final Uint8List pngBytes = img.encodePng(resizedImage);
      
      // Converter para Base64
      final String base64String = base64Encode(pngBytes);

      // Criar e salvar o modelo
      final pragaImage = PragaImage(
        imageBase64: base64String,
        colorHex: colorHex,
        cropId: cropId,
        pestId: pestId,
        diseaseId: diseaseId,
        weedId: weedId,
        createdAt: DateTime.now(),
      );

      final int id = await savePragaImage(pragaImage);
      return 'Imagem salva com sucesso! ID: $id';
    } catch (e) {
      throw Exception('Erro ao processar imagem: $e');
    }
  }

  // Versão para usar com o callback do PragaImageModal
  static Future<void> processAndSaveImageFromCallback(
    File? imageFile,
    String colorHex,
    int? cropId,
    int? pestId,
    int? diseaseId,
    int? weedId,
  ) async {
    if (imageFile == null) {
      throw Exception('Nenhuma imagem selecionada');
    }
    
    await processAndSaveImage(imageFile, colorHex, 
      cropId: cropId, 
      pestId: pestId, 
      diseaseId: diseaseId,
      weedId: weedId,
    );
  }
} 