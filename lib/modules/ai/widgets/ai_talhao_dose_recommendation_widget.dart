import 'package:flutter/material.dart';
import '../services/ai_dose_recommendation_service.dart';
import '../../../utils/logger.dart';

/// Widget de Recomendações de Dose da IA por Talhão
/// Integra com o sistema de IA FortSmart existente
class AITalhaoDoseRecommendationWidget extends StatefulWidget {
  final TalhaoDoseRecommendation recommendation;
  final Function(String organismName, List<DoseRecommendation> doses)? onAcceptRecommendation;
  final Function(String organismName, List<DoseRecommendation> doses)? onEditRecommendation;
  final Function(String organismName, String feedback)? onLearningFeedback;
  
  const AITalhaoDoseRecommendationWidget({
    Key? key,
    required this.recommendation,
    this.onAcceptRecommendation,
    this.onEditRecommendation,
    this.onLearningFeedback,
  }) : super(key: key);
  
  @override
  State<AITalhaoDoseRecommendationWidget> createState() => _AITalhaoDoseRecommendationWidgetState();
}

class _AITalhaoDoseRecommendationWidgetState extends State<AITalhaoDoseRecommendationWidget> {
  final Map<String, String> _userFeedback = {};
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do talhão com IA
            _buildAIHeader(),
            SizedBox(height: 16),
            
            // Indicador de confiança da IA
            _buildAIConfidenceIndicator(),
            SizedBox(height: 16),
            
