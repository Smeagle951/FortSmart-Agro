import 'package:flutter/material.dart';
import '../models/ai_diagnosis_result.dart';
import '../services/ai_diagnosis_service.dart';
import '../services/image_recognition_service.dart';
import '../../../utils/logger.dart';

class AIDiagnosisScreen extends StatefulWidget {
  const AIDiagnosisScreen({super.key});

  @override
  State<AIDiagnosisScreen> createState() => _AIDiagnosisScreenState();
}

class _AIDiagnosisScreenState extends State<AIDiagnosisScreen> {
  final AIDiagnosisService _diagnosisService = AIDiagnosisService();
  final ImageRecognitionService _imageService = ImageRecognitionService();
  
  final TextEditingController _cropController = TextEditingController();
  final List<String> _selectedSymptoms = [];
  final List<String> _availableSymptoms = [
    'Folhas com furos',
    'Manchas nas folhas',
    'Desfolhamento',
    'Grãos chochos',
    'Presença de insetos',
    'Redução no crescimento',
    'Pústulas nas folhas',
    'Secamento das folhas',
    'Lesões marrom-claras',
    'Furos irregulares',
  ];

  List<AIDiagnosisResult> _diagnosisResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedDiagnosisMethod = 'symptoms'; // 'symptoms' ou 'image'

  @override
  void initState() {
    super.initState();
    _cropController.text = 'Soja'; // Valor padrão
  }

  @override
  void dispose() {
    _cropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 Diagnóstico IA'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildMethodSelector(),
          Expanded(
            child: _selectedDiagnosisMethod == 'symptoms' 
                ? _buildSymptomsDiagnosis()
                : _buildImageDiagnosis(),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(bottom: BorderSide(color: Colors.green[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Método de Diagnóstico',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMethodCard(
                  'symptoms',
                  'Sintomas',
                  Icons.medical_services,
                  'Descreva os sintomas observados',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMethodCard(
                  'image',
                  'Imagem',
                  Icons.camera_alt,
                  'Tire uma foto da planta',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(String method, String title, IconData icon, String description) {
    final isSelected = _selectedDiagnosisMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDiagnosisMethod = method;
          _diagnosisResults.clear();
          _errorMessage = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[100] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.green[700] : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green[700] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.green[600] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsDiagnosis() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCropSelector(),
          const SizedBox(height: 24),
          _buildSymptomsSelector(),
          const SizedBox(height: 24),
          _buildDiagnosisButton(),
          const SizedBox(height: 24),
          if (_isLoading) _buildLoadingIndicator(),
          if (_errorMessage != null) _buildErrorMessage(),
          if (_diagnosisResults.isNotEmpty) _buildResultsList(),
        ],
      ),
    );
  }

  Widget _buildImageDiagnosis() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCropSelector(),
          const SizedBox(height: 24),
          _buildImageUploadSection(),
          const SizedBox(height: 24),
          if (_isLoading) _buildLoadingIndicator(),
          if (_errorMessage != null) _buildErrorMessage(),
          if (_diagnosisResults.isNotEmpty) _buildResultsList(),
        ],
      ),
    );
  }

  Widget _buildCropSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cultura',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _cropController.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.agriculture, color: Colors.green),
          ),
          items: ['Soja', 'Milho', 'Algodão', 'Café', 'Cana-de-açúcar']
              .map((crop) => DropdownMenuItem(value: crop, child: Text(crop)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _cropController.text = value ?? 'Soja';
            });
          },
        ),
      ],
    );
  }

  Widget _buildSymptomsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sintomas Observados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecione todos os sintomas que você observou:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableSymptoms.map((symptom) {
            final isSelected = _selectedSymptoms.contains(symptom);
            return FilterChip(
              label: Text(symptom),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSymptoms.add(symptom);
                  } else {
                    _selectedSymptoms.remove(symptom);
                  }
                });
              },
              selectedColor: Colors.green[100],
              checkmarkColor: Colors.green[700],
              backgroundColor: Colors.grey[100],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto da Planta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Toque para tirar uma foto',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _simulateImageDiagnosis,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tirar Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosisButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _selectedSymptoms.isNotEmpty ? _performDiagnosis : null,
        icon: const Icon(Icons.search),
        label: const Text(
          'Realizar Diagnóstico',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 16),
          Text(
            'Analisando...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados do Diagnóstico (${_diagnosisResults.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _diagnosisResults.length,
          itemBuilder: (context, index) {
            final result = _diagnosisResults[index];
            return _buildResultCard(result);
          },
        ),
      ],
    );
  }

  Widget _buildResultCard(AIDiagnosisResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.metadata['organismType'] == 'pest' 
                      ? Icons.bug_report 
                      : Icons.medical_services,
                  color: Colors.green[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.organismName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        result.scientificName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(result.confidence),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(result.confidence * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              result.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Estratégias de Manejo:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ...result.managementStrategies.map((strategy) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      strategy,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _performDiagnosis() async {
    if (_selectedSymptoms.isEmpty) {
      setState(() {
        _errorMessage = 'Selecione pelo menos um sintoma';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _diagnosisResults.clear();
    });

    try {
      final results = await _diagnosisService.diagnoseBySymptoms(
        symptoms: _selectedSymptoms,
        cropName: _cropController.text,
        confidenceThreshold: 0.3,
      );

      setState(() {
        _diagnosisResults = results;
        _isLoading = false;
      });

      if (results.isEmpty) {
        setState(() {
          _errorMessage = 'Nenhum diagnóstico encontrado para os sintomas informados';
        });
      }

    } catch (e) {
      Logger.error('Erro no diagnóstico: $e');
      setState(() {
        _errorMessage = 'Erro ao realizar diagnóstico: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _simulateImageDiagnosis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _diagnosisResults.clear();
    });

    try {
      // Simula tempo de processamento
      await Future.delayed(const Duration(seconds: 2));

      final results = await _imageService.recognizeOrganism(
        imagePath: '/path/to/simulated/image.jpg',
        cropName: _cropController.text,
        confidenceThreshold: 0.5,
      );

      setState(() {
        _diagnosisResults = results;
        _isLoading = false;
      });

      if (results.isEmpty) {
        setState(() {
          _errorMessage = 'Nenhum organismo reconhecido na imagem';
        });
      }

    } catch (e) {
      Logger.error('Erro no reconhecimento de imagem: $e');
      setState(() {
        _errorMessage = 'Erro ao processar imagem: $e';
        _isLoading = false;
      });
    }
  }
}
