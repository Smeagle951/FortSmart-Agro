import 'package:flutter/material.dart';
import '../services/farm_culture_sync_service.dart';
import '../models/cultura_model.dart';
import '../utils/logger.dart';

/// Widget para seleção de culturas da fazenda no módulo de monitoramento
class FarmCultureMonitoringSelector extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final bool isRequired;
  final String label;
  final bool showSyncButton;

  const FarmCultureMonitoringSelector({
    Key? key,
    this.initialValue,
    required this.onChanged,
    this.isRequired = true,
    this.label = 'Cultura',
    this.showSyncButton = true,
  }) : super(key: key);

  @override
  State<FarmCultureMonitoringSelector> createState() => _FarmCultureMonitoringSelectorState();
}

class _FarmCultureMonitoringSelectorState extends State<FarmCultureMonitoringSelector> {
  final FarmCultureSyncService _farmCultureSyncService = FarmCultureSyncService();
  List<CulturaModel> _culturas = [];
  String? _selectedCulturaId;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCulturaId = widget.initialValue;
    _loadCulturas();
  }

  Future<void> _loadCulturas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Logger.info('🔄 Carregando culturas da fazenda para monitoramento...');
      
      // Sincronizar e obter culturas da fazenda
      final culturas = await _farmCultureSyncService.getFarmCulturesForMonitoring();
      
      setState(() {
        _culturas = culturas;
        _isLoading = false;
      });
      
      Logger.info('✅ ${culturas.length} culturas da fazenda carregadas');
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas da fazenda: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar culturas: $e';
      });
    }
  }

  Future<void> _syncCulturas() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      Logger.info('🔄 Sincronizando culturas da fazenda...');
      
      // Sincronizar culturas
      final culturasSincronizadas = await _farmCultureSyncService.syncFarmCulturesToMonitoring();
      
      // Recarregar culturas
      await _loadCulturas();
      
      // Mostrar feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${culturasSincronizadas.length} culturas sincronizadas!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao sincronizar culturas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao sincronizar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label + (widget.isRequired ? ' *' : ''),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2A4F3D),
              ),
            ),
            const Spacer(),
            if (widget.showSyncButton)
              IconButton(
                onPressed: _isSyncing ? null : _syncCulturas,
                icon: _isSyncing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, color: Color(0xFF2A4F3D)),
                tooltip: 'Sincronizar culturas da fazenda',
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadCulturas,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          )
        else if (_culturas.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Nenhuma cultura da fazenda encontrada',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Clique no botão de sincronização para importar as culturas da sua fazenda.',
                  style: TextStyle(color: Colors.orange.shade600),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _syncCulturas,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar Culturas'),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedCulturaId,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF2A4F3D)),
              ),
              prefixIcon: Icon(
                Icons.grass,
                color: Color(0xFF2A4F3D),
              ),
            ),
            hint: const Text(
              'Selecione a cultura',
              style: TextStyle(color: Colors.grey),
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2A4F3D)),
            items: _culturas.map((cultura) {
              return DropdownMenuItem<String>(
                value: cultura.id,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: cultura.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cultura.nome,
                        style: const TextStyle(color: Color(0xFF2A4F3D)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cultura.fazendaId != null)
                      const Icon(
                        Icons.agriculture,
                        size: 16,
                        color: Color(0xFF2A4F3D),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCulturaId = value;
              });
              if (value != null) {
                widget.onChanged(value);
              }
            },
            validator: widget.isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma cultura';
                    }
                    return null;
                  }
                : null,
          ),
      ],
    );
  }
} 