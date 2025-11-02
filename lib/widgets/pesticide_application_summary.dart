import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fortsmart_agro/models/pesticide_application.dart';

/// Widget para exibir um resumo de aplicação de defensivos
class PesticideApplicationSummary extends StatelessWidget {
  final PesticideApplication application;
  final String productName;
  final String plotName;
  final String cropName;
  final double stockQuantity;
  final VoidCallback? onViewDetails;
  final VoidCallback? onGenerateReport;

  const PesticideApplicationSummary({
    super.key,
    required this.application,
    required this.productName,
    required this.plotName,
    required this.cropName,
    required this.stockQuantity,
    this.onViewDetails,
    this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalProductAmount = application.calculateTotalProductAmount();
    final totalMixtureVolume = application.calculateTotalMixtureVolume();
    final tanksNeeded = application.calculateTanksNeeded(2000);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, dateFormat),
          Divider(height: 1, color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(
                  context,
                  'Local da Aplicação',
                  [
                    _buildInfoRow('Talhão:', plotName),
                    _buildInfoRow('Cultura:', cropName),
                    _buildInfoRow('Área total:', '${(application.totalArea ?? 0.0).toStringAsFixed(2)} ha'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  context,
                  'Produto e Dosagem',
                  [
                    _buildInfoRow('Produto:', productName),
                    _buildInfoRow('Dose:', application.getFormattedDose()),
                    _buildInfoRow('Volume de calda:', '${application.mixtureVolume?.toStringAsFixed(2) ?? '0.00'} L/ha'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  context,
                  'Cálculos e Totais',
                  [
                    _buildInfoRow(
                      'Quantidade total de produto:', 
                      '${totalProductAmount.toStringAsFixed(2)} ${application.doseUnit?.split('/').first ?? 'kg'}'
                    ),
                    _buildInfoRow(
                      'Volume total de calda:', 
                      '${totalMixtureVolume.toStringAsFixed(2)} L'
                    ),
                    _buildInfoRow(
                      'Tanques necessários (2000L):', 
                      '${tanksNeeded.toStringAsFixed(1)}'
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStockImpact(context, totalProductAmount),
                if (application.observations?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    context,
                    'Observações',
                    [
                      Text(application.observations ?? ''),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _buildActions(context),
        ],
      ),
    );
  }

  /// Constrói o cabeçalho do card
  Widget _buildHeader(BuildContext context, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.eco,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aplicação de $productName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Data: ${dateFormat.format(application.date)} | Responsável: ${application.responsiblePerson ?? "Não informado"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói uma seção de informações
  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  /// Constrói uma linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a seção de impacto no estoque
  Widget _buildStockImpact(BuildContext context, double totalProductAmount) {
    final isLowStock = stockQuantity < totalProductAmount * 0.2;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLowStock ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLowStock ? Colors.red[200]! : Colors.green[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impacto no Estoque',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isLowStock ? Colors.red[700] : Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Estoque atual:', 
            '${stockQuantity.toStringAsFixed(2)} ${application.doseUnit?.split('/').first ?? 'kg'}'
          ),
          if (isLowStock)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estoque baixo! Considere repor este produto.',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Constrói a seção de ações
  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onViewDetails != null)
            TextButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.visibility),
              label: const Text('Detalhes'),
            ),
          if (onGenerateReport != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onGenerateReport,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Gerar PDF'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget para exibir uma lista de resumos de aplicações
class PesticideApplicationList extends StatelessWidget {
  final List<PesticideApplicationSummaryData> applications;
  final Function(String) onViewDetails;
  final Function(String) onGenerateReport;

  const PesticideApplicationList({
    Key? key,
    required this.applications,
    required this.onViewDetails,
    required this.onGenerateReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco,
              size: 64,
              color: Colors.green[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma aplicação encontrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não há registros de aplicação de defensivos para o período selecionado',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: applications.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final data = applications[index];
        
        return PesticideApplicationSummary(
          application: data.application,
          productName: data.productName,
          plotName: data.plotName,
          cropName: data.cropName,
          stockQuantity: data.stockQuantity,
          onViewDetails: () => onViewDetails(data.application.id ?? ''),
          onGenerateReport: () => onGenerateReport(data.application.id ?? ''),
        );
      },
    );
  }
}

/// Classe para armazenar dados de resumo de aplicação
class PesticideApplicationSummaryData {
  final PesticideApplication application;
  final String productName;
  final String plotName;
  final String cropName;
  final double stockQuantity;
  
  PesticideApplicationSummaryData({
    required this.application,
    required this.productName,
    required this.plotName,
    required this.cropName,
    required this.stockQuantity,
  });
}

