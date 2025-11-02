import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget reutilizável para cards de talhão
/// Baseado na estrutura do infestation_dashboard.dart
class TalhaoCardWidget extends StatelessWidget {
  final String talhaoNome;
  final String cultura;
  final String variedade;
  final int pontos;
  final double areaAfetada;
  final String nivelRisco;
  final int prescricoes;
  final DateTime dataAtualizacao;
  final String status;
  final VoidCallback? onTap;
  final Color? corStatus;
  final bool isCritico;

  const TalhaoCardWidget({
    Key? key,
    required this.talhaoNome,
    required this.cultura,
    required this.variedade,
    required this.pontos,
    required this.areaAfetada,
    required this.nivelRisco,
    required this.prescricoes,
    required this.dataAtualizacao,
    required this.status,
    this.onTap,
    this.corStatus,
    this.isCritico = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cor = corStatus ?? _getRiscoColor(nivelRisco);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do talhão
              Row(
                children: [
                  Icon(
                    isCritico ? Icons.warning : Icons.landscape,
                    color: cor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      talhaoNome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Informações básicas
              Row(
                children: [
                  Icon(Icons.agriculture, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${cultura.toUpperCase()} - $variedade',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Estatísticas
              Row(
                children: [
                  _buildStatItem(
                    'Pontos',
                    pontos.toString(),
                    Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Área Afetada',
                    '${areaAfetada.toStringAsFixed(1)}%',
                    Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    'Risco',
                    nivelRisco,
                    cor,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Prescrições
              if (prescricoes > 0) ...[
                Row(
                  children: [
                    Icon(Icons.medical_services, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      '$prescricoes prescrições',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Footer
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Atualizado ${DateFormat('dd/MM/yyyy').format(dataAtualizacao)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getRiscoColor(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'baixo':
        return Colors.green;
      case 'médio':
        return Colors.orange;
      case 'alto':
        return Colors.red;
      case 'crítico':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

/// Widget para lista de cards de talhão
class TalhaoCardList extends StatelessWidget {
  final List<TalhaoCardData> talhoes;
  final Function(TalhaoCardData)? onTalhaoTap;

  const TalhaoCardList({
    Key? key,
    required this.talhoes,
    this.onTalhaoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: talhoes.length,
      itemBuilder: (context, index) {
        final talhao = talhoes[index];
        return TalhaoCardWidget(
          talhaoNome: talhao.talhaoNome,
          cultura: talhao.cultura,
          variedade: talhao.variedade,
          pontos: talhao.pontos,
          areaAfetada: talhao.areaAfetada,
          nivelRisco: talhao.nivelRisco,
          prescricoes: talhao.prescricoes,
          dataAtualizacao: talhao.dataAtualizacao,
          status: talhao.status,
          corStatus: talhao.corStatus,
          isCritico: talhao.isCritico,
          onTap: () => onTalhaoTap?.call(talhao),
        );
      },
    );
  }
}

/// Classe de dados para o card de talhão
class TalhaoCardData {
  final String talhaoNome;
  final String cultura;
  final String variedade;
  final int pontos;
  final double areaAfetada;
  final String nivelRisco;
  final int prescricoes;
  final DateTime dataAtualizacao;
  final String status;
  final Color? corStatus;
  final bool isCritico;
  final String? talhaoId;
  final String? culturaId;

  TalhaoCardData({
    required this.talhaoNome,
    required this.cultura,
    required this.variedade,
    required this.pontos,
    required this.areaAfetada,
    required this.nivelRisco,
    required this.prescricoes,
    required this.dataAtualizacao,
    required this.status,
    this.corStatus,
    this.isCritico = false,
    this.talhaoId,
    this.culturaId,
  });
}
