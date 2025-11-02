import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../models/plot.dart';
import '../widgets/error_dialog.dart';

/// Widget para o botão de exportação de talhões para arquivo KML
class KmlExportButton extends StatelessWidget {
  final List<Plot> plots;
  final bool isLoading;
  
  const KmlExportButton({
    Key? key,
    required this.plots,
    this.isLoading = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading || plots.isEmpty ? null : () => _exportKml(context),
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.file_download),
      label: Text(isLoading ? 'Exportando...' : 'Exportar KML'),
      style: ElevatedButton.styleFrom(
        // backgroundColor: const Color(0xFF2196F3), // backgroundColor não é suportado em flutter_map 5.0.0
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        disabledBackgroundColor: Colors.grey.shade300,
      ),
    );
  }
  
  /// Exporta os talhões para um arquivo KML
  Future<void> _exportKml(BuildContext context) async {
    try {
      // Verificar permissões
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Permissão Negada',
            message: 'É necessário permitir o acesso aos arquivos para exportar KML.',
          );
        }
        return;
      }
      
      // Gerar conteúdo KML
      final String kmlContent = _generateKml();
      
      // Salvar arquivo temporário
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/talhoes_$timestamp.kml';
      final file = File(filePath);
      await file.writeAsString(kmlContent);
      
      // Compartilhar arquivo
      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Talhões exportados em formato KML',
          subject: 'Talhões FORTSMART',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Erro na Exportação',
          message: 'Ocorreu um erro ao exportar os talhões: $e',
        );
      }
    }
  }
  
  /// Gera o conteúdo do arquivo KML
  String _generateKml() {
    final StringBuffer kml = StringBuffer();
    
    // Cabeçalho KML
    kml.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    kml.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    kml.writeln('<Document>');
    kml.writeln('<name>Talhões FORTSMART</name>');
    kml.writeln('<description>Talhões exportados do aplicativo FORTSMART</description>');
    
    // Estilo para os polígonos
    kml.writeln('<Style id="polygonStyle">');
    kml.writeln('  <LineStyle>');
    kml.writeln('    <color>ff4CAF50</color>');
    kml.writeln('    <width>2</width>');
    kml.writeln('  </LineStyle>');
    kml.writeln('  <PolyStyle>');
    kml.writeln('    <color>804CAF50</color>');
    kml.writeln('  </PolyStyle>');
    kml.writeln('</Style>');
    
    // Adicionar cada talhão como um Placemark
    for (final plot in plots) {
      kml.writeln('<Placemark>');
      kml.writeln('  <name>${_escapeXml(plot.name)}</name>');
      if (plot.description != null && plot.description!.isNotEmpty) {
        kml.writeln('  <description>${_escapeXml(plot.description!)}</description>');
      }
      kml.writeln('  <styleUrl>#polygonStyle</styleUrl>');
      kml.writeln('  <Polygon>');
      kml.writeln('    <extrude>1</extrude>');
      kml.writeln('    <altitudeMode>relativeToGround</altitudeMode>');
      kml.writeln('    <outerBoundaryIs>');
      kml.writeln('      <LinearRing>');
      kml.writeln('        <coordinates>');
      
      // Adicionar coordenadas
      if (plot.coordinates != null && plot.coordinates!.isNotEmpty) {
        final StringBuffer coords = StringBuffer();
        for (var coord in plot.coordinates!) {
          coords.writeln('          ${coord['longitude']},${coord['latitude']},0');
        }
        // Fechar o polígono repetindo o primeiro ponto
        if (plot.coordinates!.isNotEmpty) {
          coords.writeln('          ${plot.coordinates!.first['longitude']},${plot.coordinates!.first['latitude']},0');
        }
        kml.write(coords.toString());
      }
      
      kml.writeln('        </coordinates>');
      kml.writeln('      </LinearRing>');
      kml.writeln('    </outerBoundaryIs>');
      kml.writeln('  </Polygon>');
      kml.writeln('</Placemark>');
    }
    
    // Fechar documento KML
    kml.writeln('</Document>');
    kml.writeln('</kml>');
    
    return kml.toString();
  }
  
  /// Escapa caracteres especiais XML
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
