import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/sync_service.dart';
import '../services/farm_service.dart';
import '../services/backup_notification_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dashboard_stats.dart';
import 'colheita/colheita_main_screen.dart';
import 'calda/calda_advanced_main_screen.dart';
import 'dashboard/informative_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FarmService _farmService = FarmService();
  final BackupNotificationService _backupNotificationService = BackupNotificationService();
  Map<String, dynamic> _farmData = {};
  bool _isLoadingFarm = true;

  @override
  void initState() {
    super.initState();
    _loadFarmData();
    _checkBackupReminder();
  }
  
  Future<void> _checkBackupReminder() async {
    // Aguardar um pouco para a tela carregar completamente
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      await _backupNotificationService.checkAndShowBackupReminder(context);
    }
  }

  Future<void> _loadFarmData() async {
    try {
      final farm = await _farmService.getCurrentFarm();
      setState(() {
        _farmData = farm != null ? {
          'nome': farm.name,
          'cidade': farm.municipality,
          'uf': farm.state,
        } : {};
        _isLoadingFarm = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFarm = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar a dashboard informativa como padrão
    return const InformativeDashboardScreen();
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.agriculture_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  _farmData['nome'] ?? 'Fazenda não configurada',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _farmData['cidade'] != null && _farmData['uf'] != null 
                      ? '${_farmData['cidade']} / ${_farmData['uf']}'
                      : 'Não informado / N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                    icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                    tooltip: 'Sincronizar',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.backup),
                    icon: const Icon(Icons.backup_rounded, color: Colors.white, size: 20),
                    tooltip: 'Backup',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                    icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                    tooltip: 'Configurações',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        _buildModernQuickAccessItem(
          context,
          'Fazendas',
          Icons.agriculture_rounded,
          () => Navigator.pushNamed(context, AppRoutes.farmList),
          const Color(0xFF4CAF50),
        ),
        _buildModernQuickAccessItem(
          context,
          'Talhões',
          Icons.grid_view_rounded,
          () => Navigator.pushNamed(context, AppRoutes.plots),
          const Color(0xFF2196F3),
        ),
        _buildModernQuickAccessItem(
          context,
          'Monitoramentos',
          Icons.bug_report_rounded,
          () => Navigator.pushNamed(context, AppRoutes.monitoringMain),
          const Color(0xFF9C27B0),
        ),
        _buildModernQuickAccessItem(
          context,
          'Estoque',
          Icons.inventory_2_rounded,
          () => Navigator.pushNamed(context, AppRoutes.inventory),
          const Color(0xFFFF9800),
        ),
        _buildModernQuickAccessItem(
          context,
          'Plantio',
          Icons.eco_rounded,
          () => Navigator.pushNamed(context, AppRoutes.plantingList),
          const Color(0xFF8BC34A),
        ),
        _buildModernQuickAccessItem(
          context,
          'Calibração',
          Icons.science_rounded,
          () => Navigator.pushNamed(context, AppRoutes.calculoBasicoCalibracao),
          const Color(0xFF607D8B),
        ),
        _buildModernQuickAccessItem(
          context,
          'Colheita',
          Icons.agriculture_rounded,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ColheitaMainScreen(),
            ),
          ),
          const Color(0xFF795548),
        ),
        _buildModernQuickAccessItem(
          context,
          'CaldaFlex',
          Icons.science_rounded,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CaldaAdvancedMainScreen(),
            ),
          ),
          const Color(0xFF2E7D32),
        ),
        _buildModernQuickAccessItem(
          context,
          'Prescrição',
          Icons.description_rounded,
          () => Navigator.pushNamed(context, AppRoutes.novaPrescricao),
          const Color(0xFF3F51B5),
        ),
        _buildModernQuickAccessItem(
          context,
          'Solo',
          Icons.terrain_rounded,
          () => Navigator.pushNamed(context, AppRoutes.soilCalculationMain),
          const Color(0xFFFFC107),
        ),
        _buildModernQuickAccessItem(
          context,
          'Importar Arquivos',
          Icons.file_upload_rounded,
          () => Navigator.pushNamed(context, AppRoutes.fileImport),
          const Color(0xFF00BCD4),
        ),
        _buildModernQuickAccessItem(
          context,
          'Dados de Máquinas',
          Icons.agriculture_rounded,
          () => Navigator.pushNamed(context, AppRoutes.machineDataImport),
          const Color(0xFF4CAF50),
        ),
      ],
    );
  }


  Widget _buildModernQuickAccessItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    String? description,
    Color? color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: (color ?? const Color(0xFF2A4F3D)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color ?? const Color(0xFF2A4F3D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showQuickActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ações Rápidas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  // backgroundColor: Color(0xFFE8F5E9), // backgroundColor não é suportado em flutter_map 5.0.0
                  child: Icon(Icons.grid_on, color: Color(0xFF2A4F3D)),
                ),
                title: const Text('Novo Talhão'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.talhoesSafra);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  // backgroundColor: Color(0xFFE8F5E9), // backgroundColor não é suportado em flutter_map 5.0.0
                  child: Icon(Icons.monitor, color: Color(0xFF2A4F3D)),
                ),
                title: const Text('Monitoramento'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.monitoringMain);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.file_upload, color: Color(0xFF2A4F3D)),
                ),
                title: const Text('Importar Arquivos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.fileImport);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.agriculture, color: Color(0xFF2A4F3D)),
                ),
                title: const Text('Dados de Máquinas'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.machineDataImport);
                },
              ),

            ],
          ),
        );
      },
    );
  }
}
