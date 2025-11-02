import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/backup_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import '../routes.dart';

/// Tela de perfil do usuário
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final BackupService _backupService = BackupService();
  String _userName = 'Usuário';
  String _userEmail = '';
  String _appVersion = '1.0.0';
  String _databaseSize = '0 MB';
  int _backupCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar dados do usuário das preferências
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Usuário';
      final userEmail = prefs.getString('user_email') ?? '';

      // Calcular tamanho do banco de dados
      final dbSize = await _calculateDatabaseSize();
      
      // Obter contagem de backups
      final backups = await _backupService.getBackupFiles();
      
      setState(() {
        _userName = userName;
        _userEmail = userEmail;
        _databaseSize = _formatBytes(dbSize);
        _backupCount = backups.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados do perfil: $e')),
      );
    }
  }

  Future<int> _calculateDatabaseSize() async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/fortsmartagro.db');
      
      if (await dbFile.exists()) {
        return await dbFile.length();
      }
      return 0;
    } catch (e) {
      print('Erro ao calcular tamanho do banco de dados: $e');
      return 0;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Future<void> _editProfile() async {
    // Implementar edição de perfil
    final TextEditingController nameController = TextEditingController(text: _userName);
    final TextEditingController emailController = TextEditingController(text: _userEmail);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_name', nameController.text);
              await prefs.setString('user_email', emailController.text);
              
              setState(() {
                _userName = nameController.text;
                _userEmail = emailController.text;
              });
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perfil atualizado com sucesso')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    // backgroundColor: Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_userEmail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _userEmail,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Divider(),
                  
                  // Informações do aplicativo
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Versão do Aplicativo'),
                    subtitle: Text(_appVersion),
                  ),
                  ListTile(
                    leading: const Icon(Icons.storage_outlined),
                    title: const Text('Tamanho do Banco de Dados'),
                    subtitle: Text(_databaseSize),
                  ),
                  ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: const Text('Backups Realizados'),
                    subtitle: Text('$_backupCount backups'),
                    // onTap: () => Navigator.pushNamed(context, // onTap não é suportado em Polygon no flutter_map 5.0.0 '/backup'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.healing),
                    title: const Text('Diagnóstico do Banco de Dados'),
                    subtitle: const Text('Verificar e corrigir problemas'),
                    // onTap: () => Navigator.pushNamed(context, // onTap não é suportado em Polygon no flutter_map 5.0.0 AppRoutes.databaseDiagnostic),
                  ),
                  ListTile(
                    leading: const Icon(Icons.science),
                    title: const Text('Testes do Banco de Dados'),
                    subtitle: const Text('Executar testes de integridade'),
                    // onTap: () => Navigator.pushNamed(context, // onTap não é suportado em Polygon no flutter_map 5.0.0 AppRoutes.databaseTest),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Ações
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await _backupService.createBackup();
                      if (result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Backup criado: $result')),
                        );
                        _loadProfileData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erro ao criar backup')),
                        );
                      }
                    },
                    icon: const Icon(Icons.backup),
                    label: const Text('Criar Backup Agora'),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  OutlinedButton.icon(
                    onPressed: () {
                      // Implementar lógica de logout
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Função não implementada')),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
