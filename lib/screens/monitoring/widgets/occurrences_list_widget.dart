import 'package:flutter/material.dart';
import '../../models/infestacao_model.dart';

/// Widget para exibir lista de ocorrências registradas
class OccurrencesListWidget extends StatelessWidget {
  final List<InfestacaoModel> ocorrencias;
  final Function(InfestacaoModel)? onEdit;
  final Function(String)? onDelete;

  const OccurrencesListWidget({
    Key? key,
    required this.ocorrencias,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ocorrências Registradas neste Ponto',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 12),
        
        if (ocorrencias.isEmpty)
          _buildEmptyState()
        else
          _buildOccurrencesList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma ocorrência registrada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque em "Nova Ocorrência" para começar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccurrencesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ocorrencias.length,
      itemBuilder: (context, index) {
        final occurrence = ocorrencias[index];
        return _buildOccurrenceCard(occurrence);
      },
    );
  }

  Widget _buildOccurrenceCard(InfestacaoModel occurrence) {
    final typeColor = _getTypeColor(occurrence.tipo);
    final levelColor = _getLevelColor(occurrence.nivel);
    final typeIcon = _getTypeIcon(occurrence.tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onEditOccurrence(occurrence),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone do tipo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      typeIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Informações da ocorrência
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occurrence.subtipo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${occurrence.percentual} indivíduos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: levelColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: levelColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              occurrence.nivel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: levelColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (occurrence.observacao != null && 
                          occurrence.observacao!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          occurrence.observacao!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Botão de deletar
                IconButton(
                  onPressed: () => _showDeleteConfirmation(occurrence),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEB5757),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(InfestacaoModel occurrence) {
    // Implementar confirmação de exclusão
    onDeleteOccurrence(occurrence.id);
  }

  Color _getTypeColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'praga':
        return const Color(0xFF27AE60); // Verde
      case 'doença':
        return const Color(0xFFF2C94C); // Amarelo
      case 'daninha':
        return const Color(0xFF2D9CDB); // Azul
      case 'outro':
        return const Color(0xFF9B59B6); // Roxo
      default:
        return const Color(0xFF95A5A6); // Cinza
    }
  }

  Color _getLevelColor(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'crítico':
        return const Color(0xFFEB5757);
      case 'alto':
        return const Color(0xFFF2C94C);
      case 'médio':
        return const Color(0xFF2D9CDB);
      case 'baixo':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String _getTypeIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'praga':
        return '🐛';
      case 'doença':
        return '🦠';
      case 'daninha':
        return '🌿';
      case 'outro':
        return '📋';
      default:
        return '❓';
    }
  }
}
