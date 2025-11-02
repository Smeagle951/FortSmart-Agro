import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/soil_analysis_import_service.dart';

class SoilAnalysisImportScreen extends StatefulWidget {
  final String talhaoId;
  final String talhaoNome;
  final Function(Map<String, dynamic>) onAnalysisImported;

  const SoilAnalysisImportScreen({
    Key? key,
    required this.talhaoId,
    required this.talhaoNome,
    required this.onAnalysisImported,
  }) : super(key: key);

  @override
  State<SoilAnalysisImportScreen> createState() => _SoilAnalysisImportScreenState();
}

class _SoilAnalysisImportScreenState extends State<SoilAnalysisImportScreen> {
  final SoilAnalysisImportService _importService = SoilAnalysisImportService();
  bool _isLoading = false;
  bool _isProcessing = false;
  File? _selectedImage;
  Map<String, dynamic>? _processedAnalysis;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Importar Análise de Solo'),
        // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF228B22)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    elevation: 2.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Talhão: ${widget.talhaoNome}',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Importe uma análise de solo a partir de uma imagem ou tire uma foto do laudo.',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Seleção de imagem
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    elevation: 2.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selecione o Laudo de Análise',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // Botões para selecionar imagem
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _selecionarImagemGaleria,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Galeria'),
                                style: ElevatedButton.styleFrom(
                                  // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _selecionarImagemCamera,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Câmera'),
                                style: ElevatedButton.styleFrom(
                                  // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),

                          // Visualização da imagem selecionada
                          if (_selectedImage != null) ...[
                            const SizedBox(height: 16.0),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                _selectedImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _processarImagem,
                                icon: const Icon(Icons.document_scanner),
                                label: Text(_isProcessing ? 'Processando...' : 'Processar Laudo'),
                                style: ElevatedButton.styleFrom(
                                  // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Resultados processados
                  if (_processedAnalysis != null) ...[
                    Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 2.0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dados Extraídos da Análise',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            
                            // Tabela de dados da análise
                            Table(
                              border: TableBorder.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              children: [
                                _buildTableRow('pH', _processedAnalysis!['ph'].toString(), true),
                                _buildTableRow('Fósforo', '${_processedAnalysis!['fosforo']} mg/dm³', false),
                                _buildTableRow('Potássio', '${_processedAnalysis!['potassio']} cmolc/dm³', false),
                                _buildTableRow('Cálcio', '${_processedAnalysis!['calcio']} cmolc/dm³', false),
                                _buildTableRow('Magnésio', '${_processedAnalysis!['magnesio']} cmolc/dm³', false),
                                _buildTableRow('V%', '${_processedAnalysis!['v_porcentagem']}%', false),
                                _buildTableRow('Matéria Orgânica', '${_processedAnalysis!['materia_organica']}%', false),
                                _buildTableRow('CTC', '${_processedAnalysis!['ctc']} cmolc/dm³', false),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            
                            // Data da análise
                            Text(
                              'Data da Análise: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(_processedAnalysis!['data']))}',
                              style: const TextStyle(
                                fontSize: 14.0,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            
                            // Botão para salvar
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _salvarAnalise,
                                icon: const Icon(Icons.save),
                                label: const Text('Salvar Análise'),
                                style: ElevatedButton.styleFrom(
                                  // backgroundColor: const Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // Construir linhas da tabela
  TableRow _buildTableRow(String label, String value, bool isHeader) {
    return TableRow(
      decoration: isHeader
          ? BoxDecoration(color: Colors.grey.shade100)
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // Selecionar imagem da galeria
  Future<void> _selecionarImagemGaleria() async {
    setState(() => _isLoading = true);
    
    try {
      final imagem = await _importService.selecionarImagemGaleria();
      if (imagem != null) {
        setState(() {
          _selectedImage = imagem;
          _processedAnalysis = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Selecionar imagem da câmera
  Future<void> _selecionarImagemCamera() async {
    setState(() => _isLoading = true);
    
    try {
      final imagem = await _importService.selecionarImagemCamera();
      if (imagem != null) {
        setState(() {
          _selectedImage = imagem;
          _processedAnalysis = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao capturar imagem: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Processar a imagem selecionada
  Future<void> _processarImagem() async {
    if (_selectedImage == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final analise = await _importService.processarAnaliseImagem(
        _selectedImage!,
        widget.talhaoId,
      );
      
      if (analise != null) {
        setState(() => _processedAnalysis = analise);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar imagem: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Salvar a análise processada
  Future<void> _salvarAnalise() async {
    if (_processedAnalysis == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Salvar no banco de dados
      final analiseId = await _importService.salvarAnaliseSolo(_processedAnalysis!);
      
      if (analiseId > 0) {
        // Notificar a tela pai que uma nova análise foi importada
        widget.onAnalysisImported(_processedAnalysis!);
        
        // Exibir mensagem de sucesso
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Análise de solo importada com sucesso!'),
            // backgroundColor: Color(0xFF228B22), // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
        
        // Voltar para a tela anterior
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar análise: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
