import 'package:flutter/material.dart';
import '../routes.dart' as app_routes;

class SubMenuItem {
  final String title;
  final VoidCallback onTap;

  SubMenuItem(this.title, this.onTap);
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);
  
  // Exibe um submenu com opções
  void _showSubMenu(BuildContext context, List<SubMenuItem> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle do modal
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Título
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Selecione uma opção',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Itens do submenu
                ...items.map((item) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF2E7D32),
                        size: 16,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      item.onTap();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hoverColor: const Color(0xFF2E7D32).withOpacity(0.05),
                    splashColor: const Color(0xFF2E7D32).withOpacity(0.1),
                  ),
                )).toList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildGroupHeader('Gerenciamento'),
                _buildMenuItem(
                  context,
                  'Perfil da Fazenda',
                  Icons.agriculture,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.farmProfile),
                ),
                _buildMenuItem(
                  context,
                  'Talhões',
                  Icons.crop_square,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.talhoesSafra),
                ),
                _buildMenuItem(
                  context,
                  'Culturas da Fazenda',
                  Icons.eco,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.farmCrops),
                ),
                const Divider(),
                _buildGroupHeader('Operações'),

                _buildMenuItem(
                  context,
                  'Plantio',
                  Icons.grass,
                  onTap: () => _showSubMenu(context, [
                    SubMenuItem('Cadastro de Plantio', () {
                      Navigator.of(context).pushNamed('/plantio/registro');
                    }),
                    SubMenuItem('Lista de Plantios', () {
                      Navigator.of(context).pushNamed(app_routes.AppRoutes.plantioHome);
                    }),
                    SubMenuItem('Cálculo de Sementes', () {
                      Navigator.of(context).pushNamed(app_routes.AppRoutes.plantioCalculoSementes);
                    }),
                    SubMenuItem('Calibragem Plantadeira', () {
                      Navigator.of(context).pushNamed(app_routes.AppRoutes.plantioCalibragemPlantadeira);
                    }),
                    SubMenuItem('Estande de Plantas', () {
                      Navigator.of(context).pushNamed(app_routes.AppRoutes.plantioEstandePlantas);
                    }),
                  ]),
                ),
                _buildMenuItem(
                  context,
                  'Prescrições Premium',
                  Icons.science,
                  onTap: () => _showSubMenu(context, [
                    SubMenuItem('Nova Prescrição', () {
                      Navigator.of(context).pushNamed(app_routes.AppRoutes.prescricaoPremium);
                    }),
                    SubMenuItem('Lista de Prescrições', () {
                      Navigator.of(context).pushNamed(app_routes.AppRoutes.prescricaoLista);
                    }),
                  ]),
                ),
                _buildMenuItem(
                  context,
                  'Caldaflex',
                  Icons.science,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.caldaflex),
                  inDevelopment: true,
                ),

                _buildMenuItem(
                  context,
                  'Colheita',
                  Icons.agriculture,
                  onTap: () => _showSubMenu(context, [
                    SubMenuItem('Cálculo de Perdas', () {
                      Navigator.of(context).pushNamed('/colheita');
                    }),
                    SubMenuItem('Histórico de Colheita', () {
                      Navigator.of(context).pushNamed('/colheita/historico');
                    }),
                  ]),
                ),

                _buildMenuItem(
                  context,
                  'Monitoramento',
                  Icons.bug_report,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.monitoringMain),
                ),
                _buildMenuItem(
                  context,
                  'Estoque de Produtos',
                  Icons.inventory,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.inventory),
                ),
                _buildMenuItem(
                  context,
                  'Gestão de Custos',
                  Icons.attach_money,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.costManagement),
                ),
                const Divider(),
                _buildGroupHeader('Análises'),
                _buildMenuItem(
                  context,
                  'Histórico e Registros de Talhão',
                  Icons.history,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.plotHistory),
                ),
                // Menu de Análises e Alertas removido - funcionalidades transferidas para Mapa de Infestação
                _buildMenuItem(
                  context,
                  'Calibração de Fertilizantes',
                  Icons.science,
                  onTap: () => _showSubMenu(context, [
                    SubMenuItem('Calibração Padrão', () {
                      Navigator.pushNamed(context, '/fertilizer_calibration');
                    }),
                    SubMenuItem('Histórico de Calibrações', () {
                      Navigator.pushNamed(context, '/fertilizer_calibration_history');
                    }),
                    SubMenuItem('Cálculo Básico', () {
                      Navigator.pushNamed(context, app_routes.AppRoutes.calculoBasicoCalibracao);
                    }),
                    SubMenuItem('Histórico Básico', () {
                      Navigator.pushNamed(context, app_routes.AppRoutes.historicoCalibracoes);
                    }),
                  ]),
                ),
                _buildMenuItem(
                  context,
                  'Relatório Agronômico',
                  Icons.analytics,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.reports),
                ),
                  _buildMenuItem(
                    context,
                    'Mapas Offline - DEV',
                    Icons.offline_bolt,
                    onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.offlineMaps),
                  ),
                  _buildMenuItem(
                    context,
                    'Download de Mapas - DEV',
                    Icons.download,
                    onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.offlineMapsDownload),
                  ),
                _buildMenuItem(
                  context,
                  'Cálculo de Solos',
                  Icons.agriculture,
                  onTap: () => Navigator.pushNamed(context, '/soil'),
                ),

                const Divider(),
                _buildGroupHeader('Desenvolvimento'),
                _buildMenuItem(
                  context,
                  'Importar/Exportar Dados - DEV',
                  Icons.swap_horiz,
                  onTap: () => _showSubMenu(context, [
                    SubMenuItem('Importar Shapefiles', () {
                      Navigator.of(context).pushNamed(app_routes.AppRoutes.fileImport);
                    }),
                    SubMenuItem('Exportar Dados', () {
                      Navigator.of(context).pushNamed('/import_export/export');
                    }),
                    SubMenuItem('Importar Dados', () {
                      Navigator.of(context).pushNamed('/import_export/import');
                    }),
                    SubMenuItem('Histórico de Jobs', () {
                      Navigator.of(context).pushNamed('/import_export/main');
                    }),
                  ]),
                ),
                // _buildMenuItem(
                //   context,
                //   'Sincronização',
                //   Icons.sync,
                //   onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.dataSync),
                // ), // Removido
                const Divider(),
                _buildGroupHeader('Configurações'),
                _buildMenuItem(
                  context,
                  'Catálogo de Organismos',
                  Icons.bug_report,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.organismCatalog),
                ),
                _buildMenuItem(
                  context,
                  'Regras de Infestação',
                  Icons.rule,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.infestationRules),
                ),
                _buildMenuItem(
                  context,
                  'Configurações',
                  Icons.settings,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, app_routes.AppRoutes.settings);
                  },
                ),
                _buildMenuItem(
                  context,
                  'Backup e Restauração',
                  Icons.backup,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, app_routes.AppRoutes.backup);
                  },
                ),
                _buildMenuItem(
                  context,
                  'Informações da Versão',
                  Icons.info_outline,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, app_routes.AppRoutes.versionInfo);
                  },
                ),
                const Divider(),
                _buildGroupHeader('Desenvolvimento'),
                _buildMenuItem(
                  context,
                  'Diagnóstico do Banco',
                  Icons.storage,
                  onTap: () => Navigator.pushNamed(context, app_routes.AppRoutes.databaseDiagnostic),
                ),
                _buildMenuItem(
                  context,
                  'Sair',
                  Icons.exit_to_app,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FortSmart Agro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sistema Premium',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon, {
    VoidCallback? onTap,
    bool highlight = false,
    bool inDevelopment = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: highlight 
            ? const Color(0xFF2E7D32).withOpacity(0.1)
            : Colors.transparent,
        border: highlight 
            ? Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: highlight 
                ? const Color(0xFF2E7D32).withOpacity(0.15)
                : Colors.grey.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: highlight ? const Color(0xFF2E7D32) : Colors.grey[700],
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
                  color: highlight ? const Color(0xFF2E7D32) : Colors.grey[800],
                  fontSize: 15,
                ),
              ),
            ),
            if (inDevelopment)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Text(
                  'DEV',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hoverColor: const Color(0xFF2E7D32).withOpacity(0.05),
        splashColor: const Color(0xFF2E7D32).withOpacity(0.1),
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair do App'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                // Aqui você pode adicionar lógica de logout
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }
}
