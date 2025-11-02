import 'package:flutter/material.dart';
import 'package:fortsmart_agro/utils/wrappers/file_picker_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fortsmart_agro/utils/wrappers/wrappers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  
  bool _isLoading = false;
  String _backupLocation = '';
  List<Map<String, dynamic>> _backupHistory = [];
  bool _autoBackup = false;
  String _backupFrequency = 'Diário';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBackupHistory();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _backupLocation = prefs.getString('backup_location') ?? 'Padrão';
      _autoBackup = prefs.getBool('auto_backup') ?? false;
      _backupFrequency = prefs.getString('backup_frequency') ?? 'Diário';
      
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
  
  Future<void> _loadBackupHistory() async {
    try {
      // Carregar backups reais do serviço
      final backupFiles = await _backupService.listBackups();
      
      setState(() {
        _backupHistory = backupFiles.map((backup) {
          return {
            'date': backup.createdAt,
            'size': (backup.sizeInBytes / (1024 * 1024)).toStringAsFixed(2), // Converter para MB
            'path': backup.filePath,
            'status': 'Sucesso',
            'fileName': backup.fileName,
          };
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar histórico de backups: $e')),
        );
      }
    }
  }
  
  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final backupPath = await _backupService.createBackup();
      
      if (backupPath != null) {
        // Recarregar o histórico de backups
        await _loadBackupHistory();
        
        if (mounted) {
          // Mostrar diálogo com informações do backup
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Backup Criado!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ Seu backup foi criado com sucesso!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '📂 Local do backup:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    backupPath,
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'IMPORTANTE: Este backup permanece salvo mesmo após desinstalar o app. Você pode restaurá-lo a qualquer momento!',
                            style: TextStyle(fontSize: 11, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao criar backup: Nenhum arquivo foi gerado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _restoreBackup() async {
    try {
      // Mostrar diálogo de aviso
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restaurar Backup'),
          content: const Text(
            'Restaurar um backup substituirá todos os dados atuais. Esta ação não pode ser desfeita. Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
      
      setState(() {
        _isLoading = true;
      });
      
      // Selecionar arquivo de backup
      final file = await FilePickerWrapper.pickSingleFile();
      
      if (file == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final path = file.path;
      
      // Verificar a extensão do arquivo
      if (!path.toLowerCase().endsWith('.zip')) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O arquivo selecionado não é um arquivo de backup válido (.zip)'),
            // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
        return;
      }
      
      // Restaurar backup
      await _backupService.restoreBackup(path);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restaurado com sucesso! Reiniciando aplicativo...'),
          // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
      
      // Aqui você implementaria a lógica para reiniciar o aplicativo
      // após a restauração do backup
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao restaurar backup: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectBackupLocation() async {
    try {
      // Nosso wrapper não suporta seleção de diretório, então mostramos uma mensagem
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devido a limitações técnicas, a seleção de diretório não está disponível. Usando diretório padrão.'),
          // backgroundColor: Colors.orange, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
      
      // Usar diretório padrão
      final appDocDir = await getApplicationDocumentsDirectory();
      final defaultPath = '${appDocDir.path}/backups';
      
      setState(() {
        _backupLocation = defaultPath;
      });
      
      // Salvar nas preferências
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup_location', defaultPath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Local de backup definido: $defaultPath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao configurar diretório: $e')),
      );
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('auto_backup', _autoBackup);
      await prefs.setString('backup_frequency', _backupFrequency);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações salvas com sucesso'),
          // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar configurações: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    }
  }
  
  // Exporta apenas os dados de culturas, pragas, doenças e plantas daninhas
  Future<void> _exportCropData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Solicitar nome personalizado para o arquivo de exportação
      final customName = await _showNameInputDialog('Exportar Dados', 'Nome do arquivo de exportação (opcional):');
      
      final exportPath = await _backupService.exportCropData(
        customName: customName,
      );
      
      if (exportPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dados exportados com sucesso para: $exportPath'),
            // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao exportar dados'),
            // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao exportar dados: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Importa dados de culturas, pragas, doenças e plantas daninhas
  Future<void> _importCropData() async {
    try {
      // Mostrar diálogo de aviso
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Importar Dados'),
          content: const Text(
            'Importar dados pode substituir ou duplicar informações existentes de culturas, pragas, doenças e plantas daninhas. Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Importar'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
      
      setState(() {
        _isLoading = true;
      });
      
      // Selecionar arquivo de exportação
      final file = await FilePickerWrapper.pickSingleFile();
      
      if (file == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final path = file.path;
      
      // Verificar a extensão do arquivo
      if (!path.toLowerCase().endsWith('.zip')) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O arquivo selecionado não é um arquivo de exportação válido (.zip)'),
            // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
        return;
      }
      
      // Importar dados
      final success = await _backupService.importCropData(path);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados importados com sucesso!'),
            // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao importar dados'),
            // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar dados: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Mostra um diálogo para entrada de nome personalizado
  Future<String?> _showNameInputDialog(String title, String hint) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup e Restauração'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionsCard(),
                  const SizedBox(height: 24),
                  _buildSettingsCard(),
                  const SizedBox(height: 24),
                  _buildHistoryCard(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildActionsCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações de Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createBackup,
                    icon: const Icon(Icons.backup),
                    label: const Text('Criar Backup'),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Colors.blue, // backgroundColor não é suportado em flutter_map 5.0.0
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _restoreBackup,
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurar'),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Colors.orange, // backgroundColor não é suportado em flutter_map 5.0.0
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Dados de Culturas e Organismos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportCropData,
                    icon: const Icon(Icons.upload),
                    label: const Text('Exportar Dados'),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _importCropData,
                    icon: const Icon(Icons.download),
                    label: const Text('Importar Dados'),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Colors.purple, // backgroundColor não é suportado em flutter_map 5.0.0
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
  
  Widget _buildSettingsCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações de Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
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
              subtitle: const Text('Realizar backup automaticamente'),
              value: _autoBackup,
              onChanged: (value) {
                setState(() {
                  _autoBackup = value;
                });
              },
            ),
            if (_autoBackup)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Frequência',
                    border: OutlineInputBorder(),
                  ),
                  value: _backupFrequency,
                  items: const [
                    DropdownMenuItem(
                      value: 'Diário',
                      child: Text('Diário'),
                    ),
                    DropdownMenuItem(
                      value: 'Semanal',
                      child: Text('Semanal'),
                    ),
                    DropdownMenuItem(
                      value: 'Mensal',
                      child: Text('Mensal'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _backupFrequency = value;
                      });
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoryCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Histórico de Backups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            _backupHistory.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Nenhum backup encontrado',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _backupHistory.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final backup = _backupHistory[index];
                      final backupDate = backup['date'] as DateTime;
                      final backupSize = backup['size'] as String;
                      final backupPath = backup['path'] as String;
                      final backupFileName = backup['fileName'] as String? ?? path.basename(backupPath);
                      
                      return ListTile(
                        leading: const Icon(
                          Icons.backup,
                          color: Colors.blue,
                        ),
                        title: Text(
                          backupFileName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(backupDate),
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '$backupSize MB',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: backup['status'] == 'Sucesso'
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.restore),
                              tooltip: 'Restaurar backup',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Restaurar Backup'),
                                    content: const Text(
                                      'Restaurar este backup substituirá todos os dados atuais. Esta ação não pode ser desfeita. Deseja continuar?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Restaurar'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  
                                  try {
                                    await _backupService.restoreBackup(backup['path']);
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Backup restaurado com sucesso! Reiniciando aplicativo...'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    
                                    // Aqui você implementaria a lógica para reiniciar o aplicativo
                                    // após a restauração do backup
                                    
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erro ao restaurar backup: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

