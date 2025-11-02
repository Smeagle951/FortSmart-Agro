import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../utils/api_config.dart';
import 'enhanced_map_download_widget.dart';
import 'free_map_download_widget.dart';

/// Card otimizado para área do mapa com integração APIConfig
class OptimizedMapAreaCard extends StatefulWidget {
  final LatLng? southwest;
  final LatLng? northeast;
  final String? farmName;
  final Function()? onDownloadComplete;
  final Function()? onDownloadCancel;
  final bool isCompact;
  final bool showFreeDownload;

  const OptimizedMapAreaCard({
    Key? key,
    this.southwest,
    this.northeast,
    this.farmName,
    this.onDownloadComplete,
    this.onDownloadCancel,
    this.isCompact = true,
    this.showFreeDownload = true,
  }) : super(key: key);

  @override
  State<OptimizedMapAreaCard> createState() => _OptimizedMapAreaCardState();
}

class _OptimizedMapAreaCardState extends State<OptimizedMapAreaCard> {
  String _selectedMapType = 'satellite';
  bool _showAdvancedOptions = false;
  
  @override
  void initState() {
    super.initState();
    _initializeMapType();
  }
  
  /// Inicializa tipo de mapa baseado na configuração da API
  void _initializeMapType() {
    if (APIConfig.isMapTilerConfigured()) {
      _selectedMapType = 'satellite';
    } else {
      _selectedMapType = 'streets';
    }
  }
  
  /// Mostra opções avançadas
  void _showAdvancedOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opções Avançadas'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tipo de mapa
              DropdownButtonFormField<String>(
                value: _selectedMapType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Mapa',
                  border: OutlineInputBorder(),
                ),
                items: APIConfig.getAvailableMapTypes().map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMapType = value ?? 'satellite';
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Informações da API
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status da API:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      APIConfig.isMapTilerConfigured() 
                          ? '✅ MapTiler configurado'
                          : '⚠️ Usando fallback (OpenStreetMap)',
                      style: TextStyle(
                        fontSize: 12,
                        color: APIConfig.isMapTilerConfigured() 
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                    if (APIConfig.isMapTilerConfigured()) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tipos disponíveis: ${APIConfig.getAvailableMapTypes().join(', ')}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
  
  /// Mostra opções de download
  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'Opções de Download',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Download para área específica
              if (widget.southwest != null && widget.northeast != null)
                Expanded(
                  child: EnhancedMapDownloadWidget(
                    southwest: widget.southwest!,
                    northeast: widget.northeast!,
                    farmName: widget.farmName,
                    onDownloadComplete: () {
                      Navigator.of(context).pop();
                      widget.onDownloadComplete?.call();
                    },
                    onDownloadCancel: () {
                      Navigator.of(context).pop();
                      widget.onDownloadCancel?.call();
                    },
                    isCompact: false,
                  ),
                ),
              
              // Download livre
              if (widget.showFreeDownload) ...[
                const SizedBox(height: 16),
                const Text(
                  'Download Livre',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Baixe mapas de qualquer área personalizada',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showFreeDownloadDialog();
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Livre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// Mostra dialog de download livre
  void _showFreeDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          child: FreeMapDownloadWidget(
            onDownloadComplete: () {
              Navigator.of(context).pop();
              widget.onDownloadComplete?.call();
            },
            onDownloadCancel: () {
              Navigator.of(context).pop();
              widget.onDownloadCancel?.call();
            },
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactCard();
    } else {
      return _buildFullCard();
    }
  }
  
  /// Card compacto
  Widget _buildCompactCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: InkWell(
        onTap: _showDownloadOptions,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.map,
                    color: APIConfig.isMapTilerConfigured() ? Colors.blue : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Mapa Offline',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _showAdvancedOptionsDialog,
                    icon: const Icon(Icons.settings, size: 16),
                    tooltip: 'Configurações',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                APIConfig.isMapTilerConfigured() 
                    ? 'MapTiler ativo'
                    : 'Fallback ativo',
                style: TextStyle(
                  fontSize: 8,
                  color: APIConfig.isMapTilerConfigured() 
                      ? Colors.green[700]
                      : Colors.orange[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Text(
                  'TAP PARA BAIXAR',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Card completo
  Widget _buildFullCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(
                  Icons.map,
                  color: APIConfig.isMapTilerConfigured() ? Colors.blue : Colors.orange,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Mapa Offline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showAdvancedOptionsDialog,
                  icon: const Icon(Icons.settings),
                  tooltip: 'Configurações',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status da API
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: APIConfig.isMapTilerConfigured() 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: APIConfig.isMapTilerConfigured() 
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        APIConfig.isMapTilerConfigured() ? Icons.check_circle : Icons.warning,
                        color: APIConfig.isMapTilerConfigured() ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        APIConfig.isMapTilerConfigured() 
                            ? 'MapTiler configurado'
                            : 'Usando fallback',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: APIConfig.isMapTilerConfigured() 
                              ? Colors.green[800]
                              : Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    APIConfig.isMapTilerConfigured() 
                        ? 'Tipos disponíveis: ${APIConfig.getAvailableMapTypes().join(', ')}'
                        : 'Usando OpenStreetMap como fallback',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Área definida
            if (widget.southwest != null && widget.northeast != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Área Definida:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Sudoeste: ${widget.southwest!.latitude.toStringAsFixed(4)}, ${widget.southwest!.longitude.toStringAsFixed(4)}'),
                    Text('Nordeste: ${widget.northeast!.latitude.toStringAsFixed(4)}, ${widget.northeast!.longitude.toStringAsFixed(4)}'),
                    if (widget.farmName != null)
                      Text('Fazenda: ${widget.farmName}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDownloadOptions,
                    icon: const Icon(Icons.download),
                    label: const Text('Baixar Mapa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.showFreeDownload)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showFreeDownloadDialog,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Área Livre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
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
