import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backup_service.dart';

/// Serviço para gerenciar notificações e lembretes de backup
class BackupNotificationService {
  static final BackupNotificationService _instance = BackupNotificationService._internal();
  factory BackupNotificationService() => _instance;
  BackupNotificationService._internal();

  final BackupService _backupService = BackupService();
  
  // Chaves para SharedPreferences
  static const String _lastBackupReminderKey = 'last_backup_reminder';
  static const String _backupReminderEnabledKey = 'backup_reminder_enabled';
  static const String _backupReminderIntervalKey = 'backup_reminder_interval';
  
  // Configurações padrão
  static const int _defaultReminderIntervalDays = 7; // Lembrar a cada 7 dias
  
  /// Verifica se deve mostrar lembrete de backup
  Future<bool> shouldShowBackupReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar se lembretes estão habilitados
      final reminderEnabled = prefs.getBool(_backupReminderEnabledKey) ?? true;
      if (!reminderEnabled) return false;
      
      // Verificar última vez que foi mostrado
      final lastReminder = prefs.getString(_lastBackupReminderKey);
      if (lastReminder == null) return true; // Primeira vez
      
      final lastReminderDate = DateTime.parse(lastReminder);
      final intervalDays = prefs.getInt(_backupReminderIntervalKey) ?? _defaultReminderIntervalDays;
      
      // Verificar se passou o intervalo
      final daysSinceLastReminder = DateTime.now().difference(lastReminderDate).inDays;
      return daysSinceLastReminder >= intervalDays;
    } catch (e) {
      print('Erro ao verificar lembrete de backup: $e');
      return false;
    }
  }
  
  /// Marca que o lembrete foi mostrado
  Future<void> markReminderShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupReminderKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Erro ao marcar lembrete como mostrado: $e');
    }
  }
  
  /// Configura o lembrete de backup
  Future<void> configureBackupReminder({
    required bool enabled,
    required int intervalDays,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_backupReminderEnabledKey, enabled);
      await prefs.setInt(_backupReminderIntervalKey, intervalDays);
    } catch (e) {
      print('Erro ao configurar lembrete de backup: $e');
    }
  }
  
  /// Mostra diálogo de lembrete de backup
  Future<void> showBackupReminderDialog(BuildContext context) async {
    if (!await shouldShowBackupReminder()) return;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.backup,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Lembrete de Backup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'É recomendado fazer backup dos seus dados regularmente para protegê-los contra perda. Deseja fazer um backup agora?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await markReminderShown();
              Navigator.of(context).pop();
            },
            child: const Text('Lembrar Depois'),
          ),
          TextButton(
            onPressed: () async {
              await markReminderShown();
              Navigator.of(context).pop();
              // Navegar para tela de backup
              Navigator.of(context).pushNamed('/backup');
            },
            child: const Text('Ir para Backup'),
          ),
          ElevatedButton(
            onPressed: () async {
              await markReminderShown();
              Navigator.of(context).pop();
              
              // Criar backup automaticamente
              try {
                final backupPath = await _backupService.createBackup();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backup criado com sucesso em: $backupPath'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao criar backup: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Fazer Backup Agora'),
          ),
        ],
      ),
    );
  }
  
  /// Verifica e mostra notificação de backup se necessário
  Future<void> checkAndShowBackupReminder(BuildContext context) async {
    if (await shouldShowBackupReminder()) {
      await showBackupReminderDialog(context);
    }
  }
  
  /// Obtém configurações atuais do lembrete
  Future<Map<String, dynamic>> getReminderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'enabled': prefs.getBool(_backupReminderEnabledKey) ?? true,
        'intervalDays': prefs.getInt(_backupReminderIntervalKey) ?? _defaultReminderIntervalDays,
        'lastReminder': prefs.getString(_lastBackupReminderKey),
      };
    } catch (e) {
      print('Erro ao obter configurações de lembrete: $e');
      return {
        'enabled': true,
        'intervalDays': _defaultReminderIntervalDays,
        'lastReminder': null,
      };
    }
  }
}
