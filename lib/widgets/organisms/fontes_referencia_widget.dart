import 'package:flutter/material.dart';
import '../../models/organism_catalog_v3.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget para exibir fontes de referência bibliográfica
class FontesReferenciaWidget extends StatelessWidget {
  final OrganismCatalogV3 organismo;
  final bool compact;

  const FontesReferenciaWidget({
    Key? key,
    required this.organismo,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (organismo.fontesReferencia == null) {
      return const SizedBox.shrink();
    }

    final fontes = organismo.fontesReferencia!;

    if (compact) {
      return Card(
        color: Colors.blue[50],
        child: InkWell(
          onTap: () => _showFullReferences(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.library_books, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fontes de Referência (${fontes.fontesPrincipais.length + fontes.fontesEspecificas.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue[700]),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.library_books, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Fontes de Referência',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Fontes principais
            if (fontes.fontesPrincipais.isNotEmpty) ...[
              const Text(
                'Fontes Principais:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...fontes.fontesPrincipais.map((fonte) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fonte,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
            ],
            
            // Fontes específicas
            if (fontes.fontesEspecificas.isNotEmpty) ...[
              const Text(
                'Fontes Específicas:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...fontes.fontesEspecificas.map((fonte) => _buildFonteEspecifica(context, fonte)),
              const SizedBox(height: 16),
            ],
            
            // Nota de licença
            if (fontes.notaLicenca != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fontes.notaLicenca!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[900],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFonteEspecifica(BuildContext context, Map<String, String> fonte) {
    final nome = fonte['fonte'] ?? '';
    final tipo = fonte['tipo'] ?? '';
    final uso = fonte['uso'] ?? '';
    final url = fonte['url'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (url != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    onPressed: () => _launchURL(context, url),
                    tooltip: 'Abrir site',
                  ),
              ],
            ),
            if (tipo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                tipo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (uso.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Uso: $uso',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o link')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _showFullReferences(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fontes de Referência'),
        content: SingleChildScrollView(
          child: FontesReferenciaWidget(
            organismo: organismo,
            compact: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

