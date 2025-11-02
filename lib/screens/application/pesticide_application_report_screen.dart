import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fortsmart_agro/models/pesticide_application.dart';
import 'package:fortsmart_agro/repositories/pesticide_application_repository.dart';
import 'package:fortsmart_agro/repositories/plot_repository.dart';
import 'package:fortsmart_agro/repositories/crop_repository.dart';
import 'package:fortsmart_agro/repositories/agricultural_product_repository.dart';
import 'package:fortsmart_agro/repositories/inventory_repository.dart';
import 'package:fortsmart_agro/database/models/inventory.dart';

import 'package:fortsmart_agro/utils/snackbar_helper.dart';
import 'package:fortsmart_agro/widgets/loading_overlay.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fortsmart_agro/utils/pdf_generator.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';

class PesticideApplicationReportScreen extends StatefulWidget {
  final String applicationId;

  const PesticideApplicationReportScreen({
    Key? key,
    required this.applicationId,
  }) : super(key: key);

  @override
  _PesticideApplicationReportScreenState createState() =>
      _PesticideApplicationReportScreenState();
}

class _PesticideApplicationReportScreenState
    extends State<PesticideApplicationReportScreen> {
  final PesticideApplicationRepository _applicationRepository =
      PesticideApplicationRepository();
  final PlotRepository _plotRepository = PlotRepository();
  final CropRepository _cropRepository = CropRepository();
  final AgriculturalProductRepository _productRepository =
      AgriculturalProductRepository();
  final InventoryRepository _inventoryRepository = InventoryRepository();

  bool _isLoading = true;
  PesticideApplication? _application;
  String _plotName = '';
  String _cropName = '';
  String _productName = '';
  String _productFormulation = '';
  InventoryItem? _inventoryItem;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carrega a aplicação
      final application =
          await _applicationRepository.getById(widget.applicationId);
      if (application == null) {
        SnackbarHelper.showErrorSnackbar(
            context, 'Aplicação não encontrada');
        Navigator.pop(context);
        return;
      }

      // Carrega informações do talhão
      final plot = await _plotRepository.getById(application.plotId);
      final plotName = plot?.name ?? 'Talhão não encontrado';

      // Carrega informações da cultura
      final crop = await _cropRepository.getById(int.tryParse(application.cropId ?? '') ?? 0);
      final cropName = crop?.name ?? 'Cultura não encontrada';

      // Carrega informações do produto
      final product = application.productId != null ? 
          await _productRepository.getById(application.productId!) : null;
      final productName = product?.name ?? 'Produto não encontrado';
      final productFormulation = product?.formulation ?? '';

      // Busca o produto no estoque
      InventoryItem? inventoryItem;
      if (product != null) {
        final items = await _inventoryRepository.getItemsByName(
            product.name, product.formulation ?? '');
        // Atribuição segura para evitar erro de tipo
        inventoryItem = items.isNotEmpty ? items.first : null;
      }

      setState(() {
        _application = application;
        _plotName = plotName;
        _cropName = cropName;
        _productName = productName;
        _productFormulation = productFormulation;
        _inventoryItem = inventoryItem;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarHelper.showErrorSnackbar(
          context, 'Erro ao carregar dados: ${e.toString()}');
    }
  }

  Future<void> _generateAndSharePDF() async {
    if (_application == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Cria o PDF
      final pdfBytes = await PdfGenerator.generatePesticideApplicationReport(
        application: _application!,
        plotName: _plotName,
        cropName: _cropName,
        productName: _productName,
        productFormulation: _productFormulation,
        stockQuantity: _inventoryItem?.quantity ?? 0,
      );

      // Salva o PDF temporariamente
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/aplicacao_${_application!.id}.pdf';
      final file = File(tempPath);
      await file.writeAsBytes(pdfBytes);

      // Compartilha o PDF
      await Share.shareXFiles(
        [XFile(tempPath)],
        text: 'Relatório de Aplicação - $_productName',
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarHelper.showErrorSnackbar(
          context, 'Erro ao gerar PDF: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório de Aplicação'),
        actions: [
          if (!_isLoading && _application != null)
            IconButton(
              icon: Icon(Icons.share),
              onPressed: _generateAndSharePDF,
              tooltip: 'Compartilhar PDF',
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _application == null
            ? Center(child: Text('Aplicação não encontrada'))
            : _buildReportContent(),
      ),
    );
  }

  Widget _buildReportContent() {
    final application = _application!;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalProductAmount = application.calculateTotalProductAmount();
    final totalMixtureVolume = application.calculateTotalMixtureVolume();
    final tanksNeeded = application.calculateTanksNeeded(2000); // Assume tanque de 2000L

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aplicação de $_productName',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Data: ${dateFormat.format(application.date)}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Responsável: ${application.responsiblePerson}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Informações do local
          _buildSectionCard(
            'Local da Aplicação',
            [
              _buildInfoRow('Talhão:', _plotName),
              _buildInfoRow('Cultura:', _cropName),
              _buildInfoRow('Área total:', '${application.totalArea?.toStringAsFixed(2) ?? '--'} ha'),
            ],
          ),
          SizedBox(height: 16),

          // Informações do produto
          _buildSectionCard(
            'Produto Aplicado',
            [
              _buildInfoRow('Produto:', _productName),
              if (_productFormulation.isNotEmpty)
                _buildInfoRow('Formulação:', _productFormulation),
              _buildInfoRow('Dose:', application.getFormattedDose()),
              _buildInfoRow('Volume de calda:', '${application.mixtureVolume?.toStringAsFixed(2) ?? '--'} L/ha'),
            ],
          ),
          SizedBox(height: 16),

          // Cálculos e totais
          _buildSectionCard(
            'Cálculos e Totais',
            [
              _buildInfoRow('Quantidade total de produto:', '${totalProductAmount.toStringAsFixed(2)} ${application.doseUnit?.split('/')?.first ?? ''}'),
              _buildInfoRow('Volume total de calda:', '${totalMixtureVolume.toStringAsFixed(2)} L'),
              _buildInfoRow('Tanques necessários (2000L):', '${tanksNeeded.toStringAsFixed(1)}'),
            ],
          ),
          SizedBox(height: 16),

          // Impacto no estoque
          _buildSectionCard(
            'Impacto no Estoque',
            [
              _buildInfoRow('Estoque antes da aplicação:', _inventoryItem != null 
                  ? '${(_inventoryItem!.quantity + totalProductAmount).toStringAsFixed(2)} ${_inventoryItem!.unit}'
                  : 'Produto não encontrado no estoque'),
              _buildInfoRow('Quantidade utilizada:', '${totalProductAmount.toStringAsFixed(2)} ${application.doseUnit?.split('/')?.first ?? ''}'),
              _buildInfoRow('Estoque atual:', _inventoryItem != null 
                  ? '${_inventoryItem!.quantity.toStringAsFixed(2)} ${_inventoryItem!.unit}'
                  : 'Produto não encontrado no estoque'),
            ],
            color: _inventoryItem != null 
                ? (_inventoryItem!.quantity < totalProductAmount * 0.2 ? Colors.red.shade50 : null)
                : Colors.orange.shade50,
          ),
          SizedBox(height: 16),

          // Condições ambientais
          if (application.temperature != null || application.humidity != null)
            _buildSectionCard(
              'Condições Ambientais',
              [
                if (application.temperature != null)
                  _buildInfoRow('Temperatura:', '${application.temperature!.toStringAsFixed(1)} °C'),
                if (application.humidity != null)
                  _buildInfoRow('Umidade relativa:', '${application.humidity!.toStringAsFixed(1)} %'),
              ],
            ),
          SizedBox(height: 16),

          // Observações
          if ((application.observations?.isNotEmpty ?? false))
            _buildSectionCard(
              'Observações',
              [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(application.observations ?? ''),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children, {Color? color}) {
    return Card(
      color: color,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

