import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

/// Serviço de relatórios integrados (sem germinação)
class IntegratedReportService {
  static final IntegratedReportService _instance = IntegratedReportService._internal();
  factory IntegratedReportService() => _instance;
  IntegratedReportService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// Gera relatório integrado (sem dados de germinação)
  Future<String> generateIntegratedReport({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? specificTestIds,
    bool includeRecommendations = true,
  }) async {
    try {
      await initialize();
      
      // Dados de integração (sem germinação)
      final integrationData = <String, dynamic>{
        'totalTests': 0,
        'averageGermination': 0.0,
        'qualityDistribution': <String, int>{},
        'trends': <String, dynamic>{},
      };
      
      // Gerar PDF integrado
      final pdf = pw.Document();
      final reportCode = _generateReportCode('INT', DateTime.now());
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(reportCode),
              pw.SizedBox(height: 20),
              _buildSummary(integrationData),
              pw.SizedBox(height: 20),
              _buildRecommendations(),
            ];
          },
        ),
      );
      
      // Salvar arquivo
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/relatorio_integrado_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      return file.path;
    } catch (e) {
      throw Exception('Erro ao gerar relatório integrado: $e');
    }
  }

  /// Cabeçalho do relatório
  pw.Widget _buildHeader(String reportCode) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Relatório Integrado FortSmart Agro',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Código: $reportCode',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.green600,
            ),
          ),
          pw.Text(
            'Data: ${DateTime.now().toString().split(' ')[0]}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.green600,
            ),
          ),
        ],
      ),
    );
  }

  /// Resumo dos dados
  pw.Widget _buildSummary(Map<String, dynamic> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumo Executivo',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Este relatório integrado foi gerado sem dados de germinação, pois o módulo foi removido.',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Para acessar funcionalidades de germinação, entre em contato com o suporte técnico.',
            style: const pw.TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Recomendações
  pw.Widget _buildRecommendations() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Recomendações',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '• Utilize outros módulos do FortSmart Agro para análise de qualidade',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            '• Consulte relatórios de plantio e monitoramento disponíveis',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            '• Entre em contato para mais informações sobre funcionalidades',
            style: const pw.TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Gera código do relatório
  String _generateReportCode(String prefix, DateTime date) {
    final timestamp = date.millisecondsSinceEpoch.toString().substring(8);
    return '$prefix-$timestamp';
  }
}
