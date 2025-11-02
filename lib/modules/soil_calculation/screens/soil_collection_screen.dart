import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/soil_compaction_point_model.dart';
import '../models/soil_diagnostic_model.dart';
import '../repositories/soil_compaction_point_repository.dart';
import '../repositories/soil_diagnostic_repository.dart';
import '../services/soil_recommendation_service.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_text_form_field.dart';

/// Tela de coleta de dados no campo
class SoilCollectionScreen extends StatefulWidget {
  final SoilCompactionPointModel ponto;
  final int talhaoId;
  final String? nomeTalhao;

  const SoilCollectionScreen({
    Key? key,
    required this.ponto,
    required this.talhaoId,
    this.nomeTalhao,
  }) : super(key: key);

  @override
  State<SoilCollectionScreen> createState() => _SoilCollectionScreenState();
}

class _SoilCollectionScreenState extends State<SoilCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _penetrometriaController = TextEditingController();
  final _umidadeController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _codigoAmostraController = TextEditingController();

  String? _texturaEscolhida;
  String? _estruturaEscolhida;
  bool _amostraColetada = false;
  List<String> _diagnosticosSelecionados = [];
  List<String> _fotosPath = [];
  bool _isLoading = false;
  Position? _currentPosition;

  final List<String> _texturas = ['Argiloso', 'Arenoso', 'Franco', 'Siltoso'];
  final List<String> _estruturas = ['Boa', 'Moderada', 'Ruim'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _penetrometriaController.text = widget.ponto.penetrometria?.toString() ?? '';
    _umidadeController.text = widget.ponto.umidade?.toString() ?? '';
    _texturaEscolhida = widget.ponto.textura;
    _estruturaEscolhida = widget.ponto.estrutura;
  }

  @override
  void dispose() {
    _penetrometriaController.dispose();
    _umidadeController.dispose();
    _observacoesController.dispose();
    _codigoAmostraController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
    }
  }

  Future<void> _tirarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _fotosPath.add(image.path);
      });
    }
  }

  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final penetrometria = double.tryParse(_penetrometriaController.text);
      final umidade = double.tryParse(_umidadeController.text);

      // Atualiza o ponto com os novos dados
      final pontoAtualizado = widget.ponto.copyWith(
        penetrometria: penetrometria,
        umidade: umidade,
        textura: _texturaEscolhida,
        estrutura: _estruturaEscolhida,
        observacoes: _observacoesController.text,
        fotosPath: _fotosPath,
        amostraColetada: _amostraColetada,
        codigoAmostra: _amostraColetada ? _codigoAmostraController.text : null,
        diagnosticos: _diagnosticosSelecionados,
        latitude: _currentPosition?.latitude ?? widget.ponto.latitude,
        longitude: _currentPosition?.longitude ?? widget.ponto.longitude,
      );

      final repository = Provider.of<SoilCompactionPointRepository>(
        context,
        listen: false,
      );

      await repository.update(pontoAtualizado);

      // Salva diagnósticos se houver
      if (_diagnosticosSelecionados.isNotEmpty) {
        await _salvarDiagnosticos(pontoAtualizado.id!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dados salvos com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarDiagnosticos(int pointId) async {
    final diagnosticRepo = Provider.of<SoilDiagnosticRepository>(
      context,
      listen: false,
    );

    for (var tipo in _diagnosticosSelecionados) {
      String severidade = 'Média';
      
      // Define severidade baseado em compactação
      if (tipo == TipoDiagnostico.compactacao) {
        final penetrometria = double.tryParse(_penetrometriaController.text);
        if (penetrometria != null) {
          if (penetrometria > 2.5) severidade = 'Crítica';
          else if (penetrometria > 2.0) severidade = 'Alta';
          else if (penetrometria > 1.5) severidade = 'Média';
          else severidade = 'Baixa';
        }
      }

      final diagnostico = SoilDiagnosticModel(
        pointId: pointId,
        tipoDiagnostico: tipo,
        severidade: severidade,
        dataIdentificacao: DateTime.now(),
        observacoes: _observacoesController.text,
        fotosPath: _fotosPath,
        recomendacoes: SoilRecommendationService.gerarRecomendacoes(
          tipoDiagnostico: tipo,
          severidade: severidade,
        ),
      );

      await diagnosticRepo.insert(diagnostico);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Ponto ${widget.ponto.pointCode}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações do Ponto
              _buildInfoCard(),
              const SizedBox(height: 16),

              // Dados de Medição
              _buildMedicaoCard(),
              const SizedBox(height: 16),

              // Características do Solo
              _buildCaracteristicasCard(),
              const SizedBox(height: 16),

              // Diagnósticos
              _buildDiagnosticosCard(),
              const SizedBox(height: 16),

              // Amostra
              _buildAmostraCard(),
              const SizedBox(height: 16),

              // Fotos
              _buildFotosCard(),
              const SizedBox(height: 16),

              // Observações
              _buildObservacoesCard(),
              const SizedBox(height: 24),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _salvarDados,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Salvar Dados da Coleta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
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
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informações do Ponto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Código', widget.ponto.pointCode),
            _buildInfoRow('Talhão', widget.nomeTalhao ?? 'N/A'),
            _buildInfoRow(
              'Coordenadas',
              '${widget.ponto.latitude.toStringAsFixed(6)}, ${widget.ponto.longitude.toStringAsFixed(6)}',
            ),
            _buildInfoRow(
              'Profundidade',
              '${widget.ponto.profundidadeInicio.toInt()}-${widget.ponto.profundidadeFim.toInt()} cm',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicaoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  child: const Icon(Icons.assessment, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Dados de Medição',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextFormField(
              controller: _penetrometriaController,
              label: 'Penetrometria (MPa) *',
              hintText: 'Ex: 2.5',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                final val = double.tryParse(value);
                if (val == null || val < 0) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CustomTextFormField(
              controller: _umidadeController,
              label: 'Umidade (%)',
              hintText: 'Ex: 25',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaracteristicasCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.brown,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.layers, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Características do Solo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _texturaEscolhida,
              decoration: const InputDecoration(
                labelText: 'Textura',
                border: OutlineInputBorder(),
              ),
              items: _texturas.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _texturaEscolhida = newValue;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _estruturaEscolhida,
              decoration: const InputDecoration(
                labelText: 'Estrutura',
                border: OutlineInputBorder(),
              ),
              items: _estruturas.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _estruturaEscolhida = newValue;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticosCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Diagnósticos Identificados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TipoDiagnostico.todos.map((tipo) {
                final isSelected = _diagnosticosSelecionados.contains(tipo);
                return FilterChip(
                  label: Text(tipo),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _diagnosticosSelecionados.add(tipo);
                      } else {
                        _diagnosticosSelecionados.remove(tipo);
                      }
                    });
                  },
                  selectedColor: Colors.orange.withOpacity(0.3),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmostraCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  child: const Icon(Icons.science, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Amostra de Solo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Amostra Coletada'),
              value: _amostraColetada,
              onChanged: (bool value) {
                setState(() {
                  _amostraColetada = value;
                });
              },
            ),
            if (_amostraColetada) ...[
              const SizedBox(height: 12),
              CustomTextFormField(
                controller: _codigoAmostraController,
                label: 'Código da Amostra',
                hintText: 'Ex: AMO-001',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFotosCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Fotos do Ponto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_fotosPath.isEmpty)
              const Text('Nenhuma foto adicionada', style: TextStyle(color: Colors.grey)),
            if (_fotosPath.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fotosPath.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_fotosPath[index]),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _fotosPath.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _tirarFoto,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Adicionar Foto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservacoesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notes, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Observações',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                hintText: 'Descreva observações adicionais...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

