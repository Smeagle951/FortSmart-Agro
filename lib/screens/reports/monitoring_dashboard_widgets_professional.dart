import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

/// 🎨 WIDGETS PROFISSIONAIS PARA O DASHBOARD DE MONITORAMENTO
/// Inclui: Imagens em Miniatura, Dados JSON Completos, Visualizações Avançadas
class MonitoringDashboardWidgetsProfessional {
  
  /// 🖼️ SEÇÃO DE IMAGENS DAS INFESTAÇÕES EM MINIATURA
  static Widget buildImagensInfestacaoSection(
    List<Map<String, dynamic>> imagens,
    BuildContext context,
    Function(String) onImageTap,
  ) {
    if (imagens.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Imagens das Infestações',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${imagens.length} fotos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imagens.length > 10 ? 10 : imagens.length,
              itemBuilder: (context, index) {
                final img = imagens[index];
                return GestureDetector(
                  onTap: () => onImageTap(img['path'] as String),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(img['path'] as String),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    img['organismo'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${img['percentual']}%',
                                    style: const TextStyle(
                                      color: Colors.yellowAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// 📊 NÍVEIS DE INFESTAÇÃO COMPLETOS COM BARRAS
  static Widget buildNiveisInfestacaoSection(List<dynamic> sintomas) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Níveis de Infestação Detalhados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sintomas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Nenhum dado de infestação disponível',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          else
            ...sintomas.map((sintoma) {
              final texto = sintoma.toString();
              // Extrair percentual (ex: "Lagarta: 85.0%")
              final match = RegExp(r'(\d+\.?\d*)%').firstMatch(texto);
              final percentual = match != null ? double.tryParse(match.group(1)!) ?? 0.0 : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            texto,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: percentual > 70 ? Colors.red : 
                                   percentual > 40 ? Colors.orange : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${percentual.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentual / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          percentual > 70 ? Colors.red : 
                          percentual > 40 ? Colors.orange : Colors.green
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
  
  /// 🌱 DADOS AGRONÔMICOS (FENOLOGIA + ESTANDE)
  static Widget buildDadosAgronomicosSection(
    Map<String, dynamic> dados,
    Function(String, String) buildInfoRow,
  ) {
    final fenologia = dados['fenologia'] as Map<String, dynamic>?;
    final estande = dados['estande'] as Map<String, dynamic>?;
    
    if (fenologia == null && estande == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Dados Agronômicos da Cultura',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (fenologia != null) ...[
            buildInfoRow('Estágio Fenológico', fenologia['estagio'] as String? ?? 'N/A'),
            buildInfoRow('Dias Após Plantio', '${fenologia['dias_apos_plantio'] ?? 'N/A'}'),
            buildInfoRow('Altura Média', '${fenologia['altura_cm'] ?? 'N/A'} cm'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
          ],
          if (estande != null) ...[
            buildInfoRow('População Média', '${estande['populacao_media'] ?? 'N/A'} plantas/m²'),
            buildInfoRow('CV (%)', '${estande['cv_percentual'] ?? 'N/A'}%'),
            buildInfoRow('Classificação do Estande', estande['classificacao'] as String? ?? 'N/A'),
          ],
        ],
      ),
    );
  }
  
  /// 🌤️ CONDIÇÕES AMBIENTAIS
  static Widget buildCondicoesAmbientaisSection(
    Map<String, dynamic> condicoes,
    Function(String, String) buildInfoRow,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.cyan[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.cyan),
              const SizedBox(width: 8),
              Text(
                'Condições Ambientais',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          buildInfoRow('🌡️ Temperatura', '${condicoes['temperatura'] ?? 'N/A'}°C'),
          buildInfoRow('💧 Umidade Relativa', '${condicoes['umidade'] ?? 'N/A'}%'),
          buildInfoRow('🌧️ Precipitação', '${condicoes['precipitacao'] ?? 'N/A'} mm'),
        ],
      ),
    );
  }
  
  /// 📄 DADOS JSON COMPLETOS EXPANDÍVEL
  static Widget buildDadosJSONExpandivel(Map<String, dynamic> dados) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ExpansionTile(
        title: const Row(
          children: [
            Icon(Icons.code, size: 20),
            SizedBox(width: 8),
            Text(
              'Dados JSON Completos da IA FortSmart',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        subtitle: const Text(
          'Clique para expandir e ver dados técnicos',
          style: TextStyle(fontSize: 11),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                const JsonEncoder.withIndent('  ').convert(dados),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${dados.length} campos disponíveis',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
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
  
  /// 🎨 INDICADOR DE RISCO VISUAL
  static Widget buildRiskIndicator(String nivel) {
    final color = nivel.toLowerCase() == 'crítico' || nivel.toLowerCase() == 'critico'
        ? Colors.red
        : nivel.toLowerCase() == 'alto'
        ? Colors.orange
        : nivel.toLowerCase() == 'médio' || nivel.toLowerCase() == 'medio'
        ? Colors.yellow.shade700
        : Colors.green;
    
    final icon = nivel.toLowerCase() == 'crítico' || nivel.toLowerCase() == 'critico'
        ? Icons.warning
        : nivel.toLowerCase() == 'alto'
        ? Icons.warning_amber
        : nivel.toLowerCase() == 'médio' || nivel.toLowerCase() == 'medio'
        ? Icons.info
        : Icons.check_circle;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nível de Risco',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  nivel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 🖼️ MOSTRAR IMAGEM EM TELA CHEIA
  static void mostrarImagemCompleta(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                InteractiveViewer(
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

