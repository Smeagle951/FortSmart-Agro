import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

import '../models/soil_laboratory_sample_model.dart';
import '../models/soil_compaction_point_model.dart';
import '../services/soil_smart_engine.dart';
import '../constants/app_colors.dart';

/// Tela para upload e processamento de laudos laboratoriais
class SoilLaboratoryUploadScreen extends StatefulWidget {
  final int pointId;
  final String pointCode;

  const SoilLaboratoryUploadScreen({
    Key? key,
    required this.pointId,
    required this.pointCode,
  }) : super(key: key);

  @override
  State<SoilLaboratoryUploadScreen> createState() => _SoilLaboratoryUploadScreenState();
}

class _SoilLaboratoryUploadScreenState extends State<SoilLaboratoryUploadScreen> {
  File? _arquivoSelecionado;
  String? _nomeArquivo;
  String _tipoArquivo = 'CSV';
  bool _isProcessando = false;
  SoilLaboratorySampleModel? _amostraProcessada;
  Map<String, dynamic>? _analiseCruzada;

  final List<String> _tiposArquivo = ['CSV', 'PDF', 'Excel'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Upload Laudo - ${widget.pointCode}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildUploadCard(),
            const SizedBox(height: 16),
            if (_amostraProcessada != null) _buildResultadoCard(),
            const SizedBox(height: 16),
            if (_analiseCruzada != null) _buildAnaliseCruzadaCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.blue.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
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
                    Icons.science,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Upload de Laudo Laboratorial',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '📄 Formatos suportados: CSV, PDF, Excel\n'
              '🧬 Análise automática de parâmetros químicos\n'
              '🔬 Integração com SoilSmart Engine\n'
              '💡 Recomendações baseadas em análise cruzada',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.upload_file,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Selecionar Arquivo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tipo de arquivo
            DropdownButtonFormField<String>(
              value: _tipoArquivo,
              decoration: const InputDecoration(
                labelText: 'Tipo de Arquivo',
                border: OutlineInputBorder(),
              ),
              items: _tiposArquivo.map((String value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _tipoArquivo = newValue!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Botão de seleção
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selecionarArquivo,
                icon: const Icon(Icons.folder_open),
                label: Text(_arquivoSelecionado == null 
                    ? 'Selecionar Arquivo' 
                    : 'Trocar Arquivo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            if (_arquivoSelecionado != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _nomeArquivo!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${(_arquivoSelecionado!.lengthSync() / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botão de processamento
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessando ? null : _processarArquivo,
                  icon: _isProcessando 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.analytics),
                  label: Text(_isProcessando ? 'Processando...' : 'Processar Laudo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoCard() {
    if (_amostraProcessada == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Resultado do Processamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Parâmetros principais
            _buildParametroRow('pH', _amostraProcessada!.ph?.toStringAsFixed(2), ''),
            _buildParametroRow('Matéria Orgânica', _amostraProcessada!.materiaOrganica?.toStringAsFixed(2), '%'),
            _buildParametroRow('Fósforo', _amostraProcessada!.fosforo?.toStringAsFixed(1), 'mg/dm³'),
            _buildParametroRow('Potássio', _amostraProcessada!.potassio?.toStringAsFixed(1), 'mg/dm³'),
            _buildParametroRow('Cálcio', _amostraProcessada!.calcio?.toStringAsFixed(2), 'cmolc/dm³'),
            _buildParametroRow('Magnésio', _amostraProcessada!.magnesio?.toStringAsFixed(2), 'cmolc/dm³'),
            _buildParametroRow('CTC', _amostraProcessada!.ctc?.toStringAsFixed(2), 'cmolc/dm³'),
            
            const Divider(height: 24),
            
            // Classificação
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCorClassificacao(_amostraProcessada!.classificacaoFertilidade ?? '').withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getCorClassificacao(_amostraProcessada!.classificacaoFertilidade ?? ''),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assessment,
                    color: _getCorClassificacao(_amostraProcessada!.classificacaoFertilidade ?? ''),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Classificação: ${_amostraProcessada!.classificacaoFertilidade}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getCorClassificacao(_amostraProcessada!.classificacaoFertilidade ?? ''),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnaliseCruzadaCard() {
    if (_analiseCruzada == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    Icons.psychology,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Análise Cruzada - SoilSmart Engine',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Diagnósticos principais
            if ((_analiseCruzada!['diagnosticos_principais'] as List).isNotEmpty) ...[
              const Text(
                'Diagnósticos Principais:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(_analiseCruzada!['diagnosticos_principais'] as List).map((diagnostico) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(diagnostico)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Recomendações prioritárias
            if ((_analiseCruzada!['recomendacoes_prioritarias'] as List).isNotEmpty) ...[
              const Text(
                'Recomendações Prioritárias:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(_analiseCruzada!['recomendacoes_prioritarias'] as List).map((recomendacao) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(recomendacao)),
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

  Widget _buildParametroRow(String parametro, String? valor, String unidade) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              parametro,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(': '),
          Text(
            valor ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (valor != null && unidade.isNotEmpty)
            Text(' $unidade', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getCorClassificacao(String classificacao) {
    if (classificacao.contains('Alta')) return Colors.green;
    if (classificacao.contains('Média')) return Colors.blue;
    if (classificacao.contains('Baixa')) return Colors.orange;
    return Colors.red;
  }

  Future<void> _selecionarArquivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _tipoArquivo == 'CSV' 
            ? ['csv'] 
            : _tipoArquivo == 'PDF' 
                ? ['pdf'] 
                : ['xlsx', 'xls'],
      );

      if (result != null) {
        setState(() {
          _arquivoSelecionado = File(result.files.single.path!);
          _nomeArquivo = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
      );
    }
  }

  Future<void> _processarArquivo() async {
    if (_arquivoSelecionado == null) return;

    setState(() => _isProcessando = true);

    try {
      // Simula processamento do arquivo
      await Future.delayed(const Duration(seconds: 2));

      // Cria amostra simulada (em produção, faria parsing real do arquivo)
      final amostra = SoilLaboratorySampleModel(
        pointId: widget.pointId,
        codigoAmostra: 'AMO-${DateTime.now().millisecondsSinceEpoch}',
        dataColeta: DateTime.now().subtract(const Duration(days: 7)),
        dataAnalise: DateTime.now(),
        laboratorio: 'Laboratório Simulado',
        metodologia: 'Embrapa',
        ph: 5.2,
        materiaOrganica: 2.8,
        fosforo: 15.5,
        potassio: 120.0,
        calcio: 1.8,
        magnesio: 0.6,
        ctc: 6.2,
        argila: 35.0,
        silte: 25.0,
        areia: 40.0,
        arquivoOriginal: _nomeArquivo,
        dadosBrutos: jsonEncode({'processado': true}),
      );

      // Análise cruzada com SoilSmart Engine
      final analise = SoilSmartEngine.analiseCruzadaCompleta(
        ponto: SoilCompactionPointModel(
          id: widget.pointId,
          pointCode: widget.pointCode,
          talhaoId: 1,
          dataColeta: DateTime.now(),
          latitude: 0.0,
          longitude: 0.0,
          profundidadeInicio: 0,
          profundidadeFim: 20,
          penetrometria: 2.8, // Simulado
        ),
        amostraQuimica: amostra,
      );

      setState(() {
        _amostraProcessada = amostra;
        _analiseCruzada = analise;
        _isProcessando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Laudo processado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() => _isProcessando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar arquivo: $e')),
      );
    }
  }
}