            // Organismos detectados pela IA
            if (widget.recommendation.organisms.isNotEmpty) ...[
              Text(
                'Organismos Detectados pela IA (${widget.recommendation.totalOrganisms}):',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12),
              
              // Lista de organismos com recomendações da IA
              ...widget.recommendation.organisms.map((organism) =>
                _buildAIOrganismCard(organism),
              ).toList(),
            ] else ...[
              _buildNoOrganismsFound(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAIHeader() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getPriorityColor(widget.recommendation.priorityLevel).withOpacity(0.1),
            _getPriorityColor(widget.recommendation.priorityLevel).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getPriorityColor(widget.recommendation.priorityLevel).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getPriorityColor(widget.recommendation.priorityLevel).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.psychology,
              color: _getPriorityColor(widget.recommendation.priorityLevel),
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Talhão: ${widget.recommendation.talhaoName}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getPriorityColor(widget.recommendation.priorityLevel),
                  ),
                ),
                Text(
                  'Cultura: ${widget.recommendation.cropName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'IA FortSmart • Confiança: ${(widget.recommendation.aiConfidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPriorityColor(widget.recommendation.priorityLevel),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.recommendation.priorityLevel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAIConfidenceIndicator() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Confiança da IA: ${(widget.recommendation.aiConfidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
          LinearProgressIndicator(
            value: widget.recommendation.aiConfidence,
            backgroundColor: Colors.blue.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAIOrganismCard(OrganismDoseRecommendation organism) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do organismo com IA
          Row(
            children: [
              Icon(
                _getOrganismIcon(organism.organismType),
                color: _getInfestationColor(organism.infestationLevel),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  organism.organismName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getInfestationColor(organism.infestationLevel).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getInfestationColor(organism.infestationLevel).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  '${organism.infestationIndex.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getInfestationColor(organism.infestationLevel),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Informações da IA
          Row(
            children: [
              Text(
                'Nível: ${organism.infestationLevel}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(width: 16),
              Text(
                'Prioridade: ${organism.priority}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getPriorityColor(organism.priority),
                ),
              ),
              SizedBox(width: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Text(
                  'IA: ${(organism.aiConfidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          
          // Fatores de risco
          if (organism.riskFactors.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Fatores de Risco (IA):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
            SizedBox(height: 4),
            ...organism.riskFactors.map((factor) =>
              Padding(
                padding: EdgeInsets.only(left: 16, bottom: 2),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        factor,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ],
          
          // Recomendações de dose da IA
          if (organism.doseRecommendations.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Recomendações da IA:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
              ),
            ),
            SizedBox(height: 8),
            ...organism.doseRecommendations.map((dose) =>
              _buildAIDoseCard(dose, organism.organismName),
            ).toList(),
          ],
          
          // Janela de aplicação da IA
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Janela de Aplicação (IA):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Época: ${organism.applicationWindow['epoca']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Horário ótimo: ${organism.optimalApplicationTime}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Condições: ${organism.applicationWindow['condicoes_ideais']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (organism.applicationWindow['ai_recommendation'] != null)
                  Text(
                    '${organism.applicationWindow['ai_recommendation']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAIDoseCard(DoseRecommendation dose, String organismName) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: Colors.purple, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  dose.defensivoName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: dose.urgency == 'URGENTE' 
                      ? Colors.red.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: dose.urgency == 'URGENTE' 
                        ? Colors.red.withOpacity(0.5)
                        : Colors.blue.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  dose.urgency,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: dose.urgency == 'URGENTE' ? Colors.red : Colors.blue,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Text(
                  'IA: ${(dose.aiConfidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Dose: ${dose.finalDose.toStringAsFixed(2)} ${dose.concentration}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            'Volume: ${dose.volumeCalda}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            'Intervalo: ${dose.intervaloSeguranca}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          
          if (dose.observacoes.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              'Observações: ${dose.observacoes}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          // Botões de ação com sistema de aprendizado
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(dose, organismName),
                  icon: Icon(Icons.edit, size: 14),
                  label: Text('Editar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue),
                    padding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acceptRecommendation(dose, organismName),
                  icon: Icon(Icons.check, size: 14),
                  label: Text('Aceitar', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoOrganismsFound() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nenhum organismo detectado pela IA - Talhão saudável',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Métodos de ação com sistema de aprendizado
  void _acceptRecommendation(DoseRecommendation dose, String organismName) {
    Logger.info('✅ [IA] Usuário aceitou recomendação: ${dose.defensivoName} para $organismName');
    
    widget.onAcceptRecommendation?.call(organismName, [dose]);
    
    // Enviar feedback positivo para a IA
    widget.onLearningFeedback?.call(organismName, 'ACCEPTED');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recomendação aceita! IA será melhorada com seu feedback.'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _showEditDialog(DoseRecommendation dose, String organismName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Recomendação da IA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Organismo: $organismName'),
            Text('Defensivo: ${dose.defensivoName}'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Feedback para a IA',
                hintText: 'Explique o que precisa ser ajustado...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                _userFeedback[organismName] = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editRecommendation(dose, organismName);
            },
            child: Text('Enviar Feedback'),
          ),
        ],
      ),
    );
  }
  
  void _editRecommendation(DoseRecommendation dose, String organismName) {
    final feedback = _userFeedback[organismName] ?? '';
    
    Logger.info('✏️ [IA] Usuário editou recomendação: ${dose.defensivoName} para $organismName');
    Logger.info('💬 [IA] Feedback: $feedback');
    
    widget.onEditRecommendation?.call(organismName, [dose]);
    
    // Enviar feedback para a IA aprender
    widget.onLearningFeedback?.call(organismName, feedback);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Feedback enviado! A IA aprenderá com suas sugestões.'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  // Métodos auxiliares para cores e ícones
  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICO': return Colors.red;
      case 'ALTO': return Colors.orange;
      case 'MÉDIO': return Colors.yellow[700]!;
      case 'BAIXO': return Colors.green;
      case 'CRITICA': return Colors.red;
      case 'ALTA': return Colors.orange;
      case 'MEDIA': return Colors.yellow[700]!;
      case 'BAIXA': return Colors.green;
      default: return Colors.grey;
    }
  }
  
  Color _getInfestationColor(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICO': return Colors.red;
      case 'ALTO': return Colors.orange;
      case 'MEDIO': return Colors.yellow[700]!;
      case 'BAIXO': return Colors.green;
      default: return Colors.grey;
    }
  }
  
  IconData _getOrganismIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pest': return Icons.bug_report;
      case 'disease': return Icons.healing;
      case 'weed': return Icons.eco;
      default: return Icons.bug_report;
    }
  }
}
