import 'package:flutter/material.dart';
import 'package:fortsmart_agro/services/fortsmart_sync_service.dart';
import 'package:fortsmart_agro/services/farm_service.dart';
import 'package:fortsmart_agro/utils/snackbar_helper.dart';

/// EXEMPLOS DE USO - FortSmart Sync Service
/// Como usar a sincronização com o Render no seu app

// ============================================================================
// EXEMPLO 1: Sincronizar Fazenda na Tela de Perfil
// ============================================================================

class FarmProfileScreenWithSync extends StatefulWidget {
  const FarmProfileScreenWithSync({super.key});

  @override
  State<FarmProfileScreenWithSync> createState() => _FarmProfileScreenWithSyncState();
}

class _FarmProfileScreenWithSyncState extends State<FarmProfileScreenWithSync> {
  final FortSmartSyncService _syncService = FortSmartSyncService();
  final FarmService _farmService = FarmService();
  bool _isSyncing = false;

  Future<void> _syncFarmToServer() async {
    setState(() => _isSyncing = true);

    try {
      // Buscar fazenda atual
      final farm = await _farmService.getCurrentFarm();
      
      if (farm == null) {
        SnackbarHelper.showWarning(context, 'Nenhuma fazenda configurada');
        return;
      }

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Sincronizando com servidor...'),
              SizedBox(height: 8),
              Text(
                'Primeira conexão pode demorar até 1 minuto',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );

      // Sincronizar
      final result = await _syncService.syncFarm(farm);

      // Fechar loading
      Navigator.pop(context);

      if (result['success']) {
        SnackbarHelper.showSuccess(context, '✅ Fazenda sincronizada com sucesso!');
      } else {
        SnackbarHelper.showError(context, 'Erro: ${result['message']}');
      }
    } catch (e) {
      Navigator.pop(context); // Fechar loading
      SnackbarHelper.showError(context, 'Erro na sincronização: $e');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Perfil da Fazenda')),
      body: Column(
        children: [
          // ... seus widgets de perfil ...
          
          SizedBox(height: 24),
          
          // Botão de sincronização
          ElevatedButton.icon(
            onPressed: _isSyncing ? null : _syncFarmToServer,
            icon: _isSyncing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.cloud_upload),
            label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar com Servidor'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXEMPLO 2: Sincronizar Relatório Agronômico
// ============================================================================

class AgronomicReportSyncScreen extends StatelessWidget {
  final String farmId;
  final String plotId;

  const AgronomicReportSyncScreen({
    super.key,
    required this.farmId,
    required this.plotId,
  });

  Future<void> _syncReport(BuildContext context) async {
    final syncService = FortSmartSyncService();

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Gerando e enviando relatório...'),
          ],
        ),
      ),
    );

    try {
      // Sincronizar relatório dos últimos 30 dias
      final result = await syncService.syncAgronomicReport(
        farmId: farmId,
        plotId: plotId,
        startDate: DateTime.now().subtract(Duration(days: 30)),
        endDate: DateTime.now(),
      );

      Navigator.pop(context); // Fechar loading

      if (result['success']) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('✅ Sucesso!'),
            content: Text('Relatório sincronizado!\nID: ${result['report_id']}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('❌ Erro'),
            content: Text(result['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Relatórios Agronômicos')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assessment, size: 80, color: Colors.green),
              SizedBox(height: 24),
              Text(
                'Relatório Agronômico',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Sincroniza dados de monitoramento, infestação e mapas térmicos',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _syncReport(context),
                icon: Icon(Icons.cloud_upload),
                label: Text('Enviar Relatório para Servidor'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXEMPLO 3: Dashboard com Estatísticas do Servidor
// ============================================================================

class ServerDashboardScreen extends StatefulWidget {
  final String farmId;

  const ServerDashboardScreen({super.key, required this.farmId});

  @override
  State<ServerDashboardScreen> createState() => _ServerDashboardScreenState();
}

class _ServerDashboardScreenState extends State<ServerDashboardScreen> {
  final FortSmartSyncService _syncService = FortSmartSyncService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final result = await _syncService.getDashboardStats(widget.farmId);

    setState(() {
      if (result['success']) {
        _stats = result['statistics'];
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Dashboard do Servidor')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_stats == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Dashboard do Servidor')),
        body: Center(child: Text('Erro ao carregar estatísticas')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard do Servidor'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Talhões
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Talhões', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Total: ${_stats!['plots']['total']}'),
                    Text('Área Total: ${_stats!['plots']['total_area']} ha'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Card de Monitoramentos
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monitoramentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Total: ${_stats!['monitorings']['total']}'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Top Organismos
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Organismos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ...(_stats!['top_organisms'] as List).map((org) {
                      return ListTile(
                        title: Text(org['organism_name'] ?? 'Desconhecido'),
                        subtitle: Text('Severidade média: ${org['avg_severity'].toStringAsFixed(1)}%'),
                        trailing: Chip(
                          label: Text('${org['count']}'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXEMPLO 4: Heatmap do Servidor
// ============================================================================

class ServerHeatmapViewer extends StatefulWidget {
  final String plotId;

  const ServerHeatmapViewer({super.key, required this.plotId});

  @override
  State<ServerHeatmapViewer> createState() => _ServerHeatmapViewerState();
}

class _ServerHeatmapViewerState extends State<ServerHeatmapViewer> {
  final FortSmartSyncService _syncService = FortSmartSyncService();
  List<Map<String, dynamic>> _heatmapPoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHeatmap();
  }

  Future<void> _loadHeatmap() async {
    final result = await _syncService.getHeatmap(widget.plotId);

    setState(() {
      if (result['success']) {
        _heatmapPoints = List<Map<String, dynamic>>.from(result['heatmap_points']);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _heatmapPoints.length,
      itemBuilder: (context, index) {
        final point = _heatmapPoints[index];
        
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getColorFromHex(point['color']),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${(point['intensity'] * 100).toInt()}%',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
          title: Text('Nível: ${point['level'].toUpperCase()}'),
          subtitle: Text(
            '${point['latitude'].toStringAsFixed(6)}, ${point['longitude'].toStringAsFixed(6)}',
          ),
          trailing: Text('${point['occurrence_count']} ocorrências'),
        );
      },
    );
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}

// ============================================================================
// EXEMPLO 5: Sincronização Automática em Background
// ============================================================================

class AutoSyncService {
  final FortSmartSyncService _syncService = FortSmartSyncService();
  
  /// Sincroniza automaticamente quando o app abre
  Future<void> syncOnAppStart() async {
    // Verificar conectividade
    final isConnected = await _checkConnectivity();
    
    if (!isConnected) {
      print('📡 Sem internet, sincronização adiada');
      return;
    }

    print('🔄 Iniciando sincronização automática...');

    try {
      // Sincronizar fazenda
      final farmService = FarmService();
      final farm = await farmService.getCurrentFarm();
      
      if (farm != null) {
        final result = await _syncService.syncFarm(farm);
        
        if (result['success']) {
          print('✅ Fazenda sincronizada automaticamente');
        }
      }
    } catch (e) {
      print('⚠️ Erro na sincronização automática: $e');
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await _syncService.getDashboardStats('test');
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

// ============================================================================
// EXEMPLO 6: Integração na Tela de Relatórios
// ============================================================================

class ReportsScreenWithSync extends StatelessWidget {
  final String farmId;
  final String plotId;

  const ReportsScreenWithSync({
    super.key,
    required this.farmId,
    required this.plotId,
  });

  Future<void> _generateAndSyncReport(BuildContext context) async {
    final syncService = FortSmartSyncService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Gerando relatório agronômico...'),
          ],
        ),
      ),
    );

    try {
      final result = await syncService.syncAgronomicReport(
        farmId: farmId,
        plotId: plotId,
        startDate: DateTime.now().subtract(Duration(days: 30)),
        endDate: DateTime.now(),
      );

      Navigator.pop(context);

      if (result['success']) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Sucesso!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Relatório sincronizado com o servidor'),
                SizedBox(height: 8),
                Text('ID: ${result['report_id']}', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Relatórios')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics, size: 100, color: Colors.blue),
              SizedBox(height: 24),
              Text(
                'Relatório Agronômico Completo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Monitoramento + Infestação + Mapas Térmicos',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _generateAndSyncReport(context),
                icon: Icon(Icons.upload),
                label: Text('Enviar para Servidor'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXEMPLO 7: Usar no main.dart (Sync ao Iniciar)
// ============================================================================

/*
// No main.dart, após inicialização:

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... outras inicializações ...
  
  // Sincronizar ao iniciar (em background)
  final autoSync = AutoSyncService();
  autoSync.syncOnAppStart(); // Não aguardar, deixa em background
  
  runApp(MyApp());
}
*/

// ============================================================================
// INSTRUÇÕES DE USO
// ============================================================================

/*

COMO USAR ESTES EXEMPLOS:

1. COPIAR O EXEMPLO DESEJADO
   Escolha um dos 7 exemplos acima e adapte para seu código.

2. IMPORTAR O SERVIÇO
   import 'package:fortsmart_agro/services/fortsmart_sync_service.dart';

3. ALTERAR URL
   Depois do deploy no Render, altere a URL em:
   lib/services/fortsmart_sync_service.dart (linha 15)

4. TESTAR
   Rode o app e teste a sincronização.

EXEMPLOS RECOMENDADOS POR TELA:

- Perfil da Fazenda: Exemplo 1
- Relatórios: Exemplo 2 ou 6
- Dashboard: Exemplo 3
- Mapas: Exemplo 4
- Sync Automático: Exemplo 5 ou 7

DÚVIDAS:

Consulte: GUIA_COMPLETO_RENDER_APPWRITE.md

*/

