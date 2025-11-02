import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import 'database_repair_screen.dart';
import '../../routes.dart' as app_routes;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationEnabled = true;
  String _selectedLanguage = 'Português';
  double _textSize = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Preferências do Aplicativo'),
          Card(
            elevation: 2,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notificações'),
                  subtitle: const Text('Receber alertas e notificações'),
                  value: _notificationsEnabled,
                  activeColor: const Color(0xFF2A4F3D),
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Modo Escuro'),
                  subtitle: const Text('Usar tema escuro no aplicativo'),
                  value: _darkModeEnabled,
                  activeColor: const Color(0xFF2A4F3D),
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Serviços de Localização'),
                  subtitle: const Text('Permitir acesso à sua localização'),
                  value: _locationEnabled,
                  activeColor: const Color(0xFF2A4F3D),
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Configurações de Monitoramento'),
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Catálogo de Organismos'),
                  subtitle: const Text('Gerenciar pragas, doenças e plantas daninhas'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pushNamed(context, app_routes.AppRoutes.organismCatalog);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.rule),
                  title: const Text('Regras de Infestação'),
                  subtitle: const Text('Configurar limites fenológicos por fazenda'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Abre tela de edição de regras fenológicas
                    Navigator.pushNamed(context, app_routes.AppRoutes.infestationRules);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Idioma e Texto'),
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Idioma'),
                  subtitle: Text(_selectedLanguage),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showLanguageDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Tamanho do Texto'),
                  subtitle: const Text('Ajustar tamanho da fonte'),
                  onTap: () {},
                ),
                Slider(
                  value: _textSize,
                  min: 0.8,
                  max: 1.2,
                  divisions: 4,
                  activeColor: const Color(0xFF2A4F3D),
                  label: _getTextSizeLabel(),
                  onChanged: (value) {
                    setState(() {
                      _textSize = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Dados e Armazenamento'),
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Limpar Cache'),
                  subtitle: const Text('Remover dados temporários'),
                  leading: const Icon(Icons.cleaning_services, color: Color(0xFF2A4F3D)),
                  onTap: () {
                    _showClearCacheDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Backup de Dados'),
                  subtitle: const Text('Fazer backup dos seus dados'),
                  leading: const Icon(Icons.backup, color: Color(0xFF2A4F3D)),
                  onTap: () {
                    Navigator.of(context).pushNamed(app_routes.AppRoutes.backup);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Download Offline'),
                  subtitle: const Text('Baixar fazenda para uso sem internet'),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.cloud_download, color: Colors.blue, size: 20),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NOVO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed(app_routes.AppRoutes.downloadFazendaOffline);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Restaurar Dados'),
                  subtitle: const Text('Restaurar a partir de um backup'),
                  leading: const Icon(Icons.restore, color: Color(0xFF2A4F3D)),
                  onTap: () {
                    Navigator.of(context).pushNamed(app_routes.AppRoutes.backup);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Manutenção do Banco de Dados'),
                  subtitle: const Text('Diagnosticar e reparar problemas'),
                  leading: const Icon(Icons.build_circle, color: Color(0xFF2A4F3D)),
                  onTap: () {
                    Navigator.of(context).pushNamed(app_routes.AppRoutes.databaseMaintenance);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Diagnóstico Avançado'),
                  subtitle: const Text('Ferramentas de diagnóstico do banco de dados'),
                  leading: const Icon(Icons.bug_report, color: Color(0xFF2A4F3D)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DatabaseRepairScreen(),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Sobre o Aplicativo'),
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Versão do Aplicativo'),
                  subtitle: const Text('3.0.0'),
                  leading: const Icon(Icons.info, color: Color(0xFF2A4F3D)),
                  onTap: () {
                    Navigator.pushNamed(context, app_routes.AppRoutes.versionInfo);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Termos de Uso'),
                  leading: const Icon(Icons.description, color: Color(0xFF2A4F3D)),
                  onTap: () {
                    Navigator.pushNamed(context, app_routes.AppRoutes.termsOfUse);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Política de Privacidade'),
                  leading: const Icon(Icons.privacy_tip, color: Color(0xFF2A4F3D)),
                  onTap: () {
                    Navigator.pushNamed(context, app_routes.AppRoutes.privacyPolicy);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Contato e Suporte'),
                  leading: const Icon(Icons.support_agent, color: Color(0xFF2A4F3D)),
                  onTap: () {
                    Navigator.pushNamed(context, app_routes.AppRoutes.contactSupport);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2A4F3D),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecionar Idioma'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('Português'),
              _buildLanguageOption('English'),
              _buildLanguageOption('Español'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: _selectedLanguage == language
          ? const Icon(Icons.check, color: Color(0xFF2A4F3D))
          : null,
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        Navigator.of(context).pop();
      },
    );
  }

  String _getTextSizeLabel() {
    if (_textSize <= 0.8) return 'Pequeno';
    if (_textSize <= 0.9) return 'Médio-pequeno';
    if (_textSize <= 1.0) return 'Médio';
    if (_textSize <= 1.1) return 'Médio-grande';
    return 'Grande';
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Limpar Cache'),
          content: const Text(
              'Isso removerá todos os dados temporários do aplicativo. Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache limpo com sucesso!')),
                );
              },
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );
  }
}
