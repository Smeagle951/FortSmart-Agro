import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../constants/app_colors.dart';
import '../widgets/custom_text_form_field.dart';
import '../services/soil_compaction_service.dart';
import '../models/soil_compaction_model.dart';
import '../repositories/soil_compaction_repository.dart';
import '../../../widgets/loading_overlay.dart';

class SimpleCompactionScreen extends StatefulWidget {
  const SimpleCompactionScreen({Key? key}) : super(key: key);

  @override
  State<SimpleCompactionScreen> createState() => _SimpleCompactionScreenState();
}

class _SimpleCompactionScreenState extends State<SimpleCompactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pesoController = TextEditingController();
  final _numGolpesController = TextEditingController();
  final _distanciaController = TextEditingController();
  final _profundidadeController = TextEditingController();
  
  
  double? _latitude;
  double? _longitude;
  
  double? _resultadoRP;
  String? _interpretacao;
  Color? _corInterpretacao;
  
  bool _isLoading = false;
  bool _isCalculated = false;
  
  List<String> _fotos = [];
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _pesoController.dispose();
    _numGolpesController.dispose();
    _distanciaController.dispose();
    _profundidadeController.dispose();
    super.dispose();
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível obter a localização atual.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  void _calcularCompactacao() {
    if (_formKey.currentState!.validate()) {
      final peso = double.parse(_pesoController.text);
      final numGolpes = int.parse(_numGolpesController.text);
      final distancia = double.parse(_distanciaController.text) / 100; // Convertendo cm para m
      
      final resultadoRP = SoilCompactionService.calcularRPSimples(
        pesoMartelo: peso,
        numGolpes: numGolpes,
        distanciaTotal: distancia,
      );
      
      final interpretacao = SoilCompactionService.interpretarRP(resultadoRP);
      final corInterpretacao = SoilCompactionService.getCorInterpretacao(interpretacao);
      
      setState(() {
        _resultadoRP = resultadoRP;
        _interpretacao = interpretacao;
        _corInterpretacao = corInterpretacao;
        _isCalculated = true;
      });
    }
  }
  
  Future<void> _tirarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    
    if (image != null) {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final directory = await getApplicationDocumentsDirectory();
      final compressedFile = await _compressImage(
        File(image.path),
        '${directory.path}/soil_compaction_${timestamp}.jpg',
      );
      
      setState(() {
        _fotos.add(compressedFile.path);
      });
    }
  }
  
  Future<File> _compressImage(File file, String targetPath) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 85,
    );
    
    return File(result!.path);
  }
  
  Future<void> _salvarCompactacao() async {
    if (_resultadoRP == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calcule a compactação antes de salvar.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final compactacao = SoilCompactionModel(
        talhaoId: 0, // Sem talhão específico
        safraId: 0, // Sem safra específica
        data: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        tipoCalculo: 'simples',
        pesoMartelo: double.parse(_pesoController.text),
        alturaQueda: 0.0, // Não aplicável ao método simples
        diametroPonteira: 0.0, // Não aplicável ao método simples
        numGolpes: int.parse(_numGolpesController.text),
        distanciaTotal: double.parse(_distanciaController.text) / 100, // Convertendo cm para m
        resultadoRp: _resultadoRP!,
        interpretacao: _interpretacao!,
        profundidade: double.parse(_profundidadeController.text),
        fotoCaminho: _fotos.isNotEmpty ? _fotos.join(',') : null,
      );
      
      final repository = Provider.of<SoilCompactionRepository>(context, listen: false);
      final id = await repository.insert(compactacao);
      
      setState(() {
        _isLoading = false;
      });
      
      if (id > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compactação salva com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Limpar o formulário
        _formKey.currentState!.reset();
        _pesoController.clear();
        _numGolpesController.clear();
        _distanciaController.clear();
        _profundidadeController.clear();
        setState(() {
          _resultadoRP = null;
          _interpretacao = null;
          _corInterpretacao = null;
          _isCalculated = false;
          _fotos = [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar a compactação.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Cálculo Simples por Impacto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Formulário de Cálculo
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cardBackground,
                        AppColors.surfaceColor,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calculate,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Parâmetros do Cálculo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          controller: _pesoController,
                          label: 'Peso do Martelo (kg)',
                          hintText: 'Ex: 4.0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, informe o peso do martelo';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Informe um valor numérico válido';
                            }
                            return null;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          controller: _numGolpesController,
                          label: 'Número de Golpes',
                          hintText: 'Ex: 10',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, informe o número de golpes';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Informe um valor inteiro válido';
                            }
                            return null;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          controller: _distanciaController,
                          label: 'Distância Total de Penetração (cm)',
                          hintText: 'Ex: 15.5',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, informe a distância de penetração';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Informe um valor numérico válido';
                            }
                            return null;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          controller: _profundidadeController,
                          label: 'Profundidade da Medição (cm)',
                          hintText: 'Ex: 20.0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, informe a profundidade da medição';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Informe um valor numérico válido';
                            }
                            return null;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _calcularCompactacao,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Calcular Compactação',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              if (_isCalculated) ...[
                const SizedBox(height: 20),
                
                // Resultado do Cálculo
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          _corInterpretacao!.withOpacity(0.1),
                          _corInterpretacao!.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _corInterpretacao,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.analytics,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Resultado do Cálculo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Resistência à Penetração:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_resultadoRP!.toStringAsFixed(2)} MPa',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _corInterpretacao,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Interpretação:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _corInterpretacao,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _interpretacao!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Fotos
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cardBackground,
                          AppColors.surfaceColor,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Fotos da Área',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_fotos.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.textHint,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Nenhuma foto adicionada',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        if (_fotos.isNotEmpty)
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _fotos.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              child: InteractiveViewer(
                                                child: Image.file(
                                                  File(_fotos[index]),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            File(_fotos[index]),
                                            height: 120,
                                            width: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _fotos.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _tirarFoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Adicionar Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Botão Salvar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _salvarCompactacao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Salvar no Histórico',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}