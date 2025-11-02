import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class SoilAnalysisImportService {
  final _tabelaAnaliseSolo = 'analise_solo';
  
  // Obter banco de dados
  Future<Database> _getDatabase() async {
    return await AppDatabase.instance.database;
  }
  
  // Obter análises de solo para um talhão específico
  Future<List<Map<String, dynamic>>> getAnalisesSoloByTalhao(String talhaoId) async {
    final db = await _getDatabase();
    return await db.query(
      _tabelaAnaliseSolo,
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'data DESC',
    );
  }
  
  // Selecionar imagem da galeria
  Future<File?> selecionarImagemGaleria() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
  
  // Selecionar imagem da câmera
  Future<File?> selecionarImagemCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
  
  // Processar a imagem da análise de solo (simulação)
  // Em um cenário real, isso poderia usar OCR ou ML para extrair dados da imagem
  Future<Map<String, dynamic>?> processarAnaliseImagem(File imagemFile, String talhaoId) async {
    // Simulação de processamento (em um app real usaria OCR/ML)
    await Future.delayed(const Duration(seconds: 2));
    
    // Criar um objeto com dados simulados
    // Em uma implementação real, estes dados viriam do processamento da imagem
    final analiseSolo = {
      'talhao_id': talhaoId,
      'data': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'ph': (5.5 + (DateTime.now().millisecond % 10) / 10).toStringAsFixed(1),
      'fosforo': 7 + (DateTime.now().second % 5),
      'potassio': (0.2 + (DateTime.now().millisecond % 10) / 100).toStringAsFixed(2),
      'calcio': (3.2 + (DateTime.now().second % 10) / 10).toStringAsFixed(1),
      'magnesio': (1.8 + (DateTime.now().millisecond % 10) / 10).toStringAsFixed(1),
      'enxofre': (5.0 + (DateTime.now().second % 10) / 10).toStringAsFixed(1),
      'aluminio': (0.1 + (DateTime.now().millisecond % 5) / 10).toStringAsFixed(1),
      'v_porcentagem': 45 + (DateTime.now().second % 20),
      'materia_organica': (2.5 + (DateTime.now().millisecond % 10) / 10).toStringAsFixed(1),
      'ctc': (9.5 + (DateTime.now().second % 10) / 10).toStringAsFixed(1),
      'saturacao_aluminio': (5.0 + (DateTime.now().millisecond % 10) / 10).toStringAsFixed(1),
      'observacoes': 'Análise importada automaticamente em ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
      'imagem_path': imagemFile.path,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 0
    };
    
    // Salvar a imagem em local permanente
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'soil_analysis_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imagemFile.copy('${appDir.path}/$fileName');
    
    // Atualizar o caminho da imagem
    analiseSolo['imagem_path'] = savedImage.path;
    
    return analiseSolo;
  }
  
  // Salvar a análise de solo no banco de dados
  Future<int> salvarAnaliseSolo(Map<String, dynamic> analise) async {
    final db = await _getDatabase();
    return await db.insert(_tabelaAnaliseSolo, analise);
  }
  
  // Importar análise de solo a partir de uma imagem
  Future<Map<String, dynamic>?> importarAnaliseSoloDeImagem(
    File imagemFile, 
    String talhaoId,
    BuildContext context
  ) async {
    try {
      // Processar a imagem
      final analiseSolo = await processarAnaliseImagem(imagemFile, talhaoId);
      
      if (analiseSolo != null) {
        // Salvar no banco de dados
        final id = await salvarAnaliseSolo(analiseSolo);
        analiseSolo['id'] = id;
        return analiseSolo;
      }
      return null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar análise: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }
}
