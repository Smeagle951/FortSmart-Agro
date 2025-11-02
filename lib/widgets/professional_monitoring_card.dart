import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../services/monitoring_card_data_service.dart';
import '../utils/logger.dart';
import '../utils/app_theme.dart';
import '../database/app_database.dart';

/// 🎯 CARD PROFISSIONAL DE MONITORAMENTO
/// Design horizontal elegante com thumbnail, métricas e ações
class ProfessionalMonitoringCard extends StatefulWidget {
  final MonitoringCardData data;
  final VoidCallback? onTap;
  
  const ProfessionalMonitoringCard({
    Key? key,
    required this.data,
    this.onTap,
  }) : super(key: key);

  @override
  State<ProfessionalMonitoringCard> createState() => _ProfessionalMonitoringCardState();
}

class _ProfessionalMonitoringCardState extends State<ProfessionalMonitoringCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // 🎯 HEADER HORIZONTAL COM THUMBNAIL
            _buildHeader(),
            
            // 📊 MÉTRICAS PRINCIPAIS (sempre visível)
            _buildMainMetrics(),
            
            // 📋 DETALHES EXPANDÍVEIS
            if (_expanded) ...[
              const Divider(height: 1),
              _buildExpandedDetails(),
            ],
          ],
        ),
      ),
    );
  }

  /// 🎯 HEADER HORIZONTAL COM THUMBNAIL DE FOTO
  Widget _buildHeader() {
    final hasPhotos = widget.data.totalFotos > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 📸 THUMBNAIL DA PRIMEIRA FOTO (ou ícone)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getRiskColor(widget.data.nivelRisco).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: hasPhotos
                ? FutureBuilder<Widget>(
                    future: _buildPhotoThumbnail(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!;
                      }
                      return _buildPlaceholderIcon();
                    },
                  )
                : _buildPlaceholderIcon(),
          ),
          
          const SizedBox(width: 16),
          
          // 📋 INFORMAÇÕES PRINCIPAIS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Talhão e Cultura
                Row(
                  children: [
                    const Icon(Icons.agriculture, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${widget.data.talhaoNome} • ${widget.data.culturaNome}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // Status e Data
                Row(
                  children: [
                    _buildStatusBadge(),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(widget.data.dataInicio),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Nível de Risco GRANDE
                _buildRiskBadgeLarge(),
              ],
            ),
          ),
          
          // 🔽 BOTÃO EXPANDIR
          IconButton(
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            icon: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 MÉTRICAS PRINCIPAIS (compactas)
  Widget _buildMainMetrics() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactMetric(
            icon: Icons.bug_report,
            label: 'Pragas',
            value: widget.data.totalPragas.toString(),
            color: Colors.red,
          ),
          _buildCompactMetric(
            icon: Icons.analytics,
            label: 'Severidade',
            value: '${widget.data.severidadeMedia.toStringAsFixed(0)}%',
            color: Colors.orange,
          ),
          _buildCompactMetric(
            icon: Icons.location_on,
            label: 'Pontos',
            value: widget.data.totalPontos.toString(),
            color: Colors.blue,
          ),
          _buildCompactMetric(
            icon: Icons.photo_camera,
            label: 'Fotos',
            value: widget.data.totalFotos.toString(),
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  /// 📋 DETALHES EXPANDIDOS
  Widget _buildExpandedDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🐛 ORGANISMOS DETECTADOS
          if (widget.data.organismosDetectados.isNotEmpty) ...[
            _buildSectionTitle('🐛 Organismos Detectados'),
            const SizedBox(height: 8),
            ...widget.data.organismosDetectados.map((org) => _buildOrganismTile(org)),
            const SizedBox(height: 16),
          ],
          
          // 📊 DADOS COMPLEMENTARES
          _buildSectionTitle('📊 Dados Complementares'),
          const SizedBox(height: 8),
          _buildInfoGrid(),
          
          const SizedBox(height: 16),
          
          // 🎯 RECOMENDAÇÕES
          if (widget.data.recomendacoes.isNotEmpty) ...[
            _buildSectionTitle('🎯 Recomendações Agronômicas'),
            const SizedBox(height: 8),
            _buildRecommendationsList(),
            const SizedBox(height: 16),
          ],
          
          // 📸 GALERIA DE FOTOS
          FutureBuilder<List<String>>(
            future: _loadAllPhotos(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('📸 Galeria (${snapshot.data!.length})'),
                    const SizedBox(height: 8),
                    _buildPhotoGallery(snapshot.data!),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const SizedBox(height: 8),
          
          // 🔍 BOTÃO VER ANÁLISE COMPLETA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onTap,
              icon: const Icon(Icons.analytics, size: 20),
              label: const Text('Ver Análise Profissional Completa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷️ STATUS BADGE
  Widget _buildStatusBadge() {
    final color = widget.data.status == 'finalized' ? Colors.green : Colors.blue;
    final text = widget.data.status == 'finalized' ? 'Finalizado' : 'Ativo';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// 🔥 BADGE DE RISCO GRANDE
  Widget _buildRiskBadgeLarge() {
    final color = _getRiskColor(widget.data.nivelRisco);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getRiskIcon(widget.data.nivelRisco), size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            widget.data.nivelRisco,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 MÉTRICA COMPACTA
  Widget _buildCompactMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
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
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 🐛 TILE DE ORGANISMO
  Widget _buildOrganismTile(OrganismSummary org) {
    final nome = org.nome;
    final quantidade = org.quantidadeTotal.toStringAsFixed(0);
    final nivelRisco = org.nivelRisco;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRiskColor(nivelRisco).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bug_report,
              color: _getRiskColor(nivelRisco),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantidade: $quantidade',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getRiskColor(nivelRisco).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              nivelRisco,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _getRiskColor(nivelRisco),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 GRID DE INFORMAÇÕES
  Widget _buildInfoGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInfoItem('🌱 Estágio', widget.data.estagioFenologico ?? 'N/D')),
              Expanded(child: _buildInfoItem('👥 População', widget.data.populacao != null ? '${(widget.data.populacao! / 1000).toStringAsFixed(0)}k/ha' : 'N/D')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInfoItem('📅 DAE', widget.data.dae != null ? '${widget.data.dae} dias' : 'N/D')),
              Expanded(child: _buildInfoItem('🌡️ Temp', '${widget.data.temperatura.toStringAsFixed(1)}°C')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 🎯 LISTA DE RECOMENDAÇÕES
  Widget _buildRecommendationsList() {
    final topRecommendations = widget.data.recomendacoes.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: topRecommendations.map((rec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    _sanitizeText(rec),
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 📸 GALERIA DE FOTOS
  Widget _buildPhotoGallery(List<String> photos) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(photos[index]),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// 📸 CARREGAR TODAS AS FOTOS DA SESSÃO
  Future<List<String>> _loadAllPhotos() async {
    try {
      final db = await AppDatabase.instance.database;
      
      final result = await db.rawQuery('''
        SELECT foto_paths 
        FROM monitoring_occurrences 
        WHERE session_id = ? 
          AND foto_paths IS NOT NULL 
          AND foto_paths != ''
          AND foto_paths != '[]'
          AND foto_paths != '[""]'
      ''', [widget.data.sessionId]);
      
      final List<String> allPhotos = [];
      
      for (final row in result) {
        final pathsJson = row['foto_paths']?.toString();
        if (pathsJson != null && pathsJson.isNotEmpty) {
          try {
            final List<dynamic> paths = jsonDecode(pathsJson);
            for (var path in paths) {
              if (path != null && path.toString().trim().isNotEmpty) {
                allPhotos.add(path.toString());
              }
            }
          } catch (e) {
            Logger.warning('⚠️ Erro ao decodificar foto_paths: $e');
          }
        }
      }
      
      Logger.info('📸 [PROF_CARD] ${allPhotos.length} fotos carregadas');
      return allPhotos;
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar fotos: $e');
      return [];
    }
  }

  /// 📸 THUMBNAIL DA PRIMEIRA FOTO
  Future<Widget> _buildPhotoThumbnail() async {
    try {
      final photos = await _loadAllPhotos();
      if (photos.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(photos.first),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) {
              return _buildPlaceholderIcon();
            },
          ),
        );
      }
    } catch (e) {
      Logger.error('❌ Erro ao carregar thumbnail: $e');
    }
    
    return _buildPlaceholderIcon();
  }

  /// 🖼️ ÍCONE PLACEHOLDER
  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.agriculture,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  /// 📋 TÍTULO DE SEÇÃO
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E7D32),
      ),
    );
  }

  /// 🎨 COR DO RISCO
  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'CRÍTICO':
        return Colors.red.shade700;
      case 'ALTO':
        return Colors.orange.shade700;
      case 'MÉDIO':
        return Colors.yellow.shade700;
      case 'BAIXO':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  /// 🎨 ÍCONE DO RISCO
  IconData _getRiskIcon(String risk) {
    switch (risk.toUpperCase()) {
      case 'CRÍTICO':
        return Icons.error;
      case 'ALTO':
        return Icons.warning_amber;
      case 'MÉDIO':
        return Icons.info;
      case 'BAIXO':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  /// 📅 FORMATAR DATA
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  /// 🧹 SANITIZAR TEXTO
  String _sanitizeText(String text) {
    return text
        .replaceAll('━', '-')
        .replaceAll('═', '=')
        .replaceAll('│', '|')
        .replaceAll('└', '+')
        .replaceAll('├', '+')
        .replaceAll('─', '-')
        .replaceAll('°', 'o')
        .replaceAll('²', '2')
        .replaceAll('³', '3')
        .replaceAll('ª', 'a')
        .replaceAll('º', 'o')
        .trim();
  }
}

