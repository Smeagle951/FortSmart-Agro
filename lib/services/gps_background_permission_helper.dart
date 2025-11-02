import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../utils/logger.dart';

/// Helper para gerenciar permissões de GPS em background
class GpsBackgroundPermissionHelper {
  /// Solicita todas as permissões necessárias para GPS em background
  static Future<bool> requestAllPermissions(BuildContext context) async {
    try {
      Logger.info('🔐 Solicitando permissões para GPS em background...');
      
      // 1. Solicitar permissão de localização
      final locationPermission = await Permission.location.request();
      if (!locationPermission.isGranted) {
        _showPermissionDeniedDialog(
          context,
          'Permissão de Localização',
          'O aplicativo precisa de permissão de localização para rastrear o talhão.',
        );
        return false;
      }
      
      // 2. Solicitar permissão de localização em background (Android 10+)
      if (Platform.isAndroid) {
        final backgroundPermission = await Permission.locationAlways.request();
        if (!backgroundPermission.isGranted) {
          _showBackgroundLocationDialog(context);
          return false;
        }
      }
      
      // 3. Solicitar permissão de notificação (Android 13+)
      if (Platform.isAndroid) {
        final notificationPermission = await Permission.notification.request();
        if (!notificationPermission.isGranted) {
          Logger.warning('⚠️ Permissão de notificação negada');
          // Não bloquear, apenas avisar
        }
      }
      
      // 4. Solicitar desativação de otimização de bateria
      await _requestBatteryOptimizationExemption(context);
      
      Logger.info('✅ Todas as permissões concedidas');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao solicitar permissões: $e');
      return false;
    }
  }
  
  /// Solicita isenção de otimização de bateria
  static Future<void> _requestBatteryOptimizationExemption(BuildContext context) async {
    if (!Platform.isAndroid) return;
    
    try {
      final isIgnoringBatteryOptimizations = await Permission.ignoreBatteryOptimizations.status;
      
      if (!isIgnoringBatteryOptimizations.isGranted) {
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Otimização de Bateria'),
            content: const Text(
              'Para garantir que o GPS funcione continuamente, mesmo com a tela desligada, '
              'é recomendado desativar a otimização de bateria para este aplicativo.\n\n'
              'Isso não afetará significativamente a bateria do dispositivo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Agora Não'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Configurar'),
              ),
            ],
          ),
        );
        
        if (shouldRequest == true) {
          final result = await Permission.ignoreBatteryOptimizations.request();
          if (result.isGranted) {
            Logger.info('✅ Otimização de bateria desativada');
          } else {
            Logger.warning('⚠️ Usuário não desativou otimização de bateria');
          }
        }
      }
    } catch (e) {
      Logger.error('❌ Erro ao solicitar isenção de bateria: $e');
    }
  }
  
  /// Mostra diálogo explicando a necessidade de permissão de localização em background
  static void _showBackgroundLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissão de Localização em Background'),
        content: const Text(
          'Para rastrear o talhão mesmo com a tela desligada, é necessário conceder '
          'a permissão "Permitir o tempo todo" para localização.\n\n'
          'Por favor, vá em Configurações > Aplicativos > FortSmart Agro > Permissões > '
          'Localização e selecione "Permitir o tempo todo".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }
  
  /// Mostra diálogo de permissão negada
  static void _showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
    String reason,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Negada'),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }
  
  /// Verifica se todas as permissões necessárias estão concedidas
  static Future<bool> hasAllPermissions() async {
    final locationPermission = await Permission.location.isGranted;
    
    if (Platform.isAndroid) {
      final backgroundPermission = await Permission.locationAlways.isGranted;
      return locationPermission && backgroundPermission;
    }
    
    return locationPermission;
  }
  
  /// Mostra dicas para melhor desempenho do GPS
  static void showGpsTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dicas para Melhor Rastreamento GPS'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '📍 Para obter o melhor rastreamento GPS:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. Mantenha o GPS ativado'),
              SizedBox(height: 8),
              Text('2. Prefira usar em áreas abertas'),
              SizedBox(height: 8),
              Text('3. Desative a otimização de bateria para o app'),
              SizedBox(height: 8),
              Text('4. Mantenha a tela ligada (ou permitir bloqueio com GPS ativo)'),
              SizedBox(height: 8),
              Text('5. Aguarde alguns segundos para o GPS estabilizar antes de iniciar'),
              SizedBox(height: 12),
              Text(
                '💡 O aplicativo agora funciona com a tela desligada!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}

