import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/diagnosis_feedback.dart';
import '../services/diagnosis_feedback_service.dart';
import '../utils/logger.dart';

/// Dialog para confirmar ou corrigir um diagnóstico/infestação
/// Parte do sistema de aprendizado contínuo
class DiagnosisConfirmationDialog extends StatefulWidget {
  final String farmId;
  final String cropName;
  final String systemPredictedOrganism;
  final double systemPredictedSeverity;
  final String systemSeverityLevel;
  final List<String> systemSymptoms;
  final double? systemConfidence;
  final String technicianName;
  final String? diagnosisId;
  final String? monitoringId;
  final String? alertId;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final VoidCallback? onFeedbackSaved;

  const DiagnosisConfirmationDialog({
    Key? key,
    required this.farmId,
    required this.cropName,
    required this.systemPredictedOrganism,
    required this.systemPredictedSeverity,
    required this.systemSeverityLevel,
    required this.systemSymptoms,
    this.systemConfidence,
    required this.technicianName,
    this.diagnosisId,
    this.monitoringId,
    this.alertId,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.onFeedbackSaved,
  }) : super(key: key);

  @override
  State<DiagnosisConfirmationDialog> createState() => _DiagnosisConfirmationDialogState();
}

class _DiagnosisConfirmationDialogState extends State<DiagnosisConfirmationDialog> {
  bool? _userConfirmed;
  String? _correctedOrganism;
  double _correctedSeverity = 50.0;
  String _correctedSeverityLevel = 'moderado';
  final _notesController = TextEditingController();
  final _correctionReasonController = TextEditingController();
  bool _isLoading = false;

  // Lista de organismos (pode ser carregada do banco)
  final List<String> _organisms = [
    'Percevejo-marrom',
    'Percevejo-pequeno',
    'Percevejo-verde',
    'Lagarta-da-soja',
    'Lagarta-do-cartucho',
    'Mosca-branca',
    'Ferrugem asiática',
    'Mancha-alvo',
    'Mofo-branco',
    'Nematoide',
  ];

  @override
  void initState() {
    super.initState();
    _correctedSeverity = widget.systemPredictedSeverity;
    _correctedSeverityLevel = widget.systemSeverityLevel;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _correctionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.psychology,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Confirmação de Diagnóstico'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mostrar diagnóstico do sistema
              _buildSystemDiagnosis(),
              
              const Divider(height: 32),
              
              // Pergunta de confirmação
              _buildConfirmationQuestion(),
              
              // Se não confirmou, mostrar campos de correção
              if (_userConfirmed == false) ...[
                const SizedBox(height: 16),
                _buildCorrectionForm(),
              ],
              
              // Campo de observações (sempre visível)
              const SizedBox(height: 16),
              _buildNotesField(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _userConfirmed == null || _isLoading
              ? null
              : _saveFeedback,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar Feedback'),
        ),
      ],
    );
  }

  Widget _buildSystemDiagnosis() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Diagnóstico do Sistema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Organismo:', widget.systemPredictedOrganism),
            _buildInfoRow(
              'Severidade:',
              '${widget.systemPredictedSeverity.toStringAsFixed(1)}% (${widget.systemSeverityLevel})',
            ),
            if (widget.systemConfidence != null)
              _buildInfoRow(
                'Confiança:',
                '${(widget.systemConfidence! * 100).toStringAsFixed(1)}%',
              ),
            if (widget.systemSymptoms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sintomas detectados:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...widget.systemSymptoms.map((symptom) => Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                          child: Row(
                            children: [
                              Icon(Icons.fiber_manual_record,
                                  size: 8, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(child: Text(symptom)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Este diagnóstico está correto?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _userConfirmed = true),
                icon: const Icon(Icons.check_circle),
                label: const Text('Sim, correto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userConfirmed == true
                      ? Colors.green
                      : Colors.grey.shade300,
                  foregroundColor:
                      _userConfirmed == true ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _userConfirmed = false),
                icon: const Icon(Icons.cancel),
                label: const Text('Não, corrigir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userConfirmed == false
                      ? Colors.red
                      : Colors.grey.shade300,
                  foregroundColor:
                      _userConfirmed == false ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCorrectionForm() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Correção dos Dados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Organismo correto
            const Text(
              'Qual é o organismo correto?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _correctedOrganism,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Selecione o organismo'),
              items: _organisms.map((org) {
                return DropdownMenuItem(value: org, child: Text(org));
              }).toList(),
              onChanged: (value) => setState(() => _correctedOrganism = value),
            ),
            
            const SizedBox(height: 16),
            
            // Severidade real
            const Text(
              'Qual é a severidade real?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _correctedSeverity,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_correctedSeverity.toStringAsFixed(0)}%',
                    onChanged: (value) {
                      setState(() {
                        _correctedSeverity = value;
                        _correctedSeverityLevel = _getSeverityLevel(value);
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '${_correctedSeverity.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSeverityColor(_correctedSeverity),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _correctedSeverityLevel.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Motivo da correção
            const Text(
              'Por que o diagnóstico estava errado?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _correctionReasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: Sintomas eram diferentes, estágio errado...',
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observações adicionais (opcional)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Adicione informações que possam ajudar o sistema...',
            contentPadding: EdgeInsets.all(12),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  String _getSeverityLevel(double severity) {
    if (severity <= 25) return 'baixo';
    if (severity <= 50) return 'moderado';
    if (severity <= 75) return 'alto';
    return 'critico';
  }

  Color _getSeverityColor(double severity) {
    if (severity <= 25) return Colors.green;
    if (severity <= 50) return Colors.yellow.shade700;
    if (severity <= 75) return Colors.orange;
    return Colors.red;
  }

  Future<void> _saveFeedback() async {
    // Validações
    if (!_userConfirmed! && _correctedOrganism == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione o organismo correto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final feedback = DiagnosisFeedback(
        id: const Uuid().v4(),
        farmId: widget.farmId,
        diagnosisId: widget.diagnosisId,
        monitoringId: widget.monitoringId,
        alertId: widget.alertId,
        cropName: widget.cropName,
        imagePath: widget.imagePath,
        systemPredictedOrganism: widget.systemPredictedOrganism,
        systemPredictedSeverity: widget.systemPredictedSeverity,
        systemSeverityLevel: widget.systemSeverityLevel,
        systemConfidence: widget.systemConfidence,
        systemSymptoms: widget.systemSymptoms,
        userConfirmed: _userConfirmed!,
        userCorrectedOrganism: _correctedOrganism,
        userCorrectedSeverity: _userConfirmed! ? null : _correctedSeverity,
        userCorrectedSeverityLevel:
            _userConfirmed! ? null : _correctedSeverityLevel,
        userNotes: _notesController.text.isEmpty ? null : _notesController.text,
        userCorrectionReason: _correctionReasonController.text.isEmpty
            ? null
            : _correctionReasonController.text,
        diagnosisDate: DateTime.now(),
        feedbackDate: DateTime.now(),
        technicianName: widget.technicianName,
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

      final service = DiagnosisFeedbackService();
      final success = await service.saveFeedback(feedback);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '✅ Feedback salvo! Obrigado por ajudar a melhorar nosso sistema.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        widget.onFeedbackSaved?.call();
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Falha ao salvar feedback');
      }
    } catch (e) {
      Logger.error('❌ Erro ao salvar feedback: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar feedback: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

