import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/backup_service.dart';
import '../services/backup_notification_service.dart';
import '../services/sync_service.dart';
import '../services/crop_service.dart';
import 'pest_list_screen.dart';
import 'disease_list_screen.dart';
import 'weed_list_screen.dart';
import 'backup_screen.dart'; // Import the BackupScreen
import 'database_maintenance_screen.dart'; // Importando a tela de manutenção do banco de dados
import '../routes.dart'; // Importando o AppRoutes

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _userIdController = TextEditingController();
  
  bool _autoSync = false;
  bool _autoBackup = false;
  bool _backupReminderEnabled = true;
  int _backupReminderInterval = 7;
  bool _isLoading = true;
  String _backupLocation = '';
  
  final CropService _cropService = CropService();
  final BackupNotificationService _backupNotificationService = BackupNotificationService();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _cropService.initializeDefaultData();
  }
  
  @override
  void dispose() {
    _serverUrlController.dispose();
    _apiKeyController.dispose();
    _userIdController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Carregar configurações de sincronização
      _serverUrlController.text = prefs.getString('server_url') ?? '';
      _apiKeyController.text = prefs.getString('api_key') ?? '';
      _userIdController.text = prefs.getInt('user_id')?.toString() ?? '';
      _autoSync = prefs.getBool('auto_sync') ?? false;
      
      // Carregar configurações de backup
      _autoBackup = prefs.getBool('auto_backup') ?? false;
      _backupLocation = prefs.getString('backup_location') ?? 'Padrão';
      
      // Carregar configurações de lembrete de backup
      final reminderSettings = await _backupNotificationService.getReminderSettings();
      _backupReminderEnabled = reminderSettings['enabled'] as bool;
      _backupReminderInterval = reminderSettings['intervalDays'] as int;
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar configurações: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar configurações de sincronização
      await prefs.setString('server_url', _serverUrlController.text);
      await prefs.setString('api_key', _apiKeyController.text);
      
      final userId = int.tryParse(_userIdController.text);
      if (userId != null) {
        await prefs.setInt('user_id', userId);
      }
      
      await prefs.setBool('auto_sync', _autoSync);
      
      // Salvar configurações de backup
      await prefs.setBool('auto_backup', _autoBackup);
      await prefs.setString('backup_location', _backupLocation);
      
      // Inicializar o serviço de sincronização com as novas configurações
      final syncService = SyncService();
      await syncService.init(
        _serverUrlController.text,
        _apiKeyController.text,
        userId ?? 0,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar configurações: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectBackupLocation() async {
    // Aqui você pode implementar a seleção de diretório
    // usando o file_picker ou outro método
    
    // Por enquanto, vamos apenas simular a seleção
    setState(() {
      _backupLocation = '/storage/emulated/0/FortSmartAgro/Backups';
    });
  }
  
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final syncService = SyncService();
      await syncService.init(
        _serverUrlController.text,
        _apiKeyController.text,
        int.parse(_userIdController.text),
      );
      
      final isConnected = await syncService.testConnection();
      
      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conexão estabelecida com sucesso!'),
            // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao conectar com o servidor. Verifique as configurações.'),
            // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao testar conexão: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSyncSection(),
                    const SizedBox(height: 24),
                    _buildBackupSection(),
                    const SizedBox(height: 24),
                    _buildDatabaseMaintenanceSection(), // Adicionando a nova seção
                    const SizedBox(height: 24),
                    _buildCropManagementSection(),
                    const SizedBox(height: 24),
                    _buildAboutSection(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSyncSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações de Sincronização',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: 'URL do Servidor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira a URL do servidor';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'Chave API',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira a chave API';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'ID do Usuário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o ID do usuário';
                }
                if (int.tryParse(value) == null) {
                  return 'Por favor, insira um número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Sincronização Automática'),
              subtitle: const Text(
                'Sincronizar automaticamente quando houver conexão',
              ),
              value: _autoSync,
              onChanged: (value) {
                setState(() {
                  _autoSync = value;
                });
              },
              activeColor: Colors.green,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.wifi),
              label: const Text('Testar Conexão'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBackupSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.backup,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Backup e Restauração de Dados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Proteja seus dados com backups regulares. Configure backup automático ou faça backups manuais.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Local de Backup'),
              subtitle: Text(_backupLocation),
              trailing: IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _selectBackupLocation,
              ),
            ),
            SwitchListTile(
              title: const Text('Backup Automático'),
              subtitle: const Text(
                'Realizar backup automático diariamente',
              ),
              value: _autoBackup,
              onChanged: (value) {
                setState(() {
                  _autoBackup = value;
                });
              },
              activeColor: Colors.blue,
            ),
            SwitchListTile(
              title: const Text('Lembretes de Backup'),
              subtitle: const Text(
                'Mostrar lembretes para fazer backup regularmente',
              ),
              value: _backupReminderEnabled,
              onChanged: (value) {
                setState(() {
                  _backupReminderEnabled = value;
                });
                _backupNotificationService.configureBackupReminder(
                  enabled: value,
                  intervalDays: _backupReminderInterval,
                );
              },
              activeColor: Colors.orange,
            ),
            if (_backupReminderEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                child: Row(
                  children: [
                    const Text('Lembrar a cada: '),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _backupReminderInterval,
                      items: const [
                        DropdownMenuItem(value: 3, child: Text('3 dias')),
                        DropdownMenuItem(value: 7, child: Text('7 dias')),
                        DropdownMenuItem(value: 14, child: Text('14 dias')),
                        DropdownMenuItem(value: 30, child: Text('30 dias')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _backupReminderInterval = value;
                          });
                          _backupNotificationService.configureBackupReminder(
                            enabled: _backupReminderEnabled,
                            intervalDays: value,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  setState(() {
                    _isLoading = true;
                  });
                  
                  final backupService = BackupService();
                  final backupPath = await backupService.createBackup();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Backup criado em: $backupPath')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao criar backup: $e')),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              icon: const Icon(Icons.backup),
              label: const Text('Criar Backup Agora'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                // backgroundColor: Colors.blue, // backgroundColor não é suportado em flutter_map 5.0.0
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BackupScreen()),
                );
              },
              icon: const Icon(Icons.settings_backup_restore),
              label: const Text('Gerenciar Backups e Exportações'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                // backgroundColor: Colors.purple, // backgroundColor não é suportado em flutter_map 5.0.0
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Nova seção para manutenção do banco de dados
  Widget _buildDatabaseMaintenanceSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manutenção do Banco de Dados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.storage, color: Colors.deepPurple),
              title: Text('Ferramentas de Manutenção'),
              subtitle: Text('Verificar e corrigir problemas no banco de dados'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DatabaseMaintenanceScreen()),
                );
              },
              icon: const Icon(Icons.build),
              label: const Text('Acessar Ferramentas de Manutenção'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                // backgroundColor: Colors.deepPurple, // backgroundColor não é suportado em flutter_map 5.0.0
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCropManagementSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gerenciamento de Culturas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.agriculture, color: Colors.green),
              title: const Text('Culturas da Fazenda'),
              subtitle: const Text('Gerenciar culturas disponíveis'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.farmCrops);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.red),
              title: const Text('Pragas'),
              subtitle: const Text('Gerenciar pragas por cultura'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PestListScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.coronavirus, color: Colors.purple),
              title: const Text('Doenças'),
              subtitle: const Text('Gerenciar doenças por cultura'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DiseaseListScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.grass, color: Colors.brown),
              title: const Text('Plantas Daninhas'),
              subtitle: const Text('Gerenciar plantas daninhas por cultura'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WeedListScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAboutSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sobre o Aplicativo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('FortSmartAgro'),
              subtitle: Text('Versão 1.0.0'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.email_outlined),
              title: Text('Suporte'),
              subtitle: Text('suporte@fortsmartagro.com.br'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.web),
              title: Text('Website'),
              subtitle: Text('www.fortsmartagro.com.br'),
            ),
          ],
        ),
      ),
    );
  }
}
